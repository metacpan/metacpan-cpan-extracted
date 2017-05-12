# XML::Idiom.pm
#
# Copyright (c) 2004 Joe Minieri <jminieri@mindspring.com> and OpenService (www.open.com).
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

package XML::Idiom;

use 5.006001;
use strict;
use warnings;

use XML::Simple;

our $VERSION = '0.02';

##########################################################################################
#
# Methods to manage the errors
#
##########################################################################################
sub isError { my $self = shift; return $self->{ _isError }; }
sub errorType { my $self = shift; return $self->{ _errorType }; }
sub errorContent { my $self = shift; return $self->{ _errorContent }; }
sub getError { my $self = shift; return $self->{ _errorHash }; }

##########################################################################################
#
# Methods to manage the events and event list
#
##########################################################################################
sub getNextEvent { my $self = shift; return pop @{ $self->{ _eventList }}; }
sub getNumberOfEvents { my $self = shift; return (scalar @{ $self->{ _eventList }});  }
sub getEvents { my $self = shift; return @{ $self->{ _eventList }}; }

##########################################################################################
#
# Methods to manage the raw and unparsed data
#
##########################################################################################
my $_IDIOM_document;
my $_IDIOM_xml;
sub Idiom { 
	my ($self, $doc) = @_;
	if(defined($doc)) {
		return $self->{ _IDIOM_document } = $doc;
	} else {
		return $self->{ _IDIOM_document }
	}
}

sub XML {
	my ($self, $doc) = @_;
	if(defined($doc)) {
		if(defined($self->{ _IDIOM_document } = $doc)) {
			return $self->{ _IDIOM_xml } = XMLin($self->{ _IDIOM_document });
		} else { 
			return undef;
		}
	} else {
		return $self->{ _IDIOM_xml };
	}
}

sub consume {
	my ($self, $idiom_doc) = @_;

	$self->{ _isError} = undef;
	$self->{ _errorType} = undef;
	$self->{ _errorContent} = undef;
	@{ $self->{ _eventList }} = ();
	$self->{ _IDIOM_document} = undef;
	$self->{ _IDIOM_xml} = undef;

	unless(defined($idiom_doc) and $idiom_doc ne '') { return undef }

	my $idiom_ref = $self->XML($idiom_doc);

	if(my $alerts_ref = $idiom_ref->{ 'evAlert' }) {
		if(ref $alerts_ref eq 'ARRAY') {
			# mutliple alerts
			foreach my $alert_hash_ref ( @$alerts_ref ) {
				push(@{ $self->{ _eventList }}, $alert_hash_ref);
			}
		} elsif( ref $alerts_ref eq 'HASH' ) {
			# one alert
			push(@{ $self->{ _eventList }}, $alerts_ref);
		} # else no alerts!
		return (scalar @{ $self->{ _eventList }});
	} elsif(my $error_ref = $idiom_ref->{ 'errorMessage' }) {
		$self->{ _isError } = 1;
		$self->{ _errorType } = $error_ref->{ 'name' };
		$self->{ _errorContent } = $error_ref->{ 'content' };
		$self->{ _errorHash } = $error_ref;
		return undef;
	}
}

sub new {
        my ($class, $document) = @_;

        my $self = {};

        bless( $self, $class );
	if(defined($document)) { $self->consume($document) }

        $XML::Simple::PREFERRED_PARSER='XML::Parser';

        return $self;
}

1;
__END__

=head1 NAME

XML::Idiom - Intrusion Detection Interaction and Operations Messages (IDIOM)

=head1 SYNOPSIS

  use XML::Idiom;

  my $idiom = XML::Idiom->new();
  $idiom->consume($idiom_xml);

  my @events = $idiom->getEvents;
  my $number_of_events = $idiom->getNumberOfEvents();

  my $processed_xml = $idiom->XML; #you can use Data::Dumper to view it prettier
  

=head1 DESCRIPTION

=over 2

Intrusion Detection Interaction and Operations Messages (IDIOM) is an XML document format developed and
used by Cisco's version 4.0 of their NIDS. This is a simple module for handling these documents is 
included with the distribution of the Net::RDEP module (the method of transporting these documents, as
specified by Cisco).

The document contains one of two pieces of information: either an error message or event information.
If a connection is successful (that is, an HTTP error is not received) the RDEP server will return an 
IDIOM document to the client.  However, it is possible that errors in the protocol itself were detected
(unknown subscription ID, for example) and the document will contain an error.  Otherwise, the document
will contain new event records, as specified by the parameters of the connection.

See www.cisco.com for more information in RDEP or IDIOM.

=head1 IDIOM METHODS

=item new( IDIOM_DOCUMENT )

This is the constructor for a new XML::Idiom object, which may take the option IDIOM document.

=item consume( IDIOM_DOCUMENT )

The consume method will process the IDIOM document, populating the error and event internal structures. 

=item XML

This method will return the IDIOM document, as processed by XML::Simple.  It can be programmatically
manipulated here, or visibly examined with Data::Dumper or something similiar.

=head1 ERROR METHODS

=item isError()

True is the IDIOM document contained an error.

=item errorType()

Returns the string value of the error type, found in the IDIOM document.  This is an error "name" provided
by the RDEP server.

=item errorContent()

Returns the string value of the error content, found in the IDIOM document.  This is a text description provided
by the RDEP server to explain the error.

=item getError()

When the IDIOM document is processed by XML::Simple, the error information is actually stored in a hash reference.
This method will return the hash reference so that you may examine it yourself.

=head1 EVENT METHODS

=item getNumberOfEvents

The number of events retrieved from the document.

=item getNextEvent

Events are received in order of creation time.  This will return the next event from the list of retrieved events.

=item getEvents

This method returns a array of all the events retrieved.

=head1 EXAMPLES

Printing out the IDIOM XML document is probably not all that useful.  There are a few methods of
handling the IDIOM document built into the XML::Idiom module that can be used.  For example:

	my $idiom = XML::Idiom->new();
	$idiom->consume($idiom_xml);
	if (defined($idiom->isError())) {
		if($idiom->errorType eq 'errNotFound') {
			# connection failed, reconnect
			...
		}
	} else {
		my $number_of_events = $idiom->getNumberOfEvents();
		print "RCVD $number_of_events number of events\n";
		while(my $e = $idiom->getNextEvent()) {
			...
		}
	}


=head1 SEE ALSO

Net::RDEP, XML::Simple, Data::Dumper

=head1 AUTHOR

Joe Minieri, E<lt>jminieri@mindspring.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Joe Minieri and OpenService (www.open.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
