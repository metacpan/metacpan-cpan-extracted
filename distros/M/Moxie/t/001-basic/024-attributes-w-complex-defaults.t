#!perl

use strict;
use warnings;

use Test::More;

=pod

...

=cut

package Foo {
    use Moxie;

    extends 'Moxie::Object';

    has 'bar' => sub { [] };

    sub bar       : ro;
    sub has_bar   : predicate;
    sub set_bar   : wo;
    sub clear_bar : clearer;

    sub init_bar ($self) { $self->{bar} = [ 1, 2, 3 ] }
}

{
    my $foo = Foo->new;
    ok( $foo->isa( 'Foo' ), '... the object is from class Foo' );

    ok($foo->has_bar, '... a bar is set');
    is_deeply($foo->bar, [], '... values are defined');

    eval { $foo->init_bar };
    is($@, "", '... initialized bar without error');
    is_deeply($foo->bar, [ 1, 2, 3 ], '... value is initialized by the init_bar method');

    eval { $foo->set_bar([1000]) };
    is($@, "", '... set bar without error');
    is_deeply($foo->bar, [1000], '... value is set by the set_bar method');

    eval { $foo->clear_bar };
    is($@, "", '... set bar without error');
    ok(!$foo->has_bar, '... no bar is set');
    is($foo->bar, undef, '... values has been cleared');

    {
        my $foo2 = Foo->new;
        isnt($foo->bar, $foo2->bar, '... different instances have different refs');
    }
}

{
    my $foo = Foo->new( bar => [10] );
    ok( $foo->isa( 'Foo' ), '... the object is from class Foo' );

    ok($foo->has_bar, '... a bar is set');
    is_deeply($foo->bar, [10], '... values are initialized via the constructor');

    eval { $foo->init_bar };
    is($@, "", '... initialized bar without error');
    ok($foo->has_bar, '... a bar is set');
    is_deeply($foo->bar, [1, 2, 3], '... value is initialized by the init_bar method');

    eval { $foo->set_bar([1000]) };
    is($@, "", '... set bar without error');
    ok($foo->has_bar, '... a bar is set');
    is_deeply($foo->bar, [1000], '... value is set by the set_bar method');

    eval { $foo->clear_bar };
    is($@, "", '... set bar without error');
    ok(!$foo->has_bar, '... no bar is set');
    is($foo->bar, undef, '... values has been cleared');
}


done_testing;
