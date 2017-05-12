# Net::RDEP.pm
#
# $Id: RDEP.pm,v 1.1 2004/12/23 12:05:58 jminieri Exp $
#
# Copyright (c) 2004 Joe Minieri <jminieri@mindspring.com> and OpenService (www.open.com).
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

package Net::RDEP;

use 5.006001;
use strict;
use warnings;

use MIME::Base64;
use LWP::UserAgent;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our $VERSION = '0.03';

my %_eventTypes = (
        'evError',              1,
        'evAlert',              1,
        'evStatus',             1,
        'evLogTransaction',     1,
        'evShunRqst',           1
);

my %_alertSeverities = (
        'informational',        1,
        'low',                  1,
        'medium',               1,
        'high',                 1
);

my %_errorSeverities = (
        'warning',      1,
        'error',        1,
        'fatal',        1
);

##########################################################################################
#
# AUTOLOAD get/set methods when they're generic
#
use vars '$AUTOLOAD';
sub AUTOLOAD {
        no strict 'refs';
        my ($self, $value) = @_;

        my $key =($AUTOLOAD =~ /.*::([_\w]+)$/)[0];

        unless(defined($key) and exists($self->{ $key })) {
                $self->error(1);
                $self->errorString("No such parameter $key");
                return undef;
        }

        # set this up for next time
        *{$AUTOLOAD} = sub {
		my ($self, $value) = @_;
                if (defined($value)) {
                        return $self->{ $key } = $value;
                } else {
                        return defined($self->{ $key })?$self->{ $key }:undef;
                }
        };

        # go ahead and execute it this time
        if ( defined( $value )) {
                # set operation
                return $self->{ $key } = $value;
        } else {
                # get operation
                return defined($self->{ $key })?$self->{ $key }:undef;
        }
}

##########################################################################################
#
# Helper methods
#
sub _make_uri {
	my $self = shift;

	my $URI = URI->new();
	$URI->scheme('https');
	$URI->host( $self->Server );
	$URI->port( $self->Port );
	$URI->path( $self->Path );

	return $URI->as_string;
}

##########################################################################################
#
# Non-generic get/set methods
#
sub _processTraits {
	my $self = shift;
	my $whichTraits = shift;

	$self->error(undef);
	$self->errorString(undef);

	unless(defined($whichTraits) and exists($self->{ $whichTraits })) {
		$self->error(1);
		$self->errorString("No such trait attribute: $whichTraits");
		return undef;
	}

	# the spec for this parameter isn't clear -- I'm going to assume this
	# goes from 0-15 instead of 1-16.

	my @traits;
	foreach my $trait ( @_ ) {
		if( $trait =~ /^\d+$/ and $trait <16 and $trait >-1 ) {
			# individual trait
			push(@traits, $trait);
		} elsif ( $trait =~ /^(\d+)-(\d+)$/ and 
				$1 <16 and $1>-1 and
				$2 <16 and $2>-1 and
				$1 < $2 ) {
			# trait range
			push(@traits, $trait);
		}
	}

	if($#traits > -1) {
		# note -- the spec shows examines with a ',' separating the traits
		# and specifies a '+' between them.  I'm going with the example.
		return $self->{ $whichTraits } = join(',', @traits);
	} else {
		$self->error(1);
		$self->errorString("No valid alarm traits: " . join(',', @_));
		return undef;
	}
}

sub mustHaveAlarmTraits {
	my $self = shift;

	unless(defined($_[0])) {
		# if no parameter, the treat as "get" method
		return $self->{ 'mustHaveAlarmTraits' };
	}

	return $self->_processTraits('mustHaveAlarmTraits', @_);
}

sub mustNotHaveAlarmTraits {
	my $self = shift;

	unless(defined($_[0])) {
		# if no parameter, the treat as "get" method
		return $self->{ 'mustNotHaveAlarmTraits' };
	}

	return $self->_processTraits('mustNotHaveAlarmTraits', @_);
}


sub errorSeverities {
	my $self = shift;
	my $error = shift;

	$self->error(undef);
	$self->errorString(undef);

	unless(defined($error)) {
		# if no parameter, the treat as "get" method
		return $self->{ 'errorSeverities' };
	}

	$error = lc($error);
	if(exists($_errorSeverities{ $error })) {
		return $self->{ 'errorSeverities' } = $error
	} else {
		$self->error(1);
		$self->errorString("Invalid error severity: $error");

		return undef;
	}
}

sub alertSeverities {
	my $self = shift;

	$self->error(undef);
	$self->errorString(undef);

	unless(defined($_[0])) {
		# if no parameter, the treat as "get" method
		return $self->{ 'alertSeverities' };
	}

	my @alertseverities;
	foreach my $s ( @_ ) {
		my $severity = lc($s);
		if(exists($_alertSeverities{ $severity })) {
			push(@alertseverities, $severity);
		}
	}

	if($#alertseverities > -1) {
		return $self->{ 'alertSeverities' } = join('+', @alertseverities);
	} else {
		$self->error(1);
		$self->errorString("No valid alert severities: " . join(',', @_));
		return undef;
	}
}

sub events {
	my $self = shift;

	unless(defined($_[0])) {
		# if no parameter, the treat as "get" method
		return $self->{ 'events' };
	}

	$self->error(undef);
	$self->errorString(undef);

	my @eventList;

	my %dedup;
	foreach my $eventtype ( grep( !$dedup{ $_ }++, @_ ) ) {
		if(exists($_eventTypes{ $eventtype })) {
			push(@eventList, $eventtype);
		}
	}

	if($#eventList > -1) {
		return $self->{ 'events' } = join('+', @eventList);
	} else {
		$self->error(1);
		$self->errorString("No valid event types: " . join(',', @_));
		return undef;
	}
}

sub confirm {
	my $self = shift;
	my $confirm = shift;

	unless(defined($confirm)) {
		# if no parameter, the treat as "get" method
		return $self->{ 'confirm' };
	}

	$self->error(undef);
	$self->errorString(undef);

	$confirm = lc($confirm);
	if($confirm eq 'no' or $confirm eq 'yes') {
		return $self->{ 'confirm' } = $confirm;
	} else {
		$self->error(1);
		$self->errorString("Invalid confirm value: $confirm");
		return undef;
	}
}

sub Type {
	my $self = shift;
	my $type = shift;

	unless(defined($type)) {
		# if no parameter, the treat as "get" method
		return $self->{ 'Type' };
	}

	$self->error(undef);
	$self->errorString(undef);

	$type = lc($type);
	if($type eq 'subscription' or $type eq 'query') {
		return $self->{ 'Type' } = $type;
	} else {
		$self->error(1);
		$self->errorString("Invalid RDEP connection type: $type");
		return undef;
	}
}

##########################################################################################
#
sub new {
        my $caller = shift;
        my %attr = @_;

	my $class = (ref($caller) or $caller);
        my $self = bless {
        	# connection parameters
        	'Server',		=> '127.0.0.1',
        	'Port',                 => 443,
        	'UserAgent',            => 'RDEP Client/4.0',
        	'Username',             => 'username',
        	'Password',             => 'password',
        	'Path',                 => '/cgi-bin/event-server',
        	'state',                => 'closed',
        	# subscription parameters
        	'Type',                 => 'subscription',
        	'Cookie',               => undef,
        	'Authorization',        => undef,
        	'subscriptionId',       => undef,
        	# retrieval parameters
        	'startTime',            => undef,
        	'stopTime',             => undef,  # only for queries
        	'events',               => 'evAlert',
        	'alertSeverities',      => undef,
        	'errorSeverities',      => undef,
        	'mustHaveAlarmTraits',  => undef,
        	'mustNotHaveAlarmTraits',       => undef,
        	'timeout',              => 1,
        	'maxNbrOfEvents',       => 20,     # set this just so we don't crush the box
        	'confirm',              => 'yes',
        	# results
        	'missedEvents', 	=> undef,
        	'error',        	=> undef,
        	'errorString',  	=> undef
	}, $class;

	foreach my $attribute ( keys %attr ) {
		$self->$attribute( $attr{ $attribute });
	}

	$self->state('closed');
	$self->missedEvents(undef);
	$self->error(undef);
	$self->errorString(undef);

        return $self;

}

sub open {
	my $self = shift;

	$self->error(undef);
	$self->errorString(undef);

	my $http_auth = $self->Username . ':' . $self->Password;
	$self->Authorization('Basic ' . MIME::Base64::encode( $http_auth, ''));

	my %headers = (
		'User-Agent'	=> $self->UserAgent,
		'Authorization'	=> $self->Authorization
	);

	# manditory parameters for subscription
	my %form_parameters = (
		events	=> $self->events
	);

	if ($self->Type eq 'subscription') {
		$form_parameters{ 'action' } = 'open';
		if (defined($self->timeout)) {
			$form_parameters{ 'timeout' } = $self->timeout;
		}
		if (defined($self->confirm)) {
			$form_parameters{ 'confirm' } = $self->confirm;
		}
	}

	if (defined($self->startTime)) {
		$form_parameters{ 'startTime' } = $self->startTime;
	}

	if (defined($self->maxNbrOfEvents)) {
		$form_parameters{ 'maxNbrOfEvents' } = $self->maxNbrOfEvents;
	}

	if (defined($self->mustHaveAlarmTraits)) {
		$form_parameters{ 'mustHaveAlarmTraits' } = $self->mustHaveAlarmTraits;
	}

	if (defined($self->mustNotHaveAlarmTraits)) {
		$form_parameters{ 'mustNotHaveAlarmTraits' } = $self->mustNotHaveAlarmTraits;
	}

	if (defined($self->alertSeverities)) {
		$form_parameters{ 'alertSeverities' } = $self->alertSeverities;
	}

	if (defined($self->errorSeverities)) {
		$form_parameters{ 'errorSeverities' } = $self->errorSeverities;
	}

	if ($self->Type eq 'query' and defined($self->stopTime)) {
		$form_parameters{ 'stopTime' } = $self->stopTime;
	}

	my $LWP = LWP::UserAgent->new();
	my $result = $LWP->post($self->_make_uri, \%form_parameters, %headers);

	if($result->is_success) {
		if($self->Type eq 'subscription' ) {
			if(my $cookie = $result->header('Set-Cookie')) {
				$self->Cookie((split(';', $cookie))[0]);
			} else {
				$self->error(1);
				$self->errorString( "No Cookie in header: " . $result->status_line);
				return undef;
			}

			if(my $parameter = $result->header('X-CISCO-RDEP-PARAMETERS')) {
				$self->subscriptionId((split('=',$parameter))[1]);
			} else {
				$self->error(1);
				$self->errorString( "No subscription ID in header: " . $result->status_line);
				return undef;
			}

			$self->state('opened');
		}
	} else {
		$self->error(1);
		$self->errorString( "Query failed: " . $result->status_line);
	}

	# on a subscription open, there is no content.  On a query, the content is the events
	return $result->content;
}

sub get {
	my $self = shift;

	$self->error(undef);
	$self->errorString(undef);

	# if we're just doing a query, return the "open";
	if( $self->Type eq 'query' ) { return $self->open() }

	# if we're doing a subscription, open first, the proceed
	if( $self->state eq 'closed' ) { $self->open() }

	#
	# only event subscriptions should be here
	my %headers = (
		'User-Agent'	=> $self->UserAgent,
		'Authorization'	=> $self->Authorization,
		'Cookie'	=> $self->Cookie
	);

	my %form_parameters = (
		'action'		=> 'get',
		'subscriptionId'	=> $self->subscriptionId
	);

	if (defined($self->timeout)) {
		$form_parameters{ 'timeout' } = $self->timeout;
	}

	if (defined($self->confirm)) {
		$form_parameters{ 'confirm' } = $self->confirm;
	}

	if (defined($self->maxNbrOfEvents)) {
		$form_parameters{ 'maxNbrOfEvents' } = $self->maxNbrOfEvents;
	}

	my $LWP = LWP::UserAgent->new();
	my $result = $LWP->post($self->_make_uri, \%form_parameters, %headers);

	if($result->is_success) {
		if(my $cookie = $result->header('Set-Cookie')) {
			$self->Cookie((split(';', $cookie))[0]);
		}

		if(my $parameter = $result->header('X-CISCO-RDEP-PARAMETERS')) {
			my ($name, $value) = split('=', $parameter);
			if($name eq 'missedEvents') {
				if($value eq 'true') {
					$self->missedEvents(1);
					$self->error(1);
					$self->errorString( "Events were dropped between polls");
				} else {
					$self->missedEvents(undef);
				}
			}
		}
		$self->state('opened');
		return $result->content;
	} else {
		$self->error(1);
		$self->errorString( "Query failed: " . $result->status_line);
		$self->state('closed');
		return undef;
	}
}

sub close {
	my $self = shift;

	$self->error(undef);
	$self->errorString(undef);

	return if( $self->state eq 'closed' or $self->Type eq 'query' ); 

	my %headers = (
		'User-Agent'	=> $self->UserAgent,
		'Authorization'	=> $self->Authorization,
		'Cookie' => $self->Cookie
	);

	# manditory parameters for subscription
	my %form_parameters = (
		action		=> 'close',
		subscriptionId	=> $self->subscriptionId
	);

	my $LWP = LWP::UserAgent->new();
	my $result = $LWP->post($self->_make_uri, \%form_parameters, %headers);

	$self->state('closed');
	if(defined($result) and $result->is_success) {
		return $result->content;
	} else {
		$self->error(1);
		$self->errorString( "Query failed: " . $result->status_line);
		return undef;
	}
}

#
# close connection, just in case we forgot to call close() properly
sub DESTROY {
	my $self = shift;

	if($self->state eq 'opened') { $self->close() }
}

#
##########################################################################################

1;
__END__

=head1 NAME

Net::RDEP - Remote Data Exchange Protocol Client

=head1 SYNOPSIS

  use Net::RDEP;

  $rdep = Net::RDEP->new(Username => 'rdepuser', Type => 'subscription');
  $rdep->Password('foobar');
  $rdep->Server('192.168.1.2');

  $rdep->mustHaveAlarmTraits(3,'5-10');
  $rdep->alertSeverities('high', 'medium');
  $rdep->events('evAlert');

  $idiom_xml = $rdep->get();
  $rdep->close();

=head1 DESCRIPTION

=over 2

Remote Data Exchange Protocol (RDEP) is a protocol designed by Cisco Systems in order to exchange
Intrusion Detection System events, configuration, log, and control messages. This protocol is
supported at least the Cisco IDS version 4.0.

This implementation only supports the collection of events.

The events are retrieved in a format, also developed by Cisco, referred to as Intrusion Detection
Interaction and Operations Messages (IDIOM), which is an XML document. A simple module for handling
these documents is included with this distribution (XML::Idiom).

RDEP supports two methods for retrieving events: an event query and an event subscription.  Both
methods use SSL to query the RDEP server and retrieve the events.  The event query method will
retrieve all the events in a given time range.  No connection is maintained in anyway.  The
event subscription, however, does maintain a connection and will support multiple "gets" to
continue to retrieve events as they are available.

See www.cisco.com for more information in RDEP or IDIOM.

=head1 CONNECTION METHODS

=item new( [Parameter => value,] )

This is the constructor for a new Net::RDEP object.  Parameters to the RDEP object can be
specified here or later.

=item open()

If the Type is set to 'query', this method will perform the event query with the already set
parameters.  Otherwise, an event subscription will be established.

=item get()

If the Type is set to 'query', the get() method simply calls open() and performs an event query.
If an event subscription is already established, get() will return the next maxNbrOfEvents from
the server.  If a subscription has not been established, then it will be established first.

=item close()

An event subscription should be closed when no longer being used.  The serer will time out the
subscription if this doesn't happen.

=item subscriptionID

An event subscription maintains a subscription ID.  This is set automatically, but can be 
retrieved.  If this value is corrupted during a session, the session will become invalid.

=head1 PARAMETER METHODS

These method names and case are, in general, as specified in the RDEP specification from Cisco.

Calling the method with arguments will cause that RDEP parameter to be set with those arguments.
Calling the method without arguments returns the current value of the parameter.  Calling the
method with arguments repeatedly will cause the parameter to be reset to the latest set of
arguments.  If a parameter supports more than one parameter, specify them all in the same call.

=item Type

Set this parameter to 'subscription' to establish an event subscription and to 'query' for an
event query.

=item startTime

Specify the start time of the events to be retrieved.  If not specified, collection will be
started by the oldest events.

=item stopTime

Events retrieved will have a creation time less than or equal to the stopTime.  If not specified,
collection will end with the newest events.  Note - this only applies to event queries.

=item events

Set the type of events to retrieve.  Valid event types are: evError, evAlert, evLogTransaction,
evStatus, evShunRqst.

=item alertSeverities

Set the alert severities of events to retrieve.  Valid alert severities are: informational, 
low, medium, and high.  Multiple alert severities may be specified:

	$rdep->alertSeverities( 'medium', 'high');

Default is ALL alert severities.

=item errorSeverities

Set the error severity of events to retrieve.  Valid error severities are: warning, error,
and fatal.  Multiple error severities may be specified.

	$rdep->errorSeverities( 'fatal', 'error');

Default is ALL error severities.

=item mustHaveAlarmTraits

Alarm traits are a set of 16 attribute bits.  Each bit has a user-defined value classifing an
evAlert into up to 16 different categories.  Specify these either as single digits or ranges:

	$rdep->mustHaveAlarmTraits(3, '5-10');

The mustHaveAlarmTraits parameters restricts retrieval of events to only those with the given
attribute bit set.

=item mustNotHaveAlarmTraits

The mustNotHaveAlarmTraits parameters restricts retrieval of events to only those without the given
attribute bit set.

=item timeout

The maximum number of seconds the server will block before returning. When this pararmeter
is not specified, the request will not timeout.

=item maxNbrOfEvents

The maximum number of events to retrieve in the query. Some servers impose an upper-limit on
the number of events that can be retrieved in a query. When this parameter is not specified,
the server will return all events, up to a server imposed limit, that match the subscription's
query criteria

=item confirm

Acknowledge that the events retrieved in the previous get() were received.

=item missedEvents

When performing an event subscription, it is possible that events could be lost between polls
if the poll happens so infrequently that the server is forced to drop events.  In this case, the
missedEvents parameter will be "defined".

=item error

In the case of an error during parameter setting, server connection, or event retrieval, this 
parameter is "defined".

=item errorString

If the 'error' parameter is defined, an explanation of the error will be stored here.

=head1 EXAMPLES

This example shows a simple way to perform an event query:

	#!/usr/local/bin/perl -w

	use Net::RDEP;

	my $rdep = Net::RDEP->new(
		Username => 'rdepuser',
		Password => 'rdeppass',
		Server   => 'rdephost',
		Type     => 'query' );

	my $idiom_xml = $rdep->get();
	if(defined($rdep->error)) {
		print "ERROR: " . $rdep->errorString;
	}
	print $idiom_xml;

In this example, an event subscription is performed:

	#!/usr/local/bin/perl -w

	use Net::RDEP;

	my $rdep = Net::RDEP->new(
		Username => 'rdepuser',
		Password => 'rdeppass',
		Server   => 'rdephost' );

	while (my $idiom_xml = $rdep->get()) {
		if(defined($rdep->error)) {
			print "ERROR: " . $rdep->errorString;
		}
		print $idiom_xml;
	}

	$rdep->close();

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

XML::Idiom, MIME::Base64

=head1 AUTHOR

Joe Minieri, E<lt>jminieri@mindspring.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Joe Minieri and OpenService (www.open.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
