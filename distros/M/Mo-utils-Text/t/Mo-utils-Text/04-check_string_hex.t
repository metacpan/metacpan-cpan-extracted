use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Text qw(check_string_hex);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {};
my $ret = check_string_hex($self, 'key');
is($ret, undef, 'Right, key not exists.');

# Test.
$self = {
	'key' => 'ABCDEF0123456789',
};
$ret = check_string_hex($self, 'key');
is($ret, undef, 'Right, valid hexadecimal string (ABCDEF0123456789).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_string_hex($self, 'key');
is($ret, undef, 'Right, valid string without null (undef).');

# Test.
$self = {
	'key' => "foo",
};
eval {
	check_string_hex($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must contain hexadecimal string.\n",
	"Parameter 'key' must contain hexadecimal string (foo).");
my $err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, "foo", 'Test error parameter (Value: foo).');
clean();
