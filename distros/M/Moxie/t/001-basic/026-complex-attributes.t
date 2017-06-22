#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use MOP;

=pod

...

=cut

package Bar {
    use Moxie;

    extends 'Moxie::Object';
}

package Foo {
    use Moxie;

    extends 'Moxie::Object';

    has 'bar' => sub { Bar->new };

    sub bar       : ro;
    sub has_bar   : predicate;
    sub set_bar   : wo;
    sub clear_bar : clearer;
}

{
    my $foo = Foo->new;
    ok( $foo->isa( 'Foo' ), '... the object is from class Foo' );

    ok($foo->has_bar, '... bar is set as a default');
    ok($foo->bar->isa( 'Bar' ), '... value isa Bar object');

    my $bar = $foo->bar;

    eval { $foo->set_bar( Bar->new ) };
    is($@, "", '... set bar without error');
    ok($foo->has_bar, '... bar is set');
    ok($foo->bar->isa( 'Bar' ), '... value is set by the set_bar method');
    isnt($foo->bar, $bar, '... the new value has been set');

    eval { $foo->clear_bar };
    is($@, "", '... set bar without error');
    ok(!$foo->has_bar, '... no bar is set');
    is($foo->bar, undef, '... values has been cleared');
}


done_testing;
