#!perl -T

use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "These tests don't run well under root"
      unless $>;
}
plan tests => 13;

use Passwd::Keyring::Auto qw(get_keyring);

my $SOME_REALM = 'my@@realm';
my $OTHER_REALM = 'other realm';

my $ring = get_keyring(app_name=>"Passwd::Keyring::Auto unit tests", group=>"test 02");

ok( defined($ring),   'get_keyring() works' );

ok( ! defined($ring->get_password("Paul", $SOME_REALM)), "get do not find phantoms");

SKIP: {
    skip "Using non-persistent keyring", 11 unless $ring->is_persistent;

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

