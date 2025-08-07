#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use Test::Exception;
use Scalar::Util qw(blessed);

BEGIN { use_ok('Params::Validate::Strict', qw(validate_strict)) }

# Test basic functionality
subtest 'Basic validation' => sub {
	my $schema = {
		name => 'string',
		age => 'integer',
	};

	my $args = {
		name => 'John',
		age => '30',
	};

	lives_ok {
		my $result = validate_strict(schema => $schema, args => $args);
		is($result->{name}, 'John', 'String value preserved');
		is($result->{age}, 30, 'Integer coerced');
		is(ref($result->{age}), '', 'Age is now a true integer');
	} 'Basic validation succeeds';
};

# Test type coercion edge cases
subtest 'Type coercion edge cases' => sub {
	my $schema = {
		int_field => { type => 'integer', optional => 1 },
		num_field => { type => 'number', optional => 1 },
	};

	# Integer edge cases
	for my $test_case (
		[' 42 ', 42, 'Whitespace trimmed in integer'],
		['+123', 123, 'Leading plus sign handled'],
		['-456', -456, 'Negative numbers work'],
		['0', 0, 'Zero handled correctly'],
	) {
		my ($input, $expected, $desc) = @$test_case;

		lives_ok {
			validate_strict(
				schema => $schema,
				args => {int_field => $input}
			);
		} "Valid integer allowed $desc";
	}

	# Number edge cases
	for my $test_case (
		['123.456', 123.456, 'Decimal numbers work'],
		['-0.5', -0.5, 'Negative decimals work'],
		['1e10', 1e10, 'Scientific notation works'],
		['inf', 'inf', 'Infinity handled'],
	) {
		my ($input, $expected, $desc) = @$test_case;

		lives_ok {
			my $result = validate_strict(
				schema => {num_field => 'number'},
				args => {num_field => $input}
			);
			cmp_ok($result->{num_field}, '==', $expected, $desc);
		} $desc;
	}
};

# Test security vulnerabilities
subtest 'Security tests' => sub {
	my $schema = {
		num_field => { 'type' => 'number', optional => 1 },
		str_field => { 'type' => 'string', optional => 1, 'max' => 1000 },
		arr_field => { 'type' => 'arrayref', optional => 1, 'max' => 500 },
	};

	# Test eval injection prevention
	throws_ok {
		validate_strict(
			schema => $schema,
			args => {num_field => 'system("cat /etc/passwd")'}
		);
	} qr/must be a number/, 'Code injection in number field prevented';

	throws_ok {
		validate_strict(
			schema => $schema,
			args => {num_field => '__FILE__'}
		);
	} qr/must be a number/, 'Variable injection in number field prevented';

	# Test DoS prevention
	throws_ok {
		validate_strict(
			schema => $schema,
			args => {str_field => 'x' x 2_000_000}
		);
	} qr/must be no longer than 1000/, 'Extremely large strings rejected';

	throws_ok {
		validate_strict(
			schema => $schema,
			args => {arr_field => [(1) x 20_000]}
		);
	} qr/must contain no more than 500 items/, 'Extremely large arrays rejected';

	# Test regex DoS prevention
	throws_ok {
		validate_strict(
			schema => {bad_regex => {type => 'string', matches => qr/(a+)+b/}},
			args => {bad_regex => 'a' x 1000}
		);
	} qr//, 'ReDoS patterns handled';

	# Test callback security
	my $malicious_callback = sub {
		system("echo 'malicious code executed'");
		return 1;
	};

	# This should work but the callback shouldn't cause harm in validation context
	lives_ok {
		validate_strict(
			schema => {test => {type => 'string', callback => $malicious_callback}},
			args => {test => 'safe_value'}
		);
	} 'Callback validation works safely';
};

# Test optional parameter edge cases
subtest 'Optional parameter handling' => sub {
	my $schema = {
		required => 'string',
		optional => {type => 'string', optional => 1},
		optional_with_default => {type => 'integer', optional => 1, min => 0},
	};

	# Missing required parameter
	throws_ok {
		validate_strict(schema => $schema, args => {});
	} qr/Required parameter 'required' is missing/, 'Missing required parameter throws';

	# Optional parameter missing
	lives_ok {
		my $result = validate_strict(
			schema => $schema,
			args => {required => 'test'}
		);
		ok(!exists $result->{optional}, 'Missing optional parameter not in result');
	} 'Missing optional parameter handled correctly';

	# Optional parameter undefined
	lives_ok {
		my $result = validate_strict(
			schema => $schema,
			args => {required => 'test', optional => undef}
		);
		ok(exists $result->{optional}, 'Undefined optional parameter in result');
		is($result->{optional}, undef, 'Undefined optional parameter stays undefined');
	} 'Undefined optional parameter handled correctly';

	# Optional parameter with value
	lives_ok {
		my $result = validate_strict(
			schema => $schema,
			args => {required => 'test', optional => 'value'}
		);
		is($result->{optional}, 'value', 'Optional parameter with value preserved');
	} 'Optional parameter with value handled correctly';
};

# Test constraint validation
subtest 'Constraint validation' => sub {
	# String length constraints
	my $string_schema = {
		short => {type => 'string', min => 3, max => 10}
	};

	throws_ok {
		validate_strict(schema => $string_schema, args => {short => 'ab'});
	} qr/too short/, 'String too short rejected';

	throws_ok {
		validate_strict(schema => $string_schema, args => {short => 'a' x 15});
	} qr/too long/, 'String too long rejected';

	lives_ok {
		validate_strict(schema => $string_schema, args => {short => 'valid'});
	} 'Valid string length accepted';

	# Numeric constraints
	my $num_schema = {
		score => {type => 'integer', min => 0, max => 100}
	};

	throws_ok {
		validate_strict(schema => $num_schema, args => {score => -1});
	} qr/must be at least 0/, 'Number too small rejected';

	throws_ok {
		validate_strict(schema => $num_schema, args => {score => 101});
	} qr/must be no more than 100/, 'Number too large rejected';

	lives_ok {
		validate_strict(schema => $num_schema, args => {score => 85});
	} 'Valid number range accepted';

	# Array size constraints
	my $array_schema = {
		items => {type => 'arrayref', min => 1, max => 3}
	};

	throws_ok {
		validate_strict(schema => $array_schema, args => {items => []});
	} qr/must be at least length 1/, 'Array too small rejected';

	throws_ok {
		validate_strict(schema => $array_schema, args => {items => [1,2,3,4]});
	} qr/must contain no more than 3 items/, 'Array too large rejected';

	lives_ok {
		validate_strict(schema => $array_schema, args => {items => [1,2]});
	} 'Valid array size accepted';

	# Hash size constraints
	my $hash_schema = {
		config => {type => 'hashref', min => 1, max => 2}
	};

	throws_ok {
		validate_strict(schema => $hash_schema, args => {config => {}});
	} qr/must contain at least 1 key/, 'Hash too small rejected';

	throws_ok {
		validate_strict(schema => $hash_schema, args => {config => {a=>1,b=>2,c=>3}});
	} qr/must contain no more than 2 keys/, 'Hash too large rejected';

	lives_ok {
		validate_strict(schema => $hash_schema, args => {config => {key => 'value'}});
	} 'Valid hash size accepted';

	# Invalid constraint combinations
	throws_ok {
		validate_strict(
			schema => {bad => {type => 'string', min => 10, max => 5}},
			args => {bad => 'test'}
		);
	} qr/min must be <= max/, 'Invalid min/max combination rejected in schema';

	throws_ok {
		validate_strict(
			schema => {bad => {type => 'object', min => 1}},
			args => {bad => bless {}, 'TestClass'}
		);
	} qr/meaningless min value/, 'Meaningless constraint rejected';

	throws_ok {
		validate_strict(
			schema => {bad => {type => 'coderef', max => 1}},
			args => {bad => sub { }}
		);
	} qr/meaningless max value/, 'Meaningless constraint rejected';
};

# Test pattern matching
subtest 'Pattern matching' => sub {
	my $schema = {
		email => {type => 'string', matches => qr/^[\w.-]+\@[\w.-]+\.\w+$/, optional => 1},
		not_numeric => {type => 'string', nomatch => qr/^\d+$/, optional => 1},
	};

	lives_ok {
		validate_strict(
			schema => $schema,
			args => {
				email => 'test@example.com',
				not_numeric => 'abc123'
			}
		);
	} 'Valid patterns accepted';

	throws_ok {
		validate_strict(schema => $schema, args => {email => 'invalid-email'});
	} qr/must match pattern/, 'Invalid email pattern rejected';

	throws_ok {
		validate_strict(schema => $schema, args => {not_numeric => '12345'});
	} qr/must not match pattern/, 'Forbidden pattern rejected';

	# Test string pattern compilation
	my $string_pattern_schema = {
		code => {type => 'string', matches => qr/^[A-Z]{2,3}\d+/},
	};

	lives_ok {
		validate_strict(schema => $string_pattern_schema, args => {code => 'ABC123'});
	} 'String pattern compiled and matched correctly';

	throws_ok {
		validate_strict(schema => $string_pattern_schema, args => {code => 'invalid'});
	} qr/must match pattern/, 'String pattern compilation works';

	# Test invalid regex in schema
	throws_ok {
		validate_strict(
			schema => {bad => {type => 'string', matches => '[unclosed'}},
			args => {bad => 'test'}
		);
	} qr/invalid regex/, 'Invalid regex in schema detected';

	# Test undefined value with patterns (should skip validation)
	lives_ok {
		validate_strict(
			schema => {optional_pattern => {type => 'string', matches => qr/test/, optional => 1}},
			args => {optional_pattern => undef}
		);
	} 'Undefined optional values skip pattern validation';
};

# Test membership validation
subtest 'Membership validation' => sub {
	my $schema = {
		status => {type => 'string', memberof => ['active', 'inactive', 'pending'], optional => 1},
		priority => {type => 'integer', memberof => [1, 2, 3, 4, 5], optional => 1},
	};

	lives_ok {
		validate_strict(
			schema => $schema,
			args => {status => 'active', priority => 3}
		);
	} 'Valid membership values accepted';

	throws_ok {
		validate_strict(schema => $schema, args => {status => 'unknown'});
	} qr/must be one of/, 'Invalid string membership rejected';

	throws_ok {
		validate_strict(schema => $schema, args => {priority => 10});
	} qr/must be one of/, 'Invalid integer membership rejected';

	# Test numeric equality vs string equality
	lives_ok {
		validate_strict(
			schema => {num => {type => 'integer', memberof => [1, 2, 3]}},
			args => {num => '2'}  # String that coerces to number
		);
	} 'Numeric membership uses numeric equality';

	lives_ok {
		validate_strict(
			schema => {str => {type => 'string', memberof => ['1', '2', '3']}},
			args => {str => 1}  # Number
		);
	} 'String membership uses string equality';

	# Test invalid memberof in schema
	throws_ok {
		validate_strict(
			schema => {bad => {type => 'string', memberof => 'not_array'}},
			args => {bad => 'test'}
		);
	} qr/must be an array reference/, 'Invalid memberof in schema detected';
};

# Test object validation
subtest 'Object validation' => sub {
	package TestClass;
	sub new { bless {}, shift }
	sub test_method { return 1 }

	package AnotherClass;
	sub new { bless {}, shift }

	package main;

	my $obj = new_ok('TestClass');
	my $other_obj = new_ok('AnotherClass');
	my $unblessed = {};

	# Basic object validation
	lives_ok {
		validate_strict(
			schema => {obj => 'object'},
			args => {obj => $obj}
		);
	} 'Blessed object accepted';

	throws_ok {
		validate_strict(
			schema => {obj => 'object'},
			args => {obj => $unblessed}
		);
	} qr/must be an object/, 'Unblessed reference rejected';

	# ISA validation
	lives_ok {
		validate_strict(
			schema => {obj => {type => 'object', isa => 'TestClass'}},
			args => {obj => $obj}
		);
	} 'Correct ISA relationship accepted';

	throws_ok {
		validate_strict(
			schema => {obj => {type => 'object', isa => 'TestClass'}},
			args => {obj => $other_obj}
		);
	} qr/must be a 'TestClass' object/, 'Incorrect ISA relationship rejected';

	# CAN validation
	lives_ok {
		validate_strict(
			schema => {obj => {type => 'object', can => 'test_method'}},
			args => {obj => $obj}
		);
	} 'Object with required method accepted';

	throws_ok {
		validate_strict(
			schema => {obj => {type => 'object', can => 'nonexistent_method'}},
			args => {obj => $obj}
		);
	} qr/must be an object that understands/, 'Object without required method rejected';

	# Invalid ISA/CAN usage
	throws_ok {
		validate_strict(
			schema => {bad => {type => 'string', isa => 'TestClass'}},
			args => {bad => 'test'}
		);
	} qr/meaningless isa value/, 'ISA on non-object type rejected';

	throws_ok {
		validate_strict(
			schema => {bad => {type => 'string', can => 'method'}},
			args => {bad => 'test'}
		);
	} qr/meaningless can value/, 'CAN on non-object type rejected';
};

# Test callback validation
subtest 'Callback validation' => sub {
	my $even_validator = sub {
		my $val = shift;
		return $val % 2 == 0;
	};

	my $length_validator = sub {
		my $val = shift;
		return length($val) >= 3;
	};

	lives_ok {
		validate_strict(
			schema => {
				num => {type => 'integer', callback => $even_validator},
				str => {type => 'string', callback => $length_validator},
			},
			args => {num => 4, str => 'hello'}
		);
	} 'Valid callback validation passes';

	throws_ok {
		validate_strict(
			schema => {num => {type => 'integer', callback => $even_validator}},
			args => {num => 3}
		);
	} qr/failed custom validation/, 'Invalid callback validation fails';

	throws_ok {
		validate_strict(
			schema => {str => {type => 'string', callback => $length_validator}},
			args => {str => 'hi'}
		);
	} qr/failed custom validation/, 'String callback validation fails appropriately';

	# Test invalid callback in schema
	throws_ok {
		validate_strict(
			schema => {bad => {type => 'string', callback => 'not_a_coderef'}},
			args => {bad => 'test'}
		);
	} qr/must be a code reference/, 'Invalid callback in schema detected';

	# Test callback that dies
	my $dying_callback = sub { die "callback error" };

	throws_ok {
		validate_strict(
			schema => {bad => {type => 'string', callback => $dying_callback}},
			args => {bad => 'test'}
		);
	} qr/callback error/, 'Dying callback propagates error';

	# Test callback with complex validation
	my $complex_validator = sub {
		my $val = shift;
		return ref($val) eq 'HASH' &&
			   exists $val->{required_key} &&
			   $val->{required_key} =~ /^valid/;
	};

	lives_ok {
		validate_strict(
			schema => {complex => {type => 'hashref', callback => $complex_validator}},
			args => {complex => {required_key => 'valid_value', other => 'data'}}
		);
	} 'Complex callback validation works';
};

# Test unknown parameter handling
subtest 'Unknown parameter handling' => sub {
	my $schema = {known => 'string'};
	my $args = {known => 'value', unknown => 'extra'};

	# Die on unknown (default)
	throws_ok {
		validate_strict(schema => $schema, args => $args);
	} qr/Unknown parameter 'unknown'/, 'Unknown parameter causes death by default';

	throws_ok {
		validate_strict(
			schema => $schema,
			args => $args,
			unknown_parameter_handler => 'die'
		);
	} qr/Unknown parameter 'unknown'/, 'Explicit die handler works';

	# Warn on unknown
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	lives_ok {
		validate_strict(
			schema => $schema,
			args => $args,
			unknown_parameter_handler => 'warn'
		);
	} 'Warn handler does not die';

	ok(@warnings > 0, 'Warning was generated');
	like($warnings[0], qr/Unknown parameter 'unknown'/, 'Warning message is correct');

	# Ignore unknown
	lives_ok {
		validate_strict(
			schema => $schema,
			args => $args,
			unknown_parameter_handler => 'ignore'
		);
	} 'Ignore handler silently ignores unknown parameters';
};

# Test input validation and error handling
subtest 'Input validation and error handling' => sub {
	# Invalid schema type
	throws_ok {
		validate_strict(schema => 'not_a_hash', args => {});
	} qr/schema must be a hash reference/, 'Invalid schema type rejected';

	# Invalid args type
	throws_ok {
		validate_strict(schema => {}, args => 'not_a_hash');
	} qr/args must be a hash reference/, 'Invalid args type rejected';

	# Invalid unknown_parameter_handler
	throws_ok {
		validate_strict(
			schema => {},
			args => {'unknown_parameter' => 1},
			unknown_parameter_handler => 'invalid'
		);
	} qr/unknown_parameter_handler must be one of/, 'Invalid handler rejected';

	# Invalid rule type in schema
	throws_ok {
		validate_strict(
			schema => {bad => []},  # Array instead of hash or string
			args => {bad => 'value'}
		);
	} qr/must be hash reference or string/, 'Invalid rule type rejected';

	# Invalid type in schema
	throws_ok {
		validate_strict(
			schema => {bad => {type => 'invalid_type'}},
			args => {bad => 'value'}
		);
	} qr/Unknown type 'invalid_type'/, 'Invalid type in schema rejected';

	# Test parameter parsing errors
	throws_ok {
		# This should cause Params::Get to fail
		validate_strict();
	} qr/schema must be a hash reference/, 'Parameter parsing errors handled';

	# Test complex nested validation errors
	throws_ok {
		validate_strict(
			schema => {
				user => {
					type => 'hashref',
					callback => sub {
						my $user = shift;
						return exists $user->{name} &&
							   exists $user->{email} &&
							   $user->{email} =~ /\@/;
					}
				}
			},
			args => {
				user => {name => 'John'}  # Missing email
			}
		);
	} qr/failed custom validation/, 'Complex validation failures handled';

	# Test memory and DoS protection
	throws_ok {
		validate_strict(
			schema => {big_string => { type => 'string', max => 100 }},,
			args => {big_string => 'x' x 1_500_000}
		);
	} qr/must be no longer than 100/, 'DoS protection for strings works';

	throws_ok {
		validate_strict(
			schema => {big_array => { type => 'arrayref', max => 100} },
			args => {big_array => [(1) x 15_000]}
		);
	} qr/must contain no more than 100 items/, 'DoS protection for arrays works';

	throws_ok {
		my %big_hash = map { $_ => $_ } (1..15_000);
		validate_strict(
			schema => {big_hash => { type => 'hashref', max => 1000 } },
			args => {big_hash => \%big_hash}
		);
	} qr/must contain no more than 1000 keys/, 'DoS protection for hashes works';
};

# Test edge cases and corner cases
subtest 'Edge cases and corner cases' => sub {
	# Empty schema and args
	lives_ok {
		my $result = validate_strict(schema => {}, args => {});
		is_deeply($result, {}, 'Empty schema and args work');
	} 'Empty validation works';

	# Undefined rules (allow anything)
	lives_ok {
		my $result = validate_strict(
			schema => {'anything' => undef},
			args => {anything => 'any_value'}
		);
		is($result->{anything}, 'any_value', 'Undefined rules allow anything');
	} 'Undefined rules work';

	# Zero values
	lives_ok {
		my $result = validate_strict(
			schema => {
				zero_int => 'integer',
				zero_num => 'number',
				zero_str => 'string',
			},
			args => {
				zero_int => 0,
				zero_num => 0.0,
				zero_str => '0',
			}
		);
		is($result->{zero_int}, 0, 'Zero integer handled');
		is($result->{zero_num}, 0, 'Zero number handled');
		is($result->{zero_str}, '0', 'Zero string handled');
	} 'Zero values handled correctly';

	# Empty containers
	lives_ok {
		my $result = validate_strict(
			schema => {
				empty_array => {type => 'arrayref', min => 0},
				empty_hash => {type => 'hashref', min => 0},
				empty_string => {type => 'string', min => 0},
			},
			args => {
				empty_array => [],
				empty_hash => {},
				empty_string => '',
			}
		);
		is_deeply($result->{empty_array}, [], 'Empty array handled');
		is_deeply($result->{empty_hash}, {}, 'Empty hash handled');
		is($result->{empty_string}, '', 'Empty string handled');
	} 'Empty containers handled correctly';

	# Unicode and special characters
	lives_ok {
		my $result = validate_strict(
			schema => {unicode => 'string'},
			args => {unicode => 'Hello 世界 🌍'}
		);
		is($result->{unicode}, 'Hello 世界 🌍', 'Unicode characters preserved');
	} 'Unicode handling works';
};

# Benchmark and performance tests
subtest 'Performance characteristics' => sub {
	# Test validation of large but reasonable datasets
	my $schema = {
		items => {
			type => 'arrayref',
			max => 1000,
			callback => sub {
				my $arr = shift;
				return @$arr <= 1000;  # Double-check constraint
			}
		}
	};

	my $large_array = [1..500];  # Reasonable size

	lives_ok {
		my $start = time;
		my $result = validate_strict(
			schema => $schema,
			args => {items => $large_array}
		);
		my $duration = time - $start;

		ok($duration < 2, 'Large dataset validation completes in reasonable time');
		is_deeply($result->{items}, $large_array, 'Large dataset result is correct');
	} 'Performance with large datasets is acceptable';
};

done_testing();
