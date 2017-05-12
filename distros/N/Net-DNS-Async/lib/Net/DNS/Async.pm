package Net::DNS::Async;

use strict;
use warnings;
use vars qw($VERSION $_LEVEL);
use constant {
	NDS_CALLBACKS => 0,
	NDS_RESOLVER  => 1,
	NDS_FQUERY    => 2,
	NDS_RETRIES   => 3,
	NDS_SENDTIME  => 4,
	NDS_SOCKET    => 5,
};
use Net::DNS::Resolver;
use IO::Select;
use Time::HiRes;
use Storable qw(freeze thaw);

$VERSION = '1.07';
$_LEVEL = 0;

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };
	$self->{Pending} = [ ];
	$self->{Queue} = { };
	$self->{QueueSize} = 20 unless $self->{QueueSize};
	$self->{Timeout} = 4 unless $self->{Timeout};
	$self->{Resolver} = new Net::DNS::Resolver();
	$self->{Selector} = new IO::Select();
	$self->{Retries} = 3 unless $self->{Retries};
	return bless $self, $class;
}

sub add {
	my ($self, $params, @query) = @_;
	my ($callback, @ns);

	if (ref($params) eq 'HASH') {
		@query = @{ $params->{Query} } if exists $params->{Query};
		$callback = $params->{Callback};
		@ns = @{ $params->{Nameservers} }
				if exists $params->{Nameservers};
	}
	else {
		$callback = $params;
	}

	unless (ref($callback) eq 'CODE') {
		die "add() requires a CODE reference for a callback";
	}
	unless (@query) {
		die "add() requires a DNS query";
	}

	my $frozen = freeze(\@query);
	unless (@ns) {
		# It's a regular boring query, we can fold it.
		# I wouldn't like to do this in a multi-threaded environment.
		for my $data (values %{ $self->{Queue} }) {
			if ($frozen eq $data->[NDS_FQUERY]) {
				# Allow the use of slot 0 for custom hacks.
				unless ($data->[NDS_RESOLVER]) {
					push(@{ $data->[NDS_CALLBACKS] }, $callback);
					return;
				}
			}
		}
	}

	# if ($_LEVEL) { add to Pending } else { recv/send }

	$self->recv(0);	# Perform fast case unconditionally.
	# print "Queue size " . scalar(keys %{ $self->{Queue} });
	while (scalar(keys %{ $self->{Queue} }) > $self->{QueueSize}) {
		# I'm fairly sure this can't busy wait since it must
		# either time out an entry or receive an entry when called
		# with no arguments.
		$self->recv();
	}

	# [ [ $callback ], $frozen, 0, undef, undef ];
	my $data = [ ];
	$data->[NDS_CALLBACKS] = [ $callback ];
	$data->[NDS_RESOLVER] = new Net::DNS::Resolver(
		nameservers	=> \@ns
			) if @ns;
	$data->[NDS_FQUERY] = $frozen;
	$data->[NDS_RETRIES] = 0;
	$self->send($data);
}

sub cleanup {
	my ($self, $data) = @_;

	my $socket = $data->[NDS_SOCKET];
	if ($socket) {
		$self->{Selector}->remove($socket);
		delete $self->{Queue}->{$socket->fileno};
		$socket->close();
	}
}

sub send {
	my ($self, $data) = @_;

	my @query = @{ thaw($data->[NDS_FQUERY]) };
	my $resolver = $data->[NDS_RESOLVER] || $self->{Resolver};
	my $socket = $resolver->bgsend(@query);

	unless ($socket) {
		die "No socket returned from bgsend()";
	}
	unless ($socket->fileno) {
		die "Socket returned from bgsend() has no fileno";
	}

	$data->[NDS_SENDTIME] = time();
	$data->[NDS_SOCKET]   = $socket;

	$self->{Queue}->{$socket->fileno} = $data;
	$self->{Selector}->add($socket);
}

sub recv {
	my $self = shift;
	my $time = shift;

	unless (defined $time) {
		$time = time();
		# Find first timer.
		for (values %{ $self->{Queue} }) {
			$time = $_->[NDS_SENDTIME] if $_->[NDS_SENDTIME] < $time;
		}
		# Add timeout, and compute delay until then.
		$time = $time + $self->{Timeout} - time();
		# It could have been a while ago.
		$time = 0 if $time < 0;
	}

	my @sockets = $self->{Selector}->can_read($time);
	for my $socket (@sockets) {
		# If we recursed from the user callback into add(), then
		# we might have read from and closed this socket.
		# XXX A neater solution would be to collect all the
		# callbacks and perform them after this loop has exited.
		next unless $socket->fileno;
		$self->{Selector}->remove($socket);
		my $data = delete $self->{Queue}->{$socket->fileno};
		unless ($data) {
			die "No data for socket " . $socket->fileno;
		}
		my $response = $self->{Resolver}->bgread($socket);
		$socket->close();
		eval {
			local $_LEVEL = 1;
			$_->($response) for @{ $data->[NDS_CALLBACKS] };
		};
		if ($@) {
			die "Async died within " . __PACKAGE__ . ": $@";
		}
	}

	$time = time();
	for my $data (values %{ $self->{Queue} }) {
		if ($data->[NDS_SENDTIME] + $self->{Timeout} < $time) {
			# It timed out.
			$self->cleanup($data);
			if ($self->{Retries} < ++$data->[NDS_RETRIES]) {
				local $_LEVEL = 1;
				$_->(undef) for @{ $data->[NDS_CALLBACKS] };
			}
			else {
				$self->send($data);
			}
		}
	}
}

sub await {
	my $self = shift;
	# If we have Pending, we need a better algorithm here.
	$self->recv while keys %{ $self->{Queue} };
}

*done = \&await;

=head1 NAME

Net::DNS::Async - Asynchronous DNS helper for high volume applications

=head1 SYNOPSIS

	use Net::DNS::Async;

	my $c = new Net::DNS::Async(QueueSize => 20, Retries => 3);

	for (...) {
		$c->add(\&callback, @query);
	}
	$c->await();

	sub callback {
		my $response = shift;
		...
	}

=head1 DESCRIPTION

Net::DNS::Async is a fire-and-forget asynchronous DNS helper.
That is, the user application adds DNS questions to the helper, and
the callback will be called at some point in the future without
further intervention from the user application. The application need
not handle selects, timeouts, waiting for a response or any other
such issues.

If the same query is added to the queue more than once, the module
may combine the queries; that is, it will perform the query only
once, and will call each callback registered for that query in turn,
passing the same Net::DNS::Response object to each query. For this
reason, you should not modify the Net::DNS::Response object in any
way lest you break things horribly for a subsequent callback.

This module is similar in principle to POE::Component::Client::DNS,
but does not require POE.

=head1 CONSTRUCTOR

The class method new(...) constructs a new helper object. All arguments
are optional. The following parameters are recognised as arguments
to new():

=over 4 

=item QueueSize

The size of the query queue. If this is exceeded, further calls to
add() will block until some responses are received or time out.

=item Retries

The number of times to retry a query before giving up.

=item Timeout

The timeout for an individual query.

=back

=head1 METHODS

=over 4

=item $c->add($callback, @query)

Adds a new query for asynchronous handling. The @query arguments are
those to Net::DNS::Resolver->bgsend(), q.v. This call will block
if the queue is full. When some pending responses are received or
timeout events occur, the call will unblock.

The user callback will be called at some point in the future, with
a Net::DNS::Packet object representing the response. If the query
timed out after the specified number of retries, the callback will
be called with undef.

=item $c->await()

Flushes the queue, that is, waits for and handles all remaining
responses.

=back

=head1 BUGS

The test suite does not test query timeouts.

=head1 SEE ALSO

L<Net::DNS>,
L<POE::Component::Client::DNS>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Shevek. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
