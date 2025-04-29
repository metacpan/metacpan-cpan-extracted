#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Get qw(get_params);

# Test get_params with a hash reference
my $params = get_params(undef, { foo => 'bar' });
is_deeply($params, { foo => 'bar' }, 'get_params correctly returns hash reference');

# Test get_params with key-value pairs
$params = get_params(undef, foo => 'bar', baz => 'qux');
is_deeply($params, { foo => 'bar', baz => 'qux' }, 'get_params correctly processes key-value pairs');

# Test get_params with a default key and single argument
$params = get_params('key', 'value');
is_deeply($params, { key => 'value' }, 'get_params correctly assigns default key');

# Test get_params with an empty argument list
throws_ok { $params = get_params('key') }
	qr /^Usage: /,
	'get_params throws exception with no arguments and no default';

$params = get_params();
ok(!defined $params, 'get_params returns undef with no arguments and no default');

$params = get_params('key', 'value1', 'value2');
is_deeply($params, { value1 => 'value2' });

$params = get_params(undef, ['value1', 'value2']);
is_deeply($params, { value1 => 'value2' });

done_testing();
