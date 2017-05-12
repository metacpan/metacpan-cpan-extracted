package Net::Server::ZMQ;

# ABSTRACT: Preforking ZeroMQ job server

use warnings;
use strict;
use base 'Net::Server::PreFork';

use Carp;
use POSIX qw/WNOHANG/;
use Net::Server::SIG qw/register_sig check_sigs/;
use ZMQ::FFI;
use ZMQ::FFI::Constants qw/ZMQ_ROUTER ZMQ_DEALER/;

our $VERSION = "0.001001";
$VERSION = eval $VERSION;

=head1 NAME

Net::Server::ZMQ - Preforking ZeroMQ job server

=head1 SYNOPSIS

	use Net::Server::ZMQ;

	Net::Server::ZMQ->run(
		port => [6660, 6661],	# [frontend port, backend port]
		min_servers => 5,
		max_servers => 10,
		app => sub {		# this is your worker code
			my $payload = shift;

			return uc($payload);
		}
	);

=head1 DESCRIPTION

C<Net::Server::ZMQ> is a L<Net::Server> personality based on L<Net::Server::PreFork>,
providing an easy way of creating a preforking ZeroMQ job server. It uses L<ZMQ::FFI>
for ZeroMQ integration, independent of the installed C<libzmq> version. You will need
to have C<libffi> installed.

Currently, this personality implements the load balancing "simple pirate" pattern
described in the L<ZeroMQ guide|http://zguide.zeromq.org/page:all>. The server creates
a C<ROUTER>-to-C<ROUTER> broker in the parent process, and one or more child processes
as C<DEALER> workers. Multiple C<REQ> clients can send requests to those workers through
the broker, which operates in a non-blocking way and balances requests across the workers.

The created topology looks like this:

	+--------+     +--------+     +--------+
	| CLIENT |     | CLIENT |     | CLIENT |
	+--------+     +--------+     +--------+
	|  REQ   |     |  REQ   |     |  REQ   |
	+---+----+     +---+----+     +---+----+
	    |              |              |
	    |______________|______________|
	                   |
	                   |
	               +---+----+
	               | ROUTER |
	               +--------+
	               | BROKER |
	               +--------+
	               | ROUTER |
	               +---+----|
	                   |
	      _____________|_____________
	     |             |             |
	     |             |             |
	+----+---+    +----+---+    +----+---+
	| DEALER |    | DEALER |    | DEALER |
	+--------+    +--------+    +--------+
	| WORKER |    | WORKER |    | WORKER |
	+--------+    +--------+    +--------+

You get the full benefits of C<Net::Server::PreFork>, including the ability to increase
or decrease the number of workers at real-time by sending the C<TTIN> and C<TTOU> signals
to the server, respectively.

This is an early release, do not rely on it on production systems without thoroughly testing
it beforehand.

I plan to implement better reliability as described in the ZeroMQ guide in future versions,
and also add support for different patterns such as publish-subscribe.

The ZMQ server does not care about the format of messages passed between clients and workers,
this kind of logic is left to the applications. You can easily implement a JSON-based job broker,
for example, either by taking care of encoding/decoding in the worker code, or by extending this
class and overriding C<process_request()>.

Note that configuration of a ZMQ server requires two ports, one for the frontend (the port to
which clients connect), and one for the backend (the port to which workers connect).

=head2 INTERNAL NOTES

ZeroMQ has some different concepts regarding sockets, and as such this class overrides
the bindings done by C<Net::Server> so they do nothing (C<pre_bind()>, C<bind()> and
C<post_bind()> are emptied). Also, since ZeroMQ never exposes client information to request
handlers, it is possible for C<Net::Server::ZMQ> to provide workers with data such as the
IP address of the client, and the C<get_client_info()> method is empties as well. Supplying client
information should therefore be done applicatively. The C<allow_deny()> method is also
overridden to always return true, for the same reason, though I'm not so certain yet
whether a better solution can be implemented.

Unfortunately, I did have to override quite a few methods I really didn't want to, such
as C<loop()>, C<run_n_children()>, C<run_child()> and C<delete_child()>, mostly to get
rid of any traditional socket communication between the child and parent processes and
replace it was ZeroMQ communication.

=head2 CLIENT IMPLEMENTATION

Clients should be implemented according to the L<lazy pirate client|http://zguide.zeromq.org/pl:lpclient>
in the ZeroMQ guide. Clients I<MUST> define a unique identity on their sockets when communicating
with the broker, otherwise the broker will not be able to direct responses from the workers back
to the correct client.

A client implementation, L<zmq-client>, is provided with this distribution to get up and running as
quickly as possible.

=head1 OVERRIDDEN METHODS

=head2 pre_bind()

=head2 bind()

=head2 post_bind()

Emptied out

=cut

sub pre_bind { }

sub bind { }

sub post_bind { }

=head2 options()

Adds the custom C<app> option to C<Net::Server>. It takes the subroutine reference
that handles requests, i.e. the worker subroutine.

=cut

sub options {
	my $self = shift;
	my $ref  = $self->SUPER::options(@_);
	my $prop = $self->{server};

	$ref->{app} = \$prop->{app};

	return $ref;
}

=head2 post_configure()

Validates the C<app> option and provides a useless default (a worker
subroutine that simply echos back what the client sends). Validates
the C<port> option, and sets default values for C<user> and C<group>.

=cut

sub post_configure {
	my $self = shift;
	my $prop = $self->{server};

	$self->SUPER::post_configure;

	$prop->{app} = sub { $_[0] }
		unless defined $prop->{app};

	$prop->{user} ||= $>;
	$prop->{group} ||= $);

	confess "app must be a subroutine reference"
		unless ref $prop->{app} && ref $prop->{app} eq 'CODE';

	confess "port must contain a frontend port and a backend port"
		unless ref $prop->{port} && ref $prop->{port} eq 'ARRAY' && scalar @{$prop->{port}} >= 2;
}

=head2 loop()

Overrides the main loop subroutine to remove pipe creation.

=cut

sub loop {
	my $self = shift;
	my $prop = $self->{server};

	# get ready for children
	$prop->{children} = {};
	$prop->{reaped_children} = {};
	if ($ENV{HUP_CHILDREN}) {
		foreach my $line (split /\n/, $ENV{HUP_CHILDREN}) {
			my ($pid, $status) = ($line =~ /^(\d+)\t(\w+)$/) ? ($1, $2) : next;
			$prop->{children}->{$pid} = { status => $status, hup => 1 };
		}
	}

	$prop->{tally} = {
		time		=> time(),
		waiting	=> scalar(grep { $_->{status} eq 'waiting' }    values %{$prop->{children}}),
		processing	=> scalar(grep { $_->{status} eq 'processing' } values %{$prop->{children}}),
		dequeue	=> scalar(grep { $_->{status} eq 'dequeue' }    values %{$prop->{children}})
	};

	$self->log(3, "Beginning prefork ($prop->{min_servers} processes)");
	$self->run_n_children($prop->{min_servers});
	$self->run_parent;
}

=head2 run_parent()

Creates the broker process, binding a C<ROUTER> on the frontend port
(facing clients), and C<ROUTER> on the backend port (facing workers).

It then starts polling on both sockets for events and passes messages
between clients and workers.

The parent process will receive the proctitle "zmq broker <fport>-<bport>",
where "<fport> is the frontend port and "<bport>" is the backend port.

=cut

sub run_parent {
	my $self = shift;
	my $prop = $self->{server};
 
	@{ $prop }{qw(last_checked_for_dead last_checked_for_waiting last_checked_for_dequeue last_process last_kill)} = (time) x 5;

	register_sig(
		PIPE => 'IGNORE',
		INT  => sub { $self->server_close },
		TERM => sub { $self->server_close },
		HUP  => sub { $self->sig_hup },
		CHLD => sub {
			while (defined(my $chld = waitpid(-1, WNOHANG))) {
				last unless $chld > 0;
				$self->{reaped_children}->{$chld} = 1;
			}
		},
		QUIT => sub { $self->{server}->{kind_quit} = 1; $self->server_close() },
		TTIN => sub { $self->{server}->{$_}++ for qw(min_servers max_servers); $self->log(3, "Increasing server count ($self->{server}->{max_servers})") },
		TTOU => sub { $self->{server}->{$_}-- for qw(min_servers max_servers); $self->log(3, "Decreasing server count ($self->{server}->{max_servers})") },
	); 

	$self->register_sig_pass;

	if ($ENV{HUP_CHILDREN}) {
		while (defined(my $chld = waitpid(-1, WNOHANG))) {
			last unless $chld > 0;
			$self->{reaped_children}->{$chld} = 1;
		}
	}

	my $fport = $prop->{port}->[0];
	my $bport = $prop->{port}->[1];

	$0 = "zmq broker $fport-$bport";

	my $ctx = ZMQ::FFI->new;

	my $f = $ctx->socket(ZMQ_ROUTER);
	$f->set_linger(0);
	$f->bind('tcp://*:'.$fport);

	my $b = $ctx->socket(ZMQ_ROUTER);
	$b->set_linger(0);
	$b->bind('tcp://*:'.$bport);

	my (@workers, $w_addr, $delim, $c_addr, $data);
	while (1) {
		check_sigs();

		$self->idle_loop_hook;

		# poll on the frontend or the backend, but only poll
		# on the frontend if there are workers
		if (scalar @workers && $f->has_pollin) {
			my @msg = $f->recv_multipart;
			$b->send_multipart([ pop(@workers), '', $msg[0], '', $msg[2] ]);
		} elsif ($b->has_pollin) {
			my @msg = $b->recv_multipart;

			$w_addr = $msg[0];
			$c_addr = $msg[2];

			next unless defined $c_addr;

			if ($c_addr =~ m/^(?:waiting|processing|dequeue|exiting)$/) {
				my ($pid) = ($w_addr =~ m/^child_(\d+)$/);
				my $status = $c_addr;

				last if $self->parent_read_hook($c_addr);

				push(@workers, $w_addr)
					if $status eq 'waiting';

				$self->log(3, "$w_addr status $status");

				if (my $child = $prop->{children}->{$pid}) {
					if ($status eq 'exiting') {
						$self->delete_child($pid);
					} else {
						# Decrement tally of state pid was in (plus sanity check)
						my $old_status = $child->{status}
							|| $self->log(2, "No status for $pid when changing to $status");

						--$prop->{tally}->{$old_status} >= 0
							|| $self->log(2, "Tally for $status < 0 changing pid $pid from $old_status to $status");

						$child->{status} = $status;
						++$prop->{tally}->{$status};

						$prop->{last_process} = time()
							if $status eq 'processing';
					}
				}
			} else {
				last if $self->parent_read_hook($msg[4]);

				$self->log(4, "$w_addr sending to $c_addr: $msg[4]");
				$f->send_multipart([ $c_addr, '', $msg[4] ]);
			}

			$self->coordinate_children();
		}
	}
}

=head2 run_n_children( $n )

The same as in C<Net::Server::PreFork>, with all socket communication
code removed.

=cut

sub run_n_children {
	my ($self, $n) = @_;
	my $prop = $self->{server};

	return unless $n > 0;

	$self->run_n_children_hook($n);

	$self->log(3, "Starting \"$n\" children");
	$prop->{last_start} = time();

	for (1 .. $n) {
		$self->pre_fork_hook;

		local $!;

		my $pid = fork;
		if (!defined $pid) {
			$self->fatal("Bad fork [$!]");
		}

		if ($pid) { # parent
			$prop->{children}->{$pid}->{status} = 'waiting';
			$prop->{tally}->{waiting}++;
		} else { # child
			$self->run_child;
		}
	}
}

=head2 run_child()

Creates a C<DEALER> socket between workers and server. Every child
process with get a proctitle of "zmq worker <bport>", where "<bport>"
is the backend port.

The child then signals the server that it is ready, and waits for requests.

=cut

sub run_child {
	my $self = shift;
	my $prop = $self->{server};

	$SIG{'INT'} = $SIG{'TERM'} = $SIG{'QUIT'} = sub {
		$self->child_finish_hook;
		exit;
	};
	$SIG{'PIPE'} = 'IGNORE';
	$SIG{'CHLD'} = 'DEFAULT';
	$SIG{'HUP'}  = sub {
		if (! $prop->{'connected'}) {
			$self->child_finish_hook;
			exit;
		}
		$prop->{'SigHUPed'} = 1;
	};

	$self->log(4, "Child Preforked ($$)");

	delete @{ $prop }{qw(children tally last_start last_process)};

	$self->child_init_hook;

	my $port = $prop->{port}->[1];

	$0 = "zmq worker $port";

	my $ctx = ZMQ::FFI->new;
	my $s = $ctx->socket(ZMQ_DEALER);
	$s->set_identity("child_$$");
	$s->set_linger(0);
	$s->connect("tcp://localhost:$port");

	$prop->{sock} = [$s];
	$prop->{context} = $ctx;

	$s->send_multipart([ '', 'waiting' ]);

	while ($self->accept) {
		$prop->{connected} = 1;

		$s->send_multipart([ '', 'processing' ]);

		my $ok = eval { $self->run_client_connection; 1 };
		if (! $ok) {
			$s->send_multipart([ '', 'exiting' ]);
			die $@;
		}

		last if $self->done;

		$prop->{connected} = 0;

		$s->send_multipart([ '', 'waiting' ]);
	}

	$self->child_finish_hook;

	$s->send_multipart([ '', 'exiting' ]);
	exit;
}

=head2 accept()

Waits for new messages from clients. When a message is received, it
is stored as the "payload" attribute, with the socket stored as the
"client" attribute.

=cut

sub accept {
	my $self = shift;
	my $prop = $self->{server};

	my $sock = $prop->{sock}->[0];

	$self->fatal("Received a bad sock!")
		unless defined $sock;

	while (1) {
		next unless $sock->has_pollin;

		my @msg = $sock->recv_multipart;

		$self->log(4, $sock->get_identity." got: $msg[3]");

		$prop->{client}	= $sock;
		$prop->{peername}	= $msg[1];
		$prop->{payload}	= $msg[3];

		return 1;
	}
}

=head2 post_accept()

=head2 get_client_info()

Emptied out

=cut

sub post_accept { }

sub get_client_info { }

=head2 allow_deny()

Simply returns a true value

=cut

sub allow_deny { 1 }

=head2 process_request()

Calls the C<app> (i.e. worker subroutine) with the payload from the
client, and sends the result back to the client.

=cut

sub process_request {
	my $self = shift;
	my $prop = $self->{server};

	$prop->{client}->send_multipart([
		'',
		$prop->{peername},
		'',
		$prop->{app}->($prop->{payload})
	]);
}

=head2 post_process_request()

Removes the C<client> attribute (holding the C<REP> socket) at the end
of the request.

=cut

sub post_process_request { delete $_[0]->{server}->{client} }

=head2 sig_hup()

Overridden to simply send C<SIGHUP> to the children (to restart them),
and that's it

=cut

sub sig_hup {
	my $self = shift;
	$self->log(2, "Received a SIG HUP");
	$self->hup_children;
}

=head2 shutdown_sockets()

Closes the ZeroMQ sockets

=cut

sub shutdown_sockets {
	my $self = shift;
	my $prop = $self->{server};

	foreach (@{$prop->{sock}}) {
		$_->close;
	}

	$prop->{sock} = [];
}

=head2 child_finish_hook()

Closes the children's socket and destroys the context (this is
necessary, otherwise we'll have zombies).

=cut

sub child_finish_hook {
	my $self = shift;
	my $prop = $self->{server};

	eval {
		$prop->{sock}->[0]->close;
		$prop->{context}->destroy;
	};
}

=head2 delete_child( $pid )

Overridden to remove dealing with sockets.

=cut

sub delete_child {
	my ($self, $pid) = @_;
	my $prop = $self->{server};

	my $child = $prop->{children}->{$pid};
	if (! $child) {
		$self->log(2, "Attempt to delete already deleted child $pid");
		return;
	}

	return if ! exists $prop->{children}->{$pid}; # Already gone?

	my $status = $child->{'status'}    || $self->log(2, "No status for $pid when deleting child");
	--$prop->{'tally'}->{$status} >= 0 || $self->log(2, "Tally for $status < 0 deleting pid $pid");
	$prop->{'tally'}->{'time'} = 0 if $child->{'hup'};

	delete $prop->{'children'}->{$pid};
}

=head1 CONFIGURATION AND ENVIRONMENT
  
Read L<Net::Server> for more information about configuration.

=head1 DEPENDENCIES

C<Net::Server::ZMQ> depends on the following CPAN modules:

=over

=item * L<Carp>

=item * L<Getopt::Long>

=item * L<Net::Server::PreFork>

=item * L<Pod::Usage>

=item * L<ZMQ::FFI>

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-Net-Server-ZMQ@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Server-ZMQ>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Net::Server::ZMQ

You can also look for information at:

=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Server-ZMQ>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Net-Server-ZMQ>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Net-Server-ZMQ>
 
=item * Search CPAN
 
L<http://search.cpan.org/dist/Net-Server-ZMQ/>
 
=back
 
=head1 AUTHOR
 
Ido Perlmuter <ido@ido50.net>

=head1 ACKNOWLEDGMENTS

In writing this module I relied heavily on L<Starman> by Tatsuhiko Miyagawa, and
on code and information from the official L<ZeroMQ guide|http://zguide.zeromq.org/>.
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2015, Ido Perlmuter C<< ido@ido50.net >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.
 
The full text of the license can be found in the
LICENSE file included with this module.
 
=head1 DISCLAIMER OF WARRANTY
 
BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.
 
IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
__END__
