#!perl -T

use strict;
use warnings;
use Test::More;

use Passwd::Keyring::Auto qw(get_keyring);

BEGIN {
    plan skip_all => "These tests don't run well under root"
      unless $>;
}
plan tests => 11;

my $SOME_REALM = 'my@@realm';
my $OTHER_REALM = 'other realm';

my $ring = get_keyring(
    app_name=>"Passwd::Keyring::Auto unit tests",
    group=>"test 02");

ok( defined($ring),   'new() works' );

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

# Note: cleanup is performed by test 03, we test passing data to
#       separate program.

