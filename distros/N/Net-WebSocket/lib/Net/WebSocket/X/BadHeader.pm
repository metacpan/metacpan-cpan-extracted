package Net::WebSocket::X::BadHeader;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $name => $value, $why) = @_;

    my @args = (
        name => $name,
        value => $value,
        why => $why,
    );

    my $value_str = defined($value) ? $value : q<>;

    my $str = length($why) ? "Bad “$name” header ($value_str): $why" : "Bad “$name” header ($value_str)";

    return $class->SUPER::_new( $str, @args );
}

1;
