#!/usr/bin/env perl
# basic_swml_service.pl
#
# Mirror of signalwire-python/examples/basic_swml_service.py — the
# minimum SWMLService viable. Demonstrates that SWML::Service runs
# standalone (no AgentBase, no AI, no SWAIG), serves a single SWML
# document on `/`, and is the building block AgentBase extends.
#
# Run:
#     perl -Ilib examples/basic_swml_service.pl
# Then:
#     curl -u user:pass http://localhost:3000/

use strict;
use warnings;
use lib 'lib';
use SignalWire::SWML::Service;
use JSON ();

unless (caller) {
    my %args = (
        name                => 'basic-swml',
        route               => '/',
        basic_auth_user     => $ENV{SWML_BASIC_AUTH_USER}     // 'user',
        basic_auth_password => $ENV{SWML_BASIC_AUTH_PASSWORD} // 'pass',
    );
    $args{port} = $ENV{PORT} if defined $ENV{PORT} && $ENV{PORT} =~ /^\d+$/;

    my $svc = SignalWire::SWML::Service->new(%args);

    # Build the simplest useful SWML doc: answer the call, say a
    # message, hang up. No AI verb at all — the whole point of this
    # example is that SWMLService doesn't need one.
    my $doc = $svc->document;
    $doc->add_verb('main', 'answer', {});
    $doc->add_verb('main', 'play',   { url => 'say:Welcome to the basic SWML service.' });
    $doc->add_verb('main', 'sleep',  500);
    $doc->add_verb('main', 'hangup', {});

    print "Basic SWMLService\n";
    print "Route:      " . $svc->route . "\n";
    print "Basic auth: " . $svc->basic_auth_user . ":" . $svc->basic_auth_password . "\n";
    print "URL:        http://"
        . $svc->basic_auth_user . ":" . $svc->basic_auth_password
        . "\@" . $svc->host . ":" . $svc->port . $svc->route . "\n\n";

    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(
        '--host'   => $svc->host,
        '--port'   => $svc->port,
        '--server' => 'HTTP::Server::PSGI',
    );
    $runner->run($svc->to_psgi_app);
}

1;
