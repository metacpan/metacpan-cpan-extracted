package XML::SDEE;
#
# $Id: SDEE.pm,v 1.1 2004/12/23 12:02:30 jminieri Exp $
#

use 5.006001;
use strict;
use warnings;

use XML::Simple;

our $VERSION = '0.01';

################################################################################
#
sub sessionId { my $self = shift; return $self->{ _sessionId }; }
sub subscriptionId { my $self = shift; return $self->{ _subscriptionId }; }
#
################################################################################

################################################################################
#
# Error reporting methods
sub isError{ my $self = shift; return $self->{ _isError };}
sub getError{ my $self = shift; return $self->{ _errorMessage }; }
sub getErrorReason{
	my $self = shift;

	if(exists($self->{ _errorMessage}{ Reason })) {
		return $self->{ _errorMessage}{ Reason }
	} else {
		return undef
	}
}

sub getErrorSubcode{
	my $self = shift;

	if(exists($self->{ _errorMessage }{ Subcode })) {
		return $self->{ _errorMessage }{ Subcode }
	} else {
		return undef
	}
}

sub getErrorCode{
	my $self = shift;
	if(exists($self->{ _errorMessage }{ Code })) {
		return $self->{ _errorMessage }{ Code }
	} else {
		return undef
	}
}

sub getErrorString {
	my $self = shift;

	return $self->getErrorCode . ':' . $self->getErrorSubcode . ':' . $self->getErrorReason;
}
#
################################################################################

################################################################################
#
# Event retrieval methods
sub getEvent { my $self = shift; return pop @{ $self->{ _eventList }}; }
sub getEvents { my $self = shift; return $self->{ _events }; }
#
################################################################################

################################################################################
#
# XML retrieval methods
sub XML { my $self = shift; return $self->{ _raw_xml }; }
sub SDEE { my $self = shift; return $self->{ SDEE }; }
#
################################################################################

sub reset {
	my $self = shift;

	$self->{ _raw_xml } = undef;
	$self->{ SDEE } = undef;
	$self->{ _sessionId } = undef;
	$self->{ _subscriptionId } = undef;
	$self->{ _isError } = undef;
	$self->{ _errorMessage } = {};
	@{$self->{ _eventsList }} = ();
	$self->{ _events } = undef;

}

#
# document processor
sub consume {
	my ($self, $raw_xml) = @_;

	unless(defined($raw_xml)) { return undef; }

	$self->reset;

	$self->{ _raw_xml } = $raw_xml;
	$self->{ SDEE } = XMLin($raw_xml);

	if (exists($self->{ SDEE }->{ 'env:Header' }->{ 'sd:oobInfo' }->{ 'sd:sessionId' } )) {
		$self->{ _sessionId } = ($self->{ SDEE }->{ 'env:Header' }->{ 'sd:oobInfo' }->{ 'sd:sessionId' } or undef);
	}

	if(exists($self->{ SDEE }->{ 'env:Body' }->{ 'sd:subscriptionId' })) {
		$self->{ _subscriptionId } = $self->{ SDEE }->{ 'env:Body' }->{ 'sd:subscriptionId' };
	}

	#
	# SDEE is made to process a bunch of types of events.  'evIdsAlert' is just one
	# I should probably store the events in a hash with the event type as a key
	#
	if(exists($self->{ SDEE }->{ 'env:Body' }->{ 'sd:events' })) {
		$self->{ _events } = $self->{ SDEE }->{ 'env:Body' }->{ 'sd:events' };

		my $events_ref = $self->{ SDEE }->{ 'env:Body' }->{ 'sd:events' };
		foreach my $event_type (keys %$events_ref) {
			my $events = $events_ref->{ $event_type };
			if(ref($events) eq 'ARRAY') {
				foreach my $event (@$events) {
					$event->{ eventType } = $event_type;
					push( @{ $self->{ _eventList }}, $event);
				}
			} elsif (ref($events) eq 'HASH') {
				$events->{ eventType } = $event_type;
				push( @{ $self->{ _eventList }}, $events);
			}
		}
	}

	if(exists($self->{ SDEE }->{ 'env:Body' }->{ 'env:Fault' })) {
		$self->{ _errorMessage }{ Code } = 
			($self->{ SDEE }->{ 'env:Body' }->{ 'env:Fault' }->{ 'env:Code' }->{ 'env:Value' } =~ /^env:(.+)$/)[0];
		$self->{ _errorMessage }{ Subcode } = 
			($self->{ SDEE }->{ 'env:Body' }->{ 'env:Fault' }->{ 'env:Code' }->{ 'env:Subcode' }->{ 'env:Value' } =~ /^sd:(.+)$/)[0];
		$self->{ _errorMessage }{ Reason } = 
			$self->{ SDEE }->{ 'env:Body' }->{ 'env:Fault' }->{ 'env:Reason' };
		$self->{ _isError }=1;
	}

	return 1;

}

sub new {
        my ($class, $document) = @_;

        my $self = {};

        bless( $self, $class );
	if(defined($document)) { $self->consume($document) }

        return $self;
}

1;

