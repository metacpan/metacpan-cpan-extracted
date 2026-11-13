# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo commit_file/;
use Review::Helper::VCS;

subtest detect => sub {
    my $dir = make_repo();
    commit_file($dir, 'Root', 'a.txt' => "a\n");

    my $vcs = Review::Helper::VCS->detect("$dir/a.txt");
    isa_ok($vcs, 'Review::Helper::VCS::Git');
    is($vcs->root, $dir, 'found from a file in the repository');

    like(dies { Review::Helper::VCS->detect('/') }, qr/Not inside a git worktree/, 'croaks outside any repository');
};

done_testing;
