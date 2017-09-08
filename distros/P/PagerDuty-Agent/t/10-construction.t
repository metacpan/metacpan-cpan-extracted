#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

use English '-no_match_vars';
use PagerDuty::Agent;

my $agent = PagerDuty::Agent->new(routing_key => '123');

is($agent->routing_key(), '123');
is($agent->api_version(), 2);
is($agent->post_url(), 'https://events.pagerduty.com/v2/enqueue');

eval { PagerDuty::Agent->new() };
is($EVAL_ERROR, "must pass routing_key\n");

eval { PagerDuty::Agent->new(routing_key => '123', api_version => -1) };
is($EVAL_ERROR, "invalid api version -1\n");

done_testing();
