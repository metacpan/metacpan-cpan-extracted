# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo commit_file pinned_refs/;
use TestCLI qw/cli/;
use Review::Helper::VCS;
use Review::Helper::Registry;

my $dir      = make_repo();
my $revision = commit_file($dir, 'One', 'a.txt' => "a\n");
my $repo     = Review::Helper::VCS->detect($dir);
my $reg      = Review::Helper::Registry->new(repo => $repo);

TestRepo::write_file($dir, 'kept.sqlite', '');
$reg->register('open-id', "$dir/kept.sqlite");
$reg->register('closed-id', "$dir/kept.sqlite", 'closed');
$repo->pin("refs/review-helper/$_/1", $revision) for qw/open-id closed-id/;

is([cli($dir, 'prune', '--dry-run')],   [0, "refs/review-helper/closed-id/1\n", ''], 'dry run lists the ref');
is(scalar(@{pinned_refs($repo->root)}), 2,                                           'dry run keeps it');

my ($exit, undef, $err) = cli($dir, 'prune', 'refs/review-helper/open-id/1');
is([$exit, $err], [1, "review-helper prune: Usage: review-helper prune [--dry-run]\n"], 'takes no ref arguments');

is([cli($dir, 'prune')],     [0, "refs/review-helper/closed-id/1\n", ''], 'prune removes the ref');
is(pinned_refs($repo->root), ['refs/review-helper/open-id/1'],            'open review keeps its ref');
ok(-e "$dir/kept.sqlite", 'review file kept');

is([cli($dir, 'prune')], [0, '', ''], 'nothing left to prune');

done_testing;
