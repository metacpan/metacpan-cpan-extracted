#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use Test::Exception;

BEGIN {
    use_ok('Moose::Test');
    use_ok('Moose::Test::Case');
}

my $test = Moose::Test::Case->new->create_test_body;

is($test, q{
{
package Foo;
use Mouse;

has 'bar' => (is => 'rw', isa => 'Str');
has 'baz' => (is => 'rw', isa => 'Str');

1;
}

{
package Bar;
use Mouse;

extends 'Foo';

has 'bar' => (is => 'rw', isa => 'Str');
has 'foo' => (is => 'rw', isa => 'Str');

1;
}

{

my $foo = Foo->new;
isa_ok($foo, 'Foo');

can_ok($foo, 'bar');
can_ok($foo, 'baz');


}

{

my $bar = Bar->new;
isa_ok($bar, 'Bar');
isa_ok($bar, 'Foo');

can_ok($bar, 'bar');
can_ok($bar, 'baz');
can_ok($bar, 'foo');


}
}, '... got the right test string');

eval $test;




