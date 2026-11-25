package Declared::WithMoo;

use 5.036;
use warnings FATAL => q{all};

use Moo;
use Types::Standard qw{Int Str};

has name => ( is => 'ro', isa => Str, required  => 1 );
has size => ( is => 'rw', isa => Int, predicate => 1 );

1;
