#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

# Test: Empty paths object
{
    my $spec = {
        openapi => '3.0.3',
        info => { title => 'Test', version => '1.0' },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    eval { $linter->find_issues };
    ok(!$@, 'Handles empty paths object without error');
}

# Test: Empty components object
{
    my $spec = {
        openapi => '3.0.3',
        info => { title => 'Test', version => '1.0' },
        paths => {},
        components => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    eval { $linter->find_issues };
    ok(!$@, 'Handles empty components object without error');
}

# Test: Schema without properties
{
    my $spec = {
        openapi => '3.0.3',
        info => { title => 'Test', version => '1.0' },
        paths => {},
        components => {
            schemas => {
                SimpleString => {
                    type => 'string',
                },
            },
        },
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    eval { $linter->find_issues };
    ok(!$@, 'Handles schema without properties');
}

# Test: Multiple linting runs
{
    my $spec = {
        openapi => '3.0.3',
        info => { title => 'Test', version => '1.0' },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @issues1 = $linter->find_issues();
    my @issues2 = $linter->find_issues();

    is(scalar(@issues1), scalar(@issues2),
       'Multiple lint runs produce consistent results');
}

done_testing;
