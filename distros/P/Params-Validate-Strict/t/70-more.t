#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Params::Validate::Strict', qw(validate_strict)) }

# Mock logger for testing
package TestLogger {
	sub new { bless { messages => [] }, shift }
	sub error { push @{shift->{messages}}, 'ERROR: ' . join('', @_); }
	sub warn { push @{shift->{messages}}, 'WARN: ' . join('', @_); }
	sub debug { push @{shift->{messages}}, 'DEBUG: ' . join('', @_); }
	sub get_messages { @{$_[0]->{messages}} }
	sub clear { $_[0]->{messages} = [] }
}

subtest "Relationship validations - uncovered code" => sub {
	my $logger = new_ok('TestLogger');
	
	# Test mutually_exclusive relationship
	dies_ok {
		validate_strict(
			schema => {
				file => { type => 'string', optional => 1 },
				content => { type => 'string', optional => 1 }
			},
			input => { file => 'test.txt', content => 'data' },
			relationships => [
				{
					type => 'mutually_exclusive',
					params => ['file', 'content'],
					description => 'Cannot specify both file and content'
				}
			],
			logger => $logger
		);
	} 'mutually_exclusive relationship should die when both params present';
	
	# Test required_group relationship
	dies_ok {
		validate_strict(
			schema => {
				id => { type => 'integer', optional => 1 },
				name => { type => 'string', optional => 1 }
			},
			input => {},
			relationships => [
				{
					type => 'required_group',
					params => ['id', 'name'],
					logic => 'or',
					description => 'Must specify either id or name'
				}
			],
			logger => $logger
		);
	} 'required_group relationship should die when none present';
	
	# Test conditional_requirement relationship
	lives_ok {
		my $result = validate_strict(
			schema => {
				async => { type => 'boolean', optional => 1 },
				callback => { type => 'coderef', optional => 1 }
			},
			input => { async => 1, callback => sub { } },
			relationships => [
				{
					type => 'conditional_requirement',
					if => 'async',
					then_required => 'callback',
					description => 'When async is specified, callback is required'
				}
			],
			logger => $logger
		);
		ok $result, 'conditional_requirement passes when condition met';
	} 'conditional_requirement with valid input';
	
	# Test dependency relationship
	dies_ok {
		validate_strict(
			schema => {
				port => { type => 'integer', optional => 1 },
				host => { type => 'string', optional => 1 }
			},
			input => { port => 80 },
			relationships => [
				{
					type => 'dependency',
					param => 'port',
					requires => 'host',
					description => 'port requires host to be specified'
				}
			],
			logger => $logger
		);
	} 'dependency relationship should die when dependency missing';
	
	# Test value_constraint relationship
	dies_ok {
		validate_strict(
			schema => {
				ssl => { type => 'boolean', optional => 1 },
				port => { type => 'integer', optional => 1 }
			},
			input => { ssl => 1, port => 80 },
			relationships => [
				{
					type => 'value_constraint',
					if => 'ssl',
					then => 'port',
					operator => '==',
					value => 443,
					description => 'When ssl is specified, port must equal 443'
				}
			],
			logger => $logger
		);
	} 'value_constraint relationship should die when constraint violated';
	
	# Test value_conditional relationship
	dies_ok {
		validate_strict(
			schema => {
				mode => { type => 'string', optional => 1 },
				key => { type => 'string', optional => 1 }
			},
			input => { mode => 'secure' },
			relationships => [
				{
					type => 'value_conditional',
					if => 'mode',
					equals => 'secure',
					then_required => 'key',
					description => "When mode equals 'secure', key is required"
				}
			],
			logger => $logger
		);
	} 'value_conditional relationship should die when condition met but required missing';
};

subtest "Semantic validation and edge cases" => sub {
	my $logger = TestLogger->new;
	
	# Test semantic rule (currently warns about unsupported)
	lives_ok {
		my $result = validate_strict(
			schema => {
				timestamp => { 
					type => 'integer',
					semantic => 'unix_timestamp'
				}
			},
			input => { timestamp => time },
			logger => $logger
		);
		ok $result, 'semantic rule with valid timestamp';
	} 'semantic rule validation';
	
	# Test _warn function via unknown_parameter_handler => 'warn'
	lives_ok {
		my $result = validate_strict(
			schema => { required_field => { type => 'string' } },
			input => { 
				required_field => 'valid',
				extra_field => 'should trigger warning'
			},
			unknown_parameter_handler => 'warn',
			logger => $logger
		);
		ok $result, 'validation with warning for unknown parameter';
		
		# Check that warning was logged
		my @messages = $logger->get_messages();
		ok(grep { /Unknown parameter 'extra_field'/ } @messages, 
		   'Warning logged for unknown parameter');
	} 'test _warn function via unknown_parameter_handler';
	
	# Test _error function with logger
	dies_ok {
		validate_strict(
			schema => { number => { type => 'integer', min => 10 } },
			input => { number => 5 },
			logger => $logger
		);
	} 'error with logger should still die';
	
	# Check that error was logged
	my @messages = $logger->get_messages;
	ok(grep { /ERROR/ } @messages, 'Error was logged via logger');
};

subtest "Edge cases in validation rules" => sub {
	# Test min > max error
	dies_ok {
		validate_strict(
			schema => { 
				field => { 
					type => 'integer',
					min => 10,
					max => 5 
				}
			},
			input => { field => 7 }
		);
	} 'should die when min > max';
	
	# Test memberof with min/max conflict
	dies_ok {
		validate_strict(
			schema => { 
				field => { 
					type => 'integer',
					memberof => [1, 2, 3],
					min => 0
				}
			},
			input => { field => 2 }
		);
	} 'should die when memberof combined with min';
	
	# Test custom types with overrides
	lives_ok {
		my $result = validate_strict(
			schema => {
				email => { 
					type => 'email',
					min => 10  # Override custom type min
				}
			},
			input => { email => 'test@example.com' },
			custom_types => {
				email => {
					type => 'string',
					matches => qr/\@/,
					min => 5,
					error_msg => 'Invalid email address'
				}
			}
		);
		ok $result, 'custom type with override';
	} 'custom type validation with override';
	
	# Test arrayref with schema validation failure
	dies_ok {
		validate_strict(
			schema => {
				items => {
					type => 'arrayref',
					schema => {
						type => 'integer',
						min => 0
					}
				}
			},
			input => { items => [1, -5, 3] }
		);
	} 'should die when nested schema validation fails';
	
	# Test transform that changes type
	dies_ok {
		validate_strict(
			schema => {
				number => {
					type => 'integer',
					transform => sub { $_[0] . 'abc' }  # Changes to string
				}
			},
			input => { number => 123 }
		);
	} 'should die when transform changes type incorrectly';
};

subtest "Positional arguments and edge cases" => sub {
	# Test positional arguments with duplicate positions
	dies_ok {
		validate_strict(
			schema => {
				first => { type => 'string', position => 0 },
				second => { type => 'string', position => 0 }  # Duplicate position
			},
			input => ['value1', 'value2']
		);
	} 'should die when duplicate positions in schema';
	
	# Test mixed positional and named args detection
	dies_ok {
		validate_strict(
			schema => {
				a => { type => 'string', position => 0 },
				b => { type => 'string' }  # Missing position
			},
			input => ['value1']
		);
	} 'should die when mixed positional and non-positional schema';
};

done_testing();
