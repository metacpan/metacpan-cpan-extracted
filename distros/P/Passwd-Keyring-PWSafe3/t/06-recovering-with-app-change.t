#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

unless($ENV{PWSAFE_SKIP_TEST}) {
    plan tests => 18;
} else {
    plan skip_all => "Skipped as PWSAFE_SKIP_TEST is set.";
}

use Passwd::Keyring::PWSafe3;

my $DBFILE = File::Spec->catfile($FindBin::Bin, "test.psafe3");

my $USER = "Herakliusz";
my $REALM = "test realm";
my $PWD = "arcytajne haslo";
my $PWD2 = "inny sekret";

my $APP1 = "Passwd::Keyring::Unit tests (1)";
my $APP2 = "Passwd::Keyring::Unit tests (2)";
my $GROUP1 = "Passwd::Keyring::Unit tests - group 1";
my $GROUP2 = "Passwd::Keyring::Unit tests - group 2";
my $GROUP3 = "Passwd::Keyring::Unit tests - group 3";

{
    my $ring = new_ok(
        "Passwd::Keyring::PWSafe3" => [
            app=>$APP1, group=>$GROUP1,
            file=>$DBFILE, master_password=>"10101010",
            lazy_save=>1 ],
        "Properly setup - new(file=>$DBFILE, group=>$GROUP1, lazy_save=>1, app=>$APP1)" );

    ok( ! defined($ring->get_password($USER, $REALM)), 
        "initially unset - get_password($USER, $REALM)");

    $ring->set_password($USER, $PWD, $REALM);
    ok( 1, "Properly set - set_password($USER, $PWD, $REALM)" );

    is(  $ring->get_password($USER, $REALM), $PWD,
        "Properly got back - get_password($USER, $REALM)");

    $ring->save();
}


# Another object with the same app and group

{
    my $ring = new_ok(
        "Passwd::Keyring::PWSafe3" => [
            app=>$APP1, group=>$GROUP1,
            file=>$DBFILE, master_password=>"10101010" ],
        "Properly setup identical as prev - new(file=>$DBFILE, group=>$GROUP1, app=>$APP1)" );

    is(  $ring->get_password($USER, $REALM), $PWD,
        "get from another ring with the same data works");
}

# Only app changes
{
    my $ring = new_ok(
        "Passwd::Keyring::PWSafe3" => [
            app=>$APP2, group=>$GROUP1,
            file=>$DBFILE, master_password=>"10101010" ],
        "Properly setup changing app - new(file=>$DBFILE, group=>$GROUP1, lazy_save=>1, app=>$APP2)" );

    is(  $ring->get_password($USER, $REALM), $PWD,
        "get from another ring with changed app but same group works");
}

# Only group changes
{
    my $ring = new_ok(
        "Passwd::Keyring::PWSafe3" => [
            app=>$APP1, group=>$GROUP2,
            file=>$DBFILE, master_password=>"10101010" ],
        "Properly setup changing group - new(file=>$DBFILE, group=>$GROUP2, app=>$APP1)" );

    ok( ! defined($ring->get_password($USER, $REALM)), "changing group forces another password");

    # To test whether original won't be spoiled
    $ring->set_password($USER, $PWD2, $REALM);
    ok( 1, "Properly set - set_password($USER, $PWD2, $REALM)" );
}

# App and group change
{
    my $ring = new_ok(
        "Passwd::Keyring::PWSafe3" => [
            app=>$APP2, group=>$GROUP3,
            file=>$DBFILE, master_password=>"10101010" ],
        "Properly setup changing group and app - new(file=>$DBFILE, group=>$GROUP2, app=>$APP2)" );

    ok( ! defined($ring->get_password($USER, $REALM)), "changing group and app forces another password");

}

# Re-reading original to check whether it was properly kept, and
# finally clearing it
{
    my $ring = new_ok(
        "Passwd::Keyring::PWSafe3" => [
            app=>$APP1, group=>$GROUP1,
            file=>$DBFILE, master_password=>"10101010" ],
        "Properly setup as original - new(file=>$DBFILE, group=>$GROUP1, app=>$APP1)" );

    is( $ring->get_password($USER, $REALM), $PWD,
        "get original after changes in other group works");

    ok( $ring->clear_password($USER, $REALM) eq 1, "clearing");
}

# Clearing the remaining 
{
    my $ring = new_ok(
        "Passwd::Keyring::PWSafe3" => [
            app=>$APP1, group=>$GROUP2,
            file=>$DBFILE, master_password=>"10101010" ]);

    ok( $ring->clear_password($USER, $REALM) eq 1, "clearing");
}


