#!/usr/bin/perl 
use strict;
use warnings;

=pod

Get/set benchmark for pure-perl memcached implementation using several backends.

Initial results:

 IO::Async::Loop::Poll  :  1897.96 cycles/s,  2.635 elapsed
 POE                    :  2169.03 cycles/s,  2.306 elapsed
 IO::Async::Loop::Select:  2446.31 cycles/s,  2.044 elapsed
 IO::Async::Loop::Epoll :  2684.97 cycles/s,  1.863 elapsed
 Socket                 :  7275.04 cycles/s,  0.687 elapsed

=cut

eval { require IO::Async::Loop; 1; } or die "This example needs IO::Async\n";
eval { require POE; 1; } or die "This example needs POE\n";
eval { require Socket; 1; } or die "This example needs Socket\n";

package Memcached::Example::Socket;
use parent qw(Protocol::Memcached);
use Socket;
use IO::Handle;
use POSIX;

# Trivial 'non-blocking' Socket implementation, assumes the socket can keep up with the requested
# writes and that we don't spin too much on reads. Just the sort of implementation that wouldn't
# play nicely with anyone else.

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless { }, $class;
	$self->connect;
	$self->Protocol::Memcached::init;
	return $self;
}

=head2 connect

Connect to the socket and enable nonblocking mode.

=cut

sub connect {
	my $self = shift;
	my $remote  = 'localhost';
	my $port    = 11211;  # random port
	if ($port =~ /\D/) { $port = getservbyname($port, 'tcp') }
	die "No port" unless $port;
	my $iaddr   = inet_aton($remote)               || die "no host: $remote";
	my $paddr   = sockaddr_in($port, $iaddr);

	my $proto   = getprotobyname('tcp');
	socket(my $sock, PF_INET, SOCK_STREAM, $proto)  or die "socket: $!";
	connect($sock, $paddr)    || die "connect: $!";
	$sock->autoflush(1);
	{
		my $flags = fcntl($sock, F_GETFL, 0) or die "Can't get flags for socket: $!\n";
		fcntl($sock, F_SETFL, $flags | O_NONBLOCK) or die "Can't make socket nonblocking: $!\n";
	}
	$self->{sock} = $sock;

}

=head2 write

Write data to socket immediately, without checking whether it's able to receive.
We'll call on_flush as soon as the write returns.

=cut

sub write {
	my ($self, $data, %args) = @_;
	$self->sock->write($data) or die $!;
	if(my $method = $args{on_flush}) {
		$self->$method();
	}
	return $self;
}

=head2 close

Close the socket immediately.

=cut

sub close { close shift->{sock} or die "$!"; }

sub sock { shift->{sock} }

package Memcached::Example::Scalar;
use parent qw(Protocol::Memcached);

# UNUSED - write to a scalar buffer rather than a socket, would need fake responses

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		data => ''
	}, $class;
	$self->Protocol::Memcached::init;
	return $self;
}

sub write {
	my $self = shift;
	$self->{data} .= shift;
	my %args = @_;
	if(my $method = $args{on_flush}) {
		$self->$method();
	}
	return $self;
}

package Memcached::Example::IO::Async;
use parent qw(Protocol::Memcached);

# IO::Async::Stream approach

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
		stream	=> $args{stream},
	}, $class;
	$self->Protocol::Memcached::init;
	return $self;
}

=head2 connect

Connects to memcached and hits the on_connected callback if available.

=cut

sub connect {
	my $self = shift;
	my %args = @_;
	my $loop = $args{loop};
	$loop->connect(
		host		=> 'localhost',
		service 	=> 11211,
		socktype	=> 'stream',
		on_stream	=> $self->sap(sub {
			my $self = shift;
			my $stream = shift;
			$stream->configure(
				on_read => $self->sap(sub {
					my $self = shift;
					my ($stream_self, $buffref, $eof) = @_;
					return 1 if $self->on_read($buffref);
					return undef;
				})
			);
			$loop->add($stream);
			$self->{stream} = $stream;
			$args{on_connected}->() if exists $args{on_connected};
		}),
		on_resolve_error => sub { die "Cannot resolve - $_[-1]\n"; },
		on_connect_error => sub { die "Cannot connect - $_[0] failed $_[-1]\n"; },
	);
}

=head2 write

Pass data straight over to L<IO::Async::Stream> which already uses the '$data, on_flush => coderef'
API.

=cut

sub write { shift->{stream}->write(@_) }

package Memcached::Example::POE;
use parent qw(Protocol::Memcached);
use POE;
use POE::Component::Client::TCP;
use POE::Filter::Stream;

# Simplistic POE implementation, probably much room for improvement here.

sub new {
	my $class = shift;
	my %args = @_;
	my $self = bless {
	}, $class;
	$self->Protocol::Memcached::init;
	# Buffer incoming data since our API uses in-place buffer modification when parsing data
	my $buffered = '';
	POE::Component::Client::TCP->new(
		RemoteAddress => 'localhost',
		RemotePort    => 11211,
		Filter        => "POE::Filter::Stream",

		Connected => sub {
			$self->{handle} = $_[HEAP]->{server};
			$args{on_connected}->($self);
		},
		ConnectError => sub { die "could not connect\n"; },
		ServerInput => sub {
			my ($kernel, $heap, $input) = @_[KERNEL, HEAP, ARG0];
			$buffered .= $input;
			1 while $self->on_read(\$buffered);
		},
	);
	return $self;
}

=head2 write

Attempt to write data to the socket using the ->put method as per cookbook examples.

=cut

sub write {
	my ($self, $data, %args) = @_;
	$self->{handle}->put($data);
	if(my $method = $args{on_flush}) {
		$self->$method();
	}
	return $self;
}

package Memcached::Benchmark;
use Time::HiRes;

# main benchmarking class - doesn't really take advantage of event-based loops since we
# could queue up data and send a certain amount without waiting for a response.

sub new {
	my $class = shift;
	my $self = bless {
		@_
	}, $class;
	$self->{loop_queued} = 0;
	$self->{total} = scalar @{$self->{data}};
	$self;
}

=head2 run

Main entry point - will attempt to connect, expecting the {connect} handler to call ->iterate when
it's ready.

=cut

sub run {
	my $self = shift;
	$self->{started} = Time::HiRes::time;
	$self->{connect}->($self);
}

=head2 iterate

Queue the SET + GET for the next pending value, or hit L<cycle_complete> if we're done.

=cut

sub iterate {
	my $self = shift;
	my ($k, $v) = $self->next_value;
	return $self->cycle_complete unless defined $k;

	# Write this value to cache
	$self->mc->set(
		$k => $v,
		on_complete	=> $self->sap(sub {
			my $self = shift;
			# And read it back when we think we've had a response to say it's been stored.
			$self->mc->get(
				$k,
				on_complete	=> $self->sap(sub {
					my $self = shift;
					my %args = @_;
					# When we've processed the GET, cycle through to the next value.
					$self->iterate;
				}),
				on_error	=> sub { die "Failed because of @_\n" }
			);
		})
	);

	# Run any manual actions required to get requested data sent/received
	$self->run_loop;
}

=head2 cycle_complete

Mark this benchmark as finished, reporting on stats.

=cut

sub cycle_complete {
	my $self = shift;
	return if $self->{is_complete};
	$self->{close}->($self);
	$self->{is_complete} = 1;
	my $elapsed = Time::HiRes::time - $self->{started};
	printf "%-64.64s: %8.2f cycles/s, %6.3f elapsed\n", $self->{type}, $self->{total} / $elapsed, $elapsed;
	return 0;
}

=head2 run_loop

Execute the main loop.

=cut

sub run_loop {
	my $self = shift;
	return ++$self->{loop_queued} if $self->{in_loop};
	$self->{loop_queued} = 0;
	{ local $self->{in_loop} = 1; $self->{loop}->($self); }
	$self->run_loop if $self->{loop_queued};
}

=head2 next_value

Returns next value if we have one.

=cut

sub next_value {
	my $self = shift;
	if(defined $self->{index}) {
		return undef if ++$self->{index} >= @{$self->{data}};
	} else {
		$self->{index} = 0;
	}
	return @{ $self->{data}->[$self->{index}] };
}

# Accessor for the memcached subclass.
sub mc { shift->{mc} }

# weasel support
sub sap { my ($self, $sub) = @_; Scalar::Util::weaken $self; return sub { $self->$sub(@_); }; }

sub is_connected { shift->{is_connected} }
sub is_complete { shift->{is_complete} }

package main;
use POSIX;

my %bench_type;
{
# The Socket benchmark needs its own 'event loop' to read data from the socket.
	my $mc;
	$bench_type{'Socket'} = {
		connect	=> sub {
			my $self = shift;
			$mc = $self->{mc} = Memcached::Example::Socket->new;
			$self->{is_connected} = 1;
			$self->iterate;
		},
		close	=> sub {
			$mc->sock->close;
		},
		loop => sub {
			my $self = shift;
			my $data = '';
			while(!$self->is_complete) {
				my $count = $mc->sock->read($data, 256, length($data));
				die $! unless defined($count) || $! == EWOULDBLOCK;
				1 while($mc->on_read(\$data));
			}
		},
	};
}
{
# POE handles most things in the subclass
	my $mc;
	my $kern = POE::Kernel->new;
	$bench_type{'POE'} = {
		connect	=> sub {
			my $self = shift;
			$mc = $self->{mc} = Memcached::Example::POE->new(
				on_connected => sub {
					$self->{is_connected} = 1;
					$self->iterate;
				}
			);
			$kern->run;
		},
		close	=> sub {
			$kern->stop;
		},
		loop => sub {
			1;
		},
	};
}
{
# Try each of the available IO::Async subclasses
	use IO::Async::Loop;
	use IO::Async::Loop::Epoll;
	use IO::Async::Loop::Poll;
	use IO::Async::Loop::Select;
	use Scalar::Util qw(weaken);
	
	for my $type (qw(Epoll Poll Select)) {
		my $class = join '::', 'IO::Async::Loop', $type;
		my $loop;
		my $mc = Memcached::Example::IO::Async->new;
		$bench_type{$class} = {
			connect	=> sub {
				my $self = shift;
				$self->{mc} = $mc;
				$loop = $class->new;
				$mc->connect(loop => $loop, on_connected => sub {
					$self->{is_connected} = 1;
					$self->iterate;
				});
				$loop->loop_forever;
			},
			loop => sub { 1; },
			close => sub { $loop->loop_stop; }
		};
	}
}

# We want each test to have a different key, otherwise the first one to run is
# at a disadvantage.
my $k = 'aaaaaaaaaaaaaaaa';
foreach my $type (keys %bench_type) {
	my $bench = Memcached::Benchmark->new(
		%{$bench_type{$type}},
		data	=> [ map { [ $k++, 65535 * rand ] } 0..5000 ],
		type	=> $type,
	);
	$bench->run;
}

