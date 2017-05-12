package Net::Gnutella::Server;
use Net::Gnutella::Connection;
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

sub accept {
	my $self = shift;

	my $server = IO::Socket::INET->new(
		Listen    => SOMAXCONN,
		LocalAddr => $self->server,
		LocalPort => $self->port,
		Reuse     => 1,
	);

	unless (defined $server) {
		$self->error("Couldn't bind to port: $!");
		return;
	}

	$self->socket($server);
	$self->server($server->sockhost);
	$self->port($server->sockport);

	$self->parent->_add_fh($self->socket, $self->can("_accept"), "r", $self);
}

sub connections {
	my $self = shift;
	my @ret;

	foreach my $key (keys %{ $self->{_connhash} }) {
		my $conn = $self->{_connhash}->{$key};

		next unless $conn->connected;

		push @ret, $conn;
	}

	return @ret;
}

sub new {
	my $proto = shift;
	my $parent = shift;
	my %args = @_;

	my $self = {
		_attr    => {
			parent    => $parent,
			debug     => $parent->debug,
			timeout   => $parent->timeout,
			error     => '',
			socket    => '',
			server    => undef,
			port      => 6346,
			allow     => 0,
		},
	};

	bless $self, $proto;

	foreach my $key (keys %args) {
		my $lkey = lc $key;

		$self->$lkey($args{$key});
	}

	$self->accept;

	return $self;
}

sub _accept {
	my $self = shift;
	my $sock = $self->socket->accept || return;

	printf STDERR "+ Accepted connection from '%s'\n", $sock->peerhost if $self->debug;

	my $conn = Net::Gnutella::Connection->new($self->parent,
		Debug     => $self->debug,
		Timeout   => $self->timeout,
		Allow     => $self->allow,
		Socket    => $sock,
		Ip        => $sock->peerhost,
		Connected => 2,
	);

	$self->{_connhash}->{$sock} = $conn;
}

1;
