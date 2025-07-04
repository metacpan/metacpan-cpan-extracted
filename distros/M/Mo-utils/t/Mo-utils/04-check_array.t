use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils qw(check_array);
use Test::MockObject;
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_array($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
my $err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Reference'}, 'SCALAR', 'Test error parameter (Reference: SCALAR).');
is($err_msg_hr->{'Value'}, 'foo', 'Test error parameter (Value: foo).');
clean();

# Test.
$self = {
	'key' => ['foo'],
};
my $ret = check_array($self, 'key');
is($ret, undef, 'Right structure.');

# Test.
$self = {};
$ret = check_array($self, 'key');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => undef,
};
eval {
	check_array($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Reference'}, 'SCALAR', 'Test error parameter (Reference: SCALAR).');
is($err_msg_hr->{'Value'}, 'undef', 'Test error parameter (Value: undef).');
clean();
