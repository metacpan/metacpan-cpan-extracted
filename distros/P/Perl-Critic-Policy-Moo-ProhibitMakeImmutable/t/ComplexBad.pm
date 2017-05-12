package Foo;
use Moose;

{
    package Bar;
    use Moo;
    do { __PACKAGE__->meta->make_immutable; }
}

package Baz;
use Moo;

package Blar;
use Moose;
__PACKAGE__->meta->make_immutable;
