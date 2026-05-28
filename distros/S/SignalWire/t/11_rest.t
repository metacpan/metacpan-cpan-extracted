#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# ===== HttpClient =====
use_ok('SignalWire::REST::HttpClient');

# HttpClient construction
{
    my $http = SignalWire::REST::HttpClient->new(
        project => 'proj-123',
        token   => 'tok-abc',
        host    => 'example.signalwire.com',
    );
    is($http->project, 'proj-123', 'http project');
    is($http->token, 'tok-abc', 'http token');
    is($http->host, 'example.signalwire.com', 'http host');
    is($http->base_url, 'https://example.signalwire.com', 'base_url built');
}

# Auth header
{
    my $http = SignalWire::REST::HttpClient->new(
        project => 'user',
        token   => 'pass',
        host    => 'test.host',
    );
    use MIME::Base64 qw(encode_base64);
    my $expected = 'Basic ' . encode_base64('user:pass', '');
    is($http->_auth_header, $expected, 'auth header correct');
}

# HttpClient Error class
{
    my $err = SignalWire::REST::HttpClient::Error->new(
        status_code => 404,
        body        => 'Not Found',
        url         => '/api/test',
        method      => 'GET',
    );
    is($err->status_code, 404, 'error status_code');
    is($err->url, '/api/test', 'error url');
    is($err->method, 'GET', 'error method');
    like("$err", qr/GET.*404.*Not Found/, 'error stringification');
}

# HttpClient Error with hash body
{
    my $err = SignalWire::REST::HttpClient::Error->new(
        status_code => 422,
        body        => { errors => ['invalid'] },
        url         => '/api/resource',
        method      => 'POST',
    );
    like("$err", qr/POST.*422/, 'error with hash body stringifies');
}

# HttpClient has all HTTP methods
{
    my $http = SignalWire::REST::HttpClient->new(
        project => 'p', token => 't', host => 'h',
    );
    ok($http->can('get'), 'has get');
    ok($http->can('post'), 'has post');
    ok($http->can('put'), 'has put');
    ok($http->can('patch'), 'has patch');
    ok($http->can('delete_request'), 'has delete_request');
}

# ===== Base namespace =====
use_ok('SignalWire::REST::Namespaces::Base');

# Base construction
{
    my $http_mock = bless {}, 'MockHttp';
    my $base = SignalWire::REST::Namespaces::Base->new(
        _http      => $http_mock,
        _base_path => '/api/test',
    );
    is($base->_base_path, '/api/test', 'base_path set');
    is($base->_path('foo', 'bar'), '/api/test/foo/bar', '_path joins correctly');
}

# CrudResource construction
{
    my $http_mock = bless {}, 'MockHttp';
    my $crud = SignalWire::REST::Namespaces::CrudResource->new(
        _http      => $http_mock,
        _base_path => '/api/crud',
    );
    is($crud->_update_method, 'PATCH', 'default update method is PATCH');
    ok($crud->can('list'), 'has list');
    ok($crud->can('create'), 'has create');
    ok($crud->can('get'), 'has get');
    ok($crud->can('update'), 'has update');
    ok($crud->can('delete_resource'), 'has delete_resource');
}

# ===== RestClient =====
use_ok('SignalWire::REST::RestClient');

# Client construction
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'proj-test',
        token   => 'tok-test',
        host    => 'test.signalwire.com',
    );
    is($client->project, 'proj-test', 'client project');
    is($client->token, 'tok-test', 'client token');
    is($client->host, 'test.signalwire.com', 'client host');
}

# Client _http is lazily built
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $http = $client->_http;
    isa_ok($http, 'SignalWire::REST::HttpClient');
    is($http->project, 'p', '_http has correct project');
}

# All 21 namespaces are accessible
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );

    # Fabric
    my $fabric = $client->fabric;
    isa_ok($fabric, 'SignalWire::REST::Namespaces::Fabric');

    # Calling
    my $calling = $client->calling;
    isa_ok($calling, 'SignalWire::REST::Namespaces::Calling');

    # Phone numbers
    my $pn = $client->phone_numbers;
    isa_ok($pn, 'SignalWire::REST::Namespaces::PhoneNumbers');

    # Addresses
    my $addr = $client->addresses;
    isa_ok($addr, 'SignalWire::REST::Namespaces::Addresses');

    # Queues
    my $q = $client->queues;
    isa_ok($q, 'SignalWire::REST::Namespaces::Queues');

    # Recordings
    my $rec = $client->recordings;
    isa_ok($rec, 'SignalWire::REST::Namespaces::Recordings');

    # Number groups
    my $ng = $client->number_groups;
    isa_ok($ng, 'SignalWire::REST::Namespaces::NumberGroups');

    # Verified callers
    my $vc = $client->verified_callers;
    isa_ok($vc, 'SignalWire::REST::Namespaces::VerifiedCallers');

    # SIP profile
    my $sip = $client->sip_profile;
    isa_ok($sip, 'SignalWire::REST::Namespaces::SipProfile');

    # Lookup
    my $lu = $client->lookup;
    isa_ok($lu, 'SignalWire::REST::Namespaces::Lookup');

    # Short codes
    my $sc = $client->short_codes;
    isa_ok($sc, 'SignalWire::REST::Namespaces::ShortCodes');

    # Imported numbers
    my $in = $client->imported_numbers;
    isa_ok($in, 'SignalWire::REST::Namespaces::ImportedNumbers');

    # MFA
    my $mfa = $client->mfa;
    isa_ok($mfa, 'SignalWire::REST::Namespaces::MFA');

    # Registry
    my $reg = $client->registry;
    isa_ok($reg, 'SignalWire::REST::Namespaces::Registry');

    # Datasphere
    my $ds = $client->datasphere;
    isa_ok($ds, 'SignalWire::REST::Namespaces::Datasphere');

    # Video
    my $vid = $client->video;
    isa_ok($vid, 'SignalWire::REST::Namespaces::Video');

    # Logs
    my $logs = $client->logs;
    isa_ok($logs, 'SignalWire::REST::Namespaces::Logs');

    # Project
    my $proj = $client->project_ns;
    isa_ok($proj, 'SignalWire::REST::Namespaces::Project');

    # PubSub
    my $ps = $client->pubsub;
    isa_ok($ps, 'SignalWire::REST::Namespaces::PubSub');

    # Chat
    my $chat = $client->chat;
    isa_ok($chat, 'SignalWire::REST::Namespaces::Chat');

    # Compat
    my $compat = $client->compat;
    isa_ok($compat, 'SignalWire::REST::Namespaces::Compat');
}

# ===== Fabric Namespace sub-objects =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $f = $client->fabric;

    # All fabric sub-resources
    isa_ok($f->swml_scripts, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
    isa_ok($f->relay_applications, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
    isa_ok($f->call_flows, 'SignalWire::REST::Namespaces::Fabric::CallFlows');
    isa_ok($f->conference_rooms, 'SignalWire::REST::Namespaces::Fabric::ConferenceRooms');
    isa_ok($f->freeswitch_connectors, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
    isa_ok($f->subscribers, 'SignalWire::REST::Namespaces::Fabric::Subscribers');
    isa_ok($f->sip_endpoints, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
    isa_ok($f->cxml_scripts, 'SignalWire::REST::Namespaces::Fabric::ResourcePUT');
    isa_ok($f->cxml_applications, 'SignalWire::REST::Namespaces::Fabric::CxmlApplications');
    isa_ok($f->swml_webhooks, 'SignalWire::REST::Namespaces::Fabric::Resource');
    isa_ok($f->ai_agents, 'SignalWire::REST::Namespaces::Fabric::Resource');
    isa_ok($f->sip_gateways, 'SignalWire::REST::Namespaces::Fabric::Resource');
    isa_ok($f->cxml_webhooks, 'SignalWire::REST::Namespaces::Fabric::Resource');
    isa_ok($f->resources, 'SignalWire::REST::Namespaces::Fabric::GenericResources');
    isa_ok($f->addresses, 'SignalWire::REST::Namespaces::Fabric::Addresses');
    isa_ok($f->tokens, 'SignalWire::REST::Namespaces::Fabric::Tokens');

    # CallFlows has version methods
    ok($f->call_flows->can('list_versions'), 'call_flows has list_versions');
    ok($f->call_flows->can('deploy_version'), 'call_flows has deploy_version');

    # Subscribers has SIP endpoint methods
    ok($f->subscribers->can('list_sip_endpoints'), 'subscribers has list_sip_endpoints');
    ok($f->subscribers->can('create_sip_endpoint'), 'subscribers has create_sip_endpoint');

    # CxmlApplications create dies
    eval { $f->cxml_applications->create(name => 'test') };
    like($@, qr/cannot be created/, 'cxml_applications create dies');

    # Tokens has methods
    ok($f->tokens->can('create_subscriber_token'), 'tokens has create_subscriber_token');
    ok($f->tokens->can('create_guest_token'), 'tokens has create_guest_token');
    ok($f->tokens->can('create_embed_token'), 'tokens has create_embed_token');
}

# ===== Calling Namespace =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $c = $client->calling;

    # Has all command methods
    my @methods = qw(
        dial update_call end transfer disconnect
        play play_pause play_resume play_stop play_volume
        record record_pause record_resume record_stop
        collect collect_stop collect_start_input_timers
        detect detect_stop
        tap tap_stop
        stream stream_stop
        denoise denoise_stop
        transcribe transcribe_stop
        ai_message ai_hold ai_unhold ai_stop
        live_transcribe live_translate
        send_fax_stop receive_fax_stop
        refer user_event
    );
    for my $method (@methods) {
        ok($c->can($method), "calling has method: $method");
    }
}

# ===== Datasphere Namespace =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $ds = $client->datasphere;
    isa_ok($ds->documents, 'SignalWire::REST::Namespaces::Datasphere::Documents');
    ok($ds->documents->can('search'), 'documents has search');
    ok($ds->documents->can('list_chunks'), 'documents has list_chunks');
    ok($ds->documents->can('get_chunk'), 'documents has get_chunk');
    ok($ds->documents->can('delete_chunk'), 'documents has delete_chunk');
}

# ===== Video Namespace =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $v = $client->video;

    isa_ok($v->rooms, 'SignalWire::REST::Namespaces::Video::Rooms');
    isa_ok($v->room_tokens, 'SignalWire::REST::Namespaces::Video::RoomTokens');
    isa_ok($v->room_sessions, 'SignalWire::REST::Namespaces::Video::RoomSessions');
    isa_ok($v->room_recordings, 'SignalWire::REST::Namespaces::Video::RoomRecordings');
    isa_ok($v->conferences, 'SignalWire::REST::Namespaces::Video::Conferences');
    isa_ok($v->conference_tokens, 'SignalWire::REST::Namespaces::Video::ConferenceTokens');
    isa_ok($v->streams, 'SignalWire::REST::Namespaces::Video::Streams');

    ok($v->rooms->can('list_streams'), 'rooms has list_streams');
    ok($v->rooms->can('create_stream'), 'rooms has create_stream');
    ok($v->room_sessions->can('list_events'), 'room_sessions has list_events');
    ok($v->room_sessions->can('list_members'), 'room_sessions has list_members');
}

# ===== Compat Namespace =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $c = $client->compat;
    is($c->account_sid, 'p', 'compat uses project as account_sid');

    isa_ok($c->accounts, 'SignalWire::REST::Namespaces::Compat::Accounts');
    isa_ok($c->calls, 'SignalWire::REST::Namespaces::Compat::Calls');
    isa_ok($c->messages, 'SignalWire::REST::Namespaces::Compat::Messages');
    isa_ok($c->faxes, 'SignalWire::REST::Namespaces::Compat::Faxes');
    isa_ok($c->conferences, 'SignalWire::REST::Namespaces::Compat::Conferences');
    isa_ok($c->phone_numbers, 'SignalWire::REST::Namespaces::Compat::PhoneNumbers');
    isa_ok($c->applications, 'SignalWire::REST::Namespaces::Compat::Applications');
    isa_ok($c->laml_bins, 'SignalWire::REST::Namespaces::Compat::LamlBins');
    isa_ok($c->queues, 'SignalWire::REST::Namespaces::Compat::Queues');
    isa_ok($c->recordings, 'SignalWire::REST::Namespaces::Compat::Recordings');
    isa_ok($c->transcriptions, 'SignalWire::REST::Namespaces::Compat::Transcriptions');
    isa_ok($c->tokens, 'SignalWire::REST::Namespaces::Compat::Tokens');

    # Call sub-resources
    ok($c->calls->can('start_recording'), 'compat calls has start_recording');
    ok($c->calls->can('start_stream'), 'compat calls has start_stream');

    # Message sub-resources
    ok($c->messages->can('list_media'), 'compat messages has list_media');

    # Conference sub-resources
    ok($c->conferences->can('list_participants'), 'compat conferences has list_participants');
    ok($c->conferences->can('list_recordings'), 'compat conferences has list_recordings');

    # Phone numbers
    ok($c->phone_numbers->can('search_local'), 'compat phone_numbers has search_local');
    ok($c->phone_numbers->can('search_toll_free'), 'compat phone_numbers has search_toll_free');
    ok($c->phone_numbers->can('import_number'), 'compat phone_numbers has import_number');

    # Queues
    ok($c->queues->can('list_members'), 'compat queues has list_members');
    ok($c->queues->can('dequeue_member'), 'compat queues has dequeue_member');
}

# ===== Registry Namespace =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $r = $client->registry;

    isa_ok($r->brands, 'SignalWire::REST::Namespaces::Registry::Brands');
    isa_ok($r->campaigns, 'SignalWire::REST::Namespaces::Registry::Campaigns');
    isa_ok($r->orders, 'SignalWire::REST::Namespaces::Registry::Orders');
    isa_ok($r->numbers, 'SignalWire::REST::Namespaces::Registry::Numbers');

    ok($r->brands->can('list_campaigns'), 'brands has list_campaigns');
    ok($r->brands->can('create_campaign'), 'brands has create_campaign');
    ok($r->campaigns->can('list_orders'), 'campaigns has list_orders');
    ok($r->campaigns->can('create_order'), 'campaigns has create_order');
}

# ===== Logs Namespace =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $l = $client->logs;

    isa_ok($l->messages, 'SignalWire::REST::Namespaces::Logs::Messages');
    isa_ok($l->voice, 'SignalWire::REST::Namespaces::Logs::Voice');
    isa_ok($l->fax, 'SignalWire::REST::Namespaces::Logs::Fax');
    isa_ok($l->conferences, 'SignalWire::REST::Namespaces::Logs::Conferences');

    ok($l->voice->can('list_events'), 'voice logs has list_events');
}

# ===== Project Namespace =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    my $p = $client->project_ns;
    isa_ok($p->tokens, 'SignalWire::REST::Namespaces::Project::Tokens');
    ok($p->tokens->can('create'), 'project tokens has create');
    ok($p->tokens->can('update'), 'project tokens has update');
    ok($p->tokens->can('delete_token'), 'project tokens has delete_token');
}

# ===== PubSub and Chat =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );
    ok($client->pubsub->can('create_token'), 'pubsub has create_token');
    ok($client->chat->can('create_token'), 'chat has create_token');
}

# ===== Relay REST Resources =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );

    # PhoneNumbers has search
    ok($client->phone_numbers->can('search'), 'phone_numbers has search');

    # Queues has member methods
    ok($client->queues->can('list_members'), 'queues has list_members');
    ok($client->queues->can('get_next_member'), 'queues has get_next_member');

    # NumberGroups has membership
    ok($client->number_groups->can('list_memberships'), 'number_groups has list_memberships');

    # VerifiedCallers has verification flow
    ok($client->verified_callers->can('redial_verification'), 'verified_callers has redial_verification');
    ok($client->verified_callers->can('submit_verification'), 'verified_callers has submit_verification');

    # SipProfile singleton
    ok($client->sip_profile->can('get'), 'sip_profile has get');
    ok($client->sip_profile->can('update'), 'sip_profile has update');

    # Lookup
    ok($client->lookup->can('phone_number'), 'lookup has phone_number');

    # MFA
    ok($client->mfa->can('sms'), 'mfa has sms');
    ok($client->mfa->can('call'), 'mfa has call');
    ok($client->mfa->can('verify'), 'mfa has verify');

    # ImportedNumbers
    ok($client->imported_numbers->can('create'), 'imported_numbers has create');
}

# ===== Base path verification =====
{
    my $client = SignalWire::REST::RestClient->new(
        project => 'p', token => 't', host => 'h',
    );

    # Spot-check key base paths
    is($client->calling->_base_path, '/api/calling/calls', 'calling base path');
    is($client->phone_numbers->_base_path, '/api/relay/rest/phone_numbers', 'phone_numbers base path');
    is($client->pubsub->_base_path, '/api/pubsub/tokens', 'pubsub base path');
    is($client->chat->_base_path, '/api/chat/tokens', 'chat base path');
}

done_testing();

# Minimal mock for tests that don't call HTTP
package MockHttp;
sub new { bless {}, shift }

1;
