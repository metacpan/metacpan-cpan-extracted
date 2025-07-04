use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg_hr);
use Mo::utils qw(check_array_object);
use Test::MockObject;
use Test::More 'tests' => 10;
use Test::NoWarnings;

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_array_object($self, 'key', 'Foo', 'Foo');
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
	check_array_object($self, 'key', 'Foo', 'Foo');
};
is($EVAL_ERROR, "Foo isn't 'Foo' object.\n",
	"Foo isn't 'Foo' object.");
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
	check_array_object($self, 'key', 'Bar', 'Bar');
};
is($EVAL_ERROR, "Bar isn't 'Bar' object.\n",
	"Bar isn't 'Bar' object.");
$err_msg_hr = err_msg_hr();
is($err_msg_hr->{'Reference'}, 'Foo', 'Test error parameter (Reference: Foo).');
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
my $ret = check_array_object($self, 'key', 'Foo', 'Foo');
is($ret, undef, 'Right structure.');

# Test.
$self = {};
$ret = check_array_object($self, 'key', 'Foo', 'Foo');
is($ret, undef, 'Right not exist key.');
