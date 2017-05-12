package Net::Gnutella::Packet::Reply;
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
			function => 129,

			ip      => [],
			port    => 0,
			speed   => 0,
			results => [],
			guid    => [],
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

	return join(".", @{ $self->{_attr}->{ip} });
}

sub parse {
	my $self = shift;
	my $data = shift;

	my $count = unpack("C",  substr($data, 0, 1, ''));
	my $port  = unpack("S",  substr($data, 0, 2, ''));
	my @ip    = unpack("C4", substr($data, 0, 4, ''));
	my $speed = unpack("L",  substr($data, 0, 4, ''));
	my @set;

	for (my $i = 0; $i < $count; $i++) {
		my $index = unpack("L", substr($data, 0, 4, ''));
		my $size  = unpack("L", substr($data, 0, 4, ''));
		my $name  = substr($data, 0, index($data, "\x00\x00"), '');
		my $extra;

		if (index($name, "\x00") != -1) {
			$extra = $name;
			$name  = substr($extra, 0, index($extra, "\x00"), '');

			substr($extra, 0, 1, '');
		}

		substr($data, 0, 2, '');

		push @set, [ $index, $size, $name, $extra ];
	}

	my @guid = unpack("L4", substr($data, 0, 16, ''));

	$self->port($port);
	$self->ip(\@ip);
	$self->speed($speed);
	$self->results(\@set);
	$self->guid(\@guid);
}

sub format {
	my $self = shift;
	my $data;

	my $results = $self->results;

	$data .= pack("C",  scalar @$results);
	$data .= pack("S",  $self->port);
	$data .= pack("C4", $self->ip);
	$data .= pack("L",  $self->speed);

	foreach my $res (@$results) {
		$data .= pack("L", $res->[0]);
		$data .= pack("L", $res->[1]);
		$data .= $res->[2];
		$data .= $data =~ /\x00\x00$/ ? "" : "\x00\x00";
	}

	$data .= pack("L4", @{ $self->guid });

	return $data;
}

1;
