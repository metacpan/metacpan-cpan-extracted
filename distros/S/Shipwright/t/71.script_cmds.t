use strict;
use warnings;


use Test::More;

if ( ! $ENV{SHIPWRIGHT_TEST_EXTRA} ) {
    plan skip_all => 'SHIPWRIGHT_TEST_EXTRA is not set';
}

use Shipwright;
use Shipwright::Util;
use Shipwright::Test;
use File::Spec::Functions qw/catdir tmpdir/;
use File::Path qw/remove_tree/;
use Cwd qw/getcwd/;
my $sw  = Shipwright::Test->shipwright_bin;
my $cwd = getcwd;

Shipwright::Test->init;

my $install_base = catdir( tmpdir(), 'vessel_71_scripts_cmds' );
my $build_base   = catdir( tmpdir(), 'shipwright_build_71_scripts_cmds' );
{

    # fs backend
    start_test( 'fs:' . create_fs_repo() );
}

SKIP: {
    skip "git: no git found or env SHIPWRIGHT_TEST_GIT not set", ( $^O =~
        /MSWin/ ? 32 : 33 )
      if skip_git();
    start_test( 'git:' . create_git_repo() );
}

SKIP: {
    skip "svn: no svn found or env SHIPWRIGHT_TEST_SVN not set", ( $^O =~
        /MSWin/ ? 34 : 35 )
      if skip_svn();

    my $repo = 'svn:' . create_svn_repo() . '/hello';

    my $source = create_svn_repo() . '/foo';    # svn source we'll import

    run_cmd(
        [
            $ENV{'SHIPWRIGHT_SVN'}, 'import',
            '-m',                   q{''},
            't/dists/version1',     $source
        ]
    );

    my $update_cmd = [
        $ENV{'SHIPWRIGHT_SVN'}, 'import',
        '-m',                   q{''},
        't/dists/version2',     $source . '/version2'
    ];
    start_test( $repo, "svn:$source", $update_cmd );
}

SKIP: {
    skip "svk: no svk found or env SHIPWRIGHT_TEST_SVK not set", ( $^O =~
        /MSWin/ ? 34 : 35 )
      if skip_svk();

    create_svk_repo();

    my $repo   = 'svk://__shipwright/hello';
    my $source = '//foo';
    run_cmd(
        [
            $ENV{'SHIPWRIGHT_SVK'}, 'import',
            '-m',                   q{''},
            't/dists/version1',     $source
        ]
    );

    start_test( $repo, "svk:$source" );

}

sub start_test {
    my $repo       = shift;
    my $source     = shift;    # the svn or svk dist source
    my $update_cmd = shift;

    # test create
    my @cmds = (

        # create hello repo
        [ ['create', '-f'], qr/successfully created/, "create $repo" ],

        # non exist cmd
        [
            [ 'obra', ],
            undef, undef,
            qr/Command not recognized/,
            "non exist cmd",
        ],

        # list cmd
        [ [ 'list', ], qr/^\s*$/, "list null $repo" ],
        [
            [ 'list', 'foo' ],
            qr/foo doesn't exist/,
            "list non exist name $repo"
        ],

        # import cmd
        [
            [ 'import', ],
            undef, undef,
            qr/need source arg/,
            'import without source ...'
        ],
        [
            [ 'import', 'file:t/hello/Foo-Bar-v0.01.tar.gz', '--no-follow' ],
            qr/successfully imported/,
            'import tar.gz file',
        ],

        # here we has a dist named Foo-Bar
        [
            [ 'list', ],
            qr{Foo-Bar:\s+
        version:\s+vendor:\s+0\.01\s+
        from:\s+vendor:\s+\Qfile:t/hello/Foo-Bar-v0.01.tar.gz\E\s+
        references:\s+0\s+
            }mx,
            'list the repo'
        ],

        # rename cmd
        [
            [ 'rename', 'Foo-Bar', 'foo' ],
            qr/successfully renamed Foo-Bar to foo/
        ],

        # now Foo-Bar is renamed to foo
        [
            [ 'list', ],
            qr{foo:\s+
        version:\s+vendor:\s+0\.01\s+
        from:\s+vendor:\s+\Qfile:t/hello/Foo-Bar-v0.01.tar.gz\E\s+
        references:\s+0\s+
            }mx,
            'list the repo'
        ],

        # invalid rename cmds
        [ [ 'rename', 'foo' ], undef, undef, qr/need new-name arg/ ],
        [
            ['rename'], undef,
            undef,      qr/need name arg/,
            "rename without name arg"
        ],
        [
            [ 'rename', 'foo' ],
            undef, undef,
            qr/need new-name arg/,
            "rename without new-name arg"
        ],
        [
            [ 'rename', 'Foo-Bar', '@' ],
            undef,
            undef,
            qr/invalid new-name: @/,
            'rename with invalid new-name'
        ],
        [
            [ 'rename', 'NonExist', 'foo' ],
            undef,
            undef,
            qr/no such dist: NonExist/,
            'rename nonexist dist'
        ],

        # delete cmd
        [ [ 'delete', 'foo' ], qr/successfully deleted foo/, 'deleted foo' ],

        # we don't have foo dist any more
        [ [ 'list', 'foo' ], qr/foo doesn't exist/, "foo is deleted" ],

        # import dists/dir_configure
        [
            [ 'import', 'dir:t/dists/dir_configure', '--version', 3.14 ],
            qr/successfully imported/,
            'imported dists_dir_configure',
        ],
        [
            [ 'ls', 'dir_configure' ],

            qr{dir_configure:\s+ 
              version:\s+vendor:\s+3\.14\s+
              from:\s+vendor:\s+\Qdirectory:\E.*?\Qt/dists/dir_configure\E\s+
              references:\s+0\s+
            }mx,
            'list dir_configure, --version arg works too',
        ],

        # import dists/tgz_build.tar.gz
        [
            [
                'import',    'file:t/dists/tgz_build.tar.gz',
                '--version', 2.72,
                '--no-follow',
            ],
            qr/successfully imported/,
            'imported tgz_build',
        ],
        [
            [ 'ls', 'tgz_build' ],
            qr{tgz_build:\s+ 
              version:\s+vendor:\s+2\.72\s+
              from:\s+vendor:\s+\Qfile:t/dists/tgz_build.tar.gz\E\s+
              references:\s+0\s+
            }mx,
            'list tgz_build, --version arg works too',
        ],

        # import dists/tbz_make.tar.bz
        [
            [ 'import', 'file:t/dists/tbz_make.tar.bz2', '--no-follow' ],
            qr/successfully imported/,
            'imported tbz_make',
        ],
        [
            [ 'ls', 'tbz_make' ],
            qr{tbz_make:\s+ 
              version:\s+vendor:\s+
              from:\s+vendor:\s+\Qfile:t/dists/tbz_make.tar.bz2\E\s+
              references:\s+0\s+
            }mx,
            'list tgz_make',
        ],

        # set flags dir_configure to 'configure'
        [
            [ 'flags', 'dir_configure', ],
            qr/flags of dir_configure are \*nothing\*/,
            'default is no flags',
        ],
        [
            [ 'flags', 'dir_configure', '--set', 'configure,foo', ],
qr/successfully set flags\s+flags of dir_configure are configure, foo/,
            'successfully set flags',
        ],
        [
            [ 'flags', 'dir_configure', '--add', 'bar', ],
qr/successfully set flags\s+flags of dir_configure are bar, configure, foo/,
            'add flags to dir_configure',
        ],
        [
            [ 'flags', 'dir_configure', '--delete', 'foo,bar', ],
            qr/successfully set flags\s+flags of dir_configure are configure/,
            'delete flags to dir_configure',
        ],
        [
            [ 'flags', 'tgz_build', '--set', 'build' ],
            qr/successfully set flags\s+flags of tgz_build are build/,
            'set flags to tgz_build',
        ],
        [
            [ 'flags', 'man1', '--set', 'build', '--mandatory' ],
qr/successfully set mandatory flags\s+mandatory flags of man1 are build/,
            'set mandatory flag man1',
        ],
        [
            [ 'build', '--install-base', $install_base, '--verbose', '--skip-test' ],
            qr/run, run, Build\.PL.*run, run, Makefile\.PL/ms,
            'Build.PL and Makefile.PL are run',
        ],
        [
            [ 'update', '--builder' ],
            qr/successfully updated/,
            "updated builder",
        ],
        [
            [ 'update', '--utility' ],
            qr/successfully updated/,
            "updated utility",
        ],
        $^O =~ /MSWin/
        ? ()
        : [
            [
                'build',       '--flags',
                'configure',   '--install-base',
                $install_base, '--verbose',
                '--skip-test',
            ],
            qr/run, run, configure/,
            'configure is run',
        ],
        $source ? (

            # import an svn or svk dist named foo
            [
                [ 'import', $source ],
                qr/successfully imported/,
                "imported $source",
            ],
            $update_cmd,    # if the source dist is svk, $update_cmd is undef
                            # update cmd
            [ [ 'update', 'foo' ], qr/successfully updated/, "updated foo", ],
          )
        : (),
    );

    for my $item (@cmds) {
        next unless $item;    # update_cmd can be undef

        if ( ref $item->[0] eq 'ARRAY' ) {
            my $cmd = shift @{ $item->[0] };
            if ( $cmd eq 'build' ) {

               # it's not really a build cmd, we need to export first, cd to it,
               # then run bin/shipwright-builder
                my $shipwright = Shipwright->new( repository => $repo );
                $shipwright->backend->export( target => $build_base );
                chdir $build_base;
                test_cmd(
                    [
                        $^X, 'bin/shipwright-builder',
                        @{ $item->[0] },
                    ],
                    @$item[ 1 .. $#$item ],
                );
                chdir $cwd;
                remove_tree($install_base);
                remove_tree($build_base);
            }
            else {
                test_cmd(
                    [ $^X, $sw, $cmd, '-r', $repo, @{ $item->[0] }, ],
                    @$item[ 1 .. $#$item ],
                );
            }
        }
        else {

            # for the update_cmd
            run_cmd( $item, 1 );
        }
    }
}

done_testing;
