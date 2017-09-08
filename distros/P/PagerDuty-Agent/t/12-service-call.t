#!/usr/bin/env perl -T

use strict;
use warnings;

use HTTP::Response;
use PagerDuty::Agent;
use Test::LWP::UserAgent;
use Test::More;

my $ua = Test::LWP::UserAgent->new();
$ua->map_response(
    qr//,
    HTTP::Response->new(
        '202',
        undef,
        undef,
        '{ "dedup_key": "my dedup_key" }',
    ),
);

subtest 'keep_alive' => sub {
    ok(PagerDuty::Agent->new(routing_key => '123')->ua_obj()->conn_cache());
};

subtest 'timeout' => sub {
    my $agent = PagerDuty::Agent->new(routing_key => '123', ua_obj => $ua, timeout => 10);
    $agent->trigger_event('HELO');

    is($ua->last_useragent()->timeout(), 10);
};

subtest 'headers' => sub {
    my $agent = PagerDuty::Agent->new(routing_key => '123', ua_obj => $ua);

    my $dedup_key = $agent->trigger_event('HELO');
    my $request = $ua->last_http_request_sent();

    is($dedup_key, 'my dedup_key');
    is($request->method(), 'POST');

    is($request->header('Content-Type'), 'application/json');
    is($request->header('Authorization'), 'Token token=123');
};

subtest 'trigger' => sub {
    my $agent = PagerDuty::Agent->new(routing_key => '123', ua_obj => $ua);

    my $dedup_key = $agent->trigger_event('HELO');
    my $request = $ua->last_http_request_sent();

    is($dedup_key, 'my dedup_key');

    my $event = $agent->json_serializer()->decode($request->content());
    is($event->{event_action}, 'trigger');
    is($event->{payload}->{summary}, 'HELO');


    $agent->trigger_event(summary => 'HELO');
    $request = $ua->last_http_request_sent();
    is($event->{payload}->{summary}, 'HELO');
};

subtest 'acknowledge' => sub {
    my $agent = PagerDuty::Agent->new(routing_key => '123', ua_obj => $ua);

    my $dedup_key = $agent->acknowledge_event('my dedup_key');
    my $request = $ua->last_http_request_sent();

    is($dedup_key, 'my dedup_key');

    my $event = $agent->json_serializer()->decode($request->content());
    is($event->{event_action}, 'acknowledge');
    is($event->{dedup_key}, 'my dedup_key');


    $agent->acknowledge_event(summary => 'HELO', dedup_key => 'my dedup_key');
    $request = $ua->last_http_request_sent();
    is($event->{dedup_key}, 'my dedup_key');
};

subtest 'resolve' => sub {
    my $agent = PagerDuty::Agent->new(routing_key => '123', ua_obj => $ua);

    my $dedup_key = $agent->resolve_event('my dedup_key');
    my $request = $ua->last_http_request_sent();

    is($dedup_key, 'my dedup_key');

    my $event = $agent->json_serializer()->decode($request->content());
    is($event->{event_action}, 'resolve');
    is($event->{dedup_key}, 'my dedup_key');


    $agent->resolve_event(summary => 'HELO', dedup_key => 'my dedup_key');
    $request = $ua->last_http_request_sent();
    is($event->{dedup_key}, 'my dedup_key');
};

done_testing();
