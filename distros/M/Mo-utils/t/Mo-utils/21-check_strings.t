use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils qw(check_strings);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_strings($self, 'key', ['key', 'value']);
};
is($EVAL_ERROR, "Parameter 'key' must be one of defined strings.\n",
	"Parameter 'key' must be one of defined strings.");
my $err_msg_hr = err_msg_hr();
is($err_msg_hr->{'String'}, 'foo', 'Test error parameter (String: foo).');
is($err_msg_hr->{'Possible strings'}, "'key', 'value'", "Test error parameter (Possible strings: 'key', 'value').");
clean();

# Test.
$self = {
	'key' => 'foo',
};
my $ret = check_strings($self, 'key', ['foo', 'bar']);
is($ret, undef, 'Right string is present (foo).');

# Test.
$self = {
	'key' => 'bar',
};
$ret = check_strings($self, 'key', ['foo', 'bar']);
is($ret, undef, 'Right string is present (bar).');

# Test.
$self = {
	'key' => undef,
};
$ret = check_strings($self, 'key', 'Foo');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_strings($self, 'key');
};
is($EVAL_ERROR, "Parameter 'key' must have strings definition.\n",
	"Parameter 'key' must have strings definition.");
clean();

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_strings($self, 'key', 'string');
};
is($EVAL_ERROR, "Parameter 'key' must have right string definition.\n",
	"Parameter 'key' must have right string definition.");
clean();
