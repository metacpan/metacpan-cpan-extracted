#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Params::Validate::Strict qw(validate_strict);

{
	package MyClass;

	sub new { return bless { }, shift }

	sub foo { }
}

subtest 'Valid Inputs' => sub {
	my $schema = {
		username => { type => 'string', min => 3, max => 50, nomatch => qr/\d/ },
		age => { type => 'integer', min => 0, max => 150 },
		email => { type => 'string', matches => qr/^[^@]+@[^@]+\.[^@]+$/, min => 1 },
		bio => { type => 'string', optional => 1, 'min' => 10, 'max' => 10 },
		price => { type => 'number', min => 0 },
		quantity => { type => 'number', min => 1 },
		password => {
			type => 'string',
			min => 8,
			callback => sub {
				my $password = shift;
				return $password =~ m/[a-z]/ && $password =~ m/[A-Z]/ && $password =~ m/[0-9]/;
			},
		},
		name => 'string', # Simple type string
		obj => { 'type' => 'object', optional => 1, can => 'foo' }
	};

	my $args = {
		username => 'test_user',
		age => 30,
		email => 'test@example.com',
		bio => 'A test bio',
		price => "19.99",
		quantity => 10,
		password => 'P@$$wOrd123',
		name => 'John Doe',
		obj => new_ok('MyClass')
	};

	my $validated_params = validate_strict({ schema => $schema, args => $args });

	ok defined $validated_params, "Validation should succeed";
	is $validated_params->{username}, "test_user", "Username should be correct";
	is $validated_params->{age}, 30, "Age should be correct and coerced to integer";
	is $validated_params->{email}, 'test@example.com', "Email should be correct";
	is $validated_params->{bio}, "A test bio", "Bio should be correct";
	is $validated_params->{price}, 19.99, "Price should be correct and coerced to number";
	is $validated_params->{quantity}, 10, "Quantity should be correct and coerced to number";
	is $validated_params->{password}, 'P@$$wOrd123', "Password should be correct";
	is $validated_params->{name}, "John Doe", "Name should be correct";
	isa_ok($validated_params->{obj}, 'MyClass', 'Object can be passed');

	my $args2 = {
		username => 'test_user',
		age => "30",
		email => 'test@example.com',
		price => "19.99",
		quantity => "10",
		password => 'P@$$wOrd123',
		name => "John Doe",
	};

	my $validated_params2 = validate_strict(schema => $schema, args => $args2);
	ok defined $validated_params2, "Validation should succeed (optional bio)";
	isnt exists $validated_params2->{bio}, 1, "Bio should not exist";

	my $args3 = {
		email => 'test@example.com',
		bio => undef,
		name => "Jane Doe",
	};

	my $validated_params3;

	throws_ok { $validated_params3 = validate_strict(schema => $schema, args => $args3) }
		qr /Required parameter '.+' is missing/,
		'missing required parameter throws exception';

	$schema = {
		'number' => { 'type' => 'integer', 'memberof' => [998, 999, 1000] }
	};
	my $args4 = { number => 999 };
	ok defined validate_strict(schema => $schema, args => $args4, unknown_parameter_handler => 'die');
};

subtest "Invalid Inputs" => sub {
	my $schema = {
		username => { type => 'string', min => 3, max => 50, optional => 1 },
		age => { type => 'integer', min => 0, max => 150, optional => 1 },
		email => { type => 'string', matches => qr/^[^@]+@[^@]+\.[^@]+$/, optional => 1 },
		price => { type => 'number', min => 0, optional => 1 },
		quantity => { type => 'number', min => 1, optional => 1 },
		password => {
			type => 'string',
			min => 8,
			optional => 1,
			callback => sub {
				my $password = shift;
				return $password =~ m/[a-z]/ && $password =~ m/[A-Z]/ && $password =~ m/[0-9]/;
			},
		},
		name => { 'type' => 'string', optional => 1 }
	};

	my $args1 = { username => 'sh' };	# Too short
	my $validated_params1 = eval { validate_strict(schema => $schema, args => $args1) };
	like $@, qr/username/, "Short username should fail";

	my $args2 = { username => 'x' x 51 }; # Too long
	my $validated_params2 = eval { validate_strict(schema => $schema, args => $args2) };
	like $@, qr/username/, "Long username should fail";

	my $args3 = { age => -1 }; # Invalid age
	my $validated_params3 = eval { validate_strict(schema => $schema, args => $args3) };
	like $@, qr/age/, 'Invalid age should fail';

	my $args4 = { email => 'invalid_email' }; # Invalid email
	my $validated_params4 = eval { validate_strict(schema => $schema, args => $args4) };
	like $@, qr/email/, "Invalid email should fail";

	my $args5 = { price => -1 }; # Invalid price
	my $validated_params5 = eval { validate_strict(schema => $schema, args => $args5) };
	like $@, qr/price/, "Invalid price should fail";

	my $args6 = { quantity => '0' }; # Invalid quantity
	my $validated_params6 = eval { validate_strict(schema => $schema, args => $args6) };
	like $@, qr/quantity/, "Invalid quantity should fail";

	my $args7 = { password => 'password' }; # Invalid password
	my $validated_params7 = eval { validate_strict(schema => $schema, args => $args7) };
	like $@, qr/password/, 'Invalid password should fail';

	my $args8 = { name => { 'value' => 123 } }; # Invalid name (should be a simple string)
	my $validated_params8 = eval { validate_strict(schema => $schema, args => $args8) };
	like $@, qr/name/, 'Invalid name should fail';

	my $args9 = { unknown => 'val' }; # Unknown parameter
	my $validated_params9 = eval { validate_strict(schema => $schema, args => $args9, unknown_parameter_handler => 'die') };
	like $@, qr/unknown/, 'Unknown parameter should fail';

	my $args10 = { username => 'user', age => 25, unknown => 'val' }; # Unknown parameter and valid
	my $validated_params10 = eval { validate_strict(schema => $schema, args => $args10, unknown_parameter_handler => 'die') };
	like $@, qr/unknown/, 'Unknown parameter should fail with valid data';

	# Intentionally passing a hashref with an extra key "other"
	my $args11 = { value => 42, other => 'oops' };

	# Simulate passing a schema only for 'value'
	throws_ok( sub { validate_strict(schema => { type => 'integer' }, args => $args11) }, qr/Unknown parameter/, 'extra key rejection');

	my $args12 = { number => ['a'] };
	throws_ok {
		validate_strict(args => $args12, schema => { number => 'integer' });
	} qr/must be an integer/, 'Fails validation for non-scalar';

	my $args13 = { number => 997 };
	$schema = {
		'number' => { 'type' => 'integer', 'memberof' => [998, 999, 1000] }
	};
	throws_ok {
		validate_strict(args => $args13, schema => $schema, unknown_parameter_handler => 'die')
	} qr/must be one of/, 'memberof detects when a number is not in the list';

	$schema = {
		'number' => { 'type' => 'integer', 'min' => 1000, 'max' => 995 }
	};
	throws_ok {
		validate_strict(args => $args13, schema => $schema, unknown_parameter_handler => 'die')
	} qr/min must be <= max/, 'validate min and max in the schema';

	$schema = {
		'obj' => { 'type' => 'object', optional => 1, can => 'bar' }
	};
	my $args14 = { obj => new_ok('MyClass') };
	throws_ok {
		validate_strict(args => $args14, schema => $schema, unknown_parameter_handler => 'die')
	} qr/must be an object that understands the bar method/, 'validate min and max in the schema';
};

done_testing();
