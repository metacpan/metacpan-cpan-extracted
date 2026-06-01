use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Hash qw(check_hash_optional_keys);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => {
		'first' => 'value',
	},
};
my $ret = check_hash_optional_keys($self, 'key', 'first', 'second');
is($ret, undef, 'Hash contain one of optional keys (first).');

# Test.
$self = {
	'key' => {
		'second' => 'value',
	},
};
$ret = check_hash_optional_keys($self, 'key', 'first', 'second');
is($ret, undef, 'Hash contain one of optional keys (second).');

# Test.
$self = {};
$ret = check_hash_optional_keys($self, 'key', 'first', 'second');
is($ret, undef, 'Right keys in hash are present (parameter key is not exists).');

# Test.
$self = {
	'key' => {},
};
$ret = check_hash_optional_keys($self, 'key', 'first', 'second');
is($ret, undef, 'Right keys in hash are present (no keys).');

# Test.
$self = {
	'key' => {
		'bad' => 'value',
	},
};
eval {
	check_hash_optional_keys($self, 'key', 'first', 'second');
};
is($EVAL_ERROR, "Parameter 'key' contain bad hash key.\n",
	"Parameter 'key' contain bad hash key (bad).");
clean();

# Test.
$self = {
	'key' => 'bad',
};
eval {
	check_hash_optional_keys($self, 'key', 'first', 'second');
};
is($EVAL_ERROR, "Parameter 'key' isn't hash reference.\n",
	"Parameter 'key' isn't hash reference (scalar).");
clean();
