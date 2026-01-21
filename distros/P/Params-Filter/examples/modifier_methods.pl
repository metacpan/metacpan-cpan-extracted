#!/usr/bin/env perl

use strict;
use warnings;
use Params::Filter;

# Example: Using Modifier Methods for Dynamic Configuration

print "=" x 60 . "\n";
print "Example 1: Starting with empty filter, adding constraints\n";
print "=" x 60 . "\n\n";

# Create an empty filter (rejects all by default)
my $filter = Params::Filter->new_filter();

print "Initial state: No fields configured (reject all)\n";
my ($result1, $msg1) = $filter->apply({ name => 'Alice', email => 'alice@example.com' });
print "Result: " . (scalar keys %$result1 ? "Unexpected" : "Empty (expected)") . "\n";
print "Fields: " . join(', ', keys %$result1) . "\n\n";

# Now configure it step by step
$filter->set_required(['id'])
          ->set_accepted(['name', 'email']);

print "After adding required=['id'], accepted=['name', 'email']:\n";
my ($result2, $msg2) = $filter->apply({
    id    => 1,
    name  => 'Bob',
    email => 'bob@example.com',
    extra => 'ignored',
});

print "Status: $msg2\n";
print "Fields: " . join(', ', sort keys %$result2) . "\n";
print "Values: id=$result2->{id}, name=$result2->{name}\n\n";

print "-" x 60 . "\n\n";

print "=" x 60 . "\n";
print "Example 2: Method chaining for one-liner configuration\n";
print "=" x 60 . "\n\n";

my $quick_filter = Params::Filter->new_filter()
    ->set_required(['user_id'])
    ->set_accepted(['username', 'role'])
    ->set_excluded(['password']);

# Simulate incoming API request data
my $api_request_data = {
    user_id  => 42,
    username => 'charlie',
    role     => 'admin',
    password => 'secret123',
    extra    => 'ignored',
};

my ($result3) = $quick_filter->apply($api_request_data);

print "Quick filter result:\n";
print "  user_id: $result3->{user_id}\n";
print "  username: $result3->{username}\n";
print "  role: $result3->{role}\n";
print "  password: " . (exists $result3->{password} ? "present (BAD!)" : "removed (GOOD)") . "\n\n";

print "-" x 60 . "\n\n";

print "=" x 60 . "\n";
print "Example 3: accept_all() and accept_none() convenience methods\n";
print "=" x 60 . "\n\n";

# Strict filter (only required fields)
my $strict = Params::Filter->new_filter()
    ->set_required(['api_key'])
    ->accept_none();

print "Strict filter (only required fields):\n";
my ($strict_result) = $strict->apply({
    api_key => 'xyz789',
    name    => 'Test',
    debug   => 1,
});
print "  Fields: " . join(', ', keys %$strict_result) . "\n";
print "  Extra fields removed: " . (!exists $strict_result->{debug} ? "yes" : "no") . "\n\n";

# Permissive filter (required + anything else)
my $permissive = Params::Filter->new_filter()
    ->set_required(['session_id'])
    ->accept_all();

print "Permissive filter (accept all additional fields):\n";
my ($perm_result) = $permissive->apply({
    session_id => 'abc123',
    user_agent => 'Mozilla',
    ip_address => '192.168.1.1',
    timestamp  => time,
});
print "  Fields: " . join(', ', sort keys %$perm_result) . "\n";
print "  All additional fields kept\n\n";

print "-" x 60 . "\n\n";

print "=" x 60 . "\n";
print "Example 4: Conditional configuration based on environment\n";
print "=" x 60 . "\n\n";

my $environment = 'production';  # Try changing to 'development'
my $env_filter = Params::Filter->new_filter();

if ($environment eq 'production') {
    $env_filter->set_required(['api_key', 'endpoint'])
                   ->set_accepted(['timeout', 'retries'])
                   ->set_excluded(['debug_info', 'test_mode']);
    print "Production mode: Strict, no debug fields\n";
}
else {
    $env_filter->set_required(['debug_mode'])
                   ->accept_all();
    print "Development mode: Permissive, accept all fields\n";
}

my $test_input = {
    debug_mode => 1,
    verbose    => 1,
    trace      => 1,
    api_key    => 'prod_key',
    endpoint   => 'https://api.example.com',
    debug_info => 'should be excluded in prod',
};

my ($env_result) = $env_filter->apply($test_input);

print "Input fields: " . join(', ', sort keys %$test_input) . "\n";
print "Result fields: " . join(', ', sort keys %$env_result) . "\n";
if ($environment eq 'production') {
    print "Debug info excluded: " . (!exists $env_result->{debug_info} ? "yes" : "no") . "\n";
}
print "\n";

print "-" x 60 . "\n\n";

print "=" x 60 . "\n";
print "Example 5: Meta-programming with configuration data\n";
print "=" x 60 . "\n\n";

# Configuration could come from JSON, YAML, database, etc.
my $field_config = {
    user_profile => {
        required => ['user_id', 'username'],
        accepted => ['email', 'bio', 'website'],
        excluded => ['password', 'ssn', 'credit_card'],
    },
    system_config => {
        required => ['config_id'],
        accepted => ['*'],  # Wildcard for all other fields
        excluded => [],
    },
};

sub create_filter {
    my ($config_name) = @_;
    my $config = $field_config->{$config_name};

    return Params::Filter->new_filter()
        ->set_required($config->{required})
        ->set_accepted($config->{accepted})
        ->set_excluded($config->{excluded});
}

print "Creating filters from configuration data:\n\n";

my $profile_filter = create_filter('user_profile');
print "User profile filter:\n";

# Simulate user profile data from database or API
my $user_profile_data = {
    user_id    => 123,
    username   => 'alice',
    email      => 'alice@example.com',
    bio        => 'Developer',
    password   => 'secret123',  # Should be excluded
    ssn        => '123-45-6789', # Should be excluded
};

my ($profile) = $profile_filter->apply($user_profile_data);
print "  Accepted: " . join(', ', sort keys %$profile) . "\n";
print "  Password excluded: " . (!exists $profile->{password} ? "yes" : "no") . "\n";
print "  SSN excluded: " . (!exists $profile->{ssn} ? "yes" : "no") . "\n\n";

my $config_filter = create_filter('system_config');
print "System config filter (wildcard mode):\n";

# Simulate config data from file or environment
my $system_config_data = {
    config_id => 'main',
    host      => 'db.example.com',
    port      => 5432,
    database  => 'production',
    ssl       => 1,
    pool_size => 20,
};

my ($config) = $config_filter->apply($system_config_data);
print "  Accepted: " . join(', ', sort keys %$config) . "\n";
print "  All fields passed through (wildcard mode)\n\n";

print "-" x 60 . "\n\n";

print "=" x 60 . "\n";
print "Example 6: Progressive configuration building\n";
print "=" x 60 . "\n\n";

my $builder = Params::Filter->new_filter();

print "Step 1: Start with basic requirements\n";
$builder->set_required(['id']);
my ($step1) = $builder->apply({ id => 1, name => 'Test' });
print "  Fields after step 1: " . join(', ', keys %$step1) . "\n\n";

print "Step 2: Add accepted fields\n";
$builder->set_accepted(['name', 'value']);
my ($step2) = $builder->apply({ id => 2, name => 'Test', value => 42 });
print "  Fields after step 2: " . join(', ', keys %$step2) . "\n\n";

print "Step 3: Add exclusions\n";
$builder->set_excluded(['temp', 'cache']);
my ($step3) = $builder->apply({
    id    => 3,
    name  => 'Progressive',
    value => 100,
    temp  => 'should_be_removed',
    cache => 'also_removed',
});
print "  Fields after step 3: " . join(', ', keys %$step3) . "\n";
print "  Temp excluded: " . (!exists $step3->{temp} ? "yes" : "no") . "\n";
print "  Cache excluded: " . (!exists $step3->{cache} ? "yes" : "no") . "\n\n";

print "-" x 60 . "\n\n";

print "=" x 60 . "\n";
print "Example 7: Dynamic field lists from user input\n";
print "=" x 60 . "\n\n";

# Simulating user-defined field selections
my $user_selection = {
    required => [qw/product_id name/],
    optional => [qw/description price category/],
    exclude  => [qw/internal_id temp_flag/],
};

my $dynamic_filter = Params::Filter->new_filter()
    ->set_required($user_selection->{required})
    ->set_accepted($user_selection->{optional})
    ->set_excluded($user_selection->{exclude});

print "Dynamic filter from user selection:\n";
my ($product) = $dynamic_filter->apply({
    product_id   => 'SKU-123',
    name         => 'Widget',
    description  => 'A useful widget',
    price        => 29.99,
    category     => 'Hardware',
    internal_id  => 999,    # Should be excluded
    temp_flag    => 1,      # Should be excluded
});

print "  Product fields: " . join(', ', sort keys %$product) . "\n";
print "  Internal excluded: " . (!exists $product->{internal_id} ? "yes" : "no") . "\n";
print "  Temp flag excluded: " . (!exists $product->{temp_flag} ? "yes" : "no") . "\n\n";

print "-" x 60 . "\n\n";

print "=" x 60 . "\n";
print "Summary: Modifier methods enable flexible, dynamic configuration\n";
print "of Filter objects for meta-programming and conditional scenarios.\n";
print "=" x 60 . "\n";
