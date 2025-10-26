#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 38;

use Params::Validate::Strict qw(validate_strict);

# Basic password confirmation
{
	my $schema = {
		password => { type => 'string', min => 8 },
		password_confirm => { type => 'string' }
	};

	my $cross_validation = {
		passwords_match => sub {
			my $params = shift;
			return $params->{password} eq $params->{password_confirm}
				? undef : "Passwords don't match";
		}
	};

	# Matching passwords
	my $result = validate_strict(
		schema => $schema,
		input => { password => 'secret123', password_confirm => 'secret123' },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Matching passwords pass');
	is($result->{password}, 'secret123', 'Password preserved');

	# Non-matching passwords
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { password => 'secret123', password_confirm => 'different' },
			cross_validation => $cross_validation
		);
	} qr/Passwords don't match/, 'Non-matching passwords fail';
}

# Date range validation (start before end)
{
	my $schema = {
		start_date => { type => 'string' },
		end_date => { type => 'string' }
	};

	my $cross_validation = {
		date_range_valid => sub {
			my $params = shift;
			return $params->{start_date} le $params->{end_date}
				? undef : "Start date must be before or equal to end date";
		}
	};

	# Valid date range
	my $result = validate_strict(
		schema => $schema,
		input => { start_date => '2024-01-01', end_date => '2024-12-31' },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Valid date range passes');

	# Invalid date range
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { start_date => '2024-12-31', end_date => '2024-01-01' },
			cross_validation => $cross_validation
		);
	} qr/Start date must be before or equal to end date/, 'Invalid date range fails';
}

# Multiple cross-field validations
{
	my $schema = {
		password => { type => 'string', min => 8 },
		password_confirm => { type => 'string' },
		email => { type => 'string' },
		email_confirm => { type => 'string' }
	};

	my $cross_validation = {
		passwords_match => sub {
			my $params = shift;
			return $params->{password} eq $params->{password_confirm}
				? undef : "Passwords don't match";
		},
		emails_match => sub {
			my $params = shift;
			return $params->{email} eq $params->{email_confirm}
				? undef : "Email addresses don't match";
		}
	};

	# All matching
	my $result = validate_strict(
		schema => $schema,
		input => {
			password => 'secret123',
			password_confirm => 'secret123',
			email => 'user@test.com',
			email_confirm => 'user@test.com'
		},
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Multiple cross-validations all pass');

	# Password mismatch
	throws_ok {
		validate_strict(
			schema => $schema,
			input => {
				password => 'secret123',
				password_confirm => 'different',
				email => 'user@test.com',
				email_confirm => 'user@test.com'
			},
			cross_validation => $cross_validation
		);
	} qr/Passwords don't match/, 'First cross-validation fails';

	# Email mismatch
	throws_ok {
		validate_strict(
			schema => $schema,
			input => {
				password => 'secret123',
				password_confirm => 'secret123',
				email => 'user@test.com',
				email_confirm => 'different@test.com'
			},
			cross_validation => $cross_validation
		);
	} qr/Email addresses don't match/, 'Second cross-validation fails';
}

# Numeric comparison validation
{
	my $schema = {
		min_price => { type => 'number', min => 0 },
		max_price => { type => 'number', min => 0 }
	};

	my $cross_validation = {
		price_range_valid => sub {
			my $params = shift;
			return $params->{min_price} <= $params->{max_price}
				? undef : "Minimum price must be less than or equal to maximum price";
		}
	};

	# Valid price range
	my $result = validate_strict(
		schema => $schema,
		input => { min_price => 10.50, max_price => 99.99 },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Valid price range passes');
	is($result->{min_price}, 10.50, 'Min price preserved');
	is($result->{max_price}, 99.99, 'Max price preserved');

	# Invalid price range
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { min_price => 100, max_price => 50 },
			cross_validation => $cross_validation
		);
	} qr/Minimum price must be less than or equal to maximum price/, 'Invalid price range fails';
}

# Conditional required field based on another field
{
	my $schema = {
		shipping_method => { type => 'string', memberof => ['pickup', 'delivery'] },
		delivery_address => { type => 'string', optional => 1 }
	};

	my $cross_validation = {
		address_required_for_delivery => sub {
			my $params = shift;
			if ($params->{shipping_method} eq 'delivery' && !$params->{delivery_address}) {
				return "Delivery address is required when shipping method is 'delivery'";
			}
			return undef;
		}
	};

	# Pickup - no address needed
	my $result = validate_strict(
		schema => $schema,
		input => { shipping_method => 'pickup' },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Pickup without address passes');

	# Delivery with address
	$result = validate_strict(
		schema => $schema,
		input => {
			shipping_method => 'delivery',
			delivery_address => '123 Main St'
		},
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Delivery with address passes');

	# Delivery without address
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { shipping_method => 'delivery' },
			cross_validation => $cross_validation
		);
	} qr/Delivery address is required/, 'Delivery without address fails';
}

# Age verification with birthday
{
	my $schema = {
		birth_year => { type => 'integer', min => 1900, max => 2024 },
		age => { type => 'integer', min => 0, max => 150 }
	};

	my $cross_validation = {
		age_matches_birth_year => sub {
			my $params = shift;
			my $current_year = 2024;
			my $calculated_age = $current_year - $params->{birth_year};

			# Allow age to be within 1 year (birthday may not have passed)
			if (abs($calculated_age - $params->{age}) > 1) {
				return "Age doesn't match birth year";
			}
			return undef;
		}
	};

	# Valid age/birth year combination
	my $result = validate_strict(
		schema => $schema,
		input => { birth_year => 1990, age => 34 },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Valid age/birth year passes');

	# Invalid age/birth year combination
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { birth_year => 1990, age => 20 },
			cross_validation => $cross_validation
		);
	} qr/Age doesn't match birth year/, 'Inconsistent age/birth year fails';
}

# Complex business logic validation
{
	my $schema = {
		total_amount => { type => 'number', min => 0 },
		discount_code => { type => 'string', optional => 1 },
		discount_amount => { type => 'number', min => 0, optional => 1 }
	};

	my $cross_validation = {
		discount_valid => sub {
			my $params = shift;

			# If discount code provided, discount amount must be provided
			if ($params->{discount_code} && !defined($params->{discount_amount})) {
				return "Discount amount required when discount code is provided";
			}

			# Discount can't exceed total
			if (defined($params->{discount_amount}) &&
				$params->{discount_amount} > $params->{total_amount}) {
				return "Discount amount cannot exceed total amount";
			}

			return undef;
		}
	};

	# Valid with discount
	my $result = validate_strict(
		schema => $schema,
		input => {
			total_amount => 100,
			discount_code => 'SAVE10',
			discount_amount => 10
		},
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Valid discount passes');

	# Discount code without amount
	throws_ok {
		validate_strict(
			schema => $schema,
			input => {
				total_amount => 100,
				discount_code => 'SAVE10'
			},
			cross_validation => $cross_validation
		);
	} qr/Discount amount required/, 'Discount code without amount fails';

	# Discount exceeds total
	throws_ok {
		validate_strict(
			schema => $schema,
			input => {
				total_amount => 100,
				discount_code => 'SAVE10',
				discount_amount => 150
			},
			cross_validation => $cross_validation
		);
	} qr/Discount amount cannot exceed total amount/, 'Excessive discount fails';
}

# Array sum validation
{
	my $schema = {
		items => { type => 'arrayref', element_type => 'integer', min => 1 },
		total => { type => 'integer', min => 0 }
	};

	my $cross_validation = {
		total_matches_sum => sub {
			my $params = shift;
			my $sum = 0;
			$sum += $_ for @{$params->{items}};

			return $sum == $params->{total}
				? undef : "Total ($params->{total}) doesn't match sum of items ($sum)";
		}
	};

	# Valid total
	my $result = validate_strict(
		schema => $schema,
		input => { items => [10, 20, 30], total => 60 },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Valid total matches sum');

	# Invalid total
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { items => [10, 20, 30], total => 50 },
			cross_validation => $cross_validation
		);
	} qr/Total \(50\) doesn't match sum of items \(60\)/, 'Incorrect total fails';
}

# Cross-validation with transformed fields
{
	my $schema = {
		email => {
			type => 'string',
			transform => sub { lc($_[0]) }
		},
		email_confirm => {
			type => 'string',
			transform => sub { lc($_[0]) }
		}
	};

	my $cross_validation = {
		emails_match => sub {
			my $params = shift;
			return $params->{email} eq $params->{email_confirm}
				? undef : "Email addresses don't match";
		}
	};

	# Case-insensitive match due to transform
	my $result = validate_strict(
		schema => $schema,
		input => {
			email => 'User@Example.COM',
			email_confirm => 'user@example.com'
		},
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Transformed emails match');
	is($result->{email}, 'user@example.com', 'Email lowercased');
	is($result->{email_confirm}, 'user@example.com', 'Confirm email lowercased');
}

# Optional fields in cross-validation
{
	my $schema = {
		min_age => { type => 'integer', min => 0, optional => 1 },
		max_age => { type => 'integer', min => 0, optional => 1 }
	};

	my $cross_validation = {
		age_range_valid => sub {
			my $params = shift;

			# Only validate if both are provided
			if (defined($params->{min_age}) && defined($params->{max_age})) {
				return $params->{min_age} <= $params->{max_age}
					? undef : "Minimum age must be less than or equal to maximum age";
			}
			return undef;
		}
	};

	# Both provided and valid
	my $result = validate_strict(
		schema => $schema,
		input => { min_age => 18, max_age => 65 },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Valid optional age range passes');

	# Only min provided
	$result = validate_strict(
		schema => $schema,
		input => { min_age => 18 },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Only min age passes');

	# Neither provided
	$result = validate_strict(
		schema => $schema,
		input => {},
		cross_validation => $cross_validation
	);
	ok(defined($result), 'No ages provided passes');

	# Both provided but invalid
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { min_age => 65, max_age => 18 },
			cross_validation => $cross_validation
		);
	} qr/Minimum age must be less than or equal to maximum age/, 'Invalid optional age range fails';
}

# Multiple validations with some passing, some failing
{
	my $schema = {
		username => { type => 'string' },
		email => { type => 'string' },
		password => { type => 'string', min => 8 },
		password_confirm => { type => 'string' }
	};

	my $cross_validation = {
		username_not_in_email => sub {
			my $params = shift;
			return index($params->{email}, $params->{username}) == -1
				? undef : "Username cannot be part of email address";
		},
		passwords_match => sub {
			my $params = shift;
			return $params->{password} eq $params->{password_confirm}
				? undef : "Passwords don't match";
		}
	};

	# First validation passes, second fails
	throws_ok {
		validate_strict(
			schema => $schema,
			input => {
				username => 'johndoe',
				email => 'contact@example.com',
				password => 'secret123',
				password_confirm => 'different'
			},
			cross_validation => $cross_validation
		);
	} qr/Passwords don't match/, 'Second validation fails even when first passes';

	# First validation fails
	throws_ok {
		validate_strict(
			schema => $schema,
			input => {
				username => 'johndoe',
				email => 'johndoe@example.com',
				password => 'secret123',
				password_confirm => 'secret123'
			},
			cross_validation => $cross_validation
		);
	} qr/Username cannot be part of email address/, 'First validation fails';
}

# Cross-validation with nested structures
{
	my $schema = {
		user => {
			type => 'hashref',
			schema => {
				name => { type => 'string' },
				age => { type => 'integer', min => 0 }
			}
		}, guardian => {
			type => 'hashref',
			optional => 1,
			schema => {
				name => { type => 'string' },
				relationship => { type => 'string' }
			}
		}
	};

	my $cross_validation = {
		guardian_required_for_minors => sub {
			my $params = shift;
			if ($params->{user}{age} < 18 && !$params->{guardian}) {
				return 'Guardian information required for users under 18';
			}
			return undef;
		}
	};

	# Adult - no guardian needed
	my $result = validate_strict(
		schema => $schema,
		input => {
			user => { name => 'John Doe', age => 25 }
		},
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Adult without guardian passes');

	# Minor with guardian
	$result = validate_strict(
		schema => $schema,
		input => {
			user => { name => 'Jane Doe', age => 16 },
			guardian => { name => 'John Doe', relationship => 'Father' }
		},
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Minor with guardian passes');

	# Minor without guardian
	throws_ok {
		validate_strict(
			schema => $schema,
			input => {
				user => { name => 'Jane Doe', age => 16 }
			},
			cross_validation => $cross_validation
		);
	} qr/Guardian information required for users under 18/, 'Minor without guardian fails';
}

# Cross-validation returns success explicitly
{
	my $schema = {
		value1 => { type => 'integer' },
		value2 => { type => 'integer' }
	};

	my $cross_validation = {
		values_different => sub {
			my $params = shift;
			return $params->{value1} != $params->{value2}
				? undef : "Values must be different";
		}
	};

	# Different values
	my $result = validate_strict(
		schema => $schema,
		input => { value1 => 10, value2 => 20 },
		cross_validation => $cross_validation
	);
	ok(defined($result), 'Different values pass');
	is($result->{value1}, 10, 'First value preserved');
	is($result->{value2}, 20, 'Second value preserved');

	# Same values
	throws_ok {
		validate_strict(
			schema => $schema,
			input => { value1 => 10, value2 => 10 },
			cross_validation => $cross_validation
		);
	} qr/Values must be different/, 'Same values fail';
}

done_testing();
