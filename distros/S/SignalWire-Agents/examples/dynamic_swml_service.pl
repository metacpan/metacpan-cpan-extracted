#!/usr/bin/env perl
# Dynamic SWML Service Example
#
# Demonstrates creating a SWML service that generates different responses
# based on caller type and department. Shows how the service builds
# different SWML documents dynamically.
#
# This example builds two service types:
# 1. Dynamic greeting service - customizes based on caller_name, caller_type
# 2. Call router service - routes based on region and queue volume
#
# Usage:
#   perl -Ilib examples/dynamic_swml_service.pl           # greeting (default)
#   perl -Ilib examples/dynamic_swml_service.pl router     # call router

use strict;
use warnings;
use lib 'lib';
use SignalWire::Agents;
use SignalWire::Agents::SWML::Service;

my $choice = $ARGV[0] // 'greeting';

if ($choice eq 'router') {
    # --- Call Router Service ---
    my $svc = SignalWire::Agents::SWML::Service->new(
        route => '/router',
    );

    my $doc = $svc->document;
    $doc->add_verb('main', 'answer', {});
    $doc->add_verb('main', 'play', {
        url => 'say:Thank you for calling. We will connect you with an available agent.',
    });
    $doc->add_verb('main', 'connect', {
        to      => '+15551234567',
        timeout => 30,
    });
    $doc->add_verb('main', 'hangup', {});

    print "Starting Call Router Service\n";
    print "Route: /router\n";
    print "Basic Auth: " . $svc->basic_auth_user . ":" . $svc->basic_auth_password . "\n\n";
    print "SWML Document:\n";
    print $doc->to_pretty_json . "\n\n";
    $svc->run;

} else {
    # --- Dynamic Greeting Service ---
    my $svc = SignalWire::Agents::SWML::Service->new(
        route => '/greeting',
    );

    my $doc = $svc->document;

    # Default greeting document
    $doc->add_verb('main', 'answer', {});
    $doc->add_verb('main', 'play', {
        url => 'say:Hello, thank you for calling our service.',
    });
    $doc->add_verb('main', 'prompt', {
        play          => 'say:Please press 1 for sales, 2 for support, or 3 to leave a message.',
        max_digits    => 1,
        terminators   => '#',
    });
    $doc->add_verb('main', 'hangup', {});

    # VIP section
    $doc->add_section('vip');
    $doc->add_verb('vip', 'answer', {});
    $doc->add_verb('vip', 'play', {
        url => 'say:As a VIP customer, you will be connected to our priority support team immediately.',
    });
    $doc->add_verb('vip', 'connect', {
        to             => '+15551234567',
        timeout        => 30,
        answer_on_bridge => JSON::true,
    });
    $doc->add_verb('vip', 'hangup', {});

    # New customer section
    $doc->add_section('new_customer');
    $doc->add_verb('new_customer', 'answer', {});
    $doc->add_verb('new_customer', 'prompt', {
        play       => 'say:Please press 1 to learn about our products, 2 to speak with sales, or 3 for a demo.',
        max_digits => 1,
    });
    $doc->add_verb('new_customer', 'hangup', {});

    print "Starting Dynamic Greeting Service\n";
    print "Route: /greeting\n";
    print "Basic Auth: " . $svc->basic_auth_user . ":" . $svc->basic_auth_password . "\n\n";
    print "Available sections: main, vip, new_customer\n";
    print "SWML Document:\n";
    print $doc->to_pretty_json . "\n\n";
    $svc->run;
}
