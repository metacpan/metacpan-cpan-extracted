#!/usr/bin/env perl
# Tap and Stop Tap Virtual Helper Examples
#
# Demonstrates using SwaigFunctionResult's tap and stop_tap virtual helpers
# for call monitoring and audio streaming:
# - WebSocket and RTP tap streaming
# - Compliance and security monitoring
# - Quality assurance and training
# - Multiple concurrent tap sessions
# - Start/stop tap workflows

use strict;
use warnings;
use lib 'lib';
use JSON ();
use SignalWire::Agents;
use SignalWire::Agents::SWAIG::FunctionResult;

my $json = JSON->new->utf8->canonical->pretty;

# 1. Basic WebSocket tap
print "=== Basic WebSocket Tap ===\n";
my $ws_tap = SignalWire::Agents::SWAIG::FunctionResult->new('Starting call monitoring')
    ->tap('wss://monitoring.company.com/audio-stream')
    ->say('Call monitoring is now active');
print $json->encode($ws_tap->to_hash), "\n";

# 2. Basic RTP tap
print "=== Basic RTP Tap ===\n";
my $rtp_tap = SignalWire::Agents::SWAIG::FunctionResult->new('Starting RTP monitoring')
    ->tap('rtp://192.168.1.100:5004')
    ->update_global_data({ rtp_monitoring => JSON::true });
print $json->encode($rtp_tap->to_hash), "\n";

# 3. Advanced compliance monitoring
print "=== Compliance Monitoring ===\n";
my $compliance = SignalWire::Agents::SWAIG::FunctionResult->new('Setting up compliance monitoring')
    ->tap('wss://compliance.company.com/secure-stream',
        control_id => 'compliance_tap_001',
        direction  => 'both',
        codec      => 'PCMA',
    )
    ->set_metadata({
        compliance_session => JSON::true,
        agent_id           => 'agent_123',
        recording_purpose  => 'regulatory_compliance',
    })
    ->say('This call may be monitored for compliance purposes');
print $json->encode($compliance->to_hash), "\n";

# 4. Customer service quality monitoring
print "=== Customer Service Monitoring ===\n";
my $cs_monitor = SignalWire::Agents::SWAIG::FunctionResult->new('Initializing quality monitoring')
    ->tap('wss://quality.company.com/cs-monitoring',
        control_id => 'cs_quality_monitor',
        direction  => 'speak',
    )
    ->update_global_data({
        quality_monitoring => JSON::true,
    })
    ->say('Welcome to customer service. How can I help you today?');
print $json->encode($cs_monitor->to_hash), "\n";

# 5. Stop tap examples
print "=== Stop Tap Examples ===\n";
my $stop_recent = SignalWire::Agents::SWAIG::FunctionResult->new('Ending monitoring session')
    ->stop_tap()
    ->say('Call monitoring has been stopped');
print "Stop most recent tap:\n" . $json->encode($stop_recent->to_hash) . "\n";

my $stop_specific = SignalWire::Agents::SWAIG::FunctionResult->new('Ending compliance monitoring')
    ->stop_tap(control_id => 'compliance_tap_001')
    ->update_global_data({ compliance_session => JSON::false })
    ->say('Compliance monitoring has been deactivated');
print "Stop specific tap:\n" . $json->encode($stop_specific->to_hash) . "\n";

# 6. Call center workflow
print "=== Call Center Workflow ===\n";
my $start = SignalWire::Agents::SWAIG::FunctionResult->new('Call center session starting')
    ->tap('wss://callcenter.company.com/agent-monitoring',
        control_id => 'agent_monitor_001',
        direction  => 'both',
    )
    ->set_metadata({
        agent_id         => 'agent_456',
        department       => 'technical_support',
        monitoring_level => 'full',
    })
    ->update_global_data({ call_monitored => JSON::true })
    ->say('Thank you for calling technical support. Your call may be monitored.');
print "Start monitoring:\n" . $json->encode($start->to_hash) . "\n";

my $end = SignalWire::Agents::SWAIG::FunctionResult->new('Ending call session')
    ->stop_tap(control_id => 'agent_monitor_001')
    ->update_global_data({ call_monitored => JSON::false })
    ->set_metadata({ session_complete => JSON::true });
print "End monitoring:\n" . $json->encode($end->to_hash) . "\n";

print "COMPLETE: All tap examples completed\n";
