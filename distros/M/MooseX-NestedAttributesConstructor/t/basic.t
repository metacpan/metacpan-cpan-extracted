package A;
use Moose;
use MooseX::NestedAttributesConstructor;

has 'str', is => 'rw', isa => 'Str';
has 'a', traits => ['NestedAttribute'], is => 'rw', isa => 'A';
has 'arrayref', traits => ['NestedAttribute'], is => 'rw', isa => 'ArrayRef[A]';
has 'hashref', traits => ['NestedAttribute'], is => 'rw', isa => 'HashRef[A]';

package main;
use strict;
use warnings;

use Test::More;

my $a;
subtest 'without nested attributes' => sub {
    $a = A->new(str => '123');
    is($a->str, 123, '$a->str');

    $a = A->new(arrayref => [ A->new(str => '123') ]);
    isa_ok($a->arrayref, 'ARRAY', '$a->arrayref');
    isa_ok($a->arrayref->[0], 'A', '$a->arrayref->[0]');
    is($a->arrayref->[0]->str, '123', '$a->arrayref->[0]->str');
};

subtest 'with a nested attribute' => sub {
    eval { A->new(str => []) };
    like($@, qr/validation failed/i, '$a->str not nested');

    eval { A->new(a => { a => 'A' }) };
    like($@, qr/validation failed/i, '$a->a->a nested but wrong type');

    subtest 'that is an object' => sub {
	$a = A->new(str => '123', a => { str => '456' });
	is($a->str, '123', '$a->str');
	isa_ok($a->a, 'A', '$a->a');
	is($a->a->str, '456', '$a->a->str');
    };

    subtest 'that is an array of objects ' => sub {
	$a = A->new(str => '123', arrayref => [
			{ a => { str => '123' } },
			{ a => { str => 'XYZ' } }
		    ]);

	is($a->str, '123', '$a->str');
	isa_ok($a->arrayref, 'ARRAY', '$a->arrayref');
	is(@{$a->arrayref}, 2, '$a->arrayref size');
	isa_ok($a->arrayref->[0], 'A', '$a->arrayref->[0]');
	isa_ok($a->arrayref->[0]->a, 'A', '$a->arrayref->[0]->a');
	is($a->arrayref->[0]->a->str, '123', '$a->arrayref->[0]->a->str');
	isa_ok($a->arrayref->[1], 'A', '$a->arrayref->[1]');
	isa_ok($a->arrayref->[1]->a, 'A', '$a->arrayref->[1]->a');
	is($a->arrayref->[1]->a->str, 'XYZ', '$a->arrayref->[1]->a->str');
    };

    subtest 'that is a hash of objects' => sub {
	$a = A->new(str => '123', hashref => {
	    a_key => { a => { str => '123' } }
	});

	is($a->str, '123', '$a->str');
	isa_ok($a->hashref, 'HASH', '$a->hashref');
	is(keys %{$a->hashref}, 1, '$a->hashref size');
	isa_ok($a->hashref->{a_key}, 'A', '$a->hashref->{a_key}');
	isa_ok($a->hashref->{a_key}->a, 'A', '$a->hashref->{a_key}->a');
	is($a->hashref->{a_key}->a->str, '123', '$a->hashref->{a_key}->a->str');
    };
};

done_testing();
