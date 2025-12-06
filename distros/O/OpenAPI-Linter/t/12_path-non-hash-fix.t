#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use OpenAPI::Linter;

# Helper to count issues by type
sub count_issues_by_type {
    my ($issues, $pattern) = @_;
    return scalar(grep { $_->{message} =~ /$pattern/ } @$issues);
}

# Test 1: Spec that would previously crash with "Not a HASH reference"
my $spec1 = {
    openapi => '3.0.3',
    info    => {
        title   => 'Test API',
        version => '1.0.0',
    },
    paths => {
        '/crash-test' => {
            parameters => [],           # Array that would cause "Not a HASH reference"
            summary    => 'Crash path', # Scalar that would be treated as hash
            'x-test'   => 'value',      # Extension
            get => {
                responses => {
                    '200' => { description => 'OK' }
                }
            }
        }
    }
};

my $linter1;
eval {
    $linter1 = OpenAPI::Linter->new(spec => $spec1);
};
ok(!$@, "Test 1: Linter creation succeeds") or diag("Error: $@");

my @issues1;
eval {
    @issues1 = $linter1->find_issues();
};
ok(!$@, "Test 2: find_issues() does not crash with non-hash path elements")
    or diag("CRASH: $@");

# Count specific types of issues
my $missing_info_desc    = count_issues_by_type(\@issues1, qr/Missing info\.description/);
my $missing_info_license = count_issues_by_type(\@issues1, qr/Missing info\.license/);
my $missing_op_desc      = count_issues_by_type(\@issues1, qr/Missing description for get/);

# Should find info.description and info.license warnings (2 issues)
# and missing operation description (1 issue) = total 3
is(scalar(@issues1), 3, "Test 3: Found 3 total issues (info.description, info.license, operation description)");

# Verify we found the operation description issue
cmp_ok($missing_op_desc, '==', 1, "Test 4: Found 1 missing operation description issue");

# Verify the operation issue is about GET /crash-test
if ($missing_op_desc) {
    my @op_issues = grep { $_->{message} =~ /Missing description for get/ } @issues1;
    like($op_issues[0]->{message}, qr/Missing description for get \/crash-test/,
        "Test 5: Issue is about missing description for GET /crash-test");
}

# Test 2: Path with only non-hash elements (no HTTP methods)
my $spec2 = {
    openapi => '3.0.3',
    info    => {
        title       => 'Test API',
        version     => '1.0.0',
        description => 'Test description',  # Added to reduce noise
        license     => { name => 'MIT' }    # Added to reduce noise
    },
    paths => {
        '/no-methods' => {
            summary    => 'No methods here',
            parameters => [],
            servers    => []
        }
    }
};

my $linter2 = OpenAPI::Linter->new(spec => $spec2);
my @issues2 = $linter2->find_issues();

# Should find 0 operation issues (no HTTP methods to check)
my $op_issues2 = count_issues_by_type(\@issues2, qr/Missing description for/);
is($op_issues2, 0, "Test 6: No operation issues when path has no HTTP methods");

# Test 3: Valid operation with description (should have no operation description issues)
my $spec3 = {
    openapi => '3.0.3',
    info    => {
        title       => 'Test API',
        version     => '1.0.0',
        description => 'Test description',  # Added to reduce noise
        license     => { name => 'MIT' }    # Added to reduce noise
    },
    paths => {
        '/good' => {
            parameters => [],
            get        => {
                summary     => 'Good operation',
                description => 'This has a description',
                responses   => { '200' => { description => 'OK' } }
            }
        }
    }
};

my $linter3 = OpenAPI::Linter->new(spec => $spec3);
my @issues3 = $linter3->find_issues();

# Should find 0 operation description issues
my $op_issues3 = count_issues_by_type(\@issues3, qr/Missing description for/);
is($op_issues3, 0, "Test 7: No operation description issues when operation has description");

# Test 4: Verify the fix doesn't break normal operation checking
my $spec4 = {
    openapi => '3.0.3',
    info    => {
        title       => 'Test API',
        version     => '1.0.0',
        description => 'Test description',
        license     => { name => 'MIT' }
    },
    paths => {
        '/test' => {
            get => {
                summary   => 'No description',
                responses => { '200' => { description => 'OK' } }
            },
            post => {
                summary     => 'Has description',
                description => 'Post operation',
                responses   => { '200' => { description => 'OK' } }
            }
        }
    }
};

my $linter4 = OpenAPI::Linter->new(spec => $spec4);
my @issues4 = $linter4->find_issues();

# Should find 1 operation description issue (for GET only)
my $op_issues4 = count_issues_by_type(\@issues4, qr/Missing description for/);
is($op_issues4, 1, "Test 8: Found 1 missing operation description (GET)");

# Test 5: Verify no hash reference errors in any issues
my @hash_errors = grep {
    $_->{message} =~ /Not a HASH reference|Can't use string|Can't use an array/
} @issues1, @issues2, @issues3, @issues4;
is(scalar(@hash_errors), 0, "Test 9: No hash reference errors in any issues");

done_testing;
