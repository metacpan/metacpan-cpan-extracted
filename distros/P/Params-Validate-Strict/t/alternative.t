#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Validate::Strict qw(validate_strict);

lives_ok {
	my $res = validate_strict({
		input => { arg => 1 },
		schema => {
			arg => [
				{ type => 'integer' },
				{ type => 'string' },
			]
		}
	});
	is_deeply($res, { arg => 1 }, 'Alternative integer works');
} 'Alternative integer works';

lives_ok {
	my $res = validate_strict({
		input => { arg => 'hello' },
		schema => {
			arg => [
				{ type => 'integer' },
				{ type => 'string' },
			]
		}
	});
	is_deeply($res, { arg => 'hello' }, 'Alternative string works');
} 'Alternative string works';

throws_ok {
	validate_strict({
		input => { arg => { } },
		schema => {
			arg => [
				{ type => 'integer' },
				{ type => 'string' },
			]
		}
	});
} qr/must be one of integer, string/, 'fails when giving a hashref when only integers or strings are acceptible';

done_testing();
