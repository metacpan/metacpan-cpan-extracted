#!perl -T

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

unless($ENV{PWSAFE_SKIP_TEST}) {
    plan tests => 2;
} else {
    plan skip_all => "Skipped as PWSAFE_SKIP_TEST is set.";
}

use Passwd::Keyring::PWSafe3;

my $DBFILE = File::Spec->catfile($FindBin::Bin, "test.psafe3");

my $ring = new_ok(
    "Passwd::Keyring::PWSafe3" => [
        file=>$DBFILE, master_password=>"10101010" ],
    "Properly setup - new(file=>$DBFILE)");

ok( $ring->is_persistent eq 1,
    "Ring is persistent - is_persistent");

