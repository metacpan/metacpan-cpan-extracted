#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

use English '-no_match_vars';
use PagerDuty::Agent;

my $agent = PagerDuty::Agent->new(routing_key => '123');


my $event = $agent->_format_pd_cef('trigger');

ok(defined $event->{payload}->{source});
ok(defined $event->{payload}->{timestamp});
is($event->{payload}->{severity}, 'error');


$event = $agent->_format_pd_cef(
    'trigger',

     class        => 'my class',
     component    => 'my component',
     dedup_key    => 'my dedup_key',
     event_action => 'trigger',
     group        => 'my group',
     routing_key  => '123',
     severity     => 'error',
     source       => 'my host',
     summary      => 'my summary',
     timestamp    => 'my timestamp',

     custom_details => {
         k1 => 'v1',
         k2 => 'v2',
     },

     images => [ { src => 'my src', href => 'my href', alt => 'my alt' } ],
     links  => [ { href => 'my href', text => 'my text' } ],
);

is_deeply(
    $event,
    {
        dedup_key    => 'my dedup_key',
        event_action => 'trigger',
        routing_key  => '123',
        payload => {
            class     => 'my class',
            component => 'my component',
            group     => 'my group',
            severity  => 'error',
            source    => 'my host',
            summary   => 'my summary',
            timestamp => 'my timestamp',

            custom_details => {
                k1 => 'v1',
                k2 => 'v2',
            },
        },
        images => [ { src => 'my src', href => 'my href', alt => 'my alt' } ],
        links  => [ { href => 'my href', text => 'my text' } ],
    },
);


done_testing();
