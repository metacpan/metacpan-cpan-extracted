#!/usr/bin/env perl
use v5.40;
use Params::Filter qw/filter/;

# Advanced Filtering Example: Complex combinations of required, accepted, excluded
# Demonstrates sophisticated filtering and filtering patterns

say "=== Advanced Filtering Patterns ===\n";

say "--- Pattern 1: Security Filtering ---\n";

# Remove sensitive fields from user input
my ($safe_user, $msg1) = filter(
    {
        username      => 'alice',
        email         => 'alice@example.com',
        password      => 'secret123',      # Excluded
        password_confirm => 'secret123',   # Excluded
        ssn           => '123-45-6789',    # Excluded
        credit_card   => '4111-1111-1111-1111',  # Excluded
        full_name     => 'Alice Johnson',
        phone         => '555-1234',
    },
    ['username', 'email'],                    # Required
    ['full_name', 'phone', 'bio'],            # Accepted
    ['password', 'password_confirm', 'ssn', 'credit_card', 'token'],  # Excluded
    1,  # Debug ON
);

say "Safe user data (sensitive fields removed):";
say "  $_: $safe_user->{$_}" for sort keys $safe_user->%*;
say "  Status: $msg1\n";

say "--- Pattern 2: Whitelisting with Exclusions ---\n";

# Accept specific fields but exclude dangerous ones
my ($filtered, $msg2) = filter(
    {
        id          => 42,
        name        => 'Product Name',
        price       => 29.99,
        description => 'A product',
        internal_id => 'SECRET-123',  # Excluded
        admin_notes => 'Internal use only',  # Excluded
        spam        => 'yes',  # Ignored (not in accepted)
    },
    ['id'],
    ['name', 'price', 'description', 'category', 'stock'],
    ['internal_id', 'admin_notes', 'cost', 'supplier'],
    1,
);

say "Whitelisted fields (non-whitelisted ignored, excluded removed):";
say "  $_: $filtered->{$_}" for sort keys $filtered->%*;
say "  Status: $msg2\n";

say "--- Pattern 3: API Request Filtering ---\n";

# API endpoint: create user with public and internal fields
my $api_filter = Params::Filter->new_filter({
    required => ['username', 'email'],
    accepted  => ['*'],  # Accept everything else
    excluded  => ['is_admin', 'role', 'permissions', 'banned'],  # Security-critical
    debug     => 1,
});

my ($api_result, $api_msg) = $api_filter->apply({
    username     => 'bob',
    email        => 'bob@example.com',
    full_name    => 'Bob Smith',
    bio          => 'Just a user',
    is_admin     => 1,        # Excluded (security!)
    role         => 'admin',  # Excluded
    permissions  => ['all'],  # Excluded
});

say "API request (security fields excluded):";
say "  $_: $api_result->{$_}" for sort keys $api_result->%*;
say "  Status: $api_msg\n";

say "--- Pattern 4: Multi-Layer Filtering ---\n";

# First layer: Strip sensitive fields
my ($layer1, $msg4a) = filter(
    {
        user_id     => 123,
        name        => 'Charlie',
        email       => 'charlie@example.com',
        password    => 'secret',  # Will be excluded
        ssn         => '123-45-6789',  # Will be excluded
        preferences => 'json-data',
        metadata    => 'more-data',
    },
    ['user_id', 'name'],
    ['*'],  # Accept all
    ['password', 'ssn', 'secret'],
);

# Second layer: Extract only specific fields from remaining
my ($layer2, $msg4b) = filter(
    $layer1,
    ['user_id'],
    ['name', 'email', 'preferences'],
    [],  # Nothing excluded (already done)
);

say "Multi-layer filtering:";
say "  Layer 1 (remove sensitive): " . join(', ', sort keys $layer1->%*);
say "  Layer 2 (select fields): " . join(', ', sort keys $layer2->%*);
say "  Final result: $_ => $layer2->{$_}" for sort keys $layer2->%*;
say "";

say "--- Pattern 5: Conditional Accept/Exclude ---\n";

# Simulate conditional filtering based on data type
sub filter_user_input {
    my ($input, $is_admin) = @_;

    my $rules = {
        required => ['user_id', 'username'],
        accepted => ['email', 'full_name'],
        excluded => [],
    };

    # Add admin-only fields if admin
    if ($is_admin) {
        push $rules->{accepted}->@*, 'role', 'permissions', 'notes';
    } else {
        push $rules->{excluded}->@*, 'role', 'permissions', 'admin_notes';
    }

    my $filter = Params::Filter->new_filter($rules);
    return $filter->apply($input);
}

my $admin_input = {
    user_id     => 1,
    username    => 'admin',
    email       => 'admin@example.com',
    full_name   => 'System Admin',
    role        => 'administrator',
    permissions => ['all'],
    notes       => 'System account',
};

my ($admin_result, $admin_msg) = filter_user_input($admin_input, 1);  # Admin
say "Admin user (gets role/permissions):";
say "  $_: $admin_result->{$_}" for sort keys $admin_result->%*;
say "";

my $regular_input = {
    user_id     => 2,
    username    => 'bob',
    email       => 'bob@example.com',
    full_name   => 'Bob User',
    role        => 'user',  # Will be excluded
    permissions => ['read'],  # Will be excluded
};

my ($user_result, $user_msg) = filter_user_input($regular_input, 0);  # Not admin
say "Regular user (role/permissions excluded):";
say "  $_: $user_result->{$_}" for sort keys $user_result->%*;
say "";

say "--- Pattern 6: Progressive Enrichment ---\n";

# Build up a data structure through multiple filterings
my $base_data = {
    id    => 42,
    name  => 'Product',
    price => 29.99,
};

my ($step1, $msg6a) = filter(
    $base_data,
    ['id'],
    ['name', 'price'],
);

# Add more fields
$step1->{category} = 'Electronics';
$step1->{stock}    = 100;
$step1->{internal} = 'secret';  # Will be excluded

my ($final, $msg6b) = filter(
    $step1,
    ['id', 'name'],
    ['price', 'category', 'stock'],
    ['internal', 'cost'],
);

say "Progressive enrichment:";
say "  Base: " . join(', ', sort keys $base_data->%*);
say "  Step 1: " . join(', ', sort keys $step1->%*);
say "  Final: " . join(', ', sort keys $final->%*);
say "";

say "--- Pattern 7: Field Renaming via Mapping ---\n";

# Strictly doesn't rename, but you can map after filtering
my ($raw, $msg7a) = filter(
    {
        fname    => 'Alice',
        lname    => 'Johnson',
        addr     => '123 Main St',
        phonenum => '555-1234',
    },
    [],
    ['*'],
);

# Map field names
my %field_map = (
    fname    => 'first_name',
    lname    => 'last_name',
    addr     => 'address',
    phonenum => 'phone',
);

my $mapped = {
    map { $field_map{$_} || $_ => $raw->{$_} }
    keys $raw->%*
};

say "Field mapping after filtering:";
say "  Original: " . join(', ', sort keys $raw->%*);
say "  Mapped: " . join(', ', sort keys $mapped->%*);
say "";
