#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

unless($ENV{PWSAFE_SKIP_TEST}) {
    plan tests => 4;
} else {
    plan skip_all => "Skipped as PWSAFE_SKIP_TEST is set.";
}

use Passwd::Keyring::PWSafe3;

my $DBFILE = File::Spec->catfile($FindBin::Bin, "test.psafe3");

my $UGLY_NAME = "Joh ## no ^^ »ąćęłóśż«";
my $UGLY_PWD =  "«tajne hasło»";
my $UGLY_REALM = '«do»–main';

# NO lazy_save on purpose
my $ring = new_ok(
    "Passwd::Keyring::PWSafe3" => [
        app=>"Passwd::PWSafe3::Keyring unit tests", group=>"Ugly chars",
        file=>$DBFILE, master_password=>"10101010" ],
    "Properly setup  - new(file=>$DBFILE, group=>Ugly chars)" );

$ring->set_password($UGLY_NAME, $UGLY_PWD, $UGLY_REALM);
ok( 1, "Properly set (ugly chars) - set_password($UGLY_NAME, $UGLY_PWD, $UGLY_REALM)" );

is( $ring->get_password($UGLY_NAME, $UGLY_REALM), $UGLY_PWD,
    "Properly got back (ugly chars) - get_password($UGLY_NAME, $UGLY_REALM)");

is( $ring->clear_password($UGLY_NAME, $UGLY_REALM), 1,
    "Properly cleared (ugly chars) - clear_password($UGLY_NAME, $UGLY_REALM)");

