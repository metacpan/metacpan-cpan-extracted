#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

package Foo {
    use Moxie;

    extends 'Moxie::Object';

    has 'foo' => ( default => sub { 'DFOO' } );
    has 'bar' => ( required => 1 );

    sub foo : ro;
    sub bar : ro;
}

{
    my $foo = Foo->new(foo => 'FOO', bar => 'BAR');
    is($foo->foo, 'FOO', 'slot with default and arg');
    is($foo->bar, 'BAR', 'required slot with arg');
}

{
    my $foo = Foo->new(bar => 'BAR');
    is($foo->foo, 'DFOO', 'slot with default and no arg');
    is($foo->bar, 'BAR', 'required slot with arg');
}

like(
    exception { Foo->new },
    qr/^A \`bar\` value is required/,
    'missing required slot throws an exception'
);


done_testing;
