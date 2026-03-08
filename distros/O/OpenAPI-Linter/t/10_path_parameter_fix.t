#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('OpenAPI::Linter'); }

# Test 1: Valid path parameter should not generate errors (3.1.0)
{
    my $spec = {
        openapi => '3.1.0',
        info    => {
            title       => 'Test API',
            version     => '1.0.0',
            description => 'Test API',
            license     => { name => 'MIT' },
        },
        servers => [
            { url => 'https://api.example.com/v1' }
        ],
        security => [{ apiKey => [] }],
        paths    => {
            '/{id}/items' => {
                parameters => [
                    { '$ref' => '#/components/parameters/id' }
                ],
                get => {
                    operationId => 'getItems',
                    security    => [{ apiKey => [] }],
                    responses   => {
                        '200' => {
                            description => 'Success',
                            content => {
                                'application/json' => {
                                    schema => { type => 'object' }
                                }
                            }
                        }
                    }
                }
            }
        },
        components => {
            securitySchemes => {
                apiKey => {
                    type => 'apiKey',
                    name => 'X-API-Key',
                    'in' => 'header',
                }
            },
            parameters => {
                id => {
                    name     => 'id',
                    in       => 'path',
                    required => 1,
                    schema   => { type => 'string' }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'Path parameter with in: path should validate successfully');
}

# Test 2: Boolean true for required field should not generate errors (3.1.0)
{
    my $spec = {
        openapi => '3.1.0',  # CHANGED from 3.0.3 to 3.1.0
        info    => {
            title       => 'Test API',
            version     => '1.0.0',
            description => 'Test API',
            license     => { name => 'MIT' },
        },
        servers => [
            { url => 'https://api.example.com/v1' }
        ],
        security => [{ apiKey => [] }],
        paths => {
            '/test' => {
                get => {
                    summary     => 'Test operation',
                    operationId => 'getTest',
                    security    => [{ apiKey => [] }],
                    parameters  => [
                        {
                            name        => 'param',
                            in          => 'query',
                            required    => 1,
                            schema      => { type => 'string' },
                            description => 'Test parameter',
                        }
                    ],
                    responses => {
                        '200' => {
                            description => 'Success',
                            content => {
                                'application/json' => {
                                    schema => { type => 'object' }
                                }
                            }
                        }
                    }
                }
            }
        },
        components => {
            securitySchemes => {
                apiKey => {
                    type => 'apiKey',
                    name => 'X-API-Key',
                    'in' => 'header',
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'Boolean true for required field should validate successfully');
}

# Test 3: All parameter location types should be valid (3.1.0)
{
    my @locations = qw(path query header cookie);

    for my $location (@locations) {
        my $spec = {
            openapi => '3.1.0',  # CHANGED from 3.0.3 to 3.1.0
            info => {
                title       => 'Test API',
                version     => '1.0.0',
                description => 'Test API',
                license     => { name => 'MIT' },
            },
            servers => [
                { url => 'https://api.example.com/v1' }
            ],
            security => [{ apiKey => [] }],
            paths => {
                ($location eq 'path' ? '/{testParam}' : '/test') => {
                    get => {
                        summary     => 'Test operation',
                        operationId => 'getTest',
                        security    => [{ apiKey => [] }],
                        parameters  => [
                            {
                                name        => 'testParam',
                                in          => $location,
                                required    => ($location eq 'path' ? 1 : 0),
                                schema      => { type => 'string' },
                                description => 'Test parameter',
                            }
                        ],
                        responses => {
                            '200' => {
                                description => 'Success',
                                content => {
                                    'application/json' => {
                                        schema => { type => 'object' }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            components => {
                securitySchemes => {
                    apiKey => {
                        type => 'apiKey',
                        name => 'X-API-Key',
                        'in' => 'header',
                    }
                }
            }
        };

        my $linter = OpenAPI::Linter->new(spec => $spec);
        my @errors = $linter->validate_schema();
        is(scalar(@errors), 0, "Parameter location '$location' should validate successfully");
    }
}

# Test 4: Inline parameter definition without $ref should not generate missing $ref error (3.1.0)
{
    my $spec = {
        openapi => '3.1.0',
        info => {
            title   => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/{id}' => {
                parameters => [
                    {
                        name     => 'id',
                        in       => 'path',
                        required => 1,
                        schema   => { type => 'string' }
                    }
                ],
                get => {
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
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'Inline parameter definition should not generate missing $ref error');
}

# Test 5: Invalid spec should still generate errors (3.0.3) - KEEP THIS ONE AS 3.0.3
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title   => 'Test API',
            version => 123,  # Should be string, not number
        },
        paths => {}
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();
    ok(scalar(@errors) > 0, 'Invalid type should still generate validation errors');
}

# Test 6: Complete valid spec from the issue report (3.1.0)
{
    my $spec = {
        openapi => '3.1.0',
        info => {
            description => 'Test API',
            version     => '1.0.0',
            title       => 'Test API',
            contact     => {
                email => 'nobody@example.com'
            },
            license => {
                name => 'MIT',
                url  => 'https://opensource.org/licenses/MIT'
            }
        },
        servers => [
            {
                url => 'https://www.example.com/v1',
                variables => {
                    scheme => {
                        description => 'The Test REST API is only accessible via https',
                        enum        => ['https'],
                        default     => 'https'
                    }
                }
            }
        ],
        security => [
            { basic_auth => [] }
        ],
        paths => {
            '/{source}/search' => {
                parameters => [
                    { '$ref' => '#/components/parameters/source' }
                ],
                get => {
                    operationId => 'search',
                    description => 'Search the database.',
                    responses => {
                        '200' => {
                            '$ref' => '#/components/responses/success'
                        }
                    }
                }
            }
        },
        components => {
            parameters => {
                source => {
                    name        => 'source',
                    in          => 'path',
                    description => 'The source of the test object.',
                    required    => 1,
                    schema      => {
                        default => 'test',
                        type    => 'string',
                        enum    => ['test']
                    }
                }
            },
            responses => {
                success => {
                    description => 'Successful response',
                    content     => {
                        'text/plain' => {
                            schema   => {
                                type    => 'string',
                                example => 'Hello'
                            }
                        }
                    }
                }
            },
            securitySchemes => {
                basic_auth => {
                    type        => 'http',
                    scheme      => 'basic',
                    description => 'Basic auth'
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'Complete valid OpenAPI spec from issue report should validate successfully');
}

# Test 7: Verify false positive filtering doesn't hide real errors (3.0.3)
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title       => 'Test API',
            version     => '1.0.0',
            description => 'Test API',
            license     => { name => 'MIT' },
        },
        servers => [
            { url => 'https://api.example.com/v1' }
        ],
        # Intentionally missing security - this is invalid for 3.0.3
        paths => {
            '/test' => {
                get => {
                    summary     => 'Test operation',
                    operationId => 'getTest',
                    # Missing security
                    parameters  => [
                        {
                            name        => 'param',
                            in          => 'invalid_location',
                            schema      => { type => 'string' },
                            description => 'Test parameter',
                        }
                    ],
                    responses => {
                        '200' => {
                            description => 'Success',
                            content => {
                                'application/json' => {
                                    schema => { type => 'object' }
                                }
                            }
                        }
                    }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();
    ok(scalar(@errors) > 0, 'Real validation errors should not be filtered out');
}

# Test 8: Mixed valid and invalid parameters (3.0.3)
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title       => 'Test API',
            version     => '1.0.0',
            description => 'Test API',
            license     => { name => 'MIT' },
        },
        servers => [
            { url => 'https://api.example.com/v1' }
        ],
        # Intentionally missing security - this is invalid for 3.0.3
        paths => {
            '/{id}' => {
                get => {
                    summary     => 'Get user',
                    operationId => 'getUser',
                    # Missing security
                    parameters  => [
                        {
                            name        => 'id',
                            in          => 'path',
                            required    => 1,
                            schema      => { type => 'string' },
                            description => 'User ID',
                        },
                        {
                            name => 'filter',
                            in   => 'query',
                            # Missing schema - this is an error
                        }
                    ],
                    responses => {
                        '200' => {
                            description => 'Success',
                            content => {
                                'application/json' => {
                                    schema => { type => 'object' }
                                }
                            }
                        }
                    }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();
    ok(scalar(@errors) > 0, 'Missing required schema should generate error');

    my $has_path_enum_error = grep {
        $_->{message} =~ m{/in:.*Not in enum list}i
    } @errors;
    is($has_path_enum_error, 0, 'Path parameter should not generate enum errors');
}

# Test 9: Test with OpenAPI 3.1.0
{
    my $spec = {
        openapi => '3.1.0',
        info => {
            title   => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/{id}' => {
                parameters => [
                    {
                        name     => 'id',
                        in       => 'path',
                        required => 1,
                        schema   => { type => 'string' }
                    }
                ],
                get => {
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
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'OpenAPI 3.1.0 spec with path parameter should validate successfully');
}

# Test 10: Verify JSON::Validator success indicator (0) is handled correctly (3.1.0)
{
    my $spec = {
        openapi => '3.1.0',
        info => {
            title   => 'Minimal Valid API',
            version => '1.0.0',
        },
        paths => {}
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'Minimal valid spec should return empty list, not (0)');
    ok(!grep({ !ref($_) && $_ eq '0' } @errors), 'Result should not contain scalar 0');
}

# Test 11: Cookie parameter location (3.1.0)
{
    my $spec = {
        openapi => '3.1.0',
        info => {
            title   => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/test' => {
                get => {
                    parameters => [
                        {
                            name   => 'sessionId',
                            in     => 'cookie',
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
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'Cookie parameter location should validate successfully');
}

# Test 12: Boolean false for required field (3.1.0)
{
    my $spec = {
        openapi => '3.1.0',
        info => {
            title   => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/test' => {
                get => {
                    parameters => [
                        {
                            name     => 'optional',
                            in       => 'query',
                            required => 0,
                            schema   => { type => 'string' }
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
    my @errors = $linter->validate_schema();
    is(scalar(@errors), 0, 'Boolean false for required field should validate successfully');
}

done_testing;
