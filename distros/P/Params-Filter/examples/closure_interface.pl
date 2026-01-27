#!/usr/bin/env perl
use v5.40;
use strict;
use warnings;

use Params::Filter qw/make_filter/;

say "=" x 80;
say "Params::Filter Closure Interface Examples";
say "=" x 80;
say "";

# ============================================================================
# Example 1: Basic usage - filtering user registration data
# ============================================================================
say "EXAMPLE 1: User Registration Filter";
say "-" x 80;
say "";

my $user_filter = make_filter(
    [qw(username email)],     # required
    [qw(full_name bio)],      # accepted
    [qw(password confirm)],   # excluded
);

my @registrations = (
    {
        username => 'alice',
        email => 'alice@example.com',
        full_name => 'Alice Johnson',
        bio => 'Software developer',
        password => 'secret123',
        confirm => 'secret123',
    },
    {
        username => 'bob',
        email => 'bob@example.com',
        full_name => 'Bob Smith',
        password => 'pass456',
        # bio missing (optional, ok)
    },
    {
        username => 'charlie',
        # email missing (required - should fail)
        full_name => 'Charlie Brown',
    },
);

say "Processing registrations:";
for my $reg (@registrations) {
    my $filtered = $user_filter->($reg);

    if ($filtered) {
        say "  ✅ Valid: ", join(", ", sort keys %$filtered);
    } else {
        say "  ❌ Invalid: missing required fields";
    }
}
say "";

# ============================================================================
# Example 2: Wildcard - safe logging
# ============================================================================
say "EXAMPLE 2: Safe Logging (Wildcard with Exclusions)";
say "-" x 80;
say "Use wildcard to accept all fields except sensitive ones";
say "";

my $safe_log_filter = make_filter(
    [qw(id timestamp level)],          # required
    ['*'],                              # wildcard - accept all
    [qw(password token ssn credit_card secret)],  # but exclude sensitive
);

my @log_entries = (
    {
        id => '12345',
        timestamp => '2025-01-26T10:00:00Z',
        level => 'INFO',
        message => 'User login',
        user_id => 42,
        ip => '192.168.1.1',
        password => 'leaked123',  # Should be excluded
        token => 'abc-secret',    # Should be excluded
    },
);

say "Safe log entries (sensitive fields removed):";
for my $entry (@log_entries) {
    my $safe = $safe_log_filter->($entry);
    say "  Fields: ", join(", ", sort keys %$safe);
    say "  Has password? ", (exists $safe->{password} ? "YES (BUG!)" : "NO (good)");
    say "  Has token? ", (exists $safe->{token} ? "YES (BUG!)" : "NO (good)");
}
say "";

# ============================================================================
# Example 3: Required-only - minimal validation
# ============================================================================
say "EXAMPLE 3: Required-Only Variant";
say "-" x 80;
say "When accepted list is empty, only required fields are returned";
say "";

my $minimal_filter = make_filter(
    [qw(id type)],  # required
    [],             # no accepted fields
    [],             # no exclusions
);

my @events = (
    {
        id => 1,
        type => 'click',
        timestamp => '2025-01-26',
        user_id => 42,
        url => '/page',
        referrer => 'https://example.com',
        metadata => {foo => 'bar'},
    },
);

say "Minimal filtering (only required fields):";
for my $event (@events) {
    my $minimal = $minimal_filter->($event);
    say "  Input fields: ", scalar(keys %$event), " fields";
    say "  Output fields: ", join(", ", sort keys %$minimal);
    say "  Extra fields discarded: ", scalar(keys %$event) - scalar(keys %$minimal);
}
say "";

# ============================================================================
# Example 4: High-volume data processing
# ============================================================================
say "EXAMPLE 4: High-Volume Data Processing";
say "-" x 80;
say "Process large datasets efficiently";
say "";

my $api_filter = make_filter(
    [qw(item_id title price)],
    [qw(description category stock)],
    [qw(internal_id cost_margin supplier_code)],
);

# Simulate high-volume data
my @products = map {
    {
        item_id => $_,
        title => "Product $_",
        price => $_ * 10,
        description => "Description for $_",
        category => 'electronics',
        stock => 100,
        internal_id => "INT-$_",
        cost_margin => 0.3,
        supplier_code => "SUP-$_",
    }
} (1..1000);

say "Processing 1000 products...";
my $start = time;
my $valid_count = 0;

for my $product (@products) {
    my $filtered = $api_filter->($product);
    $valid_count++ if $filtered;
}

my $elapsed = time - $start;
say "Processed: $valid_count valid records";
say "Time: ${elapsed}s";
if ($elapsed > 0) {
    say "Rate: ", sprintf('%.0f', $valid_count/$elapsed), " records/sec";
}
say "";

# ============================================================================
# Example 5: Multiple filter pipeline
# ============================================================================
say "EXAMPLE 5: Multiple Filter Pipeline";
say "-" x 80;
say "Apply different filters to same data for different consumers";
say "";

my $public_filter = make_filter(
    [qw(id title)],
    [qw(description price)],
    [qw(cost stock supplier_code)],
);

my $internal_filter = make_filter(
    [qw(id title)],
    ['*'],  # all fields
    [],     # no exclusions
);

my $warehouse_filter = make_filter(
    [qw(id title stock)],
    [qw(location warehouse_bin)],
    [qw(price cost margin)],
);

my $product_data = {
    id => 123,
    title => 'Widget Pro',
    description => 'Premium widget',
    price => 29.99,
    cost => 15.00,
    margin => 0.5,
    stock => 100,
    location => 'A1-23',
    warehouse_bin => 'BIN-42',
    supplier_code => 'SUP-123',
};

say "Original data has ", scalar(keys %$product_data), " fields";
say "";

my $public = $public_filter->($product_data);
say "Public API receives: ", join(", ", sort keys %$public);

my $internal = $internal_filter->($product_data);
say "Internal dashboard receives: ", join(", ", sort keys %$internal);

my $warehouse = $warehouse_filter->($product_data);
say "Warehouse system receives: ", join(", ", sort keys %$warehouse);
say "";

# ============================================================================
# Example 6: Conditional filtering
# ============================================================================
say "EXAMPLE 6: Conditional Filtering";
say "-" x 80;
say "Choose filter based on runtime conditions";
say "";

my %filters = (
    user => make_filter([qw(id name email)], [qw(phone bio)], []),
    admin => make_filter([qw(id name email role)], ['*'], [qw(password)]),
    guest => make_filter([qw(id)], [], []),
);

my @requests = (
    {user_type => 'user', id => 1, name => 'Alice', email => 'alice@example.com', phone => '555-0001', bio => 'User bio'},
    {user_type => 'admin', id => 2, name => 'Bob', email => 'bob@example.com', role => 'admin', password => 'admin123'},
    {user_type => 'guest', id => 3, name => 'Charlie', email => 'charlie@example.com'},
);

say "Filtering based on user type:";
for my $req (@requests) {
    my $type = delete $req->{user_type};
    my $filter = $filters{$type};
    my $result = $filter->($req);

    say "  $type: ", $result ? join(", ", sort keys %$result) : "INVALID";
}
say "";

say "=" x 80;
say "Key Takeaways";
say "=" x 80;
say "";
say "1. Create filter once, use many times - maximum performance";
say "2. Three specialized variants: required-only, wildcard, accepted-specific";
say "3. Non-destructive - original data never modified";
say "4. Perfect for high-volume data processing";
say "5. Combine multiple filters for data pipelines";
say "";
