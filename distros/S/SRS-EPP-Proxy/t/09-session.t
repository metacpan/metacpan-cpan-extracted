
#!/usr/bin/perl -w
#
# test the SRS::EPP::Session class overall

use 5.010;
use strict;
use Test::More qw(no_plan);
use Fatal qw(:void open);
use Data::Dumper;
use FindBin qw($Bin);
use lib $Bin;
use Mock;

use XML::EPP;
use XML::EPP::Host;
use XML::SRS;
use XML::SRS::Keyring;

use t::Log4test;

BEGIN { use_ok("SRS::EPP::Session"); }

my $input = do {
	(my $filename = $0) =~ s{\.t}{/example-session.raw};
	open my $input, "<$filename";
	local($/);
	<$input>
};

XML::EPP::register_obj_uri(
	"urn:ietf:params:xml:ns:obj1",
	"urn:ietf:params:xml:ns:obj2",
	"urn:ietf:params:xml:ns:obj3",
);

XML::EPP::register_ext_uri(
	"http://custom/obj1ext-1.0" => "obj",
);

my $event = Mock::Event->new();
my $proxy = Mock::Base->new(rfc_compliant_ssl => 1);
my $session = SRS::EPP::Session->new(
	backend_url => "foo",
	event => $event,
	io => Mock::IO->new(input => ""),
	proxy => $proxy,
	peerhost => "101.1.5.27",
	socket => Mock::Base->new,
	peer_cn => "foobar.client.cert.example.com",
);

# 0. test the ->connected event and greeting response
$session->connected;
is(@{$session->{event}{io}}, 2, "set up IO watchers OK on connected");
is_deeply(
	[$session->event->queued_events], ["signal_handler_timer", "output_event"],
	"data waiting to be written",
);

# let's write to the socket for a bit, until we see an event.  This
# simulates events from Event etc saying that the output socket is
# writable, and the condition where variable-sized chunks can be
# written to it.
srand 107;
$event->loop_until(
	sub { !@{ $session->output_queue } },
	[qw(signal_handler_timer output_event)],
	"queued output",
);

my $greeting = delete $session->io->{output};
my $greeting_length = unpack("N", bytes::substr($greeting, 0, 4, ""));
is(
	bytes::length($greeting)+4, $greeting_length,
	"got a full packet back ($greeting_length bytes)"
);

is_deeply(
	[$session->event->queued_events], [],
	"After issuing greeting, no events waiting"
);
is(
	$session->state, "Waiting for Client Authentication",
	"RFC5730 session state flowchart state as expected"
);

# 1. test that input leads to queued commands
$session->{io}{input} = $input;
$event->loop_until(
	sub {
		$session->event->queued("process_queue") or
			!$session->io->input;
	},
	[qw(input_event)],
	"queued input",
);

is($session->commands_queued, 1, "command is now queued");

# 2. proceed with the event which was 'queued'
$event->loop_until(
	sub { $event->queued("output_event") },
	[qw(process_queue input_event send_pending_replies)],
	"queue processing",
);

# this one can jump the queue here...
my $error;
do {
	$session->output_event;
} until ( $error = $session->io->get_packet );

# 3. check that we got an error!
use utf8;
like(
	$error->message->result->[0]->msg->content,
	qr/not logged in/i,
	"got an appropriate error"
);
is(
	$error->message->tx_id->client_id,
	"ÄBC-12345", "returned client ID OK"
);

# 4. check that the login message results in queued back-end messages
$event->loop_until(
	sub {
		$event->queued("send_backend_queue");
	},
	[qw(input_event process_queue output_event)],
	"login produces a backend message",
);

ok(
	$session->backend_pending,
	"login message produced backend messages"
);
ok(
	$session->stalled,
	"waiting for login result before processing further commands"
);
my $rq = $session->next_message;
is(@{$rq->parts}, 3, "login makes 3 messages");
is_deeply(
	[ map { $_->message->root_element } @{$rq->parts} ],
	[
		qw(RegistrarDetailsQry AccessControlListQry
			AccessControlListQry)
	],
	"login message transform",
);

ok($event->queued("send_backend_queue"), "Session wants to send", );

use Crypt::Password;

# fake some responses.
$event->ignore("send_backend_queue");

my $password = XML::SRS::Password->new(
    crypted => Crypt::Password->new("foo-BAR2")."",
);

my $contact = XML::SRS::Contact->new(
	name => "Bob",
	email => 'bob@gmail.com',
);
my @action_rs = (
	XML::SRS::Registrar->new(
		id => "123",
		name => "Model Registrar",
		account_reference => "xx",
		epp_auth => $password,
		contact_public => $contact,
		contact_private => $contact,
		contact_technical => $contact,
		keyring => XML::SRS::Keyring->new(),
	),
	XML::SRS::ACL->new(
		Resource => "epp_connect",
		List => "allow",
		Size => 1,
		Type => "registrar_ip",
		entries => [
			XML::SRS::ACL::Entry->new(
				Address => "101.1.5.0/24",
				RegistrarId => "90",
				Comment => "Test Registrar Netblock",
			),
		],
	),
	XML::SRS::ACL->new(
		Resource => "epp_client_certs",
		List => "allow",
		Size => 1,
		Type => "registrar_domain",
		entries => [
			XML::SRS::ACL::Entry->new(
				DomainName => "*.client.cert.example.com",
				RegistrarId => "90",
				Comment => "Test Registrar Key",
			),
		],
	),
);

use MooseX::TimestampTZ;

my @rs = map {
	XML::SRS::Result->new(
		action => $_,
		fe_id => "2",
		unique_id => "1234",
		by_id => "123",
		server_time => timestamptz,
		response => shift(@action_rs),
		)
	}
	map {
	$_->message->root_element
	}
	@{$rq->parts};

my $srs_rs = XML::SRS::Response->new(
	version => "auto",
	results => \@rs,
	RegistrarId => 90,
);

my $rs_tx = SRS::EPP::SRSMessage->new( message => $srs_rs );
$session->be_response($rs_tx);

# now, with the response there, process_replies should be ready.
ok(
	$event->queued("process_responses"),
	"Session wants to process that response",
);

my $response;
$event->loop_until(
	sub { $response = $session->io->get_packet },
	[
		qw(send_pending_replies input_event process_queue
			process_responses output_event)
	],
	"response produced",
);

is($response->message->result->[0]->code, 1000, "Login successful!");

# now we should have a response ready to go
ok($session->user, "Session now authenticated");

$session->input_event;

# ... and we should eventually log out
my @expected = qw(process_queue send_pending_replies output_event);
my $failed = 0;
event:
while ( my @events = $session->event->queued_events ) {
	$session->input_event if $session->io->input;
	for my $event (@events) {
		unless ($event ~~ @expected) {
			fail("weren't expecting $event");
			$failed = 1;
			last event;
		}
		$session->$event;
	}
}
pass("events as expected") unless $failed;

my $goodbye = $session->io->get_packet;
is(eval{$goodbye->message->result->[0]->code}, 1500, "logout response");

# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>

