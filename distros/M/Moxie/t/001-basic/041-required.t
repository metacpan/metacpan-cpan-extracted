#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

package Foo {
    use Moxie;

    extends 'Moxie::Object';

    has _foo => ( default => sub { 'DFOO' } );
    has _bar => ( required => 'A `_bar` value is required' );

    sub BUILDARGS : init(
        foo? => _foo,
        bar? => _bar,
    );

    sub foo : ro(_foo);
    sub bar : ro(_bar);
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
    qr/^A \`_bar\` value is required/,
    'missing required slot throws an exception'
);


done_testing;
