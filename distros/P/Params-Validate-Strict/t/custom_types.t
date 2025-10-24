#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 26;

use Params::Validate::Strict qw(validate_strict);

# Basic custom type - email
{
    my $custom_types = {
        email => {
            type => 'string',
            matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/
        }
    };

    my $schema = {
        user_email => { type => 'email' }
    };

    # Valid email
    my $result = validate_strict(
        schema => $schema,
        input => { user_email => 'test@example.com' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Valid email passes');
    is($result->{user_email}, 'test@example.com', 'Email value preserved');

    # Invalid email
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { user_email => 'not-an-email' },
            custom_types => $custom_types
        );
    } qr/must match pattern/, 'Invalid email fails';
}

# Custom type with min/max constraints - phone
{
    my $custom_types = {
        phone => {
            type => 'string',
            matches => qr/^\+?[1-9]\d{1,14}$/,
            min => 10,
            max => 15
        }
    };

    my $schema = {
        contact_number => { type => 'phone' }
    };

    # Valid phone
    my $result = validate_strict(
        schema => $schema,
        input => { contact_number => '+12345678901' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Valid phone passes');

    # Too short
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { contact_number => '123' },
            custom_types => $custom_types
        );
    } qr/too short/, 'Phone too short fails';

    # Invalid format
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { contact_number => 'abc1234567' },
            custom_types => $custom_types
        );
    } qr/must match pattern/, 'Invalid phone format fails';
}

# Multiple custom types in one schema
{
    my $custom_types = {
        email => {
            type => 'string',
            matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/
        },
        zipcode => {
            type => 'string',
            matches => qr/^\d{5}(-\d{4})?$/
        },
        username => {
            type => 'string',
            matches => qr/^[a-z0-9_]{3,20}$/,
            min => 3,
            max => 20
        }
    };

    my $schema = {
        email => { type => 'email' },
        zip => { type => 'zipcode' },
        username => { type => 'username' }
    };

    # All valid
    my $result = validate_strict(
        schema => $schema,
        input => {
            email => 'user@test.com',
            zip => '12345',
            username => 'john_doe'
        },
        custom_types => $custom_types
    );
    ok(defined($result), 'Multiple custom types all valid');

    # Invalid username
    throws_ok {
        validate_strict(
            schema => $schema,
            input => {
                email => 'user@test.com',
                zip => '12345',
                username => 'John-Doe'  # capitals and dash not allowed
            },
            custom_types => $custom_types
        );
    } qr/must match pattern/, 'Invalid username in multi-type schema';
}

# Custom type with optional field
{
    my $custom_types = {
        url => {
            type => 'string',
            matches => qr/^https?:\/\/[\w\.\-]+/
        }
    };

    my $schema = {
        website => { type => 'url', optional => 1 }
    };

    # Optional field provided and valid
    my $result = validate_strict(
        schema => $schema,
        input => { website => 'https://example.com' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Optional custom type when provided');

    # Optional field not provided
    $result = validate_strict(
        schema => $schema,
        input => {},
        custom_types => $custom_types
    );
    ok(defined($result), 'Optional custom type when omitted');

    # Optional field provided but invalid
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { website => 'not a url' },
            custom_types => $custom_types
        );
    } qr/must match pattern/, 'Invalid optional custom type fails';
}

# Custom type extending base type with memberof
{
    my $custom_types = {
        status => {
            type => 'string',
            memberof => ['draft', 'published', 'archived']
        }
    };

    my $schema = {
        post_status => { type => 'status' }
    };

    # Valid status
    my $result = validate_strict(
        schema => $schema,
        input => { post_status => 'published' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Valid enum-like custom type');

    # Invalid status
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { post_status => 'deleted' },
            custom_types => $custom_types
        );
    } qr/must be one of/, 'Invalid enum value fails';
}

# Custom numeric type with range
{
    my $custom_types = {
        percentage => {
            type => 'number',
            min => 0,
            max => 100
        },
        age => {
            type => 'integer',
            min => 0,
            max => 150
        }
    };

    my $schema = {
        completion => { type => 'percentage' },
        user_age => { type => 'age' }
    };

    # Valid values
    my $result = validate_strict(
        schema => $schema,
        input => { completion => 75.5, user_age => 30 },
        custom_types => $custom_types
    );
    ok(defined($result), 'Valid numeric custom types');
    is($result->{completion}, 75.5, 'Percentage preserved');
    is($result->{user_age}, 30, 'Age preserved');

    # Percentage out of range
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { completion => 150, user_age => 30 },
            custom_types => $custom_types
        );
    } qr/must be no more than 100/, 'Percentage exceeds max';

    # Age out of range
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { completion => 75, user_age => 200 },
            custom_types => $custom_types
        );
    } qr/must be no more than 150/, 'Age exceeds max';
}

# Custom type with arrayref
{
    my $custom_types = {
        tag_list => {
            type => 'arrayref',
            element_type => 'string',
            min => 1,
            max => 10
        }
    };

    my $schema = {
        tags => { type => 'tag_list' }
    };

    # Valid tag list
    my $result = validate_strict(
        schema => $schema,
        input => { tags => ['perl', 'validation', 'testing'] },
        custom_types => $custom_types
    );
    ok(defined($result), 'Valid arrayref custom type');
    is(scalar(@{$result->{tags}}), 3, 'Correct number of tags');

    # Too many tags
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { tags => [1..11] },
            custom_types => $custom_types
        );
    } qr/must contain no more than 10/, 'Too many array elements';

    # Empty array
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { tags => [] },
            custom_types => $custom_types
        );
    } qr/must be at least length 1/, 'Empty array fails min constraint';
}

# Overriding custom type constraints in schema
{
    my $custom_types = {
        username => {
            type => 'string',
            matches => qr/^[a-z0-9_]+$/,
            min => 3,
            max => 20
        }
    };

    my $schema = {
        admin_username => {
            type => 'username',
            min => 5,  # Override the custom type's min
            max => 15  # Override the custom type's max
        }
    };

    # Length 6 - passes both
    my $result = validate_strict(
        schema => $schema,
        input => { admin_username => 'john_d' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Valid with overridden constraints');
}

# Custom type with callback validation
{
    my $custom_types = {
        even_number => {
            type => 'integer',
            callback => sub {
                my $value = shift;
                return $value % 2 == 0;
            }
        }
    };

    my $schema = {
        quantity => { type => 'even_number' }
    };

    # Even number
    my $result = validate_strict(
        schema => $schema,
        input => { quantity => 10 },
        custom_types => $custom_types
    );
    ok(defined($result), 'Valid even number passes');

    # Odd number
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { quantity => 9 },
            custom_types => $custom_types
        );
    } qr/failed custom validation/, 'Odd number fails callback';
}

# Custom type with error_message
{
    my $custom_types = {
        strong_password => {
            type => 'string',
            min => 8,
            matches => qr/^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[\@$!%*?&])/,
            error_message => 'Password must be at least 8 characters with uppercase, lowercase, number, and special character'
        }
    };

    my $schema = {
        password => { type => 'strong_password' }
    };

    # Weak password
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { password => 'weak' },
            custom_types => $custom_types
        );
    } qr/Password must be at least 8 characters/, 'Custom error message shown';
}

# Nested custom types (custom type within arrayref/hashref)
# TODO: This functionality is not implemented
if(0) {
    my $custom_types = {
        email => {
            type => 'string',
            matches => qr/^[\w\.\-]+@[\w\.\-]+\.\w+$/
        }
    };

    my $schema = {
        contacts => {
            type => 'arrayref',
            schema => {
                name => { type => 'string' },
                email => { type => 'email' }
            }
        }
    };

    # Valid nested custom type
    my $result = validate_strict(
        schema => $schema,
        input => {
            contacts => [
                { name => 'John', email => 'john@test.com' },
                { name => 'Jane', email => 'jane@test.com' }
            ]
        },
        custom_types => $custom_types
    );
    ok(defined($result), 'Custom type in nested schema');

    # Invalid nested custom type
    throws_ok {
        validate_strict(
            schema => $schema,
            input => {
                contacts => [
                    { name => 'John', email => 'not-an-email' }
                ]
            },
            custom_types => $custom_types
        );
    } qr/must match pattern/, 'Invalid custom type in nested schema fails';
}

done_testing();
