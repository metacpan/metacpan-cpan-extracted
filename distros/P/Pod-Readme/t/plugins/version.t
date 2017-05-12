use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use Cwd;
use File::Compare qw/ compare_text /;
use File::Temp qw/ tempfile /;
use Path::Tiny qw/ path /;

use lib 't/lib';
use Pod::Readme::Test;

# use Pod::Readme::Test::Kit;

our $VERSION = '1.23'; # for testing

my $class = 'Pod::Readme';
use_ok $class;

isa_ok $prf = $class->new(
    input_file => $0,
    output_fh  => $io,
 ), $class;

{
    filter_lines('=for readme plugin version', '');
    is $out, "=head1 VERSION\n\n${VERSION}\n\n";

    is_deeply [ $prf->depends_on ], [ $prf->version_file, $prf->input_file ],
      'depends_on';

    lives_ok { $prf->dependencies_updated } 'dependencies_updated';

    reset_out();
    $prf->version_run(0);
}

{
    filter_lines("=for readme plugin version file=${0} title='THIS VER'", '');
    is $out, "=head1 THIS VER\n\n${VERSION}\n\n";
    reset_out();
    $prf->version_run(0);
}

{
    filter_lines('=for readme plugin version heading-level=2 title="Version"', '');
    is $out, "=head2 Version\n\n${VERSION}\n\n";
    reset_out();
    $prf->version_run(0);
}

done_testing;
