package Net::Gnutella::Packet::Query;
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
			function => 128,

			minspeed => 0,
			query    => "\x00",
		},
	};

	bless $self, $proto;

	foreach my $key (keys %args) {
		my $lkey = lc $key;

		$self->$lkey($args{$key});
	}

	return $self;
}

sub parse {
	my $self = shift;
	my $data = shift;

	my $minspeed = unpack("S", substr($data, 0, 2, ''));
	my $query = substr($data, 0, index($data, "\x00"), '');

	$self->minspeed($minspeed);
	$self->query($query);
}

sub format {
	my $self = shift;
	my $data;

	$data .= pack("S", $self->minspeed);
	$data .= $self->query;
	$data .= $data =~ /\x00$/ ? "" : "\x00";

	return $data;
}

1;
