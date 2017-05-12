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

my $UGLY_NAME = "Joh ## no ^^ »ąćęłóśż«";
my $UGLY_PWD =  "«tajne hasło»";
my $UGLY_REALM = '«do»–main';

my $ring = Passwd::Keyring::OSXKeychain->new(app=>"Passwd::OSXKeychain::Keyring unit tests", group=>"Ugly chars");

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::OSXKeychain',   'new() works' );

$ring->set_password($UGLY_NAME, $UGLY_PWD, $UGLY_REALM);

ok( 1, "set_password with ugly chars works" );

ok( $ring->get_password($UGLY_NAME, $UGLY_REALM) eq $UGLY_PWD, "get works with ugly characters");

ok( $ring->clear_password($UGLY_NAME, $UGLY_REALM) eq 1, "clear clears");

