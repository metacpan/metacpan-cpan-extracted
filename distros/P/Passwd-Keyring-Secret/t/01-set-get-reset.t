#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    if ($ENV{DBUS_SESSION_BUS_ADDRESS})
    {
        plan tests => 9;
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

my $secrets = eval { Passwd::Keyring::Secret->new(alias => 'session') };
isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object");

if ($@)
{
    diag($@);
    BAIL_OUT("OS unsupported");
}

my $USER = 'John';
my $PASSWORD = 'verysecret';

$secrets->set_password($USER, $PASSWORD, 'my@@realm');
pass("working set_password()");

is($secrets->get_password($USER, 'my@@realm'), $PASSWORD, "get_password() recovers password");

ok($secrets->clear_password($USER, 'my@@realm'), "clear_password() removes password");

is($secrets->get_password($USER, 'my@@realm'), undef, "no more password after clear_password()");

ok(!$secrets->clear_password($USER, 'my@@realm'), "another clear_password() has nothing to clear");

ok(!$secrets->clear_password("non-existing user", 'my@@realm'), "clear_password() for unknown user has nothing to clear" );

ok(!$secrets->clear_password("$USER", 'no realm known'), "clear_password() for unknown realm has nothing to clear" );
