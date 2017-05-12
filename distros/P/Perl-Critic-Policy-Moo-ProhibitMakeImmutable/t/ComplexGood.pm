package Foo;
use Moo;

{
    package Bar;
    use Moose;
    __PACKAGE__->meta->make_immutable;
}

package Baz;
use Moose;
__PACKAGE__->meta->make_immutable;

package Blar;
use Moo;
