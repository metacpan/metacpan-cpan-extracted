use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Hash qw(check_hash_keys);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => {
		'first' => {
			'second' => 'value',
		},
	},
};
my $ret = check_hash_keys($self, 'key', 'first', 'second');
is($ret, undef, 'Right keys in hash are present (right structure).');

# Test.
$self = {};
$ret = check_hash_keys($self, 'key', 'first', 'second');
is($ret, undef, 'Right keys in hash are present (parameter key is not exists).');

# Test.
$self = {
	'key' => {},
};
eval {
	check_hash_keys($self, 'key', 'first', 'second');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain expected keys.\n",
	"Parameter 'key' doesn't contain expected keys ({}).");
clean();

# Test.
$self = {
	'key' => {
		'first' => {
			'second_typo' => 'value',
		},
	},
};
eval {
	check_hash_keys($self, 'key', 'first', 'second');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain expected keys.\n",
	"Parameter 'key' doesn't contain expected keys. (typo in second hash key).");
clean();

# Test.
$self = {
	'key' => {
		'first' => 'value',
	},
};
eval {
	check_hash_keys($self, 'key', 'first', 'second');
};
is($EVAL_ERROR, "Parameter 'key' doesn't contain expected keys.\n",
	"Parameter 'key' doesn't contain expected keys. (first key contain value instead of reference to another hash).");
clean();

# Test.
$self = {
	'key' => {},
};
eval {
	check_hash_keys($self, 'key');
};
is($EVAL_ERROR, "Expected keys doesn't exists.\n",
	"Expected keys doesn't exists. (bad usage of check).");
clean();
