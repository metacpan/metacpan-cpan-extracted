use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use MooseX::Types::Moose qw/Int/;
use MooseX::Lexical::Types qw/Int/;

isa_ok(Int, 'Moose::Meta::TypeConstraint');

my Int $foo = 42;
is($foo, 42);

lives_ok {
    $foo = 23;
};
is($foo, 23);

throws_ok {
    $foo = 'bar';
} qr/Validation failed/;
