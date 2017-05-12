package Protocol::IMAP::Client;
{
  $Protocol::IMAP::Client::VERSION = '0.004';
}
use strict;
use warnings;
use parent qw{Protocol::IMAP};

=head1 NAME

Protocol::IMAP::Client - client support for the Internet Message Access Protocol.

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 package Some::IMAP::Client;
 use parent 'Protocol::IMAP::Client';
 sub on_message { warn "new message!" }

 package main;
 my $client = Some::IMAP::Client->new;
 $client->login('user', 'pass');
 $client->idle;

=head1 DESCRIPTION

There are two standard modes of operation:

=over 4

=item * One-shot - connect to a server, process some messages, then disconnect

=item * Long-term connection - connect to a server, update status, then sit in idle mode waiting for events

=back

For one-shot operation against a server that doesn't keep you waiting, other more mature IMAP implementations
are suggested ("see also" section).

=head1 IMPLEMENTATION DETAILS

All requests from the client have a tag, which is a 'unique' alphanumeric identifier - it is the client's responsibility
to ensure these are unique for the session, see the L<next_id> method for the implementation used here.

Server responses are always one of three possible states:

=over 4

=item * B<OK> - Command was successful

=item * B<NO> - The server's having none of it

=item * B<BAD> - You sent something invalid

=back

with additional 'untagged' responses in between. Any significant data is typically exchanged in the untagged sections - the
final response to a command is indicated by a tagged response, once the client receives this then it knows that the server
has finished with the original request.

The IMAP connection will be in one of the following states:

=over 4

=item * ConnectionEstablished - we have a valid socket but no data has been exchanged yet, waiting for ServerGreeting

=item * ServerGreeting - server has sent an initial greeting, for some servers this may take a few seconds

=item * NotAuthenticated - server is waiting for client response, and the client has not yet been authenticated

=item * Authenticated - server is waiting on client but we have valid authentication credentials, for PREAUTH state this may happen immediately after ServerGreeting

=item * Selected - mailbox has been selected and we have valid context for commands

=item * Logout - logout request has been issued, waiting for server response

=item * ConnectionClosed - connection has been closed on both sides

=back

State changes are provided by the L<state> method. Some actions run automatically on state changes, for example switching to TLS mode and exchanging login information
when server greeting has been received.

=head1 IMPLEMENTING SUBCLASSES

The L<Protocol::IMAP> classes only provide the framework for handling IMAP data. Typically you would need to subclass this to get a usable IMAP implementation.

The following methods are required:

=over 4

=item * write - called at various points to send data back across to the other side of the IMAP connection

=item * on_user - called when the user name is required for the login stage

=item * on_pass - called when the password is required for the login stage

=item * start_idle_timer - switching into idle mode, hint to start the timer so that we can refresh the session as required

=item * stop_idle_timer - switch out of idle mode due to other tasks that need to be performed

=back

Optionally, you may consider providing these:

=over 4

=item * on_starttls - the STARTTLS stanza has been received and we need to upgrade to a TLS connection. This only applies to STARTTLS connections, which start in plaintext - a regular SSL connection will be SSL encrypted from the initial connection onwards.

=back

To pass data back into the L<Protocol::IMAP> layer, you will need the following methods:

=over 4

=item * is_multi_line - send a single line of data for handling

=item * on_single_line - send a single line of data for handling

=item * on_multi_line - send a multi-line section for handling

=back

=head1 LIMITATIONS

=over 4

=item * There is no provision for dealing with messages that exceed memory limits - if someone has a 2Gb email then this will attempt to read it
all into memory, and it's quite possible that buffers are being copied around as well.

=item * Limited support for some of the standard protocol pieces, since I'm mainly interested in pulling all new messages then listening for any
new ones.

=item * SASL authentication is not implemented yet.

=back

=head1 SEE ALSO

=over 4

=item * L<Mail::IMAPClient> - up-to-date, supports IDLE, generally seems to be the best of the bunch.

=item * L<Net::IMAP::Client> - rewritten version of Net::IMAP::Simple, seems to be well maintained and up to date although it's not been
around as long as some of the other options.

=item * L<Net::IMAP::Simple> - handy for simple one-off mailbox access although has a few API limitations.

=item * L<Net::IMAP> - over a decade since the last update, and doesn't appear to be passing on many platforms, but at least the API
is reasonably full-featured.

=back

=cut

use Protocol::IMAP::Fetch;
use List::Util qw(min);
use Try::Tiny;

=head1 METHODS

=cut

=head2 new

Instantiate a new object - the subclass does not need to call this if it hits L<configure> at some point before attempting to transfer data.

=cut

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	return $self;
}

sub on_read {
	my $self = shift;
	my $buffref = shift;

#	warn "on_read with " . $$buffref;
	if(my $fetch = $self->{fetching}) {
		return 0 if $fetch->on_read($buffref);
#		warn "Finished the read!\n";
		delete $self->{fetching};
		return 1;
	}

	if($self->is_multi_line) {
		$self->debug("Multi line: buffer has " . $$buffref);
		$self->on_multi_line($buffref);
		return 0;
	}

	if($$buffref =~ s/^(.*)[\r\n]+//) {
		$self->on_single_line($1);
		return 1;
		$self->debug("Switched to multiline mode") if $self->is_multi_line;
		return 1 if $self->is_multi_line;
	}
	return 0;
}

=head2 on_single_line

Called when there's more data to process for a single-line (standard mode) response.

=cut

sub on_single_line {
	my ($self, $data) = @_;

	$data =~ s/[\r\n]+//g;
	$self->debug("Had [$data]");

	if($self->in_state('ConnectionEstablished')) {
		$self->check_greeting($data);
	}

# Untagged responses either have a numeric or a text prefix
	if($data =~ /^\* ([A-Z]+) (.*?)$/) {
		# untagged
		$self->handle_untagged($1, $2);
	} elsif($data =~ /^\* (\d+) (.*?)$/) {
		# untagged
		$self->handle_numeric($1, $2);
	} elsif($data =~ /^([\w]+) (OK|NO|BAD) (.*?)$/i) {
# And tagged responses indicate that a server command has finished
		my $id = $1;
		my $status = $2;
		my $response = $3;
		$self->debug("Check for $1 with waiting: " . join(',', keys %{$self->{waiting}}));
		my $code = $self->{waiting}->{$id};
		$code->($status, $response) if $code;
		delete $self->{waiting}->{$id};
	}

	return 0 unless $self->is_multi_line;
	return $self->{multiline}->{remaining};
}

=head2 on_multi_line

Called when we have multi-line data (fixed size in characters).

=cut

sub on_multi_line {
	my ($self, $buffref) = @_;

	if($self->{multiline}->{remaining}) {
		my $chunk = substr $$buffref, 0, min($self->{multiline}->{remaining}, length $$buffref), '';
		$self->{multiline}->{buffer} .= $chunk;
		$self->{multiline}->{remaining} -= length $chunk;
	}

	if($self->{multiline}->{remaining} == 0) {
		$self->{multiline}->{on_complete}->($self->{multiline}->{buffer});
		delete $self->{multiline};
	}
	return $self;
}

=head2 handle_untagged

Process an untagged message from the server.

=cut

sub handle_untagged {
	my $self = shift;
	my ($cmd, $response) = @_;
	$self->debug("Had untagged: $cmd with data $response");
	my $method = join('_', 'check', lc $cmd);
	$self->$method($response) if $self->can($method);
	return $self;
}

=head2 untagged_fetch

Fetch untagged message data. Defines the multiline callback so that we build up a buffer for the data to process.

Once we call this method, the pending message takes over input until it has managed
to read the entire response.

=cut

sub untagged_fetch {
	my $self = shift;
	my ($idx, $data) = @_;
	$self->debug("Fetch data: $data");

	try {
		my $fetch = Protocol::IMAP::Fetch->new;
		$fetch->completion->on_done($self->{fetch_handler}[0]);
		push @{$self->{fetch_stack}}, $fetch;
		$self->{fetching} = $fetch if $fetch->on_read(\$data);
	} catch {
		warn "error: $_"
	};
	return $self;
}

sub untagged_list {
	my $self = shift;
	my ($idx, $data) = @_;
	$self->debug("List data: $data");

#	$fetch->completion->on_done($self->{fetch_handler}[0]);
	return $self;
}

=head2 handle_numeric

Deal with an untagged response with a numeric prefix.

=cut

sub handle_numeric {
	my $self = shift;
	my ($num, $data) = @_;
	$data =~ s/^(\w+)\s*//;
	my $cmd = $1;
	$self->debug("Now we have $cmd with $num");
	my $method = join('_', 'untagged', lc $cmd);
	$self->$method($num, $data) if $self->can($method);
	$self->{on_idle_update}->($cmd, $num) if $self->{on_idle_update} && $self->{in_idle};
	return $self;
}

=head2 on_server_greeting

Parse the server greeting, and move on to the capabilities step.

=cut

sub on_server_greeting {
	my $self = shift;
	my $data = shift;
	$self->debug("Had valid server greeting");
	($self->{server_name}) = $data =~ /^\* OK (.*?)$/;
	$self->get_capabilities;
}

=head2 on_not_authenticated

Handle the change of state from 'connected' to 'not authenticated', which indicates that we've had a valid server greeting and it's
time to get ourselves authenticated.

Depending on whether we're expecting (and supporting) the STARTTLS upgrade, we'll either switch to TLS mode at this point or just log
in directly.

=cut

sub on_not_authenticated {
	my $self = shift;
	if($self->{tls} && $self->{capability}->{STARTTLS} && !$self->{tls_enabled}) {
		return $self->starttls;
	} else {
		$self->debug("Attempt to log in");
		$self->invoke_event(authentication_required => );
	}
}

=head2 on_authenticated

What to do when we've been authenticated and are ready to begin the session. Suggest the subclass overrides this to make it do
something useful.

=cut

sub on_authenticated {
	my $self = shift;
	$self->debug("Authenticated session");
}

=head2 check_capability

Check the server capabilities, and store them locally.

=cut

sub check_capability {
	my $self = shift;
	my $data = shift;
	foreach my $cap (split ' ', $data) {
		$self->debug("Have cap: $cap");
		if($cap =~ /^auth=(.*)/i) {
			push @{ $self->{authtype} }, $1;
		} else {
			# Some servers have variations on the case here, fold to a standard case for ease of checking later
			$cap = 'IMAP4rev1' if lc $cap eq 'imap4rev1';
			$self->{capability}->{$cap} = 1;
		}
	}
	die "Not IMAP4rev1-capable" unless $self->{capability}->{'IMAP4rev1'};
	$self->on_capability($self->{capability});
}

=head2 on_capability

Virtual method called when we have capabilities back from the server.

=cut

sub on_capability {
	my $self = shift;
	my $caps = shift;
}

=head2 check_greeting

Verify that we had a reasonable response back from the server as an initial greeting, just in case someone pointed us at an SSH listener
or something equally unexpected.

=cut

sub check_greeting {
	my $self = shift;
	my $data = shift;
	if($data =~ /^\* OK/) {
		$self->state('ServerGreeting', $data);
	} else {
		$self->state('Logout');
	}
}

=head2 get_capabilities

Request capabilities from the server.

=cut

sub get_capabilities {
	my $self = shift;
	my %args = @_;
	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'CAPABILITY',
		on_ok		=> $self->_capture_weakself(sub {
			my $self = shift;
			my $data = shift;
			$self->debug("Successfully retrieved caps: $data");
			$self->state('NotAuthenticated');
			$f->done($data);
		}),
		on_bad		=> $self->_capture_weakself(sub {
			my $self = shift;
			my $data = shift;
			$self->debug("Caps retrieval failed: $data");
			$f->fail($data);
		})
	);
	$f
}

=head2 next_id

Returns the next ID in the sequence. Uses a standard Perl increment, tags are suggested to be 'alphanumeric'
but with no particular restrictions in place so this should be good for even long-running sessions.

=cut

sub next_id {
	my $self = shift;
	unless($self->{id}) {
		$self->{id} = 'A0001';
	}
	my $id = $self->{id};
	++$self->{id};
	return $id;
}

=head2 push_waitlist

Add a command to the waitlist.

Sometimes we need to wait for the server to catch up before sending the next entry.

TODO - maybe a mergepoint would be better for this?

=cut

sub push_waitlist {
	my $self = shift;
	my $id = shift;
	my $sub = shift;
	$self->{waiting}->{$id} = $sub;
	return $self;
}

=head2 send_command

Generic helper method to send a command to the server.

=cut

sub send_command {
	my $self = shift;
	my %args = @_;
	my $id = exists $args{id} ? $args{id} : $self->next_id;
	if($self->{in_idle} && defined $id) {
		# If we're currently in IDLE mode, we have to finish the current command first by issuing the DONE command.
		return $self->done(
			on_ok	=> $self->_capture_weakself(sub {
				my $self = shift;
				$self->{in_idle} = 0;
				$self->send_command(%args, id => $id);
			})
		);
	}

	my $cmd = $args{command};
	my $data = defined $id ? "$id " : '';
	$data .= $cmd;
	$data .= ' ' . $args{param} if $args{param};
	$self->push_waitlist($id, sub {
		my ($status, $data) = @_;
		my $method = join('_', 'on', lc $status);
		(delete $args{$method})->($data) if exists $args{$method};
		(delete $args{on_response})->("$status $data") if exists $args{on_response};
	}) if defined $id;
	$self->debug("Sending [$data] to server");
	if($self->{in_idle} && defined $id) {
# If we're currently in IDLE mode, we have to finish the current command first by issuing the DONE command.
		$self->{idle_queue} = $data;
		$self->done;
	} else {
		$self->debug("In idle?") if $self->{in_idle};
		$self->write("$data\x0D\x0A");
		$self->{in_idle} = 1 if $args{command} eq 'IDLE';
	}
	return $id;
}

=head2 login

Issue the LOGIN command.

Takes two parameters:

=over 4

=item * $user - username to send

=item * $pass - password to send

=back

See also the L<authenticate> command, which does the same thing but via L<Authen::SASL> if I ever get around to writing it.

=cut

sub login {
	my ($self, $user, $pass) = @_;
	my %args;
	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'LOGIN',
		param		=> qq{$user "$pass"},
		on_ok		=> $self->_capture_weakself(sub {
			my $self = shift;
			my $data = shift;
			$self->debug("Successfully logged in: $data");
			$self->state('Authenticated');
			$f->done($data);
		}),
		on_bad		=> $self->_capture_weakself(sub {
			my $self = shift;
			my $data = shift;
			$self->debug("Login failed: $data");
			$f->fail($data);
		})
	);
	$f
}

=head2 check_status

Check the mailbox status response as received from the server.

=cut

sub check_status {
	my $self = shift;
	my $data = shift;
	my %status;
	my ($mbox) = $data =~ /([^ ]+)/;
	$mbox =~ s/^(['"])(.*)\1$/$2/;
	foreach (qw(MESSAGES UNSEEN RECENT UIDNEXT)) {
		$status{lc($_)} = $1 if $data =~ /$_ (\d+)/i;
	}
	$self->{status}->{$mbox} = \%status;
	return $self;
}

=head2 noop

Send a null command to the server, used as a keepalive or server ping.

=cut

sub noop {
	my $self = shift;
	my %args = @_;

	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'NOOP',
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Status completed");
			$f->done;
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("Login failed: $data");
			$f->fail($data);
		}
	);
	return $self;
}

=head2 starttls

Issue the STARTTLS command in an attempt to get the connection upgraded to something more secure.

=cut

sub starttls {
	my $self = shift;
	my %args = @_;

	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'STARTTLS',
		on_ok		=> sub {
			my $data = shift;
			$self->debug("STARTTLS in progress");
			$f->done();
			$self->invoke_event(starttls => );
			$self->on_starttls if $self->can('on_starttls');
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("STARTTLS failed: $data");
			$f->fail($data);
		}
	);
	$f
}

sub list {
	my $self = shift;
	my %args = @_;

	my $f = $self->_future_from_args(\%args);
	push @{$self->{list_handler}}, $args{on_list};
	$self->send_command(
		command		=> join(' ', 'LIST', ($args{reference} || '""'), ($args{mailbox} || '*')),
		on_ok		=> sub {
			my $data = shift;
			shift @{$self->{list_handler}};
			$f->done($data);
		},
		on_bad		=> sub {
			my $data = shift;
			$f->fail($data);
		}
	);
	$f
}

sub _future_from_args {
	my $self = shift;
	my $args = shift;
	my $f = shift || Future->new;
	$f->on_done(delete $args->{on_ok}) if exists $args->{on_ok};
	$f->on_fail(delete $args->{on_bad}) if exists $args->{on_bad};
	return $f
}

=head2 status

Issue the STATUS command for either the given mailbox, or INBOX if none is provided.

=cut

sub status {
	my $self = shift;
	my %args = @_;

	my $mbox = $args{mailbox} || 'INBOX';
	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'STATUS',
		param		=> "$mbox (unseen recent messages uidnext)",
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Status completed");
			$f->done($self->{status}->{$mbox});
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("Login failed: $data");
			$f->fail($data);
		}
	);
	return $f;
}

=head2 select

Issue the SELECT command to switch to a different mailbox.

=cut

sub select : method {
	my $self = shift;
	my %args = @_;

	my $mbox = $args{mailbox} || 'INBOX';
	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'SELECT',
		param		=> $mbox,
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Have selected");
			$f->done($self->{status}->{$mbox});
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("Login failed: $data");
			$f->fail($data);
		}
	);
	$f;
}

=head2 examine

Like L</select>, but readonly.

=cut

sub examine : method {
	my $self = shift;
	my %args = @_;

	my $mbox = $args{mailbox} || 'INBOX';
	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'EXAMINE',
		param		=> $mbox,
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Have selected for readonly");
			$f->done($self->{status}->{$mbox});
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("Login failed: $data");
			$f->fail($data);
		}
	);
	$f;
}

=head2 fetch

Issue the FETCH command to retrieve one or more messages.

=cut

sub fetch : method {
	my $self = shift;
	my %args = @_;

	my $msg = exists($args{message}) ? $args{message} : 1;
	my $type = exists($args{type}) ? $args{type} : 'ALL';
	my $f = $self->_future_from_args(\%args);
	push @{$self->{fetch_handler}}, $args{on_fetch};
	$self->send_command(
		command		=> 'FETCH',
		param		=> "$msg $type",
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Have fetched");
			shift @{$self->{fetch_handler}};
			$f->done($data);
		},
		on_bad		=> sub {
			my $data = shift;
			pop @{$self->{fetch_handler}};
			$f->fail($data);
		}
	);
	$f
}

=head2 delete

Issue the DELETE command, which will delete one or more messages if it can.

=cut

sub delete : method {
	my $self = shift;
	my %args = @_;

	my $msg = exists $args{message} ? $args{message} : 1;
	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'STORE',
		param		=> $msg . ' +FLAGS (\Deleted)',
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Have deleted");
			$f->done;
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("Login failed: $data");
			$f->fail($data);
		}
	);
	$f
}

=head2 expunge

Issue an EXPUNGE to clear any deleted messages from storage.

=cut

sub expunge : method {
	my $self = shift;
	my %args = @_;

	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'EXPUNGE',
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Have expunged");
			$f->done;
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("Login failed: $data");
			$f->fail($data);
		}
	);
	$f
}

=head2 done

Issue a DONE command, which did something useful and important at the time although I no longer remember what this was.

=cut

sub done {
	my $self = shift;
	my %args = @_;

	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'DONE',
		id		=> undef,
		on_ok		=> sub {
			my $data = shift;
			$self->debug("Done completed");
			$f->done;
		},
		on_bad		=> sub {
			my $data = shift;
			$self->debug("DONE command failed: $data");
			$f->fail($data);
		}
	);
	$f
}

sub untagged_exists {
	my $self = shift;
	my $count = shift;
	$self->debug("Exists @_");
	$self->invoke_event(message_available => $count);
	return $self;
}

=head2 idle

Switch to IDLE mode. This will put the server into a state where it will continue to send untagged
responses as any changes happen to the selected mailboxes.

=cut

sub idle {
	my $self = shift;
	my %args = @_;

	$self->{start_idle_timer}->(%args) if $self->{start_idle_timer};
	my $f = $self->_future_from_args(\%args);
	$self->send_command(
		command		=> 'IDLE',
		on_ok		=> $self->_capture_weakself( sub {
			my $data = shift;
			$self->debug("Left IDLE mode");
			$self->{idle_timer}->stop if $self->{idle_timer};
			$self->{in_idle} = 0;
			my $queued = $self->{idle_queue};
			$self->write("$queued\x0D\x0A") if $queued;
			$f->done;
		}),
		on_bad		=> sub {
			my $data = shift;
			$self->debug("Idle failed: $data");
			$self->{in_idle} = 0;
			$f->fail($data);
		}
	);
	$f;
}

=head2 is_multi_line

Returns true if we're in a multiline (fixed size read) state.

=cut

sub is_multi_line { shift->{multiline} ? 1 : 0 }

=head2 configure

Set up any callbacks that were available.

=cut

sub configure {
	my $self = shift;
	my %args = @_;

# Enable TLS by default
	if(exists $args{tls}) {
		$self->{tls} = delete $args{tls};
	} else {
		$self->{tls} = 1;
	}

	foreach ($self->STATE_HANDLERS, qw{
		on_idle_update
		on_message
		on_message_received
		on_message_available
	}) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}
	return %args;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Licensed under the same terms as Perl itself.
