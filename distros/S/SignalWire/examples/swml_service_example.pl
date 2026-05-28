#!/usr/bin/env perl
# Basic SWML Service Example
#
# Demonstrates using the SWML::Service class directly to create and serve
# SWML documents without AI components. Shows how to build telephony flows
# for voicemail, IVR menus, call transfers, and call recording.

use strict;
use warnings;
use lib 'lib';
use SignalWire;
use SignalWire::SWML::Service;

# --- Voicemail Service ---
sub build_voicemail {
    my $svc = SignalWire::SWML::Service->new(
        route => '/voicemail',
    );

    my $doc = $svc->document;
    $doc->add_verb('main', 'answer', {});
    $doc->add_verb('main', 'play', {
        url => "say:Hello, you've reached the voicemail service. Please leave a message after the beep.",
    });
    $doc->add_verb('main', 'sleep', 1000);
    $doc->add_verb('main', 'record', {
        format     => 'mp3',
        stereo     => JSON::false,
        beep       => JSON::true,
        max_length => 120,
        terminators => '#',
    });
    $doc->add_verb('main', 'play', {
        url => 'say:Thank you for your message. Goodbye!',
    });
    $doc->add_verb('main', 'hangup', {});

    return $svc;
}

# --- IVR Menu Service ---
sub build_ivr {
    my $svc = SignalWire::SWML::Service->new(
        route => '/ivr',
    );

    my $doc = $svc->document;

    # Main section: answer and jump to menu
    $doc->add_verb('main', 'answer', {});
    $doc->add_verb('main', 'transfer', { dest => 'main_menu' });

    # Menu section
    $doc->add_section('main_menu');
    $doc->add_verb('main_menu', 'prompt', {
        play          => 'say:Welcome to our service. Press 1 for sales, 2 for support, or 3 to leave a message.',
        max_digits    => 1,
        terminators   => '#',
        digit_timeout => 5.0,
    });
    $doc->add_verb('main_menu', 'switch', {
        variable => 'prompt_digits',
        case     => {
            '1' => [{ transfer => { dest => 'sales' } }],
            '2' => [{ transfer => { dest => 'support' } }],
            '3' => [{ transfer => { dest => 'voicemail' } }],
        },
        default => [
            { play     => { url => "say:I'm sorry, I didn't understand your selection." } },
            { transfer => { dest => 'main_menu' } },
        ],
    });

    # Sales section
    $doc->add_section('sales');
    $doc->add_verb('sales', 'play',    { url => 'say:Connecting you to sales. Please hold.' });
    $doc->add_verb('sales', 'connect', { to => '+15551234567' });

    # Support section
    $doc->add_section('support');
    $doc->add_verb('support', 'play',    { url => 'say:Connecting you to support. Please hold.' });
    $doc->add_verb('support', 'connect', { to => '+15557654321' });

    # Voicemail section
    $doc->add_section('voicemail');
    $doc->add_verb('voicemail', 'play',   { url => 'say:Please leave a message after the beep.' });
    $doc->add_verb('voicemail', 'sleep',  1000);
    $doc->add_verb('voicemail', 'record', { format => 'mp3', max_length => 120, terminators => '#' });
    $doc->add_verb('voicemail', 'play',   { url => 'say:Thank you for your message. Goodbye!' });
    $doc->add_verb('voicemail', 'hangup', {});

    return $svc;
}

# --- Display SWML output ---
my $choice = $ARGV[0] // 'voicemail';
my $svc;

if ($choice eq 'ivr') {
    $svc = build_ivr();
} else {
    $svc = build_voicemail();
}

print "SWML Service: $choice\n";
print "Route: " . $svc->route . "\n";
print "Basic Auth: " . $svc->basic_auth_user . ":" . $svc->basic_auth_password . "\n\n";
print "SWML Document:\n";
print $svc->document->to_pretty_json . "\n";

print "\nStarting server on http://0.0.0.0:" . $svc->port . $svc->route . "\n";
$svc->run;
