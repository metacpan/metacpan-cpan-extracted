#!/usr/bin/env perl
# SWML Service Routing Example
#
# Demonstrates using a single SWML Service with multiple sections for
# path-based content routing. Different sections are built for different
# purposes (main, customer, product) and served based on request context.
#
# Endpoints:
#   /main     - Default greeting
#   /customer - Customer service greeting
#   /product  - Product information greeting

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::SWML::Service;

my $svc = SignalWire::SWML::Service->new(
    route => '/main',
);

my $doc = $svc->document;

# --- Main section (default greeting) ---
$doc->add_verb('main', 'answer', {});
$doc->add_verb('main', 'play', { url => 'say:Hello from the main service!' });
$doc->add_verb('main', 'hangup', {});

# --- Customer section ---
$doc->add_section('customer_section');
$doc->add_verb('customer_section', 'answer', {});
$doc->add_verb('customer_section', 'play', {
    url => 'say:Hello from the customer service!',
});
$doc->add_verb('customer_section', 'prompt', {
    play       => 'say:Press 1 for account management, 2 for billing, or 3 for technical support.',
    max_digits => 1,
});
$doc->add_verb('customer_section', 'hangup', {});

# --- Product section ---
$doc->add_section('product_section');
$doc->add_verb('product_section', 'answer', {});
$doc->add_verb('product_section', 'play', {
    url => 'say:Hello from the product service!',
});
$doc->add_verb('product_section', 'prompt', {
    play       => 'say:Press 1 for product info, 2 for pricing, or 3 for a demo.',
    max_digits => 1,
});
$doc->add_verb('product_section', 'hangup', {});

print "Starting SWML Service with Routing\n";
print "Route: " . $svc->route . "\n";
print "Basic Auth: " . $svc->basic_auth_user . ":" . $svc->basic_auth_password . "\n\n";
print "Sections available: main, customer_section, product_section\n";
print "\nSWML Document:\n";
print $doc->to_pretty_json . "\n\n";

$svc->run;
