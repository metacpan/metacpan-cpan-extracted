use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::Currency qw(check_currency_code);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'USD',
};
my $ret = check_currency_code($self, 'key');
is($ret, undef, "Unit 'USD' is valid.");

# Test.
$self = {
	'key' => 'XXX',
};
eval {
	check_currency_code($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a valid currency code.\n",
	"Parameter 'key' must be a valid currency code (XXX).");
clean();

# Test.
$self = {};
$ret = check_currency_code($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_currency_code($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");
