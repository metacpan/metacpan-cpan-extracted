#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

{
    package BaseObject;
    BEGIN { $INC{'BaseObject.pm'} = __FILE__ }
    use strict;
    use warnings;

    sub new { bless {} => shift }

    sub hello { 'Object::hello' }
}


{
    package Foo;
    use Moxie;

    extends 'Moxie::Object', 'BaseObject';

    sub REPR {
        my ($class, $proto) = @_;
        $class->BaseObject::new( %$proto );
    }

    sub bar { 'Foo::bar' }
}

{
    package Bar;
    use Moxie;

    extends 'Foo';

    sub baz { 'Bar::baz' }
}

my $foo = Foo->new;
is($foo->bar, 'Foo::bar', '... got the value we expected from $foo->bar');

is(Foo->bar, 'Foo::bar', '... got the value we expected from Foo->bar');

my $bar = Bar->new;
is($bar->baz, 'Bar::baz', '... got the value we expected from $bar->baz');
is($bar->bar, 'Foo::bar', '... got the value we expected from $bar->bar');

is(Bar->baz, 'Bar::baz', '... got the value we expected from Bar->baz');
is(Bar->bar, 'Foo::bar', '... got the value we expected from Bar->bar');

is(Bar->hello, 'Object::hello', '... got the value we expected from Bar->hello');
is(Foo->hello, 'Object::hello', '... got the value we expected from Foo->hello');

is_deeply(
    mro::get_linear_isa('Foo'),
    [ 'Foo', 'Moxie::Object', 'UNIVERSAL::Object', 'BaseObject' ],
    '... got the expected linear isa'
);

is_deeply(
    mro::get_linear_isa('Bar'),
    [ 'Bar', 'Foo', 'Moxie::Object', 'UNIVERSAL::Object', 'BaseObject' ],
    '... got the expected linear isa'
);

done_testing;


