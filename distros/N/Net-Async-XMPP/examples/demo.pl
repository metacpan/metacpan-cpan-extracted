#!/usr/bin/env perl
use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::XMPP::Client;

my $loop = IO::Async::Loop->new;
print "Had $loop\n";

my $client = Net::Async::XMPP::Client->new(
	debug			=> 0,
	on_message		=> sub {
		my ($client, $msg) = @_;
		warn "Message from " . $msg->from . " subject " . $msg->subject . " body " . $msg->body;
		$msg->reply(
			body => 'Message received: ' . $msg->body
		);
	},
	on_contact_request	=> sub {
		my ($client, $contact) = @_;
		warn "Contact request from " . $contact->jid;
	},
	on_login		=> sub {
		warn "Login complete";
	},
	on_presence		=> sub {
		my ($client, $contact) = @_;
		warn "Had a presence update from " . $contact->jid;
	},
);
$loop->add($client);
$client->login(
	jid	=> 'xmpptest@roku',
	password => 'none',
);
$loop->loop_forever;

