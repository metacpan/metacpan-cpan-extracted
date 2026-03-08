#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OpenAPI::Linter;

my $spec = {
    openapi => '3.1.0',
    info => {
        title       => 'Test API',
        version     => '1.0.0',
        description => 'A test API',
        license     => { name => 'MIT' },
    },
    # NO servers
    # NO security - ABSOLUTELY NO SECURITY
    # NO components.securitySchemes
    paths => {
        '/users' => {
            get => {
                summary => 'Get users',
                operationId => 'getUsers',
                # NO description - WARNING 1
                # NO security
                responses => {
                    '200' => {
                        description => 'OK',
                        content => {
                            'application/json' => {
                                schema => {
                                    type => 'array',
                                    items => {
                                        '$ref' => '#/components/schemas/User'
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        '/users/{id}' => {
            get => {
                summary => 'Get user by ID',
                operationId => 'getUserById',
                # NO description - WARNING 2
                # NO security
                parameters => [
                    {
                        name        => 'id',
                        in          => 'path',
                        required    => 1,
                        schema      => { type => 'integer' },
                        description => 'User ID',  # HAS description
                    }
                ],
                responses => {
                    '200' => {
                        description => 'OK',
                        content => {
                            'application/json' => {
                                schema => {
                                    '$ref' => '#/components/schemas/User'
                                }
                            }
                        }
                    }
                }
            }
        }
    },
    components => {
        # NO securitySchemes
        schemas => {
            User => {
                type => 'object',
                # NO description - WARNING 3
                # NO example - WARNING 4
                properties => {
                    id => {
                        type => 'integer',
                        # NO description - WARNING 5
                    },
                    name => {
                        type => 'string',
                        # NO description - WARNING 6
                    }
                }
            }
        }
    },
};

my $linter     = OpenAPI::Linter->new(spec => $spec);
my @all_issues = $linter->find_issues();
my @errors     = grep { $_->{level} eq 'ERROR' } @all_issues;
my @warnings   = grep { $_->{level} eq 'WARN'  } @all_issues;

# Test: Find by level
{
    my @errors = $linter->find_issues(level => 'ERROR');
    is(scalar(@errors), 0, 'No errors in this spec');

    my @warnings = $linter->find_issues(level => 'WARN');
    is(scalar(@warnings), 6, 'Has exactly 6 warnings');
}

# Test: Find by pattern
{
    my @missing_issues = $linter->find_issues(pattern => qr/missing/i);
    is(scalar(@missing_issues), 6, 'Found 6 issues matching "missing"');

    my @example_issues = $linter->find_issues(pattern => qr/example/i);
    is(scalar(@example_issues), 1, 'Found 1 issue matching "example"');

    my @description_issues = $linter->find_issues(pattern => qr/description/i);
    is(scalar(@description_issues), 5, 'Found 5 issues matching "description"');
}

# Test: Find all issues
{
    my @all = $linter->find_issues();
    is(scalar(@all), 6, 'Returns exactly 6 issues when no filters');
}

# Test: Return context
{
    my @array = $linter->find_issues();
    my $arrayref = $linter->find_issues();

    is(ref($arrayref), 'ARRAY', 'Returns arrayref in scalar context');
    is(scalar(@array), scalar(@$arrayref), 'Same number of issues in both contexts');
}

done_testing;
