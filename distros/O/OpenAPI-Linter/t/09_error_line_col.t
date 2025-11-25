#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Temp qw(tempfile);

BEGIN { use_ok('OpenAPI::Linter') }

my ($yaml_fh, $yaml_file) = tempfile(SUFFIX => '.yaml');
my ($json_fh, $json_file) = tempfile(SUFFIX => '.json');
my ($incomplete_yaml_fh, $incomplete_yaml_file) = tempfile(SUFFIX => '.yaml');
my ($complete_yaml_fh, $complete_yaml_file)     = tempfile(SUFFIX => '.yaml');

# Complete valid YAML file with all required fields
print $complete_yaml_fh <<'YAML';
openapi: 3.0.3
info:
  title: Test API
  version: 1.0.0
  description: A test API
  license:
    name: MIT
    url: https://opensource.org/licenses/MIT
paths:
  /users:
    get:
      summary: Get users
      description: Returns a list of users
      responses:
        '200':
          description: Success
YAML
close $complete_yaml_fh;

# Test YAML file with some missing optional fields (will have warnings)
print $yaml_fh <<'YAML';
openapi: 3.0.3
info:
  title: Test API
  version: 1.0.0
paths:
  /users:
    get:
      summary: Get users
      responses:
        '200':
          description: Success
YAML
close $yaml_fh;

# Test JSON file with missing optional fields
print $json_fh <<'JSON';
{
  "openapi": "3.0.3",
  "info": {
    "title": "Test API",
    "version": "1.0.0"
  },
  "paths": {
    "/users": {
      "get": {
        "responses": {
          "200": {
            "description": "Success"
          }
        }
      }
    }
  }
}
JSON
close $json_fh;

# Incomplete YAML file for error testing
print $incomplete_yaml_fh <<'YAML';
openapi: 3.0.3
info:
  version: 1.0.0
  # Missing title on purpose
paths:
  /test:
    get:
      # Missing description on purpose
      responses:
        '200':
          description: OK
YAML
close $incomplete_yaml_fh;

# Test 1: Complete valid YAML file
subtest 'Complete valid YAML file with location tracking' => sub {
    my $linter = OpenAPI::Linter->new(spec => $complete_yaml_file);
    isa_ok($linter, 'OpenAPI::Linter', 'Linter object created from complete YAML file');

    my @issues = $linter->find_issues;
    is(scalar @issues, 0, 'No issues in complete valid YAML file')
        or diag explain \@issues;

    # Check that locations hash is populated
    my $locations = $linter->{locations};
    ok(ref $locations eq 'HASH', 'Locations hash exists');
    ok(exists $locations->{base}, 'Base location exists');
};

# Test 2: YAML file with warnings
subtest 'YAML file with warnings' => sub {
    my $linter = OpenAPI::Linter->new(spec => $yaml_file);
    isa_ok($linter, 'OpenAPI::Linter', 'Linter object created from YAML file');

    my @issues = $linter->find_issues;
    cmp_ok(scalar @issues, '>', 0, 'Found warnings in YAML file with missing optional fields');

    # All issues should have location information
    foreach my $issue (@issues) {
        like($issue->{location}, qr/:\d+:\d+$/, "Issue has location: $issue->{location}");
        ok($issue->{path}, "Issue has path: $issue->{path}");
        is($issue->{level}, 'WARN', "Issue is warning level: $issue->{message}");
    }
};

# Test 3: JSON file handling
subtest 'JSON file handling' => sub {
    my $linter = OpenAPI::Linter->new(spec => $json_file);
    isa_ok($linter, 'OpenAPI::Linter', 'Linter object created from JSON file');

    my @issues = $linter->find_issues;
    cmp_ok(scalar @issues, '>', 0, 'Found issues in JSON file with missing optional fields');

    # Check that issues have location information
    foreach my $issue (@issues) {
        like($issue->{location}, qr/:\d+:\d+$/, "Issue has location: $issue->{location}");
        ok($issue->{path}, "Issue has path: $issue->{path}");
    }
};

# Test 4: Incomplete YAML file with specific line numbers
subtest 'Incomplete YAML with line numbers' => sub {
    my $linter = OpenAPI::Linter->new(spec => $incomplete_yaml_file);
    my @issues = $linter->find_issues;

    cmp_ok(scalar @issues, '>=', 2, 'Found expected issues in incomplete YAML');

    # Check for specific errors with location info
    my %found_issues;
    foreach my $issue (@issues) {
        $found_issues{$issue->{message}} = $issue->{location};

        # All issues should have location information
        like($issue->{location}, qr/:\d+:\d+$/, "Issue '$issue->{message}' has location");
        ok($issue->{path}, "Issue '$issue->{message}' has path: $issue->{path}");
    }

    # Verify specific expected issues
    ok(exists $found_issues{'Missing info.title'}, 'Found missing title error');
    ok(exists $found_issues{'Missing description for get /test'}, 'Found missing description warning');
};

# Test 5: Hash reference input
subtest 'Hash reference input' => sub {
    my $spec = {
        openapi => '3.0.3',
        info    => {
            title   => 'Test API',
            version => '1.0.0',
        },
        paths => {
            '/test' => {
                get => {
                    responses => {
                        '200' => { description => 'OK' }
                    }
                }
            }
        }
    };

    my $linter = OpenAPI::Linter->new(spec => $spec);
    my @issues = $linter->find_issues;

    # Should have warnings but no errors
    my ($errors, $warnings) = (0, 0);
    foreach my $issue (@issues) {
        $errors++ if $issue->{level} eq 'ERROR';
        $warnings++ if $issue->{level} eq 'WARN';

        # Even with hash input, should have basic location info
        like($issue->{location}, qr/:\d+:\d+$/, "Hash input issue has location: $issue->{location}");
    }

    is($errors, 0, 'No errors with valid hash spec');
    cmp_ok($warnings, '>=', 1, 'Found expected warnings');
};

# Test 6: Schema validation with location info
subtest 'Schema validation locations' => sub {
    my $invalid_spec = {
        openapi => '3.0.3',
        info    => {
            # Missing required title and version
        },
        paths => {}
    };

    my $linter = OpenAPI::Linter->new(spec => $invalid_spec);
    my @schema_issues = $linter->validate_schema;

    cmp_ok(scalar @schema_issues, '>', 0, 'Found schema validation issues');

    foreach my $issue (@schema_issues) {
        is($issue->{level}, 'ERROR', 'Schema issues are ERROR level');
        like($issue->{location}, qr/:\d+:\d+$/, "Schema issue has location: $issue->{location}");
        ok($issue->{path}, "Schema issue has path: $issue->{path}");
    }
};

# Test 7: Location object functionality
subtest 'Location object' => sub {
    my $location = OpenAPI::Linter::Location->new('test.yaml', 10, 5);
    isa_ok($location, 'OpenAPI::Linter::Location', 'Location object created');

    is($location->{file}, 'test.yaml', 'File name set correctly');
    is($location->{line}, 10, 'Line number set correctly');
    is($location->{column}, 5, 'Column number set correctly');

    my $location_str = $location->to_string;
    is($location_str, 'test.yaml:10:5', 'Location string format correct');
};

# Test 8: Filtering with location info
subtest 'Filtering with location info' => sub {
    my $linter = OpenAPI::Linter->new(spec => $incomplete_yaml_file);

    # Test level filtering
    my @errors = $linter->find_issues(level => 'ERROR');
    foreach my $error (@errors) {
        is($error->{level}, 'ERROR', 'Filtered to ERROR level only');
        like($error->{location}, qr/:\d+:\d+$/, "Error has location: $error->{location}");
    }

    # Test pattern filtering
    my @title_issues = $linter->find_issues(pattern => qr/title/i);
    cmp_ok(scalar @title_issues, '>=', 1, 'Found title-related issues');
    foreach my $issue (@title_issues) {
        like($issue->{message}, qr/title/i, "Issue matches title pattern");
        like($issue->{location}, qr/:\d+:\d+$/, "Pattern-filtered issue has location");
    }
};

# Test 9: File not found
subtest 'Error handling' => sub {
    eval {
        my $linter = OpenAPI::Linter->new(spec => 'nonexistent.yaml');
    };
    like($@, qr/Spec file not found/, 'Correct error for nonexistent file');
};

# Test 10: Mixed return contexts
subtest 'Return contexts' => sub {
    my $linter = OpenAPI::Linter->new(spec => $incomplete_yaml_file);

    # List context
    my @issues_list = $linter->find_issues;
    ok(@issues_list > 0, 'Returns issues in list context');

    # Scalar context
    my $issues_ref = $linter->find_issues;
    is(ref $issues_ref, 'ARRAY', 'Returns arrayref in scalar context');
    is(scalar @$issues_ref, scalar @issues_list, 'Same number of issues in both contexts');

    # Check locations in both contexts
    foreach my $issue (@issues_list) {
        like($issue->{location}, qr/:\d+:\d+$/, "List context issue has location");
    }
    foreach my $issue (@$issues_ref) {
        like($issue->{location}, qr/:\d+:\d+$/, "Scalar context issue has location");
    }
};

# Test 11: Specific path location tracking
subtest 'Specific path locations' => sub {
    my $linter = OpenAPI::Linter->new(spec => $incomplete_yaml_file);
    my $locations = $linter->{locations};

    # Basic location structure should exist
    ok(ref $locations eq 'HASH', 'Locations is a hashref');

    # The locations hash should at least have a base location
    # Note: With YAML::XS we might only have base, with YAML::PP we get more
    ok((exists $locations->{base} || scalar keys %$locations > 0),
       'Has at least base location or specific path locations');
};

# Test 12: Version detection with locations
subtest 'Version detection' => sub {
    my $spec_with_version = {
        openapi => '3.1.0',
        info    => {
            title   => 'Test',
            version => '1.0.0'
        },
        paths => {}
    };

    my $linter = OpenAPI::Linter->new(spec => $spec_with_version);
    is($linter->{version}, '3.1.0', 'Version detected correctly');

    my @issues = $linter->find_issues;
    foreach my $issue (@issues) {
        like($issue->{location}, qr/:\d+:\d+$/, "Version detection issue has location");
    }
};

done_testing;

END {
    unlink $yaml_file if -f $yaml_file;
    unlink $json_file if -f $json_file;
    unlink $incomplete_yaml_file if -f $incomplete_yaml_file;
    unlink $complete_yaml_file   if -f $complete_yaml_file;
}
