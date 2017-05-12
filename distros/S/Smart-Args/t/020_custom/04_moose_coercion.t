#!perl-w
use strict;
use Test::Requires { 'Moose' => 1.21 };
use Test::More;
use t::Util;
use Smart::Args;
use Moose::Util::TypeConstraints;

my $MyHashRef = subtype 'MyHashRef', as 'HashRef';

coerce 'MyHashRef',
    from 'ArrayRef', via {
        return +{ @{$_} };
    },
;

sub foo {
    args my $h => $MyHashRef;
    return $h;
}

lives_and {
    is_deeply foo( h => { foo => 42 } ), { foo => 42 };
    is_deeply foo( h => [ foo => 42 ] ), { foo => 42 };
};

throws_ok {
    foo(h => 42);
} qr/Validation failed for 'MyHashRef' with value 42/;

done_testing;

