use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_number_min);
use Test::More 'tests' => 7;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 10,
};
my $ret = check_number_min($self, 'key', 0);
is($ret, undef, 'Right number is present (10 > 0).');

# Test.
$self = {
	'key' => -5,
};
$ret = check_number_min($self, 'key', -10);
is($ret, undef, 'Right number is present (-5 > -10).');

# Test.
$self = {};
$ret = check_number_min($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_number_min($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_number_min($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a number.\n",
	"Parameter 'key' must be a number.");
clean();

# Test.
$self = {
	'key' => 10,
};
eval {
	check_number_min($self, 'key', 11);
};
is($EVAL_ERROR, "Parameter 'key' must be greater than 11.\n",
	"Parameter 'key' must be greater than 11 (10).");
clean();
