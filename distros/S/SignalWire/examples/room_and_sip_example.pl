#!/usr/bin/env perl
# Room and SIP Virtual Helper Examples
#
# Demonstrates using SwaigFunctionResult's join_room, sip_refer, and
# join_conference virtual helpers for:
# - RELAY room joining for multi-party communication
# - SIP REFER for call transfers in SIP environments
# - Audio conferences with recording and callbacks
# - Metadata tracking and global data management

use strict;
use warnings;
use lib 'lib';
use JSON ();
use SignalWire;
use SignalWire::SWAIG::FunctionResult;

my $json = JSON->new->utf8->canonical->pretty;

# 1. Basic room join
print "=== Basic Room Join ===\n";
my $room = SignalWire::SWAIG::FunctionResult->new('Joining the support team room')
    ->join_room('support_team_room')
    ->say('Welcome to the support team collaboration room');
print $json->encode($room->to_hash), "\n";

# 2. Conference room with metadata
print "=== Conference Room ===\n";
my $conf = SignalWire::SWAIG::FunctionResult->new('Setting up daily standup meeting')
    ->join_room('daily_standup_room')
    ->set_metadata({
        meeting_type   => 'daily_standup',
        participant_id => 'user_123',
        role           => 'scrum_master',
    })
    ->update_global_data({
        meeting_active => JSON::true,
        room_name      => 'daily_standup_room',
    })
    ->say('You have joined the daily standup meeting');
print $json->encode($conf->to_hash), "\n";

# 3. Basic SIP REFER
print "=== Basic SIP REFER ===\n";
my $sip = SignalWire::SWAIG::FunctionResult->new('Transferring your call to support')
    ->say('Please hold while I transfer you')
    ->sip_refer('sip:support@company.com');
print $json->encode($sip->to_hash), "\n";

# 4. Advanced SIP REFER with metadata
print "=== Advanced SIP REFER ===\n";
my $adv_sip = SignalWire::SWAIG::FunctionResult->new('Transferring to technical support')
    ->set_metadata({
        transfer_type   => 'technical_support',
        priority        => 'high',
        original_caller => '+15551234567',
    })
    ->say("I'm connecting you to our senior technical specialist")
    ->sip_refer('sip:tech-specialist@pbx.company.com:5060')
    ->update_global_data({
        transfer_completed   => JSON::true,
        transfer_destination => 'tech-specialist@pbx.company.com',
    });
print $json->encode($adv_sip->to_hash), "\n";

# 5. Customer service escalation workflow
print "=== Customer Service Escalation ===\n";
my $join = SignalWire::SWAIG::FunctionResult->new('Connecting to customer service')
    ->join_room('customer_service_room')
    ->set_metadata({
        service_type  => 'billing_inquiry',
        customer_tier => 'premium',
    })
    ->say('You have been connected to our customer service team');
print "Join:\n" . $json->encode($join->to_hash) . "\n";

my $escalate = SignalWire::SWAIG::FunctionResult->new('Escalating to manager')
    ->say('Let me connect you with a manager')
    ->sip_refer('sip:manager@customer-service.company.com')
    ->update_global_data({
        escalated         => JSON::true,
        escalation_reason => 'customer_request',
    });
print "Escalate:\n" . $json->encode($escalate->to_hash) . "\n";

# 6. Join conference
print "=== Join Conference ===\n";
my $simple_conf = SignalWire::SWAIG::FunctionResult->new('Joining team conference')
    ->join_conference('daily_standup')
    ->say('Welcome to the daily standup conference');
print $json->encode($simple_conf->to_hash), "\n";

print "COMPLETE: All room and SIP examples completed\n";
