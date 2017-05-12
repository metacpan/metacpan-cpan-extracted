package Net::TinyIp::Address::v6;
use strict;
use warnings;
use base "Net::TinyIp::Address";
use Readonly;

Readonly our $VERSION        => 6;
Readonly our $BITS_PER_BLOCK => 16;
Readonly our $BLOCK_LENGTH   => 8;
Readonly our $BITS_LENGTH    => $BITS_PER_BLOCK * $BLOCK_LENGTH;
Readonly our $SEPARATOR      => q{:};

our $BLOCK_FORMAT = q{%04x};

sub from_string {
    my $class = shift;
    my $str   = shift;

    return $class->from_hex( join q{}, q{0x}, map { $_ } split m{[$SEPARATOR]}, $str );
}

1;

