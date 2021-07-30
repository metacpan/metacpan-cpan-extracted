use strict;
use warnings;

use Test::More;

eval q{
    package Foo;

    use Mouse::Util::TypeConstraints;

    coerce class_type('Foo')
        => from 'Int'
        => via { Foo->new(bar => @_) };

    use Moo;
    use MooX::MouseTypeConstraints;

    has bar => (
        is  => 'ro',
        isa => 'Int',
    );

    package Bar;

    use MooX::MouseTypeConstraints;
    use Moo;

    has foo => (
        is  => 'ro',
        isa => 'Foo',
    );
};
is $@, '', 'should not fail when declaring';

eval {
    my $foo = Foo->new(bar => 1);
    my $bar = Bar->new(foo => $foo);
};
is $@, '', 'should not fail to construct';

eval {
    my $bar = Bar->new(foo => 1);
};
is $@, '', 'should not fail to construct with coerce target type';
note $@;

eval {
    my $bar = Bar->new(foo => 'foo');
};
isnt $@, '', 'should fail to construct with invalid Foo';
note $@;

done_testing;
