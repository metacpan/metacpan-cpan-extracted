#!perl

use strict;
use warnings;
use Test::More;
unless($^O eq 'darwin') {
    plan skip_all => "Test relevant only to Mac OS/X";
} else {
    plan tests => 4;
}

use Passwd::Keyring::OSXKeychain;

my $APP = "Passwd::OSXKeychain::Keyring unit test 08 ";
$APP .= "X" x (256 - length($APP));
my $GROUP = "Passwd::OSXKeychain::Keyring unit tests ";
$GROUP .= "X" x (256 - length($GROUP));

my $USER = "A" x 256;
my $PWD =  "B" x 256;
my $REALM = 'C' x 256;

my $ring = Passwd::Keyring::OSXKeychain->new(
    app=>$APP, group=>$GROUP);

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::OSXKeychain',   'new() works with long params' );

$ring->set_password($USER, $PWD, $REALM);

ok( 1, "set_password with long params works" );

ok( $ring->get_password($USER, $REALM) eq $PWD, "get_password with long params works");

ok( $ring->clear_password($USER, $REALM) eq 1, "clear_password with long params works");

