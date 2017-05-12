#!perl

use strict;
use warnings;
use Test::More;
unless($^O eq 'darwin') {
    plan skip_all => "Test relevant only to Mac OS/X";
} else {
    plan tests => 13;
}


use Passwd::Keyring::OSXKeychain;

my $SOME_REALM = 'my@@realm';
my $OTHER_REALM = 'other realm';

my $ring = Passwd::Keyring::OSXKeychain->new(app=>"Passwd::Keyring::OSXKeychain", group=>"Unit tests");

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::OSXKeychain',   'new() works' );

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



