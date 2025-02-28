#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Get qw(get_params);

use Error qw(:try);

# Hash reference input
my $hash_input = { key1 => 'value1', key2 => 'value2' };
is_deeply(get_params(undef, $hash_input), $hash_input, 'Direct hash reference input works');

# Single argument with default
is_deeply(get_params('key', 'value'), { key => 'value' }, 'Single argument with default works');

# Multiple key-value pairs
is_deeply(get_params(undef, key1 => 'value1', key2 => 'value2'), { key1 => 'value1', key2 => 'value2' }, 'Multiple key-value pairs work');

# Invalid single argument without default
my $msg;
try {
	get_params(undef, 'value');
} catch Error with {
	$msg = shift;
};
like($msg, qr/Usage/, 'Throws an error for single argument without default');

# Test 5: Zero arguments with default
try {
	get_params('key');
} catch Error with {
	$msg = shift;
};
like($msg, qr/Usage/, 'Throws an error for zero arguments with default');

# Test 6: Zero arguments without default
my $params = get_params();
is_deeply($params, undef, 'Zero arguments without default returns undef');

done_testing();
