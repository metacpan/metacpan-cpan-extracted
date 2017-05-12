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

my $APP = "Passwd::Gnome::Keyring unit test 08 ";
$APP .= "X" x (256 - length($APP));
my $GROUP = "Passwd::Gnome::Keyring unit tests ";
$GROUP .= "X" x (256 - length($GROUP));

my $USER = "A" x 256;
my $PWD =  "B" x 256;
my $REALM = 'C' x 256;

my $ring = Passwd::Keyring::Gnome->new(
    app=>$APP, group=>$GROUP);

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome',   'new() works with long params' );

$ring->set_password($USER, $PWD, $REALM);

ok( 1, "set_password with long params works" );

ok( $ring->get_password($USER, $REALM) eq $PWD, "get_password with long params works");

ok( $ring->clear_password($USER, $REALM) eq 1, "clear_password with long params works");

