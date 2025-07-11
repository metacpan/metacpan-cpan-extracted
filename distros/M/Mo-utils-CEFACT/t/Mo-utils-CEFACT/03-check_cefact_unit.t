use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Mo::utils::CEFACT qw(check_cefact_unit);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'KGM',
};
my $ret = check_cefact_unit($self, 'key');
is($ret, undef, "Unit 'KGM' is valid.");

# Test.
$self = {
	'key' => 'XXX',
};
eval {
	check_cefact_unit($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a UN/CEFACT unit common code.\n",
	"Parameter 'key' must be a UN/CEFACT unit common code. (XXX).");
clean();

# Test.
$self = {};
$ret = check_cefact_unit($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_cefact_unit($self, 'key');
is($ret, undef, "Value is undefined, that's ok.");
