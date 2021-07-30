use strict;
use warnings;

use Test::More;

eval q{
    package Foo;

    use Moo;
    use MooX::MouseTypeConstraints;

    has bar => (
        is  => 'ro',
        isa => 'Int',
    );
};
is $@, '', 'should not fail when declaring';

eval q{
    package Bar;

    use MooX::MouseTypeConstraints;
    use Moo;

    has foo => (
        is  => 'ro',
        isa => 'Foo',
    );
};
is $@, '', 'should works regardless of the order of "use"';

eval q{
    package Baz;
    use MooX::MouseTypeConstraints;
};
isnt $@, '', 'should fail with non Moo based class';

eval {
    my $foo = Foo->new(bar => 1);
    my $bar = Bar->new(foo => $foo);
};
is $@, '', 'should not fail construct';

eval {
    my $foo = Foo->new(bar => 'invalid');
    my $bar = Bar->new(foo => $foo);
};
isnt $@, '', 'should fail to construct with invalid Int';
note $@;

eval {
    my $foo = Foo->new(bar => 1);
    my $bar = Bar->new(foo => $foo);
    Bar->new(foo => $bar);
};
isnt $@, '', 'should fail to construct with invalid Foo';
note $@;

done_testing;
