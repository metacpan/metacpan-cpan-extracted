#!perl

use strict;
use warnings;
use Test::More;

if($ENV{DESKTOP_SESSION} || $ENV{DBUS_SESSION_BUS_ADDRESS}) {
    plan tests => 20;
} else {
    plan skip_all => "Keyring not available (not running under KDE/Gnome/other desktop session), skipping tests";
}


use Passwd::Keyring::KDEWallet;

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

SKIP: {

    my $ring; 
    eval {
        $ring = Passwd::Keyring::KDEWallet->new(app=>"Passwd::Keyring::KDEWallet", group=>"Unit tests (secrets)");
    }; if($@) {
        if($@ =~ /^KWallet not available/) {
            skip "KWallet not available ($@)", 20;
        } else {
            die $@;
        }
    }

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::KDEWallet',   'new() works' );

    $ring->set_password($USER1, $PWD1, $REALM_B);
    $ring->set_password($USER2, $PWD2, $REALM_B); #
    $ring->set_password($USER1, $PWD1_ALT, $REALM_C);
    $ring->set_password($USER4, $PWD4, $REALM_B);

    ok( 1, "set_password works" );

    ok( $ring->get_password($USER1, $REALM_B) eq $PWD1, "get works");

    ok( $ring->get_password($USER2, $REALM_B) eq $PWD2, "get works");

    ok( $ring->get_password($USER1, $REALM_C) eq $PWD1_ALT, "get works");

    ok( $ring->get_password($USER4, $REALM_B) eq $PWD4, "get works");

    $ring->clear_password($USER1, $REALM_B);
    ok(1, "clear_password works");

    ok( ! defined($ring->get_password($USER1, $REALM_A)), "get works");

    ok( ! defined($ring->get_password($USER2, $REALM_A)), "get works");

    ok( $ring->get_password($USER2, $REALM_B) eq $PWD2, "get works");

    ok( $ring->get_password($USER1, $REALM_C) eq $PWD1_ALT, "get works");

    ok( $ring->get_password($USER4, $REALM_B) eq $PWD4, "get works");

    ok( $ring->clear_password($USER2, $REALM_B) eq 1, "clear clears");

    ok( ! defined($ring->get_password($USER2, $REALM_A)), "clear cleared");

    ok( $ring->get_password($USER1, $REALM_C) eq $PWD1_ALT, "get works");

    ok( $ring->get_password($USER4, $REALM_B) eq $PWD4, "get works");

    ok( $ring->clear_password($USER1, $REALM_C) eq 1, "clear clears");

    ok( $ring->clear_password($USER4, $REALM_B) eq 1, "clear clears");

    ok( ! defined($ring->get_password($USER1, $REALM_C)), "clear cleared");
    ok( ! defined($ring->get_password($USER4, $REALM_B)), "clear cleared");

}
