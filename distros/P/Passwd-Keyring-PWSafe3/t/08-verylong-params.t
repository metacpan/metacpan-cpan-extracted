#!perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

unless($ENV{PWSAFE_SKIP_TEST}) {
    plan tests => 6;
} else {
    plan skip_all => "Skipped as PWSAFE_SKIP_TEST is set.";
}

use Passwd::Keyring::PWSafe3;

my $DBFILE = File::Spec->catfile($FindBin::Bin, "test.psafe3");

my $APP = "Passwd::PWSafe3::Keyring unit test 08 ";
$APP .= "X" x (256 - length($APP));
my $GROUP = "Passwd::PWSafe3::Keyring unit tests ";
$GROUP .= "X" x (256 - length($GROUP));

my $USER = "A" x 256;
my $PWD =  "B" x 256;
my $REALM = 'C' x 256;

# No lazy_save on purpose
my $ring = new_ok(
    "Passwd::Keyring::PWSafe3" => [
        app=>$APP, group=>$GROUP,
        file=>$DBFILE,
        master_password=> sub {
            my ($app, $file) = @_;
            is( $app, $APP, "master_password callback got proper app");
            is( $file, $DBFILE, "master_password callback got proper file");
            return "10101010";
        },
       ], "Properly setup with callback for master  - new(file=>$DBFILE, group=>$GROUP)" );

$ring->set_password($USER, $PWD, $REALM);
ok( 1, "Properly set long params - set_password($USER, $PWD, $REALM)" );

is( $ring->get_password($USER, $REALM), $PWD,
    "Got back long password - get_password($USER, $REALM)");

ok( $ring->clear_password($USER, $REALM) eq 1, 
    "Cleared long - clear_password($USER, $REALM)");

