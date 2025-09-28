#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most tests => 18;
use Params::Validate::Strict qw(validate_strict);

# Test nested structure validation
sub test_nested_validation {
	my $schema = {
		user => {
			type => 'hashref',
			schema => {
				name => { type => 'string', min => 2 },
				age => { type => 'integer', min => 0, max => 150 },
				address => {
					type => 'hashref',
					schema => {
						street => { type => 'string' },
						city => { type => 'string' },
						zip => { type => 'string', matches => qr/^\d{5}(-\d{4})?$/ }
					},
					optional => 1
				},
				hobbies => {
					type => 'arrayref',
					schema => { type => 'string' },
					min => 1
				}
			}
		}
	};

	# Valid input
	my $valid_input = {
		user => {
			name => 'John Doe',
			age => 30,
			address => {
				street => '123 Main St',
				city => 'Anytown',
				zip => '12345'
			},
			hobbies => ['reading', 'hiking']
		}
	};

	# Invalid input - wrong zip format
	my $invalid_zip_input = {
		user => {
			name => 'John Doe',
			age => 30,
			address => {
				street => '123 Main St',
				city => 'Anytown',
				zip => 'not-a-zip'
			},
			hobbies => ['reading', 'hiking']
		}
	};

	# Invalid input - missing required field
	my $missing_field_input = {
		user => {
			name => 'John Doe',
			# age is missing
			address => {
				street => '123 Main St',
				city => 'Anytown',
				zip => '12345'
			},
			hobbies => ['reading', 'hiking']
		}
	};

	# Invalid input - wrong type for hobbies
	my $wrong_type_input = {
		user => {
			name => 'John Doe',
			age => 30,
			address => {
				street => '123 Main St',
				city => 'Anytown',
				zip => '12345'
			},
			hobbies => 'not-an-array'	# Should be arrayref
		}
	};

	my $wrong_type_elements = {
		user => {
			name => 'John Doe',
			age => 30,
			address => {
				street => '123 Main St',
				city => 'Anytown',
				zip => '12345'
			},
			hobbies => [ { 'foo' => 'bar' } ],	# Should be an arrayref of strings
		}
	};

	# Test valid input
	my $result;
	lives_ok {
		$result = validate_strict(schema => $schema, input => $valid_input);
	} "Valid nested input should not die";

	is(ref $result, 'HASH', "Result should be a hashref");
	is(ref $result->{user}, 'HASH', "User should be a hashref");
	is($result->{user}{name}, 'John Doe', "Name should be correct");
	is($result->{user}{age}, 30, "Age should be correct and coerced to integer");
	is(ref $result->{user}{address}, 'HASH', "Address should be a hashref");
	is($result->{user}{address}{zip}, '12345', "Zip code should be correct");
	is(ref $result->{user}{hobbies}, 'ARRAY', "Hobbies should be an arrayref");
	is(scalar @{$result->{user}{hobbies}}, 2, "Should have 2 hobbies");

	# Test invalid zip code
	throws_ok {
		validate_strict(schema => $schema, input => $invalid_zip_input);
	} qr/zip.*must match pattern/, "Invalid zip code should throw error";

	# Test missing required field
	throws_ok {
		validate_strict(schema => $schema, input => $missing_field_input);
	} qr/age.*missing/, "Missing required field should throw error";

	# Test wrong type for hobbies
	throws_ok {
		validate_strict(schema => $schema, input => $wrong_type_input);
	} qr/must be an arrayref/, 'Wrong type for hobbies should throw error';

	# Each hobby should be a string
	throws_ok {
		validate_strict(schema => $schema, input => $wrong_type_elements);
	} qr/must be a string/, 'Wrong type for hobbies should throw error';

	# Test with empty nested structure
	my $empty_nested_input = {
		user => {
			name => 'John Doe',
			age => 30,
			address => {},	# Empty address
			hobbies => ['reading']
		}
	};

	lives_ok {
		$result = validate_strict(schema => $schema, input => $empty_nested_input);
	} "Empty nested hashref should be acceptable";

	# Test with optional nested fields
	my $schema_with_optional = {
		user => {
			type => 'hashref',
			schema => {
				name => { type => 'string' },
				age => { type => 'integer', optional => 1 },	# age is optional
				address => {
					type => 'hashref',
					optional => 1,	# address is optional
					schema => {
						street => { type => 'string' },
						city => { type => 'string' }
					}
				}
			}
		}
	};

	my $input_without_optional = {
		user => {
			name => 'John Doe'
			# age and address are optional and missing
		}
	};

	lives_ok {
		$result = validate_strict(schema => $schema_with_optional, input => $input_without_optional);
	} "Missing optional nested fields should be acceptable";

	is($result->{user}{name}, 'John Doe', "Name should be correct");
	ok(!exists $result->{user}{age}, "Age should not exist in result");
	ok(!exists $result->{user}{address}, "Address should not exist in result");
}

# Run the tests
test_nested_validation();

done_testing();
