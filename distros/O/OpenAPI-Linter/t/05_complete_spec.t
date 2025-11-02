#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

my $complete_spec = {
    openapi => '3.0.3',
    info => {
        title => 'Complete API',
        version => '1.0.0',
        description => 'A complete API specification',
        license => {
            name => 'Apache 2.0',
            url => 'https://www.apache.org/licenses/LICENSE-2.0.html',
        },
    },
    paths => {
        '/users' => {
            get => {
                description => 'List all users',
                responses => {
                    '200' => {
                        description => 'Successful response',
                    },
                },
            },
            post => {
                description => 'Create a new user',
                responses => {
                    '201' => {
                        description => 'User created',
                    },
                },
            },
        },
    },
    components => {
        schemas => {
            User => {
                type => 'object',
                properties => {
                    id => {
                        type => 'integer',
                        description => 'User ID',
                    },
                    name => {
                        type => 'string',
                        description => 'User name',
                    },
                },
            },
        },
    },
};

my $linter = OpenAPI::Linter->new(spec => $complete_spec);

my @all_issues = $linter->find_issues();
is(scalar(@all_issues), 0, 'Complete spec has no issues');

my @errors = $linter->find_issues(level => 'ERROR');
is(scalar(@errors), 0, 'Complete spec has no errors');

my @warnings = $linter->find_issues(level => 'WARN');
is(scalar(@warnings), 0, 'Complete spec has no warnings');

done_testing;
