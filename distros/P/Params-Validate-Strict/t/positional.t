#!/usr/bin/env perl

# Test positional arguments

use strict;
use warnings;

use Test::Most;
use Params::Validate::Strict qw(validate_strict);

my $schema = {
	username => { type => 'string', optional => 1, 'default' => 'xyzzy', position => 0 }
};

my $result = validate_strict({ schema => $schema, args => [ 'foo' ] });

is_deeply($result, [ 'foo' ], 'positional arg works');

$result = validate_strict({ schema => $schema, args => [ ] });

is_deeply($result, [ 'xyzzy' ], 'positional default arg works');

$schema = {
	name => {
		'type' => 'string',
		'position' => 0
	}, age => {
		'type' => 'integer',
		'position' => 1
	}
};

$result = validate_strict({ schema => $schema, args => [ 'Fred Bloggs', 64 ] });

is_deeply($result, [ 'Fred Bloggs', 64 ], 'positional arg works with two args');

done_testing();
