#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OpenAPI::Linter;

# Test: Missing required fields (ERROR level)
{
    my $spec   = { openapi => '3.0.3' };
    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema;

    ok(!grep({ $_->{message} =~ /openapi/i } @errors),
       'OpenAPI field is present (no error)');

    ok(grep({ $_->{message} =~ /info/ } @errors),  # SIMPLIFIED
       'Detects missing info field');

    ok(grep({ $_->{message} =~ /paths/ } @errors),  # SIMPLIFIED
       'Detects missing paths field');

    is(scalar(@errors), 2, 'Found exactly 2 errors (info and paths)');
}

# Test: Missing info fields
{
    my $spec = {
        openapi => '3.0.3',
        info    => {},
        paths   => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @errors = $linter->validate_schema;

    ok(grep({ $_->{message} =~ /title/   } @errors),
       'Detects missing info.title');
    ok(grep({ $_->{message} =~ /version/ } @errors),
       'Detects missing info.version');
}

done_testing;
