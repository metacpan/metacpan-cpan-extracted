package POE::Framework::MIDI::Interval;
use strict;
use vars '$VERSION'; $VERSION = '0.02';
use POE::Framework::MIDI::Utility;

sub new {
	my ( $self, $class ) = ( {}, shift );
	bless $self,$class;
	my %params = @_;
	$self->{cfg} = \%params;
	die "Interval needs a duration and a notes listref" unless ($params{duration}
		and ref($params{notes}) eq 'ARRAY');	
	return $self;	
}

sub duration {
	my $self = shift;
	return $self->{cfg}->{duration};
}

sub notes {
	my $self = shift;
	return $self->{cfg}->{notes};
}




1;