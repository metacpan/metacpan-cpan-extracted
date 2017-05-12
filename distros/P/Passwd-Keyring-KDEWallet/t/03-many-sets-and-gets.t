#!perl

use strict;
use warnings;
use Test::More;
use Passwd::Keyring::KDEWallet;

if($ENV{DESKTOP_SESSION} || $ENV{DBUS_SESSION_BUS_ADDRESS}) {
    plan tests => 11;
} else {
    plan skip_all => "Keyring not available (not running under KDE/Gnome/other desktop session), skipping tests";
}

my $SOME_REALM = 'my@@realm';
my $OTHER_REALM = 'other realm';

SKIP: {

    my $ring;
    eval {
        $ring = Passwd::Keyring::KDEWallet->new(app=>"Passwd::Keyring::KDEWallet", group=>"Unit tests");
    }; if($@) {
        if($@ =~ /^KWallet not available/) {
            skip "KWallet not available ($@)", 11;
        } else {
            die $@;
        }
    }

    ok( defined($ring) && ref $ring eq 'Passwd::Keyring::KDEWallet',   'new() works' );

    $ring->set_password("Paul", "secret-Paul", $SOME_REALM);
    $ring->set_password("Gregory", "secret-Greg", $SOME_REALM); #
    $ring->set_password("Paul", "secret-Paul2", $OTHER_REALM);
    $ring->set_password("Duke", "secret-Duke", $SOME_REALM);

    ok( 1, "set_password works" );

    ok( $ring->get_password("Paul", $SOME_REALM) eq 'secret-Paul', "get works");

    ok( $ring->get_password("Gregory", $SOME_REALM) eq 'secret-Greg', "get works");

    ok( $ring->get_password("Paul", $OTHER_REALM) eq 'secret-Paul2', "get works");

    ok( $ring->get_password("Duke", $SOME_REALM) eq 'secret-Duke', "get works");

    ok( $ring->clear_password("Paul", $SOME_REALM) eq 1, "clear_password removed 1");

    ok( ! defined($ring->get_password("Paul", $SOME_REALM)), "get works");

    ok( $ring->get_password("Gregory", $SOME_REALM) eq 'secret-Greg', "get works");

    ok( $ring->get_password("Paul", $OTHER_REALM) eq 'secret-Paul2', "get works");

    ok( $ring->get_password("Duke", $SOME_REALM) eq 'secret-Duke', "get works");


    # Note: cleanup is performed by test 04, we test passing data to
    #       separate program.
}
