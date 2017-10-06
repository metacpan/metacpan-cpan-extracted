#!perl

use strict;
use warnings;

use Test::More;

=pod

...

=cut

package Bar {
    use Moxie;

    extends 'Moxie::Object';
}

package Baz {
    use Moxie;

    extends 'Moxie::Object';
}

package Foo {
    use Moxie;

    extends 'Moxie::Object';

    has _bar => sub { Bar->new };
    has _baz => sub { Baz->new };

    sub bar       : ro(_bar);
    sub has_bar   : predicate(_bar);
    sub set_bar   : wo(_bar);
    sub clear_bar : clearer(_bar);

    sub baz       : ro(_baz);
    sub has_baz   : predicate(_baz);
    sub set_baz   : wo(_baz);
    sub clear_baz : clearer(_baz);
}

{
    my $foo = Foo->new;
    ok( $foo->isa( 'Foo' ), '... the object is from class Foo' );

    ok($foo->has_bar, '... bar is set as a default');
    ok($foo->bar->isa( 'Bar' ), '... value isa Bar object');

    ok($foo->has_baz, '... baz is set as a default');
    ok($foo->baz->isa( 'Baz' ), '... value isa Baz object');

    my $bar = $foo->bar;
    my $baz = $foo->baz;

    #diag $bar;
    #diag $baz;

    eval { $foo->set_bar( Bar->new ) };
    is($@, "", '... set bar without error');
    ok($foo->has_bar, '... bar is set');
    ok($foo->bar->isa( 'Bar' ), '... value is set by the set_bar method');
    isnt($foo->bar, $bar, '... the new value has been set');

    eval { $foo->set_baz( Baz->new ) };
    is($@, "", '... set baz without error');
    ok($foo->has_baz, '... baz is set');
    ok($foo->baz->isa( 'Baz' ), '... value is set by the set_baz method');
    isnt($foo->baz, $baz, '... the new value has been set');

    eval { $foo->clear_bar };
    is($@, "", '... set bar without error');
    ok(!$foo->has_bar, '... no bar is set');
    is($foo->bar, undef, '... values has been cleared');

    eval { $foo->clear_baz };
    is($@, "", '... set baz without error');
    ok(!$foo->has_baz, '... no baz is set');
    is($foo->baz, undef, '... values has been cleared');
}


done_testing;
