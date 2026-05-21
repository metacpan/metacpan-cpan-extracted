use strict;
use warnings;
use Test::More;

use Params::Validate::Strict qw(validate_strict);

subtest 'union type: string accepted' => sub {
	my $r = eval { validate_strict(
		input  => { x => 'hello' },
		schema => { x => { type => ['string', 'arrayref'] } },
	) };
	ok(!$@, "no error: $@");
	is($r->{x}, 'hello', 'value preserved');
};

subtest 'union type: arrayref accepted' => sub {
	my $r = eval { validate_strict(
		input  => { x => [1,2,3] },
		schema => { x => { type => ['string', 'arrayref'] } },
	) };
	ok(!$@, 'no error');
	is_deeply($r->{x}, [1,2,3], 'arrayref preserved');
};

subtest 'union type: neither type rejected' => sub {
	eval { validate_strict(
		input  => { x => { foo => 1 } },
		schema => { x => { type => ['string', 'arrayref'] } },
	) };
	like($@, qr/must be one of/, 'correct error for wrong type');
};

subtest 'union type: integer coercion propagates' => sub {
	my $r = eval { validate_strict(
		input  => { x => '99' },
		schema => { x => { type => ['integer', 'string'] } },
	) };
	ok(!$@, "no error");
	is($r->{x}, 99, 'integer coerced');
};

subtest 'union type: optional absent param is fine' => sub {
	my $r = eval { validate_strict(
		input  => {},
		schema => { x => { type => ['string', 'arrayref'], optional => 1 } },
	) };
	ok(!$@, "no error: $@");
	ok(!exists($r->{x}), 'key absent from result');
};

subtest 'union type: value failing all branches is rejected' => sub {
	# 'hi' is a string but only 2 chars; min => 5 means the string branch
	# rejects it, and it is not an arrayref either.  Union-level rejection
	# gives "must be one of" — not a branch-internal "too short".
	eval { validate_strict(
		input  => { x => 'hi' },
		schema => { x => { type => ['string', 'arrayref'], min => 5 } },
	) };
	like($@, qr/must be one of/, 'union-level error when all branches fail');
};

subtest 'union type: empty list is an error' => sub {
	eval { validate_strict(
		input  => { x => 'hello' },
		schema => { x => { type => [] } },
	) };
	like($@, qr/must not be empty/, 'empty union list caught');
};

subtest 'array-of-rules: coerced value returned to caller' => sub {
	my $r = eval { validate_strict(
		input  => { n => '7' },
		schema => { n => [
			{ type => 'integer', min => 1 },
			{ type => 'string' },
		] },
	) };
	ok(!$@, "no error: $@");
	ok($r->{n} == 7, "integer coercion captured (got $r->{n})");
};

done_testing;
