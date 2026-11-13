# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use Cwd qw/abs_path/;
use File::Temp qw/tempdir/;
use POSIX();
use TestRepo qw/make_repo run_git commit_file/;
use Review::Helper::VCS;

# A commit's diff of one file, against its first parent or the empty revision.
sub commit_diff($repo, $revision, @paths) {
    return $repo->range_diff($repo->parents($revision)->[0] // $repo->empty_revision, $revision, @paths);
}

my $dir    = make_repo();
my $root   = commit_file($dir, "Root commit\n\nWith a body.", 'a.txt' => "one\ntwo\nthree\n", 'img.bin' => "\0\1\2");
my $second = commit_file(
    $dir, 'Second commit',
    'a.txt'     => "one\n2\nthree\nfour\n",
    'img.bin'   => undef,
    'lib/b.txt' => "bee\n",
);
run_git($dir, qw/mv a.txt c.txt/);
my $third = commit_file($dir, 'Rename');

subtest find => sub {
    my $repo = Review::Helper::VCS->detect($dir);
    isa_ok($repo, 'Review::Helper::VCS::Git');
    ok($repo->DOES('Review::Helper::VCS'), 'detect gives the git implementation of the VCS role');
    is($repo->root,       $dir,        'root from the top directory');
    is($repo->git_dir,    "$dir/.git", 'git dir');
    is($repo->common_dir, "$dir/.git", 'common dir');

    is(Review::Helper::VCS->detect("$dir/lib/b.txt")->root,      $dir, 'root from a file');
    is(Review::Helper::VCS->detect("$dir/lib/new.sqlite")->root, $dir, 'root from a file that does not exist yet');

    mkdir("$dir/.git/review-helper");
    my $inside = Review::Helper::VCS->detect("$dir/.git/review-helper/x.sqlite");
    is($inside->root,    $dir,        'root from inside the git directory');
    is($inside->git_dir, "$dir/.git", 'git dir from inside the git directory');

    my $wt = abs_path(tempdir(CLEANUP => 1)) . "/wt";
    run_git($dir, qw/worktree add -q/, $wt);
    my $linked = Review::Helper::VCS->detect($wt);
    is($linked->root,       $wt,                                         'linked worktree root');
    is($linked->git_dir,    "$dir/.git/worktrees/" . ($wt =~ s{.*/}{}r), 'linked worktree git dir');
    is($linked->common_dir, "$dir/.git",                                 'linked worktree shares the common dir');

    my $wt_git = "$dir/.git/worktrees/" . ($wt =~ s{.*/}{}r);
    is($linked->state_dir,        "$wt_git/review-helper",   'a linked worktree has its own state directory');
    is($linked->shared_state_dir, "$dir/.git/review-helper", 'and shares the common one');
    ok($linked->is_internal_path("$wt_git/review-helper/x.sqlite"), 'its git directory is internal');
    ok($linked->is_internal_path("$dir/.git/review-helper/r.json"), 'and so is the common one');

    my $wt_file = $linked->state_dir . '/x.sqlite';
    mkdir($linked->state_dir);
    is(Review::Helper::VCS->detect($wt_file)->root, $wt, 'root from inside a linked worktree git directory');
    run_git($dir, qw/worktree remove --force/, $wt);

    my $rel = abs_path(tempdir(CLEANUP => 1)) . "/wtrel";
    my ($major, $minor) = run_git($dir, '--version') =~ m/(\d+)\.(\d+)/;
    SKIP: {
        skip 'git worktree add --relative-paths needs git 2.48', 1 if $major < 2 || ($major == 2 && $minor < 48);
        run_git($dir, qw/worktree add -q --relative-paths/, $rel);
        my $rel_dir = Review::Helper::VCS->detect($rel)->state_dir;
        mkdir($rel_dir);
        is(Review::Helper::VCS->detect("$rel_dir/x.sqlite")->root, $rel, 'root from inside the git directory of a worktree added with relative paths');
        run_git($dir, qw/worktree remove --force/, $rel);
    }

    like(dies { Review::Helper::VCS->detect('/') },           qr/Not inside a git worktree/, 'no repository');
    like(dies { Review::Helper::VCS->detect("$dir/nope/x") }, qr/No such directory/,         'missing directory');
};

subtest non_ascii_dir => sub {
    my $parent = tempdir(CLEANUP => 1);
    my $named  = "$parent/caf\xc3\xa9";    # UTF-8 bytes, as the file system returns them
    mkdir($named) or die "mkdir: $!";
    run_git($named, qw/init -q/);
    my $found = Review::Helper::VCS->detect($named);
    is($found->root, abs_path($named), 'a repository under a non-ASCII directory is found');
};

subtest find_submodule => sub {
    my $super = make_repo();
    commit_file($super, 'Super', 'README' => "super\n");
    run_git($super, qw/-c protocol.file.allow=always submodule add -q/, $dir, 'sm');
    run_git($super, qw/commit -q -m/, 'Add submodule');

    my $sm = Review::Helper::VCS->detect("$super/sm");
    is($sm->root, "$super/sm", 'submodule worktree');

    my $sm_dir = $sm->state_dir;
    like($sm_dir, qr{/\.git/modules/sm/review-helper\z}, 'its git directory is inside the superproject');
    mkdir($sm_dir);
    my $inside = Review::Helper::VCS->detect("$sm_dir/x.sqlite");
    is($inside->root,    "$super/sm",              'root from inside a submodule git directory');
    is($inside->git_dir, "$super/.git/modules/sm", 'its git dir');

    my $sup  = Review::Helper::VCS->detect($super);
    my $head = $sup->resolve('HEAD');
    is(
        $sup->range_changes($sup->parents($head)->[0] // $sup->empty_revision, $head),
        [
            {path => '.gitmodules', old_path => undef, status => 'A', added => 3, removed => 0, binary => 0, submodule => 0},
            {path => 'sm',          old_path => undef, status => 'A', added => 1, removed => 0, binary => 0, submodule => 1},
        ],
        'a submodule entry is marked',
    );
    is($sup->file($head, 'sm'), undef, 'a submodule has no blob');
};

my $repo = Review::Helper::VCS->detect($dir);

subtest git => sub {
    is($repo->_git(qw/rev-parse HEAD/), "$third\n", 'returns stdout');
    like(dies { $repo->_git(qw/not-a-command/) }, qr/git not-a-command failed: .*not a git command/s, 'dies with stderr');

    run_git($dir, qw/config diff.noprefix true/);
    like(commit_diff($repo, $second, 'a.txt'), qr{^--- a/a\.txt$}m, 'repository diff config cannot change prefixes');
    run_git($dir, qw/config --unset diff.noprefix/);
};

subtest revisions => sub {
    is($repo->resolve('HEAD'),   $third, 'rev_parse HEAD');
    is($repo->resolve('HEAD~2'), $root,  'rev_parse relative');
    like(dies { $repo->resolve('nope') }, qr/Unknown revision 'nope'/, 'unknown revision croaks');

    ok($repo->has_revision($second),   'has_commit true');
    ok(!$repo->has_revision('0' x 40), 'has_commit false');

    is($repo->revisions($root, $third), [{revision => $second, parents => [$root]}, {revision => $third, parents => [$second]}], 'revisions oldest first, with their parents');

    is($repo->revision_name('HEAD'),  'main', 'a branch names HEAD');
    is($repo->revision_name('main'),  'main', 'a branch names itself');
    is($repo->revision_name($second), undef,  'a sha is no name');
    is($repo->revision_name('--all'), undef,  'an option is no name');
};

subtest state => sub {
    is($repo->state_dir,        "$dir/.git/review-helper", 'state directory in the git directory');
    is($repo->shared_state_dir, "$dir/.git/review-helper", 'shared one in the common directory');

    ok($repo->is_internal_path("$dir/.git/review-helper/x.sqlite"), 'a file in the git directory is internal');
    ok(!$repo->is_internal_path("$dir/x.sqlite"),                   'one in the worktree is not');
    ok(!$repo->is_internal_path("$dir/.git"),                       'nor the git directory itself');
};

subtest revision_info => sub {
    is(
        $repo->revision_info($root),
        {
            revision => $root,
            parent   => undef,
            subject  => 'Root commit',
            message  => "Root commit\n\nWith a body.\n",
            author   => 'Tester <tester@example.com>',
            authored => match qr/^\d+$/,
        },
        'root commit',
    );
    is($repo->revision_info($second)->{parent}, $root, 'first parent');
};

subtest change_id => sub {
    like($repo->change_id($second), qr/^[0-9a-f]{40}$/, 'the change id');
    my $empty = commit_file($dir, 'Empty');
    is($repo->change_id($empty), undef, 'empty commit has no change id');
    run_git($dir, qw/reset -q --hard HEAD~1/);
};

subtest changes => sub {
    is(
        $repo->range_changes($repo->parents($root)->[0] // $repo->empty_revision, $root),
        [
            {path => 'a.txt',   old_path => undef, status => 'A', added => 3, removed => 0, binary => 0, submodule => 0},
            {path => 'img.bin', old_path => undef, status => 'A', added => 0, removed => 0, binary => 1, submodule => 0},
        ],
        'root commit against the empty revision',
    );
    is(
        $repo->range_changes($repo->parents($second)->[0] // $repo->empty_revision, $second),
        [
            {path => 'a.txt',     old_path => undef, status => 'M', added => 2, removed => 1, binary => 0, submodule => 0},
            {path => 'img.bin',   old_path => undef, status => 'D', added => 0, removed => 0, binary => 1, submodule => 0},
            {path => 'lib/b.txt', old_path => undef, status => 'A', added => 1, removed => 0, binary => 0, submodule => 0},
        ],
        'modify, delete, add',
    );
    is(
        $repo->range_changes($repo->parents($third)->[0] // $repo->empty_revision, $third),
        [{path => 'c.txt', old_path => 'a.txt', status => 'R', added => 0, removed => 0, binary => 0, submodule => 0}],
        'rename',
    );
};

subtest ranges => sub {
    is($repo->empty_revision, run_git($dir, qw{hash-object -t tree /dev/null}) =~ s/\n//r, 'empty revision');
    is(
        $repo->range_changes($repo->empty_revision, $third),
        [
            {path => 'c.txt',     old_path => undef, status => 'A', added => 4, removed => 0, binary => 0, submodule => 0},
            {path => 'lib/b.txt', old_path => undef, status => 'A', added => 1, removed => 0, binary => 0, submodule => 0},
        ],
        'a whole tree',
    );
    is([map { $_->{path} } @{$repo->range_changes($root, $third,  ['lib'])}],   ['lib/b.txt'],          'limited by path spec');
    is([map { $_->{path} } @{$repo->range_changes($root, $second, ['*.txt'])}], ['a.txt', 'lib/b.txt'], 'one commit, limited by path spec');
};

subtest diff => sub {
    is(commit_diff($repo, $second, 'a.txt'), <<'EOT', 'fixed-option diff');
diff --git a/a.txt b/a.txt
index 4cb29ea..ea14db2 100644
--- a/a.txt
+++ b/a.txt
@@ -1,3 +1,4 @@
 one
-two
+2
 three
+four
EOT
    like(commit_diff($repo, $root, 'a.txt'), qr{^\+\+\+ b/a\.txt$}m, 'root commit diffs against the empty revision');
    like(commit_diff($repo, $third, 'c.txt', 'a.txt'), qr{^rename from a\.txt$}m, 'rename pairs both paths');

    my $gdir  = make_repo();
    my $gbase = commit_file($gdir, 'Base', 'app/[id]/page.js' => "one\n", 'app/i/page.js' => "other\n");
    my $gsha  = commit_file($gdir, 'Both', 'app/[id]/page.js' => "two\n", 'app/i/page.js' => "else\n");
    my $grepo = Review::Helper::VCS->detect($gdir);
    my $gdiff = commit_diff($grepo, $gsha, 'app/[id]/page.js');
    like($gdiff, qr{^\+two$}m, 'a path with glob characters diffs its own file');
    {
        local @ENV{qw/GIT_LITERAL_PATHSPECS GIT_ICASE_PATHSPECS/} = (1, 1);
        is(commit_diff($grepo, $gsha, 'app/[id]/page.js'), $gdiff, "the user's path spec mode does not reach git");
    }
    unlike($gdiff, qr{app/i/page\.js}, 'and not a sibling its glob would match');
};

subtest file => sub {
    is($repo->file($root,   'img.bin'), "\0\1\2", 'raw bytes');
    is($repo->file($second, 'img.bin'), undef,    'absent at that commit');
    is($repo->file($second, 'lib'),     undef,    'a directory is not a file');

    like($repo->file_id($root, 'a.txt'), qr/^[0-9a-f]{40,64}$/, 'the blob id');
    is($repo->file_id($third, 'c.txt'), $repo->file_id($second, 'a.txt'), 'same content, same id');
    isnt($repo->file_id($root, 'a.txt'), $repo->file_id($second, 'a.txt'), 'other content, other id');
    is($repo->file_id($second, 'img.bin'), undef, 'absent at that commit');
};

subtest pins => sub {
    is($repo->pin_name('abc', 1), 'refs/review-helper/abc/1', 'a pin is a ref');
    $repo->pin($repo->pin_name('abc', $_->[0]), $_->[1]) for [1, $root], [2, $second];
    $repo->pin('refs/review-helper/abcd/1', $root);
    is($repo->pins('abc'),                         ['refs/review-helper/abc/1', 'refs/review-helper/abc/2'], 'pinned, not another review\'s');
    is($repo->resolve('refs/review-helper/abc/1'), $root,                                                    'pin points at the commit');

    $repo->unpin('refs/review-helper/abc/1');
    is($repo->pins('abc'), ['refs/review-helper/abc/2'], 'unpinned');
    $repo->unpin($_) for @{$repo->pins('abc')}, 'refs/review-helper/abcd/1';
};

subtest parents => sub {
    is($repo->parents($second), [$root], 'one parent');
    is($repo->parents($root),   [],      'a root commit has none');
};

subtest resolution => sub {
    my $mdir = make_repo();
    commit_file($mdir, 'Start', 'f.txt' => "a\nb\nc\n");
    run_git($mdir, qw/checkout -q -b side/);
    commit_file($mdir, 'Side', 'f.txt' => "a\nB-side\nc\n");
    run_git($mdir, qw/checkout -q main/);
    commit_file($mdir, 'Main', 'f.txt' => "a\nB-main\nc\n");
    ok(!eval { run_git($mdir, qw/merge -q side/); 1 }, 'the merge conflicts');
    my $merge = commit_file($mdir, 'Merge side', 'f.txt' => "a\nB-both\nc\n");
    my $mrepo = Review::Helper::VCS->detect($mdir);

    is(scalar(@{$mrepo->parents($merge)}),                       2,  'a merge has two parents');
    is($mrepo->resolution_changes($mrepo->parents($merge)->[0]), [], 'a commit that is not a merge has none');
    SKIP: {
        skip 'remerge diffs need git 2.36', 3 unless $mrepo->_has_remerge_diff;
        is($mrepo->resolution_changes($merge),              [{path => 'f.txt', old_path => undef, status => 'M', submodule => 0}], 'the resolved file');
        is($mrepo->resolution_changes($merge, ['nothing']), [],                                                                    'path specs limit it');
        like($mrepo->resolution_diff($merge, 'f.txt'), qr/^-<<<<<<< .*^\+B-both$/ms, 'the diff runs from the conflict to the resolution');
    }

    my $old = mock 'Review::Helper::VCS::Git' => (override => [_git => sub ($self, @args) { "git version 2.35.4\n" }]);
    ok(!Review::Helper::VCS->detect($mdir)->_has_remerge_diff, 'git 2.35 has none');
    is(Review::Helper::VCS->detect($mdir)->resolution_changes($merge), [], 'so a merge shows no resolutions');
};

subtest running_git => sub {
    my $rdir     = make_repo();
    my $bytes    = "\xff\xfe\0caf\xc3\xa9\n";
    my $revision = commit_file($rdir, 'Bytes', 'raw.bin' => $bytes);
    my $rrepo    = Review::Helper::VCS->detect($rdir);

    binmode(STDOUT, ':encoding(UTF-8)');
    binmode(STDERR, ':encoding(UTF-8)');
    my $got = $rrepo->file($revision, 'raw.bin');
    binmode(STDOUT);
    binmode(STDERR);
    is($got, $bytes, 'output is raw bytes whatever layers STDOUT and STDERR carry');

    {
        local *STDERR;
        open(STDERR, '>', \my $mem) or die "open: $!";
        like(dies { $rrepo->_git(qw/cat-file -t nope/) },                        qr/failed: fatal: .*nope/,                                         "git's errors are captured when STDERR is not descriptor 2");
        like(dies { local $ENV{PATH} = '/nonexistent'; $rrepo->_git('status') }, qr/git status failed: exec git failed: No such file or directory/, 'a git that cannot run says so on descriptor 2');
        is($mem, undef, 'and not written to the in-memory STDERR');
    }

    {
        # The error file lands on descriptor 0 when the parent has it closed.
        my $save = POSIX::dup(0) // die "dup: $!";
        POSIX::close(0);
        my $err = dies { $rrepo->_git(qw/cat-file -t nope/) };
        POSIX::dup2($save, 0) // die "dup2: $!";
        POSIX::close($save);
        like($err, qr/failed: fatal: .*nope/, "git's errors are captured when descriptor 0 is closed");
    }

    {
        my $real = \&POSIX::dup2;
        my $mock = mock POSIX => (override => [dup2 => sub ($from, $to) { $to == 0 ? undef : $real->($from, $to) }]);
        like(dies { $rrepo->_git('status') }, qr/git status failed: cannot set up git's input/, 'a failure setting up descriptors is not reported as a failed exec');
    }

    {
        local *STDIN;
        open(STDIN, '<', \"") or die "open: $!";
        like($rrepo->change_id($revision), qr/^[0-9a-f]{40}$/, 'input reaches git when STDIN is not descriptor 0');
    }

    run_git($rdir, qw/config --unset user.name/);
    run_git($rdir, qw/config --unset user.email/);
    my $home = abs_path(tempdir(CLEANUP => 1));
    TestRepo::write_file($home, '.gitconfig', "[user]\n\tname = Global Person\n");
    local $ENV{HOME} = $home;
    delete local $ENV{GIT_CONFIG_GLOBAL};
    is($rrepo->user, 'Global Person', "user reads the user's own configuration");
    like(dies { $rrepo->_git(qw/config --get user.name/) }, qr/failed/, 'other git runs do not');
};

done_testing;
