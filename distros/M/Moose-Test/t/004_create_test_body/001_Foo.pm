package Foo;
use Mouse;

has 'bar' => (is => 'rw', isa => 'Str');
has 'baz' => (is => 'rw', isa => 'Str');

1;