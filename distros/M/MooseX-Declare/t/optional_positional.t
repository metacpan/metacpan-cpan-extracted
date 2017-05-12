use strict;
use warnings;

use Test::More tests => 3;
use Test::Fatal;

use MooseX::Declare;

class ValueHolder {
    has value => (
        is => 'rw',
        isa => 'Any',
    );

    around value ($newval?) {
        $orig->($newval);
    }

    method method1 ($argument?) {
        +@_;
    }
}

is( exception {
    ValueHolder->new(value => 22)->value;
}, undef, 'value() should not die');

is( exception {
    is(ValueHolder->new->method1, 1, 'method1() should only get 1 element in @_');
}, undef, 'nor should method1()');
