#!/usr/bin/env perl -T

use strict;
use warnings;

package FailingAgent;
use Moo;
extends 'PagerDuty::Agent';

sub json_serializer { die "something is super wrong" }


package main;

use Test::More;
use English '-no_match_vars';

my $failing_agent = FailingAgent->new(routing_key => '123');

my $warn_message;
local $SIG{__WARN__} = sub { $warn_message = $_[0] };

is($failing_agent->trigger_event('HELO'), undef);

like($warn_message, qr/something is super wrong/);
like($EVAL_ERROR, qr/something is super wrong/);

done_testing();
