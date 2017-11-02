#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

=pod

Every new instance created should be a new reference
but it should link back to the same class data.

=cut

package Foo {
    use Moxie;

    extends 'Moxie::Object';
}

my $foo = Foo->new;
ok( $foo->isa( 'Foo' ), '... the object is from class Foo' );
ok( $foo->isa( 'UNIVERSAL::Object' ), '... the object is derived from class Object' );
is( Scalar::Util::blessed($foo), 'Foo', '... the class of this object is Foo' );

{
    my $foo2 = Foo->new;
    ok( $foo2->isa( 'Foo' ), '... the object is from class Foo' );
    ok( $foo2->isa( 'UNIVERSAL::Object' ), '... the object is derived from class Object' );
    is( Scalar::Util::blessed($foo), 'Foo', '... the class of this object is Foo' );

    isnt( $foo, $foo2, '... these are not the same objects' );
    is( Scalar::Util::blessed($foo), Scalar::Util::blessed($foo2), '... these two objects share the same class' );
}

package Bar {
    use Moxie;

    extends 'Moxie::Object';

    has _foo => ();

    my sub _foo : private;

    sub BUILDARGS : init( foo? => _foo );

    sub foo { _foo }
}

{
    my $bar = Bar->new;
    isa_ok($bar, 'Bar');
    is($bar->foo, undef, '... defaults to undef');
}

{
    my $bar = Bar->new( foo => 10 );
    isa_ok($bar, 'Bar');
    is($bar->foo, 10, '... keyword args to new work');
}

{
    my $bar = Bar->new({ foo => 10 });
    isa_ok($bar, 'Bar');
    is($bar->foo, 10, '... keyword args to new work');
}

done_testing;
