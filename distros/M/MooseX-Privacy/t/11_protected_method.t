use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use Test::Moose;

{

    package Foo;
    use Moose;
    use MooseX::Privacy;

    protected_method 'bar' => sub {
        my $self = shift;
        return 'baz';
    };
}

{

    package Bar;
    use Moose;
    extends 'Foo';

    sub baz {
        my $self = shift;
        return $self->bar;
    }
}

with_immutable {
    my $foo = Foo->new();
    isa_ok( $foo, 'Foo' );
    dies_ok { $foo->bar } "... can't call bar, method is protected";

    my $bar = Bar->new();
    isa_ok( $bar, 'Bar' );
    is $bar->baz(), 'baz', "... got the good value from &bar";

    is $foo->meta->_count_protected_methods, 1, "... got one protected method";
}
(qw/Foo Bar/);

