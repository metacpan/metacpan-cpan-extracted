#!/usr/bin/perl -T

use Test::More tests => 9;
use Paranoid;
use Paranoid::Log;
use Paranoid::Debug;

psecureEnv();

# Redirect STDERR to /dev/null
close STDERR;
open STDERR, '>', '/dev/null';

# Load a non-existent facility
ok( !startLogger( 'foo', 'stderrrrrrrrrrrrr', PL_WARN, PL_GE ),
    'startLogger 1' );
ok( startLogger( 'foo', 'Stderr', PL_WARN, PL_GE ), 'startLogger 2' );
ok( plog( PL_CRIT,  'this is a test' ),      'plog 1a' );
ok( plog( PL_DEBUG, 'this is a test, too' ), 'plog 1b' );
ok( stopLogger('foo'), 'stopLogger 1' );
ok( plog( PL_CRIT,  "this is a test" ), 'plog 2' );
ok( plog( PL_EMERG, "this is a test" ), 'plog 3' );
ok( plog( PL_ALERT, "this is a test" ), 'plog 4' );
ok( plog( PL_WARN,  "this is a test" ), 'plog 5' );

