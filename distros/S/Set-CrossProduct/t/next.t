use strict;
use warnings;

use Test::More 1;

my $class  = 'Set::CrossProduct';
my $method = 'next';

subtest 'sanity' => sub {
	use_ok $class or BAIL_OUT( "$class did not compile" );
	can_ok $class, $method;
	};

my @apples  = ('Granny Smith', 'Washington', 'Red Delicious');
my @oranges = ('Navel', 'Florida');

my $cross;
subtest 'construct' => sub {
	$cross = $class->new( [ \@apples, \@oranges ] );
	isa_ok $cross, $class;

	is $cross->cardinality, 6, 'get back the right number of elements';
	};

subtest "$method at end" => sub {
	ok defined $cross->next, 'next element is defined';
	$cross->combinations; #exhaust iterator
	ok $cross->done, 'cross is done';
	ok !defined $cross->next, 'next element is undefined';
	};

subtest "$method after unget" => sub {
	ok $cross->unget;
	ok ! $cross->done, 'cross is not done';
	ok defined $cross->next, 'next element is defined';
	};

subtest "exhaust again" => sub {
	ok $cross->get, 'get last element again';
	ok $cross->done, 'cross is done';
	ok ! defined $cross->next, 'next element is undefined';
	};

done_testing();
