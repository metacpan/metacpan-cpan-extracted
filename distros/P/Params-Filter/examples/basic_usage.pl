#!/usr/bin/env perl
use v5.40;
use Params::Filter qw/filter/;

# Basic usage example: Simple form filtering
# Demonstrates required + accepted fields

say "=== Basic Form Filtering ===\n";

# Define the filtering rules once
# These could be defined in a config file or constants
my @required_fields = qw(name email);
my @accepted_fields = qw(phone city state zip);

# Simulate incoming form data from web submission
# In real use, this might come from:
# - CGI.pm or Plack request parameters
# - JSON from API request
# - Form processing library
my $incoming_form_data = {
    name  => 'Alice Johnson',
    email => 'alice@example.com',
    phone => '555-1234',
    city  => 'San Francisco',
    spam  => 'yes',  # This will be ignored (not in accepted)
};

# Apply the filter to the incoming data
my ($user_data, $status) = filter(
    $incoming_form_data,
    \@required_fields,
    \@accepted_fields,
);

say "Result:";
say "  Status: $status";
say "  Data:";
say "    $_: $user_data->{$_}" for sort keys $user_data->%*;

say "\n=== Example 2: Only Required Fields ===\n";

# Simulate another incoming request with minimal data
my $minimal_request_data = {
    name  => 'Bob Smith',
    email => 'bob@example.com',
};

my ($minimal_data, $status2) = filter(
    $minimal_request_data,
    ['name', 'email'],    # required only
    [],                   # no accepted fields
);

say "Result:";
say "  Status: $status2";
say "  Data:";
say "    $_: $minimal_data->{$_}" for sort keys $minimal_data->%*;

say "\n=== Example 3: Missing Required Field ===\n";

# Simulate incomplete incoming data (malformed request)
my $incomplete_request_data = {
    name  => 'Charlie',
    # email is missing!
    phone => '555-5678',
};

my ($bad_data, $status3) = filter(
    $incomplete_request_data,
    ['name', 'email'],    # both required
    ['phone'],
);

if ($bad_data) {
    say "Success!";
} else {
    say "Validation failed: $status3";
}

