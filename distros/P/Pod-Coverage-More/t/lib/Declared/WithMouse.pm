package Declared::WithMouse;

use 5.036;
use warnings FATAL => q{all};

use Mouse;

has name => ( is => 'rw', isa => 'Str', required => 1, predicate => 'has_name' );

__PACKAGE__->meta->make_immutable;

1;
