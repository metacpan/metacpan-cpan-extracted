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

my $APP = 'Passwd::Keyring::Secret Tests 06 ';
$APP .= 'X' x (256 - length($APP));
my $GROUP = 'Passwd::Keyring::Secret Tests ';
$GROUP .= 'X' x (256 - length($GROUP));

my $USER = 'A' x 256;
my $PWD =  'B' x 256;
my $REALM = 'C' x 256;

my $secrets = eval { Passwd::Keyring::Secret->new(app => $APP, group => $GROUP, alias => 'session') };
isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object");

if ($@)
{
    diag($@);
    BAIL_OUT("OS unsupported");
}

$secrets->set_password($USER, $PWD, $REALM);
pass("set_password() works with long parameters");

is($secrets->get_password($USER, $REALM), $PWD, "get_password() works with long parameters");

ok($secrets->clear_password($USER, $REALM), "clear_password() works with long parameters");
