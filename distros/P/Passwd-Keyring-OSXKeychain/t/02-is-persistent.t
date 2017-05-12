#!perl

use strict;
use warnings;
use Test::More;

unless($^O eq 'darwin') {
    plan skip_all => "Test relevant only to Mac OS/X";
} else {
    plan tests => 2;
}

use Passwd::Keyring::OSXKeychain;

my $ring = Passwd::Keyring::OSXKeychain->new;

ok( defined($ring) && ref $ring eq 'Passwd::Keyring::OSXKeychain',   'new() works' );

ok( $ring->is_persistent eq 1, "is_persistent knows we are persistent");

