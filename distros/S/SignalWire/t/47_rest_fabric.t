#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::REST::RestClient;

my $client = SignalWire::REST::RestClient->new(
    project => 'p', token => 't', host => 'h',
);

# ============================================================
# 1. Fabric namespace
# ============================================================
subtest 'fabric namespace' => sub {
    my $f = $client->fabric;
    isa_ok($f, 'SignalWire::REST::Namespaces::Fabric');
};

# ============================================================
# 2. SWML scripts
# ============================================================
subtest 'swml_scripts' => sub {
    my $r = $client->fabric->swml_scripts;
    isa_ok($r, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
};

# ============================================================
# 3. Relay applications
# ============================================================
subtest 'relay_applications' => sub {
    my $r = $client->fabric->relay_applications;
    isa_ok($r, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
};

# ============================================================
# 4. Call flows with versions
# ============================================================
subtest 'call_flows' => sub {
    my $cf = $client->fabric->call_flows;
    isa_ok($cf, 'SignalWire::REST::Namespaces::Fabric::CallFlows');
    ok($cf->can('list_versions'), 'list_versions');
    ok($cf->can('deploy_version'), 'deploy_version');
};

# ============================================================
# 5. Conference rooms
# ============================================================
subtest 'conference_rooms' => sub {
    my $cr = $client->fabric->conference_rooms;
    isa_ok($cr, 'SignalWire::REST::Namespaces::Fabric::ConferenceRooms');
};

# ============================================================
# 6. Subscribers
# ============================================================
subtest 'subscribers' => sub {
    my $s = $client->fabric->subscribers;
    isa_ok($s, 'SignalWire::REST::Namespaces::Fabric::Subscribers');
    ok($s->can('list_sip_endpoints'), 'list_sip_endpoints');
    ok($s->can('create_sip_endpoint'), 'create_sip_endpoint');
};

# ============================================================
# 7. SIP endpoints
# ============================================================
subtest 'sip_endpoints' => sub {
    my $s = $client->fabric->sip_endpoints;
    isa_ok($s, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
};

# ============================================================
# 8. CXML resources
# ============================================================
subtest 'cxml resources' => sub {
    isa_ok($client->fabric->cxml_scripts, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
    my $ca = $client->fabric->cxml_applications;
    isa_ok($ca, 'SignalWire::REST::Namespaces::Fabric::CxmlApplications');
    eval { $ca->create(name => 'test') };
    like($@, qr/cannot be created/, 'cxml_applications create dies');
};

# ============================================================
# 9. Generic resources
# ============================================================
subtest 'generic resources' => sub {
    for my $r (qw(swml_webhooks ai_agents sip_gateways cxml_webhooks)) {
        isa_ok($client->fabric->$r, 'SignalWire::REST::Namespaces::Fabric::Resource');
    }
};

# ============================================================
# 9a. Auto-materialized webhook deprecation (phone-binding helpers)
# ============================================================
subtest 'swml_webhooks and cxml_webhooks use deprecated create subclass' => sub {
    # See phone-binding.md and t/52_rest_phone_binding.t for the full story.
    # The create() method on these classes carps a deprecation message
    # pointing at phone_numbers->set_swml_webhook / set_cxml_webhook.
    isa_ok($client->fabric->swml_webhooks,
        'SignalWire::REST::Namespaces::Fabric::SwmlWebhooks',
        'swml_webhooks is SwmlWebhooks (deprecated-create subclass)');
    isa_ok($client->fabric->cxml_webhooks,
        'SignalWire::REST::Namespaces::Fabric::CxmlWebhooks',
        'cxml_webhooks is CxmlWebhooks (deprecated-create subclass)');
};

# ============================================================
# 10. Addresses and tokens
# ============================================================
subtest 'addresses and tokens' => sub {
    isa_ok($client->fabric->addresses, 'SignalWire::REST::Namespaces::Fabric::Addresses');
    my $tokens = $client->fabric->tokens;
    isa_ok($tokens, 'SignalWire::REST::Namespaces::Fabric::Tokens');
    ok($tokens->can('create_subscriber_token'), 'subscriber token');
    ok($tokens->can('create_guest_token'), 'guest token');
    ok($tokens->can('create_embed_token'), 'embed token');
};

# ============================================================
# 11. Resources
# ============================================================
subtest 'resources' => sub {
    my $r = $client->fabric->resources;
    isa_ok($r, 'SignalWire::REST::Namespaces::Fabric::GenericResources');
};

done_testing;
