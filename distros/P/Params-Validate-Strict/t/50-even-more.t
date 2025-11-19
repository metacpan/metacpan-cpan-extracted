#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Validate::Strict qw(validate_strict);

# Mock logger for testing
{
	package Test::Logger;
	sub new { bless { messages => [] }, shift }
	sub error { push @{$_[0]->{messages}}, { type => 'error', message => $_[2] }; die $_[2] }
	sub warn { push @{$_[0]->{messages}}, { type => 'warn', message => $_[2] } }
	sub debug { push @{$_[0]->{messages}}, { type => 'debug', message => $_[2] } }
	sub get_messages { @{$_[0]->{messages}} }
	sub clear { $_[0]->{messages} = [] }
}

my $logger = new_ok('Test::Logger');

# Undefined rules (allow anything)
subtest 'undefined rules' => sub {
	my $schema = { anything => undef };
	my $input = { anything => 'this should pass' };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is($@, '', 'undefined rules should allow anything');
	is($result->{anything}, 'this should pass', 'value should be passed through');
};

# Rules must be hashref
subtest 'invald rules' => sub {
	my $schema = { anything => [ 1, 2 ] };
	my $input = { anything => 'this should pass' };

	throws_ok { validate_strict(schema => $schema, input => $input) } qr/rules must be a hash reference/, 'Rules must hashref';
};

# String rules edge cases
subtest 'string rules edge cases' => sub {
	my $schema = { bar => 'string' };
	my $input = { bar => 'foo' };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'string rule should be valid';
	is $result->{bar}, 'foo', 'string should be preserved';
};

# String validation edge cases
subtest 'string validation edge cases' => sub {
	my $schema = {
		empty_string => { type => 'string' },
		undef_string => { type => 'string', optional => 1 },
	};

	my $input = { empty_string => '' };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'empty string should be valid';
	is $result->{empty_string}, '', 'empty string should be preserved';
};

# Arrayref validation with undef
subtest 'arrayref with undef' => sub {
	my $schema = {
		array => { type => 'arrayref', optional => 1 },
	};

	my $input = { array => undef };

	my $result = eval {
		validate_strict(
			schema => $schema,
			input => $input,
			logger => $logger
		)
	};
	is $@, '', 'undef arrayref should be allowed when optional';
};

# Hashref validation with undef
subtest 'hashref with undef' => sub {
	my $schema = {
		hash => { type => 'hashref', optional => 1 },
	};

	my $input = { hash => undef };

	my $result = eval {
		validate_strict(
			schema => $schema,
			input => $input,
			logger => $logger
		)
	};
	is $@, '', 'undef hashref should be allowed when optional';
};

# Number validation edge cases
subtest 'number validation edge cases' => sub {
	my $schema = {
		undef_number => { type => 'number', optional => 1 },
		zero => { type => 'number' },
		negative => { type => 'number' },
	};

	my $input = {
		zero => 0,
		negative => -5,
	};

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'zero and negative numbers should be valid';
	is $result->{zero}, 0, 'zero should be preserved';
	is $result->{negative}, -5, 'negative number should be preserved';
};

# Invalid min/max combinations
subtest 'invalid min/max' => sub {
	my $schema = {
		test => { type => 'string', min => 10, max => 5 },
	};

	my $input = { test => 'hello' };

	eval { validate_strict(schema => $schema, input => $input, logger => $logger) };
	like $@, qr/min must be <= max/, 'should die when min > max';
};

# matches/nomatch with arrayrefs
subtest 'regex with arrayrefs' => sub {
	my $schema = {
		tags => {
			type => 'arrayref',
			matches => qr/^[a-z]+$/,
			nomatch => qr/\d/,
		},
	};

	my $input = { tags => ['hello', 'world'] };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'valid arrayref with regex should pass';
	is_deeply $result->{tags}, ['hello', 'world'], 'array should be preserved';
};

# memberof validation
subtest 'memberof validation' => sub {
	my $schema = {
		status => { type => 'string', memberof => ['active', 'inactive'] },
		number_status => { type => 'integer', memberof => [1, 2, 3] },
	};

	my $input = {
		status => 'active',
		number_status => 2,
	};

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'memberof validation should work';
	is $result->{status}, 'active', 'string member should be preserved';
	is $result->{number_status}, 2, 'number member should be preserved';
};

# callback validation
subtest 'callback validation' => sub {
	my $schema = {
		even_number => {
			type => 'integer',
			callback => sub { $_[0] % 2 == 0 }
		},
	};

	my $input = { even_number => 4 };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'callback validation should work';
	is $result->{even_number}, 4, 'validated value should be preserved';
};

# isa and can validation
subtest 'object validation' => sub {
	{
		package Test::Object;
		sub new { bless {}, shift }
		sub method1 { }
		sub method2 { }
	}

	my $obj = Test::Object->new;
	my $schema = {
		obj => {
			type => 'object',
			isa => 'Test::Object',
			can => ['method1', 'method2'],
		},
	};

	my $input = { obj => $obj };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'object validation should work';
	is $result->{obj}, $obj, 'object should be preserved';
};

# element_type validation
subtest 'element type validation' => sub {
	my $schema = {
		numbers => {
			type => 'arrayref',
			element_type => 'number',
		},
		strings => {
			type => 'arrayref',
			element_type => 'string',
		},
		integers => {
			type => 'arrayref',
			element_type => 'integer',
		},
	};

	my $input = {
		integers => [1, 2, 3],
		numbers => [1, 2, 3.5],
		strings => ['a', 'b', 'c'],
	};

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'element type validation should work';
	is_deeply $result->{integers}, [1, 2, 3], 'integer array should be preserved';
	is_deeply $result->{numbers}, [1, 2, 3.5], 'number array should be preserved';
	is_deeply $result->{strings}, ['a', 'b', 'c'], 'strings array should be preserved';
};

# nested schema validation
subtest 'nested schema validation' => sub {
	my $schema = {
		user => {
			type => 'hashref',
			schema => {
				name => { type => 'string' },
				age => { type => 'integer', min => 0 },
			},
		},
		tags => {
			type => 'arrayref',
			schema => { type => 'string' },
		},
	};

	my $input = {
		user => { name => 'John', age => 30 },
		tags => ['perl', 'testing'],
	};

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'nested schema validation should work';
	is $result->{user}{name}, 'John', 'nested name should be preserved';
	is $result->{user}{age}, 30, 'nested age should be preserved';
	is_deeply $result->{tags}, ['perl', 'testing'], 'nested tags should be preserved';
};

# unknown parameter handlers
subtest 'unknown parameter handlers' => sub {
	my $schema = { known => { type => 'string' } };
	my $input = { known => 'ok', unknown => 'should be handled' };

	# Test warn handler
	eval {
		validate_strict(
			schema => $schema,
			input => $input,
			unknown_parameter_handler => 'warn',
			logger => $logger
		)
	};
	is $@, '', 'warn handler should not die';

	# Test ignore handler
	eval {
		validate_strict(
			schema => $schema,
			input => $input,
			unknown_parameter_handler => 'ignore',
			logger => $logger
		)
	};
	is $@, '', 'ignore handler should not die';
};

# default values
subtest 'default values' => sub {
	my $schema = {
		username => {
			type => 'string',
			optional => 1,
			default => 'guest'
		},
	};

	my $input = { };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'default values should work';
	is $result->{username}, 'guest', 'default value should be set';
};

# error messages
subtest 'custom error messages' => sub {
	my $schema = {
		age => {
			type => 'integer',
			min => 18,
			error_msg => 'You must be at least 18 years old'
		},
	};

	my $input = { age => 16 };

	eval { validate_strict(schema => $schema, input => $input) };
	like $@, qr/You must be at least 18 years old/, 'custom error message should be used';
};

# invalid regex in matches
subtest 'invalid regex' => sub {
	my $schema = {
		test => {
			type => 'string',
			matches => '[[invalid-regex', # broken regex
		},
	};

	my $input = { test => 'hello' };

	eval { validate_strict(schema => $schema, input => $input, logger => $logger) };
	like $@, qr/invalid regex/, 'should handle invalid regex gracefully';
};

# coderef validation
subtest 'coderef validation' => sub {
	my $schema = {
		callback => { type => 'coderef' },
	};

	my $input = { callback => sub { return 'test' } };

	my $result = eval { validate_strict(schema => $schema, input => $input) };
	is $@, '', 'coderef validation should work';
	is ref($result->{callback}), 'CODE', 'should preserve coderef';
};

done_testing;
