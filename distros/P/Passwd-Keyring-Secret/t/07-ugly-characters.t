#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    if ($ENV{DBUS_SESSION_BUS_ADDRESS})
    {
        plan tests => 5;
    }
    else
    {
        plan skip_all => "Session D-Bus not available (not running a desktop session?), skipping tests";
    }

    ok(eval { require Passwd::Keyring::Secret; 1 }, "load Passwd::Keyring::Secret");

    if ($@)
    {
        diag($@);
        BAIL_OUT("OS unsupported");
    }
}

my $secrets = eval { Passwd::Keyring::Secret->new(app => 'Passwd::Keyring::Secret', group => 'Tests with Ugly Characters', alias => 'session') };
isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object");

if ($@)
{
    diag($@);
    BAIL_OUT("OS unsupported");
}

my $UGLY_NAME = 'Joh ## no ^^ »Gźegąćęłóśż«';
my $UGLY_PWD = '«tajne hąsło»';
my $UGLY_REALM = '«do»–main';

$secrets->set_password($UGLY_NAME, $UGLY_PWD, $UGLY_REALM);
pass("set_password() works with ugly characters");

is($secrets->get_password($UGLY_NAME, $UGLY_REALM), $UGLY_PWD, "get_password() works with ugly characters");

ok($secrets->clear_password($UGLY_NAME, $UGLY_REALM), "clear_password() works with ugly characters");
