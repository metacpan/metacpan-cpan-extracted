#!perl -T

use strict;
use warnings;
use Test::Simple tests => 4;

use Passwd::Keyring::Memory;

my $UGLY_NAME = "Joh ## no ^^ »ąćęłóśż«";
my $UGLY_PWD =  "«tajne hasło»";
my $UGLY_REALM = '«do»–main';

my $ring = Passwd::Keyring::Memory->new(app=>"Passwd::Memory::Keyring unit tests", group=>"Ugly chars");

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Memory',   'new() works' );

$ring->set_password($UGLY_NAME, $UGLY_PWD, $UGLY_REALM);

ok( 1, "set_password with ugly chars works" );

ok( $ring->get_password($UGLY_NAME, $UGLY_REALM) eq $UGLY_PWD, "get works with ugly characters");

ok( $ring->clear_password($UGLY_NAME, $UGLY_REALM) eq 1, "clear clears");

