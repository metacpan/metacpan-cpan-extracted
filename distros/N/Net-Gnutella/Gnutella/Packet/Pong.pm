package Net::Gnutella::Packet::Pong;
use Socket qw(inet_ntoa inet_aton);
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
	my %args = @_;

	my $self = {
		_attr   => {
			msgid    => [],
			ttl      => 7,
			hops     => 1,
			function => 1,

			ip    => [],
			port  => 0,
			count => 0,
			size  => 0,
		},
	};

	bless $self, $proto;

	foreach my $key (keys %args) {
		my $lkey = lc $key;

		$self->$lkey($args{$key});
	}

	return $self;
}

sub ip {
	my $self = shift;

	if (@_) {
		if (ref($_[0]) eq 'ARRAY') {
			$self->{_attr}->{ip} = $_[0];
		} elsif ($_[0] =~ /^[\d.]+$/) {
			$self->{_attr}->{ip} = [ split(/\./, $_[0]) ];
		} elsif ($_[0] =~ /\D/) {
			$self->{_attr}->{ip} = [ split(/\./, inet_ntoa(inet_aton($_[0]))) ];
		}
	}

	return @{ $self->{_attr}->{ip} };
}

sub ip_as_string {
	my $self = shift;

	return join('.', @{ $self->{_attr}->{ip} });
}

sub parse {
	my $self = shift;
	my $data = shift;

	my $port = unpack("S",  substr($data, 0,  2));
	my @ip   = unpack("C4", substr($data, 2,  4));
	my $count= unpack("L",  substr($data, 6,  4));
	my $size = unpack("L",  substr($data, 10, 4));

	$self->port($port);
	$self->ip(\@ip);
	$self->count($count);
	$self->size($size);
}

sub format {
	my $self = shift;

	my $data = pack("SC4LL", $self->port, $self->ip, $self->count, $self->size);

	return $data;
}

1;
