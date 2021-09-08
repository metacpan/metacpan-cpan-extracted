#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    if ($ENV{DBUS_SESSION_BUS_ADDRESS})
    {
        plan tests => 4;
    }
    else
    {
        plan skip_all => "Session D-Bus not available (not running a desktop session?), skipping tests";
    }

    require_ok('Passwd::Keyring::Secret') or BAIL_OUT("Cannot load Passwd::Keyring::Secret");
}

my $secrets = Passwd::Keyring::Secret->new();
isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object");

ok($secrets->is_persistent(), "is_persistent() returns that default keyring is persistent");

my $secrets2 = $secrets->new(alias => 'session');

ok(!$secrets2->is_persistent(), "is_persistent() returns that session keyring is not persistent");
