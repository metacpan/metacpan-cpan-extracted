#!/usr/bin/env perl
use v5.40;
use Params::Filter qw/filter/;

# Debug Mode Example: Development-time warnings for edge cases
# Debug mode helps catch potential issues during development

say "=== Debug Mode: Development Warnings ===\n";

say "--- Example 1: Odd Number of Array Elements ---\n";

my ($result1, $msg1) = filter(
    ['name', 'Alice', 'age', 'verbose'],  # 5 elements (odd!)
    ['name'],
    ['age', 'verbose'],
    [],
    1,  # DEBUG mode ON
);

say "Result data:";
say "  $_: $result1->{$_}" for sort keys $result1->%*;
say "\nStatus message (with debug warnings):";
say "  $msg1";

say "\n--- Example 2: Excluded Fields Warning ---\n";

my ($result2, $msg2) = filter(
    {
        name     => 'Bob',
        email    => 'bob@example.com',
        password => 'secret123',  # Will be excluded
        ssn      => '123-45-6789', # Will be excluded
        phone    => '555-1234',
    },
    ['name', 'email'],
    ['phone'],
    ['password', 'ssn', 'api_key'],  # excluded fields
    1,  # DEBUG mode ON
);

say "Result data (excluded fields removed):";
say "  $_: $result2->{$_}" for sort keys $result2->%*;
say "\nStatus message (shows excluded fields):";
say "  $msg2";

say "\n--- Example 3: Unrecognized Fields Warning ---\n";

my ($result3, $msg3) = filter(
    {
        name      => 'Charlie',
        email     => 'charlie@example.com',
        random1   => 'foo',
        random2   => 'bar',
        ignored   => 'baz',
    },
    ['name', 'email'],
    [],  # No accepted fields = only required accepted
    [],
    1,  # DEBUG mode ON
);

say "Result data (only required fields):";
say "  $_: $result3->{$_}" for sort keys $result3->%*;
say "\nStatus message (shows unrecognized fields):";
say "  $msg3";

say "\n--- Example 4: Combined Warnings ---\n";

my ($result4, $msg4) = filter(
    {
        user_id  => 123,
        name     => 'Diana',
        password => 'hidden',    # Excluded
        spam     => 'yes',       # Unrecognized
    },
    ['user_id'],
    ['name'],
    ['password', 'token', 'secret'],  # excluded
    1,  # DEBUG mode ON
);

say "Result data:";
say "  $_: $result4->{$_}" for sort keys $result4->%*;
say "\nStatus message (multiple warnings):";
say "  $msg4";

say "\n--- Example 5: Scalar Input Warning ---\n";

my ($result5, $msg5) = filter(
    'This is just a plain string, not a hashref!',  # Scalar input
    [],
    ['_'],  # Accept the special '_' key
    [],
    1,  # DEBUG mode ON
);

say "Result data:";
say "  $_: $result5->{$_}" for sort keys $result5->%*;
say "\nStatus message (warns about scalar input):";
say "  $msg5";

say "\n--- Example 6: OO Interface with Debug Mode ---\n";

my $debug_filter = Params::Filter->new_filter({
    required => ['id'],
    accepted => ['name', 'value'],
    excluded => ['secret', 'temp'],
    debug    => 1,  # Debug mode enabled
});

my ($result6, $msg6) = $debug_filter->apply({
    id     => 42,
    name   => 'Test',
    secret => 'classified',  # Excluded
    extra  => 'ignored',      # Unrecognized
});

say "Result data:";
say "  $_: $result6->{$_}" for sort keys $result6->%*;
say "\nStatus message:";
say "  $msg6";

say "\n--- Example 7: Production Mode (No Debug) ---\n";

my ($result7, $msg7) = filter(
    {
        name     => 'Eve',
        email    => 'eve@example.com',
        password => 'secret',   # Excluded (silently in production)
        random   => 'ignored',  # Unrecognized (silently in production)
    },
    ['name', 'email'],
    [],
    ['password'],
    0,  # DEBUG mode OFF (production)
);

say "Result data:";
say "  $_: $result7->{$_}" for sort keys $result7->%*;
say "\nStatus message (clean, no warnings):";
say "  $msg7";
