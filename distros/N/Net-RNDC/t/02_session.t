#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Net::RNDC::Session;

## new
throws_ok { Net::RNDC::Session->new(); }
	qr/Missing required argument 'want_read'/,
	"new() without want_read fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub  {},
	) }
	qr/Missing required argument 'want_write'/,
	"new() without want_write fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
	) }
	qr/Missing required argument 'want_finish'/,
	"new() without want_finish fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
		want_finish => sub {},
	) }
	qr/Missing required argument 'want_error'/,
	"new() without want_finish fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
		want_finish => sub {},
		want_error  => sub {},
	) }
	qr/Missing required argument 'key'/,
	"new() without key fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
		want_finish => sub {},
		want_error  => sub {},
		key         => 'aabc',
	) }
	qr/Missing required argument 'command'/,
	"new() without command fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
		want_finish => sub {},
		want_error  => sub {},
		key         => 'aabc',
		command     => 'status',
	) }
	qr/Argument 'is_client' or 'is_server' must be defined/,
	"new() without is_client or is_server fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => 'cat',
		want_write  => sub {},
		want_finish => sub {},
		want_error  => sub {},
		key         => 'aabc',
		command     => 'status',
		is_client   => 1,
	) }
	qr/Argument 'want_read' is not a code ref/,
	"new() with bad want_read fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => 'cat',
		want_finish => sub {},
		want_error  => sub {},
		key         => 'aabc',
		command     => 'status',
		is_client   => 1,
	) }
	qr/Argument 'want_write' is not a code ref/,
	"new() with bad want_write fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
		want_finish => 'cat',
		want_error  => sub {},
		key         => 'aabc',
		command     => 'status',
		is_client   => 1,
	) }
	qr/Argument 'want_finish' is not a code ref/,
	"new() with bad want_finish fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
		want_finish => sub {},
		want_error  => 'cat',
		key         => 'aabc',
		command     => 'status',
		is_client   => 1,
	) }
	qr/Argument 'want_error' is not a code ref/,
	"new() with bad want_error fails";

throws_ok { Net::RNDC::Session->new(
		want_read   => sub {},
		want_write  => sub {},
		want_finish => sub {},
		want_error  => sub {},
		key         => 'aabc',
		command     => 'status',
		is_client   => 1,
		is_server   => 1,
	) }
	qr/Argument 'is_client' cannot be mixed with 'is_server'/,
	"new() with is_client and is_server fails";

{

# Test both client/session (which also tests parsing/generation)

# Response from server
my $sresp;

# Client error, if any
my $cerror;

# Server error, if any
my $serror;

my ($client, $server);

$client = Net::RNDC::Session->new(
	want_read => sub {}, # $server->want_write() handles this
	want_write => sub {
		my $c = shift;

		$c->next;

		$server->next(shift);
	},
	want_finish => sub {
		my $c = shift;

		$sresp = shift;
	},
	want_error => sub {
		my $c = shift;

		$cerror = shift;
	},
	key       => 'abcd',
	is_client => 1,
	command   => 'status',
);

$server = Net::RNDC::Session->new(
	want_read => sub {}, # $client->want_write() handles this
	want_write => sub {
		my $s = shift;

		$s->next;

		$client->next(shift);
	},
	want_finish => sub {
		my $s = shift;

		return;
	},
	want_error => sub {
		my $s = shift;

		$serror = shift;
	},
	key       => 'abcd',
	is_server => 1,
	command   => 'hahahaha',
);

# Calls $server->want_read which does nothing
$server->start;

# Calls $client->want_write which kicks off the flow
$client->start;

is($cerror, undef, 'No client error reported');
is($serror, undef, 'No server error reported');

is($sresp, 'hahahaha', 'Client/Server communicated');

}

done_testing;
