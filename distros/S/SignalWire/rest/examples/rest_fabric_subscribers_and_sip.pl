#!/usr/bin/env perl
# Example: Provision a SIP-enabled user on Fabric.
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

# 1. Create a subscriber
print "Creating subscriber...\n";
my $subscriber = $client->fabric->subscribers->create(
    name  => 'Alice Johnson',
    email => 'alice@example.com',
);
my $sub_id       = $subscriber->{id};
my $inner_sub_id = ($subscriber->{subscriber} // {})->{id} // $sub_id;
print "  Created subscriber: $sub_id\n";

# 2. Add a SIP endpoint
print "\nCreating SIP endpoint on subscriber...\n";
my $endpoint = $client->fabric->subscribers->create_sip_endpoint(
    $sub_id,
    username => 'alice_sip',
    password => 'SecurePass123!',
);
my $ep_id = $endpoint->{id};
print "  Created SIP endpoint: $ep_id\n";

# 3. List SIP endpoints
print "\nListing subscriber SIP endpoints...\n";
my $endpoints = $client->fabric->subscribers->list_sip_endpoints($sub_id);
for my $ep (@{ $endpoints->{data} // [] }) {
    print "  - $ep->{id}: " . ($ep->{username} // 'unknown') . "\n";
}

# 4. Get specific endpoint details
print "\nGetting SIP endpoint $ep_id...\n";
my $ep_detail = $client->fabric->subscribers->get_sip_endpoint($sub_id, $ep_id);
print "  Username: " . ($ep_detail->{username} // 'N/A') . "\n";

# 5. Create a standalone SIP gateway
print "\nCreating SIP gateway...\n";
my $gateway = $client->fabric->sip_gateways->create(
    name       => 'Office PBX Gateway',
    uri        => 'sip:pbx.example.com',
    encryption => 'required',
    ciphers    => ['AES_256_CM_HMAC_SHA1_80'],
    codecs     => ['PCMU', 'PCMA'],
);
my $gw_id = $gateway->{id};
print "  Created SIP gateway: $gw_id\n";

# 6. List fabric addresses
print "\nListing fabric addresses...\n";
safe('List addresses', sub {
    my $addresses = $client->fabric->addresses->list;
    my @data = @{ $addresses->{data} // [] };
    for my $addr (@data[0 .. ($#data < 4 ? $#data : 4)]) {
        print "  - " . ($addr->{display_name} // $addr->{id} // 'unknown') . "\n";
    }

    # 7. Get a specific address
    if (@data && $data[0]{id}) {
        my $addr_detail = $client->fabric->addresses->get($data[0]{id});
        print "  Address detail: " . ($addr_detail->{display_name} // 'N/A') . "\n";
    }
});

# 8. Generate a subscriber token
print "\nGenerating subscriber token...\n";
safe('Subscriber token', sub {
    my $token = $client->fabric->tokens->create_subscriber_token(
        subscriber_id => $inner_sub_id,
        reference     => $inner_sub_id,
    );
    my $t = $token->{token} // '';
    print "  Token: " . substr($t, 0, 40) . "...\n" if $t;
});

# 9. Clean up
print "\nCleaning up...\n";
$client->fabric->subscribers->delete_sip_endpoint($sub_id, $ep_id);
print "  Deleted SIP endpoint $ep_id\n";
$client->fabric->subscribers->delete($sub_id);
print "  Deleted subscriber $sub_id\n";
$client->fabric->sip_gateways->delete($gw_id);
print "  Deleted SIP gateway $gw_id\n";
