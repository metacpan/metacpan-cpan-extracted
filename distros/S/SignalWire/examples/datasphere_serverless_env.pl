#!/usr/bin/env perl
# DataSphere Serverless Environment Demo
#
# Loads the DataSphere serverless skill from environment variables.
#
# Required: SIGNALWIRE_SPACE_NAME, SIGNALWIRE_PROJECT_ID, SIGNALWIRE_TOKEN,
#           DATASPHERE_DOCUMENT_ID
# Optional: DATASPHERE_COUNT, DATASPHERE_DISTANCE, DATASPHERE_TAGS

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
    name  => 'DataSphere Serverless Env',
    route => '/datasphere-env',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

$agent->prompt_add_section('Role',
    'You are a knowledge assistant with access to a document library. '
    . 'Search the knowledge base to answer user questions.');

eval { $agent->add_skill('datetime') };
eval { $agent->add_skill('math') };

my %config = (
    document_id => $document_id,
    count       => $count,
    distance    => $distance,
);

if (my $tags = $ENV{DATASPHERE_TAGS}) {
    $config{tags} = [split /,/, $tags];
}

eval {
    $agent->add_skill('datasphere', \%config);
    print "Added DataSphere serverless skill\n";
};
print "DataSphere error: $@\n" if $@;

print "DataSphere Serverless Environment Demo\n";
print "  Document: $document_id\n";
print "  Count: $count, Distance: $distance\n";
print "Starting agent...\n\n";

$agent->run;
