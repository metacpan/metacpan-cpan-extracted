#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 15;

use Params::Validate::Strict qw(validate_strict);

# Basic conditional min with country-based drinking age
{
    my $schema = {
        country => { type => 'string' },
        age => {
            type => 'integer',
            min => sub {
                my ($value, $all_params) = @_;
                return $all_params->{country} eq 'US' ? 21 : 18;
            }
        }
    };

    # Should pass - US citizen age 21
    my $result = validate_strict(
        schema => $schema,
        input => { country => 'US', age => 21 }
    );
    ok(defined($result), 'US age 21 passes');
    is($result->{age}, 21, 'Age value preserved');

    # Should pass - UK citizen age 18
    $result = validate_strict(
        schema => $schema,
        input => { country => 'UK', age => 18 }
    );
    ok(defined($result), 'UK age 18 passes');

    # Should fail - US citizen age 20
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { country => 'US', age => 20 }
        );
    } qr/must be at least 21/, 'US age 20 fails with correct error';

    # Should fail - UK citizen age 17
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { country => 'UK', age => 17 }
        );
    } qr/must be at least 18/, 'UK age 17 fails';
}

# Conditional max based on account type
{
    my $schema = {
        account_type => { type => 'string', memberof => ['free', 'premium'] },
        storage_gb => {
            type => 'integer',
            min => 1,
            max => sub {
                my ($value, $all_params) = @_;
                return $all_params->{account_type} eq 'premium' ? 1000 : 10;
            }
        }
    };

    # Free account with 5GB - should pass
    my $result = validate_strict(
        schema => $schema,
        input => { account_type => 'free', storage_gb => 5 }
    );
    ok(defined($result), 'Free account 5GB passes');

    # Premium account with 500GB - should pass
    $result = validate_strict(
        schema => $schema,
        input => { account_type => 'premium', storage_gb => 500 }
    );
    ok(defined($result), 'Premium account 500GB passes');

    # Free account with 20GB - should fail
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { account_type => 'free', storage_gb => 20 }
        );
    } qr/must be no more than 10/, 'Free account exceeds limit';
}

# Conditional required field (required_if)
{
    my $schema = {
        has_license => { type => 'boolean' },
        license_number => {
            type => 'string',
            optional => sub {
                my ($value, $all_params) = @_;
                return !$all_params->{has_license};  # Optional if no license
            }
        }
    };

    # Has license, provides number - should pass
    my $result = validate_strict(
        schema => $schema,
        input => { has_license => 1, license_number => 'DL123456' }
    );
    ok(defined($result), 'License provided when required');

    # No license, no number - should pass
    $result = validate_strict(
        schema => $schema,
        input => { has_license => 0 }
    );
    ok(defined($result), 'No license number when not required');

    # Has license, no number - should fail
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { has_license => 1 }
        );
    } qr/Required parameter 'license_number' is missing/, 'License required but missing';
}

# Conditional matches pattern
{
    my $schema = {
        input_type => { type => 'string', memberof => ['email', 'phone'] },
        contact => {
            type => 'string',
            matches => sub {
                my ($value, $all_params) = @_;
                if ($all_params->{input_type} eq 'email') {
                    return qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/;
                } else {
                    return qr/^\d{3}-\d{3}-\d{4}$/;
                }
            }
        }
    };

    # Valid email
    my $result = validate_strict(
        schema => $schema,
        input => { input_type => 'email', contact => 'test@example.com' }
    );
    ok(defined($result), 'Valid email passes');

    # Valid phone
    $result = validate_strict(
        schema => $schema,
        input => { input_type => 'phone', contact => '555-123-4567' }
    );
    ok(defined($result), 'Valid phone passes');

    # Invalid email format
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { input_type => 'email', contact => 'not-an-email' }
        );
    } qr/must match pattern/, 'Invalid email fails';
}

# Complex conditional with multiple dependencies
{
    my $schema = {
        shipping_method => { type => 'string', memberof => ['standard', 'express', 'overnight'] },
        country => { type => 'string' },
        shipping_cost => {
            type => 'number',
            min => sub {
                my ($value, $all_params) = @_;
                my $method = $all_params->{shipping_method};
                my $country = $all_params->{country};

                return 0 if $method eq 'standard';
                return $country eq 'US' ? 10 : 25 if $method eq 'express';
                return $country eq 'US' ? 25 : 50 if $method eq 'overnight';
                return 0;
            }
        }
    };

    # Express shipping US with $15 - should pass
    my $result = validate_strict(
        schema => $schema,
        input => {
            shipping_method => 'express',
            country => 'US',
            shipping_cost => 15
        }
    );
    ok(defined($result), 'US express shipping with valid cost');
}

done_testing();
