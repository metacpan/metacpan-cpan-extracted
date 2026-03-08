#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OpenAPI::Linter;

my $complete_spec = {
    openapi => '3.1.0',
    info => {
        title       => 'Complete API',
        version     => '1.0.0',
        description => 'A complete API specification',
        license     => {
            name => 'Apache 2.0',
            url  => 'https://www.apache.org/licenses/LICENSE-2.0.html',
        },
    },
    security => [{ apiKey => [] }],
    servers  => [
        {
            url         => 'https://api.example.com/v1',
            description => 'Production server',
        }
    ],
    paths => {
        '/users' => {
            get => {
                summary     => 'List all users',
                description => 'List all users',
                operationId => 'getUsers',
                security    => [{ apiKey => [] }],
                responses => {
                    '200' => {
                        description => 'Successful response',
                        content     => {
                            'application/json' => {
                                schema => {
                                    type  => 'array',
                                    items => {
                                        '$ref' => '#/components/schemas/User'
                                    }
                                }
                            }
                        }
                    },
                },
            },
            post => {
                summary     => 'Create a new user',
                description => 'Creates a new user',
                operationId => 'createUser',
                security    => [{ apiKey => [] }],
                requestBody => {
                    description => 'User object',
                    required    => 1,
                    content     => {
                        'application/json' => {
                            schema => {
                                '$ref' => '#/components/schemas/User'
                            }
                        }
                    }
                },
                responses => {
                    '201' => {
                        description => 'User created',
                        content     => {
                            'application/json' => {
                                schema => {
                                    '$ref' => '#/components/schemas/User'
                                }
                            }
                        }
                    },
                    '400' => {
                        description => 'Bad request',
                    },
                },
            },
        },
        '/users/{id}' => {
            get => {
                summary     => 'Get user by ID',
                description => 'Returns a single user',
                operationId => 'getUserById',
                security    => [{ apiKey => [] }],
                parameters  => [
                    {
                        name        => 'id',
                        in          => 'path',
                        required    => 1,
                        schema      => { type => 'integer' },
                        description => 'User ID',
                    }
                ],
                responses => {
                    '200' => {
                        description => 'Successful response',
                        content => {
                            'application/json' => {
                                schema => {
                                    '$ref' => '#/components/schemas/User'
                                }
                            }
                        }
                    },
                    '404' => {
                        description => 'User not found',
                    },
                },
            },
        },
    },
    components => {
        securitySchemes => {
            apiKey => {
                type => 'apiKey',
                name => 'X-API-Key',
                'in' => 'header',
            },
        },
        schemas => {
            User => {
                type        => 'object',
                description => 'A user object',
                example     => { id => 1, name => 'John Doe' },
                required    => ['id', 'name'],
                properties  => {
                    id => {
                        type        => 'integer',
                        description => 'User ID',
                    },
                    name => {
                        type        => 'string',
                        description => 'User name',
                    },
                },
            },
        },
    },
};

my $linter = OpenAPI::Linter->new(spec => $complete_spec);
my @issues = $linter->find_issues();

is(scalar(@issues), 0, 'Complete spec has no issues');

my @errors = grep { $_->{level} eq 'ERROR' } @issues;
is(scalar(@errors), 0, 'Complete spec has no errors');

my @warnings = grep { $_->{level} eq 'WARN' } @issues;
is(scalar(@warnings), 0, 'Complete spec has no warnings');

done_testing;
