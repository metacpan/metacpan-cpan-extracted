use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils qw(check_number);
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 10,
};
my $ret = check_number($self, 'key');
is($ret, undef, 'Right number is present (positive number).');

# Test.
$self = {
	'key' => 10.0001,
};
$ret = check_number($self, 'key');
is($ret, undef, 'Right number is present (positive floating number).');

# Test.
$self = {
	'key' => '+10',
};
$ret = check_number($self, 'key');
is($ret, undef, 'Right number is present (positive number with plus).');

# Test.
$self = {
	'key' => -10,
};
$ret = check_number($self, 'key');
is($ret, undef, 'Right number is present (negative number).');

# Test.
$self = {};
$ret = check_number($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_number($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_number($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a number.\n",
	"Parameter 'key' must be a number.");
clean();

