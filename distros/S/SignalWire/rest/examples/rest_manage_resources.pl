#!/usr/bin/env perl
# Example: Create an AI agent, assign a phone number, and place a test call.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::REST::RestClient;

my $client = SignalWire::REST::RestClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

sub safe {
    my ($label, $fn) = @_;
    my $result = eval { $fn->() };
    if ($@) {
        print "  $label: failed ($@)\n";
        return undef;
    }
    print "  $label: OK\n";
    return $result;
}

# 1. Create an AI agent
print "Creating AI agent...\n";
my $agent = $client->fabric->ai_agents->create(
    name   => 'Demo Support Bot',
    prompt => { text => 'You are a friendly support agent for Acme Corp.' },
);
my $agent_id = $agent->{id};
print "  Created agent: $agent_id\n";

# 2. List all AI agents
print "\nListing AI agents...\n";
my $agents = $client->fabric->ai_agents->list;
for my $a (@{ $agents->{data} // [] }) {
    print "  - $a->{id}: " . ($a->{name} // 'unnamed') . "\n";
}

# 3. Search for a phone number
print "\nSearching for available phone numbers...\n";
my $available = safe('Search numbers', sub {
    $client->phone_numbers->search(area_code => '512', max_results => 3);
});
if ($available) {
    for my $num (@{ $available->{data} // [] }) {
        print "  - " . ($num->{e164} // $num->{number} // 'unknown') . "\n";
    }
}

# 4. Place a test call (requires valid numbers)
print "\nPlacing a test call...\n";
safe('Dial', sub {
    $client->calling->dial(
        from_ => '+15559876543',
        to    => '+15551234567',
        url   => 'https://example.com/call-handler',
    );
});

# 5. Clean up
print "\nDeleting agent $agent_id...\n";
$client->fabric->ai_agents->delete($agent_id);
print "  Deleted.\n";
