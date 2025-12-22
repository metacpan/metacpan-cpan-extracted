# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Monero-Keys.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 8;
use parent qw(Test::Class);
use Monero::Keys;

sub seed_key_generation: Tests {
    my $sc = "\x2f\xbb\xd0\xe9\xe7\x88\x6a\xcb\xc3\x22\x29\x23\xa0\xe5\xaa\x8e\x78\xc2\x75\xc8\x7d\x2e\x6e\xa5\xbf\x01\x32\xf2\x43\x01\x3f\x02";
    my $keys = Monero::Keys::generate_keys($sc);
    is (unpack("H*", $keys->{spend_pk}),  "2fbbd0e9e7886acbc3222923a0e5aa8e78c275c87d2e6ea5bf0132f243013f02");
    is (unpack("H*", $keys->{spend_pub}), "991fef2230ceecb6523179646e1795cdc7c216cc7ffdc317e997b62db51fd00c");
    is (unpack("H*", $keys->{view_pk}),   "cf79310435b9d9b87e0429ea7508e990b760f232e5487ed9ce7545ec15493b0b");
    is (unpack("H*", $keys->{view_pub}),   "fe8e4a7770e12f0f59fb4f9e1e13053078625c2c2edd2ff9b5ee4a71ba3cf9bb");
}

sub seed_above_l: Tests {
    my $sc = "\xc6\x5c\x27\xfb\xc5\xbb\x1e\x53\x2e\x10\x11\xd9\x38\xdb\xbf\x25\xe5\x4c\xc5\x0f\x9a\xd8\x53\x0b\x12\x55\x87\x25\xf3\xfb\xb0\xf2";
    my $keys = Monero::Keys::generate_keys($sc);
    is(unpack("H*", $keys->{spend_pk}), "e3f1bf883aed0a2a9fdf8e4c2d37afece34cc50f9ad8530b12558725f3fbb002");
}

sub seed_is_zero: Tests {
    my $sc = "\x00" x 32;
    my $keys = Monero::Keys::generate_keys($sc);
    is ($keys, undef);
}

sub seed_is_eq_l: Tests {
    my $sc = "\xe3\x6a\x67\x72\x8b\xce\x13\x29\x8f\x30\x82\x8c\x0b\xa4\x10\x39\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xf0";
    my $keys = Monero::Keys::generate_keys($sc);
    is ($keys, undef);
}

sub seed_is_short_key: Tests {
    my $sc = "\xde";
    my $keys = Monero::Keys::generate_keys($sc);
    ok( $keys );
}

__PACKAGE__->runtests;
