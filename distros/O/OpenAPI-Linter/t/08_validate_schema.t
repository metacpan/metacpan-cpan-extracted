#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

# Suppress JSON::Validator warnings about missing format rules
# These are informational and don't affect validation
BEGIN {
    $SIG{__WARN__} = sub {
        my $warning = shift;
        warn $warning unless $warning =~ /Format rule for .* is missing/;
    };
}

# Test: Valid OpenAPI 3.0.3 spec
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Valid API',
            version => '1.0.0',
        },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec, version => '3.0.3');
    my @errors = $linter->validate_schema();

    is(scalar(@errors), 0, 'Valid 3.0.3 spec passes validation')
        or diag(explain(\@errors));
}

# Test: Valid OpenAPI 3.1.0 spec
{
    my $spec = {
        openapi => '3.1.0',
        info => {
            title => 'Valid API',
            version => '1.0.0',
        },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec, version => '3.1.0');
    my @errors = $linter->validate_schema();

    is(scalar(@errors), 0, 'Valid 3.1.0 spec passes validation')
        or diag(explain(\@errors));
}

# Test: Invalid spec - missing required fields
{
    my $spec = {
        openapi => '3.0.3',
        # Missing info
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();

    ok(scalar(@errors) > 0, 'Invalid spec returns validation errors');

    # Check that error mentions 'info'
    my $error_str = join(' ', map { $_->{message} // $_->{path} // $_ } @errors);
    like($error_str, qr/info/i, 'Error mentions missing info field');
}

# Test: Invalid spec - wrong openapi version format
{
    my $spec = {
        openapi => '3',  # Should be '3.0.3' or similar
        info => {
            title => 'Test',
            version => '1.0.0',
        },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();

    ok(scalar(@errors) > 0, 'Invalid openapi version format returns errors');
}

# Test: Invalid spec - wrong info.version type
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test',
            version => 123,  # Should be string
        },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();

    ok(scalar(@errors) > 0, 'Invalid info.version type returns errors');
}

# Test: Complete valid spec with paths and components
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Complete API',
            version => '1.0.0',
            description => 'A complete API',
        },
        paths => {
            '/users' => {
                get => {
                    summary => 'Get users',
                    responses => {
                        '200' => {
                            description => 'Success',
                            content => {
                                'application/json' => {
                                    schema => {
                                        type => 'array',
                                        items => {
                                            '$ref' => '#/components/schemas/User',
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
        components => {
            schemas => {
                User => {
                    type => 'object',
                    required => ['id', 'name'],
                    properties => {
                        id => {
                            type => 'integer',
                            format => 'int64',
                        },
                        name => {
                            type => 'string',
                        },
                    },
                },
            },
        },
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();

    is(scalar(@errors), 0, 'Complex valid spec passes validation')
        or diag(explain(\@errors));
}

# Test: Invalid path - missing required operation fields
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test',
            version => '1.0.0',
        },
        paths => {
            '/test' => {
                get => {
                    # Missing responses (required)
                },
            },
        },
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();

    ok(scalar(@errors) > 0, 'Missing required responses field returns errors');
}

# Test: Schema validation uses correct version URL
{
    # Test all 3.0.x versions
    for my $version (qw(3.0.0 3.0.1 3.0.2 3.0.3)) {
        my $spec = {
            openapi => $version,
            info => {
                title => 'Test API',
                version => '1.0.0',
            },
            paths => {},
        };

        my $linter = OpenAPI::Linter->new(spec => $spec, version => $version);
        my @errors = $linter->validate_schema();
        is(scalar(@errors), 0, "$version spec validates correctly")
            or diag("Errors for $version: ", explain(\@errors));
    }

    # Test all 3.1.x versions
    for my $version (qw(3.1.0 3.1.1)) {
        my $spec = {
            openapi => $version,
            info => {
                title => 'Test API',
                version => '1.0.0',
            },
            paths => {},
        };

        my $linter = OpenAPI::Linter->new(spec => $spec, version => $version);
        my @errors = $linter->validate_schema();
        is(scalar(@errors), 0, "$version spec validates correctly")
            or diag("Errors for $version: ", explain(\@errors));
    }
}

# Test: Unsupported version handling
{
    my $spec = {
        openapi => '2.0',
        info => {
            title => 'Test',
            version => '1.0.0',
        },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec, version => '2.0');

    eval { $linter->validate_schema() };
    like($@, qr/Unsupported OpenAPI version/,
         'Dies with clear error for unsupported version');
}

# Test: Return value is array in list context
{
    my $spec = {
        openapi => '3.0.3',
        info => { title => 'Test', version => '1.0' },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();

    ok(ref(\@errors) eq 'ARRAY', 'Returns array in list context');
}

# Test: Combining lint and validate_schema
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test',
            version => '1.0.0',
            # Missing description - lint warning, but valid schema
        },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);

    # Lint checks for best practices
    my @lint_issues = $linter->find_issues(level => 'WARN');
    ok(scalar(@lint_issues) > 0, 'Lint finds warnings');

    # Schema validation checks structural validity
    my @schema_errors = $linter->validate_schema();
    is(scalar(@schema_errors), 0, 'But schema validation passes');
}

done_testing;
