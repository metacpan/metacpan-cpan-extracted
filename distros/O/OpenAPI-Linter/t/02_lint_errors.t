#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

# Test: Missing required fields (ERROR level)
{
    my $spec = {};
    my $linter = OpenAPI::Linter->new(spec => $spec);

    my @errors = $linter->find_issues(level => 'ERROR');

    ok(grep({ $_->{message} =~ /Missing openapi/ } @errors),
       'Detects missing openapi field');
    ok(grep({ $_->{message} =~ /Missing info/ } @errors),
       'Detects missing info field');
    ok(grep({ $_->{message} =~ /Missing paths/ } @errors),
       'Detects missing paths field');

    is(scalar(@errors), 3, 'Found exactly 3 errors');
}

# Test: Missing info fields
{
    my $spec = {
        openapi => '3.0.3',
        info => {},
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);

    my @errors = $linter->find_issues(level => 'ERROR');

    ok(grep({ $_->{message} =~ /Missing info.title/ } @errors),
       'Detects missing info.title');
    ok(grep({ $_->{message} =~ /Missing info.version/ } @errors),
       'Detects missing info.version');
}

done_testing;
