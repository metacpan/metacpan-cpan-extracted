#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use JSON       qw(decode_json);
use Time::HiRes ();
use POSIX       ();

BEGIN {
    use_ok('Monitoring::Sneck') || print "Bail out!\n";
}

if ( $^O eq 'MSWin32' ) {
    done_testing();
    exit 0;
}

my $perl       = $^X;
my $dir        = tempdir( CLEANUP => 1 );
my $log        = $dir . '/restart.log';
my $state_file = $dir . '/state.json';

# Writes a file with the given content.
sub write_file {
    my ( $file, $content ) = @_;
    open( my $fh, '>', $file ) or die( 'failed to write "' . $file . '"... ' . $! );
    print $fh $content;
    close($fh);
    return $file;
}

# Reads a file, returning undef if it does not exist.
sub read_file {
    my ($file) = @_;
    open( my $fh, '<', $file ) or return undef;
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

# check.pl exits with the number in its flag file, or 0 if there is none.
my $check_script = write_file( $dir . '/check.pl', <<'END' );
my $flag = shift;
my $code = 0;
if ( open( my $fh, '<', $flag ) ) { $code = <$fh>; chomp($code); }
print "check output\n";
exit $code;
END

# restart.pl logs its name, then exits with the given code.
my $restart_script = write_file( $dir . '/restart.pl', <<'END' );
my ( $name, $log, $code, $sleep ) = @ARGV;
open( my $fh, '>>', $log ) or die($!);
print $fh $name . "\n";
close($fh);
print "restarted " . $name . "\n";
sleep($sleep) if $sleep;
exit $code;
END

# hang.pl prints some output, then writes a marker after 3 seconds.
my $hang_script = write_file( $dir . '/hang.pl', <<'END' );
my $marker = shift;
$| = 1;
print "partial output\n";
sleep 3;
open( my $fh, '>', $marker );
exit 0;
END

# tree.pl starts a child, which starts a grandchild. Each sleeps 3 seconds,
# then writes its own marker.
my $tree_script = write_file( $dir . '/tree.pl', <<'END' );
my ( $parent_marker, $child_marker, $grandchild_marker ) = @ARGV;
my $marker = $parent_marker;
if ( !fork() ) {
    $marker = $child_marker;
    if ( !fork() ) {
        $marker = $grandchild_marker;
    }
}
sleep 3;
open( my $fh, '>', $marker );
exit 0;
END

# daemon.pl starts a child that keeps stdout open for 5 seconds, then exits right away.
my $daemon_script = write_file( $dir . '/daemon.pl', <<'END' );
if ( !fork() ) {
    sleep 5;
    exit 0;
}
print "started\n";
exit 0;
END

# signal.pl kills itself with SIGTERM without printing anything.
my $signal_script = write_file( $dir . '/signal.pl', <<'END' );
kill( 'TERM', $$ );
sleep 5;
exit 0;
END

# quiet_fail.pl exits 1 without printing anything.
my $quiet_fail_script = write_file( $dir . '/quiet_fail.pl', "exit 1;\n" );

# big.pl prints 100000 bytes to both stdout and stderr.
my $big_script = write_file( $dir . '/big.pl', <<'END' );
print STDOUT 'x' x 100000;
print STDERR 'y' x 100000;
exit 0;
END

# chatty.pl prints started, then exits while a child keeps writing for up to 8
# seconds.
my $chatty_script = write_file( $dir . '/chatty.pl', <<'END' );
$| = 1;
print "started\n";
if ( !fork() ) {
    my $end = time + 8;
    while ( time < $end ) {
        print( 'z' x 1_000_000 ) || exit 0;
    }
    exit 0;
}
exit 0;
END

# closed.pl closes stdout and stderr, sleeps for the given seconds, then exits 3.
my $closed_script = write_file( $dir . '/closed.pl', <<'END' );
close(STDOUT);
close(STDERR);
sleep(shift);
exit 3;
END

# drip.pl prints started, then exits while a child prints a line every 0.01
# seconds for up to 8 seconds.
my $drip_script = write_file( $dir . '/drip.pl', <<'END' );
$| = 1;
print "started\n";
if ( !fork() ) {
    my $end = time + 8;
    while ( time < $end ) {
        print("drip\n") || exit 0;
        select( undef, undef, undef, 0.01 );
    }
    exit 0;
}
exit 0;
END

# env.pl prints the value of SNECK_RESTART_TEST.
my $env_script = write_file( $dir . '/env.pl', "print \$ENV{SNECK_RESTART_TEST};\n" );

# sneck_env.pl prints the SNECK_* variables, one per line, as name=value.
my $sneck_env_script = write_file( $dir . '/sneck_env.pl', <<'END' );
foreach my $var (qw(SNECK_RESTART SNECK_REASON SNECK_CASCADE_FROM SNECK_FAILED_CHECKS SNECK_CHECKS SNECK_THRESHOLD SNECK_ATTEMPTS)) {
    print $var . '=' . ( defined( $ENV{$var} ) ? $ENV{$var} : 'undef' ) . "\n";
}
END

# fix.pl logs its name, removes the given flag files so those checks are ok
# again, then exits with the given code.
my $fix_script = write_file( $dir . '/fix.pl', <<'END' );
my ( $name, $log, $code, @flags ) = @ARGV;
open( my $fh, '>>', $log ) or die($!);
print $fh $name . "\n";
close($fh);
unlink(@flags);
exit $code;
END

# Sets what a check exits with on its next run. undef means ok.
sub set_check {
    my ( $name, $code ) = @_;
    my $flag = $dir . '/' . $name . '.flag';
    if ( defined($code) ) {
        write_file( $flag, $code );
    } else {
        unlink($flag);
    }
    return;
}

# Returns a config line for a check controlled by set_check.
sub check_line {
    my ($name) = @_;
    return $name . '|' . $perl . ' ' . $check_script . ' ' . $dir . '/' . $name . ".flag\n";
}

# Returns a config line for a restart that logs its name and exits with the given code.
sub restart_line {
    my ( $name, $options, $exit_code, $sleep ) = @_;
    return
          '@'
        . $name . '|'
        . $options . '|'
        . $perl . ' '
        . $restart_script . ' '
        . $name . ' '
        . $log . ' '
        . ( defined($exit_code) ? $exit_code : 0 )
        . ( $sleep ? ' ' . $sleep : '' ) . "\n";
}

# Returns a config line for a restart that removes the flags of the given
# checks, making them ok, and exits with the given code.
sub fix_line {
    my ( $name, $options, $exit_code, @checks ) = @_;
    return
          '@'
        . $name . '|'
        . $options . '|'
        . $perl . ' '
        . $fix_script . ' '
        . $name . ' '
        . $log . ' '
        . $exit_code . ' '
        . join( ' ', map { $dir . '/' . $_ . '.flag' } @checks ) . "\n";
}

# Returns the names logged by restarts since the last reset.
sub restarts_logged {
    my $content = read_file($log);
    return [] if !defined($content);
    return [ split( /\n/, $content ) ];
}

# Clears the restart log, state file, and check flags.
sub reset_all {
    unlink( $log, $state_file );
    unlink( glob( $dir . '/*.flag' ) );
    return;
}

# Creates a Monitoring::Sneck with restarts enabled and the test state file.
sub new_sneck {
    my ( $config, %args ) = @_;
    my $cfg = write_file( $dir . '/sneck.conf', $config );
    return Monitoring::Sneck->new( { config => $cfg, state_file => $state_file, restart => 1, %args } );
}

# Runs sneck in a child process and kills it with SIGKILL once the named
# restart has logged that it started. The restart should sleep long enough
# for that to happen while it is still running.
sub run_and_kill_during_restart {
    my ( $config, $name ) = @_;
    my $pid = fork();
    die( 'fork failed... ' . $! ) if !defined($pid);
    if ( !$pid ) {
        new_sneck($config)->run;
        # skip END blocks so the temp dir and Test::More are left alone
        POSIX::_exit(0);
    }
    my $deadline = Time::HiRes::time + 10;
    while ( Time::HiRes::time < $deadline && !grep { $_ eq $name } @{ restarts_logged() } ) {
        Time::HiRes::sleep(0.05);
    }
    kill( 'KILL', $pid );
    waitpid( $pid, 0 );
    return;
}

#
# no restarts configured
#
{
    reset_all();
    my $ret = new_sneck( check_line('c1') )->run;
    is_deeply( $ret->{data}{restarts}, {}, 'restarts empty when none configured' );
    is( $ret->{data}{restarted}, 0, 'restarted 0 when none configured' );
    ok( !-e $state_file, 'state file not created when none configured' );
}

#
# restarts disabled
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1' ), restart => 0 )->run;
    my $r1 = $ret->{data}{restarts}{r1};
    is( $r1->{reason},    'restarts disabled', 'reason when restarts disabled' );
    is( $r1->{triggered}, 1,                   'triggered still worked out when disabled' );
    is( $r1->{ran},       0,                   'not ran when disabled' );
    is_deeply( $r1->{failed_checks}, ['c1'], 'failed checks still listed when disabled' );
    is_deeply( restarts_logged(), [], 'nothing restarted when disabled' );
    ok( !-e $state_file, 'state file not touched when disabled' );
}

#
# what counts as failed
#
{
    reset_all();
    set_check( 'c_warn', 1 );
    set_check( 'c_crit', 2 );
    set_check( 'c_unk',  3 );
    set_check( 'c_err',  5 );
    my $config
        = check_line('c_warn')
        . check_line('c_crit')
        . check_line('c_unk')
        . check_line('c_err')
        . "c_missing|/nonexistent/sneck_check\n"
        . restart_line( 'r_warn',           'checks=c_warn' )
        . restart_line( 'r_crit',           'checks=c_crit' )
        . restart_line( 'r_unk',            'checks=c_unk' )
        . restart_line( 'r_unk_counted',    'checks=c_unk ignore_unknown=0' )
        . restart_line( 'r_err',            'checks=c_err' )
        . restart_line( 'r_err_counted',    'checks=c_err ignore_errored=0' )
        . restart_line( 'r_missing',        'checks=c_missing' )
        . restart_line( 'r_missing_counted', 'checks=c_missing ignore_errored=0' );
    my $ret = new_sneck($config)->run;
    my %triggered = map { $_ => $ret->{data}{restarts}{$_}{triggered} } keys( %{ $ret->{data}{restarts} } );
    is_deeply(
        \%triggered,
        {
            r_warn            => 0,
            r_crit            => 1,
            r_unk             => 0,
            r_unk_counted     => 1,
            r_err             => 0,
            r_err_counted     => 1,
            r_missing         => 0,
            r_missing_counted => 1,
        },
        'critical triggers, warning never does, unknown and errored only when not ignored'
    );
    is_deeply(
        restarts_logged(),
        [ 'r_crit', 'r_err_counted', 'r_missing_counted', 'r_unk_counted' ],
        'triggered restarts ran in name order'
    );
    is( $ret->{data}{restarted}, 4, 'restarted count' );
    is( $ret->{data}{restarts}{r_crit}{reason}, 'threshold', 'reason is threshold' );
    is( $ret->{data}{restarts}{r_warn}{reason}, 'not triggered', 'reason is not triggered' );
}

#
# threshold
#
{
    reset_all();
    my $config
        = check_line('a')
        . check_line('b')
        . check_line('c')
        . restart_line( 'r', 'checks=a,b,c threshold=2 min_interval=0' );
    my $sneck = new_sneck($config);

    set_check( 'a', 2 );
    my $ret = $sneck->run;
    is( $ret->{data}{restarts}{r}{triggered}, 0, 'one of three failing does not meet threshold 2' );
    is_deeply( $ret->{data}{restarts}{r}{failed_checks}, ['a'], 'failed checks listed below threshold' );
    is( $ret->{data}{restarts}{r}{threshold}, 2, 'threshold in output' );

    set_check( 'b', 2 );
    $ret = $sneck->run;
    is( $ret->{data}{restarts}{r}{triggered}, 1, 'two of three failing meets threshold 2' );
    is_deeply( $ret->{data}{restarts}{r}{failed_checks}, [ 'a', 'b' ], 'failed checks listed in config order' );
    is_deeply( restarts_logged(), ['r'], 'restart ran once threshold met' );
}

#
# depends only order restarts
#
{
    reset_all();
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db' )
        . restart_line( 'z_db',  'checks=db_check' );

    set_check( 'app_check', 2 );
    set_check( 'db_check',  2 );
    my $ret = new_sneck($config)->run;
    is_deeply( restarts_logged(), [ 'z_db', 'a_app' ], 'depend runs first when both trigger' );

    reset_all();
    set_check( 'app_check', 2 );
    $ret = new_sneck($config)->run;
    is_deeply( restarts_logged(), ['a_app'], 'passing depend is not restarted' );
    is( $ret->{data}{restarts}{z_db}{reason}, 'not triggered', 'passing depend reason' );

    reset_all();
    set_check( 'db_check', 2 );
    $ret = new_sneck($config)->run;
    is_deeply( restarts_logged(), ['z_db'], 'dependent not restarted without cascade' );
}

#
# cascade
#
{
    reset_all();
    set_check( 'db_check', 2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db cascade=1' )
        . restart_line( 'z_db',  'checks=db_check' );
    my $ret = new_sneck($config)->run;
    is_deeply( restarts_logged(), [ 'z_db', 'a_app' ], 'cascade restarts dependent after depend' );
    is( $ret->{data}{restarts}{a_app}{reason},    'cascade from z_db', 'cascade reason' );
    is( $ret->{data}{restarts}{a_app}{triggered}, 0,                   'cascaded restart not triggered itself' );
    is( $ret->{data}{restarts}{a_app}{ran},       1,                   'cascaded restart ran' );
    is( $ret->{data}{restarted},                  2,                   'cascade counted in restarted' );

    reset_all();
    set_check( 'db_check', 2 );
    $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db cascade=1' )
        . restart_line( 'z_db',  'checks=db_check', 1 );
    $ret = new_sneck($config)->run;
    is_deeply( restarts_logged(), ['z_db'], 'no cascade from a failed depend' );

    # cascade does not count towards max_retries
    reset_all();
    set_check( 'db_check', 2 );
    $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db cascade=1 min_interval=0 max_retries=1' )
        . restart_line( 'z_db',  'checks=db_check min_interval=0' );
    my $sneck = new_sneck($config);
    $sneck->run foreach ( 1 .. 3 );
    is_deeply( restarts_logged(), [ ( 'z_db', 'a_app' ) x 3 ], 'cascade ignores max_retries' );
}

#
# failed depends
#
{
    reset_all();
    set_check( 'app_check', 2 );
    set_check( 'db_check',  2 );
    set_check( 'web_check', 2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . check_line('web_check')
        . restart_line( 'app', 'checks=app_check depends=db' )
        . restart_line( 'db',  'checks=db_check', 1 )
        . restart_line( 'web', 'checks=web_check depends=app' );
    my $ret = new_sneck($config)->run;
    is_deeply( restarts_logged(), ['db'], 'dependents of a failed restart do not run' );
    is( $ret->{data}{restarts}{app}{reason}, 'skipped, dependency db failed',  'skipped for failed depend' );
    is( $ret->{data}{restarts}{web}{reason}, 'skipped, dependency app failed', 'skip carries down the chain' );
    is( $ret->{data}{restarts}{db}{exit}, 1, 'failed restart exit stored' );
    is( $ret->{data}{alert}, 1, 'failed restart sets alert' );
    like( $ret->{data}{alertString}, qr/^restart "db" failed, exit 1: restarted db$/m, 'failed restart and its output in alertString' );
}

#
# a depend held back by cooldown is not a failure
#
{
    reset_all();
    set_check( 'app_check', 2 );
    set_check( 'db_check',  2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'app', 'checks=app_check depends=db min_interval=0' )
        . restart_line( 'db',  'checks=db_check' );
    my $sneck = new_sneck($config);
    $sneck->run;
    my $ret = $sneck->run;
    is_deeply( restarts_logged(), [ 'db', 'app', 'app' ], 'dependent runs while depend is in cooldown' );
    like( $ret->{data}{restarts}{db}{reason}, qr/^cooldown, \d+ seconds left$/, 'depend reason is cooldown' );
}

#
# min_interval
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $sneck = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1' ) );
    my $ret   = $sneck->run;
    is( $ret->{data}{restarts}{r1}{ran}, 1, 'first run restarts' );
    $ret = $sneck->run;
    is( $ret->{data}{restarts}{r1}{ran}, 0, 'second run held back by default min_interval' );
    like( $ret->{data}{restarts}{r1}{reason}, qr/^cooldown, (1[0-7][0-9]|180) seconds left$/, 'cooldown reason' );
    is_deeply( restarts_logged(), ['r1'], 'restarted once' );

    # pretend the last run was long enough ago
    write_file( $state_file, '{"restarts":{"r1":{"attempts":1,"last_run":' . ( time - 200 ) . '}}}' );
    $ret = $sneck->run;
    is( $ret->{data}{restarts}{r1}{ran}, 1, 'runs again once min_interval has passed' );

    reset_all();
    set_check( 'c1', 2 );
    $sneck = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1 min_interval=0' ) );
    $sneck->run foreach ( 1 .. 3 );
    is_deeply( restarts_logged(), [ ('r1') x 3 ], 'min_interval=0 never holds back' );
}

#
# max_retries
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $sneck = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1 min_interval=0 max_retries=2' ) );
    is( $sneck->run->{data}{restarts}{r1}{attempts}, 1, 'attempts 1' );
    is( $sneck->run->{data}{restarts}{r1}{attempts}, 2, 'attempts 2' );
    my $ret = $sneck->run;
    is( $ret->{data}{restarts}{r1}{reason},   'max retries reached', 'max retries reached' );
    is( $ret->{data}{restarts}{r1}{ran},      0,                     'not ran once max retries reached' );
    is( $ret->{data}{restarts}{r1}{attempts}, 2,                     'attempts stay at max' );
    is_deeply( restarts_logged(), [ 'r1', 'r1' ], 'restarted max_retries times' );

    set_check( 'c1', undef );
    $ret = $sneck->run;
    is( $ret->{data}{restarts}{r1}{attempts}, 0, 'attempts reset when checks recover' );

    set_check( 'c1', 2 );
    $ret = $sneck->run;
    is( $ret->{data}{restarts}{r1}{ran},      1, 'restarts again after recovering' );
    is( $ret->{data}{restarts}{r1}{attempts}, 1, 'attempts counting again' );

    reset_all();
    set_check( 'c1', 2 );
    $sneck = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1 min_interval=0' ) );
    $sneck->run foreach ( 1 .. 5 );
    is_deeply( restarts_logged(), [ ('r1') x 5 ], 'max_retries=0 always retries' );
}

#
# not_every matching, with a fixed time and time zone
#
{
    my $old_tz = $ENV{TZ};
    $ENV{TZ} = 'UTC';
    POSIX::tzset();
    my $sneck = new_sneck( check_line('c1') );

    # Sun Oct 11 02:30:00 2026 UTC
    my $epoch = 1791685800;
    is( $sneck->_in_not_every( '* 2-3 * * 0',  $epoch ), 1, 'matches hour and day of week' );
    is( $sneck->_in_not_every( '* 2-3 * * 7',  $epoch ), 1, 'Sunday as 7' );
    is( $sneck->_in_not_every( '30 2 11 10 *', $epoch ), 1, 'matches minute, hour, day, and month' );
    is( $sneck->_in_not_every( '31 2 * * *',   $epoch ), 0, 'other minute does not match' );
    is( $sneck->_in_not_every( '* 4 * * *',    $epoch ), 0, 'other hour does not match' );
    is( $sneck->_in_not_every( '* * * * 1-5',  $epoch ), 0, 'weekdays do not match a Sunday' );
    is( $sneck->_in_not_every( '* * 1 * 0',    $epoch ), 1, 'day of month or day of week, like cron' );
    is( $sneck->_in_not_every( '* * 11 * 1',   $epoch ), 1, 'day of month or day of week, other way around' );
    is( $sneck->_in_not_every( '* * 1 * 1',    $epoch ), 0, 'neither day matching does not match' );

    # five hours behind UTC, making it Sat Oct 10 21:30
    $ENV{TZ} = 'EST5';
    POSIX::tzset();
    is( $sneck->_in_not_every( '* 21 * * 6', $epoch ), 1, 'TZ honored' );
    is( $sneck->_in_not_every( '* 2-3 * * 0', $epoch ), 0, 'UTC time not used' );

    if ( defined($old_tz) ) {
        $ENV{TZ} = $old_tz;
    } else {
        delete( $ENV{TZ} );
    }
    POSIX::tzset();
}

#
# not_every holding back restarts
#
{
    # a month that is not this one, so the window never matches
    my $other_month = ( localtime(time) )[4] + 2;
    $other_month = 1 if $other_month > 12;

    reset_all();
    set_check( 'c1', 2 );
    my $sneck = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1 max_retries=1 not_every="* * * * *"' ) );
    my $ret   = $sneck->run;
    is( $ret->{data}{restarts}{r1}{triggered}, 1,                    'triggered in maintenance window' );
    is( $ret->{data}{restarts}{r1}{ran},       0,                    'not ran in maintenance window' );
    is( $ret->{data}{restarts}{r1}{reason},    'maintenance window', 'maintenance window reason' );
    is( $ret->{data}{restarts}{r1}{attempts},  0,                    'attempts not counted in maintenance window' );
    unlike( $ret->{data}{alertString}, qr/restart/, 'maintenance window is not a restart alert' );
    is_deeply( restarts_logged(), [], 'nothing restarted in maintenance window' );

    # same state file, with a window that never matches
    $sneck = new_sneck(
        check_line('c1') . restart_line( 'r1', 'checks=c1 max_retries=1 not_every="* * * ' . $other_month . ' *"' ) );
    $ret = $sneck->run;
    is( $ret->{data}{restarts}{r1}{ran},      1,           'runs outside maintenance window' );
    is( $ret->{data}{restarts}{r1}{reason},   'threshold', 'threshold reason outside maintenance window' );
    is( $ret->{data}{restarts}{r1}{attempts}, 1,           'first attempt, none used up by the window' );
    is_deeply( restarts_logged(), ['r1'], 'restarted outside maintenance window' );
}

#
# not_every and depends
#
{
    reset_all();
    set_check( 'app_check', 2 );
    set_check( 'db_check',  2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db min_interval=0' )
        . restart_line( 'z_db',  'checks=db_check min_interval=0 not_every="* * * * *"' );
    my $ret = new_sneck($config)->run;
    is( $ret->{data}{restarts}{z_db}{reason},  'maintenance window', 'depend held back by maintenance window' );
    is( $ret->{data}{restarts}{a_app}{reason}, 'threshold',          'dependent still runs for its own threshold' );
    is_deeply( restarts_logged(), ['a_app'], 'only the dependent restarted' );

    reset_all();
    set_check( 'db_check', 2 );
    $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db cascade=1 min_interval=0' )
        . restart_line( 'z_db',  'checks=db_check min_interval=0 not_every="* * * * *"' );
    $ret = new_sneck($config)->run;
    is( $ret->{data}{restarts}{a_app}{ran},    0,               'no cascade from a depend in maintenance window' );
    is( $ret->{data}{restarts}{a_app}{reason}, 'not triggered', 'not triggered reason without cascade' );
    is_deeply( restarts_logged(), [], 'nothing restarted' );

    # a failed depend is reported over the maintenance window
    reset_all();
    set_check( 'app_check', 2 );
    set_check( 'db_check',  2 );
    $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db min_interval=0 not_every="* * * * *"' )
        . restart_line( 'z_db', 'checks=db_check min_interval=0', 1 );
    $ret = new_sneck($config)->run;
    is( $ret->{data}{restarts}{a_app}{reason}, 'skipped, dependency z_db failed', 'failed depend wins over maintenance window' );
}

#
# state file problems
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $config = check_line('c1') . restart_line( 'r1', 'checks=c1' );

    write_file( $state_file, 'not json' );
    my $ret = new_sneck($config)->run;
    like( $ret->{data}{restart_state_error}, qr/^failed to read restart state file/, 'corrupt state file reported' );
    is( $ret->{data}{restarts}{r1}{ran}, 1, 'restarts still run with corrupt state file' );
    ok( eval { decode_json( read_file($state_file) ); 1 }, 'state file rewritten as valid JSON' );

    write_file( $state_file, '[]' );
    $ret = new_sneck($config)->run;
    is(
        $ret->{data}{restart_state_error},
        'restart state file "' . $state_file . '" is not in the expected format',
        'wrong shape state file reported'
    );

    reset_all();
    set_check( 'c1', 2 );
    $ret = new_sneck( $config, state_file => $dir . '/no/such/dir/state.json' )->run;
    like( $ret->{data}{restart_state_error}, qr/^failed to write restart state file/, 'unwritable state file reported' );
    is( $ret->{data}{restarts}{r1}{ran}, 1, 'restarts still run with unwritable state file' );

    reset_all();
    set_check( 'c1', 2 );
    write_file( $state_file, '{"restarts":{"gone":{"attempts":3,"last_run":1}}}' );
    $ret = new_sneck($config)->run;
    ok( !exists $ret->{data}{restart_state_error}, 'no state error for good state file' );
    my $state = decode_json( read_file($state_file) );
    ok( !exists $state->{restarts}{gone}, 'restarts no longer configured dropped from state' );
    is( $state->{restarts}{r1}{attempts}, 1, 'attempts saved' );
    like( $state->{restarts}{r1}{last_run}, qr/^\d+$/, 'last_run saved' );

    $ret = new_sneck($config)->run;
    ok( !exists $ret->{data}{restart_state_error}, 'restart_state_error cleared on next good run' );
}

#
# timeouts
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $marker = $dir . '/hang.marker';
    my $config = check_line('c1') . '@r1|checks=c1 timeout=1|' . $perl . ' ' . $hang_script . ' ' . $marker . "\n";
    my $start  = Time::HiRes::time;
    my $ret    = new_sneck($config)->run;
    my $r1     = $ret->{data}{restarts}{r1};
    is( $r1->{error},  'timed out after 1 seconds', 'timeout error' );
    is( $r1->{exit},   -1,                          'timeout exit is -1' );
    is( $r1->{output}, 'partial output',            'output from before the timeout kept' );
    ok( Time::HiRes::time - $start < 3, 'gave up on the restart at the timeout' );
    ok( !-e $marker, 'restart was still running when given up on' );
    is( $ret->{data}{alert}, 1, 'timed out restart sets alert' );
    like(
        $ret->{data}{alertString},
        qr/^restart "r1" failed, timed out after 1 seconds: partial output$/m,
        'timeout and output in alertString'
    );

    sleep 4;
    ok( -e $marker, 'timed out restart was left running, not killed' );
}

#
# timeout_signal, with and without kill_sub_pids
#
{
    # Runs tree.pl as a restart with the given options and command suffix,
    # then returns the restart's result and which markers exist once it
    # would have finished.
    my $run_tree = sub {
        my ( $options, $suffix ) = @_;
        reset_all();
        set_check( 'c1', 2 );
        my @markers = map { $dir . '/tree.' . $_ . '.marker' } ( 'parent', 'child', 'grandchild' );
        unlink(@markers);
        my $config
            = check_line('c1') . '@r1|checks=c1 timeout=1 '
            . $options . '|'
            . $perl . ' '
            . $tree_script . ' '
            . join( ' ', @markers )
            . $suffix . "\n";
        my $start = Time::HiRes::time;
        my $ret   = new_sneck($config)->run;
        ok( Time::HiRes::time - $start < 3, 'gave up at the timeout with ' . $options );
        sleep 4;
        return ( $ret, [ map { -e $_ ? 1 : 0 } @markers ] );
    };

    my ( $ret, $markers ) = $run_tree->( 'timeout_signal=TERM', '' );
    my $r1 = $ret->{data}{restarts}{r1};
    is( $r1->{error}, 'timed out after 1 seconds, sent SIGTERM', 'timeout error says the signal was sent' );
    is( $r1->{exit},  -1,                                        'signaled timeout exit is -1' );
    like(
        $ret->{data}{alertString},
        qr/^restart "r1" failed, timed out after 1 seconds, sent SIGTERM$/m,
        'signaled timeout in alertString'
    );
    is_deeply( $markers, [ 0, 0, 0 ], 'command and all sub pids killed' );

    ( $ret, $markers ) = $run_tree->( 'timeout_signal=TERM kill_sub_pids=0', '' );
    is( $ret->{data}{restarts}{r1}{error}, 'timed out after 1 seconds, sent SIGTERM', 'kill_sub_pids=0 error' );
    is_deeply( $markers, [ 0, 1, 1 ], 'kill_sub_pids=0 kills only the command' );

    # the ; makes open3 run it via /bin/sh, so the PID is the shell
    ( $ret, $markers ) = $run_tree->( 'timeout_signal=TERM', '; exit 0' );
    is( $ret->{data}{restarts}{r1}{error}, 'timed out after 1 seconds, sent SIGTERM', 'shell wrapped error' );
    is_deeply( $markers, [ 0, 0, 0 ], 'shell wrapped command and all sub pids killed' );

    ( $ret, $markers ) = $run_tree->( 'kill_sub_pids=1', '' );
    is( $ret->{data}{restarts}{r1}{error}, 'timed out after 1 seconds', 'kill_sub_pids alone sends nothing' );
    is_deeply( $markers, [ 1, 1, 1 ], 'kill_sub_pids alone leaves everything running' );
}

#
# a timed out restart is a failed depend
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $config
        = check_line('c1')
        . '@r1|checks=c1 timeout=1|'
        . $perl . ' '
        . $hang_script . ' '
        . $dir
        . "/hang2.marker\n"
        . restart_line( 'r2', 'checks=c1 depends=r1' );
    my $ret = new_sneck($config)->run;
    is( $ret->{data}{restarts}{r2}{reason}, 'skipped, dependency r1 failed', 'timed out depend skips dependents' );
    sleep 4;
}

#
# a restart that leaves a process holding its output open
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $config = check_line('c1') . '@r1|checks=c1|' . $perl . ' ' . $daemon_script . "\n";
    my $start  = Time::HiRes::time;
    my $ret    = new_sneck($config)->run;
    my $r1     = $ret->{data}{restarts}{r1};
    ok( Time::HiRes::time - $start < 3, 'did not wait on a process holding the pipes open' );
    is( $r1->{exit},   0,         'exit 0' );
    is( $r1->{output}, 'started', 'output captured' );
    ok( !exists $r1->{error}, 'no error' );
}

#
# restart command that can not be run
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( check_line('c1') . "\@r1|checks=c1|/nonexistent/sneck_restart\n" )->run;
    my $r1  = $ret->{data}{restarts}{r1};
    is( $r1->{error}, 'failed to execute', 'failed exec error' );
    is( $r1->{exit},  -1,                  'failed exec exit is -1, same as checks' );
    like( $r1->{output}, qr/open3/, 'failed exec output has the open3 error' );
    like( $ret->{data}{alertString}, qr/^restart "r1" failed, failed to execute: open3/m, 'failed exec in alertString' );
}

#
# output fields and variable substitution
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( "NAME=r1\n"
            . check_line('c1')
            . '@r1|checks=c1|'
            . $perl . ' '
            . $restart_script
            . ' %NAME% '
            . $log
            . " 0\n" )->run;
    my $r1 = $ret->{data}{restarts}{r1};
    like( $r1->{command},     qr/ %NAME% /, 'command is before substitution' );
    like( $r1->{ran_command}, qr/ r1 /,     'ran_command is after substitution' );
    is( $r1->{output}, 'restarted r1', 'output captured and chomped' );
    is( $r1->{exit},   0,              'exit 0' );
    like( $r1->{run_time}, qr/^\d+\.\d+$/, 'run_time is decimal' );
    ok( !exists $r1->{error}, 'no error on success' );
    is( $ret->{data}{alert}, 1, 'alert from the critical check' );
    unlike( $ret->{data}{alertString}, qr/restart/, 'successful restart not in alertString' );
}

#
# restart killed by a signal is a failure, and a failure with no output adds no ": "
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $config
        = check_line('c1')
        . '@r1|checks=c1|'
        . $perl . ' '
        . $signal_script . "\n"
        . restart_line( 'r2', 'checks=c1 depends=r1' );
    my $ret = new_sneck($config)->run;
    my $r1  = $ret->{data}{restarts}{r1};
    is( $r1->{exit},   128 + 15,                    'signal exit is 128 + signal' );
    is( $r1->{error},  'child died with signal 15', 'signal error' );
    is( $r1->{output}, '',                          'no output' );
    is( $ret->{data}{alert}, 1, 'signal sets alert' );
    like(
        $ret->{data}{alertString},
        qr/^restart "r1" failed, child died with signal 15$/m,
        'signal in alertString, with no ": " as there is no output'
    );
    is( $ret->{data}{restarts}{r2}{reason}, 'skipped, dependency r1 failed', 'signal skips dependents' );

    reset_all();
    set_check( 'c1', 2 );
    $ret = new_sneck( check_line('c1') . '@r1|checks=c1|' . $perl . ' ' . $quiet_fail_script . "\n" )->run;
    is( $ret->{data}{restarts}{r1}{exit}, 1, 'quiet failure exit' );
    like( $ret->{data}{alertString}, qr/^restart "r1" failed, exit 1$/m, 'quiet failure has no ": " in alertString' );
}

#
# bad state entries are dropped one at a time, without a error
#
{
    reset_all();
    set_check( 'c1', 2 );
    # each bad entry would hold its restart back if it were used instead of dropped
    my $now    = time;
    my $config = check_line('c1')
        . restart_line( 'r_bad_attempts',  'checks=c1 min_interval=0 max_retries=1' )
        . restart_line( 'r_bad_last_run',  'checks=c1' )
        . restart_line( 'r_no_last_run',   'checks=c1 min_interval=0 max_retries=1' )
        . restart_line( 'r_no_attempts',   'checks=c1' )
        . restart_line( 'r_not_hash',      'checks=c1' )
        . restart_line( 'r_good_attempts', 'checks=c1 min_interval=0 max_retries=1' )
        . restart_line( 'r_good_last_run', 'checks=c1' );
    write_file(
        $state_file,
        '{"restarts":{'
            . '"r_bad_attempts":{"attempts":"5x","last_run":1},'
            . '"r_bad_last_run":{"attempts":0,"last_run":"'
            . $now . 'x"},'
            . '"r_no_last_run":{"attempts":5},'
            . '"r_no_attempts":{"last_run":'
            . $now . '},'
            . '"r_not_hash":"nope",'
            . '"r_good_attempts":{"attempts":5,"last_run":1},'
            . '"r_good_last_run":{"attempts":0,"last_run":'
            . $now . '}'
            . '}}'
    );
    my $ret = new_sneck($config)->run;
    ok( !exists $ret->{data}{restart_state_error}, 'bad entries are not a state error' );
    is( $ret->{data}{restarts}{r_good_attempts}{reason}, 'max retries reached', 'good attempts entry used' );
    like( $ret->{data}{restarts}{r_good_last_run}{reason}, qr/^cooldown/, 'good last_run entry used' );
    foreach my $name ( 'r_bad_attempts', 'r_bad_last_run', 'r_no_last_run', 'r_no_attempts', 'r_not_hash' ) {
        is( $ret->{data}{restarts}{$name}{ran}, 1, $name . ' entry dropped, so it ran' );
    }

    reset_all();
    set_check( 'c1', 2 );
    write_file( $state_file, '{"restarts":[]}' );
    $ret = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1' ) )->run;
    is(
        $ret->{data}{restart_state_error},
        'restart state file "' . $state_file . '" is not in the expected format',
        'restarts not being a hash is a state error'
    );
    is( $ret->{data}{restarts}{r1}{ran}, 1, 'restarts still run' );
}

#
# no cascade from a depend held back by cooldown or max retries
#
{
    reset_all();
    set_check( 'db_check', 2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db cascade=1 min_interval=0' )
        . restart_line( 'z_db',  'checks=db_check' );
    my $sneck = new_sneck($config);
    $sneck->run;
    my $ret = $sneck->run;
    like( $ret->{data}{restarts}{z_db}{reason}, qr/^cooldown/, 'depend in cooldown' );
    is( $ret->{data}{restarts}{a_app}{ran},    0,               'no cascade from a depend in cooldown' );
    is( $ret->{data}{restarts}{a_app}{reason}, 'not triggered', 'reason when no cascade' );
    is_deeply( restarts_logged(), [ 'z_db', 'a_app' ], 'only the first run restarted' );

    reset_all();
    set_check( 'db_check', 2 );
    $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db cascade=1 min_interval=0' )
        . restart_line( 'z_db',  'checks=db_check min_interval=0 max_retries=1' );
    $sneck = new_sneck($config);
    $sneck->run;
    $ret = $sneck->run;
    is( $ret->{data}{restarts}{z_db}{reason}, 'max retries reached', 'depend at max retries' );
    is( $ret->{data}{restarts}{a_app}{ran},   0,                     'no cascade from a depend at max retries' );
    is_deeply( restarts_logged(), [ 'z_db', 'a_app' ], 'only the first run restarted' );
}

#
# cascade chains, and which depend a cascade is from
#
{
    reset_all();
    set_check( 'base_check', 2 );
    my $config
        = check_line('base_check')
        . check_line('other_check')
        . restart_line( 'a_top',  'checks=other_check depends=m_mid cascade=1' )
        . restart_line( 'm_mid',  'checks=other_check depends=z_base cascade=1' )
        . restart_line( 'z_base', 'checks=base_check' );
    my $ret = new_sneck($config)->run;
    is_deeply( restarts_logged(), [ 'z_base', 'm_mid', 'a_top' ], 'cascade carries down a chain in order' );
    is( $ret->{data}{restarts}{m_mid}{reason}, 'cascade from z_base', 'middle of chain cascades from base' );
    is( $ret->{data}{restarts}{a_top}{reason}, 'cascade from m_mid',  'top of chain cascades from middle' );

    reset_all();
    set_check( 'db1_check', 2 );
    set_check( 'db2_check', 2 );
    $config
        = check_line('app_check')
        . check_line('db1_check')
        . check_line('db2_check')
        . restart_line( 'app', 'checks=app_check depends=db2,db1 cascade=1' )
        . restart_line( 'db1', 'checks=db1_check' )
        . restart_line( 'db2', 'checks=db2_check' );
    $ret = new_sneck($config)->run;
    is( $ret->{data}{restarts}{app}{reason}, 'cascade from db2', 'cascade is from the first depend listed that ran' );
    is( $ret->{data}{restarted}, 3, 'app ran once for both depends' );

    reset_all();
    set_check( 'db1_check', 2 );
    $ret = new_sneck($config)->run;
    is( $ret->{data}{restarts}{app}{reason}, 'cascade from db1', 'cascade skips depends that did not run' );
}

#
# which reason wins when more than one applies
#
{
    reset_all();
    set_check( 'app_check', 2 );
    set_check( 'db_check',  2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'app', 'checks=app_check depends=db max_retries=1' )
        . restart_line( 'db',  'checks=db_check', 1 );
    write_file( $state_file, '{"restarts":{"app":{"attempts":1,"last_run":' . time . '}}}' );
    my $ret = new_sneck($config)->run;
    is(
        $ret->{data}{restarts}{app}{reason},
        'skipped, dependency db failed',
        'failed depend wins over cooldown and max retries'
    );

    my $state = decode_json( read_file($state_file) );
    is( $state->{restarts}{app}{attempts}, 1, 'skipped restart keeps its attempts' );

    reset_all();
    set_check( 'app_check', 2 );
    write_file( $state_file, '{"restarts":{"app":{"attempts":1,"last_run":' . time . '}}}' );
    $ret = new_sneck( check_line('app_check') . restart_line( 'app', 'checks=app_check max_retries=1' ) )->run;
    like( $ret->{data}{restarts}{app}{reason}, qr/^cooldown/, 'cooldown wins over max retries' );
}

#
# last_run in the future, such as after the clock goes back, does not hold a restart back
#
{
    reset_all();
    set_check( 'c1', 2 );
    write_file( $state_file, '{"restarts":{"r1":{"attempts":0,"last_run":' . ( time + 1000 ) . '}}}' );
    my $ret = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1' ) )->run;
    is( $ret->{data}{restarts}{r1}{ran}, 1, 'future last_run does not hold back' );
    my $state = decode_json( read_file($state_file) );
    ok( $state->{restarts}{r1}{last_run} <= time, 'last_run set back to now' );
}

#
# a depend held back by max retries is not a failure
#
{
    reset_all();
    set_check( 'app_check', 2 );
    set_check( 'db_check',  2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'app', 'checks=app_check depends=db min_interval=0' )
        . restart_line( 'db',  'checks=db_check min_interval=0 max_retries=1' );
    my $sneck = new_sneck($config);
    $sneck->run;
    my $ret = $sneck->run;
    is( $ret->{data}{restarts}{db}{reason}, 'max retries reached', 'depend at max retries' );
    is_deeply( restarts_logged(), [ 'db', 'app', 'app' ], 'dependent runs while depend is at max retries' );
}

#
# a invalid config never touches the state file
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $config = "this is not valid\n" . check_line('c1') . restart_line( 'r1', 'checks=c1' );
    my $state  = '{"restarts":{"r1":{"attempts":7,"last_run":1}}}';
    write_file( $state_file, $state );
    my $ret = new_sneck($config)->run;
    is( $ret->{error}, 1, 'invalid config is a error' );
    is( read_file($state_file), $state, 'state file not changed for invalid config' );
    is_deeply( restarts_logged(), [], 'nothing restarted for invalid config' );

    reset_all();
    new_sneck($config)->run;
    ok( !-e $state_file, 'state file not created for invalid config' );
}

#
# restart output larger than a pipe buffer
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret    = new_sneck( check_line('c1') . '@r1|checks=c1|' . $perl . ' ' . $big_script . "\n" )->run;
    my $output = $ret->{data}{restarts}{r1}{output};
    is( $ret->{data}{restarts}{r1}{exit}, 0, 'large output restart exits 0' );
    ok( !exists $ret->{data}{restarts}{r1}{error}, 'large output restart has no error' );
    is( length($output),       200000, 'all large output captured' );
    is( ( $output =~ tr/x// ), 100000, 'all large stdout captured' );
    is( ( $output =~ tr/y// ), 100000, 'all large stderr captured' );
}

#
# state read and write errors are both reported
#
SKIP: {
    skip( 'directory permissions do not apply to root', 2 ) if $> == 0;

    reset_all();
    set_check( 'c1', 2 );
    my $locked_dir = $dir . '/locked';
    mkdir($locked_dir) or die($!);
    my $locked_state = $locked_dir . '/state.json';
    write_file( $locked_state, 'not json' );
    chmod( 0555, $locked_dir );
    my $ret = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1' ), state_file => $locked_state )->run;
    chmod( 0755, $locked_dir );
    like(
        $ret->{data}{restart_state_error},
        qr/^failed to read restart state file .*; failed to write restart state file /,
        'read and write errors joined'
    );
    is( $ret->{data}{restarts}{r1}{ran}, 1, 'restarts still run' );
}

#
# restart failures come after check output in alertString
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1', 1 ) )->run;
    is(
        $ret->{data}{alertString},
        "check output\n" . 'restart "r1" failed, exit 1: restarted r1' . "\n",
        'check output first, then restart failures'
    );
}

#
# removing every restart leaves the state file alone, adding one back prunes it
#
{
    reset_all();
    set_check( 'c1', 2 );
    new_sneck( check_line('c1') . restart_line( 'old', 'checks=c1' ) )->run;
    my $state = read_file($state_file);
    like( $state, qr/"old"/, 'state saved for old restart' );

    my $ret = new_sneck( check_line('c1') )->run;
    is_deeply( $ret->{data}{restarts}, {}, 'no restarts' );
    is( read_file($state_file), $state, 'state file left alone with no restarts' );

    new_sneck( check_line('c1') . restart_line( 'new', 'checks=c1' ) )->run;
    my $decoded = decode_json( read_file($state_file) );
    ok( !exists $decoded->{restarts}{old}, 'old entry pruned once a restart exists again' );
    ok( exists $decoded->{restarts}{new},  'new entry saved' );
}

#
# output still being written after the command exits is not waited on. Reading
# stops once nothing is ready, with a 1 second cap as a backstop. The cap itself
# can not be reliably reached here, as the writer always leaves tiny gaps.
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $start = Time::HiRes::time;
    my $ret   = new_sneck( check_line('c1') . '@r1|checks=c1|' . $perl . ' ' . $chatty_script . "\n" )->run;
    my $r1    = $ret->{data}{restarts}{r1};
    ok( Time::HiRes::time - $start < 3.5, 'did not wait on a process still writing after the command exited' );
    is( $r1->{exit}, 0, 'exit 0' );
    ok( !exists $r1->{error}, 'no error' );
    like( $r1->{output}, qr/^started\n/, 'output from the command kept' );
}

#
# a run killed while a restart is running still leaves its state behind
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $config = check_line('c1') . restart_line( 'r1', 'checks=c1', 0, 5 );
    run_and_kill_during_restart( $config, 'r1' );
    my $state = eval { decode_json( read_file($state_file) ) };
    is( $state->{restarts}{r1}{attempts}, 1, 'attempt saved before the restart ran' );
    like( $state->{restarts}{r1}{last_run}, qr/^[1-9]\d*$/, 'last_run saved before the restart ran' );
    my $ret = new_sneck($config)->run;
    like( $ret->{data}{restarts}{r1}{reason}, qr/^cooldown/, 'cooldown holds after sneck was killed during the restart' );
    is_deeply( restarts_logged(), ['r1'], 'not restarted again after sneck was killed' );

    reset_all();
    set_check( 'c1', 2 );
    $config = check_line('c1') . restart_line( 'r1', 'checks=c1 min_interval=0 max_retries=1', 0, 5 );
    run_and_kill_during_restart( $config, 'r1' );
    $ret = new_sneck($config)->run;
    is( $ret->{data}{restarts}{r1}{reason}, 'max retries reached', 'max retries holds after sneck was killed during the restart' );
    is_deeply( restarts_logged(), ['r1'], 'not retried after sneck was killed' );
}

#
# min_interval is counted from when the restart finished
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $start = int(time);
    new_sneck( check_line('c1') . restart_line( 'r1', 'checks=c1', 0, 2 ) )->run;
    my $state = decode_json( read_file($state_file) );
    ok( $state->{restarts}{r1}{last_run} >= $start + 2, 'last_run is when the restart finished' );
}

#
# a restart that closes its output before exiting is still waited on
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( check_line('c1') . '@r1|checks=c1|' . $perl . ' ' . $closed_script . " 1\n" )->run;
    my $r1  = $ret->{data}{restarts}{r1};
    is( $r1->{exit},   3,  'exit code from after the output was closed' );
    is( $r1->{output}, '', 'no output' );
    ok( !exists $r1->{error}, 'no error' );
    ok( $r1->{run_time} >= 1, 'waited for it to exit' );

    reset_all();
    set_check( 'c1', 2 );
    my $start = Time::HiRes::time;
    $ret = new_sneck( check_line('c1') . '@r1|checks=c1 timeout=1|' . $perl . ' ' . $closed_script . " 3\n" )->run;
    $r1  = $ret->{data}{restarts}{r1};
    is( $r1->{error},  'timed out after 1 seconds', 'timeout with the output closed' );
    is( $r1->{exit},   -1,                          'timeout exit is -1 with the output closed' );
    is( $r1->{output}, '',                          'no output with the output closed' );
    ok( Time::HiRes::time - $start < 3, 'gave up at the timeout with the output closed' );
}

#
# reading output after the command exits stops after 1 second. can_read(0)
# is made to wait up to 0.5 seconds, so the steady drip always looks ready
# and only the cap can end it.
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $can_read = \&IO::Select::can_read;
    my $ret;
    {
        no warnings 'redefine';
        local *IO::Select::can_read = sub {
            my ( $select, $timeout ) = @_;
            return $can_read->( $select, defined($timeout) && $timeout == 0 ? 0.5 : $timeout );
        };
        $ret = new_sneck( check_line('c1') . '@r1|checks=c1|' . $perl . ' ' . $drip_script . "\n" )->run;
    }
    my $r1 = $ret->{data}{restarts}{r1};
    ok( $r1->{run_time} >= 1, 'kept reading until the cap' );
    ok( $r1->{run_time} < 3,  'stopped reading at the cap' );
    is( $r1->{exit}, 0, 'exit 0 when the cap is hit' );
    like( $r1->{output}, qr/^started\n(drip\n)+/, 'output read up to the cap kept' );
}

#
# attempts reset when the checks fall below the threshold, even with some still failing
#
{
    reset_all();
    my $config
        = check_line('a')
        . check_line('b')
        . restart_line( 'r', 'checks=a,b threshold=2 min_interval=0' );
    my $sneck = new_sneck($config);

    set_check( 'a', 2 );
    set_check( 'b', 2 );
    is( $sneck->run->{data}{restarts}{r}{attempts}, 1, 'attempts 1 at threshold' );

    set_check( 'b', undef );
    my $ret = $sneck->run;
    is( $ret->{data}{restarts}{r}{triggered}, 0, 'below threshold with a check still failing' );
    is( $ret->{data}{restarts}{r}{attempts},  0, 'attempts reset below threshold' );
    is( decode_json( read_file($state_file) )->{restarts}{r}{attempts}, 0, 'reset attempts saved' );
}

#
# a cascade run starts the cooldown for the restart's own threshold
#
{
    reset_all();
    set_check( 'db_check', 2 );
    my $config
        = check_line('app_check')
        . check_line('db_check')
        . restart_line( 'a_app', 'checks=app_check depends=z_db cascade=1' )
        . restart_line( 'z_db',  'checks=db_check min_interval=0' );
    my $sneck = new_sneck($config);
    is( $sneck->run->{data}{restarts}{a_app}{reason}, 'cascade from z_db', 'cascade ran' );

    set_check( 'db_check',  undef );
    set_check( 'app_check', 2 );
    my $ret = $sneck->run;
    is( $ret->{data}{restarts}{a_app}{triggered}, 1, 'own threshold met after cascade' );
    like( $ret->{data}{restarts}{a_app}{reason}, qr/^cooldown/, 'held back by cooldown from the cascade run' );
    is_deeply( restarts_logged(), [ 'z_db', 'a_app' ], 'not restarted again' );
}

#
# YAML configs run restarts the same as the sneck format
#
SKIP: {
    skip( 'YAML::XS not installed', 5 ) if !eval { require YAML::XS; 1 };

    reset_all();
    set_check( 'c1', 2 );
    my $yaml = write_file(
        $dir . '/sneck.yaml',
        "vars:\n"
            . "  NAME: r1\n"
            . "checks:\n"
            . "  c1: '$perl $check_script $dir/c1.flag'\n"
            . "  c2: '$perl $check_script $dir/c2.flag'\n"
            . "restarts:\n"
            . "  r1:\n"
            . "    command: '$perl $restart_script %NAME% $log 0'\n"
            . "    checks: [c1]\n"
            . "  r2:\n"
            . "    command: '$perl $restart_script r2 $log 0'\n"
            . "    checks: [c2]\n"
            . "    depends: [r1]\n"
            . "    cascade: true\n"
    );
    my $ret = Monitoring::Sneck->new( { config => $yaml, state_file => $state_file, restart => 1 } )->run;
    is( $ret->{error}, 0, 'YAML config ran' ) or diag( $ret->{errorString} );
    is_deeply( restarts_logged(), [ 'r1', 'r2' ], 'YAML restarts ran in dependency order' );
    is( $ret->{data}{restarts}{r1}{reason}, 'threshold',         'YAML threshold reason' );
    is( $ret->{data}{restarts}{r2}{reason}, 'cascade from r1',   'YAML cascade reason' );
    is( $ret->{data}{restarts}{r1}{output}, 'restarted r1',      'YAML restart variables put in place' );
}

#
# env lines from the config are seen by restarts
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( "env SNECK_RESTART_TEST=from_env\n"
            . check_line('c1')
            . '@r1|checks=c1|'
            . $perl . ' '
            . $env_script
            . "\n" )->run;
    is( $ret->{data}{restarts}{r1}{output}, 'from_env', 'restart sees env from the config' );
    delete( $ENV{SNECK_RESTART_TEST} );
}

#
# a check killed by a signal is errored, so only counts with ignore_errored=0
#
{
    reset_all();
    my $ret = new_sneck( 'c_sig|'
            . $perl . ' '
            . $signal_script . "\n"
            . restart_line( 'r_sig',         'checks=c_sig' )
            . restart_line( 'r_sig_counted', 'checks=c_sig ignore_errored=0' ) )->run;
    is( $ret->{data}{checks}{c_sig}{exit},              128 + 15, 'check killed by signal' );
    is( $ret->{data}{restarts}{r_sig}{triggered},        0,        'signal ignored by default' );
    is( $ret->{data}{restarts}{r_sig_counted}{triggered}, 1,       'signal counts with ignore_errored=0' );
    is_deeply( restarts_logged(), ['r_sig_counted'], 'only the restart counting errored ran' );
}

#
# SNECK_* variables for a threshold run
#
{
    reset_all();
    set_check( 'c1', 2 );
    set_check( 'c3', 2 );
    my $ret = new_sneck( check_line('c1')
            . check_line('c2')
            . check_line('c3')
            . '@r1|checks=c1,c2,c3 threshold=2 max_retries=5|'
            . $perl . ' '
            . $sneck_env_script
            . "\n" )->run;
    is(
        $ret->{data}{restarts}{r1}{output},
        join( "\n",
            'SNECK_RESTART=r1',      'SNECK_REASON=threshold',
            'SNECK_CASCADE_FROM=',   'SNECK_FAILED_CHECKS=c1,c3',
            'SNECK_CHECKS=c1,c2,c3', 'SNECK_THRESHOLD=2',
            'SNECK_ATTEMPTS=1' ),
        'SNECK_* variables for a threshold run'
    );
    ok( !exists( $ENV{SNECK_RESTART} ), 'SNECK_* variables do not leak into the caller' );
}

#
# SNECK_* variables for a cascade run
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( check_line('c1')
            . check_line('c2')
            . restart_line( 'r_db', 'checks=c1' )
            . '@r_app|checks=c2 depends=r_db cascade=1|'
            . $perl . ' '
            . $sneck_env_script
            . "\n" )->run;
    is( $ret->{data}{restarts}{r_app}{reason}, 'cascade from r_db', 'cascade ran' );
    is(
        $ret->{data}{restarts}{r_app}{output},
        join( "\n",
            'SNECK_RESTART=r_app',      'SNECK_REASON=cascade',
            'SNECK_CASCADE_FROM=r_db',  'SNECK_FAILED_CHECKS=',
            'SNECK_CHECKS=c2',          'SNECK_THRESHOLD=1',
            'SNECK_ATTEMPTS=0' ),
        'SNECK_* variables for a cascade run'
    );
}

#
# check_restart off by default, so checks are not rerun
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck( check_line('c1') . fix_line( 'r1', 'checks=c1', 0, 'c1' ) )->run;
    is( $ret->{data}{restarts}{r1}{ran},       1, 'restart ran' );
    is( $ret->{data}{checks}{c1}{exit},        2, 'check result not updated without check_restart' );
    is( $ret->{data}{critical},                1, 'still counted as critical without check_restart' );
    ok( !exists( $ret->{data}{checks}{c1}{rechecked_by} ), 'rechecked_by not set without check_restart' );
    ok( !exists( $ret->{data}{restarts}{r1}{recheck_failed_checks} ), 'recheck_failed_checks not set without check_restart' );
}

#
# check_restart with the restart fixing things
#
{
    reset_all();
    set_check( 'c1', 2 );
    set_check( 'c2', 1 );
    my $ret = new_sneck( check_line('c1')
            . check_line('c2')
            . fix_line( 'r1', 'checks=c1 check_restart=1 check_restart_delay=0', 0, 'c1' ) )->run;
    my $r1 = $ret->{data}{restarts}{r1};
    is( $r1->{ran}, 1, 'restart ran' );
    ok( !exists( $r1->{error} ), 'no error when the recheck passes' );
    is_deeply( $r1->{recheck_failed_checks}, [], 'nothing failed on recheck' );
    is_deeply( $r1->{failed_checks}, ['c1'], 'failed_checks still what triggered it' );
    is( $ret->{data}{checks}{c1}{exit},         0,    'check result updated by the recheck' );
    is( $ret->{data}{checks}{c1}{rechecked_by}, 'r1', 'rechecked_by set' );
    ok( !exists( $ret->{data}{checks}{c2}{rechecked_by} ), 'unwatched check not rerun' );
    is( $ret->{data}{ok},          1,                'ok count uses the recheck' );
    is( $ret->{data}{warning},     1,                'warning count unchanged' );
    is( $ret->{data}{critical},    0,                'critical count uses the recheck' );
    is( $ret->{data}{alert},       1,                'alert still set by the warning' );
    is( $ret->{data}{alertString}, "check output\n", 'alertString only has the warning' );
}

#
# check_restart with things still failing
#
{
    reset_all();
    set_check( 'c1', 2 );
    set_check( 'c2', 2 );
    my $ret = new_sneck( check_line('c1')
            . check_line('c2')
            . restart_line( 'r1', 'checks=c1 check_restart=1 check_restart_delay=0' )
            . restart_line( 'r2', 'checks=c2 depends=r1' ) )->run;
    my $r1 = $ret->{data}{restarts}{r1};
    is( $r1->{exit}, 0, 'command itself exited 0' );
    is( $r1->{error}, 'checks still failing after restart: c1', 'error when still failing' );
    is_deeply( $r1->{recheck_failed_checks}, ['c1'], 'still failing check listed' );
    is( $ret->{data}{checks}{c1}{rechecked_by}, 'r1', 'rechecked_by set' );
    is( $ret->{data}{critical}, 2, 'still counted as critical' );
    is( $ret->{data}{alert},    1, 'alert set' );
    is(
        $ret->{data}{alertString},
        "check output\ncheck output\n" . 'restart "r1" failed, checks still failing after restart: c1: restarted r1' . "\n",
        'alertString has the checks then the failed restart'
    );
    is( $ret->{data}{restarts}{r2}{reason}, 'skipped, dependency r1 failed', 'dependent skipped' );
    is_deeply( restarts_logged(), ['r1'], 'only r1 ran' );
}

#
# check_restart threshold is applied to the recheck
#
{
    reset_all();
    set_check( 'a', 2 );
    set_check( 'b', 2 );
    my $ret = new_sneck( check_line('a')
            . check_line('b')
            . fix_line( 'r1', 'checks=a,b threshold=2 check_restart=1 check_restart_delay=0', 0, 'a' ) )->run;
    my $r1 = $ret->{data}{restarts}{r1};
    is_deeply( $r1->{recheck_failed_checks}, ['b'], 'b still failing' );
    ok( !exists( $r1->{error} ), 'below threshold on recheck is not a failure' );
    is( $ret->{data}{ok},       1, 'a now ok' );
    is( $ret->{data}{critical}, 1, 'b still critical' );
}

#
# check_restart when the command fails but the recheck passes
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $ret = new_sneck(
        check_line('c1') . fix_line( 'r1', 'checks=c1 check_restart=1 check_restart_delay=0', 1, 'c1' ) )->run;
    my $r1 = $ret->{data}{restarts}{r1};
    is( $r1->{exit}, 1, 'command exit kept' );
    ok( !exists( $r1->{error} ), 'no error, as exit shows it failed' );
    is_deeply( $r1->{recheck_failed_checks}, [], 'recheck passed' );
    is( $ret->{data}{checks}{c1}{exit}, 0, 'check result updated' );
    is( $ret->{data}{alert}, 1, 'alert set for the failed command' );
    is( $ret->{data}{alertString}, 'restart "r1" failed, exit 1' . "\n", 'alertString only has the restart' );
}

#
# check_restart_delay
#
{
    reset_all();
    set_check( 'c1', 2 );
    my $start = Time::HiRes::time;
    my $ret
        = new_sneck( check_line('c1') . fix_line( 'r1', 'checks=c1 check_restart=1 check_restart_delay=2', 0, 'c1' ) )
        ->run;
    my $took = Time::HiRes::time - $start;
    ok( $took >= 2, 'waited check_restart_delay before rechecking' ) or diag( 'took ' . $took );
    is( $ret->{data}{checks}{c1}{exit}, 0, 'rechecked after the delay' );
}

#
# check_restart rechecks use check_timeout, with a timed out recheck only
# counting as still failing if errored is not ignored
#
{
    # recheck.pl is critical until its flag exists, then hangs for 3 seconds.
    my $recheck_script = write_file( $dir . '/recheck.pl', <<'END' );
my $flag = shift;
$| = 1;
if ( -e $flag ) {
    print "rechecking\n";
    sleep 3;
    exit 0;
}
print "down\n";
exit 2;
END
    # arm.pl creates the flag, so the recheck hangs.
    my $arm_script = write_file( $dir . '/arm.pl', <<'END' );
open( my $fh, '>', shift ) or die($!);
exit 0;
END
    my $flag = $dir . '/recheck.flag';

    # Runs c1 with a restart that arms it, using the given extra restart options.
    my $run_recheck = sub {
        my ($options) = @_;
        reset_all();
        unlink($flag);
        my $start = Time::HiRes::time;
        my $ret
            = new_sneck( "\$check_timeout=1\n"
                . "c1|$perl $recheck_script $flag\n"
                . "\@r1|checks=c1 check_restart=1 check_restart_delay=0 $options|$perl $arm_script $flag\n" )->run;
        ok( Time::HiRes::time - $start < 3, 'gave up on the recheck at the timeout with "' . $options . '"' );
        return $ret;
    };

    my $ret = $run_recheck->('ignore_errored=0');
    my $c1  = $ret->{data}{checks}{c1};
    is( $c1->{error},        'timed out after 1 seconds', 'recheck timeout error' );
    is( $c1->{exit},         -1,                          'recheck timeout exit is -1' );
    is( $c1->{output},       'rechecking',                'recheck output from before the timeout kept' );
    is( $c1->{rechecked_by}, 'r1',                        'timed out recheck has rechecked_by set' );
    ok( $c1->{run_time} >= 1, 'recheck waited the full timeout' ) or diag( 'run_time ' . $c1->{run_time} );
    is( $ret->{data}{errored},  1, 'timed out recheck counted as errored' );
    is( $ret->{data}{critical}, 0, 'timed out recheck no longer counted as critical' );
    my $r1 = $ret->{data}{restarts}{r1};
    is( $r1->{exit}, 0, 'restart command exited 0' );
    is( $r1->{error}, 'checks still failing after restart: c1', 'timed out recheck still failing with ignore_errored=0' );
    is_deeply( $r1->{recheck_failed_checks}, ['c1'], 'timed out recheck listed as still failing' );
    is( $ret->{data}{alert}, 1, 'alert set for the still failing restart' );

    $ret = $run_recheck->('ignore_errored=1');
    $r1  = $ret->{data}{restarts}{r1};
    is( $ret->{data}{checks}{c1}{error}, 'timed out after 1 seconds', 'recheck timeout error with ignore_errored=1' );
    ok( !exists( $r1->{error} ), 'timed out recheck not a failure with ignore_errored=1' );
    is_deeply( $r1->{recheck_failed_checks}, [], 'timed out recheck not listed with ignore_errored=1' );
}

done_testing();
