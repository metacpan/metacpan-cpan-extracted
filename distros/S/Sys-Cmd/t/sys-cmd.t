# Derived from System-Command/t/10-command.t which is
# copyright Phillipe Bruhat (BooK).
use v5.18;
use warnings;
use utf8;
use Cwd qw/cwd abs_path/;
use Encode::Locale '$ENCODING_LOCALE';
use Encode 'encode';
use File::Spec;
use File::Temp qw/tempdir/;
use Sys::Cmd ':all';
use Test2::V0;

use constant MSWin32 => $^O eq 'MSWin32';

diag "Test locale is '$ENCODING_LOCALE'";

my $no_utf8 = $ENCODING_LOCALE !~ m/UTF-8/;
my $dir     = abs_path( tempdir( CLEANUP => 1 ) );
my $cwd     = cwd;
my @info_pl = ( $^X, File::Spec->catfile( $cwd, 't', 'info.pl' ) );

$ENV{TO_BE_DELETED} = 'LATER';
$ENV{WIDE_CHAR}     = encode( locale => '✅' ) unless $no_utf8;

my @tests = (
    {
        test    => 'standard',
        cmdline => [@info_pl],
        result  => {},
    },
    {
        test    => 'arguments UTF-8',
        no_utf8 => $no_utf8,
        cmdline => [ @info_pl, 'ß' ],
        result  => {},
    },
    {
        test    => 'env',
        cmdline => [
            @info_pl,
            {
                env => {
                    SYS_CMD => 'Sys::Cmd',
                }
            }
        ],
        result => {
            env => {
                SYS_CMD => 'Sys::Cmd',
            }
        },
    },
    {
        test    => 'env UTF-8',
        no_utf8 => $no_utf8,
        cmdline => [
            @info_pl,
            {
                env => {
                    UTF8_CHECK => 'Défaut',
                }
            }
        ],
        result => {
            env => {
                UTF8_CHECK => 'Défaut',
            }
        },
    },
    {
        test    => 'dir',
        cmdline =>
          [ @info_pl, { dir => $dir, env => { SYS_CMD => 'Sys::Cmd' } }, ],
        result => {
            env => { SYS_CMD => 'Sys::Cmd' },
            dir => $dir,
        },
    },
    {
        test    => 'delete env',
        cmdline => [
            @info_pl,
            {
                env => {
                    SYS_CMD       => 'Sys::Cmd',
                    TO_BE_DELETED => undef,
                    OTHER_ENV     => 'something else',
                }
            },
        ],
        result => {
            env => {
                OTHER_ENV     => 'something else',
                SYS_CMD       => 'Sys::Cmd',
                TO_BE_DELETED => undef,
            }
        },
    },
    {
        test    => 'empty input',
        cmdline => [
            @info_pl,
            {
                env => {
                    'SYS_CMD_INPUT' => 1,
                    'TO_BE_DELETED' => undef,
                },
                input => ''
            }
        ],
        result => {
            env => {
                'SYS_CMD_INPUT' => 1,
                'TO_BE_DELETED' => undef,
            },
            input => ''
        }
    },
    {
        test    => 'input scalar',
        cmdline => [
            @info_pl, { env => { 'SYS_CMD_INPUT' => 1 }, input => 'test input' }
        ],
        result => {
            env   => { 'SYS_CMD_INPUT' => 1 },
            input => 'test input',
        }
    },
    {
        test    => 'input list',
        cmdline => [
            @info_pl,
            {
                env   => { 'SYS_CMD_INPUT' => 1 },
                input => [ "line1\n", "line2\n" ],
            }
        ],
        result => {
            env   => { 'SYS_CMD_INPUT' => 1 },
            input => "line1\nline2\n",
        }
    },
    {
        test    => 'error output',
        cmdline => [ @info_pl, { env => { SYS_CMD_ERR => 'Meh!' } } ],
        result  => { err => "Meh!\n" },
    },
    {
        test    => 'kitchen sink',
        cmdline => [
            @info_pl, 'a', 'b', 1300,
            {
                env => {
                    'SYS_CMD_INPUT' => 1,
                    TO_BE_DELETED   => undef,
                    SYS_CMD_ERR     => 'Meh!',
                },
                input => 'test input',
                dir   => $dir,
            }
        ],
        result => {
            argv => [ 'a', 'b', 1300 ],
            dir  => $dir,
            env  => {
                'SYS_CMD_INPUT' => 1,
                TO_BE_DELETED   => undef,
            },
            err   => "Meh!\n",
            input => 'test input',
        }
    },
);

my @fail = (
    {
        test    => 'chdir fail',
        cmdline =>
          [ @info_pl, { dir => File::Spec->catdir( $dir, 'nothere' ) } ],
        fail   => qr/directory not found/,
        result => {},
    },
    {
        test    => 'command not found',
        cmdline => ['no_command_x77328efe'],
        fail    => qr/^command not found/,
        result  => {},
    },
    {
        test    => 'not executable',
        cmdline => [__FILE__],
        fail    => qr/^command not executable/,
        result  => {},
    },
    {
        test    => 'execute a directory',
        cmdline => ['t'],
        fail    => qr/^command not found/,
        result  => {},
    },
);

sub do_test {
    my $t     = shift;
    my @argv  = grep { !ref } @{ $t->{cmdline} };
    my ($opt) = grep { ref } @{ $t->{cmdline} };

    # run the command

    my $proc = eval { spawn( @{ $t->{cmdline} } ) };
    if ( $t->{fail} ) {
        ok( !$proc,
                $t->{test}
              . ': command failed: '
              . ( defined $proc ? $proc : '' ) );
        like( $@, $t->{fail}, $t->{test} . ': expected error message' );
        return;
    }
    die $@ if $@;

    isa_ok( $proc, 'Sys::Cmd::Process' );

    # test the handles
    for my $handle (qw( stdin stdout stderr )) {
        isa_ok( $proc->$handle, 'IO::Handle' );
        if ( $handle eq 'stdin' ) {
            my $opened = !exists $t->{result}{input};
            is( $proc->$handle->opened,
                $opened, "$t->{test}: $handle @{[ !$opened && 'not ']}opened" );
        }
        else {
            ok( $proc->$handle->opened, "$t->{test}: $handle opened" );
        }
    }

    is( [ $proc->cmdline ], \@argv, $t->{test} . ': cmdline ' . "@argv" );

    # Set @argv to just the script arguments
    shift @argv;
    shift @argv;

    # get the outputs
    my $errput = join '', $proc->stderr->getlines();
    is( $errput, $t->{result}->{err} // '', $t->{test} . ': stderr match' );

    my $output = join '', $proc->stdout->getlines();
    ok( !!$output, $t->{test} . ': stdout returned something' ) || return;

    my $info;
    eval $output;
    die $@ if $@;
    ok( !!$info, $t->{test} . ': output parses to $info' );

    is( $info->{argv}, \@argv, $t->{test} . ": argument match @argv" );

    {
        local %ENV = %ENV;
        while ( my ( $key, $val ) = each %{ $opt->{env} // {} } ) {
            my $keybytes = encode( $ENCODING_LOCALE, $key, Encode::FB_CROAK );
            if ( defined $val ) {
                $ENV{$keybytes} =
                  encode( $ENCODING_LOCALE, $val, Encode::FB_CROAK );
            }
            else {
                delete $ENV{$keybytes};
            }
        }
        if ( exists $t->{result}->{dir} and $^O eq 'MSWin32' ) {
            $ENV{PWD} = $t->{result}->{dir};
        }

        is( $info->{env}, \%ENV, $t->{test} . ': environments match' );
    }

    is(
        $info->{input},
        $t->{result}{input} || '',
        $t->{test} . ': input match'
    );
    is( $info->{pid}, $proc->pid, $t->{test} . ': pid match' );
    is(
        $info->{cwd},
        fc( $t->{result}{dir} || $cwd ),
        $t->{test} . ': dir match'
    );

    # close and check
    $proc->close();
    $proc->wait_child();
    is( $proc->exit,   0,               $t->{test} . ': exit 0' );
    is( $proc->signal, 0,               $t->{test} . ': no signal received' );
    is( $proc->core,   $t->{core} || 0, $t->{test} . ': no core dumped' );
}

for my $t ( @tests, @fail ) {
  SKIP: {
        skip $t->{test} . ' skipped under this locale' if $t->{no_utf8};
        subtest $t->{test}, \&do_test, $t;
    }
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
    use Cwd 'abs_path';
    my $tdir = abs_path('t');

    subtest 'coderef', sub {

        my $proc = spawn(
            sub {
                my $d = cwd();
                while ( my $line = <STDIN> ) {
                    print STDOUT $d . ': ' . $line;
                }
                exit 3;
            },
            { dir => $tdir },
        );

        foreach my $i ( 1 .. 10 ) {
            $proc->stdin->print( $i . "\n" );
            my $res = $proc->stdout->getline;
            chomp $res if defined $res;
            is $res, "$tdir: $i", "coderef: echo $i";
        }
        unless ($no_utf8) {
            my $i = 'Zürich';
            $proc->stdin->print( $i . "\n" );
            my $res = $proc->stdout->getline;
            chomp $res if defined $res;
            is $res, "$tdir: $i", "coderef: echo $i";
        }

        $proc->close;
        $proc->wait_child;
        is $proc->exit, 3, 'coderef: exit 3';
    };
}

subtest 'run', sub {
    my ( $out, $err, $info, $exit );
    my $errstr = 'Parachute Please! ' . ( $no_utf8 ? '' : '✈️' );

    subtest 'return out', sub {
        $info = $out = $err = $exit = undef;
        no_warnings { $out = run(@info_pl) };
        eval $out;
        die $@ if $@;
        is ref($info), 'HASH', 'run() returned $info = { ... }';
    };

    subtest 'warn on stderr', sub {
        $info = $out = $err = $exit = undef;
        $err =
          warning { run( @info_pl, { env => { SYS_CMD_ERR => $errstr }, } ) };
        like $err, qr/$errstr/, 'stderr raised warning ' . $errstr;
    };

    subtest 'catch out, err and exit in vars', sub {
        $info = $out = $err = $exit = undef;
        ok(
            no_warnings {
                run(
                    @info_pl,
                    {
                        out  => \$out,
                        err  => \$err,
                        exit => \$exit,
                    }
                )
            },
            'no warnings'
        );
        eval $out;
        die $@ if $@;
        is ref($info), 'HASH', 'run() put $info into \$out';
        is $err,       '',     'run() $err empty on zero warnings';
        is $exit,      0,      'run() $exit set 0';

        $info = $out = $err = $exit = undef;
        ok(
            no_warnings {
                run(
                    @info_pl,
                    {
                        out  => \$out,
                        err  => \$err,
                        env  => { SYS_CMD_ERR => $errstr },
                        exit => \$exit,
                    }
                )
            },
            'no warnings'
        );
        eval $out;
        die $@ if $@;
        is ref($info), 'HASH',         'run() put $info into \$out';
        is $err,       $errstr . "\n", '$err is ' . $errstr;
        is $exit,      0,              'run() $exit set 0';

        $info = $out = $err = $exit = undef;
        ok(
            no_warnings {
                ok(
                    lives {
                        run(
                            @info_pl,
                            {
                                out => \$out,
                                err => \$err,
                                env => {
                                    SYS_CMD_ERR  => $errstr,
                                    SYS_CMD_EXIT => 2,
                                },
                                exit => \$exit,
                            }
                        )
                    },
                    'no exception'
                )
            },
            'no warnings'
        );
        eval $out;
        die $@ if $@;

        is ref($info), 'HASH',         'run() put $info into \$out';
        is $err,       $errstr . "\n", '$err is ' . $errstr;
        is $exit,      2,              "exit is $exit";
    };

    # Test early ->core. Cannot test ->exit here, as even on exception
    # $proc->{exit} jumps into existance, and wait_child uses
    # ->has_exit.
    $info = $out = $err = $exit = undef;
    my $proc = spawn(@info_pl);

    like(
        dies { $proc->core },
        qr/before wait_child/,
        'exit,core,signal only valid after wait_child'
    );
    $proc->wait_child;
    is $proc->core, 0, 'core status 0';

};

SKIP: {
    my $ls = eval { syscmd( 'ls', { dir => 't' } ) };
    skip "No ls?: $@", 1 if $@;

    subtest 'Sys::Cmd', sub {
        my ( $out, @out );
        @out = $ls->run();
        is scalar @out, 4, 'ls t/';

        @out = ();
        $ls->run( '../lib', { out => \$out } );
        @out = split /\n/, $out;
        is scalar @out, 1, 'ls ../lib -> $out';
    };
}

#subtest 'mock run', sub {
#    my $cmd = syscmd(
#        'junk',
#        {
#            input => "input here\n",
#            mock  => sub {
#                my $proc = shift // return warn "No proc?";
#                like $proc->input, qr/in/, 'in is ' . $proc->input;
#
#                #                diag 'mocked: ' . $proc->cmdline;
#                [
#                    $proc->cmd->[1],         # out
#                    $proc->cmd->[2],         # err
#                    $proc->cmd->[3] // 0,    # exit
#                    $proc->cmd->[4] // 0,    # core
#                    $proc->cmd->[5] // 0,    # signal
#                ];
#
#            }
#        }
#    );
#
#    my ( $out, $err );
#    $out = $err = undef;
#    $out = $cmd->run( "out1\n", '', 0, 0, 0 );
#    is $out, "out1\n", 'mock scalar out';
#
#    $out = $err = undef;
#    $cmd->run(
#        "out1\n", "err1\n", 0, 0, 0,
#        {
#            input => 'in1',
#            out   => \$out,
#            err   => \$err,
#        }
#    );
#    is $out, "out1\n", 'mock ref out';
#    is $err, "err1\n", 'mock ref err';
#
#    $out = $err = undef;
#    my $proc = $cmd->spawn( "out1\n", "err1\n", 13, 23, 33 );
#    $out = $proc->stdout->getline;
#    $err = $proc->stderr->getline;
#    $proc->wait_child;
#    is $out, "out1\n", 'mock ref out';
#    is $err, "err1\n", 'mock ref err';
#    is( $proc->exit,   13, 'mock exit' );
#    is( $proc->core,   33, 'mock core' );
#    is( $proc->signal, 23, 'mock signal' );
#};

done_testing();
