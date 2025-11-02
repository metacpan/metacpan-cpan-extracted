#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

# Test 1: Constructor with spec hashref
{
    my $spec = {
        openapi => '3.0.3',
        info => { title => 'Test API', version => '1.0.0' },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    isa_ok($linter, 'OpenAPI::Linter', 'Constructor with spec hashref');
    is($linter->{version}, '3.0.3', 'Default version is 3.0.3');
}

# Test 2: Constructor with custom version
{
    my $spec = {
        openapi => '3.1.0',
        info => { title => 'Test API', version => '1.0.0' },
        paths => {},
    };

    my $linter = OpenAPI::Linter->new(spec => $spec, version => '3.1.0');
    is($linter->{version}, '3.1.0', 'Custom version set correctly');
}

# Test 3: Constructor dies without spec or file
{
    eval { OpenAPI::Linter->new };
    like($@, qr/spec => HASHREF required/, 'Dies without spec or file');
}

done_testing;
