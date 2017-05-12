#!/usr/bin/env perl
use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::SMTP::Client;
use Email::Simple;
my $email = Email::Simple->create(
	header => [
		From    => 'someone@example.com',
		To      => 'other@example.com',
		Subject => 'NaSMTP test',
	],
	attributes => {
		encoding => "8bitmime",
		charset  => "UTF-8",
	},
	body_str => '... text ...',
);
my $loop = IO::Async::Loop->new;
$loop->add(
	my $smtp = Net::Async::SMTP::Client->new(
		domain => 'example.com',
	)
);
$smtp->connected->then(sub {
	$smtp->login(
		user => '...',
		pass => '...',
	)
})->then(sub {
	$smtp->send(
		to   => 'someone@example.com',
		from => 'other@example.com',
		data => $email->as_string,
	)
})->get;
