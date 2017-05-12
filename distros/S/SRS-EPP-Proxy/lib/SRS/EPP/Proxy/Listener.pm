
package SRS::EPP::Proxy::Listener;
{
  $SRS::EPP::Proxy::Listener::VERSION = '0.22';
}

use 5.010;  # for (?| alternation feature

use Moose;

with 'MooseX::Log::Log4perl::Easy';

use IO::Select;
use Net::SSLeay::OO;
use Socket;
use IO::Socket::INET;
use MooseX::Params::Validate;

our ($HAVE_V6, @SOCKET_TYPES);

BEGIN {
	my $sock = eval {
    use if $] < 5.014, "Socket6";
		require IO::Socket::INET6;
		IO::Socket::INET6->new(
			Listen    => 1,
			LocalAddr => '::1',
			LocalPort => int(rand(60000)+1024),
			Proto     => 'tcp',
		);
	};
	if ( $sock or $!{EADDRINUSE} ) {
		$HAVE_V6 = 1;
		@SOCKET_TYPES = ("IO::Socket::INET6");
	}
	push @SOCKET_TYPES, "IO::Socket::INET";
}

sub resolve {
	my $hostname = shift;
	my @addr;
	$DB::single = 1;
	if ($HAVE_V6) {
		my @res = getaddrinfo($hostname, "", AF_UNSPEC);
		while (
			my (
				$family, $socktype, $proto, $address,
				$canonical
			)
			= splice @res, 0, 5
			)
		{
			my ($addr) = getnameinfo($address, &NI_NUMERICHOST);
			push @addr, $addr unless grep { $_ eq $addr }
					@addr;
		}
	}
	else {
		my $packed_ip = gethostbyname($hostname)
			or die "fail to resolve host '$hostname'; $!";
		my $ip_address = inet_ntoa($packed_ip);
		push @addr, $ip_address;
	}
	@addr;
}

has 'listen' =>
	is => "ro",
	isa => "ArrayRef[Str]",
	required => 1,
	default => sub { [ ($HAVE_V6 ? "[::]" : "0.0.0.0") ] },
	;

has 'sockets' =>
	is => "ro",
	isa => "ArrayRef[IO::Socket]",
	default => sub { [] },
	;

use constant EPP_DEFAULT_TCP_PORT => 700;
use constant EPP_DEFAULT_LOCAL_PORT => "epp(".EPP_DEFAULT_TCP_PORT.")";

sub fmt_addr_port {
	my $addr = shift;
	my $port = shift;
	if ( $addr =~ m{:} ) {
		"[$addr]:$port";
	}
	else {
		"$addr:$port";
	}
}

sub init {
    my $self = shift;

	my @sockets;
	for my $addr ( @{ $self->listen } ) {

		# parse out the hostname and port; I can't see another
		# way to supply a default port number.
		my ($hostname, $port) = $addr =~
			m{^(?|\[([^]]+)\]|([^:]+))(?::(\d+))?$}
			or die "bad listen address: $addr";
		$port ||= EPP_DEFAULT_LOCAL_PORT;

		my @addr = resolve($hostname);
		$self->log_debug("$hostname resolved to @addr");

		for my $addr (@addr) {
			my $SOCKET_TYPE = "IO::Socket::INET";
			if ( $addr =~ /:/ ) {
				$SOCKET_TYPE .= "6";
			}
			my $socket = $SOCKET_TYPE->new(
				Listen => 5,
				LocalAddr => $addr,
				LocalPort => $port,
				Proto => "tcp",
				ReuseAddr => 1,
			);

			my $addr_port = fmt_addr_port($addr,$port);

			if ( !$socket ) {
				$self->log_error(
					"Failed to listen on $addr_port; $!",
				);
			}
			else {
				$self->log_info(
					"Listening on $addr_port",
				);
				push @sockets, $socket;
			}
		}
	}

	if ( !@sockets ) {
		die "No listening sockets; aborting";
	}

	@{ $self->sockets } = @sockets;
}

sub accept {
    my $self = shift;
    
    my ( $timeout ) = pos_validated_list(
        \@_,
        { isa => 'Int', optional => 1 },
    );        
    
	my $select = IO::Select->new();
	$select->add($_) for @{$self->sockets};
	my @ready = $select->can_read($timeout)
		or return;
	while ( @ready > 1 ) {
		if ( rand(1) > 0.5 ) {
			shift @ready;
		}
		else {
			pop @ready;
		}
	}
	my $socket = $ready[0]->accept;
	if ( !$socket ) {
		die "accept lost a socket; exiting";
	}
	$socket;
}

sub close {
    my $self = shift;
    
	for my $socket ( @{ $self->sockets } ) {
		$socket->close if $socket;
	}
	@{ $self->sockets } = ();
}

1;

__END__

=head1 NAME

SRS::EPP::Proxy::Listener - socket factory class

=head1 SYNOPSIS

 my $listener = SRS::EPP::Proxy::Listener->new(
     listen => [ "hostname:port", "address:port" ],
     );

 # this does the listen part
 $listener->init;

 # this normally blocks, and returns a socket.
 # it might return undef, if you pass it a timeout.
 my $socket = $listener->accept;

=head1 DESCRIPTION

This class is a TCP/IP listener.  It listens on the configured ports
for TCP connections and returns sockets when there are incoming
connections waiting.

You don't actually need to supply the port or listen addresses; the
defaults are to listen on INADDR_ANY (0.0.0.0) or IN6ADDR_ANY (::) on
port C<epp(700)>.

If the L<IO::Socket::INET6> module is installed, then at load time the
module tries to listen on a random port on the IPv6 loopback address.
If that works (or fails with a particular plausible error, if
something else happened to be using that port), then IPv6 is
considered to be available.  This means that the RFC3493-style
I<getaddrinfo> and such are used instead of C<gethostbyname>.  You
will end up with a socket for every distinct address returned by
C<getaddrinfo> on the passed-in list.

IPv6 addresses (not names) must be passed in square brackets, such as
C<[2404:130:0::42]>.

In general these rules should make this listener behave like any
normal IPv6-aware daemon.

=head1 SEE ALSO

L<IO::Socket::INET>, L<Socket6>, L<IO::Socket::INET6>

=head1 AUTHOR AND LICENCE

Development commissioned by NZ Registry Services, and carried out by
Catalyst IT - L<http://www.catalyst.net.nz/>

Copyright 2009, 2010, NZ Registry Services.  This module is licensed
under the Artistic License v2.0, which permits relicensing under other
Free Software licenses.

=cut

