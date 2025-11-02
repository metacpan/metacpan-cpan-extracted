#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

my $spec = {
    openapi => '3.0.3',
    info => {
        title => 'Test API',
        version => '1.0.0',
    },
    paths => {
        '/users' => {
            get => {},
        },
    },
};

my $linter = OpenAPI::Linter->new(spec => $spec);

# Test: Find by level
{
    my @errors = $linter->find_issues(level => 'ERROR');
    ok(scalar(@errors) == 0, 'No errors in this spec');

    my @warnings = $linter->find_issues(level => 'WARN');
    ok(scalar(@warnings) > 0, 'Has warnings');
}

# Test: Find by pattern
{
    my @info_issues = $linter->find_issues(pattern => qr/info/);
    ok(scalar(@info_issues) > 0, 'Found issues matching "info"');

    my @missing_issues = $linter->find_issues(pattern => qr/Missing/);
    ok(scalar(@missing_issues) > 0, 'Found issues matching "Missing"');
}

# Test: Find by level and pattern
{
    my @warn_info = $linter->find_issues(
        level => 'WARN',
        pattern => qr/info/,
    );

    for my $issue (@warn_info) {
        is($issue->{level}, 'WARN', 'Issue has correct level');
        like($issue->{message}, qr/info/, 'Issue matches pattern');
    }
}

# Test: Find all issues
{
    my @all = $linter->find_issues();
    ok(scalar(@all) > 0, 'Returns all issues when no filters');
}

# Test: Return context
{
    my @array = $linter->find_issues();
    my $arrayref = $linter->find_issues();

    is(ref($arrayref), 'ARRAY', 'Returns arrayref in scalar context');
    ok(!ref($array[0]) || ref($array[0]) eq 'HASH',
       'Returns array in list context');
}

done_testing;
