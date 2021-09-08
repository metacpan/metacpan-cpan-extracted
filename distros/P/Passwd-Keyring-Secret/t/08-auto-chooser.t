#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    if ($ENV{DBUS_SESSION_BUS_ADDRESS})
    {
        eval "use Passwd::Keyring::Auto";
        if ($@)
        {
            plan skip_all => "Passwd::Keyring::Auto required";
        }
        else
        {
            plan tests => 3;
        }
    }
    else
    {
        plan skip_all => "Session D-Bus not available (not running a desktop session?), skipping tests";
    }

    require_ok('Passwd::Keyring::Secret') or BAIL_OUT("Cannot load Passwd::Keyring::Secret");
}

my $keyring = get_keyring(force => 'Secret', alias => 'session');
isa_ok($keyring, 'Passwd::Keyring::Secret', "new keyring object");

ok(!$keyring->is_persistent(), "is_persistent() returns that session keyring is not persistent");
