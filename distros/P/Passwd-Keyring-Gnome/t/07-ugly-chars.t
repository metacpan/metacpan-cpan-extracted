#!perl -T

use strict;
use warnings;
use Test::More;

if($ENV{GNOME_KEYRING_CONTROL}) {
    plan tests => 4;
} else {
    plan skip_all => "Keyring not available (not running under Gnome?), skipping tests";
}


use Passwd::Keyring::Gnome;

my $UGLY_NAME = "Joh ## no ^^ »ąćęłóśż«";
my $UGLY_PWD =  "«tajne hasło»";
my $UGLY_REALM = '«do»–main';

my $ring = Passwd::Keyring::Gnome->new(app=>"Passwd::Gnome::Keyring unit tests", group=>"Ugly chars");

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome',   'new() works' );

$ring->set_password($UGLY_NAME, $UGLY_PWD, $UGLY_REALM);

ok( 1, "set_password with ugly chars works" );

ok( $ring->get_password($UGLY_NAME, $UGLY_REALM) eq $UGLY_PWD, "get works with ugly characters");

ok( $ring->clear_password($UGLY_NAME, $UGLY_REALM) eq 1, "clear clears");

