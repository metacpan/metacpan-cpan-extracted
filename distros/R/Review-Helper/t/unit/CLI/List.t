# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo/;
use TestCLI qw/cli/;
use Review::Helper::VCS;
use Review::Helper::Registry;

my $dir = make_repo();
my $reg = Review::Helper::Registry->new(repo => Review::Helper::VCS->detect($dir));

is([cli($dir, 'list')], [0, '', ''], 'nothing registered');

$reg->register('b-id', "$dir/b.sqlite", 'closed');
$reg->register('a-id', "$dir/a.sqlite");
is([cli($dir, 'list')], [0, "a-id\topen\t$dir/a.sqlite\nb-id\tclosed\t$dir/b.sqlite\n", ''], 'one line per review, sorted by id');

my ($exit, undef, $err) = cli($dir, 'list', 'x');
is([$exit, $err], [1, "review-helper list: Usage: review-helper list\n"], 'takes no arguments');

done_testing;
