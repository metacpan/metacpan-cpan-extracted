#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Get qw(get_params);

use Error qw(:try);

my @args = [ 'Hello', 'Goodbye' ];
my $params = get_params('foo', @args);

diag(Data::Dumper->new([$params])->Dump()) if($ENV{'TEST_VERBOSE'});

cmp_deeply($params, { 'foo' => [ 'Hello', 'Goodbye' ] }, 'Simple test, array');
$params = get_params('foo', \@args);
cmp_deeply($params, { 'foo' => [ 'Hello', 'Goodbye' ] }, 'Simple test, array ref');

# Hash reference input
my $hash_input = { key1 => 'value1', key2 => 'value2' };
is_deeply(get_params(undef, $hash_input), $hash_input, 'Direct hash reference input works');

# Single argument with default
is_deeply(get_params('key', 'value'), { key => 'value' }, 'Single argument with default works');

# Multiple key-value pairs
is_deeply(get_params(undef, key1 => 'value1', key2 => 'value2'), { key1 => 'value1', key2 => 'value2' }, 'Multiple key-value pairs work');

# Invalid single argument without default
my $msg;
try {
	get_params(undef, 'value');
} catch Error with {
	$msg = shift;
};
like($msg, qr/Usage/, 'Throws an error for single argument without default');

# Zero arguments with default
try {
	get_params('key');
} catch Error with {
	$msg = shift;
};
like($msg, qr/Usage/, 'Throws an error for zero arguments with default');

# Zero arguments without default
$params = get_params();
is($params, undef, 'Zero arguments without default returns undef');

# Default argument with options, ref to array
{
	package Family;

	use Params::Get;

	sub new {
		my $class = shift;
		my $rc = Params::Get::get_params('name', \@_);

		return bless $rc, $class;
	}
}

my $obj = Family->new('flintstones', { 'fred' => 'wilma' });

is_deeply($obj, { 'name' => 'flintstones', 'fred' => 'wilma' }, 'Mandatory followed by options works, arrayref');

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

# Default argument with options, array
{
	package Family2;

	use Params::Get;

	sub new {
		my $class = shift;
		my $rc = Params::Get::get_params('name', @_);

		return bless $rc, $class;
	}
}

$obj = Family2->new('rubbles', { 'barney' => 'betty' });

is_deeply($obj, { 'name' => 'rubbles', 'barney' => 'betty' }, 'Mandatory followed by options works, array');

{
	package MyClass;

	use Params::Get;

	sub new {
		my $class = shift;
		my $rc = Params::Get::get_params(undef, @_);

		return bless $rc, $class;
	}
}

$obj = MyClass->new(
	config_dirs => ['/tmp'],
	config_file => 'xml_test'
);

diag(Data::Dumper->new([$obj])->Dump()) if($ENV{'TEST_VERBOSE'});

is_deeply(get_params('string', 'Hello World'), { 'string' => 'Hello World' });

is_deeply(get_params('string', \'Hello World'), { 'string' => 'Hello World' });

diag(Data::Dumper->new([get_params('string', \'Hello World')])->Dump()) if($ENV{'TEST_VERBOSE'});

done_testing();
