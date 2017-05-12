use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::Method::Signatures;
    method bar { 42 }
}

my $foo = Foo->new;

is(exception {
    $foo->bar
}, undef, 'method without signature succeeds when called without args');

is(exception {
    $foo->bar(42)
}, undef, 'method without signature succeeds when called with args');

done_testing;
