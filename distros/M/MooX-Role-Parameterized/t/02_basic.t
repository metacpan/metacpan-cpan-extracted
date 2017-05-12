use strict;
use warnings;
use Test::More;

use lib 't/lib';

{

    package Foo;

    use Moo;

    use Bar;

    Bar->apply( { attr => 'baz', method => 'run' } );

    has foo => ( is => 'ro' );
}

my $foo = Foo->new( foo => 1, bar => 2, baz => 3 );

isa_ok $foo, 'Foo', 'foo';
ok $foo->DOES('Bar'), 'foo should does Bar';
is $foo->foo, 1, 'should has foo';
is $foo->bar, 2, 'should has bar ( from Role )';
is $foo->baz, 3, 'should has baz ( from parameterized Role)';
ok $foo->can('run'), 'should can run';
is $foo->run, 1024, 'should call run';

done_testing;
