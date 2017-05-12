#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 14;

my $exception;
{
    package TypeLib;

    use MouseX::Types -declare => [qw( MyUnionType Test1 Test2 Test3 MyStr )];
    use MouseX::Types::Mouse qw(Str Int Item Object);

    subtype MyUnionType, as Str|'Int';
    subtype MyStr, as Str;

    eval { coerce MyStr, from Item, via {"$_"} };
    my $exception = $@;

	Test::More::ok !$@, 'types are not mutated by union with a string type';

	subtype Test1, 
	  as Int | 'ArrayRef[Int]';
	
	Test::More::ok Test1->check(1), '1 is an Int';
	Test::More::ok !Test1->check('a'),  'a is not an Int';
	Test::More::ok Test1->check([1, 2, 3]),  'Passes ArrayRef';
	Test::More::ok !Test1->check([1, 'a', 3]),  'Fails ArrayRef with a letter';
	Test::More::ok !Test1->check({a=>1}), 'fails wrong ref type';

	eval {
	subtype Test2, 
	 as Int | 'IDONTEXIST';
	};

	my $check = $@;

	Test::More::ok $@, 'Got an error for bad Type'; 
	Test::More::like $check,  qr/IDONTEXIST is not a type constraint/,  'correct error';

	my $obj = subtype Test3, 
	  as Int | 'ArrayRef[Int]' | Object;

	Test::More::ok Test3->check(1), '1 is an Int';
	Test::More::ok !Test3->check('a'),  'a is not an Int';
	Test::More::ok Test3->check([1, 2, 3]),  'Passes ArrayRef';
	Test::More::ok !Test3->check([1, 'a', 3]),  'Fails ArrayRef with a letter';
	Test::More::ok !Test3->check({a=>1}), 'fails wrong ref type';
	Test::More::ok Test3->check($obj), 'Union allows Object';
}
