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

my $ring = new_ok(
    "Passwd::Keyring::PWSafe3" => [
        app=>"Passwd::Keyring::PWSafe3", group=>"Unit tests",
        file=>$DBFILE, master_password=>"10101010",
        lazy_save=>1],
    "Properly setup - new(file=>$DBFILE, group=>Unit tests, lazy_save=>1)" );

$ring->set_password("Paul", "secret-Paul", $SOME_REALM);
ok( 1, "Properly set - set_password(Paul, secret-Paul, $SOME_REALM)" );
$ring->set_password("Gregory", "secret-Greg", $SOME_REALM);
ok( 1, "Properly set - set_password(Gregory, secret-Greg, $SOME_REALM)" );#
$ring->set_password("Paul", "secret-Paul2", $OTHER_REALM);
ok( 1, "Properly set - set_password(Paul, secret-Paul2, $OTHER_REALM)" );
$ring->set_password("Duke", "secret-Duke", $SOME_REALM);
ok( 1, "Properly set - set_password(Duke, secret-Duke, $SOME_REALM)" );

is( $ring->get_password("Paul", $SOME_REALM), 'secret-Paul',
    "got password back - get_password(Paul, $SOME_REALM)");

is( $ring->get_password("Gregory", $SOME_REALM), 'secret-Greg',
    "got password back - get_password(Gregory, $SOME_REALM)");

is( $ring->get_password("Paul", $OTHER_REALM), 'secret-Paul2',
    "got password back - get_password(Paul, $OTHER_REALM)");

is( $ring->get_password("Duke", $SOME_REALM), 'secret-Duke', 
    "got password back - get_password(Duke, $SOME_REALM)");

is( $ring->clear_password("Paul", $SOME_REALM), 1,
    "clear_password removed sth - clear_password(Paul, $SOME_REALM)");

ok( ! defined($ring->get_password("Paul", $SOME_REALM)),
    "got password back - get_password(Paul, $SOME_REALM)");

is( $ring->get_password("Gregory", $SOME_REALM), 'secret-Greg',
    "got password back - get_password(Gregory, $SOME_REALM)");

is(  $ring->get_password("Paul", $OTHER_REALM), 'secret-Paul2',
    "got password back - get_password(Paul, $OTHER_REALM)");

is(  $ring->get_password("Duke", $SOME_REALM), 'secret-Duke',
    "got password back - get_password(Duke, $SOME_REALM)");

diag( "No save, on purpose, destructor is to fire.");
diag( "04-recovering-in-sep-prog.t is to recover saved data (in separate process)." );
# No ring->save, on purpose, let's test destructor
#$ring->save();
#ok( 1, "Save succeeded");

# Note: cleanup is performed by test 04, we test passing data to
#       separate program.
