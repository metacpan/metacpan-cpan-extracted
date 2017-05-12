use strict;
use warnings;
use Test::More;

use lib 't/lib';
{

    package FooWithXoxo;

    use Moo;

    has xoxo => ( is => 'ro' );

    require MooX::Role::Parameterized::With;

    MooX::Role::Parameterized::With->import( BarWithRequires =>
          { attr => 'baz', method => 'run', requires => 'xoxo' } );

    has foo => ( is => 'ro' );
}

my $foo = FooWithXoxo->new( foo => 1, bar => 2, baz => 3 );

isa_ok $foo, 'FooWithXoxo', 'foo';
ok $foo->DOES('BarWithRequires'), 'foo should does Bar';
is $foo->foo, 1, 'should has foo';
is $foo->bar, 2, 'should has bar ( from Role )';
is $foo->baz, 3, 'should has baz ( from parameterized Role)';
ok $foo->can('run'), 'should can run';
is $foo->run, 1024, 'should call run';

done_testing;
