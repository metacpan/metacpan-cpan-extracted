package MyTest::Net::NSCA::Client;

use strict;
use warnings 'all';

use Test::Fatal;
use Test::More 0.18;

use base qw[MyTest::Class];

# TODO: Write more tests for this class

sub constructor_new : Tests(3) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make sure new exists
	can_ok $class, 'new';

	# Constructor with no arguments should work
	my $client = new_ok $class;

	ok(exception { $class->new(bad_argument => 1) }, 'Constructor dies on non-existant attribute');

	return;
}

sub attribute_remote_host : Tests(6) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make sure attribute exists
	can_ok $class, 'remote_host';

	# Constructor tests
	$test->_attribute_constructor_test(remote_host => 'test.example.net');

	# New object
	my $client = $test->_bare_object;

	{
		no strict 'refs';
		is $client->remote_host, ${$class.'::DEFAULT_HOST'}, 'remote_host is defaulting to $DEFAULT_HOST';
	}

	ok(!exception { $client->remote_host('lava.example.net') }, 'Setting remote_host to valid value works');
	is $client->remote_host, 'lava.example.net', 'remote_host setting works';

	return;
}

sub attribute_remote_port : Tests(9) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make sure attribute exists
	can_ok $class, 'remote_port';

	# Constructor tests
	$test->_attribute_constructor_test(remote_port => 600);

	# New object
	my $client = $test->_bare_object;

	{
		no strict 'refs';
		is $client->remote_port, ${$class.'::DEFAULT_PORT'}, 'remote_port is defaulting to $DEFAULT_PORT';
	}

	ok(!exception { $client->remote_port(2) }, 'Setting remote_port to valid value works');
	is $client->remote_port, 2, 'remote_port setting works';

	ok(exception { $client->remote_port(5.55) }, 'Setting remote_port to decimal number fails');
	ok(exception { $client->remote_port(-2) }, 'Setting remote_port to negative number fails');
	ok(exception { $client->remote_port(9564481) }, 'Setting remote_port too large fails');

	return;
}

sub attribute_timeout : Tests(9) {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Make sure attribute exists
	can_ok $class, 'timeout';

	# Constructor tests
	$test->_attribute_constructor_test(timeout => 600);

	# New object
	my $client = $test->_bare_object;

	{
		no strict 'refs';
		is $client->timeout, ${$class.'::DEFAULT_TIMEOUT'}, 'Timeout is defaulting to $DEFAULT_TIMEOUT';
	}

	ok(!exception { $client->timeout(2) }, 'Setting timeout to valid value works');
	is $client->timeout, 2, 'Timeout setting works';

	ok(exception { $client->timeout(5.55) }, 'Setting timeout to deciman number fails');
	ok(exception { $client->timeout(-2) }, 'Setting timeout to negative number fails');
	ok(exception { $client->timeout(0) }, 'Setting timeout to 0 fails');

	return;
}

sub _attribute_constructor_test {
	my ($test, $attribute_name, $attribute_value) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	# Attribute is settable from constructor
	is $class->new( $attribute_name => $attribute_value )->$attribute_name, $attribute_value,
		sprintf 'Attribute %s set from constructor(HASH)', $attribute_name;
	is $class->new({$attribute_name => $attribute_value})->$attribute_name, $attribute_value,
		sprintf 'Attribute %s set from constructor(HASHREF)', $attribute_name;

	return;
}

sub _bare_object {
	my ($test) = @_;

	# Get the name of the class we are testing
	my $class = $test->class;

	return $class->new;
}

1;
