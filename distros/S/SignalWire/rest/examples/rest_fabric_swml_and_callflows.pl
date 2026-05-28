#!/usr/bin/env perl
# Example: Deploy a voice application end-to-end with SWML and call flows.
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

# 1. Create a SWML script
print "Creating SWML script...\n";
my $swml = $client->fabric->swml_scripts->create(
    name     => 'Greeting Script',
    contents => {
        sections => {
            main => [{ play => { url => 'say:Hello from SignalWire' } }],
        },
    },
);
my $swml_id = $swml->{id};
print "  Created SWML script: $swml_id\n";

# 2. List SWML scripts
print "\nListing SWML scripts...\n";
my $scripts = $client->fabric->swml_scripts->list;
for my $s (@{ $scripts->{data} // [] }) {
    print "  - $s->{id}: " . ($s->{display_name} // 'unnamed') . "\n";
}

# 3. Create a call flow
print "\nCreating call flow...\n";
my $flow = $client->fabric->call_flows->create(title => 'Main IVR Flow');
my $flow_id = $flow->{id};
print "  Created call flow: $flow_id\n";

# 4. Deploy a version
print "\nDeploying call flow version...\n";
safe('Deploy version', sub {
    $client->fabric->call_flows->deploy_version($flow_id, label => 'v1');
});

# 5. List call flow versions
print "\nListing call flow versions...\n";
safe('List versions', sub {
    my $versions = $client->fabric->call_flows->list_versions($flow_id);
    for my $v (@{ $versions->{data} // [] }) {
        print "  - Version: " . ($v->{label} // $v->{id} // 'unknown') . "\n";
    }
});

# 6. List addresses for the call flow
print "\nListing call flow addresses...\n";
safe('List addresses', sub {
    my $addrs = $client->fabric->call_flows->list_addresses($flow_id);
    for my $a (@{ $addrs->{data} // [] }) {
        print "  - " . ($a->{display_name} // $a->{id} // 'unknown') . "\n";
    }
});

# 7. Create a SWML webhook
print "\nCreating SWML webhook...\n";
my $webhook = $client->fabric->swml_webhooks->create(
    name                => 'External Handler',
    primary_request_url => 'https://example.com/swml-handler',
);
my $webhook_id = $webhook->{id};
print "  Created webhook: $webhook_id\n";

# 8. Clean up
print "\nCleaning up...\n";
$client->fabric->swml_webhooks->delete($webhook_id);
print "  Deleted webhook $webhook_id\n";
$client->fabric->call_flows->delete($flow_id);
print "  Deleted call flow $flow_id\n";
$client->fabric->swml_scripts->delete($swml_id);
print "  Deleted SWML script $swml_id\n";
