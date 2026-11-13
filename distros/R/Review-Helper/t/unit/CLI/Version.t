# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use File::Temp qw/tempdir/;
use Review::Helper;
use TestCLI qw/cli/;

my $dir = tempdir(CLEANUP => 1);

is(
    [cli($dir, 'version')],
    [0, "standard " . Review::Helper->STANDARD_VERSION . "\nimplementation Review-Helper $Review::Helper::VERSION\n", ''],
    'prints the standard and implementation versions',
);

is([cli($dir, 'version', 'x')], [1, '', "review-helper version: Usage: review-helper version\n"], 'arguments are refused');

done_testing;
