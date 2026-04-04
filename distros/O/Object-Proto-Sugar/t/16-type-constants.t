use Test::More;

{
	package Test;

	use Object::Proto::Sugar;

	has name  => ( is => 'rw', isa => Str     );
	has age   => ( is => 'rw', isa => Int     );
	has score => ( is => 'rw', isa => Num     );
	has tags  => ( is => 'rw', isa => ArrayRef );
	has meta  => ( is => 'rw', isa => HashRef  );
	has cb    => ( is => 'rw', isa => CodeRef  );

	1;
}

package main;

my $test = new Test 'Alice', 30, 9.5, [], {}, sub {};

is($test->name,  'Alice', 'Str slot works');
is($test->age,   30,      'Int slot works');
is($test->score, 9.5,     'Num slot works');

eval { new Test {}, 30, 9.5, [], {}, sub {} };
like($@, qr/Str/, 'Str constraint enforced');

eval { new Test 'Alice', 'old', 9.5, [], {}, sub {} };
like($@, qr/Int/, 'Int constraint enforced');

eval { new Test 'Alice', 30, 9.5, {}, {}, sub {} };
like($@, qr/ArrayRef/, 'ArrayRef constraint enforced');

eval { new Test 'Alice', 30, 9.5, [], [], sub {} };
like($@, qr/HashRef/, 'HashRef constraint enforced');

eval { new Test 'Alice', 30, 9.5, [], {}, 'not_a_sub' };
like($@, qr/CodeRef/, 'CodeRef constraint enforced');

done_testing();
