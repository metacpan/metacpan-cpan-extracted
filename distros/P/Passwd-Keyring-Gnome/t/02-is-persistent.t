#!perl -T

use strict;
use warnings;
use Test::More;

if($ENV{GNOME_KEYRING_CONTROL}) {
    plan tests => 2;
} else {
    plan skip_all => "Keyring not available (not running under Gnome?), skipping tests";
}

use Passwd::Keyring::Gnome;

my $ring = Passwd::Keyring::Gnome->new;

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::Gnome',   'new() works' );

ok( $ring->is_persistent eq 1, "is_persistent knows we are persistent");

