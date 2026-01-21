#!/usr/bin/env perl
use v5.40;

# Example: Strict Parameter Construction
# Demonstrates the concept of "strict construction" - ensuring only
# valid, expected fields are accepted and dangerous fields are excluded

use Params::Filter qw/filter/;

say "=== Strict Parameter Construction ===\n";

# Define filtering rules as package-level constants
# In a real application, these might be in a config file
our $USER_REQUIRED = [qw/name email/];
our $USER_ACCEPTED = [qw/phone address city state zip/];
our $USER_EXCLUDED = [qw/ssn license credit_card/];

say "--- Functional Interface Example ---\n";

# Example 1: User registration with all fields
my $user_data1 = {
    name  => 'Alice Johnson',
    email => 'alice@example.com',
    phone => '555-1234',
    city  => 'San Francisco',
    state => 'CA',
    zip   => '94102',
    ssn   => '123-45-6789',  # Will be excluded
};

my ($filtered1, $msg1) = filter(
    $user_data1,
    $USER_REQUIRED,
    $USER_ACCEPTED,
    $USER_EXCLUDED,
    1,  # Debug mode
);

say "User 1 registration:";
say "  $_: $filtered1->{$_}" for sort keys $filtered1->%*;
say "  Status: $msg1";
say "  SSN excluded: " . (exists $filtered1->{ssn} ? "NO (BAD!)" : "YES (GOOD)");
say "\n";

# Example 2: Minimal registration (only required fields)
my $user_data2 = {
    name  => 'Bob Smith',
    email => 'bob@example.com',
};

my ($filtered2, $msg2) = filter(
    $user_data2,
    $USER_REQUIRED,
    $USER_ACCEPTED,
    $USER_EXCLUDED,
);

say "User 2 registration (minimal):";
say "  $_: $filtered2->{$_}" for sort keys $filtered2->%*;
say "  Status: $msg2\n";

# Example 3: Failed registration (missing required field)
my $user_data3 = {
    name => 'Charlie',
    # email is missing!
    phone => '555-5678',
};

my ($filtered3, $msg3) = filter(
    $user_data3,
    $USER_REQUIRED,
    $USER_ACCEPTED,
    $USER_EXCLUDED,
);

say "User 3 registration (incomplete):";
if ($filtered3) {
    say "  SUCCESS: $_ => $filtered3->{$_}" for sort keys $filtered3->%*;
} else {
    say "  FAILED: $msg3";
}
say "\n";

say "--- OO Interface Example ---\n";

# Create a reusable filter for user registration
my $user_filter = Params::Filter->new_filter({
    required => $USER_REQUIRED,
    accepted => $USER_ACCEPTED,
    excluded => $USER_EXCLUDED,
    debug    => 1,
});

# Example 4: Attempt to register with excluded field
my $user_data4 = {
    name        => 'Diana Prince',
    email       => 'diana@example.com',
    phone       => '555-9999',
    city        => 'New York',
    state       => 'NY',
    zip         => '10001',
    credit_card => '4111-1111-1111-1111',  # Will be excluded
};

my ($filtered4, $msg4) = $user_filter->apply($user_data4);

say "User 4 registration (with credit card):";
say "  $_: $filtered4->{$_}" for sort keys $filtered4->%*;
say "  Status: $msg4";
say "  Credit card excluded: " . (exists $filtered4->{credit_card} ? "NO (BAD!)" : "YES (GOOD)");
say "\n";

say "--- Example 5: Only Required Fields (Strict Mode) ---\n";

# Sometimes you only want required fields, nothing else
my $user_data5 = {
    name  => 'Eve Anderson',
    email => 'eve@example.com',
    phone => '555-4321',  # Will be ignored
    city  => 'Boston',    # Will be ignored
};

my ($filtered5, $msg5) = filter(
    $user_data5,
    $USER_REQUIRED,
    [],  # No accepted fields = only required
    $USER_EXCLUDED,
);

say "User 5 registration (required only):";
say "  $_: $filtered5->{$_}" for sort keys $filtered5->%*;
say "  Status: $msg5";
say "  Phone excluded (not in accepted): " . (exists $filtered5->{phone} ? "YES (BAD!)" : "NO (GOOD)");
say "\n";

say "--- Summary ---\n";
say "Strict parameter construction ensures:";
say "  1. Required fields are present";
say "  2. Only accepted fields are allowed";
say "  3. Dangerous/excluded fields are removed";
say "  4. Unknown fields are ignored (unless using wildcard)";
say "\nThis provides security by validation at the input boundary.";
