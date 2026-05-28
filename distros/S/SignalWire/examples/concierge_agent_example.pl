#!/usr/bin/env perl
# Concierge Agent Example
#
# Demonstrates the Concierge prefab for providing virtual concierge services
# with information about amenities, services, and hours of operation.

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::Prefabs::Concierge;

my $agent = SignalWire::Prefabs::Concierge->new(
    venue_name => 'Oceanview Resort',
    services   => [
        'room service',
        'spa bookings',
        'restaurant reservations',
        'activity bookings',
        'airport shuttle',
        'valet parking',
        'concierge assistance',
    ],
    amenities => {
        'infinity pool' => {
            hours       => '7:00 AM - 10:00 PM',
            location    => 'Main Level, Ocean View',
            description => 'Heated infinity pool overlooking the ocean with poolside service.',
        },
        'spa' => {
            hours       => '9:00 AM - 8:00 PM',
            location    => 'Lower Level, East Wing',
            description => 'Full-service luxury spa offering massages, facials, and body treatments.',
        },
        'fitness center' => {
            hours       => '24 hours',
            location    => '2nd Floor, North Wing',
            description => 'State-of-the-art fitness center with cardio equipment, weights, and yoga studio.',
        },
        'beach access' => {
            hours       => 'Dawn to Dusk',
            location    => 'Southern Pathway',
            description => 'Private beach access with complimentary chairs, umbrellas, and towels.',
        },
    },
    hours_of_operation => {
        'check-in'     => '3:00 PM',
        'check-out'    => '11:00 AM',
        'front desk'   => '24 hours',
        'concierge'    => '7:00 AM - 11:00 PM',
        'room service' => '24 hours',
    },
    special_instructions => [
        'Always greet guests by name when possible.',
        'Offer to make reservations for guests at local attractions.',
        'Provide weather updates when discussing outdoor activities.',
        'Inform guests about the daily resort activities and events.',
    ],
    welcome_message => 'Welcome to Oceanview Resort, where luxury meets comfort. '
        . "I'm your virtual concierge, ready to assist with any requests "
        . 'or answer questions about our amenities and services. '
        . 'How may I help you today?',
);

$agent->add_language(name => 'English', code => 'en-US', voice => 'inworld.Mark');
$agent->set_params({ ai_model => 'gpt-4.1-nano' });

print "Starting Concierge Agent for Oceanview Resort\n";
print "Available at: http://localhost:3000/concierge\n";

$agent->run;
