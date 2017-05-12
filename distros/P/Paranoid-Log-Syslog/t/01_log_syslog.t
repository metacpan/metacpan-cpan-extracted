#!/usr/bin/perl -T

use Test::More tests => 6;
use Paranoid;
use Paranoid::Log;
use Paranoid::Module;
use Paranoid::Debug;

psecureEnv();

ok( startLogger(
        'syslog_local0', 'Syslog',
        PL_WARN,         PL_EQ,
        { facility => 'local0' }
        ),
    'startLogger 1'
    );
ok( startLogger(
        'syslog_local1',
        'Syslog', PL_WARN, PL_EQ,
        {   facility => 'local1',
            ident    => 'test-logger'
        }
        ),
    'startLogger 2'
    );
ok( startLogger(
        'syslog_local2', 'Syslog',
        PL_CRIT,         PL_EQ,
        { facility => 'local2' }
        ),
    'startLogger 3'
    );
ok( plog( PL_WARN, "this is a test for local0/1" ), 'plog 1' );
ok( plog( PL_CRIT, "this is a test for local2" ),   'plog 2' );
ok( plog( PL_WARN, "this is a test for local0/1" ), 'plog 3' );

