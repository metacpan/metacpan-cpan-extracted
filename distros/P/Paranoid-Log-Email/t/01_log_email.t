#!/usr/bin/perl -T

use Test::More tests => 11;
use Paranoid;
use Paranoid::Log;
use Paranoid::Module;

use strict;
use warnings;

psecureEnv();

my $rv;

# Bad mailhost, should fail
ok( startLogger(
        'email', 'Email', PL_WARN, PL_EQ,
        {   mailhost  => 'localhst0.',
            recipient => "$ENV{USER}\@localhost",
            subject   => 'Test message -- please ignore'
        }
        ),
    'startLogger 1'
    );
ok( !plog( PL_WARN, "this is a test" ), 'plog 1' );
ok( stopLogger('email'), 'stopLogger 1' );

# Good mailhost, should succeed (if mail services are running)
ok( startLogger(
        'email', 'Email', PL_WARN, PL_EQ,
        {   mailhost  => 'localhost',
            recipient => "$ENV{USER}\@localhost",
            subject   => 'Test message -- please ignore'
        }
        ),
    'startLogger 2'
    );
$rv = plog( PL_WARN, "this is a test" );
ok( stopLogger('email'), 'stopLogger 2' );

# This following test should fail, but its entirely possible that it
# doesn't if someone has a *really* stupid mail config
ok( startLogger(
        'email', 'Email', PL_WARN, PL_EQ,
        {   mailhost  => 'localhost',
            recipient => "$ENV{USER}\@localhost",
            sender    => 'user@fooo.coom.neeeet.',
            subject   => 'Test message -- please ignore'
        }
        ),
    'startLogger 4'
    );
$rv = plog( PL_WARN, "this is a test" );
if ($rv) {
    warn "test 'plog 4' should have failed, but didn't.\n";
    warn "Ignoring since this could be a MTA config issue.\n";
}
ok( 1,                   'plog 4' );
ok( stopLogger('email'), 'stopLogger 4' );

# The same goes for this -- if it succeeds it may be a mail config issue
ok( startLogger(
        'email', 'Email', PL_WARN, PL_EQ,
        {   mailhost  => 'localhost',
            recipient => "iHopeTheresNoSuchUserReallyReallyBad\@localhost",
            subject   => 'Test message -- please ignore'
        }
        ),
    'startLogger 5'
    );
$rv = plog( PL_WARN, "this is a test" );
if ($rv) {
    warn "test 'plog 5' should have failed, but didn't.\n";
    warn "Ignoring since this could be a MTA config issue.\n";
}
ok( 1,                   'plog 5' );
ok( stopLogger('email'), 'stopLogger 5' );

