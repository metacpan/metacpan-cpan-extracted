#!perl -T

use strict;
use warnings;
use Test::More;

if($ENV{GNOME_KEYRING_CONTROL}) {
    plan tests => 8;
} else {
    plan skip_all => "Keyring not available (not running under Gnome?), skipping tests";
}


use Passwd::Keyring::Gnome;

my $ring = Passwd::Keyring::Gnome->new;

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome',   'new() works' );

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
