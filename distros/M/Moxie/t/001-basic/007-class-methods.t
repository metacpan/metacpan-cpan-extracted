#!perl

use strict;
use warnings;

use Test::More;

package Foo {
    use Moxie
        traits => [':experimental'];

    extends 'Moxie::Object';

    has _bar => ();

    my sub _bar : private;

    sub bar ($self, $x = undef) {
        _bar = $x if $x;
        _bar + 1;
    }
}

eval { Foo->bar(10) };
like(
    $@,
    qr/^Can\'t use string \(\"Foo\"\) as a HASH ref while \"strict refs\" in use/,
    '... got the error we expected'
);

eval { Foo->bar() };
like(
    $@,
    qr/^Can\'t use string \(\"Foo\"\) as a HASH ref while \"strict refs\" in use/,
    '... got the error we expected'
);

my $foo = Foo->new;
isa_ok($foo, 'Foo');
{
    my $result = eval { $foo->bar(10) };
    is($@, "", '... did not die');
    is($result, 11, '... and the method worked');
    is($foo->bar, 11, '... and the slot assignment worked');
}

done_testing;
