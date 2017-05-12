package Bar;
use Mouse;

extends 'Foo';

has 'bar' => (is => 'rw', isa => 'Str');
has 'foo' => (is => 'rw', isa => 'Str');

1;