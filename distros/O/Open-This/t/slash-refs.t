use strict;
use warnings;

use Open::This        qw( to_editor_args );
use Path::Tiny        qw( path tempdir );
use Test::Differences qw( eq_or_diff );
use Test::More import => [qw( done_testing is )];
use Test::Requires::Git;
use Test::Warnings ();

test_requires_git();

local $ENV{EDITOR} = 'vim';

# A hook's GIT_DIR would point git at another repo
delete local @ENV{qw( GIT_DIR GIT_WORK_TREE )};

# A pasted URL can't say where a ref like "feature/x" ends, so git decides
my $repo = tempdir();
$repo->child('lib')->mkpath;
$repo->child('lib/Foo.pm')->spew('1;');

my $cwd = path('.')->absolute;

# CI has no git identity, and both the commit and the annotated tag need one
local @ENV{
    qw( GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL )
} = qw( t t@t t t@t );
chdir $repo or die "chdir $repo: $!";
for my $cmd (
    [qw( init -q )],
    [qw( -c commit.gpgsign=false commit -q --allow-empty -m init )],
    [qw( branch feature/x )],
    [qw( branch release/2026/q1 )],
    [qw( -c tag.gpgsign=false tag -a -m rel rel/1 )],
    [qw( update-ref refs/remotes/origin/feature/y HEAD )],
) {
    system( 'git', @$cmd ) == 0 or die "git @$cmd failed";
}

my @cases = (
    [
        'https://github.com/o/r/blob/feature/x/lib/Foo.pm#L5',
        [ '+5', 'lib/Foo.pm' ],
        'GitHub ref with a slash'
    ],
    [
        'https://gitlab.com/g/r/-/blob/feature/x/lib/Foo.pm#L5',
        [ '+5', 'lib/Foo.pm' ],
        'GitLab ref with a slash'
    ],
    [
        'https://codeberg.org/o/r/src/branch/feature/x/lib/Foo.pm#L5',
        [ '+5', 'lib/Foo.pm' ],
        'Codeberg ref with a slash'
    ],
    [
        'https://bitbucket.org/o/r/src/feature/x/lib/Foo.pm#lines-5',
        [ '+5', 'lib/Foo.pm' ],
        'Bitbucket ref with a slash'
    ],
    [
        'https://git.sr.ht/~o/r/tree/feature/x/item/lib/Foo.pm#L5',
        [ '+5', 'lib/Foo.pm' ],
        'SourceHut ref with a slash'
    ],
    [
        'https://github.com/o/r/blob/release/2026/q1/lib/Foo.pm#L5',
        [ '+5', 'lib/Foo.pm' ],
        'ref with two slashes'
    ],
    [
        'https://codeberg.org/o/r/src/tag/rel/1/lib/Foo.pm#L5',
        [ '+5', 'lib/Foo.pm' ],
        'tag with a slash'
    ],
    [
        'https://github.com/o/r/blob/feature/y/lib/Foo.pm#L5',
        [ '+5', 'lib/Foo.pm' ],
        'branch with a slash that only exists on origin'
    ],
    [
        'https://github.com/o/r/blob/nope/x/lib/Foo.pm',
        [],
        'unknown ref does not shorten the path to another file'
    ],
);

for my $case (@cases) {
    my ( $url, $expected, $name ) = @$case;
    eq_or_diff( [ to_editor_args($url) ], $expected, $name );
}

# Outside a repo git can't vouch for the ref, so the URL names no file
my $no_repo = tempdir();
$no_repo->child('lib')->mkpath;
$no_repo->child('lib/Foo.pm')->spew('1;');
chdir $no_repo or die "chdir $no_repo: $!";
{
    local $ENV{GIT_CEILING_DIRECTORIES} = $no_repo->parent->stringify;

    # git's "not a git repository" must not reach the terminal, and STDERR
    # must work again afterwards
    my $err = $no_repo->child('stderr');
    open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
    open STDERR,    '>',  "$err"   or die "redirect STDERR: $!";
    my @got;
    my $died = eval {
        @got = to_editor_args(
            'https://github.com/o/r/blob/feature/x/lib/Foo.pm');
        1;
    } ? q{} : $@;
    my $git_said = $err->slurp;
    print STDERR 'restored';
    open STDERR, '>&', $saved or die "restore STDERR: $!";

    is( $died, q{}, 'no exception outside a repo' );
    eq_or_diff( \@got, [], 'slash ref outside a repo names no file' );
    is( $git_said,   q{},        'git stays quiet outside a repo' );
    is( $err->slurp, 'restored', 'STDERR works again afterwards' );
}

chdir $cwd or die "chdir $cwd: $!";

done_testing();
