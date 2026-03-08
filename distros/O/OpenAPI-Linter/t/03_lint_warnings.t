#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OpenAPI::Linter;

# Test: Missing optional but recommended fields (WARN level)
{
    my $spec = {
        openapi => '3.0.3',
        paths   => {},
        info    => {
            title   => 'Test API',
            version => '1.0.0',
        },
    };

    my $linter   = OpenAPI::Linter->new(spec => $spec);
    my @warnings = $linter->find_issues;
    @warnings    = grep { $_->{level} eq 'WARN' } @warnings;

    ok(grep({ $_->{message} =~ /info.*description/i } @warnings),
       'Detects missing info.description');
    ok(grep({ $_->{message} =~ /info.*license/i     } @warnings),
       'Detects missing license');
}

# Test: Missing operation descriptions
{
    my $spec = {
        openapi  => '3.0.3',
        security => [{ apiKey => [] }],
        info     => {
            title       => 'Test API',
            version     => '1.0.0',
            description => 'A test API',
            license     => { name => 'MIT' },
        },
        components => {
            securitySchemes => {
                apiKey => {
                    type => 'apiKey',
                    name => 'X-API-Key',
                    in   => 'header',
                },
            },
        },
        paths => {
            '/users' => {
                get => {
                    summary     => 'Get users',
                    operationId => 'getUsers',
                    security    => [{ apiKey => [] }],
                    responses   => {
                        '200'   => { description => 'OK' },
                    },
                },
                post => {
                    description => 'Create user',
                    summary     => 'Create user',
                    operationId => 'createUser',
                    security    => [{ apiKey => [] }],
                    responses   => {
                        '201'   => { description => 'Created' },
                    },
                },
            },
        },
    };

    my $linter   = OpenAPI::Linter->new(spec => $spec);
    my @warnings = $linter->find_issues;
    @warnings    = grep { $_->{level} eq 'WARN' } @warnings;

    ok(grep({ $_->{message} =~ /Operation get \/users.*missing a description/ } @warnings),
       'Detects missing operation description');
    ok(!grep({ $_->{message} =~ /post \/users.*missing a description/         } @warnings),
       'Does not warn when description exists');
}

# Test: Missing schema descriptions
{
    my $spec = {
        openapi => '3.0.3',
        info    => {
            title       => 'Test API',
            version     => '1.0.0',
            description => 'Test',
            license     => { name => 'MIT' },
        },
        security   => [{ apiKey => [] }],
        components => {
            securitySchemes => {
                apiKey => {
                    type => 'apiKey',
                    name => 'X-API-Key',
                    in   => 'header',
                },
            },
            schemas => {
                User => {
                    type => 'object',
                    properties => {
                        id   => { type => 'integer' },
                        name => {
                            type        => 'string',
                            description => 'User name',
                        },
                    },
                },
            },
        },
        paths => {},
    };

    my $linter   = OpenAPI::Linter->new(spec => $spec);
    my @warnings = $linter->find_issues;
    @warnings    = grep { $_->{level} eq 'WARN' } @warnings;

    ok(grep({ $_->{message} =~ /Property 'id'.*missing description/    } @warnings),
       'Detects missing property description');
    ok(!grep({ $_->{message} =~ /Property 'name'.*missing description/ } @warnings),
       'Does not warn when property description exists');
}

# Test: Missing schema type
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title       => 'Test API',
            version     => '1.0.0',
            description => 'Test',
            license     => { name => 'MIT' },
        },
        security   => [{ apiKey => [] }],
        components => {
            securitySchemes => {
                apiKey => {
                    type => 'apiKey',
                    name => 'X-API-Key',
                    in   => 'header',
                },
            },
            schemas => {
                BadSchema => {
                    properties => {
                        field => { type => 'string' },
                    },
                },
            },
        },
        paths => {},
    };

    my $linter   = OpenAPI::Linter->new(spec => $spec);
    my @warnings = $linter->find_issues;
    @warnings    = grep { $_->{level} eq 'WARN' } @warnings;

    ok(grep({ $_->{message} =~ /Schema 'BadSchema'.*missing type/ } @warnings),
       'Detects missing schema type');
}

done_testing;
