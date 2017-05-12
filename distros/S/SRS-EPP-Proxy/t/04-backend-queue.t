#!/usr/bin/perl -w
#
# test the backend queue class

use strict;
use Test::More qw(no_plan);

BEGIN {
	use_ok("SRS::EPP::Session::BackendQ");
}

# the backend queue - queues SRS::Request objects, associated with
# SRS::EPP::Command objects.

{

	package Mock::Anything;
	sub isa {1}  # trump most type constraints :->
	use Moose;
	sub root_element {'yomomma'}
	with 'XML::SRS::Action';  # fool a role typeconstraint

	sub new {
		my $class = shift;
		bless {@_}, $class;
	}
	our $AUTOLOAD;

	sub AUTOLOAD {
		my $self = shift;
		$AUTOLOAD=~/.*::(.*)/;
		if (@_) {
			$self->{$1} = shift;
		}
		else {
			$self->{$1};
		}
	}
}

# here's the abstract model: a *single* EPP command,
my $command = SRS::EPP::Command->new(
	message => Mock::Anything->new(
		name => "login",
		message => Mock::Anything->new(
			)
	),
);

# converts to a *list* of SRS Actions / Queries, eg
my @commands = qw(RegistrarDetailsQry AccessControlListQry1
	AccessControlListQry2);
my @command_rq = map {
	SRS::EPP::SRSRequest->new(
		message => Mock::Anything->new(
			request => 1,
			name => $_,
		),
	);
} @commands;

# each action/query has a response/error
my @command_rs = map {
	SRS::EPP::SRSResponse->new(
		message => Mock::Anything->new(
			response => 1,
			name => $_,
		),
	);
} @commands;

# ok.  we've got some data, construct our test object.
my $BE_q = SRS::EPP::Session::BackendQ->new();
isa_ok(
	$BE_q, "SRS::EPP::Session::BackendQ",
	"SRS::EPP::Session::BackendQ->new()"
);

# some basic tests
is($BE_q->queue_size, 0, "->queue_size (null)");
is($BE_q->backend_pending, 0, "->backend_pending (null)");
ok(!$BE_q->backend_response_ready, "->backend_response_ready (null)");

# data in: enqueue the command and SRS Request objects
$BE_q->queue_backend_request( $command, @command_rq );

is($BE_q->queue_size, 3, "->queue_size (added rq)");
is($BE_q->backend_pending, 3, "->backend_pending (added rq)");

# state change: grab requests to shove into XML::SRS::Request
# containers and issue to the registry
my @rq = $BE_q->backend_next(2);

is($BE_q->queue_size, 3, "->queue_size (sent rq)");
is($BE_q->backend_pending, 1, "->backend_pending (sent rq)");
ok(!$BE_q->backend_response_ready, "->backend_response_ready (sent rq)");

# state change: back-end returns with response.
$BE_q->add_backend_response(shift(@rq), shift(@command_rs)) for 1..2;

# nothing changed yet!  No commands are notified of responses until
# they are all received.
is($BE_q->queue_size, 3, "->queue_size (sent rq)");
is($BE_q->backend_pending, 1, "->backend_pending (sent rq)");
ok(!$BE_q->backend_response_ready, "->backend_response_ready (sent rq)");

# so process the next batch
@rq = $BE_q->backend_next(2);
is(@rq, 1, "->backend_next(X) where X > ->backend_pending");
is($BE_q->backend_pending, 0, "->backend_pending (sent all rq)");
ok(!$BE_q->backend_response_ready, "->backend_response_ready (sent all rq)");

$BE_q->add_backend_response($rq[0], shift(@command_rs));
ok($BE_q->backend_response_ready, "->backend_response_ready (got all rs)");

my ($owner, @rs) = $BE_q->dequeue_backend_response;
is($owner, $command, "->dequeue_backend_response (got all rs) - correct command");
is(@rs, 3, "->dequeue_backend_response (got all rs) - correct # responses");

ok(
	!(
		grep{
			$rs[$_]->message->name ne $command_rq[$_]->message->name
				or !$rs[$_]->message->response
		}
		0..2
	),
	"got results back in correct order"
);

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
