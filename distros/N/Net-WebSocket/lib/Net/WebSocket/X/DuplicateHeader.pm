package Net::WebSocket::X::DuplicateHeader;

use strict;
use warnings;

use parent qw( Net::WebSocket::X::Base );

sub _new {
    my ($class, $name => @values) = @_;

    my @args = (
        name => $name,
        values => \@values,
    );

    my @values_str = map { defined ? $_ : q<> } @values;

    return $class->SUPER::_new(
        sprintf('Received multiple values (%s) for “%s” header', join(',', @values_str), $name),
        @args,
    );
}

1;
