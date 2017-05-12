use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

{
    package MyClass;
    use Moose;
    use MooseX::AlwaysCoerce;
    use Moose::Util::TypeConstraints;

    subtype 'MyType', as 'Int';
    coerce 'MyType', from 'Str', via { length $_ };

    subtype 'Uncoerced', as 'Int';

    has foo => (is => 'rw', isa => 'MyType');

    class_has bar => (is => 'rw', isa => 'MyType');

    class_has baz => (is => 'rw', isa => 'MyType', coerce => 0);

    has quux => (is => 'rw', isa => 'MyType', coerce => 0);

    has uncoerced_attr => (is => 'rw', isa => 'Uncoerced');

    class_has uncoerced_class_attr => (is => 'rw', isa => 'Uncoerced');

    has untyped_attr => (is => 'rw');

    class_has untyped_class_attr => (is => 'rw');
}

ok( (my $instance = MyClass->new), 'instance' );

is(
    exception {
        $instance->foo('bar');
        is $instance->foo, 3;
    },
    undef,
    'attribute coercion ran',
);

is(
    exception {
        $instance->bar('baz');
        is $instance->bar, 3;
    },
    undef,
    'class attribute coercion ran',
);

isnt(
    exception { $instance->baz('quux') },
    undef,
    'class attribute coercion did not run with coerce => 0',
);

isnt(
    exception{ $instance->quux('mtfnpy') },
    undef,
    'attribute coercion did not run with coerce => 0',
);

is(
    exception {
        $instance->uncoerced_attr(10);
        is $instance->uncoerced_attr(10), 10;
    },
    undef,
    'set attribute having type with no coercion and no coerce=0',
);

is(
    exception {
        $instance->uncoerced_class_attr(10);
        is $instance->uncoerced_class_attr(10), 10;
    },
    undef,
    'set class attribute having type with no coercion and no coerce=0',
);

is(
    exception {
        $instance->untyped_attr(10);
        is $instance->untyped_attr, 10;
    },
    undef,
    'set untyped attribute',
);

is(
    exception {
        $instance->untyped_class_attr(10);
        is $instance->untyped_class_attr, 10;
    },
    undef,
    'set untyped class attribute',
);

done_testing;
