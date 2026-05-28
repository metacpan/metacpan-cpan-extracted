#!/usr/bin/env perl
# Record Call Virtual Helper Examples
#
# Demonstrates using SwaigFunctionResult's record_call and stop_record_call
# virtual helpers for background call recording with various configurations:
# - Basic and advanced recording settings
# - Custom format, direction, and quality
# - Start/stop recording workflows
# - Compliance and customer service scenarios

use strict;
use warnings;
use lib 'lib';
use JSON ();
use SignalWire;
use SignalWire::SWAIG::FunctionResult;

my $json = JSON->new->utf8->canonical->pretty;

# 1. Basic recording
print "=== Basic Recording Example ===\n";
my $basic = SignalWire::SWAIG::FunctionResult->new('Starting basic call recording')
    ->record_call()
    ->say('This call is now being recorded');
print $json->encode($basic->to_hash), "\n";

# 2. Advanced recording with options
print "=== Advanced Recording Example ===\n";
my $advanced = SignalWire::SWAIG::FunctionResult->new('Starting advanced call recording')
    ->record_call(
        control_id => 'support_call_001',
        stereo     => 1,
        format     => 'mp3',
        direction  => 'both',
    )
    ->say('This call is being recorded for quality and training purposes');
print $json->encode($advanced->to_hash), "\n";

# 3. Stop recording
print "=== Stop Recording Example ===\n";
my $stop = SignalWire::SWAIG::FunctionResult->new('Ending call recording')
    ->stop_record_call(control_id => 'support_call_001')
    ->say('Thank you for calling. Your feedback is important to us.');
print $json->encode($stop->to_hash), "\n";

# 4. Customer service workflow
print "=== Customer Service Workflow ===\n";
my $cs_start = SignalWire::SWAIG::FunctionResult->new('Transferring to agent')
    ->record_call(
        control_id => 'cs_transfer_001',
        format     => 'mp3',
        direction  => 'both',
    )
    ->update_global_data({ recording_id => 'cs_transfer_001' })
    ->say('Please hold while I connect you');
print "Start recording:\n" . $json->encode($cs_start->to_hash) . "\n";

my $cs_end = SignalWire::SWAIG::FunctionResult->new('Call recording stopped')
    ->stop_record_call(control_id => 'cs_transfer_001')
    ->remove_global_data('recording_id')
    ->say('Thank you for calling. Have a wonderful day!');
print "End recording:\n" . $json->encode($cs_end->to_hash) . "\n";

# 5. Compliance recording
print "=== Compliance Recording Example ===\n";
my $compliance = SignalWire::SWAIG::FunctionResult->new(
    'This call is being recorded for compliance purposes'
)
    ->record_call(
        control_id => 'compliance_rec_001',
        stereo     => 1,
        format     => 'wav',
        direction  => 'both',
    )
    ->set_metadata({
        call_type          => 'compliance',
        legal_notice_given => JSON::true,
    });
print $json->encode($compliance->to_hash), "\n";

print "COMPLETE: All recording examples completed\n";
