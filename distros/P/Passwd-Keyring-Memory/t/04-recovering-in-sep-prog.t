#!perl -T

use strict;
use warnings;
#use Test::Simple tests => 13;
use Test::More skip_all => 'Passwd::Keyring::Memory is volatile';

use Passwd::Keyring::Memory;

my $SOME_REALM = 'my@@realm';
my $OTHER_REALM = 'other realm';

my $ring = Passwd::Keyring::Memory->new(app=>"Passwd::Keyring::Memory", group=>"Unit tests");

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Memory',   'new() works' );

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



