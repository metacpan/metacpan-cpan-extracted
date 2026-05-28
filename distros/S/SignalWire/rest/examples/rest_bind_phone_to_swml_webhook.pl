#!/usr/bin/env perl
# Example: bind an inbound phone number to an SWML webhook (the happy path).
#
# This is the simplest way to route a SignalWire phone number to a backend
# that returns an SWML document per inbound call. You set `call_handler`
# on the phone number; the server auto-materializes a `swml_webhook`
# Fabric resource pointing at your URL. You do NOT need to create the
# Fabric webhook resource manually; you do NOT call assign_phone_route.
#
# Set these env vars:
#   SIGNALWIRE_PROJECT_ID   - your SignalWire project ID
#   SIGNALWIRE_API_TOKEN    - your SignalWire API token
#   SIGNALWIRE_SPACE        - your SignalWire space (e.g. example.signalwire.com)
#   PHONE_NUMBER_SID        - SID of a phone number you own (pn-...)
#   SWML_WEBHOOK_URL        - your backend's SWML endpoint

use strict;
use warnings;
use lib 'lib';
use SignalWire::REST::RestClient;
use SignalWire::REST::PhoneCallHandler;

my $pn_sid      = $ENV{PHONE_NUMBER_SID}     // die "Set PHONE_NUMBER_SID\n";
my $webhook_url = $ENV{SWML_WEBHOOK_URL}     // die "Set SWML_WEBHOOK_URL\n";

my $client = SignalWire::REST::RestClient->new(
    project => $ENV{SIGNALWIRE_PROJECT_ID} // die("Set SIGNALWIRE_PROJECT_ID\n"),
    token   => $ENV{SIGNALWIRE_API_TOKEN}  // die("Set SIGNALWIRE_API_TOKEN\n"),
    host    => $ENV{SIGNALWIRE_SPACE}      // die("Set SIGNALWIRE_SPACE\n"),
);

# The typed helper — one line:
print "Binding $pn_sid to $webhook_url ...\n";
$client->phone_numbers->set_swml_webhook($pn_sid, url => $webhook_url);

# The equivalent wire-level form (use this if you need unusual fields):
#
# $client->phone_numbers->update(
#     $pn_sid,
#     call_handler          => SignalWire::REST::PhoneCallHandler::RELAY_SCRIPT,
#     call_relay_script_url => $webhook_url,
# );

# Verify: the server auto-created a swml_webhook Fabric resource.
my $pn = $client->phone_numbers->get($pn_sid);
printf "  call_handler = %s\n",
    defined $pn->{call_handler} ? "'$pn->{call_handler}'" : 'undef';
printf "  call_relay_script_url = %s\n",
    defined $pn->{call_relay_script_url} ? "'$pn->{call_relay_script_url}'" : 'undef';
printf "  calling_handler_resource_id (server-derived) = %s\n",
    defined $pn->{calling_handler_resource_id} ? "'$pn->{calling_handler_resource_id}'" : 'undef';

# To route to something other than an SWML webhook, use:
#   $client->phone_numbers->set_cxml_webhook($sid, url => ...);        # LAML / Twilio-compat
#   $client->phone_numbers->set_ai_agent($sid, agent_id => ...);       # AI Agent
#   $client->phone_numbers->set_call_flow($sid, flow_id => ...);       # Call Flow
#   $client->phone_numbers->set_relay_application($sid, name => ...);  # Named RELAY app
#   $client->phone_numbers->set_relay_topic($sid, topic => ...);       # RELAY topic
