use strict;
use warnings;

use Test::More 0.88;
use Test::Moose;

use lib 't/lib';
use ConstructorTests;

with_immutable { ConstructorTests::do_tests() } qw(Foo Bar);

note 'Ran ', Test::More->builder->current_test, ' tests - should have run 56';

done_testing;

