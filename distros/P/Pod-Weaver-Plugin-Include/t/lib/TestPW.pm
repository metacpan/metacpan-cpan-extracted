#
package TestPW;
use strict;
use warnings;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(
  slurp_file
  test_basic weaver_input
  compare_pod_ok
);
our $Data = do { local $/; <DATA> };

use Test::More 0.96;
use Test::Differences 0.500;
use Test::MockObject 1.09;

use PPI;

use Pod::Elemental 0.102360;
use Pod::Elemental::Selectors -all;
use Pod::Elemental::Transformer::Pod5;
use Pod::Elemental::Transformer::Nester;

use Pod::Weaver;
require Software::License::BSD;

my $zilla = Test::MockObject->new();
$zilla->set_always( is_trial => 0 );
$zilla->set_always( license =>
      Software::License::BSD->new( { holder => 'DZHolder', year => 2017, } ) );
$zilla->set_always( authors     => ['DZAuth Belman <vrurg@cpan.org>'] );
$zilla->set_always( stash_named => undef );
$zilla->mock( copyright_holder => sub { $_[0]->license->holder } );

# proposed changes to Pod::Weaver::Section::Legal look for a license file.  we can ignore that for these tests.
$zilla->set_always( files => [] );

sub slurp_file { local ( @ARGV, $/ ) = @_; <> }

sub test_basic {
    my ( $testName, $weaver, $input ) = @_;
    my $expected = $input->{expected};

    # copied/modified from Pod::Weaver tests (Pod-Weaver-3.101632/t/basic.t)
    my $woven = $weaver->weave_document($input);
    
    #say STDERR $woven->as_pod_string;

    compare_pod_ok( $woven->as_pod_string, $expected,
        "test $testName: exactly the pod string we wanted after weaving!",
    );
}

sub compare_pod_ok {
    my ( $got, $exp, $desc ) = @_;

    # As it says in the pod weaver tests:
    # XXX: This test is extremely risky as things change upstream.

    eq_or_diff( normalize($got), normalize($exp), $desc );
}

sub normalize {
    local $_ = $_[0];

    # Pod::Elemental 0.103003 has a bug that produces an extra newline...
    # It was fixed in the next version, but who cares about an extra newline...
    s/\n+/\n/sg;
    return $_;
}

sub weaver_input {
    my ($dir) = @_;
    my $base = $dir ? "$dir/" : 't/eg/';

    # copied/modified from Pod::Weaver tests (Pod-Weaver-3.101632/t/basic.t)
    my $in_pod   = slurp_file("${base}in.pod");
    my $expected = slurp_file("${base}out.pod");
    my $document = Pod::Elemental->read_string($in_pod);
    
    my $perl_document = $Data;
    my $ppi_document  = PPI::Document->new( \$perl_document );

    return {
        pod_document => $document,
        ppi_document => $ppi_document,

        # below configuration modified by rwstauner
        expected => $expected,

        version => '1.002003',

        authors => [ 'Vadim Belman <vrurg@cpan.org>', ],
        license => Software::License::BSD->new(
            {
                year   => 2017,
                holder => 'Vadim Belman <vrurg@cpan.org>'
            }
        ),
        zilla => $zilla,
    };
}

1;

__DATA__

package Module::Name;
# ABSTRACT: abstract text

my $this = 'a test';


__END__

This module has been borrowed from Pod::Weaver::Plugin::StopWords. The initial
code has been written by Randy Stauner <rwstauner@cpan.org>.
