package Net::TinyIp::Address::v4;
use strict;
use warnings;
use base "Net::TinyIp::Address";
use Readonly;

Readonly our $VERSION        => 4;
Readonly our $BITS_PER_BLOCK => 8;
Readonly our $BLOCK_LENGTH   => 4;
Readonly our $BITS_LENGTH    => $BITS_PER_BLOCK * $BLOCK_LENGTH;
Readonly our $SEPARATOR      => q{.};

our $BLOCK_FORMAT = q{%03d};

sub from_string {
    my $class = shift;
    my $str   = shift;

    return $class->from_bin( join q{}, q{0b}, map { sprintf "%0${BITS_PER_BLOCK}b", $_ } split m{[$SEPARATOR]}, $str );
}

1;

