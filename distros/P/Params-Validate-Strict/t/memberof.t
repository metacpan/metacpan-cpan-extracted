#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 47;

use Params::Validate::Strict qw(validate_strict);

# Basic string memberof (whitelist)
{
    my $schema = {
        status => {
            type => 'string',
            memberof => ['draft', 'published', 'archived']
        }
    };

    # Valid status
    my $result = validate_strict(
        schema => $schema,
        input => { status => 'published' }
    );
    ok(defined($result), 'Valid status in memberof passes');
    is($result->{status}, 'published', 'Status value preserved');

    # Invalid status (not in whitelist)
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'deleted' }
        );
    } qr/must be one of draft, published, archived/, 'Status not in memberof fails';
}

# Numeric memberof (integer)
{
    my $schema = {
        priority => {
            type => 'integer',
            memberof => [1, 2, 3, 4, 5]
        }
    };

    # Valid priority
    my $result = validate_strict(
        schema => $schema,
        input => { priority => 3 }
    );
    ok(defined($result), 'Valid priority in memberof passes');
    is($result->{priority}, 3, 'Priority value preserved');

    # Invalid priority
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { priority => 10 }
        );
    } qr/must be one of 1, 2, 3, 4, 5/, 'Priority not in memberof fails';
}

# Float/number memberof
{
    my $schema = {
        rating => {
            type => 'number',
            memberof => [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]
        }
    };

    # Valid rating
    my $result = validate_strict(
        schema => $schema,
        input => { rating => 2.5 }
    );
    ok(defined($result), 'Valid rating in memberof passes');
    is($result->{rating}, 2.5, 'Rating value preserved');

    # Invalid rating
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { rating => 4.0 }
        );
    } qr/must be one of/, 'Rating not in memberof fails';
}

# Case-sensitive string memberof (default behavior)
{
    my $schema = {
        code => {
            type => 'string',
            memberof => ['ABC', 'DEF', 'GHI']
        }
    };

    # Exact case match
    my $result = validate_strict(
        schema => $schema,
        input => { code => 'ABC' }
    );
    ok(defined($result), 'Exact case match passes');

    # Different case fails (case-sensitive by default)
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { code => 'abc' }
        );
    } qr/must be one of ABC, DEF, GHI/, 'Different case fails with default case-sensitive';
}

# Case-sensitive explicitly set to true
{
    my $schema = {
        code => {
            type => 'string',
            memberof => ['ABC', 'DEF', 'GHI'],
            case_sensitive => 1
        }
    };

    # Exact case match
    my $result = validate_strict(
        schema => $schema,
        input => { code => 'ABC' }
    );
    ok(defined($result), 'Exact case match with case_sensitive => 1 passes');

    # Different case fails
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { code => 'abc' }
        );
    } qr/must be one of ABC, DEF, GHI/, 'Different case fails with case_sensitive => 1';
}

# Case-insensitive memberof
{
    my $schema = {
        code => {
            type => 'string',
            memberof => ['ABC', 'DEF', 'GHI'],
            case_sensitive => 0
        }
    };

    # Lowercase input
    my $result = validate_strict(
        schema => $schema,
        input => { code => 'abc' }
    );
    ok(defined($result), 'Lowercase matches with case_sensitive => 0');
    is($result->{code}, 'abc', 'Original case preserved in output');

    # Uppercase input
    $result = validate_strict(
        schema => $schema,
        input => { code => 'DEF' }
    );
    ok(defined($result), 'Uppercase matches with case_sensitive => 0');

    # Mixed case input
    $result = validate_strict(
        schema => $schema,
        input => { code => 'GhI' }
    );
    ok(defined($result), 'Mixed case matches with case_sensitive => 0');

    # Still fails if not in list (case-insensitive)
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { code => 'xyz' }
        );
    } qr/must be one of ABC, DEF, GHI/, 'Non-member fails even with case_sensitive => 0';
}

# Case-insensitive with mixed case memberof list
{
    my $schema = {
        country => {
            type => 'string',
            memberof => ['US', 'uk', 'Canada', 'FRANCE'],
            case_sensitive => 0
        }
    };

    # Various case inputs
    my $result = validate_strict(
        schema => $schema,
        input => { country => 'us' }
    );
    ok(defined($result), 'us matches US case-insensitively');

    $result = validate_strict(
        schema => $schema,
        input => { country => 'UK' }
    );
    ok(defined($result), 'UK matches uk case-insensitively');

    $result = validate_strict(
        schema => $schema,
        input => { country => 'canada' }
    );
    ok(defined($result), 'canada matches Canada case-insensitively');

    $result = validate_strict(
        schema => $schema,
        input => { country => 'france' }
    );
    ok(defined($result), 'france matches FRANCE case-insensitively');
}

# Optional field with memberof
{
    my $schema = {
        role => {
            type => 'string',
            memberof => ['admin', 'user', 'guest'],
            optional => 1
        }
    };

    # Optional field not provided
    my $result = validate_strict(
        schema => $schema,
        input => {}
    );
    ok(defined($result), 'Optional memberof field can be omitted');

    # Optional field provided and valid
    $result = validate_strict(
        schema => $schema,
        input => { role => 'user' }
    );
    ok(defined($result), 'Optional memberof field with valid value passes');

    # Optional field provided but invalid
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { role => 'superuser' }
        );
    } qr/must be one of admin, user, guest/, 'Optional memberof field still validated';
}

# Custom error message with memberof
{
    my $schema = {
        status => {
            type => 'string',
            memberof => ['active', 'inactive'],
            error_msg => 'Status must be either active or inactive'
        }
    };

    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'pending' }
        );
    } qr/Status must be either active or inactive/, 'Custom error message shown for memberof';
}

# Empty memberof array
{
    my $schema = {
        value => {
            type => 'string',
            memberof => []  # Empty whitelist - nothing allowed
        }
    };

    throws_ok {
        validate_strict(
            schema => $schema,
            input => { value => 'anything' }
        );
    } qr/must be one of/, 'Empty memberof rejects all values';
}

# Single item memberof
{
    my $schema = {
        mode => {
            type => 'string',
            memberof => ['production']  # Only one allowed value
        }
    };

    # Valid mode
    my $result = validate_strict(
        schema => $schema,
        input => { mode => 'production' }
    );
    ok(defined($result), 'Single memberof value passes');

    # Invalid mode
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { mode => 'development' }
        );
    } qr/must be one of production/, 'Non-member of single-item list fails';
}

# memberof with transformed values
{
    my $schema = {
        status => {
            type => 'string',
            transform => sub { lc($_[0]) },
            memberof => ['draft', 'published', 'archived']
        }
    };

    # Uppercase input gets transformed and then checked
    my $result = validate_strict(
        schema => $schema,
        input => { status => 'PUBLISHED' }
    );
    ok(defined($result), 'Transformed value checked against memberof');
    is($result->{status}, 'published', 'Transform applied before memberof check');

    # Invalid after transform
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'DELETED' }
        );
    } qr/must be one of draft, published, archived/, 'Transformed invalid value still fails';
}

# memberof with custom types
{
    my $custom_types = {
        post_status => {
            type => 'string',
            memberof => ['draft', 'published', 'archived', 'scheduled']
        }
    };

    my $schema = {
        status => { type => 'post_status' }
    };

    # Valid status
    my $result = validate_strict(
        schema => $schema,
        input => { status => 'scheduled' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Custom type with memberof passes');

    # Invalid status
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'deleted' },
            custom_types => $custom_types
        );
    } qr/must be one of draft, published, archived, scheduled/, 'Custom type memberof enforced';
}

# Case-insensitive with custom types
{
    my $custom_types = {
        language_code => {
            type => 'string',
            memberof => ['EN', 'FR', 'DE', 'ES'],
            case_sensitive => 0
        }
    };

    my $schema = {
        language => { type => 'language_code' }
    };

    # Lowercase input
    my $result = validate_strict(
        schema => $schema,
        input => { language => 'en' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Custom type with case_sensitive => 0 passes');
    is($result->{language}, 'en', 'Original case preserved');

    # Mixed case input
    $result = validate_strict(
        schema => $schema,
        input => { language => 'Fr' },
        custom_types => $custom_types
    );
    ok(defined($result), 'Mixed case with custom type passes');
}

# Invalid memberof value (not an array)
{
    my $schema = {
        status => {
            type => 'string',
            memberof => 'draft'  # Should be arrayref
        }
    };

    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'draft' }
        );
    } qr/must be an array reference/, 'memberof requires array reference';
}

# Numeric memberof doesn't use case_sensitive
{
    my $schema = {
        priority => {
            type => 'integer',
            memberof => [1, 2, 3],
            case_sensitive => 0  # Should be ignored for numbers
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { priority => 2 }
    );
    ok(defined($result), 'Numeric memberof ignores case_sensitive flag');
    is($result->{priority}, 2, 'Numeric value preserved');
}

# Case-insensitive memberof with special characters
{
    my $schema = {
        category => {
            type => 'string',
            memberof => ['How-To', 'Q&A', 'News'],
            case_sensitive => 0
        }
    };

    # Lowercase with special chars
    my $result = validate_strict(
        schema => $schema,
        input => { category => 'how-to' }
    );
    ok(defined($result), 'Case-insensitive with special characters passes');

    $result = validate_strict(
        schema => $schema,
        input => { category => 'q&a' }
    );
    ok(defined($result), 'Case-insensitive with ampersand passes');
}

# Large memberof list
{
    my @valid_codes = map { sprintf("CODE%03d", $_) } (1..100);

    my $schema = {
        code => {
            type => 'string',
            memberof => \@valid_codes
        }
    };

    # Valid code
    my $result = validate_strict(
        schema => $schema,
        input => { code => 'CODE050' }
    );
    ok(defined($result), 'Large memberof list works');

    # Invalid code
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { code => 'CODE999' }
        );
    } qr/must be one of/, 'Invalid value in large memberof list fails';
}

# memberof with min/max should conflict
{
    my $schema = {
        status => {
            type => 'string',
            memberof => ['draft', 'published'],
            min => 3  # This makes no sense with memberof
        }
    };

    # Should error about conflicting rules
    throws_ok {
        validate_strict(
            schema => $schema,
            input => { status => 'draft' }
        );
    } qr/min.*makes no sense with memberof/, 'memberof conflicts with min';
}

# Case-insensitive with whitespace in values
{
    my $schema = {
        title => {
            type => 'string',
            enum => ['Mr', 'Mrs', 'Ms', 'Dr'],
            case_sensitive => 0
        }
    };

    my $result = validate_strict(
        schema => $schema,
        input => { title => 'dr' }
    );
    ok(defined($result), 'Case-insensitive simple values pass');
    is($result->{title}, 'dr', 'Original case preserved');
}

done_testing();
