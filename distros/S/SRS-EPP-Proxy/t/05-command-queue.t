#!/usr/bin/perl -w
#
# test the command queue class

use strict;
use Test::More qw(no_plan);

use SRS::EPP::Command;
use SRS::EPP::Response;

BEGIN {
	use_ok("SRS::EPP::Session::CmdQ");
}

# the command queue - queues SRS::EPP::Command objects, and their
# SRS::EPP::Response partners

{

	package Mock::Anything;
	sub isa {1}  # trump most type constraints :->

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
		message => Mock::Anything->new(),
	),
);

# is answered by a *single* EPP response
my $response = SRS::EPP::Response->new(
	code => 1000,
	message => Mock::Anything->new(
		response => 1,
		name => "greeting",
	),
);

# Ad infinitum
my @commands = qw(check1 info create1 transfer1 delete1 transfer2
	delete2 create2 check2);

my @command_rq = map {
	SRS::EPP::Command->new(
		message => Mock::Anything->new(
			name => $_,
			message => Mock::Anything->new(),
		),
	);
} @commands;

my @command_rs = map {
	SRS::EPP::Response->new(
		code => 1000,
		message => Mock::Anything->new(
			name => $_,
			request => 1,
			message => Mock::Anything->new(),
		),
	);
} @commands;

# ok.  we've got some data, construct our test object.
my $cq = SRS::EPP::Session::CmdQ->new();
isa_ok(
	$cq, "SRS::EPP::Session::CmdQ",
	"SRS::EPP::Session::CmdQ->new()"
);

# some basic tests
is($cq->commands_queued, 0, "->commands_queued (null)");
ok(!$cq->response_ready, "->response_ready (null)");

# data in: enqueue the command and SRS Request objects
$cq->queue_command($command);

is($cq->commands_queued, 1, "->commands_queued (added rq)");

# state change: grab requests to begin processing
my $rq = $cq->next_command;

is($cq->commands_queued, 1, "->commands_queued (sent rq)");
ok(!$cq->response_ready, "->response_ready (sent rq)");
ok(!$cq->next_command, "->next_command (empty q)");

# state change: back-end returns with response.
$cq->add_command_response($response, $command);

is($cq->commands_queued, 1, "->commands_queued (got rs)");
ok($cq->response_ready, "->response_ready (got rs)");

# dequeue
my $rs = $cq->dequeue_response;
is($rs, $response, "->dequeue_response (got rs)");
is($cq->commands_queued, 0, "->commands_queued (dequeued rs)");
ok(!$cq->response_ready, "->response_ready (dequeued rs)");

# now throw the rest at it!
my @rq_q = @command_rq;
my @rs_q = @command_rs;
srand 1042;
my @output_q;
while ( @rq_q or @rs_q ) {
	if ( @rq_q and rand(1) < 0.5 ) {
		$cq->queue_command(shift @rq_q);
	}
	if ( @rs_q > @rq_q and rand(1) < 0.4 ) {
		my $rs = shift @rs_q;
		$cq->add_command_response($rs);
	}
	if ( rand(1) < 0.6 and $cq->response_ready ) {
		my @output = $cq->dequeue_response;
		if (@output) {
			push @output_q, \@output;
		}
	}
}
push @output_q, [ $cq->dequeue_response ]
	while $cq->response_ready;

is(
	$cq->next, 0,
	"->next not decremented even if the commands were not dequeued"
);

ok(
	!(
		grep{
			my $rv = (
				!$output_q[$_]
					or
					!$output_q[$_][0]->message->request
					or
					$output_q[$_][1]->message->request
					or
					$output_q[$_][0] != $command_rs[$_]
					or
					$output_q[$_][1] != $command_rq[$_]
			);

			#$DB::single = 1 if $rv;
			$rv;
		} 0..$#command_rq
	),
	"got results back in correct order"
	)
	or do {
	require Data::Dumper;
	diag("results: ".Data::Dumper::Dumper(\@output_q));
	};

$cq->queue_command( $command_rq[0] );
$cq->add_command_response($command_rs[0]);

is(
	$cq->next_command, undef,
	"commands with immediate responses not returned by ->next_command"
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
