use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw( tempdir );
use Cwd qw( cwd abs_path );
use System::Command;
use Config;
use constant MSWin32 => $^O eq 'MSWin32';

$ENV{TO_BE_DELETED} = 'LATER';
my $dir   = abs_path( tempdir( CLEANUP => 1 ) );
my $cwd   = cwd;
my $name  = File::Spec->catfile( t => 'info.pl' );
my $tests_per_test = 17;
my @tests = (
    {   cmdline => [ $^X, $name ],
        options => {},
    },
    {   cmdline => [
            $^X, $name, { env => { SYSTEM_COMMAND => 'System::Command' } }
        ],
        options => { env => { SYSTEM_COMMAND => 'System::Command' } },
    },
    {   cmdline => [
            $^X, $name,
            { env  => { SYSTEM_COMMAND => 'System::Command' } },
            { },
        ],
        options => {
            env  => { SYSTEM_COMMAND => 'System::Command' },
        },
    },
    {   cmdline => [
            $^X,
            File::Spec->catfile( $cwd => $name ),
            { cwd => $dir, name => 'powie' },
            { env => { SYSTEM_COMMAND => 'System::Command' } },
        ],
        cwd     => $dir,
        name    => File::Spec->catfile( $cwd => $name ),
        options => {
            name => 'powie',
            env  => { SYSTEM_COMMAND => 'System::Command' },
            cwd  => $dir,
        },
    },
    {   cmdline => [
            $^X, $name,
            { env => { SYSTEM_COMMAND => 'System::Command' } },
            { env => { TO_BE_DELETED  => undef } },
            { env => { OTHER_ENV      => 'something else' } },
        ],
        options => {
            env => {
                OTHER_ENV      => 'something else',
                SYSTEM_COMMAND => 'System::Command',
                TO_BE_DELETED  => undef,
            }
        },
    },
    {   cmdline => [
            $^X,
            $name,
            { env => { 'SYSTEM_COMMAND_INPUT' => 1 }, input => 'test input' }
        ],
        options =>
            { env => { 'SYSTEM_COMMAND_INPUT' => 1 }, input => 'test input' }
    },
    {   cmdline => [
            $^X, $name,
            {   env =>
                    { 'SYSTEM_COMMAND_INPUT' => 1, 'TO_BE_DELETED' => undef },
                input => ''
            }
        ],
        options => {
            env => { 'SYSTEM_COMMAND_INPUT' => 1, 'TO_BE_DELETED' => undef },
            input => ''
            }
    },
    {   cmdline => [ $^X, $name, { env => { 'TO_BE_DELETED' => '' } } ],
        options => { env => { 'TO_BE_DELETED' => '' } },
        skip_reason => "this test makes no sense on Win32",
        skip_check => sub { MSWin32 },
        skip_count => $tests_per_test,
    },
);
my @fail = (
    {   cmdline =>
            [ $^X, $name, { cwd => File::Spec->catdir( $dir, 'nothere' ) } ],
        cwd     => File::Spec->catdir( $dir, 'nothere' ),
        fail    => qr/^Can't chdir to /,
        options => {},
    },
    {   cmdline => [ $^X, $name, { env => { 'TO_BE_DELETED' => '' } } ],
        fail    => qr/^ENV variables cannot be empty strings on Win32 /,
        skip_reason => "this test only makes sense on Win32",
        skip_check => sub { !MSWin32 },
        skip_count => 2,
    },
);

plan tests => $tests_per_test * @tests + 2 * @fail;

if ( $Config{sig_name} !~ /\bPIPE\b/ ) {
   diag "No SIGPIPE signal on this Perl. Available signals:";
   diag $Config{sig_name};
}

for my $t ( @tests, @fail ) {SKIP:{
    skip $t->{skip_reason}, $t->{skip_count}
        if ($t->{skip_check}||sub{})->();

    # run the command
    my $cmd = eval { System::Command->new( @{ $t->{cmdline} } ) };
    if ( $t->{fail} ) {
        ok( !$cmd, 'command failed' );
        like( $@, $t->{fail}, '... expected error message' );
        next;
    }

    isa_ok( $cmd, 'System::Command' );

    # test the handles
    for my $handle (qw( stdin stdout stderr )) {
        isa_ok( $cmd->$handle, 'GLOB' );
        if ( $handle eq 'stdin' ) {
            my $opened = !exists $t->{options}{input};
            is( $cmd->$handle->opened, $opened,
                "$handle @{[ !$opened && 'not ']}opened" );
        }
        else {
            ok( $cmd->$handle->opened, "$handle opened" );
        }
    }

    # default option: setpgrp
    $t->{options}{setpgrp} = 1
        if !exists $t->{options}{setpgrp};
    is_deeply( [ $cmd->cmdline ],
        [ grep { !ref } @{ $t->{cmdline} } ], 'cmdline' );
    is_deeply( $cmd->options, $t->{options}, 'options' );

    # get the output
    my $output = join '', $cmd->stdout->getlines();
    my $errput = join '', $cmd->stderr->getlines();
    is( $errput, '', 'no errput' );

    my $env = { %ENV, %{ $t->{options}{env} || {} } };
    delete $env->{$_}
        for grep { !defined $t->{options}{env}{$_} }
        keys %{ $t->{options}{env} || {} };
    delete $env->{$_} for grep /^CONEMU/, keys %ENV;
    if (MSWin32) {
        # env vars can't be empty strings on Win32
        # seems GNU make is adding an empty-string MFLAGS env-var which causes mayhem
        delete $env->{$_} for grep !length $env->{$_}, keys %$env;
    }
    my $info;
    eval $output;
    my $w32env = {};
    $w32env = { PWD => $t->{options}{cwd} }
        if MSWin32 && exists $t->{options}{cwd};
    my $expected = {   argv  => [],
        cwd   => $t->{options}{cwd} || $cwd,
        env   => { %$env, %$w32env },
        input => $t->{options}{input} || '',
        name  => $t->{name} || $name,
        pid   => $cmd->pid,
    };
    is_deeply($info, $expected, "perl $name") or do {
        diag '$t: ', explain $t;
        diag '$info: ', explain $info;
        diag '$expected: ', explain $expected;
    };

    # close and check
    my $reaper = $cmd->close();
    my @things = ( cmd => $cmd, reaper => $reaper );
    while ( my ( $desc, $thing ) = splice @things, 0, 2 ) {
        is( $thing->exit,   0, "exit 0 ($desc)" );
        is( $thing->signal, 0, "no signal received ($desc)" );
        is( $thing->core, $t->{core} || 0, "no core dumped ($desc)" );
    }
}}

