#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use IO::Async::Loop;
use Net::Async::XMPP::Client;

use Getopt::Long;

GetOptions(
	"jid=s"           => \my $jid,
	"target|t=s"      => \my $target,
	"message|m=s"     => \my $message,
	"host|h=s"        => \my $host,
	"password|p=s"    => \my $password,
	"debug|d"         => \my $debug,
) or die "bad options";

# Obtain a standard event loop
my $loop = IO::Async::Loop->new;

# Create a client object with our event callbacks
$loop->add(
	my $client = Net::Async::XMPP::Client->new(
		debug => $debug,
	)
);

$client->login(
	jid          => $jid,
	(defined $host
	? (host         => $host)
	: ()
	),
	password     => $password,
)->then(sub {
	$client->compose(
		to   => $target,
		body => $message,
	)->send
}, sub {
	warn "Something went wrong: @_";
})->then(sub {
	$client->logout
})->get;
say "Message sent to $target.";

