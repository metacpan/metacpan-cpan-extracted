package Net::Gnutella::Packet::Ping;
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
			function => 0,
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
	return;
}

sub format {
	return;
}

1;
