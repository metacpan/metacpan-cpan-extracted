use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils::Array qw(check_array_object);
use Test::MockObject;
use Test::More 'tests' => 12;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_array_object($self, 'key', 'Foo');
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
eval {
	check_array_object($self, 'key', 'Foo');
};
is($EVAL_ERROR, "Parameter 'key' with array must contain 'Foo' objects.\n",
	"Parameter 'key' with array must contain 'Foo' objects (foo).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Value'}, 'foo', 'Test error parameter (Value: foo).');
clean();

# Test.
my $mock = Test::MockObject->new;
$mock->fake_module('Foo',
	'new' => sub { return bless {}, 'Foo'; },
);
my $foo = Foo->new;
$self = {
	'key' => [$foo],
};
eval {
	check_array_object($self, 'key', 'Bar');
};
is($EVAL_ERROR, "Parameter 'key' with array must contain 'Bar' objects.\n",
	"Parameter 'key' with array must contain 'Bar' objects (Foo object).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Reference'}, 'Foo', 'Test error parameter (Reference: Foo).');
clean();

# Test.
$self = {
	'key' => [[]],
};
eval {
	check_array_object($self, 'key', 'Bar');
};
is($EVAL_ERROR, "Parameter 'key' with array must contain 'Bar' objects.\n",
	"Parameter 'key' with array must contain 'Bar' objects (reference to array).");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Reference'}, 'ARRAY', 'Test error parameter (Reference: ARRAY).');
clean();

# Test.
$mock = Test::MockObject->new;
$mock->fake_module('Foo',
	'new' => sub { return bless {}, 'Foo'; },
);
$foo = Foo->new;
$self = {
	'key' => [$foo],
};
my $ret = check_array_object($self, 'key', 'Foo');
is($ret, undef, 'Right structure.');

# Test.
$self = {};
$ret = check_array_object($self, 'key', 'Foo');
is($ret, undef, 'Right not exist key.');
