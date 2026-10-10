#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use Time::HiRes ();

BEGIN {
    use_ok('Monitoring::Sneck') || print "Bail out!\n";
}

if ( $^O eq 'MSWin32' ) {
    done_testing();
    exit 0;
}

my $perl = $^X;
my $dir  = tempdir( CLEANUP => 1 );

# Writes a file with the given content and returns the path.
sub write_file {
    my ( $file, $content ) = @_;
    open( my $fh, '>', $file ) or die( 'failed to write "' . $file . '"... ' . $! );
    print $fh $content;
    close($fh);
    return $file;
}

# Writes a config to a temp file and returns a new Monitoring::Sneck for it,
# with any extra args to new.
sub new_sneck {
    my ( $config, %args ) = @_;
    my ( $fh, $file ) = tempfile( DIR => $dir, SUFFIX => '.conf' );
    print $fh $config;
    close($fh);
    return Monitoring::Sneck->new( { config => $file, %args } );
}

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
exit 2;
END

#
# defaults, config options, and args overriding them
#
{
    my $sneck = new_sneck("c1|$perl -e 1\n");
    is( $sneck->{check_timeout}, 30, 'default check_timeout' );
    ok( !defined( $sneck->{check_timeout_signal} ), 'default check_timeout_signal' );
    is( $sneck->{check_kill_sub_pids}, 1, 'default check_kill_sub_pids' );

    my $config = "\$check_timeout=5\n\$check_timeout_signal=sigkill\n\$check_kill_sub_pids=0\nc1|$perl -e 1\n";
    $sneck = new_sneck($config);
    is( $sneck->{check_timeout},        5,      'config check_timeout' );
    is( $sneck->{check_timeout_signal}, 'KILL', 'config check_timeout_signal' );
    is( $sneck->{check_kill_sub_pids},  0,      'config check_kill_sub_pids' );

    $sneck = new_sneck( $config, check_timeout => 7, check_timeout_signal => 15, check_kill_sub_pids => 1 );
    is( $sneck->{check_timeout},        7,      'arg check_timeout overrides config' );
    is( $sneck->{check_timeout_signal}, 'TERM', 'arg check_timeout_signal overrides config' );
    is( $sneck->{check_kill_sub_pids},  1,      'arg check_kill_sub_pids overrides config' );

    $sneck = new_sneck( $config, check_timeout_signal => 'none' );
    ok( !defined( $sneck->{check_timeout_signal} ), 'arg check_timeout_signal none clears config' );

    $sneck = new_sneck( "c1|$perl -e 1\n", check_timeout => 0, check_timeout_signal => 'BOGUS', check_kill_sub_pids => 2 );
    is( $sneck->{good}, 0, 'bad args make it not good' );
    is(
        $sneck->run->{errorString},
        'arg check_timeout: option "check_timeout" must be a whole number of at least 1; '
            . 'arg check_timeout_signal: option "check_timeout_signal" must be a signal name or a signal number other than 0; '
            . 'arg check_kill_sub_pids: option "check_kill_sub_pids" must be 0 or 1',
        'bad args reported'
    );
}

#
# a check and debug check timing out
#
{
    my $marker       = $dir . '/hang.marker';
    my $debug_marker = $dir . '/hang.debug.marker';
    my $config
        = "\$check_timeout=1\n"
        . "c1|$perl $hang_script $marker\n"
        . "%d1|$perl $hang_script $debug_marker\n"
        . "c2|$perl -e 1\n";
    my $start = Time::HiRes::time;
    my $ret   = new_sneck($config)->run;
    my $took  = Time::HiRes::time - $start;
    ok( $took < 4, 'gave up on the checks at the timeout' );
    ok( $took >= 2, 'waited the full timeout on each of the check and debug check' ) or diag( 'took ' . $took );

    my $c1 = $ret->{data}{checks}{c1};
    ok( $c1->{run_time} >= 1, 'check run_time is at least the timeout' ) or diag( 'run_time ' . $c1->{run_time} );
    ok( $ret->{data}{debugs}{d1}{run_time} >= 1, 'debug check run_time is at least the timeout' )
        or diag( 'run_time ' . $ret->{data}{debugs}{d1}{run_time} );
    is( $c1->{error},  'timed out after 1 seconds', 'check timeout error' );
    is( $c1->{exit},   -1,                          'check timeout exit is -1' );
    is( $c1->{output}, 'partial output',            'check output from before the timeout kept' );
    is( $ret->{data}{errored}, 1, 'timed out check counted as errored' );
    is( $ret->{data}{ok},      1, 'other check still ran' );
    is( $ret->{data}{alert},   1, 'timed out check sets alert' );

    is( $ret->{data}{debugs}{d1}{error}, 'timed out after 1 seconds', 'debug check timeout error' );
    is( $ret->{data}{debugs}{d1}{exit},  -1,                          'debug check timeout exit is -1' );

    sleep 4;
    ok( -e $marker, 'timed out check was left running without a signal' );
}

#
# check_timeout_signal, with and without check_kill_sub_pids
#
{
    # Runs tree.pl as a check with the given config options and args to new,
    # then returns the check's result and which markers exist once it would
    # have finished.
    my $run_tree = sub {
        my ( $options, %args ) = @_;
        my @markers = map { $dir . '/tree.' . $_ . '.marker' } ( 'parent', 'child', 'grandchild' );
        unlink(@markers);
        my $config = "\$check_timeout=1\n" . $options . "c1|$perl $tree_script " . join( ' ', @markers ) . "\n";
        my $start  = Time::HiRes::time;
        my $ret    = new_sneck( $config, %args )->run;
        ok( Time::HiRes::time - $start < 3, 'gave up at the timeout with "' . $options . '"' );
        ok( $ret->{data}{checks}{c1}{run_time} >= 1, 'waited the full timeout with "' . $options . '"' )
            or diag( 'run_time ' . $ret->{data}{checks}{c1}{run_time} );
        sleep 4;
        return ( $ret->{data}{checks}{c1}, [ map { -e $_ ? 1 : 0 } @markers ] );
    };

    my ( $c1, $markers ) = $run_tree->("\$check_timeout_signal=TERM\n");
    is( $c1->{error}, 'timed out after 1 seconds, sent SIGTERM', 'check timeout error says the signal was sent' );
    is( $c1->{exit},  -1,                                        'signaled check timeout exit is -1' );
    is_deeply( $markers, [ 0, 0, 0 ], 'check and all sub pids killed' );

    ( $c1, $markers ) = $run_tree->("\$check_timeout_signal=TERM\n\$check_kill_sub_pids=0\n");
    is_deeply( $markers, [ 0, 1, 1 ], 'check_kill_sub_pids=0 kills only the check' );

    ( $c1, $markers ) = $run_tree->( "\$check_timeout_signal=TERM\n", check_kill_sub_pids => 0 );
    is_deeply( $markers, [ 0, 1, 1 ], 'check_kill_sub_pids arg overrides config' );

    ( $c1, $markers ) = $run_tree->( "\$check_timeout_signal=TERM\n", check_timeout_signal => 'none' );
    is( $c1->{error}, 'timed out after 1 seconds', 'check_timeout_signal none sends nothing' );
    is_deeply( $markers, [ 1, 1, 1 ], 'check_timeout_signal none leaves everything running' );
}

#
# a check leaving a child holding stdout open does not wait on it
#
{
    my $start = Time::HiRes::time;
    my $ret   = new_sneck("c1|$perl $daemon_script\n")->run;
    ok( Time::HiRes::time - $start < 4, 'check not waited on past its exit' );
    my $c1 = $ret->{data}{checks}{c1};
    is( $c1->{exit},   2,         'check exit kept' );
    is( $c1->{output}, 'started', 'check output kept' );
    ok( !exists( $c1->{error} ), 'no error for a check that exited' );
}

#
# a check dying on a signal keeps its error format
#
{
    my $signal_script = write_file( $dir . '/signal.pl', "kill( 'TERM', \$\$ );\nsleep 5;\n" );
    my $ret           = new_sneck("c1|$perl $signal_script\n")->run;
    my $c1  = $ret->{data}{checks}{c1};
    is( $c1->{exit},  143,                                            'signal death exit is 128 + signal' );
    is( $c1->{error}, "child died with signal 15, without coredump\n", 'signal death error' );
}

done_testing();
