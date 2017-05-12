use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;
use Test::Moose;

{

    package Foo;
    use Moose;
    use MooseX::Privacy;

    private_method bar => sub {
        my $self = shift;
        return 'baz';
    };

    sub baz {
        my $self = shift;
        return $self->bar;
    }

    sub foo {
        my $self = shift;
        return $self->foobar(shift);
    }

    private_method 'foobar' => sub {
        my $self = shift;
        my $str  = shift;
        return 'foobar' . $str;
    };

}

{

    package Bar;
    use Moose;
    extends 'Foo';

    sub newbar {
        my $self = shift;
        return $self->bar;
    }
}

with_immutable {
    my $foo = Foo->new();
    isa_ok( $foo, 'Foo' );
    dies_ok { $foo->bar } "... can't call bar, method is private";
    is $foo->baz, 'baz', "... got the good value from &baz";
    is $foo->foo('baz'), 'foobarbaz', "... got the good value from &foobar";
    my $bar = Bar->new();
    isa_ok( $bar, 'Bar' );
    dies_ok { $bar->newbar() } "... can't call bar, method is private";

    is $foo->meta->_count_private_methods, 2, "... got two privates method";
}
(qw/Foo Bar/);



