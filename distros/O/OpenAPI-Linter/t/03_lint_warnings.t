#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

# Test: Missing optional but recommended fields (WARN level)
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test API',
            version => '1.0.0',
        },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);

    my @warnings = $linter->find_issues(level => 'WARN');

    ok(grep({ $_->{message} =~ /Missing info.description/ } @warnings),
       'Detects missing info.description');
    ok(grep({ $_->{message} =~ /Missing info.license/ } @warnings),
       'Detects missing license');
}

# Test: Missing operation descriptions
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test API',
            version => '1.0.0',
            description => 'A test API',
            license => { name => 'MIT' },
        },
        paths => {
            '/users' => {
                get => {
                    summary => 'Get users',
                },
                post => {
                    description => 'Create user',
                },
            },
        },
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);

    my @warnings = $linter->find_issues(level => 'WARN');

    ok(grep({ $_->{message} =~ /Missing description for get \/users/ } @warnings),
       'Detects missing operation description');
    ok(!grep({ $_->{message} =~ /post \/users/ } @warnings),
       'Does not warn when description exists');
}

# Test: Missing schema descriptions
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test API',
            version => '1.0.0',
            description => 'Test',
            license => { name => 'MIT' },
        },
        paths => {},
        components => {
            schemas => {
                User => {
                    type => 'object',
                    properties => {
                        id => { type => 'integer' },
                        name => {
                            type => 'string',
                            description => 'User name',
                        },
                    },
                },
            },
        },
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);

    my @warnings = $linter->find_issues(level => 'WARN');

    ok(grep({ $_->{message} =~ /Schema User.id missing description/ } @warnings),
       'Detects missing property description');
    ok(!grep({ $_->{message} =~ /User.name/ } @warnings),
       'Does not warn when property description exists');
}

# Test: Missing schema type
{
    my $spec = {
        openapi => '3.0.3',
        info => {
            title => 'Test API',
            version => '1.0.0',
            description => 'Test',
            license => { name => 'MIT' },
        },
        paths => {},
        components => {
            schemas => {
                BadSchema => {
                    properties => {
                        field => { type => 'string' },
                    },
                },
            },
        },
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);

    my @warnings = $linter->find_issues(level => 'WARN');

    ok(grep({ $_->{message} =~ /Schema BadSchema missing type/ } @warnings),
       'Detects missing schema type');
}

done_testing;
