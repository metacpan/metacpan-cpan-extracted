#!perl

use strict;
use warnings;
use Test::More;

unless($^O eq 'darwin') {
    plan skip_all => "Test relevant only to Mac OS/X";
} else {
    plan tests => 8;
}

use Passwd::Keyring::OSXKeychain;

my $ring = Passwd::Keyring::OSXKeychain->new;

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::OSXKeychain',   'new() works' );

my $USER = 'John';
my $PASSWORD = 'verysecret';

$ring->set_password($USER, $PASSWORD, 'my@@realm');

ok( 1, "set_password works" );

ok( $ring->get_password($USER, 'my@@realm') eq $PASSWORD, "get recovers");

ok( $ring->clear_password($USER, 'my@@realm') eq 1, "clear_password removed one password" );

ok( !defined($ring->get_password($USER, 'my@@realm')), "no password after clear");

ok( $ring->clear_password($USER, 'my@@realm') eq 0, "clear_password again has nothing to clear" );

ok( $ring->clear_password("Non user", 'my@@realm') eq 0, "clear_password for unknown user has nothing to clear" );
ok( $ring->clear_password("$USER", 'non realm') eq 0, "clear_password for unknown realm has nothing to clear" );
