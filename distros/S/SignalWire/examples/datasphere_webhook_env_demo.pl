#!/usr/bin/env perl
# DataSphere Webhook Environment Demo
#
# Traditional webhook-based DataSphere skill from environment variables.
# Compare with datasphere_serverless_env.pl for the serverless approach.
#
# Required: DATASPHERE_DOCUMENT_ID

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Agent::AgentBase;

sub require_env {
    my ($name) = @_;
    my $val = $ENV{$name};
    unless ($val) {
        die "Error: Required environment variable $name is not set.\n";
    }
    return $val;
}

my $document_id = require_env('DATASPHERE_DOCUMENT_ID');
my $count       = $ENV{DATASPHERE_COUNT}    // 3;
my $distance    = $ENV{DATASPHERE_DISTANCE} // 4.0;

my $agent = SignalWire::Agent::AgentBase->new(
    name  => 'DataSphere Webhook Env',
    route => '/datasphere-webhook',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section('Role',
    'You are a knowledge assistant using webhook-based DataSphere for retrieval.');

eval { $agent->add_skill('datetime') };
eval { $agent->add_skill('math') };

eval {
    $agent->add_skill('datasphere', {
        document_id => $document_id,
        count       => $count,
        distance    => $distance,
        mode        => 'webhook',
    });
    print "Added DataSphere webhook skill\n";
};
print "DataSphere error: $@\n" if $@;

print "DataSphere Webhook Environment Demo\n";
print "  Document: $document_id\n";
print "  Execution: Webhook-based (traditional)\n";
print "\n";
print "  Webhook:    Full control, custom error handling\n";
print "  Serverless: No webhooks, lower latency, executes on SignalWire\n\n";

$agent->run;
