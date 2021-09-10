#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    if ($ENV{DBUS_SESSION_BUS_ADDRESS})
    {
        plan tests => 12;
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

$secrets->set_password('Paul', 'secret-Paul', $SOME_REALM);
$secrets->set_password('Gregory', 'secret-Greg', $SOME_REALM);
$secrets->set_password('Paul', 'secret-Paul2', $ANOTHER_REALM);
$secrets->set_password('Duke', 'secret-Duke', $SOME_REALM);
pass("working set_password()");

is($secrets->get_password('Paul', $SOME_REALM), 'secret-Paul', "working get_password()");
is($secrets->get_password('Gregory', $SOME_REALM), 'secret-Greg', "working get_password()");
is($secrets->get_password('Paul', $ANOTHER_REALM), 'secret-Paul2', "working get_password()");
is($secrets->get_password('Duke', $SOME_REALM), 'secret-Duke', "working get_password()");

ok($secrets->clear_password('Paul', $SOME_REALM), "working clear_password()");

is($secrets->get_password('Paul', $SOME_REALM), undef, "working get_password()");
is($secrets->get_password('Gregory', $SOME_REALM), 'secret-Greg', "working get_password()");
is($secrets->get_password('Paul', $ANOTHER_REALM), 'secret-Paul2', "working get_password()");
is($secrets->get_password('Duke', $SOME_REALM), 'secret-Duke', "working get_password()");

note("Cleanup is performed by tests 04; we test passing data to another program");
