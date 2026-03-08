#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OpenAPI::Linter;

my @issues;

my $valid_api = OpenAPI::Linter->new(spec => "t/specs/valid_api.yaml");
@issues       = $valid_api->find_issues;
is(scalar @issues, 0, 'Valid spec should have no issues');

# Use bundled schema — no schema_url, no network call
my $broken_spec = OpenAPI::Linter->new(
    spec => {
        openapi => '3.0.3',
        info    => { title => 'Broken' },   # missing required 'version'
    },
);
@issues = $broken_spec->validate_schema;
ok(scalar @issues > 0, 'Broken spec should return schema errors');

my $msg = $issues[0]->{message} // '';
isnt(ref($msg), 'ARRAY', 'Error message should be a string, not an array reference');

my $found = 0;
foreach my $issue (@issues) {
    my $loc_str = "$issue->{location}";
    $found = 1 if $issue->{message} =~ /required|missing|property/i
               || $loc_str          =~ /required|missing|property/i;
}
ok($found, 'Errors should be descriptive');

my $semantic_broken = OpenAPI::Linter->new(spec => "t/specs/semantic_broken.yaml");
@issues = $semantic_broken->find_issues;
my @missing_desc = grep { $_->{message} =~ /missing a description/ } @issues;
is(scalar @missing_desc, 1, 'Detected operation missing description');

my $missing_op_desc = OpenAPI::Linter->new(spec => "t/specs/missing_op_description.yaml");
@issues   = $missing_op_desc->find_issues;
my @warns = grep { $_->{level} eq 'WARN' } @issues;
ok(scalar @warns > 0, 'Detected missing operation description');

done_testing;
