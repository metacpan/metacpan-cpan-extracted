#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

unless($ENV{PWSAFE_SKIP_TEST}) {
    plan tests => 25;
} else {
    plan skip_all => "Skipped as PWSAFE_SKIP_TEST is set.";
}

use Passwd::Keyring::PWSafe3;

my $DBFILE = File::Spec->catfile($FindBin::Bin, "test.psafe3");

my $REALM_A = 'my@@realm';
my $REALM_B = 'bum trala la';
my $REALM_C = 'other realm';

my $USER1 = "Paul Anton";
my $USER2 = "Gżegąź";
my $USER4 = "-la-san-ty-";

my $PWD1 = "secret-Paul";
my $PWD1_ALT = "secret-Paul2 ąąąą";
my $PWD2 = "secret-Greg";
my $PWD4 = "secret-Duke";

my $ring = new_ok(
    "Passwd::Keyring::PWSafe3" => [
        app=>"Passwd::Keyring::PWSafe3", group=>"Unit tests (secrets)",
        file=>$DBFILE, master_password=>"10101010",
        lazy_save=>1 ], 
    "Properly setup - new(file=>$DBFILE, group=>Unit tests (secrets), lazy_save=>1)");

$ring->set_password($USER1, $PWD1, $REALM_B);
ok( 1, "Properly set - set_password($USER1, $PWD1, $REALM_B)" );
$ring->set_password($USER2, $PWD2, $REALM_B);
ok( 1, "Properly set - set_password($USER2, $PWD2, $REALM_B)" );#
$ring->set_password($USER1, $PWD1_ALT, $REALM_C);
ok( 1, "Properly set - set_password($USER1, $PWD1_ALT, $REALM_C)" );
$ring->set_password($USER4, $PWD4, $REALM_B);
ok( 1, "Properly set - set_password($USER4, $PWD4, $REALM_B)" );

$ring->save();
ok( 1, "Save succeeded");

is( $ring->get_password($USER1, $REALM_B), $PWD1,
    "Properly got back - get_password($USER1, $REALM_B)");

is( $ring->get_password($USER2, $REALM_B), $PWD2,
    "Properly got back - get_password($USER2, $REALM_B)");

is( $ring->get_password($USER1, $REALM_C), $PWD1_ALT,
    "Properly got back - get_password($USER1, $REALM_C)");

is( $ring->get_password($USER4, $REALM_B), $PWD4,
    "Properly got back - get_password($USER4, $REALM_B)");

$ring->clear_password($USER1, $REALM_B);
ok(1, "clear works - clear_password($USER1, $REALM_B)");

ok( ! defined($ring->get_password($USER1, $REALM_A)),
    "Properly got nothing - get_password($USER1, $REALM_A)");

ok( ! defined($ring->get_password($USER2, $REALM_A)),
    "Properly got nothing - get_password($USER2, $REALM_A)");

is( $ring->get_password($USER2, $REALM_B), $PWD2,
    "Properly got back - get_password($USER2, $REALM_B)");

is( $ring->get_password($USER1, $REALM_C), $PWD1_ALT,
    "Properly got back - get_password($USER1, $REALM_C)");

is( $ring->get_password($USER4, $REALM_B), $PWD4,
    "Properly got back - get_password($USER4, $REALM_B)");

is( $ring->clear_password($USER2, $REALM_B), 1,
    "Properly cleared - clear_password($USER2, $REALM_B)");

ok( ! defined($ring->get_password($USER2, $REALM_A)),
    "Properly got nothing after clear - get_password($USER2, $REALM_A)");

is( $ring->get_password($USER1, $REALM_C), $PWD1_ALT,
    "Properly got back - get_password($USER1, $REALM_C)");

is( $ring->get_password($USER4, $REALM_B), $PWD4,
    "Properly got back - get_password($USER4, $REALM_B)");

is( $ring->clear_password($USER1, $REALM_C), 1,
    "Properly cleared - clear_password($USER1, $REALM_C)");

is( $ring->clear_password($USER4, $REALM_B), 1,
    "Properly cleared - clear_password($USER4, $REALM_B)");

ok( ! defined($ring->get_password($USER1, $REALM_C)),
    "Got nothing after clear - get_password($USER1, $REALM_C)");
ok( ! defined($ring->get_password($USER4, $REALM_B)),
    "Got nothing after clear - get_password($USER4, $REALM_B)");

$ring->save();
ok( 1, "Save succeeded");




