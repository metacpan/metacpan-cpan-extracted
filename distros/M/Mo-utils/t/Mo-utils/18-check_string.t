use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_string);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
my $ret = check_string($self, 'key', 'foo');
is($ret, undef, 'Right string is present (foo).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_string($self, 'key', 'foo');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {
	'key' => 'bar',
};
eval {
	check_string($self, 'key', 'foo');
};
is($EVAL_ERROR, "Parameter 'key' must have expected value.\n",
	"Parameter 'key' must have expected value (bar).");
clean();

# Test.
$self = {
	'key' => 1,
};
eval {
	check_string($self, 'key', 'foo');
};
is($EVAL_ERROR, "Parameter 'key' must have expected value.\n",
	"Parameter 'key' must have expected value (1).");
clean();
