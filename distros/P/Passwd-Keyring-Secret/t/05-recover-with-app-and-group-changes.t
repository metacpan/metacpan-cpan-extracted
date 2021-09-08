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

    require_ok('Passwd::Keyring::Secret') or BAIL_OUT("Cannot load Passwd::Keyring::Secret");
}

my $USER = 'Paul Anton';
my $REALM = 'test realm';
my $PWD = 'arcytajne haslo';
my $PWD2 = 'inny sekret';

my $APP1 = 'Passwd::Keyring::Secret Tests (1)';
my $APP2 = 'Passwd::Keyring::Secret Tests (2)';
my $GROUP1 = 'Passwd::Keyring::Secret Tests - Group 1';
my $GROUP2 = 'Passwd::Keyring::Secret Tests - Group 2';
my $GROUP3 = 'Passwd::Keyring::Secret Tests - Group 3';

my @cache;

subtest "test with App1 and Group1" => sub
{
    plan tests => 4;

    my $secrets = Passwd::Keyring::Secret->new(app => $APP1, group => $GROUP1, alias => 'session');
    isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object");

    is($secrets->get_password($USER, $REALM), undef, "initially unset password");

    $secrets->set_password($USER, $PWD, $REALM);
    pass("set password");

    is($secrets->get_password($USER, $REALM), $PWD, "get password");

    push @cache, $secrets;
};

subtest "another test with App1 and Group1" => sub
{
    plan tests => 2;

    # another object with the same app and group
    my $secrets = Passwd::Keyring::Secret->new(app => $APP1, group => $GROUP1, alias => 'session');
    isa_ok($secrets, 'Passwd::Keyring::Secret', "another new keyring object");

    is($secrets->get_password($USER, $REALM), $PWD, "get password from another instance with the same data");
};

subtest "test with App2 and Group1" => sub
{
    plan tests => 2;

    # only app changes
    my $secrets = Passwd::Keyring::Secret->new(app => $APP2, group => $GROUP1, alias => 'session');
    isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object with different app");

    is($secrets->get_password($USER, $REALM), $PWD, "get password from another instance with different app but same group");
};

subtest "test with App1 and Group2" => sub
{
    plan tests => 2;

    # only group changes
    my $secrets = Passwd::Keyring::Secret->new(app => $APP1, group => $GROUP2, alias => 'session');
    isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object with different group");

    is($secrets->get_password($USER, $REALM), undef, "changing group forces another password");

    # to check if original password won't be spoiled
    $secrets->set_password($USER, $PWD2, $REALM);

    push @cache, $secrets;
};

subtest "test with App2 and Group3" => sub
{
    plan tests => 2;

    # app and group change
    my $secrets = Passwd::Keyring::Secret->new(app => $APP2, group => $GROUP3, alias => 'session');
    isa_ok($secrets, 'Passwd::Keyring::Secret', "new keyring object with both app and group changed");

    is($secrets->get_password($USER, $REALM), undef, "changing app and group again forces yet another password");
};

subtest "yet another test with App1 and Group1" => sub
{
    plan tests => 2;

    my $secrets = Passwd::Keyring::Secret->new(app => $APP1, group => $GROUP1, alias => 'session');
    isa_ok($secrets, 'Passwd::Keyring::Secret', "yet another new keyring object");

    # re-reading original password to check if it was properly kept
    is($secrets->get_password($USER, $REALM), $PWD, "get original password after changes in another group");
};

# cleaning up
my $i = 0;
foreach my $secrets (@cache)
{
    ++$i;
    ok($secrets->clear_password($USER, $REALM), "clearing password in Group$i");
}
