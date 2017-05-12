#!perl

use strict;
use warnings;
use Test::More;
use Passwd::Keyring::KDEWallet;

if($ENV{DESKTOP_SESSION} || $ENV{DBUS_SESSION_BUS_ADDRESS}) {
    plan tests => 13;
} else {
    plan skip_all => "Keyring not available (not running under KDE/Gnome/other desktop session), skipping tests";
}

SKIP: {

    my $SOME_REALM = 'my@@realm';
    my $OTHER_REALM = 'other realm';

    my $ring; 

    eval {
        $ring = Passwd::Keyring::KDEWallet->new(app=>"Passwd::Keyring::KDEWallet", group=>"Unit tests");
    }; if($@) {
        if($@ =~ /^KWallet not available/) {
            skip "KWallet not available ($@)", 13;
        } else {
            die $@;
        }
    }

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::KDEWallet',   'new() works' );

    ok( ! defined($ring->get_password("Paul", $SOME_REALM)), "get works");

    ok( $ring->get_password("Gregory", $SOME_REALM) eq 'secret-Greg', "get works");

    ok( $ring->get_password("Paul", $OTHER_REALM) eq 'secret-Paul2', "get works");

    ok( $ring->get_password("Duke", $SOME_REALM) eq 'secret-Duke', "get works");

    ok( $ring->clear_password("Gregory", $SOME_REALM) eq 1, "clear clears");

    ok( ! defined($ring->get_password("Gregory", $SOME_REALM)), "clear cleared");

    ok( $ring->get_password("Paul", $OTHER_REALM) eq 'secret-Paul2', "get works");

    ok( $ring->get_password("Duke", $SOME_REALM) eq 'secret-Duke', "get works");

    ok( $ring->clear_password("Paul", $OTHER_REALM) eq 1, "clear clears");

    ok( $ring->clear_password("Duke", $SOME_REALM) eq 1, "clear clears");

    ok( ! defined($ring->get_password("Paul", $SOME_REALM)), "clear cleared");
    ok( ! defined($ring->get_password("Duke", $SOME_REALM)), "clear cleared");

}
