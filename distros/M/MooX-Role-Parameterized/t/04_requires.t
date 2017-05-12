use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib 't/lib';

{

    package Foo;

    use Moo;

    use BarWithRequires;

    BarWithRequires->apply(
        { attr => 'baz', method => 'run', requires => 'xoxo' } );

    has foo => ( is => 'ro' );

    sub xoxo { }
}

my $foo = Foo->new( foo => 1, bar => 2, baz => 3 );

isa_ok $foo, 'Foo', 'foo';
ok $foo->DOES('BarWithRequires'), 'foo should does Bar';
is $foo->foo, 1, 'should has foo';
is $foo->bar, 2, 'should has bar ( from Role )';
is $foo->baz, 3, 'should has baz ( from parameterized Role)';
ok $foo->can('run'), 'should can run';
is $foo->run, 1024, 'should call run';

throws_ok {

    package Foo2;

    use Moo;

    use BarWithRequires;

    BarWithRequires->apply(
        { attr => 'baz', method => 'run', requires => 'xoxo2' } );

    has foo => ( is => 'ro' );

    sub xoxo { }
}
qr/Can't apply BarWithRequires to Foo2 - missing xoxo/,
'should die when apply BarWithRequires on class Foo2, reason: missing xoxo2 method';

done_testing;
