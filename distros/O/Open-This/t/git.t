use strict;
use warnings;

use Carp::Always;
use Open::This qw( maybe_get_url_from_parsed_text );
use Path::Tiny qw( path tempdir );
use Test::More import => [qw( done_testing is like ok skip )];
use Test::Needs qw( Git::Helpers Git::Sub );
use Test::Requires::Git;
use URI ();

test_requires_git();

# A hook's GIT_DIR would point git at another repo
delete local @ENV{qw( GIT_DIR GIT_WORK_TREE )};

# A build dir (e.g. dzil's .build) sits inside the checkout but is uncommitted
my $committed = Git::Helpers::is_inside_work_tree() && eval {
    my @hits = git::ls_tree(qw( --name-only HEAD -- lib/Open/This.pm ));
    @hits == 1;
};

SKIP: {
    skip 'lib/Open/This.pm must be committed on HEAD of a Git checkout', 5
        unless $committed;

    local $ENV{OPEN_THIS_REMOTES} = q{};

    is( maybe_get_url_from_parsed_text(),     undef, 'undef on undef' );
    is( maybe_get_url_from_parsed_text( {} ), undef, 'undef on empty hash' );

    my $url = maybe_get_url_from_parsed_text(
        { file_name => 'lib/Open/This.pm' } );
    ok( $url, 'got url' );
    my $uri = URI->new($url);
    ok( $uri->path =~ m{lib/Open/This.pm\z}, 'path' );
    is( $uri->scheme, 'https', 'scheme' );
}

{
    my $cwd = path('.')->absolute;
    my $tmp = tempdir();

    # Keep outside.pm outside any repo even when TMPDIR is in a checkout
    local $ENV{GIT_CEILING_DIRECTORIES} = $tmp->parent->stringify;

    # Windows forbids ':' in file names, and its filename bytes are unreliable
    my $windows   = $^O eq 'MSWin32';
    my $cafe      = "lib/caf\xc3\xa9.pm";
    my @committed = (
        qw( .gitignore lib/Open/This.pm lib/x.pm ),
        $windows ? () : $cafe
    );

    my %remote = ( repo => 'Orig', other => 'Other' );
    for my $name ( sort keys %remote ) {
        my $repo = $tmp->child($name);
        $repo->child('lib/Open')->mkpath;
        $repo->child($_)->spew('1;')
            for @committed,
            qw( lib/Untracked.pm lib/Ignored.pm lib/Staged.pm ),
            $windows ? () : 'lib/:x.pm';
        $repo->child('.gitignore')->spew("lib/Ignored.pm\n");
        chdir $repo or die "chdir $repo: $!";
        for my $cmd (
            [qw( git init -q )],
            [ qw( git symbolic-ref HEAD ), "refs/heads/$name" ],
            [ qw( git add -- ),            @committed ],
            [
                qw( git -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q -m init )
            ],
            [qw( git add lib/Staged.pm )],
            [
                qw( git remote add origin ),
                "https://github.com/$remote{$name}/repo.git"
            ],
        ) {
            system(@$cmd) == 0 or die "@$cmd failed";
        }
    }
    $tmp->child('outside.pm')->spew('1;');

    my $repo = $tmp->child('repo');
    chdir $repo or die "chdir $repo: $!";
    system(qw( git remote add upstream git@github.com:Up/repo.git )) == 0
        or die 'git remote add failed';

    for my $case (
        [ q{},               qr{^/Orig/repo/blob/} ],
        [ 'nope',            qr{^/Orig/repo/blob/} ],
        [ 'upstream',        qr{^/Up/repo/blob/} ],
        [ 'nope,upstream',   qr{^/Up/repo/blob/} ],
        [ 'origin,upstream', qr{^/Orig/repo/blob/} ],
    ) {
        my ( $remotes, $expected ) = @$case;
        local $ENV{OPEN_THIS_REMOTES} = $remotes;
        my $current_url = maybe_get_url_from_parsed_text(
            { file_name => 'lib/Open/This.pm' } );
        like(
            URI->new($current_url)->path, $expected,
            "OPEN_THIS_REMOTES='$remotes'"
        );
    }

    local $ENV{OPEN_THIS_REMOTES} = q{};
    my $lib = $repo->child('lib');
    chdir $lib or die "chdir $lib: $!";
    my $expected = 'https://github.com/Orig/repo/blob/repo/lib/Open/This.pm';
    for my $file_name (
        'Open/This.pm', '../lib/Open/This.pm',
        $lib->child('Open/This.pm')->stringify
    ) {
        is(
            maybe_get_url_from_parsed_text( { file_name => $file_name } ),
            $expected, "$file_name maps to its path from the repo root"
        );
    }
    is( path('.')->realpath, $lib->realpath, 'cwd is restored' );

    # A hostile checkout's fsmonitor hook must not run
    my $marker = $tmp->child('fsmonitor-ran');
    system(
        qw( git -C ../../other config core.fsmonitor ),
        "echo >'$marker'"
        ) == 0
        or die 'git config failed';

    # Control: the hook must fire for ls-files, or its absence proves nothing
    system(qw( git -C ../../other ls-files -- no-such-file ));
    my $hook_fires = -e $marker;
    unlink $marker;
    is(
        maybe_get_url_from_parsed_text(
            { file_name => '../../other/lib/Open/This.pm' }
        ),
        'https://github.com/Other/repo/blob/other/lib/Open/This.pm',
        'file in another checkout uses its remote and branch'
    );
SKIP: {
        skip 'fsmonitor hook does not fire here', 1 unless $hook_fires;
        ok( !-e $marker, 'fsmonitor hook did not run' );
    }

SKIP: {
        skip 'filename bytes are unreliable on Windows', 1 if $windows;
        is(
            maybe_get_url_from_parsed_text( { file_name => "../$cafe" } ),
            'https://github.com/Orig/repo/blob/repo/lib/caf%C3%A9.pm',
            'non-ASCII file name'
        );
    }

    # Without a literal pathspec, :x.pm would match the committed x.pm
    for my $file_name (
        'Untracked.pm', 'Ignored.pm', 'Staged.pm',
        ( $windows ? () : ':x.pm' ),
        '../../outside.pm', 'no-such.pm'
    ) {
        is(
            maybe_get_url_from_parsed_text( { file_name => $file_name } ),
            undef, "no URL for $file_name"
        );
    }

    chdir $cwd or die "chdir $cwd: $!";
}

done_testing();
