# Derived from System-Command/t/10-command.t which is
# copyright Phillipe Bruhat (BooK).
use strict;
use warnings;
use utf8;
use Cwd qw/cwd abs_path/;
use File::Spec;
use File::Temp qw/tempdir/;
use Sys::Cmd qw/spawn run/;
use Test::More;

use constant MSWin32 => $^O eq 'MSWin32';

$ENV{TO_BE_DELETED} = 'LATER';
{
    # Environment variables are not passed in and out of Perl like
    # string scalars so make sure they stay as bytes.
    no utf8;
    $ENV{UTF8_CHECK} = 'Défaut';
}

my $dir   = abs_path( tempdir( CLEANUP => 1 ) );
my $cwd   = cwd;
my $name  = File::Spec->catfile( t => 'info.pl' );
my @tests = (
    {
        test    => 'standard',
        cmdline => [ $^X, $name ],
        options => {},
    },
    {
        test    => 'env',
        cmdline => [ $^X, $name, { env => { SYS_CMD => 'Sys::Cmd' } } ],
        options => { env => { SYS_CMD => 'Sys::Cmd' } },
    },
    {
        test    => 'dir',
        cmdline => [
            $^X,
            File::Spec->catfile( $cwd => $name ),
            { dir => $dir, env => { SYS_CMD => 'Sys::Cmd' } },
        ],
        name    => File::Spec->catfile( $cwd => $name ),
        options => {
            env => { SYS_CMD => 'Sys::Cmd' },
            dir => $dir,
        },
    },
    {
        test    => 'delete env',
        cmdline => [
            $^X, $name,
            {
                env => {
                    SYS_CMD       => 'Sys::Cmd',
                    TO_BE_DELETED => undef,
                    OTHER_ENV     => 'something else',
                }
            },
        ],
        options => {
            env => {
                OTHER_ENV     => 'something else',
                SYS_CMD       => 'Sys::Cmd',
                TO_BE_DELETED => undef,
            }
        },
    },
    {
        test    => 'input',
        cmdline => [
            $^X, $name,
            { env => { 'SYS_CMD_INPUT' => 1 }, input => 'test input' }
        ],
        options => { env => { 'SYS_CMD_INPUT' => 1 }, input => 'test input' }
    },
    {
        test    => 'empty input',
        cmdline => [
            $^X, $name,
            {
                env   => { 'SYS_CMD_INPUT' => 1, 'TO_BE_DELETED' => undef },
                input => ''
            }
        ],
        options => {
            env   => { 'SYS_CMD_INPUT' => 1, 'TO_BE_DELETED' => undef },
            input => ''
        }
    },
);
my @fail = (
    {
        test => 'chdir fail',
        cmdline =>
          [ $^X, $name, { dir => File::Spec->catdir( $dir, 'nothere' ) } ],
        fail    => qr/^Failed to change directory/,
        options => {},
    },
    {
        test    => 'command not found',
        cmdline => ['no_command_x77328efe'],
        fail    => qr/^command not found/,
        options => {},
    },
    {
        test    => 'not executable',
        cmdline => [__FILE__],
        fail    => qr/^command not executable/,
        options => {},
    },
    {
        test    => 'execute a directory',
        cmdline => ['t'],
        fail    => qr/^command not found/,
        options => {},
    },
);

for my $t ( @tests, @fail ) {

    subtest $t->{test}, sub {

        # run the command
        my $cmd = eval { spawn( @{ $t->{cmdline} } ) };
        if ( $t->{fail} ) {
            ok( !$cmd,
                    $t->{test}
                  . ': command failed: '
                  . ( defined $cmd ? $cmd : '' ) );
            like( $@, $t->{fail}, $t->{test} . ': expected error message' );
            return;
        }
        die $@ if $@;

        isa_ok( $cmd, 'Sys::Cmd' );

        # test the handles
        for my $handle (qw( stdin stdout stderr )) {
            isa_ok( $cmd->$handle, 'IO::Handle' );
            if ( $handle eq 'stdin' ) {
                my $opened = !exists $t->{options}{input};
                is( $cmd->$handle->opened, $opened,
                    "$t->{test}: $handle @{[ !$opened && 'not ']}opened" );
            }
            else {
                ok( $cmd->$handle->opened, "$t->{test}: $handle opened" );
            }
        }

        is_deeply(
            [ $cmd->cmdline ],
            [ grep { !ref } @{ $t->{cmdline} } ],
            $t->{test} . ': cmdline'
        );

        # get the output
        my $output = join '', $cmd->stdout->getlines();
        my $errput = join '', $cmd->stderr->getlines();
        is( $errput, '', $t->{test} . ': no errput' );

        my $env = { %ENV, %{ $t->{options}{env} || {} } };
        if ( exists $t->{options}->{dir} and $^O eq 'MSWin32' ) {
            $env->{PWD} = $t->{options}->{dir};
        }
        delete $env->{$_}
          for grep { !defined $t->{options}{env}{$_} }
          keys %{ $t->{options}{env} || {} };
        my $info;
        eval $output;
        is_deeply(
            $info,
            {
                argv  => [],
                cwd   => lc( $t->{options}{dir} || $cwd ),
                env   => $env,
                input => $t->{options}{input} || '',
                pid   => $cmd->pid,
            },
            "$t->{test}: perl $name"
        );

        # close and check
        $cmd->close();
        $cmd->wait_child();
        is( $cmd->exit,   0, $t->{test} . ': exit 0' );
        is( $cmd->signal, 0, $t->{test} . ': no signal received' );
        is( $cmd->core, $t->{core} || 0, $t->{test} . ': no core dumped' );
    };
}

subtest 'reaper', sub {
    my $proc2 = spawn($^X);
    my $proc  = spawn(
        $^X,
        {
            on_exit => sub { kill 9, $proc2->pid }
        }
    );

    kill 9, $proc->pid;
    $proc->wait_child;
    $proc2->wait_child;

    ok( ( defined $proc2->exit ),
        'reaper: reaper worked on PID ' . $proc2->pid );
    ok( ( defined $proc->exit ), 'reaper: reaper worked on PID ' . $proc->pid );

  SKIP: {
        skip 'signals do not work on Win32', 1 if $^O eq 'MSWin32';

        is $proc->signal,  9, 'matching signal PID ' . $proc->pid;
        is $proc2->signal, 9, 'matching signal PID ' . $proc2->pid;
    }

};

SKIP: {
    skip "coderefs not supported on Win32", 1 if $^O eq 'MSWin32';

    subtest 'coderef', sub {

        my $proc = spawn(
            sub {
                while ( my $line = <STDIN> ) {
                    print STDOUT $line;
                }
                exit 3;
            }
        );

        foreach my $i ( 1 .. 10, 'Zürich' ) {
            $proc->stdin->print( $i . "\n" );
            my $res = $proc->stdout->getline;
            chomp $res;
            is $res, $i, "coderef: echo $i";
        }

        $proc->close;
        $proc->wait_child;
        is $proc->exit, 3, 'coderef: exit 3';
    };
}

done_testing();
