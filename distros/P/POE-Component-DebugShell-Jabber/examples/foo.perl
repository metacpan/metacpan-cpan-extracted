#!/usr/bin/perl

use warnings;
use strict;

use POE;
use POE::Component::DebugShell::Jabber;

sub DEBUG () { 1 }

POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->alias_set('PIE');

            $_[KERNEL]->alias_set('PIE2');
            POE::Component::DebugShell::Jabber->spawn(
				jabber => {
					IP => 'foo.server.blah',
					PORT => '5222',
					HOSTNAME => 'foo.server.blah',
					USERNAME => 'bot',
					PASSWORD => 'testing',
				},
				jabber_package => 'POE::Component::Jabber::Client::Legacy',
				users => {
					'david@foo.server.blah' => 1,
				},
			) if DEBUG;
            $_[KERNEL]->yield('ping');
        },
        _stop => sub { },

        ping => sub {
			print "ping!\n";
			warn "ping warn!";
            $_[KERNEL]->delay('ping', 10);
        },
    }
);

POE::Kernel->run();
exit;
