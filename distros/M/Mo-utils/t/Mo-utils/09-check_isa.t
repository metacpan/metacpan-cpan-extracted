use strict;
use warnings;

use English;
use Error::Pure::Utils qw(clean err_msg);
use Mo::utils qw(check_isa);
use Test::MockObject;
use Test::More 'tests' => 8;
use Test::NoWarnings;

# Test.
my $mock = Test::MockObject->new;
$mock->fake_module('Foo',
	'new' => sub { return bless {}, 'Foo'; },
);
my $foo = Foo->new;
my $self = {
	'key' => $foo,
};
my $ret = check_isa($self, 'key', 'Foo');
is($ret, undef, 'Right object is present.');

# Test.
$self = {
	'key' => undef,
};
$ret = check_isa($self, 'key', 'Foo');
is($ret, undef, "Value is undefined, that's ok.");

# Test.
$self = {};
$ret = check_isa($self, 'key', 'Foo');
is($ret, undef, 'Right not exist key.');

# Test.
$self = {
	'key' => 'foo',
};
eval {
	check_isa($self, 'key', 'Foo');
};
my @errors = err_msg();
is_deeply(
	\@errors,
	[
		"Parameter 'key' must be a 'Foo' object.",
		'Value',
		'foo',
	],
	"Parameter 'key' must be a 'Foo' object (is string)."
);
clean();

# Test.
$self = {
	'key' => {'foo' => 'bar'},
};
eval {
	check_isa($self, 'key', 'Foo');
};
@errors = err_msg();
is_deeply(
	\@errors,
	[
		"Parameter 'key' must be a 'Foo' object.",
		'Reference',
		'HASH',
	],
	"Parameter 'key' must be a 'Foo' object (is reference to hash)."
);
clean();

# Test.
$self = {
	'key' => ['foo', 'bar'],
};
eval {
	check_isa($self, 'key', 'Foo');
};
@errors = err_msg();
is_deeply(
	\@errors,
	[
		"Parameter 'key' must be a 'Foo' object.",
		'Reference',
		'ARRAY',
	],
	"Parameter 'key' must be a 'Foo' object (is reference to array)."
);
clean();

# Test.
$mock = Test::MockObject->new;
$mock->fake_module('Bar',
	'new' => sub { return bless $self, 'Bar'; },
);
my $bar = Bar->new;
$self = {
	'key' => $bar,
};
eval {
	check_isa($self, 'key', 'Foo');
};
@errors = err_msg();
is_deeply(
	\@errors,
	[
		"Parameter 'key' must be a 'Foo' object.",
		'Reference',
		'Bar',
	],
	"Parameter 'key' must be a 'Foo' object (is another object)."
);
clean();
