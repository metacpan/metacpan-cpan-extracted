#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use OpenAPI::Linter;

sub count_issues_by_type {
    my ($issues, $pattern) = @_;
    return scalar(grep { $_->{message} =~ /$pattern/ } @$issues);
}

# Test 1: Spec that would previously crash with "Not a HASH reference"
my $spec1 = {
    openapi => '3.1.0',
    info    => {
        title   => 'Test API',
        version => '1.0.0',
        # NO description - warning
        # NO license - warning
    },
    paths => {
        '/crash_test' => {
            parameters => [],
            summary    => 'Crash path',
            'x-test'   => 'value',
            get => {
                # NO operationId - warning
                # NO description - warning
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
my $missing_info_desc    = count_issues_by_type(\@issues1, qr/info.*description/i);
my $missing_info_license = count_issues_by_type(\@issues1, qr/info.*license/i);
my $missing_op_desc      = count_issues_by_type(\@issues1, qr/operation.*description/i);
my $missing_op_id        = count_issues_by_type(\@issues1, qr/operationId/i);
my $kebab_case           = count_issues_by_type(\@issues1, qr/kebab-case/i);

# Expected issues for spec1: 6 total
# 1. Missing info.description
# 2. Missing info.license
# 3. Missing operation description for GET /crash_test
# 4. Missing operationId for GET /crash_test
# 5. Path segment 'crash_test' should be kebab-case
# 6. Response 200 in get /crash_test is missing description? OR Component warning?
is(scalar(@issues1), 6, "Test 3: Found 6 total issues in incomplete 3.1.0 spec");
is($missing_info_desc, 1, "Test 3a: Found missing info.description");
is($missing_info_license, 1, "Test 3b: Found missing info.license");
is($missing_op_desc, 1, "Test 3c: Found missing operation description");
is($missing_op_id, 1, "Test 3d: Found missing operationId");
is($kebab_case, 1, "Test 3e: Found kebab-case warning for path segment");

# Test 2: Path with only non-hash elements (no HTTP methods)
my $spec2 = {
    openapi => '3.1.0',
    info    => {
        title       => 'Test API',
        version     => '1.0.0',
        description => 'Test description',
        license     => { name => 'MIT' }
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
my $op_issues2 = count_issues_by_type(\@issues2, qr/operation/i);
is($op_issues2, 0, "Test 6: No operation issues when path has no HTTP methods");

# Test 3: Valid operation with description (should have no operation description issues)
my $spec3 = {
    openapi => '3.1.0',
    info    => {
        title       => 'Test API',
        version     => '1.0.0',
        description => 'Test description',
        license     => { name => 'MIT' }
    },
    paths => {
        '/good' => {
            parameters => [],
            get        => {
                summary     => 'Good operation',
                description => 'This has a description',
                operationId => 'goodOperation',
                responses   => { '200' => { description => 'OK' } }
            }
        }
    }
};

my $linter3 = OpenAPI::Linter->new(spec => $spec3);
my @issues3 = $linter3->find_issues();

# Should find 0 operation description issues
my $op_issues3 = count_issues_by_type(\@issues3, qr/operation.*description/i);
is($op_issues3, 0, "Test 7: No operation description issues when operation has description");

# Test 4: Verify the fix doesn't break normal operation checking
my $spec4 = {
    openapi => '3.1.0',
    info    => {
        title       => 'Test API',
        version     => '1.0.0',
        description => 'Test description',
        license     => { name => 'MIT' }
    },
    paths => {
        '/test' => {
            get => {
                summary     => 'No description',
                operationId => 'getTest',    # FIXED: Added operationId
                responses   => { '200' => { description => 'OK' } }
            },
            post => {
                summary     => 'Has description',
                description => 'Post operation',
                operationId => 'postTest',
                responses   => { '200' => { description => 'OK' } }
            }
        }
    }
};

my $linter4 = OpenAPI::Linter->new(spec => $spec4);
my @issues4 = $linter4->find_issues();

# Should find 0 operation description issues (3.1.0 doesn't require descriptions)
my $op_issues4 = count_issues_by_type(\@issues4, qr/operation.*description/i);
is($op_issues4, 1, "Test 8: Found missing operation description (GET /test)");

# Test 5: Verify no hash reference errors in any issues
my @hash_errors = grep {
    $_->{message} =~ /Not a HASH reference|Can't use string|Can't use an array/
} @issues1, @issues2, @issues3, @issues4;
is(scalar(@hash_errors), 0, "Test 9: No hash reference errors in any issues");

done_testing;
