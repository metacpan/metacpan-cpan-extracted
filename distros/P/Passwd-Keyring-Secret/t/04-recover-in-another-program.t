#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    if ($ENV{DBUS_SESSION_BUS_ADDRESS})
    {
        plan tests => 14;
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

my $secrets = eval { Passwd::Keyring::Secret->new(app => 'Passwd::Keyring::Secret', group => 'Passwd::Keyring::Secret Tests', alias => 'session') };
isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object");

if ($@)
{
    diag($@);
    BAIL_OUT("OS unsupported");
}

my $SOME_REALM = 'my@@realm';
my $ANOTHER_REALM = 'another realm';

is($secrets->get_password('Paul', $SOME_REALM), undef, "no phantom password in another program");
is($secrets->get_password('Gregory', $SOME_REALM), 'secret-Greg', "working get_password() from another program");
is($secrets->get_password('Paul', $ANOTHER_REALM), 'secret-Paul2', "working get_password() from another program");
is($secrets->get_password('Duke', $SOME_REALM), 'secret-Duke', "working get_password() from another program");

ok($secrets->clear_password('Gregory', $SOME_REALM), "working clear_password()");

is($secrets->get_password('Gregory', $SOME_REALM), undef, "working get_password() after clear_password()");
is($secrets->get_password('Paul', $ANOTHER_REALM), 'secret-Paul2', "working get_password() from another program");
is($secrets->get_password('Duke', $SOME_REALM), 'secret-Duke', "working get_password() from another program");

ok($secrets->clear_password('Paul', $ANOTHER_REALM), "working clear_password()");
ok($secrets->clear_password('Duke', $SOME_REALM), "working clear_password()");

is($secrets->get_password('Paul', $ANOTHER_REALM), undef, "working get_password() after clear_password()");
is($secrets->get_password('Duke', $SOME_REALM), undef, "working get_password() after clear_password()");
