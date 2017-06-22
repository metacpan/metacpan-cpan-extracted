#!perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;

BEGIN {
    use_ok('MOP');
}

=pod

This test

=cut

{
    package Foo;
    use Moxie;

    extends 'Moxie::Object';

    has foo => sub { 'foo' };

    sub BUILDARGS : init_args(
        bar => 'foo',
        baz => 'foo',
    );

    sub foo : ro;
    sub bar { $_[0]->{bar} }
    sub baz { $_[0]->{baz} }
}


{
    my $foo = Foo->new;
    isa_ok($foo, 'Foo');

    is($foo->foo, 'foo', '... the generated accessor worked as expected');
    is($foo->bar, undef, '... the generated accessor worked as expected');
    is($foo->baz, undef, '... the generated accessor worked as expected');
}

{
    my $foo = Foo->new( foo => 'FOOOOOO' );
    isa_ok($foo, 'Foo');

    is($foo->foo, 'FOOOOOO', '... the generated BUILDARGS worked as expected');
    is($foo->bar, undef, '... the generated BUILDARGS worked as expected');
    is($foo->baz, undef, '... the generated BUILDARGS worked as expected');
}

{
    my $foo = Foo->new( bar => 'BAR' );
    isa_ok($foo, 'Foo');

    is($foo->foo, 'BAR', '... the generated BUILDARGS worked as expected');
    is($foo->bar, undef, '... the generated BUILDARGS worked as expected');
    is($foo->baz, undef, '... the generated BUILDARGS worked as expected');
}

{
    my $foo = Foo->new( baz => 'BAZ' );
    isa_ok($foo, 'Foo');

    is($foo->foo, 'BAZ', '... the generated BUILDARGS worked as expected');
    is($foo->bar, undef, '... the generated BUILDARGS worked as expected');
    is($foo->baz, undef, '... the generated BUILDARGS worked as expected');
}

{
    my $foo = Foo->new( foo => 'FOO', bar => 'BAR', baz => 'BAZ' );
    isa_ok($foo, 'Foo');

    like($foo->foo, qr/BA[R|Z]/, '... the generated BUILDARGS worked as expected');
    is($foo->bar, undef, '... the generated BUILDARGS worked as expected');
    is($foo->baz, undef, '... the generated BUILDARGS worked as expected');
}

done_testing;

