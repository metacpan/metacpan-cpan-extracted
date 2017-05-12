package Net::RNDC;
{
  $Net::RNDC::VERSION = '0.003';
}
# ABSTRACT: Speak the BIND RNDC protocol

use strict;
use warnings;

use Carp qw(croak);

use Net::RNDC::Session;

my $sock;

BEGIN {
	eval 'use IO::Socket::INET6;';

	if ($@) {
		eval 'use IO::Socket::INET;';

		die $@ if $@;

		$sock = 'IO::Socket::INET';
	} else {
		$sock = 'IO::Socket::INET6';
	}
}

# Required for new()
my @required_args = qw(
);

# Optional for new()/do()
my @optional_args = qw(
	key
	host
	port
);

sub new {
	my ($class, %args) = @_;

	my %obj = $class->_parse_args(%args);

	return bless \%obj, $class;
}

sub _parse_args {
	my ($class, %args) = @_;

	for my $r (@required_args) {
		unless ($args{$r}) {
			croak("Required argument '$r' is missing");
		}
	}

	$args{port} ||= 953;

	return map {
		$_ => $args{$_}
	} grep { $args{$_} } (@required_args, @optional_args);
}

sub _check_do_args {
	my ($self, %args) = @_;

	for my $r (qw(key host)) {
		unless ($args{$r}) {
			croak("Required argument '$r' is missing");
		}
	}
}

sub do {
	my ($self, $command, %override) = @_;

	$self->{response} = $self->{error} = '';

	my $host = $self->{host};
	my $port = $self->{port};
	my $key  = $self->{key};

	if (%override) {
		my %args = $self->_parse_args(
			host => $host,
			port => $port,
			key => $key,
			%override,
		);

		$host = $args{host};
		$port = $args{port};
		$key  = $args{key};
	}

	$self->_check_do_args(
		host => $host,
		port => $port,
		key  => $key,
	);

	my $c = $sock->new(
		PeerAddr => "$host:$port",
	);

	unless ($c) {
		$self->{error} = "Failed to create a socket: $@ ($!)";

		return 0;
	}

	# Net::RNDC::Session does all of the work
	my $sess = Net::RNDC::Session->new(
		key         => $key,
		command     => $command,
		is_client   => 1,

		want_write => sub {
			my $s = shift;

			$c->send(shift);

			$s->next;
		},

		want_read => sub {
			my $s = shift;

			my $buff;

			$c->recv($buff, 4096);

			$s->next($buff);
		},

		want_finish => sub {
			my $s = shift;
			my $res = shift;

			$self->{response} = $res;
		},

		want_error => sub {
			my $s = shift;
			my $err = shift;

			$self->{error} = $err;
		}
	);

	# Work!
	$sess->start;

	$c->close;

	if ($self->response) {
		return 1;
	} else {
		return 0;
	}
}

sub response {
	my ($self) = @_;

	return $self->{response};
}

sub error {
	my ($self) = @_;

	return $self->{error};
}

1;
__END__;

=head1 NAME

Net::RNDC - Speak the BIND Remote Name Daemon Control (RNDC) V1 protocol

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Simple synchronous command/response:

  use Net::RNDC;

  my $rndc = Net::RNDC->new(
    host => '127.0.0.1',
    port => 953,         # Defaults to 953
    key  => 'abcd',
  );

  if (!$rndc->do('status')) {
    die "RNDC failed: " . $rndc->error;
  }

  print $rndc->response;

All arguments to new() are allowed in do:

  my $rndc = Net::RNDC->new();

  my $key = 'abcd';

  for my $s (qw(127.0.0.1 127.0.0.2)) {
    if (!$rndc->do('status', key => $key, host => $s)) {
      my $err = $rndc->error;
    } else {
      my $resp = $rndc->response;
    }
  }

=head1 DESCRIPTION

This package provides a synchronous, easy to use interface to the RNDC V1 
protocol. For more mid-level control, see L<Net::RNDC::Session>, and for 
absolute control, L<Net::RNDC::Packet>.

=head2 Constructor

=head3 new

  Net::RNDC->new(%args);

Optional Arguments:

=over 4

=item *

B<key> - The Base64 encoded HMAC-MD5 private key to use.

=item *

B<host> - The hostname/IP of the remote server to connect to. If 
L<IO::Socket::INET6> is installed, IPv6 support will be enabled.

=item *

B<port> - The port to connect to. Defaults to I<953>.

=back

=head2 Methods

=head3 do

  $rndc->do($command);

  $rndc->do($commands, %args);

Connects to the remote nameserver configured in L</new> or passed in to  
B<%args> and sends the specified command.

Returns 1 on success, 0 on failure.

Arguments:

=over 4

=item *

B<$command> - The RNDC command to run. For example: C<status>.

=back

Optional Arguments - See L</new> above.

=head3 error

  $rndc->error;

Returns the last string error from a call to L</do>, if any. Only set if 
L</do> returns 0.

=head3 response

  $rndc->response;

Returns the last string response from a call to L</do>, if any. Only set if 
L</do> returns 1.

=head1 SEE ALSO

L<Net::RNDC::Session> - Manage the 4-packet RNDC session

L<Net::RNDC::Packet> - Low level RNDC packet manipulation.

=head1 AUTHOR

Matthew Horsfall (alh) <WolfSage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
