use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean);
use Test::MockObject;
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Mo::utils qw(check_array_object);

# Test.
my $self = {
	'key' => 'foo',
};
eval {
	check_array_object($self, 'key', 'Foo', 'Foo');
};
is($EVAL_ERROR, "Parameter 'key' must be a array.\n",
	"Parameter 'key' must be a array.");
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
clean();

# Test.
my $mock = Test::MockObject->new;
$mock->fake_module('Foo',
	'new' => sub { return $self, 'Foo'; },
);
my $foo = Foo->new;
$self = {
	'key' => [$foo],
};
my $ret = check_array_object($self, 'key', 'Foo', 'Foo');
is($ret, undef, 'Right structure.');

# Test.
$self = {};
$ret = check_array_object($self, 'key', 'Foo', 'Foo');
is($ret, undef, 'Right structure. No key.');
