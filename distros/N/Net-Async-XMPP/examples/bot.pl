#!/usr/bin/env perl
use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::XMPP::Client;

# Obtain a standard event loop
my $loop = IO::Async::Loop->new;

my %command_help = (
	help => 'Shows help',
	subscribe => 'Subscribes to a contact',
	unsubscribe => 'Unsubscribes from a contact',
);
my %command_map; %command_map = (
	help	=> sub {
		my ($client, $msg, @param) = @_;
		return "List of supported commands: " . join(',', sort keys %command_map) unless @param;
		my $cmd = shift @param;
		return "No help found for command '$cmd'" unless $command_help{$cmd};
		return $command_help{$cmd};
	},
	subscribe => sub {
		my ($client, $msg, @param) = @_;
		my $target = shift(@param) || $msg->from;
		$client->subscribe($target);
		"Subscribed to " . $msg->from;
	},
	unsubscribe => sub {
		my ($client, $msg, @param) = @_;
		my $target = shift(@param) || $msg->from;
		$client->unsubscribe($target);
		"Unsubscribed from " . $msg->from;
	},
	authorise => sub {
		my ($client, $msg, @param) = @_;
		my $target = shift(@param) || $msg->from;
		$client->authorise($target);
		"Authorised " . $msg->from;
	},
	deauthorise => sub {
		my ($client, $msg, @param) = @_;
		my $target = shift(@param) || $msg->from;
		$client->deauthorise($target);
		"Deauthorised " . $msg->from;
	},
);

# Create a client object with our event callbacks
my $client = Net::Async::XMPP::Client->new(
# Called when a message is received.
	on_message		=> sub {
		my ($client, $msg) = @_;
		# Don't attempt to send anything if it was from us, to avoid loops
		return if $msg->from eq $msg->to;

		my ($cmd, @param) = split ' ', $msg->body;
		my $rslt = $command_map{$cmd} ? $command_map{$cmd}->($client, $msg, @param) : "Invalid command '$cmd'";
		return unless defined $rslt;
		$msg->reply(body => $rslt);
	},

# Called when someone asks to add us to their list - we're set up to auto-authorise here
# and send a basic greeting.
	on_contact_request	=> sub {
		my ($client, $contact) = @_;
		$contact->authorise;
		$client->compose(
			to	=> $contact->jid,
			body	=> "Pleased to make your acquaintance. Type help to get started.",
		)->send;
	},

# This will be called when we're notified of someone's presence - in this case
	on_presence		=> sub {
		my ($client, $contact) = @_;
		return if $contact->is_me;

		warn "Had a presence update from " . $contact->jid;
		$client->compose(
			to => $contact->jid,
			body => "Hi " . $contact->name . ", type help to get started.",
		)->send;
	},
);

$loop->add($client);
$client->login(
	jid	=> 'xmpptest@roku',
	password => 'none',
);
$loop->loop_forever;

