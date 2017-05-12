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
		$msg->reply(
			body => 'Received: ' . $msg->body
		) unless $msg->from eq $msg->to;
	},
	on_contact_request	=> sub {
		my ($client, $contact) = @_;
		$contact->authorise;
	},
	on_presence		=> sub {
		my ($client, $contact) = @_;
		warn "Had a presence update from " . $contact->jid;
		$client->compose(
			to => $contact->jid,
			body => "Hi " . $contact->name,
		)->send;
	},
);

$loop->add($client);
$client->login(
	jid	=> 'xmpptest@roku',
	password => 'none',
);
$loop->loop_forever;

