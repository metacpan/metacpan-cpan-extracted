package Declared::WithTypeParams;

use 5.036;
use warnings FATAL => q{all};

use Type::Params    qw{signature_for};
use Types::Standard qw{Int Str};

signature_for add => ( positional => [ Int, Int, { default => 1 } ], returns => Int );

sub add {
    my ( $x, $y ) = @_;
    return $x + $y;
}

signature_for greet => ( method => 1, named => [ who => Str, times => Int, { optional => 1 } ] );

sub greet {
    my ( $self, $arg ) = @_;
    return $arg->who;
}

1;
