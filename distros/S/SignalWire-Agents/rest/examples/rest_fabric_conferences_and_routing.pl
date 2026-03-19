#!/usr/bin/env perl
# Example: Conference infrastructure, cXML resources, generic routing, and tokens.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents::REST::SignalWireClient;

my $client = SignalWire::Agents::REST::SignalWireClient->new(
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

# 1. Create a conference room
print "Creating conference room...\n";
my $room = $client->fabric->conference_rooms->create(name => 'team-standup');
my $room_id = $room->{id};
print "  Created conference room: $room_id\n";

# 2. List conference room addresses
print "\nListing conference room addresses...\n";
safe('List addresses', sub {
    my $addrs = $client->fabric->conference_rooms->list_addresses($room_id);
    for my $a (@{ $addrs->{data} // [] }) {
        print "  - " . ($a->{display_name} // $a->{id} // 'unknown') . "\n";
    }
});

# 3. Create a cXML script
print "\nCreating cXML script...\n";
my $cxml = $client->fabric->cxml_scripts->create(
    name     => 'Hold Music Script',
    contents => '<Response><Say>Please hold.</Say><Play>https://example.com/hold.mp3</Play></Response>',
);
my $cxml_id = $cxml->{id};
print "  Created cXML script: $cxml_id\n";

# 4. Create a cXML webhook
print "\nCreating cXML webhook...\n";
my $cxml_wh = $client->fabric->cxml_webhooks->create(
    name                => 'External cXML Handler',
    primary_request_url => 'https://example.com/cxml-handler',
);
my $cxml_wh_id = $cxml_wh->{id};
print "  Created cXML webhook: $cxml_wh_id\n";

# 5. Create a relay application
print "\nCreating relay application...\n";
my $relay_app = $client->fabric->relay_applications->create(
    name  => 'Inbound Handler',
    topic => 'office',
);
my $relay_id = $relay_app->{id};
print "  Created relay application: $relay_id\n";

# 6. List all fabric resources
print "\nListing all fabric resources...\n";
my $resources = safe('List resources', sub { $client->fabric->resources->list });
if ($resources) {
    my @data = @{ $resources->{data} // [] };
    for my $r (@data[0 .. ($#data < 4 ? $#data : 4)]) {
        print "  - " . ($r->{type} // 'unknown') . ": "
            . ($r->{display_name} // $r->{id} // 'unknown') . "\n";
    }
}

# 7. Get a specific resource
if ($resources && $resources->{data} && @{ $resources->{data} }) {
    my $first = $resources->{data}[0];
    if ($first->{id}) {
        my $detail = safe('Get resource', sub { $client->fabric->resources->get($first->{id}) });
        if ($detail) {
            print "  Resource detail: " . ($detail->{display_name} // 'N/A')
                . " (" . ($detail->{type} // 'N/A') . ")\n";
        }
    }
}

# 8. Assign a phone route (demo)
print "\nAssigning phone route (demo)...\n";
safe('Phone route', sub {
    $client->fabric->resources->assign_phone_route($relay_id, phone_number => '+15551234567');
});

# 9. Assign a domain application (demo)
print "\nAssigning domain application (demo)...\n";
safe('Domain app', sub {
    $client->fabric->resources->assign_domain_application($relay_id, domain => 'app.example.com');
});

# 10. Generate tokens
print "\nGenerating tokens...\n";
safe('Guest token', sub {
    my $guest = $client->fabric->tokens->create_guest_token(resource_id => $relay_id);
    my $t = $guest->{token} // '';
    print "  Guest token: " . substr($t, 0, 40) . "...\n" if $t;
});
safe('Invite token', sub {
    my $invite = $client->fabric->tokens->create_invite_token(resource_id => $relay_id);
    my $t = $invite->{token} // '';
    print "  Invite token: " . substr($t, 0, 40) . "...\n" if $t;
});
safe('Embed token', sub {
    my $embed = $client->fabric->tokens->create_embed_token(resource_id => $relay_id);
    my $t = $embed->{token} // '';
    print "  Embed token: " . substr($t, 0, 40) . "...\n" if $t;
});

# 11. Clean up
print "\nCleaning up...\n";
$client->fabric->relay_applications->delete($relay_id);
print "  Deleted relay application $relay_id\n";
$client->fabric->cxml_webhooks->delete($cxml_wh_id);
print "  Deleted cXML webhook $cxml_wh_id\n";
$client->fabric->cxml_scripts->delete($cxml_id);
print "  Deleted cXML script $cxml_id\n";
$client->fabric->conference_rooms->delete($room_id);
print "  Deleted conference room $room_id\n";
