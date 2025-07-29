use strict;
use warnings;

use Test::Most;
use Return::Set qw(set_return);

note('Testing positional arguments');
is(set_return(5), 5, 'Returns value without schema (positional)');
is(set_return(42, { type => 'integer' }), 42, 'Validates scalar (positional)');

note('Testing named parameters');
is(set_return({ value => 7 }), 7, 'Returns value without schema (named)');
is(set_return({ value => 99, schema => { type => 'integer' } }), 99, 'Validates scalar (named)');

throws_ok {
	set_return({ value => ['a'], schema => { type => 'integer' } });
} qr/Validation failed/, 'Fails validation for non-scalar (named)';

done_testing();
