use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Text qw(check_no_null);
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $self = {};
my $ret = check_no_null($self, 'key');
is($ret, undef, 'Right, key not exists.');

# Test.
$self = {
	'key' => 'foo',
};
$ret = check_no_null($self, 'key');
is($ret, undef, 'Right, valid string without null (foo).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_no_null($self, 'key');
is($ret, undef, 'Right, valid string without null (undef).');

# Test.
$self = {
	'key' => "foo\0",
};
eval {
	check_no_null($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must not contain NULL on the end of string.\n",
	"Parameter 'key' must not contain NULL on the end of string (foo\\0).");
my $err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, "foo\0", 'Test error parameter (Value: foo\\0).');
clean();
