use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::Method::Signatures;

    method foo ($bar) { $bar }
}

my $o = Foo->new;
is(exception { $o->foo(42) }, undef);
like(exception { $o->foo(42, 23) }, qr/Validation failed/);

done_testing;
