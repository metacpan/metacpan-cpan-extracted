package Net::Gnutella::Client;
use IO::Socket;
use Carp;
use strict;
use vars qw/$VERSION $AUTOLOAD/;

$VERSION = $VERSION = "0.1";

# Use AUTOHANDLER to supply generic attribute methods
#
sub AUTOLOAD {
	my $self = shift;
	my $attr = $AUTOLOAD;
	$attr =~ s/.*:://;
	return unless $attr =~ /[^A-Z]/; # skip DESTROY and all-cap methods
	croak sprintf "invalid attribute method: %s->%s()", ref($self), $attr unless exists $self->{_attr}->{lc $attr};
	$self->{_attr}->{lc $attr} = shift if @_;
	return $self->{_attr}->{lc $attr};
}

sub new {
	my $proto = shift;
	my $parent = shift;
	my %args = @_;

	my $self = {
		_attr    => {
			proto  => $proto,
			parent => $parent,
			debug  => $parent->debug,
			timeout=> $parent->timeout,
			error  => '',
			server => '',
			port   => 6346,
		},
	};

	bless $self, $proto;

	foreach my $key (keys %args) {
		my $lkey = lc $key;

		$self->$lkey($args{$key});
	}

	return $self->connect;
}

sub connect {
	my $self = shift;

	unless ($self->server) {
		$self->error("No server specified!");
		return $self;
	}

	my $sock = new IO::Socket::INET
		PeerAddr => $self->server,
		PeerPort => $self->port,
		Proto    => "tcp";

	unless ($sock) {
		$self->error("Connect failed: $!");
		return $self;
	}

	my $conn = Net::Gnutella::Connection->new($self->parent,
		Debug     => $self->debug,
		Timeout   => $self->timeout,
		Socket    => $sock,
		Ip        => $sock->peerhost,
		Connected => 1,
	);

	$conn->_write_wrapper("GNUTELLA CONNECT/0.4\n\n");

	return $conn;
}

1;