#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Validate::Strict qw(validate_strict);

lives_ok {
	my $res = validate_strict({
		input => { args => [ 1, 2, 3, 4 ] },
		schema => {
			args => { type => 'arrayref', nomatch => qr/\D/ }
		}
	});
	is_deeply($res, { args => [1, 2, 3, 4] }, 'Empty schema and args work');
} 'nomatch checks all members of an array';

throws_ok {
	validate_strict({
		input => { args => [ 1, '2x', 3 ] },
		schema => {
			args => { type => 'arrayref', nomatch => qr/\D/ }
		}
	});
} qr/No member of parameter 'args' /, 'nomatch checks all members of an array';

lives_ok {
	my $res = validate_strict({
		input => { params => [ 'abc', 'def' ] },
		schema => {
			params => { type => 'arrayref', matches => qr/^[a-z]+$/ }
		}
	});
	is_deeply($res, { params => ['abc', 'def'] }, 'Empty schema and args work');
} 'match checks all members of an array';

lives_ok {
	my $res = validate_strict({
		input => { params => [ 'abc', 'def' ] },
		schema => {
			params => { type => 'arrayref', element_type => 'string' }
		}
	});
} 'element_type string allows strings';

throws_ok {
	my $res = validate_strict({
		input => { params => [ 'abc', 'def' ] },
		schema => {
			params => { type => 'arrayref', element_type => 'number' }
		}
	});
} qr/params can only contain numbers/, 'element_type number does not allow strings';

done_testing();
