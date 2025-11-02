#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use OpenAPI::Linter;

# Test YAML file loading
{
    my ($fh, $filename) = tempfile(SUFFIX => '.yaml', UNLINK => 1);
    print $fh <<'YAML';
openapi: 3.0.3
info:
  title: Test API
  version: 1.0.0
paths: {}
YAML
    close $fh;

    my $linter = eval { OpenAPI::Linter->new(spec => $filename) };
    ok($linter, 'Loads YAML file successfully');
    isa_ok($linter, 'OpenAPI::Linter');
}

# Test JSON file loading
{
    my ($fh, $filename) = tempfile(SUFFIX => '.json', UNLINK => 1);
    print $fh <<'JSON';
{
  "openapi": "3.0.3",
  "info": {
    "title": "Test API",
    "version": "1.0.0"
  },
  "paths": {}
}
JSON
    close $fh;

    my $linter = eval { OpenAPI::Linter->new(spec => $filename) };
    ok($linter, 'Loads JSON file successfully');
    isa_ok($linter, 'OpenAPI::Linter');
}

done_testing;
