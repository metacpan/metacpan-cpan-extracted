use strict;
use Test::More;
use App::pod2pandoc;
use File::Temp qw(tempdir);
use File::Spec::Functions;
use Test::Output qw(:functions);
use JSON;

plan skip_all => 'these tests are for release candidate testing'
  unless $ENV{RELEASE_TESTING};

my $dir = tempdir( CLEANUP => 1 );
sub slurp { local ( @ARGV, $/ ) = @_; <> }

# convert a single file
{
    my @source = 'lib/Pod/Pandoc.pm';
    my $target = catfile( $dir, 'Pandoc-Elements.html' );
    my @args = ('--template' => 't/template.html'); 
    is stdout_from { pod2pandoc( \@source, -o => $target, @args ) }, '';

    is slurp($target),
      "Pod::Pandoc: process Plain Old Documentation format with Pandoc\n"
      . ": lib/Pod/Pandoc.pm\n",
      "pod2pandoc single file";

    # convert file to json
    my $stdout = stdout_from { pod2pandoc( \@source ) };
    ok decode_json($stdout), 'JSON by default';

    # convert and emit to STDOUT
    $stdout = stdout_from { pod2pandoc( \@source, '-t', 'rst' ) };
    like $stdout, qr/^NAME/, 'convert to STDOUT';
}

# convert multiple files
{
    my @source = ( 'lib/App/pod2pandoc.pm', 'lib/Pod/Pandoc.pm' );
    my $target = catfile( $dir, 'Pod-Pandoc.md' );
    pod2pandoc( \@source, { ext => 'md' },
        '-o', $target, '--template', 't/template.html' );

    is slurp($target),
      "App::pod2pandoc: implements pod2pandoc command line script\n"
      . ": lib/App/pod2pandoc.pm, lib/Pod/Pandoc.pm\n",
      "pod2pandoc multiple files";
}

# convert directory

my ( $stdout, $stderr ) = output_from {
    pod2pandoc( [ 'lib/', 'script', 't/empty', $dir ],
        { 'ext' => 'md', wiki => 1, update => 1, index => 'Home' } );
};
is( ( scalar split "\n", $stdout ), 5, 'pod2pandoc directory, option update' );
is $stderr, "no .pm, .pod or Perl script found in t/empty\n", 'warning';

ok -e catfile( $dir, 'Pod-Simple-Pandoc.md' ), 'option wiki';
ok -e catfile( $dir, 'Home.md' ), 'option index';

done_testing;
