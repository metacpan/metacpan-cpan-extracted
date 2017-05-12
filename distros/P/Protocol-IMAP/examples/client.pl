#!/usr/bin/env perl
use strict;
use warnings;

package Example::Net::IMAP::Client;
use parent qw{Protocol::IMAP::Client};
use Socket;

# This is just a simple subclass demonstrating how to create a standard, synchronous socket-based
# implementation based on the Protocol::IMAP code.

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	my %args = @_;
	$self->configure(%args);
	return $self;
}

=head2 C<on_read>

Pass any new data into the protocol handler.

=cut

sub on_read {
	my ($self, $buffref, $closed) = @_;
	$self->debug("Stream was closed, this was not expected") if $closed;

	# We'll be called again, don't know where, don't know when, but the rest of our data will be waiting for us
	if($$buffref =~ s/^(.*[\n\r]+)//) {
		if($self->is_multi_line) {
			$self->on_multi_line($1);
		} else {
			$self->on_single_line($1);
		}
		return 1;
	}
	return 0;
}

=head2 C<configure>

Apply callbacks and other parameters, preparing state for event loop start.

=cut

sub configure {
	my $self = shift;
	my %args = @_;

# Debug flag is used to control the copious amounts of data that we dump out when tracing
	$self->{debug} = delete $args{debug} ? 1 : 0;

	die "No host provided" unless $args{host};
	foreach (qw{host service user pass ssl tls}) {
		$self->{$_} = delete $args{$_} if exists $args{$_};
	}

# Don't think I like this much, but didn't want the list of callbacks held here
	%args = $self->Protocol::IMAP::Client::configure(%args);

	return $self;
}

sub on_user {
	my $self = shift;
	return $self->{user};
}

sub on_pass {
	my $self = shift;
	return $self->{pass};
}

=head2 C<on_connection_established>


=cut

sub on_connection_established {
	my $self = shift;
	my $sock = shift;
	my $transport = IO::Async::Stream->new(handle => $sock)
		or die "No transport?";
	$self->{transport} = $transport;
	$self->setup_transport($transport);
	my $loop = $self->get_loop or die "No IO::Async::Loop available";
	$loop->add($transport);
	$self->debug("Have transport " . $self->transport);
}

=head2 C<start_idle_timer>

=cut

sub start_idle_timer {
	my $self = shift;
	my %args = @_;

	$SIG{ALRM} = sub {
		$self->noop(
				on_ok => sub {
				$self->idle(%args);
				}
			   );
	};
	alarm($args{idle_timeout} // 25 * 60);
	return $self;
}

=head2 C<stop_idle_timer>

Disable the timer if it's running.

=cut

sub stop_idle_timer {
	my $self = shift;
	alarm(0);
}

package main;

# Use one of the Perl Email Project modules for handling the email parsing. This one's good enough for our needs.
use Email::Simple;

# We create a new client instance, passing the information needed to connect - when the event loop starts, this
# should make the connection for us and call the on_authenticated callback.
my $imap = Example::Net::IMAP::Client->new(
# Set the debug flag to 1 to see lots of tedious detail about what's happening.
	debug			=> 0,
	host			=> $ENV{NET_ASYNC_IMAP_SERVER},
	service			=> $ENV{NET_ASYNC_IMAP_PORT} || 'imap',
	user			=> $ENV{NET_ASYNC_IMAP_USER},
	pass			=> $ENV{NET_ASYNC_IMAP_PASS},
	on_authenticated	=> \&check_server,
);

# First task is to check the status for the mailbox
my $total;
my $cur = 1;
sub check_server {
	$imap->status(
		on_ok => sub {
			my $data = shift;
# Store the total number of messages and report what we found
			$total = $data->{messages};
			warn "Message count: " . $data->{messages} . ", next: " . $data->{uidnext} . "\n";
# Then pass on to the next task in the list - you should probably weaken a copy of $imap here
			$imap->select(
				mailbox => 'INBOX',
				on_ok => sub {
					return unless $total > $cur;
					fetch_message(++$cur);
				}
			);
		}
	);
}

sub fetch_message {
	my $idx = shift;
	$imap->fetch(
# Provide the ID for the message to fetch here - one-based, not zero-based!
		message => $idx,

# Specify which parts of the message you want - if you only need subject/from/to etc., then just ask for the headers
		type => 'RFC822.HEADER',
		# type => 'RFC822.HEADER RFC822.TEXT',
		on_ok => sub {
			my $msg = shift;

			my $es = Email::Simple->new($msg);
			printf("[%03d] %s\n", $idx, $es->header('Subject'));
			if($cur < $total) {
				fetch_message(++$cur);
			}
		}
	);
}


