#!/usr/bin/env perl
use v5.40;
use Params::Filter;

# OO Interface Example: Using new_filter() and apply()
# Best for when you need to validate multiple datasets with the same rules

say "=== OO Interface: Reusable Filter ===\n";

# Create a filter once - defines the rules for what data is acceptable
# This configuration could come from a config file, database, etc.
my $user_filter = Params::Filter->new_filter({
    required => ['username', 'email'],
    accepted => ['full_name', 'phone', 'bio'],
    excluded => ['password', 'ssn', 'credit_card'],
});

say "Filter configured. Now processing incoming data...\n";

# Simulate incoming data from different sources
# In real use, these might come from:
# - Web form submissions
# - API requests
# - Database queries
# - File imports
# - User input

# Data source 1: Web form registration
my $user_form_data = {
    username   => 'alice123',
    email      => 'alice@example.com',
    full_name  => 'Alice Johnson',
    phone      => '555-1234',
    password   => 'secret123',  # Will be excluded!
    spam       => 'yes',        # Will be ignored!
};

say "Processing web form data...";
my ($data1, $msg1) = $user_filter->apply($user_form_data);
say "User 1:";
say "  $_: $data1->{$_}" for sort keys $data1->%*;
say "  Status: $msg1\n";

# Data source 2: API endpoint (minimal data)
my $api_user_data = {
    username => 'bob456',
    email    => 'bob@example.com',
};

say "Processing API data...";
my ($data2, $msg2) = $user_filter->apply($api_user_data);
say "User 2:";
say "  $_: $data2->{$_}" for sort keys $data2->%*;
say "  Status: $msg2\n";

# Data source 3: Another API request (missing required field)
my $incomplete_data = {
    username => 'charlie',
    # email is missing!
    full_name => 'Charlie Brown',
};

say "Processing incomplete data...";
my ($data3, $msg3) = $user_filter->apply($incomplete_data);
if ($data3) {
    say "User 3: Success";
} else {
    say "User 3: Validation failed";
    say "  Error: $msg3\n";
}

say "=== Creating Different Filters for Different Purposes ===\n";

# Different filter for a different use case
# Each filter encapsulates its own filtering rules
my $comment_filter = Params::Filter->new_filter({
    required => ['post_id', 'author_id'],
    accepted => ['comment_text', 'rating'],
    excluded => ['admin_notes', 'ip_address'],
});

# Incoming comment data from web request
my $web_comment_data = {
    post_id      => 42,
    author_id    => 17,
    comment_text => 'Great post!',
    rating       => 5,
    ip_address   => '192.168.1.1',  # Excluded for privacy
};

say "Processing comment submission...";
my ($comment_data, $comment_msg) = $comment_filter->apply($web_comment_data);
say "Comment filtering:";
say "  $_: $comment_data->{$_}" for sort keys $comment_data->%*;
say "  Status: $comment_msg";

