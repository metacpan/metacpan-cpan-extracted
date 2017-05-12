#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

unless($ENV{PWSAFE_SKIP_TEST}) {
    plan tests => 14;
} else {
    plan skip_all => "Skipped as PWSAFE_SKIP_TEST is set.";
}

use Passwd::Keyring::PWSafe3;

my $DBFILE = File::Spec->catfile($FindBin::Bin, "test.psafe3");
my $SOME_REALM = 'my@@realm';
my $OTHER_REALM = 'other realm';

diag("This assumes 03-many-sets-and-gets.t was run and filled $DBFILE.");

my $ring = new_ok(
    "Passwd::Keyring::PWSafe3" => [
        app=>"Passwd::Keyring::PWSafe3", group=>"Unit tests",
        file=>$DBFILE, master_password=>sub {"10101010"},
        lazy_save => 1 ],
    "Properly setup - new(file=>$DBFILE, group=>Unit tests, lazy_save=>1)" );

ok( ! defined($ring->get_password("Paul", $SOME_REALM)),
    "Got password back -> get_password(Paul, $SOME_REALM)");

is( $ring->get_password("Gregory", $SOME_REALM), 'secret-Greg',
    "Got password back -> get_password(Gregory, $SOME_REALM)");

is(  $ring->get_password("Paul", $OTHER_REALM), 'secret-Paul2',
    "Got password back -> get_password(Paul, $SOME_REALM)");

is(  $ring->get_password("Duke", $SOME_REALM), 'secret-Duke',
    "Got password back -> get_password(Duke, $SOME_REALM)");

ok( $ring->clear_password("Gregory", $SOME_REALM) eq 1,
    "Cleared properly -> clear_password(Gregory, $SOME_REALM)");

ok( ! defined($ring->get_password("Gregory", $SOME_REALM)),
    "Nothing to clear -> clear_password(Gregory, $SOME_REALM)");

is(  $ring->get_password("Paul", $OTHER_REALM), 'secret-Paul2',
    "Got password back -> get_password(Paul, $OTHER_REALM)");

is(  $ring->get_password("Duke", $SOME_REALM), 'secret-Duke',
    "Got password back -> get_password(Duke, $SOME_REALM)");

ok( $ring->clear_password("Paul", $OTHER_REALM) eq 1,
    "Cleared properly -> clear_password(Paul, $OTHER_REALM)");

ok( $ring->clear_password("Duke", $SOME_REALM) eq 1,
    "Cleared properly -> clear_password(Duke, $SOME_REALM)");

ok( ! defined($ring->get_password("Paul", $SOME_REALM)), 
    "Got nothing after clear -> get_password(Paul, $SOME_REALM)");
ok( ! defined($ring->get_password("Duke", $SOME_REALM)),
    "Got nothing after clear -> get_password(Duke, $SOME_REALM)");

$ring->save();
ok( 1, "Save succeeded");


