package My::Redis;

use strict;
use warnings;

use Digest::SHA qw( sha1_hex );

sub info {
    return { redis_version => $_[0]{version} };
}

sub script_load {
    return sha1_hex( $_[1] );
}

sub set {
    die "JUST MOCKING AROUND";
}

1;

# vim: ts=4 sw=4 et:
