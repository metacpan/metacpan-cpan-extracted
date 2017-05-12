# Net::SDEE.pm
#
# $Id: SDEE.pm,v 1.4 2005/03/07 20:12:39 jminieri Exp $
#
# Copyright (c) 2004-2005 Joe Minieri <jminieri@mindspring.com> and OpenService (www.open.com).
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

package Net::SDEE;

use 5.006001;
use strict;
use warnings;

use LWP::UserAgent;

use XML::SDEE;
use Net::SDEE::Query;
use Net::SDEE::Session;
use Net::SDEE::Subscription;

our $VERSION = '0.01';

#
# These are the parameters for each query type
my @_open_parameters = qw/action sessionId startTime events idsAlertSeverities force/;
my @_get_parameters = qw/action sessionId subscriptionId timeout maxNbrOfEvents confirm/;
my @_cancel_parameters = qw/action sessionId subscriptionId/;
my @_close_parameters = qw/action sessionId subscriptionId/;

##########################################################################################
#
# AUTOLOAD get/set methods when they're generic
#
use vars '$AUTOLOAD';
sub AUTOLOAD {
        no strict 'refs';
        my ($self, $value) = @_;

        my $method =($AUTOLOAD =~ /.*::([_\w]+)$/)[0];
        return if $method eq 'DESTROY';

	#
	# Pass all unknown methods to the session object
        unless(defined($method) and exists($self->{ _session }->{ $method })) {
                $self->call_debug("No such parameter $method");
                return undef;
        }

        # set this up for next time
        *{$AUTOLOAD} = sub {
                my ($self, $value) = @_;
                if (defined($value)) {
                        return $self->{ _session }->{ $method } = $value;
                } else {
                        return defined($self->{ _session }->{ $method })?$self->{ _session }->{ $method }:undef;
                }
        };

        goto &$AUTOLOAD;
}
#
##########################################################################################

##########################################################################################
#
# Debug callback routine
#
sub debug_log {
	my $message = shift;

	unless(defined($message)) { return undef }

	# caller 0 = current
	# caller 1 = eval
	# caller 2 = call_debug
	# caller 3 = actual caller
	my $caller = (caller(3))[3];
	print "$caller() $message\n";
	#warn $message;
}

sub debug_callback {
	my ($self, $callback) = @_;

	unless(defined($callback)) {
		return $self->{ _debug_callback };
	}

	$self->set_callback('_debug_callback', $callback);
}

sub call_debug {
	my $self = shift;

	return unless(defined($self->{ _debug_callback }));

	if(defined($self->debug)) {
		my $handler = $self->{ _debug_callback };
		my $ret = eval { &$handler(@_); };

		return (defined($ret))?$ret:$@;
	} else {
		return undef;
	}
}

sub debug {
	my ($self, $debug) = @_; 

	if(defined($debug)) {
		return $self->{ _debug } = $debug;
	} else {
		return $self->{ _debug };
	}
}

#
##########################################################################################

##########################################################################################
#
# Callback setting/executing methods
#
sub execute {
	my $self = shift;

	return unless(defined($self->{ _callback }));

	my $handler = $self->{ _callback };
	my $ret = eval { 
		# block out die/warn just in case...
		local $SIG{ __DIE__ };
		local $SIG{ __WARN__ };
		&$handler(@_);
	};

	return (defined($ret))?$ret:$@;
}

sub set_callback {
	my ($self, $which, $callback) = @_;

	unless(defined($callback) and defined($which)) {
		return $self->{ $which };
	}

	if(ref($callback) eq 'CODE') {
		$self->{ $which } = $callback;
	} else {
		return undef;
	}
}

sub callback {
	my ($self, $callback) = @_;

	unless(defined($callback)) {
		return $self->{ _callback };
	}

	$self->set_callback('_callback', $callback);
}

sub returnResults {
	my $self = shift;
	my $results = shift;

	if(defined($self->returnRawXML)) {
		# return RAW XML only
		return defined($self->callback)?$self->execute($results, @_):$results;
	} 

	my $returnContents;
	unless(defined($self->{ _xml }->XML)) {
		$self->{ _xml }->consume($results);
		if($self->{ _xml }->isError) {
			$self->call_debug( $self->{ _xml }->getErrorString );
		}
	}

	if(defined($self->returnXML)) {
		# return PROCESSED XML only
		$returnContents = $self->{ _xml }->SDEE;
		return defined($self->callback)?$self->execute($returnContents, @_):$returnContents;
	}

	# return only events
	if(defined($self->callback)) {
		# execute "callback" for each event
		my @returnValues;
		while(my $event = $self->{ _xml }->getEvent) {
			my $ret = $self->execute($event, @_);
			push(@returnValues, $ret);
		}
		return \@returnValues;
	} else {
		$returnContents = $self->{ _xml }->getEvents;
		return defined($self->callback)?$self->execute($returnContents, @_):$returnContents;
	}
}
#
##########################################################################################

##########################################################################################
#
# set/get methods
#
sub returnRawXML {
	my ($self, $returnRawXML) = @_; 

	if(defined($returnRawXML)) {
		return $self->{ _returnRawXML } = $returnRawXML;
	} else {
		return $self->{ _returnRawXML };
	}
}

sub returnXML {
	my ($self, $returnXML) = @_; 

	if(defined($returnXML)) {
		return $self->{ _returnXML } = $returnXML;
	} else {
		return $self->{ _returnXML };
	}
}

sub returnEvents {
	my ($self, $returnEvents) = @_; 

	if(defined($returnEvents)) {
		return $self->{ _returnEvents } = $returnEvents;
	} else {
		return $self->{ _returnEvents };
	}
}
#
##########################################################################################

##########################################################################################
#
sub getNumberOfSubscriptions {
	my $self = shift;

	return scalar keys %{$self->{ _subscriptions }};
}

sub getSubscription {
	my ($self, $subscriptionId) = @_;

	unless(defined($subscriptionId) and exists($self->{ _subscriptions }->{ $subscriptionId })) { return undef }

	return $self->{ _subscriptions }->{ $subscriptionId };
}

sub getSubscriptionIds {
	my $self = shift;

	my @returnValue = keys %{$self->{ _subscriptions }};
	return \@returnValue;
}

sub addSubscription {
	my $self = shift;

	if( $#_ == 0 and ref($_[0]) eq 'Net::SDEE::Subscription') {
		return $self->open($_[0]);
	} else {
		return $self->open(Net::SDEE::Subscription->new(@_));
	}
}

sub deleteSubscription {
	my ($self, $subscriptionId) = @_;

	unless(defined($subscriptionId) and exists($self->{ _subscriptions }->{ $subscriptionId })) { return undef }

	return delete($self->{ _subscriptions }->{ $subscriptionId });
}

sub addQuery {
	my $self = shift;

	if( $#_ == 0 and ref($_[0]) eq 'Net::SDEE::Query') {
		$self->{ _query } = $_[0];
	} else {
		$self->{ _query } = Net::SDEE::Query->new(@_);
	}
}

sub addSession {
	my $self = shift;

	if( $#_ == 0 and ref($_[0]) eq 'Net::SDEE::Session') {
		$self->{ _session } = $_[0];
	} else {
		$self->{ _session } = Net::SDEE::Session->new(@_);
	}
}
#
##########################################################################################

##########################################################################################
#
sub new {
        my $caller = shift;
        my %args = @_;

	my $class = (ref($caller) or $caller);
        my $self = bless {
			'_xml',			XML::SDEE->new(),
			'_session',		undef,
			'_subscriptions',	{},
			'_query',		undef,
			'_callback',		undef,
			'_returnXML',		undef,
			'_returnRawXML',	undef,
			'_returnEvents',	undef,
			'_debug',		undef,
			'_debug_callback',	\&debug_log
		}, $class;

	if(defined($args{ Session }) and ref($args{ Session }) eq 'Net::SDEE::Session') {
		$self->{ _session } = $args{ Session };
		delete($args{ Session }); # clean up for loop @ bottom
	} else {
		$self->{ _session } = Net::SDEE::Session->new();
	}

	if(defined($args{ Query }) and ref($args{ Query }) eq 'Net::SDEE::Query') {
		$self->{ _query } = $args{ Query };
		delete($args{ Query }); # clean up for loop @ bottom

		# we should NOT have both, so drop the subscription if we do...
		delete($args{ Subscription });
	}

	#
	# Note, we cannot pass in a Subscription because we need an Subscription ID that
	# we only get when we connect.
	#
	foreach my $attribute ( keys %args ) {
		$self->$attribute( $args{ $attribute });
	}

	#
	# If we've set 'returnXML', then make sure 'returnEvents' is unset.
	# Also, if 'returnXML' is not set, make sure 'returnEvents' is set.
	if(defined($self->returnRawXML)) {
		# return RAW XML
		$self->returnXML(undef); 
		$self->returnEvents(undef); 
	} elsif(defined($self->returnXML)) {
		# return PROCESSED XML
		$self->returnRawXML(undef); 
		$self->returnEvents(undef); 
	} else {
		# return Events
		$self->returnXML(undef); 
		$self->returnRawXML(undef); 
		$self->returnEvents(1); 
	}

        return $self;
}

#
# Opens a session
# Parameters:
# - action = open
# - startTime = 0
# - events = evtype
# - idsAlertSeverities 
# - force = yes/no
#
# Response Code:
# - errLimitExceeded = server has reached subscription limit
#
# Return subscriptionID
#
sub open {
	my $self = shift;

	my $subscription = undef;
	if(defined($_[0]) and ref($_[0]) eq 'Net::SDEE::Subscription') {
		# got a subscription object
		$subscription = shift;
	} else {
		# don't have a subscription object, make a new one
		$subscription = Net::SDEE::Subscription->new();
	}

	unless(defined($subscription->sessionId)) {
		if(my $sessionId = $self->{ _session }->sessionId) {
			$subscription->sessionId($sessionId);
		}
	}

	if( $#_ > 0 ) {
		my %args = @_;
		foreach my $parameter (keys %args) {
			$subscription->$parameter($args{ $parameter });
		}
	}

	$subscription->action('open');
	
        my $LWP = LWP::UserAgent->new();
        my $result = $LWP->post(
		$self->{ _session }->getURL,
                $subscription->getParameters(@_open_parameters),
                %{ $self->{ _session }->getHeader }
	);

	if($result->is_success) {
		if($self->{ _session }->Type eq 'subscription') {
			if(my $cookie = $result->headers('SET-COOKIE')) {
				$self->{ _session }->Cookie((split(';', $cookie))[0]);
			} else {
				$self->call_debug( 'No Cookie in header: ' . $result->status_line);
				return undef;
			}
			$self->{ _session }->state('opened');
		}

		$self->{ _xml }->reset;
		$self->{ _xml }->consume($result->content);
		if(my $sessionId = $self->{ _xml }->sessionId) {
			$self->sessionId($sessionId);
			$subscription->sessionId($sessionId);
			$self->call_debug("New SessionID: $sessionId");
		} elsif($sessionId = $self->{ _session }->sessionId) {
			$self->call_debug("Existing SessionID: $sessionId");
		} else {
			$self->call_debug('NO SessionID');
		}
		if(my $subscriptionId = $self->{ _xml }->subscriptionId) {
			$subscription->subscriptionId($subscriptionId);
			$self->{ _subscriptions }->{ $subscriptionId } = $subscription;
			$self->call_debug("New SubscriptionID: $subscriptionId");
		}
	} else {
		$self->call_debug( 'open failed: ' . $result->status_line);
		return undef;
	}
	return $self->returnResults($result->content, $subscription->subscriptionId);
}

#
# Retrieve Events
# Parameters:
# - action = get
# - timeout = # (blocking, waiting for events )
# - maxNbrOfEvents = #
# - confirm = yes/no
#   * unconfirmed events will be resent
#
# Response Codes:
# - missedEvents - server dropped events since last retrieval
# - errNotFound - subscription not open
# - errInUse - retrieval already taking place
#
sub get {
	my ($self, $subscriptionId) = @_;

	my $parameters;
	if(defined($subscriptionId)) {
		# setup for subscription

		# perhaps should call open() to fix these? but what to do w/ returned XML?
		unless(defined($self->{ _subscriptions }->{ $subscriptionId })) {
			$self->call_debug("No such subscription Id: $subscriptionId");
			return undef;
		}
        	unless( $self->{ _session }->state eq 'opened' ) {
			$self->call_debug('Session state is ' . $self->{ _session }->state);
			return undef;
		}
		$self->{ _subscriptions }->{ $subscriptionId }->action('get');
                $parameters = $self->{ _subscriptions }->{ $subscriptionId }->getParameters(@_get_parameters);
	} else {
		# setup for query
		unless(defined($self->{ _query })) {
			$self->{ _query } = Net::SDEE::Query->new();
		}
                $parameters = $self->{ _query }->getParameters(@_get_parameters);
	}

        my $LWP = LWP::UserAgent->new();
        my $result = $LWP->post(
		$self->{ _session }->getURL,
		$parameters,
                %{ $self->{ _session }->getHeader }
	);

        if($result->is_success) {
		#
		# Response Codes:
		# - missedEvents - server dropped events since last retrieval
		# - errNotFound - subscription not open
		# - errInUse - retrieval already taking place
		#
        } else {
                $self->call_debug('http session failed ' . $result->status_line);
                $self->{ _session }->state('closed');
		return undef;
        }
	$self->{ _xml }->reset;
	return $self->returnResults($result->content, $subscriptionId);
}

#
# Cancels a blocked subscription
#
# Parameters:
# - action = cancel
#
# Response Codes:
# - errNotFound - subscription not open
#
# Return ?? XML document?
#
sub cancel {
	my ($self, $subscriptionId) = @_;

	return undef unless(defined($subscriptionId));

	$self->call_debug("SubscriptionId: $subscriptionId");

	my $subscription;
	unless($subscription = $self->getSubscription( $subscriptionId )) {
		$self->call_debug("NO subscription $subscriptionId");
		return undef;
	}

	$subscription->action('cancel');

        my $LWP = LWP::UserAgent->new();
        my $result = $LWP->post(
		$self->{ _session }->getURL,
                $subscription->getParameters(@_cancel_parameters),
                %{ $self->{ _session }->getHeader }
	);

        if($result->is_success) {
		#
		# Response Codes:
		# - errNotFound - subscription not open
		#
        } else {
                $self->call_debug( 'cancel failed: ' . $result->status_line);
		return undef;
        }
	$self->{ _xml }->reset;
	return $self->returnResults($result->content, $subscriptionId);
}

#
# Closes a subscription
#
# Parameters:
# - action = close
#
# Response Codes:
# - errNotFound - subscription not open
#
# Return ?? XML document?
#
sub close {
	my ($self, $subscriptionId) = @_;

	return undef unless(defined($subscriptionId));

	my $subscription;
	unless($subscription = $self->getSubscription( $subscriptionId )) {
		$self->call_debug("NO subscription $subscriptionId");
		return undef;
	}

	my $sessionId = $subscription->sessionId;
	$self->call_debug("SessionId: $sessionId, SubscriptionId: $subscriptionId");

	$subscription->action('close');

        my $LWP = LWP::UserAgent->new();
        my $result = $LWP->post(
		$self->{ _session }->getURL,
                $subscription->getParameters(@_close_parameters),
                %{ $self->{ _session }->getHeader }
	);

	$self->deleteSubscription($subscriptionId);
        if($result->is_success) {
		#
		# Response Codes:
		# - errNotFound - subscription not open
		#
        } else {
                $self->call_debug( 'close failed: ' . $result->status_line);
		return undef;
        }
	$self->{ _xml }->reset;
	return $self->returnResults($result->content, $subscriptionId);
}

#
# get ALL
sub getAll {
	my $self = shift;

	my $returnAll = {};

	foreach my $subscriptionId ( @{ $self->getSubscriptionIds } ) {
		if(my $return_value =$self->get($subscriptionId)) {
			$self->call_debug($return_value);
		}
	}

	return $returnAll;
}

#
# close ALL
sub closeAll {
	my $self = shift;

	my $returnAll = {};

	# need to close ALL the subscriptions
	foreach my $subscriptionId ( @{ $self->getSubscriptionIds }) {
		if(my $return_value =$self->close($subscriptionId)) {
			$self->call_debug($return_value);
		}
	}

	return $returnAll;
}

#
# Close the session, just in case we forgot...
sub DESTROY {
	my $self = shift;

	# need to close ALL the subscriptions
	$self->closeAll();
}

#
##########################################################################################

1;
__END__

=head1 NAME

Net::SDEE - Security Device Event Exchange

=head1 SYNOPSIS

  use Net::SDEE;

  $sdee = Net::SDEE->new(Username => 'sdeeuser', Type => 'subscription');
  $sdee->Password('foobar');
  $sdee->Server('192.168.1.2');

  $sdee->getAll();
  $sdee->closeAll();

=head1 INTRODUCTION

=over 2

The Security Device Event Exchange (SDEE) protocol was developed to communicate the events generated by security devices.  Currently, only IDS events are supported, but the protocol is designed to be extensible, allowing additional event types to be defined and included.

The SDEE client establishes a session with the server by successfully authenticating with that server.  Once authenticated, a session ID or session cookie is given to the client, which is included with all futures requests.

SDEE supports two methods for retrieving events: an event query and an event subscription.  Both methods use SSL to query the SDEE server and retrieve the events.  The event query method will retrieve all the events in a given time range.  No connection is maintained in anyway.  The event subscription, however, does maintain a connection and will support multiple "gets" to continue to retrieve events as they are available.  Furthermore, multiple subscriptions are supported for a single session.  In this case, each subscription would be configured to retrieve different events (either type or severity).

To either the query or subscription request, the server's response is received in the form of a SOAP document.  The document may contain response or error messages, as well as one or more events.

For more information and the specification for SDEE, see http://www.icsalabs.com/html/communities/ids/sdee/index.shtml

=head1 DESCRIPTION

There are several ways to use this module, depending on what you're interested in doing and what you'd like to leave to the SDEE object to handle.

=head1 CONTROL METHODS

=item new( [Parameter => value,] )

This is the constructor for a new Net::SDEE object.  Parameters to the SDEE object can be specified here or later.

=item open( [Subscription Object] )

This method is only used for subscriptions.  If a subscription object is passed as a paramter, that subscription is opened and established.  Otherwise, a new instance of a subscription object is created.  The server is presented with the options in the subscription object and a subscription ID is created and returned.  This ID is used by the client in all future queries so that the server might differentiate between subscriptions and return the correct set of events.  Note - no events are returned at this point, the subscription is simply registered with the server.

=item get( subscription ID )

This method will retrieve events.  If a subscription ID is passed as a paramter, then that subscription is requested of the server, otherwise, it is assumed that the desire was for an event query and that is performed.

=item cancel( subscription ID )

Canceling a subscription is done when a get() is blocked and the desire is to interrupt.  Obviously, this needs to be sent through a different session than the currently blocked one.

=item close( subscription ID )

Informs the server that this subscription is no longer valid.  This subscription is removed from the list of active subscriptions and no longer queried.

=item getAll()

Perform a get() for all established subscriptions.  This should be used only when callback routines are implemented, otherwise, the results from the multiple gets are lost.

=item closeAll()

Performs a close() on all established subscriptions.

=head1 SESSION METHODS

The session methods describe how the client will connect to the server.

=item Scheme

Sets the URI scheme for the connection.  The default is 'https'

=item Port

Sets the URI port for the connection.  The default is '443'

=item Server

Sets the SDEE server for the session.  The default is '127.0.0.1'.

=item Username

Sets the username to use when authenticating to the server.

=item Password

Sets the password to use when authenticating to the server.

=head1 RETRIEVAL METHODS

These methods specify to the server the parameters surrounding event retrieval for each subscription or query.

=item startTime

Specify the start time of the events to be retrieved.  If not specified, collection will be started by the oldest events.  This applies to both subscriptions and queries.

=item stopTime

Events retrieved will have a creation time less than or equal to the stopTime.  If not specified, collection will end with the newest events.  Note - this only applies to event queries.

=item timeout

The maximum number of seconds the server will block before returning. When this pararmeter is not specified, the request will not timeout.  This applies only to subscriptions.

=item maxNbrOfEvents

The maximum number of events to retrieve. Some servers impose an upper-limit on the number of events that can be retrieved in a query. When this parameter is not specified, the server will return all events, up to a server imposed limit, that match the request's criteria.  Note - the default for both queries and subscriptions is 20.  This can easily be adjusted:

	$sdee->maxNbrOfEvents(100);	# limit to 100
	$sdee->maxNbrOfEvents(undef);	# unlimited or limited by the server, this could be dangerous!

=item confirm

Acknowledge that the events retrieved in the previous get() were received.  The default is to confirm.

=item idsAlertSeverities

Set the alert severities of events to retrieve.  Valid alert severities are: informational, low, medium, and high.  Multiple alert severities may be specified:

        $sdee->idsAlertSeverities( 'medium', 'high');

Default is ALL IDS alert severities.

=item errorSeverities

Set the error severities of events to retrieve.  Valid error severities are: warning, error, and fatal.  Multiple error severities may be specified:

        $sdee->errorSeverities( 'fatal', 'error');

Default is ALL error severities.

=item events

Specify the type of events to retrieve.  Currently, only IDS events are supported:
	evIdsError, evIdsAlert, evIdsStatus, evIdsLogTransaction, evIdsShunRqst

The default is evIdsAlert messages only.

=head1 CALLBACK METHODS

There are several ways to control the behavior of the SDEE object, depending on what you want to do with it.  To control this behavior, you have the ability to control how the error/response messages are handled, how the events are returned/processed, and how the SOAP document is processed.  This module comes with the basic functionality for all three, but you may choose to include your own for your own purposes.

=item debug

Setting this will turn on debugging.  There is internal debugging messages that will be reported if this flag is set.  This does not affect the reporting of response messages.

=item debug_callback

By default, the reponse messages and SDEE object messages are handled by an internal routine that merely prints them and their calling method.  This method can be used to redefine that internal routine to another one:
Events
	$sdee->debug_callback(\$local_debug);

This routine should expect to receive a single argument being an error message.

=item callback

The callback method sets the routine that will handle the returned results from the get().  The callback method received two paramters.  The second is the subscriptionID that the request came from.  The first depends on the return setting set (see returnEvents, returnXML, and returnRawXML).

If no callback routine is set, the particular portion and format of the document is returned.  Here are some examples:

	my $sdee = Net::SDEE->new( returnEvents => 1, callback => \&eventProcessor );

	$sdee->returnXML(1);
	$sdee->callback(\&xmlProcessor);

=item returnEvents

If this is set, the SDEE object will execute the callback routine for EACH event.  If no callback routine is set, then a structure containing all the events will be returned from the get().  Also, any response messages will be sent to the debug_callback function.

=item returnXML

If this is set, then the callback routine (or return value of get()) is the entire XML document returned from the response processed by XML::Simple's XMLin() function.  Also, any response messages will be sent to the debug_callback function.

=item returnRawXML

If this is set, then the callback routine (or return value of get()) is the entire, raw, unprocessed XML document.  Also, NO response messages will be sent to the debug_callback function.  You should use this if you want to handle ALL processing of the return document yourself.

=head1 SUBSCRIPTION METHODS

Since an SDEE object may have multiple subscriptions, there are a few methods provided to assist in controlling the subscriptions.  However, if you are intending to make use the above callback routeins, getAll() and closeAll(), you will probably not need to use any of these methods.

=item getNumberOfSubscriptions

Returns the number of defined and valid subscriptions.

=item getSubscriptionIds

Returns a reference to a list of defined and valid subscription IDs.

foreach my $subscriptionId ( @{ $sdee->getSubscriptionIds } ) { $sdee->get($subscriptionId); }

=item getSubscription

Takes a subscription ID as a parameter and retrieves the subscription object.  Note, this does not remove it from the list, only returns are a reference to the object.

=item addSubscriptions

Takes a subscription object as a parameter.  If no subscription object is provided, a new one is instantiated with the default parameters.  Additionally, the subscription object is registered with the server.

=item deleteSubscriptions

Takes as a parameter, a subscription ID.  This subscription is removed from the list of valid subscriptions.  Note - this subscription is NOT closed, so, if you're using this method, be sure to call 'close($subscriptionId)' first.

=head1 EXAMPLE

Here's a simple way to setup an SDEE subscription and begin processing events

	sub eventCallback { my ($event, $subscriptionID) = @_; ... }
	sub errorCallback { my $message = shift; ... }

        $sdee = Net::SDEE->new(
                returnEvents => 1,
                debug => 1,
                callback => \&eventCallback,
                debug_callback => \&errorCallback
        );

        $sdee->Username($user);
        $sdee->Password($pass);
        $sdee->Server($host);
        $sdee->open(); # establish a subscription with the defaults

        # callback subs are called for each event
        for(;;) { $sdee->get(); } # probably want to sleep or something inbetween


=head1 TODO

This implementation currently supports IDS messages, as described in the SDEE specification.  However, it is not possible to add additional message types at this point.  Furthermore, detection of and reporting of missed events is not currently incorporated into this version.

The main reason for these limitations is my inability to test either of these.  This module was tested with a beta version of Cisco's CIPS 5.0, which I did not control.  I would be interested in hearing about other systems that support SDEE and would be happy to work on finishing these two options if someone could provide a system to test against.

=head1 AUTHOR

Joe Minieri, E<lt>jminieri@mindspring.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Joe Minieri and OpenService (www.open.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

