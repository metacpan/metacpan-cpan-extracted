#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

# Test 1: Parameter with 'path' in 'in' field should be valid
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/users/{id}' => {
                get => {
                    parameters => [
                        {
                            name => 'id',
                            in => 'path',
                            required => 1,  # Boolean true
                            schema => { type => 'string' }
                        }
                    ],
                    responses => {
                        '200' => {
                            description => 'Success'
                        }
                    }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema;

    # Filter to only 'in' related errors
    my @in_errors = grep { $_->{message} =~ /\/in:/i } @errors;

    is(scalar(@in_errors), 0,
        "Parameter with 'in' => 'path' should not produce validation errors");

    if (@in_errors) {
        diag "Unexpected 'in' errors found:";
        diag "  - " . $_->{message} for @in_errors;
    }
}

# Test 2: Parameter with boolean 'required' should be valid
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/users' => {
                get => {
                    parameters => [
                        {
                            name => 'limit',
                            in => 'query',
                            required => 1,  # Boolean true (will be coerced)
                            schema => { type => 'integer' }
                        }
                    ],
                    responses => {
                        '200' => {
                            description => 'Success'
                        }
                    }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema;

    # Filter to only 'required' related errors
    my @required_errors = grep {
        $_->{message} =~ /\/required:/i && $_->{message} =~ /enum/i
    } @errors;

    is(scalar(@required_errors), 0,
        "Parameter with boolean 'required' should not produce enum errors");

    if (@required_errors) {
        diag "Unexpected 'required' errors found:";
        diag "  - " . $_->{message} for @required_errors;
    }
}

# Test 3: All valid 'in' values should work
{
    my @valid_in_values = qw(path query header cookie);

    foreach my $in_value (@valid_in_values) {
        my $spec = {
            openapi => '3.0.3',
            info => {
                title => 'Test API',
                version => '1.0.0',
            },
            paths => {
                '/test' => {
                    get => {
                        parameters => [
                            {
                                name => 'test_param',
                                in => $in_value,
                                schema => { type => 'string' }
                            }
                        ],
                        responses => {
                            '200' => {
                                description => 'Success'
                            }
                        }
                    }
                }
            }
        };

        my $linter = OpenAPI::Linter->new(spec => $spec);
        my @errors = $linter->validate_schema;

        my @in_errors = grep {
            $_->{message} =~ /\/in:/i && $_->{message} =~ /enum/i
        } @errors;

        is(scalar(@in_errors), 0,
            "Parameter with 'in' => '$in_value' should be valid");
    }
}

# Test 4: Inline parameter (no $ref) should be valid
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/items' => {
                get => {
                    parameters => [
                        {
                            name => 'filter',
                            in => 'query',
                            description => 'Filter items',
                            schema => {
                                type => 'string',
                                enum => ['active', 'inactive']
                            }
                        }
                    ],
                    responses => {
                        '200' => {
                            description => 'Success'
                        }
                    }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema;

    my @ref_errors = grep {
        $_->{message} =~ /\$ref/i && $_->{message} =~ /missing/i
    } @errors;

    is(scalar(@ref_errors), 0,
        "Inline parameter without \$ref should not require \$ref");

    if (@ref_errors) {
        diag "Unexpected \$ref errors found:";
        diag "  - " . $_->{message} for @ref_errors;
    }
}

# Test 5: Complete valid spec should pass validation
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Complete Test API',
            version => '1.0.0',
            description => 'A test API'
        },
        paths => {
            '/users/{userId}' => {
                get => {
                    summary => 'Get user by ID',
                    parameters => [
                        {
                            name => 'userId',
                            in => 'path',
                            required => 1,
                            schema => { type => 'string' }
                        },
                        {
                            name => 'expand',
                            in => 'query',
                            required => 0,
                            schema => { type => 'boolean' }
                        }
                    ],
                    responses => {
                        '200' => {
                            description => 'User found',
                            content => {
                                'application/json' => {
                                    schema => {
                                        type => 'object',
                                        properties => {
                                            id => { type => 'string' },
                                            name => { type => 'string' }
                                        }
                                    }
                                }
                            }
                        },
                        '404' => {
                            description => 'User not found'
                        }
                    }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema;

    is(scalar(@errors), 0,
        "Complete valid OpenAPI spec should pass validation without errors");

    if (@errors) {
        diag "Unexpected validation errors:";
        diag "  - " . $_->{message} for @errors;
    }
}

done_testing;
