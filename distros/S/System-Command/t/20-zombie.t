use strict;
use warnings;
use Test::More;
use System::Command;
use File::Spec;

# show more precise times if possible
eval "use Time::HiRes qw( time )";

my @cmd  = ( $^X, File::Spec->catfile( t => 'fail.pl' ) );
my @cmd2 = ( $^X, File::Spec->catfile( t => 'lines.pl' ) );

my $win32  = $^O eq 'MSWin32';
my $cygwin = $^O eq 'cygwin';

# under Win32, $SIG{CHLD} = 'IGNORE' has no effect,
# and we do not get the expected warnings
plan tests => my $tests + ( $win32 ? -2 : $cygwin ? -1 : 0 );

my $status = 1;
my $delay  = 2;

# this is necessary, because kill(0,pid) is misimplemented in perl core
# note that tasklist does not provide a return code; pipe to find to obtain return code
my $_is_alive = $win32
    ? sub { return `tasklist /FO CSV /NH /fi "PID eq $_[0]" 2>NUL | find /I /N "$_[0]" >NUL` }
    : sub { return kill 0, $_[0]; };

# catch warnings
my $expect_CHLD_warning;
$SIG{__WARN__} = sub {
    my ($warning) = @_;
    if ($expect_CHLD_warning) {
        like(
            $warning,
            qr/^Child process already reaped, check for a SIGCHLD handler /,
            'Warning about $SIG{CHLD}'
        );
    }
    else {
        ok( 0, "Unexpected warning: $warning" );
    }
};

# the standard stuff
BEGIN { $tests += 10 }
{

    # just started the command
    my $cmd = System::Command->new( @cmd, $status, $delay );
    ok( !$cmd->is_terminated, 'child still alive' );
    is( $cmd->exit, undef, 'no exit status' );

    # leave it time to die
    sleep $delay + 1;
    ok( $cmd->is_terminated, 'child is dead now' );    # was a zombie
    is( $cmd->exit, $status, 'exit status collected' );

    # yes, our handles are still open
    ok( $cmd->is_terminated,  'child is still dead' );
    ok( $cmd->stdout->opened, 'stdout still opened' );
    ok( $cmd->stderr->opened, 'stderr still opened' );

    # close our handles now
    $cmd->close;
    ok( $cmd->is_terminated,   'child is still dead' );
    ok( !$cmd->stdout->opened, 'stdout closed' );
    ok( !$cmd->stderr->opened, 'stderr closed' );
}

# what if our user decided to reap children automatically?
BEGIN { $tests += 16 + 2 } # tests + tests within $SIG{__WARN__}
{
    diag q{$SIG{CHLD} = 'IGNORE'};
    local $SIG{CHLD} = 'IGNORE';
    $expect_CHLD_warning = 1;
    my $cmd = System::Command->new( @cmd, $status, $delay );
    ok( !$cmd->is_terminated, 'child still alive' );
    is( $cmd->exit, undef, 'no exit status' );

    # leave it time to die
    sleep $delay + 1;
    diag "\$cmd->is_terminated should warn" if !$win32;
    ok( $cmd->is_terminated, 'child was reaped' );    # was dead and gone
    $win32
        ? is( $cmd->exit, $status, 'exit status collected' )
        : is( $cmd->exit, -1,      'BOGUS exit status collected' );

    # yes, our handles are still open
    ok( $cmd->is_terminated,  'child is still dead' );
    ok( $cmd->stdout->opened, 'stdout still opened' );
    ok( $cmd->stderr->opened, 'stderr still opened' );

    # close our handles now
    $cmd->close;
    ok( $cmd->is_terminated,   'child is still dead' );
    ok( !$cmd->stdout->opened, 'stdout closed' );
    ok( !$cmd->stderr->opened, 'stderr closed' );

    # close first
    $cmd = System::Command->new( @cmd, $status, $delay );
    ok( !$cmd->is_terminated, 'child still alive' );
    is( $cmd->exit, undef, 'no exit status' );

    # don't leave it time, just choke it now
    diag "\$cmd->close should warn" if !$win32;
    $cmd->close;

    # See http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=666631#17
    # Under load, there can be a window of time during which the child
    # process is still reachable via kill(0), even though waitpid() returned
    my ( $start, $pid, $attempts ) = ( time, $cmd->pid, 0 );
    $attempts++ while $_is_alive->($pid);
    diag sprintf '%d kill( 0, $pid ) attempts succeeded in %f seconds',
        $attempts, time - $start
        if $attempts;

    ok( $cmd->is_terminated, 'child was reaped' );    # was dead and gone
    ( $win32 or $cygwin )
        ? is( $cmd->exit, $status, 'exit status collected' )
        : is( $cmd->exit, -1,      'BOGUS exit status collected' );
    ok( !$cmd->stdout->opened, 'stdout closed' );
    ok( !$cmd->stderr->opened, 'stderr closed' );
}

# this code: my $fh = System::Command->new( @cmd )->stdout
# will create a zombie process with the current implementation
BEGIN { $tests += 4 }
{
    diag 'hunting for zombies';
    my $pid;
    {
        my $fh = do {
            my $zed = System::Command->new( @cmd2, 1 );
            $pid = $zed->pid;
            $zed;
            }
            ->stdout;

        # zombies do not exist under win32
        my $blip = $_is_alive->($pid);
        $win32
            ? ok( !$blip, "process $pid is gone" )
            : ok( $blip,  "process $pid is still alive" );

        my $ln = <$fh>;
        is( $ln, "STDOUT line 1\n", 'scope: { $fh = cmd->fh }' );

        $blip = $_is_alive->($pid);
        $win32
            ? ok( !$blip, "process $pid is gone" )
            : ok( $blip,  "process $pid is still alive" );
        $fh->close;
    }

    ok( !$_is_alive->($pid), "process $pid should be dead" );
}

# don't confuse Test::More
$? = 0;
