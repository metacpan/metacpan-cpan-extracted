#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use File::Copy;

# Copying example database
copy(File::Spec->catfile($FindBin::Bin, "sampledb", "test.psafe3"),
     $FindBin::Bin);

unless($ENV{PWSAFE_SKIP_TEST}) {
    plan tests => 8;
} else {
    plan skip_all => "Skipped as PWSAFE_SKIP_TEST is set.";
}

use Passwd::Keyring::PWSafe3;

my $DBFILE = File::Spec->catfile($FindBin::Bin, "test.psafe3");

# No lazy_save, on purpose, let's check also no lazy save mode
my $ring = new_ok(
    "Passwd::Keyring::PWSafe3" => [
        file=>$DBFILE, master_password=>"10101010" ], 
    "Correctly setup non-lazy - new($DBFILE)" );

my $USER = 'John';
my $PASSWORD = 'verysecret';
my $REALM = 'some simple realm';

$ring->set_password($USER, $PASSWORD, $REALM);

ok( 1,
    "Properly set - set_password($USER, $PASSWORD, $REALM)" );

is( $ring->get_password($USER, $REALM), $PASSWORD,
    "Got password back - get_password($USER, $REALM)");

is( $ring->clear_password($USER, $REALM), 1,
    "Cleared - clear_password($USER, $REALM)" );

is( $ring->get_password($USER, $REALM), undef,
    "Got nothing back after clear - get_password($USER, $REALM)");

is( $ring->clear_password($USER, $REALM), 0,
    "Nothing more to clear - clear_password($USER, $REALM)" );

my $NON_USER = "Non user";
is( $ring->clear_password($NON_USER, $REALM), 0,
    "Nothing to clear for unknown user - clear_password($NON_USER, $REALM)" );

my $NON_REALM = "non realm";
is( $ring->clear_password("$USER", $NON_REALM), 0, 
    "Nothing to clear for unknown realm - clear_password($USER, $NON_REALM");

