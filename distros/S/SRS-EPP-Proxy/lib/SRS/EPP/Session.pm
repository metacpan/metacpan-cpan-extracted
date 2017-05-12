# vim: filetype=perl:noexpandtab:ts=3:sw=3
#
# Copyright (C) 2009  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.  You should
# have received a copy of the Artistic License the file COPYING.txt.
# If not, see <http://www.perlfoundation.org/artistic_license_2_0>

package SRS::EPP::Session;
{
  $SRS::EPP::Session::VERSION = '0.22';
}

# this object is unfortunately something of a ``God Object'', but
# measures are taken to stop that from being awful; mostly delegation
# to other objects

use 5.010;
use strict;

use Moose;
use MooseX::Params::Validate;
use Scalar::Util qw(blessed);
use Data::Dumper;
use Carp;

with 'MooseX::Log::Log4perl::Easy';

# messages that we use
# - XML formats
use XML::EPP;
use XML::SRS;

# - wrapper classes
use SRS::EPP::Command;
use SRS::EPP::Response;
use SRS::EPP::Response::Error;
use SRS::EPP::SRSMessage;
use SRS::EPP::SRSRequest;
use SRS::EPP::SRSResponse;

# queue classes and slave components
use SRS::EPP::Packets;
use SRS::EPP::Session::CmdQ;
use SRS::EPP::Session::BackendQ;
use SRS::EPP::Proxy::UA;

# other includes
use HTTP::Request::Common qw(POST);
use bytes qw();
use utf8;
use Encode qw(decode encode);

our %SSL_ERROR;

BEGIN {
	my @errors =
		qw( NONE ZERO_RETURN WANT_READ WANT_WRITE WANT_CONNECT
		WANT_X509_LOOKUP SYSCALL SSL );
	%SSL_ERROR = map { $_ => undef } @errors;
}
use Net::SSLeay::OO::Constants map {"ERROR_$_"} keys %SSL_ERROR;

BEGIN {
	no strict 'refs';
	$SSL_ERROR{$_} = &{"ERROR_$_"}
		for keys %SSL_ERROR;
}

has io => (
	is => "ro",
	isa => "Net::SSLeay::OO::SSL",
);

# so the socket doesn't fall out of scope and get closed...
has 'socket' => (
	is => "ro",
	isa => "IO::Handle",
);

has user => (
	is => "rw",
	isa => "Maybe[Str]",
);

# hack for login message
has want_user => (
	is => "rw",
	isa => "Str",
	clearer => "clear_want_user",
);

# this "State" is the state according to the chart in RFC3730 and is
# updated for amusement's sake only
has state => (
	is => "rw",
	isa => "Str",
	default => "Waiting for Client",
	trigger => sub {
		my $self = shift;
		if ( $self->has_proxy ) {
			$self->proxy->show_state(shift, $self);
		}
	},
);

has 'proxy' => (
	is => "ro",
	isa => "SRS::EPP::Proxy",
	predicate => "has_proxy",
	weak_ref => 1,
	handles => [qw/openpgp/],
	required => 1,
);

# this object is billed with providing an Event.pm-like interface.
has event => (
	is => "ro",
	required => 1,
);

has output_event_watcher => (
	is => "rw",
);

has input_event_watcher => (
	is => "rw",
);

# 'yield' means to queue an event for running but not run it
# immediately.
has 'yielding' => (
	is => "ro",
	isa => "HashRef",
	default => sub { {} },
);

sub yield {
    my $self = shift;
    
    my ( $method ) = pos_validated_list(
        [shift],
        { isa => 'Str' },
    );
    
    my @args = @_;
    
	my $trace;
	if ( $self->log->is_trace ) {
		my $caller = ((caller(1))[3]);
		$self->log_trace(
			"$caller yields $method"
				.(@args?" (with args: @args)":"")
		);
	}
	if ( !@args ) {
		if ( $self->yielding->{$method} ) {
			$self->log_trace(" - already yielding");
			return;
		}
		else {
			$self->yielding->{$method} = 1;
		}
	}
	$self->event->timer(
		desc => $method,
		after => 0,
		cb => sub {
			delete $self->yielding->{$method};
			if ( $self->log->is_trace ) {
				$self->log_trace(
					"Calling $method".(@args?"(@args)":"")
				);
			}

			my $ok = eval {
				$self->$method(@args);
				1;
			};
			my $error = $@;
			if (!$ok) {
				my $message = "Uncaught exception when yielding to "
					."$method: $error";
				$self->log_error($message);

				die $error || $message;
			}
		},
	);
}

has 'connection_id' => (
	is => "ro",
	isa => "Str",
	default => sub {
		sprintf("sep.%x.%.4x",time(),$$&65535);
	},
);

has 'peerhost' => (
	is => "rw",
	isa => "Str",
);

has 'peer_cn' => (
	is => "rw",
	isa => "Str",
);

has 'server_id_seq' => (
	is => "rw",
	isa => "Num",
	traits => [qw/Number/],
	handles => {
		'inc_server_id' => 'add',
	},
	default => 0,
);

use SRS::EPP::Session::Extensions;
has 'extensions' => (
	is => "ro",
	isa => 'SRS::EPP::Session::Extensions',
	default => sub {
		SRS::EPP::Session::Extensions->new(),
	}
);

# called when a response is generated from the server itself, not the
# back-end.  Return an ephemeral ID based on the timestamp and a
# session counter.
sub new_server_id {
    my $self = shift;
    
	$self->inc_server_id(1);
	my $id = $self->connection_id.".".sprintf("%.3d",$self->server_id_seq);
	$self->log_trace("server-generated ID is $id");
	$id;
}

#----
# input packet chunking
has 'input_packeter' => (
	default => sub {
		my $self = shift;
		SRS::EPP::Packets->new(session => $self);
	},
	handles => [qw( input_event input_state input_expect )],
);

sub read_input {
    my $self = shift;
    
    my ( $how_much ) = pos_validated_list(
        \@_,
        { isa => 'Int', },
    );
    
    croak '$how_much must be > 0' unless $how_much > 0;
    
	my $rv = $self->io->read($how_much);

	if (! defined $rv) {
	    # Error occured during read
	    my ($error, $error_name, $err_info) = $self->get_last_ssl_error;

		$self->log_error("error on write; $error_name ($err_info)");
	}

	$self->log_trace("read_input($how_much) = ".bytes::length($rv));
	return $rv;
}

sub input_ready {
    my $self = shift;
    
	!!$self->io->peek(1);
}

# convert input packets to messages
sub input_packet {
    my $self = shift;
    
    my ( $data ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );    
    
	$self->log_debug("parsing ".bytes::length($data)." bytes of XML");
	my $msg = eval {
		if ( !utf8::is_utf8($data) ) {
			my $pre_length = bytes::length($data);
			$data = decode("utf8", $data);
			my $post_length = length($data);
			if ( $pre_length != $post_length ) {
				$self->log_debug(
					"data is $post_length unicode characters"
				);
			}
		}
		$self->log_packet("input", $data);
		XML::EPP->parse($data);
	};
	my $error = ( $msg ? undef : $@ );
	if ($error) {
		my $err_str = "".$error;
		$self->log_info("error parsing message: $err_str");
	}
	my $queue_item = SRS::EPP::Command->new(
		( $msg ? (message => $msg) : () ),
		xml => $data,
		( $error ? (error => $error) : () ),
		session => $self,
	);
	$self->log_info("queuing command: $queue_item");
	$self->queue_command($queue_item);
	if ($error) {
		my $error_rs = SRS::EPP::Response::Error->new(
			(
				$queue_item->client_id
				? (client_id => $queue_item->client_id)
				: ()
			),
			server_id => $self->new_server_id,
			exception => $error,
		);
		$self->log_info("queuing response: $error_rs");
		$self->add_command_response(
			$error_rs,
			$queue_item,
		);
		$self->yield("send_pending_replies");
	}
	else {
		$self->yield("process_queue");
	}
}

#----
# queues
has 'processing_queue' => (
	is => "ro",
	default => sub {
		my $self = shift;
		SRS::EPP::Session::CmdQ->new();
	},
	handles => [
		qw( queue_command next_command
			add_command_response commands_queued
			response_ready dequeue_response )
	],
);

has 'backend_queue' => (
	is => "ro",
	default => sub {
		my $self = shift;
		SRS::EPP::Session::BackendQ->new();
	},
	handles => [
		qw( queue_backend_request backend_next
			backend_pending
			add_backend_response backend_response_ready
			dequeue_backend_response get_owner_of_request )
	],
);

# this shouldn't be required... but is a good checklist
sub check_queues() {
    my $self = shift;
    
	$self->yield("send_pending_replies")
		if $self->response_ready;
	$self->yield("process_queue")
		if !$self->stalled and $self->commands_queued;
	$self->yield("process_responses")
		if $self->backend_response_ready;
	$self->yield("send_backend_queue")
		if $self->backend_pending;
}

# "stalling" means that no more processing can be advanced until the
# responses to the currently processing commands are available.
#
#  eg, "login" and "logout" both stall the queue, as will the
#  <transform><renew> command, if we have to first query the back-end
#  to determine what the correct renewal message is.
#
#  the value in 'stalled' is the command which stalled the pipeline;
#  so that it can be restarted without the command doing anything
#  special.
has stalled => (
	is => "rw",
	isa => "Maybe[SRS::EPP::Command|Bool]",
	trigger => sub {
		my $self = shift;
		my $val = shift;
		$self->log_debug(
			"processing queue is ".($val?"":"un-")."stalled"
		);
		if ( !$val ) {
			$self->check_queues;
		}
		}
);

sub process_queue {
    my $self = shift;
    
    my ( $count ) = pos_validated_list(
        \@_,
        { isa => 'Int', default => 1 },
    );    
    
	while ( $count-- > 0 ) {
		if ( $self->stalled ) {
			$self->state("Processing Command");
			$self->log_trace("stalled; not processing");
			last;
		}
		my $command = $self->next_command or last;
		$self->log_info(
			"processing command $command"
		);
		if ( $command->simple ) {

			# "simple" commands include "hello" and "logout"
			my $response = $command->process($self);
			$self->log_debug(
				"processed simple command $command; response is $response"
			);
			$self->add_command_response($response, $command);
		}
		elsif ( $command->authenticated xor $self->user ) {
			my $reason = ($self->user?"already":"not")." logged in";
			$self->add_command_response(
				$command->make_response(
					Error => (
						code => 2001,
						exception => $reason,
						)
				),
				$command,
			);
			$self->log_info(
				"rejecting command: $reason"
			);
		}
		else {

			# regular message which may need to talk to
			# the SRS backend
			my @messages = eval {
				$command->process($self);
			};
			my $error = $@;
			$self->process_notify_result( $command, $error, @messages );
		}
		$self->yield("send_pending_replies")
			if $self->response_ready;
	}
}

sub process_notify_result {
    my $self = shift;    
    
    my ( $command ) = pos_validated_list(
        [shift],
        { isa => 'SRS::EPP::Command', },
    );
    my ($error, @messages) = @_;
    
	$self->log_debug(
		"$command process/notify result: error=".($error//"(none)")
			.", ".(@messages?"messages=@messages":"no messages"),
	);
	if (!@messages or !blessed($messages[0])) {
		$self->log_info(
			$error
			? "Error when calling process on $command: $error"
			: "Unblessed return from process: @messages"
		);

		my $error_resp = $command->make_error(
			($error ? (exception => $error) : ()),
			code => 2400,
		);
		@messages = $error_resp;
	}

	# convert unwrapped responses to wrapped ones
	if ( $messages[0]->isa('XML::EPP') ) {

		# add these messages to the outgoing queue
		die "wrong" if @messages > 1;
		my $response = SRS::EPP::EPPResponse->new(
			message => $messages[0],
		);
		@messages = $response;
	}

	# check what kind of messages these are
	if (
		$messages[0]->does('XML::SRS::Action') ||
		$messages[0]->does('XML::SRS::Query')
		)
	{
		foreach my $i (0 .. $#messages) {
			# Make sure every message has a unique action or query id
			# TODO: perhaps we should override anything the mapping has set, so we can
			#  be sure it is actually unique. Would also make sense to have one place
			#  where the ids are controlled.
			unless ($messages[$i]->unique_id) {
				my $id = $command->client_id || $command->server_id;
				$id .= "[$i]" if scalar @messages > 1;
				$messages[$i]->unique_id($id);
			}

			$messages[$i] = SRS::EPP::SRSRequest->new( message => $messages[$i], );
		}

		$self->log_info( "$command produced ".@messages." SRS message(s)" );
		$self->queue_backend_request( $command, @messages, );
		if ( $command->isa("SRS::EPP::Command::Login") ) {
			$self->state("Processing <login>");
		}
		else {
			$self->state("Processing Command");
		}
		$self->yield("send_backend_queue");
	}
	elsif ( $messages[0]->isa('SRS::EPP::Response') )
	{
		if ( $self->stalled and $self->stalled == $command ) {
			$self->log_info(
				$error
				? "re-enabling pipeline after command received untrapped error"
				: "command did not re-enable processing pipeline!"
			);
			$self->stalled(0);
		}
		$self->log_info("$command produced $messages[0]");
		$self->add_command_response( $messages[0], $command, );

		$self->yield("send_pending_replies")
 			if $self->response_ready;
	}
	else {

		# We got something else unknown... return an error
		$self->log_debug(
			"process_queue: Unknown message type - $messages[0] ... doesn't appear"
				." to be a SRS or EPP request, returning error"
		);
		my $rs = $command->make_response(
			code => 2400,
		);
		$self->add_command_response( $rs, $command, );
	}
}

#----
# method to say "we're connected, so send a greeting"; if this class
# were abstracted to not run over a stream transport then this would
# be important.
sub connected {
    my $self = shift;
    
	$self->state("Prepare Greeting");
	my $response = SRS::EPP::Response::Greeting->new(
		session => $self,
	);
	$self->log_info(
		"prepared greeting $response for ".$self->peerhost
	);
	my $socket_fd = $self->io->get_fd;
	$self->log_trace("setting up io event handlers for FD $socket_fd");
	my $w = $self->event->io(
		desc => "input_event",
		fd => $socket_fd,
		poll => 'r',
		cb => sub {
			$self->log_trace("got input callback");
			$self->input_event;
		},
		timeout => $self->timeout,
		timeout_cb => sub {
			$self->log_trace("got input timeout event");
			$self->input_timeout;
		},
	);
	$self->input_event_watcher($w);

	$w = $self->event->io(
		desc => "output_event",
		fd => $socket_fd,
		poll => 'w',
		cb => sub {
			$self->output_event;
		},
		timeout => $self->timeout,
		timeout_cb => sub {
			$self->log_trace("got output timeout event");
		},
	);
	$w->stop;
	$self->output_event_watcher($w);

	# Process signals every few seconds (if any were received)
	$self->event->timer(
		desc => "signal_handler_timer",
		after => 3,
		interval => 3,
		cb => sub {
		  $self->proxy->process_signals;
		},
	);

	$self->send_reply($response);
	$self->state("Waiting for Client Authentication");
}

#----
# Backend stuff.  Perhaps this should all go in the BackendQ class.

has 'backend_tx_max' => (
	isa => "Int",
	is => "rw",
	default => 10,
);

has 'user_agent' => (
	is => "rw",
	lazy => 1,
	default => sub {
		my $self = shift;
		my $ua = SRS::EPP::Proxy::UA->new(session => $self);
		$self->log_trace("setting up UA input event");
		my $w;
		$w = $self->event->io(
			desc => "user_agent",
			fd => $ua->read_fh,
			poll => 'r',
			cb => sub {
				if ( $self->user_agent ) {
					$self->log_trace(
						"UA input event fired, calling backend_response",
					);

					eval {
						$self->backend_response;
					};
					if ($@) {
						my $error =
							"Uncaught exception calling backend_response in user_agent: $@";
						$self->log_info($error);

						die $error;
					}
				}
				else {
					$self->log_trace(
						"canceling UA watcher",
					);
					$w->cancel;
				}
			},
		);
		$ua;
	},
	handles => {
		"user_agent_busy" => "busy",
	},
);

has 'backend_url' => (
	isa => "Str",
	is => "rw",
	required => 1,
);

has 'active_request' => (
	is => "rw",
	isa => "Maybe[SRS::EPP::SRSMessage]",
);

sub next_message {
    my $self = shift;
    
	my @next = $self->backend_next($self->backend_tx_max)
		or return;
	my $tx = XML::SRS::Request->new(
		version => "auto",
		requests => [ map { $_->message } @next ],
	);
	my $rq = SRS::EPP::SRSMessage->new(
		message => $tx,
		parts => \@next,
	);
	$self->log_info("creating a ".@next."-part SRS message");
	if ( $self->log->is_debug ) {
		$self->log_debug("parts: @next");
	}
	$self->active_request($rq);
	$rq;
}

sub send_backend_queue {
    my $self = shift;
    
	return if $self->user_agent_busy;

	my $tx = $self->next_message;
	my $xml = $tx->to_xml;
	$self->log_packet(
		"backend request",
		$xml,
	);
	my $sig = $self->openpgp->detached_sign($xml);
	$self->log_debug("signed XML message - sig is ".$sig)
		if $self->log->is_debug;
	my $reg_id = $self->user;
	if ( !$reg_id ) {
		$reg_id = $self->want_user;
	}

	# It seems like we are getting bytes from the XML libraries, but the 
	# HTTP::Request library wants chars.  This matters when we are dealing
	# with UNICODE.
	$xml = decode("utf8",$xml);

	my $req = POST(
		$self->backend_url,
		[
			r => $xml,
			s => $sig,
			n => $reg_id,
		],
	);
	$self->log_info(
		"posting to ".$self->backend_url." as registrar $reg_id"
	);

	$self->user_agent->request($req);
}

sub url_decode {
	my $url_encoded = shift;
	$url_encoded =~ tr{+}{ };
	$url_encoded =~ s{%([0-9a-f]{2})}{chr(hex($1))}eg;
	return $url_encoded;
}

#----
# Dealing with backend responses
sub backend_response {
    my $self = shift;
    
	my $response = $self->user_agent->get_response;

	# urldecode response; split response from fields
	my $content = $response->content;

	$self->log_debug(
		"received ".bytes::length($content)." bytes of "
			."response from back-end"
	);

	my %fields = map {
		my ($key, $value) = split "=", $_, 2;
		($key, decode("utf8", url_decode($value)));
	} split "&", $content;

	# check signature
	$self->log_debug("verifying signature");
	
	if ($fields{s}) {
	   $self->openpgp->verify_detached(data => $fields{r}, signature => $fields{s})
		  or die "failed to verify BE response integrity";
	}

	$self->log_packet("BE response", $fields{r});

	my $rs_tx = $self->parse_be_response($fields{r});
	return unless $rs_tx;

	$self->be_response($rs_tx);

	# user agent is now free, perhaps more messages are waiting
	$self->yield("send_backend_queue")
		if $self->backend_pending;
}

sub parse_be_response {
    my $self = shift;
    
    my ( $xml ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
    );    
    
	# decode message
	my $message = eval { XML::SRS::Response->parse($xml, 1) };
	my $error = $@;
	if ($error) {
		# Got an error parsing response. Log and generate a 2500 error
		$self->log_error("Exception parsing SRS Response: $error");

		my $request = $self->active_request;
		my $rq_parts = $request->parts;

		my $command = $self->get_owner_of_request($rq_parts->[0]);

		my $error_resp = SRS::EPP::Response::Error->new(
			code => 2500,
			server_id => 'unknown',
		);

		$self->add_command_response(
			$error_resp,
			$command,
		);
		$self->yield("send_pending_replies");
		$self->shutdown;

		return;

	}

	return SRS::EPP::SRSMessage->new( message => $message );
}

sub be_response {
    my $self = shift;
    
    my ( $rs_tx ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::SRSMessage' },
    );      
    
	my $request = $self->active_request;

 	my $rq_parts = $request->parts;
	my $rs_parts = $rs_tx->parts;
	my $result_id = eval { $rs_parts->[0]->message->result_id }
		|| "(no unique_id)";
	$self->log_info(
		"response $result_id from back-end has "
			.@$rs_parts." parts, "
			."active request ".@$rq_parts." parts"
	);
	if (
		@$rs_parts < @$rq_parts
		and @$rs_parts == 1
		and
		$rs_parts->[0]->message->isa("XML::SRS::Error")
		)
	{ 
		# this is a more fundamental type of error than others
		# ... 'extend' to the other messages
		@$rs_parts = ((@$rs_parts) x @$rq_parts);
	}

	(@$rq_parts == @$rs_parts) or do {
		die "rs parts != rq parts";
	};

	for (my $i = 0; $i <= $#$rq_parts; $i++ ) {
		if (@$rq_parts > 1) {
			eval { $rs_parts->[$i]->message->part($i+1); };
		}
		$self->add_backend_response($rq_parts->[$i], $rs_parts->[$i]);
	}
	$self->yield("process_responses");
}

sub process_responses {
    my $self = shift;
    
	while ( $self->backend_response_ready ) {
		my ($cmd, @rs) = $self->dequeue_backend_response;

		# for easier tracking of messages.
		if (
			my $server_id = eval {
				$rs[0]->message->result_id;
			}
			)
		{
			my $before = $cmd->server_id
				if $cmd->has_server_id;
			if ( @rs > 1 ) {
				$server_id .= "+".(@rs-1);
			}
			$cmd->server_id($server_id);
			if ($before) {
				my $after = $cmd->server_id;
				$self->log_info(
					"changing server_id: $before => $after"
				);
			}
		}

		my (@messages, $error);

		my $check_ok = eval { @messages = $self->check_for_be_error($cmd, @rs); 1 };
		$error = $@;
		if ( @messages or $error or !$check_ok ) {
			$self->log_error(
				"$cmd received "
					.(
					$error
					? "fault during BE error check"
					: (
						$check_ok
						? "untrapped SRS error"
						: "error without a clue"
						)
					)
			);
			$error ||= "SRS error";  # flag for process_notify_result
		}
		else {
			$self->log_info(
				"notifying command $cmd of back-end response"
			);
			@messages = eval{ $cmd->notify(\@rs) };
			$error = $@;
		}

		$self->process_notify_result($cmd, $error, @messages);
	}
}

# Check responses for an error from the SRS. If we find one, we create
#  an appropriate response and return it
sub check_for_be_error {
    my $self = shift;
    
    my ( $cmd ) = pos_validated_list(
        [shift],
        { isa => 'SRS::EPP::Command' },
    );
    
    my @rs = @_;

	my @errors;
	foreach my $rs (@rs) {
		my $message = $rs->message;

		my $resps = $message->can('responses')
			? $message->responses : [$message];

		next unless $resps;

		foreach my $resp (@$resps) {
			if ($resp->isa('XML::SRS::Error')) {
				push @errors, $resp;

				# If it's a system error (i.e. the
				# original message is an
				# XML::SRS::Error, not an error
				# wrapped in a response), or if this
				# command type doesn't expect multiple
				# responses, we're done here.

				last if $message->isa('XML::SRS::Error')
						|| !$cmd->multiple_responses;
			}
		}
	}

	if (@errors) {
		return $cmd->make_error_response(
			\@errors,
		);
	}

	return;
}

sub send_pending_replies {
    my $self = shift;
    
	while ( $self->response_ready ) {
		my $response = $self->dequeue_response;
		$self->log_info(
			"queuing response $response"
		);
		$self->send_reply($response);
	}
	if ( !$self->commands_queued ) {
		if ( $self->user ) {
			$self->state("Waiting for Command");
		}
		else {
			$self->state("Waiting for Client Authentication");
		}
	}
}

#----
# Sending responses back

# this is a queue of byte strings, which are ready for transmission
has 'output_queue' => (
	is => "ro",
	isa => "ArrayRef[Str]",
	default => sub { [] },
);

# this is the interface for sending replies.
sub send_reply {
    my $self = shift;
    
    my ( $rs ) = pos_validated_list(
        \@_,
        { isa => 'SRS::EPP::Response' },
    );    
    
	$self->log_debug(
		"converting response $rs to XML"
	);
	my $reply_data = $rs->to_xml;
	$self->log_packet("output", $reply_data);
	if ( utf8::is_utf8($reply_data) ) {
		$reply_data = encode("utf8", $reply_data);
	}
	$self->log_info(
		"response $rs is ".bytes::length($reply_data)
			." bytes long"
	);
	my $length = pack("N", bytes::length($reply_data)+4);
	push @{ $self->output_queue }, $length, $reply_data;
	$self->yield("output_event");
	my $remaining = 0;
	for ( @{ $self->output_queue }) {
		$remaining += bytes::length;
	}
	return $remaining;
}

# once we are "shutdown", no new commands will be allowed to process
# (stalled queue) and the connection will be disconnected once the
# back-end processing and output queue is cleared.
has 'shutting_down' => (
	is => "rw",
	isa => "Bool",
);

sub shutdown {
    my $self = shift;
    
	$self->log_info("shutting down session");
	$self->state("Shutting down");
	$self->stalled(1);
	$self->shutting_down(1);
	$self->yield("output_event");
}

has 'timeout' => (
	is => "ro",
	isa => "Int",
	default => 300,
);

sub input_timeout {
    my $self = shift;

	# just hang up...
	$self->shutdown;
}

sub do_close {
    my $self = shift;
    

	# hang up on us without logging out will you?  Well, we'll
	# just have to close your TCP session without properly closing
	# SSL.  Take that.
	$self->log_debug("shutting down Socket");
	$self->socket->shutdown(1);
	$self->log_debug("shutting down user agent");
	$self->user_agent(undef);
	$self->input_event_watcher->cancel;
	$self->event->unloop_all;
}

# called when input_event fires, but nothing is readable.
sub empty_read {
    my $self = shift;
    
	$self->log_info("detected EOF on input");
	$self->do_close;
}

sub output_event {
    my $self = shift;
    
	my $oq = $self->output_queue;

	my $written = $self->write_to_client($oq);

	if (@$oq) {
		$self->output_event_watcher->start;
	}
	else {
		$self->output_event_watcher->stop;
		$self->log_info("flushed output to client");
		if ( $self->shutting_down ) {
			$self->check_queues;

			# if check_queues didn't yield any events, we're done.
			if ( !keys %{$self->yielding} ) {
				$self->do_close;
			}
			else {
				$self->log_debug(
					"shutdown still pending: @{[keys %{$self->yielding}]}"
				);
			}
		}
	}
	return $written;
}

# write as much to the client as the output buffer will accept this
# time around and re-queue any partial fragments
sub write_to_client {
    my $self = shift;
    
    my ( $oq ) = pos_validated_list(
        \@_,
        { isa => 'ArrayRef' },
    ); 
    
	my $written = 0;
	my $io = $self->io;
	while (@$oq) {
		my $datum = shift @$oq;
		my $wrote = $io->write($datum);
		if ( $wrote <= 0 ) {		    
			my ($error, $error_name, $err_info) = $self->get_last_ssl_error($wrote);

			if ( $error == $SSL_ERROR{WANT_READ} ) {
				# try calling input_event straight away
				$self->log_debug("got WANT_READ during write to client, calling input_event()");

				$self->input_event;
			}
			elsif ($error != $SSL_ERROR{NONE}) {
				# Got an error we couldn't handle, probably can't continue with this connection
				$self->log_error("error on write; $error_name (ret: $wrote, $err_info)");
				die "Error writing to client: $err_info\n";
			}

			unshift @$oq, $datum;
			last;
		}
		else {

			# thankfully, this is returned in bytes.
			$written += $wrote;
			if ( $wrote < bytes::length $datum ) {
				unshift @$oq, bytes::substr $datum, $wrote;
				last;
			}
		}
	}
	$self->log_trace(
		"write_to_client wrote $written bytes, ".@$oq." chunk(s) remaining"
	);

	return $written;
}

sub get_last_ssl_error {
	my $self = shift;
	my $ret = shift;

	my $io = $self->io;

	my $error = $io->get_error($ret);
	my $err_info = "err = $error";
	if ( $error == $SSL_ERROR{SYSCALL} ) {
		$err_info .= ", \$! = $!";
	}

	my ($error_name) = grep { $SSL_ERROR{$_} == $error }
		keys %SSL_ERROR;

	return ($error, $error_name, $err_info);   
}

sub log_packet {
    my $self = shift;
    
    my ( $label, $data ) = pos_validated_list(
        \@_,
        { isa => 'Str' },
        { isa => 'Str' },
    );        
        
    
	$data =~ s{([\0-\037])}{chr(ord($1)+0x2400)}eg;
	$data =~ s{([,\|])}{chr(ord($1)+0xff00-0x20)}eg;
	my @data;
	while ( length $data ) {
		push @data, substr $data, 0, 1024, "";
	}
	for (my $i = 0; $i <= $#data; $i++ ) {
		my $n_of_n = (@data > 1 ? " [".($i+1)." of ".@data."]" : "");
		$self->log_info(
			"$label message$n_of_n: "
				.encode("utf8", $data[$i]),
		);
	}
}
1;

__END__

=head1 NAME

SRS::EPP::Session - logic for EPP Session State machine

=head1 SYNOPSIS

 my $session = SRS::EPP::Session->new( io => $socket );

 #--- session events:

 $session->connected;
 $session->input_event;
 $session->input_packet($data);
 $session->queue_command($command);
 $session->process_queue($count);
 $session->be_response($srs_rs);
 $session->send_pending_replies();
 $session->send_reply($response);
 $session->output_event;

 #--- information messages:

 # print RFC3730 state eg 'Waiting for Client',
 # 'Prepare Greeting' (see Page 4 of RFC3730)
 print $session->state;

 # return the credential used for login
 print $session->user;

=head1 DESCRIPTION

The SRS::EPP::Session class manages the flow of individual
connections.  It implements the "EPP Server State Machine" from
RFC3730, as well as the exchange encapsulation described in RFC3734
"EPP TCP Transport".

This class is designed to be called from within an event-based
framework; this is fairly essential in the context of a server given
the potential to deadlock if the client does not clear its responses
in a timely fashion.

Input commands go through several stages:

=over

=item *

First, incoming data ready is chunked into complete EPP requests.
This is a binary de-chunking, and is based on reading a packet length
as a U32, then waiting for that many octets.  See L</input_event>

=item *

Complete chunks are passed to the L<SRS::EPP::Command> constructor for
validation and object construction.  See L</input_packet>

=item *

The constructed object is triaged, and added to an appropriate
processing queue.  See L</queue_command>

=item *

The request is processed; either locally for requests such as
C<E<gt>helloE<lt>>, or converted to the back-end format
(L<SRS::Request>) and placed in the back-end queue (this is normally
immediately dispatched).  See L</process_queue>

=item *

The response (a L<SRS::Response> object) from the back-end is
received; this is converted to a corresponding L<SRS::EPP::Response>
object.  Outstanding queued back-end requests are then dispatched if
they are present (so each session has a maximum of one outstanding
request at a time).  See L</be_response>

=item *

Prepared L<SRS::EPP::Response> objects are queued, this involves
individually converting them to strings, which are sent back to the
client, each response its own SSL frame.  See L</send_reply>

=item *

If the output blocks, then the responses wait and are sent back as
the response queue clears.  See L</output_event>

=back

=head1 METHODS

=head2 connected()

This event signals to the Session that the client is now connected.
It signals that it is time to issue a C<E<gt>greetingE<lt>> response,
just as if a C<E<gt>helloE<lt>> message had been received.

=head2 input_event()

This event is intended to be invoked whenever there is data ready to
read on the input socket.  It returns false if not enough data could
be read to get a complete subpacket.

=head2 input_packet($data)

This message is self-fired with a complete packet of data once it has
been read.

=head2 queue_command($command)

Enqueues an EPP command for processing and does nothing else.

=head2 process_queue($count)

Processes the back-end queue, up to C<$count> at a time.  At the end
of this, if there are no outstanding back-end transactions, any
produced L<SRS::Request> objects are wrapped into an
L<SRS::Transaction> object and dispatched to the back-end.

Returns the number of commands remaining to process.

=head2 be_response($srs_rs)

This is fired when a back-end response is received.  It is responsible
for matching responses with commands in the command queue and
converting to L<SRS::EPP::Response> objects.

=head2 send_pending_replies()

This is called by process_queue() or be_response(), and checks each
command for a corresponding L<SRS::EPP::Response> object, dequeues and
starts to send them back.

=head2 send_reply($response)

This is called by send_pending_replies(), and converts a
L<SRS::EPP::Response> object to network form, then starts to send it.
Returns the total number of octets which are currently outstanding; if
this is non-zero, the caller is expected to watch the output socket
for writability and call L<output_event()> once it is writable.

=head2 output_event()

This event is intended to be called when the return socket is newly
writable; it writes everything it can to the output socket and returns
the number of bytes written.

=head1 SEE ALSO

L<SRS::EPP::Command>, L<SRS::EPP::Response>

=cut

# Local Variables:
# mode:cperl
# indent-tabs-mode: t
# cperl-continued-statement-offset: 8
# cperl-brace-offset: 0
# cperl-close-paren-offset: 0
# cperl-continued-brace-offset: 0
# cperl-continued-statement-offset: 8
# cperl-extra-newline-before-brace: nil
# cperl-indent-level: 8
# cperl-indent-parens-as-block: t
# cperl-indent-wrt-brace: nil
# cperl-label-offset: -8
# cperl-merge-trailing-else: t
# End:

