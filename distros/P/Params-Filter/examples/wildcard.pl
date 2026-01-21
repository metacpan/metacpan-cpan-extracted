#!/usr/bin/env perl
use v5.40;
use Params::Filter qw/filter/;

# Wildcard Example: Using '*' to accept all remaining fields
# Useful when you want required fields but allow any additional data

say "=== Wildcard: Accept Everything Except Exclusions ===\n";

# Example 1: Configuration filter
# Required: service_name, port
# Accept everything else except sensitive fields
my ($config, $status) = filter(
    {
        service_name   => 'api_server',
        port           => 8080,
        host           => 'localhost',
        max_connections => 100,
        timeout        => 30,
        debug_mode     => 1,
        api_key        => 'secret-key-123',  # Will be excluded
        admin_password => 'admin123',         # Will be excluded
    },
    ['service_name', 'port'],    # required
    ['*'],                         # wildcard: accept everything else
    ['api_key', 'admin_password', 'secret'],  # excluded (security sensitive)
);

say "Configuration filtering:";
say "  $_: $config->{$_}" for sort keys $config->%*;
say "  Status: $status\n";

say "=== Example 2: Logging with Wildcard ===\n";

# Log filter: require timestamp and level, accept any other log fields
my ($log_entry, $log_status) = filter(
    {
        timestamp => '2025-01-12T10:30:45Z',
        level     => 'ERROR',
        message   => 'Database connection failed',
        error_code => 500,
        user_id   => 42,
        request_id => 'abc-123',
        ip_address => '192.168.1.100',
    },
    ['timestamp', 'level'],    # required fields
    ['*'],                       # accept all other fields
    [],                          # nothing excluded
);

say "Log entry:";
say "  $_: $log_entry->{$_}" for sort keys $log_entry->%*;
say "  Status: $log_status\n";

say "=== Example 3: OO Interface with Wildcard ===\n";

my $flexible_filter = Params::Filter->new_filter({
    required => ['id'],
    accepted => ['*'],  # Accept any additional fields
    excluded => ['password', 'token', 'secret'],
});

my $record = {
    id        => 999,
    name      => 'Flexible Record',
    value     => 42,
    active    => 1,
    metadata  => 'any data here',
    token     => 'hidden-token',  # Excluded
};

my ($result, $msg) = $flexible_filter->apply($record);
say "Flexible filtering result:";
say "  $_: $result->{$_}" for sort keys $result->%*;
say "  Status: $msg\n";

say "=== Example 4: Wildcard + Specific Fields ===\n";

# You can combine wildcard with specific fields for documentation
my ($data, $status4) = filter(
    {
        user_id   => 123,
        name      => 'Test User',
        custom_field_1 => 'value1',
        custom_field_2 => 'value2',
        random_data => 999,
    },
    ['user_id'],                    # required
    ['name', 'email', 'phone', '*'], # explicit + wildcard (wildcard covers everything else)
    [],                              # nothing excluded
);

say "Result with explicit + wildcard:";
say "  $_: $data->{$_}" for sort keys $data->%*;
say "  Status: $status4";
