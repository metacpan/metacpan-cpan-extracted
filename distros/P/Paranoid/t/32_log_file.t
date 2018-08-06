#!/usr/bin/perl -T

use Test::More tests => 13;
use Paranoid;
use Paranoid::Log;
use Paranoid::Process qw(:pfork);
use Paranoid::IO::Line;
use Paranoid::Debug;
use Paranoid::Module;
use Fcntl qw(:DEFAULT :flock :mode :seek);

psecureEnv();

$SIG{CHLD} = \&sigchld;

my ( $child, $pid, @lines, $line, $i, $j );
my $file = './t/foo.log';

# Load a bad facility
ok( !startLogger( 'foo', 'File', PL_WARN, PL_EQ ), 'startLogger 1' );
ok( plog( PL_WARN, 'this is a test' ), 'plog 1' );
ok( stopLogger('foo'), 'stopLogger 1' );
ok( startLogger(
        'foo', 'File', PL_WARN, PL_EQ, { file => $file, syslog => 1 }
        ),
    'startLogger 2'
    );
ok( plog( PL_WARN, "this is a test" ), 'plog 2' );

SKIP: {
    skip( 'No Time::HiRes -- skipping permissions test', 1 )
        unless loadModule( 'Time::HiRes', qw(usleep) );

    # Fork some children and have them all log fifty messages each
    foreach $child ( 1 .. 5 ) {
        unless ( $pid = pfork() ) {
            for ( 1 .. 50 ) {
                my $intvl = int rand 500;
                usleep($intvl);
                plog( PL_WARN,
                    "child $child: this is test #$_ (slept $intvl usec)" );
            }
            exit 0;
        }
    }
    while ( childrenCount() ) { sleep 1 }
    sleep 5;

    # Count the number of lines -- should be 251
    piolClose($file);
    slurp( $file, @lines, 1 );
    my $rv = ( scalar @lines == 251 or scalar @lines == 252 );
    ok( $rv, 'line count' );

    # Make sure children have been logging at the same time and not blocked
    # by advisory locks, etc.
    $i = $j = 0;
    while (@lines) {
        $line = shift @lines;
        if ($line =~ /child 2:/s) {
            $i++;
            $i += $j;
            $j = 0;
        } elsif ($i) {
            $j++;
        }
    }
    ok( $i > 55, 'multiple children logged' );
}

ok( stopLogger('foo'), 'stopLogger 2' );
ok( startLogger(
        'foo', 'File', PL_WARN, PL_GE,
        { file => $file, mode => O_TRUNC | O_RDWR, }
        ),
    'logger options 1'
    );
my @fstats = stat $file;
is( $fstats[7], 0, 'file size' );
ok( stopLogger('foo'), 'stopLogger 2' );
unlink $file;

ok( startLogger(
        'foo', 'File', PL_WARN, PL_GE,
        { file => $file, perm => 0600, mode => O_CREAT | O_RDWR, }
        ),
    'logger options 2'
    );
@fstats = stat $file;
is( $fstats[2] & 077777, 0600, 'file perm' );

unlink $file;

