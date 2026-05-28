#!/usr/bin/env perl
# Receptionist Agent Example
#
# Demonstrates the Receptionist prefab for creating a call routing system
# that greets callers and transfers them to the appropriate department.

use strict;
use warnings;
use lib 'lib';
use JSON qw(encode_json);
use SignalWire;
use SignalWire::Prefabs::Receptionist;

my $agent = SignalWire::Prefabs::Receptionist->new(
    name => 'acme-receptionist',
    route => '/reception',
    departments => [
        {
            name        => 'sales',
            description => 'For product inquiries, pricing, and purchasing',
            number      => '+15551235555',
        },
        {
            name        => 'support',
            description => 'For technical assistance, troubleshooting, and bug reports',
            number      => '+15551236666',
        },
        {
            name        => 'billing',
            description => 'For payment questions, invoices, and subscription changes',
            number      => '+15551237777',
        },
        {
            name        => 'general',
            description => 'For all other inquiries',
            number      => '+15551238888',
        },
    ],
    greeting => 'Hello, thank you for calling ACME Corporation. How may I direct your call today?',
    voice    => 'inworld.Mark',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

# Add extra company info to the prompt
$agent->prompt_add_section(
    'Company Information',
    'ACME Corporation is a leading provider of innovative solutions. '
    . 'Business hours are Monday through Friday, 9 AM to 5 PM Eastern Time.',
);

# Summary callback for call reporting
$agent->on_summary(sub {
    my ($summary, $raw) = @_;
    if ($summary) {
        print "Call Summary: " . encode_json($summary) . "\n";
    }
});

print "Starting Receptionist Agent\n";
print "Available at: http://localhost:3000/reception\n";

$agent->run;
