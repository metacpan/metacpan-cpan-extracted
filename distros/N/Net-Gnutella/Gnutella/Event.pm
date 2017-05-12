package Net::Gnutella::Event;
use Carp;
use strict;
use vars qw/$VERSION %trans $AUTOLOAD/;

$VERSION = $VERSION = "0.1";

%trans = (
	0   => "ping",
	1   => "pong",
	64  => "push",
	128 => "query",
	129 => "reply",
);

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

# Instantiate an object, parent to all others
#
sub new {
	my $class = shift;
	my %args = @_;

	my $self = {
		_attr  => {
			packet => undef,
			from => undef,
			type => undef,
		},
	};

	bless $self, $class;

	foreach my $key (keys %args) {
		my $lkey = lc $key;

		$self->$lkey($args{$key});
	}

	return $self;
}

sub type {
	my $self = shift;

	if (@_) {
		$self->{_attr}->{type} = $_[0] =~ /^\d/ ? $self->trans($_[0]) : $_[0];
	}

	return $self->{_attr}->{type};
}


sub trans {
	shift if (ref($_[0]) || $_[0]) =~ /^Net::Gnutella/;

	my $event = shift;

	return (exists $trans{$event} ? $trans{$event} : undef);
}

1;
