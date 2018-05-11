#
package TestPW;
use strict;
use warnings;
use File::Spec;
use Exporter;

#our @ISA    = qw(Exporter);
#our @EXPORT = qw(
#  slurp_file
#  test_basic weaver_input
#  compare_pod_ok
#);
our $fakePerl = do { local $/; <DATA> };

use Test::More 0.96;
use Test::Differences 0.500;
use Test::MockObject 1.09;

use PPI;

use Pod::Elemental 0.102360;

use Pod::Weaver;
require Software::License::BSD;

use Moose;
use namespace::autoclean;
with qw<Pod::Elemental::PerlMunger>;

my $zilla = Test::MockObject->new();
$zilla->set_always( is_trial => 0 );
$zilla->set_always( license =>
      Software::License::BSD->new( { holder => 'DZHolder', year => 2017, } ) );
$zilla->set_always( authors     => ['DZAuth Belman <vrurg@cpan.org>'] );
$zilla->set_always( stash_named => undef );
$zilla->mock( copyright_holder => sub { $_[0]->license->holder } );

# proposed changes to Pod::Weaver::Section::Legal look for a license file.  we can ignore that for these tests.
$zilla->set_always( files => [] );

has dir => ( is => 'rw', );

has testName => ( is => 'rw', );

has inFile => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initInFile',
);

has inSource => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initInSource',
);

# fromPod is true if source is loaded from .pod, not .pm
has fromPod => ( is => 'rw', lazy => 1, builder => 'initFromPod', );

has expected => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initExpected',
);

has args => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initArgs',
);

has weaver => (
    is      => 'ro',
    lazy    => 1,
    builder => 'initWeaver',
);

# Used only when fromPod is true.
has docPod => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initDocPod',
);

# User only when fromPod is true. Will contain fake Perl code PPI.
has docPPI => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initDocPPI',
);

sub slurp_file { local ( @ARGV, $/ ) = @_; <> }

sub run_in_dir {
    shift if $_[0]->isa(__PACKAGE__);    # Take TestPW->run_in_dir into account.
    my $dir = shift;

    my $tDir = File::Spec->catdir( "t", $dir );

    my $tester = __PACKAGE__->new( dir => $tDir, testName => $dir, );

    $tester->run;
}

sub run {
    my $this = shift;

    my $outStr;

    if ( $this->fromPod ) {
        my $doc = $this->weaver->weave_document(
            {
                %{ $this->args },
                pod_document => $this->docPod,
                ppi_document => $this->docPPI,
            }
        );
        $outStr = $doc->as_pod_string;
    }
    else {
        $outStr = $this->munge_perl_string( $this->inSource, $this->args );
    }
    
    compare_pod_ok(
        $outStr,
        $this->expected,
        "test "
          . $this->testName
          . ": exactly the pod string we wanted after weaving!",
    );
}

sub munge_perl_string {
    my $this = shift;
    my ( $doc, $args ) = @_;

    my $newDoc = $this->weaver->weave_document(
        {
            %$args,
            pod_document => $doc->{pod},
            ppi_document => $doc->{ppi},
        }
    );

    return {
        pod => $newDoc,
        ppi => $doc->{ppi},
    };
}

sub compare_pod_ok {
    my ( $got, $exp, $desc ) = @_;

    # As it says in the pod weaver tests:
    # XXX: This test is extremely risky as things change upstream.

    eq_or_diff( normalize($got), normalize($exp), $desc );
}

sub normalize {
    local $_ = $_[0];
    
    # Skip any Perl code before __END__ - as returned by munge_perl_string().
    s/^.*\n__END__\R\R?//s;

    # Pod::Elemental 0.103003 has a bug that produces an extra newline...
    # It was fixed in the next version, but who cares about an extra newline...
    s/\n+/\n/sg;
    return $_;
}

sub initInFile {
    my $this = shift;

    my $base = $this->dir;
    my $inFile;
  SCAN: foreach my $ext (qw<pod pm>) {
        my $file = File::Spec->catfile( $base, "in.${ext}" );
        if ( -e $file && -f $file ) {
            $inFile = $file;
            last SCAN;
        }
    }

    die "No input file found in " . $this->dir unless defined $inFile;
    $this->_canRead( $inFile, 'input file' );

    return $inFile;
}

sub initFromPod {
    my $this = shift;

    return $this->inFile =~ /\.pod$/;
}

sub initInSource {
    my $this = shift;

    my $in = slurp_file( $this->inFile );

    if ( $this->fromPod ) {
        $in =
          "# PODNAME: " . $this->testName . "\n# ABSTRACT: no abstract\n" . $in;
    }

    return $in;
}

sub initArgs {
    my $this = shift;

    return {
        version => '1.002003',
        authors => [ 'Vadim Belman <vrurg@cpan.org>', ],
        license => Software::License::BSD->new(
            {
                year   => 2017,
                holder => 'Vadim Belman <vrurg@cpan.org>'
            }
        ),
        zilla    => $zilla,
        filename => $this->inFile,
    };
}

sub initWeaver {
    my $this = shift;

    return Pod::Weaver->new_from_config( { root => $this->dir, } );
}

sub initDocPod {
    my $this = shift;
    return Pod::Elemental->read_string( slurp_file( $this->inFile ) );
}

sub initDocPPI {
    my $this = shift;
    return PPI::Document->new(\$fakePerl);
}

sub initExpected {
    my $this = shift;
    my $outFile = File::Spec->catfile( $this->dir, "out.pod" );
    $this->_canRead( $outFile, 'out.pod' );
    return slurp_file($outFile);
}

sub _canRead {
    my $this = shift;
    my ( $file, $alias ) = @_;
    die "No $alias found in dir " . $this->dir unless -e $file;
    die "$file isn't a plain file"             unless -f $file;
    die "$file is not readable"                unless -r $file;
}

1;

__DATA__

package Module::Name;
# ABSTRACT: abstract text

my $this = 'a test';


__END__

This module has been borrowed from Pod::Weaver::Plugin::StopWords. The initial
code has been written by Randy Stauner <rwstauner@cpan.org>.
