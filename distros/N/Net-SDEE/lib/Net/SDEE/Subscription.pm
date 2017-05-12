# Net::SDEE::Subscription.pm
#
# $Id: Subscription.pm,v 1.1 2004/12/23 12:02:30 jminieri Exp $
#
# Copyright (c) 2004 Joe Minieri <jminieri@mindspring.com> and OpenService (www.open.com).
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

package Net::SDEE::Subscription;

use 5.006001;
use strict;
use warnings;

require Net::SDEE::Common;
our @ISA = qw/Net::SDEE::Common/;
our $VERSION = '0.01';

##########################################################################################
#
# Non-generic get/set methods
#
sub action {
	my ($self, $action) = @_;

	unless(defined($action)) {
		# if no parameter, the treat as "get" method
		return $self->{ 'action' };
	}

	$self->error(undef);
	$self->errorString(undef);

	$action = lc($action);
	if($action eq 'open' or $action eq 'get' or $action eq 'cancel' or $action eq 'close' ) {
		return $self->{ 'action' } = $action;
	} else {
		$self->error(1);
		$self->errorString("Invalid action value: $action");
		return undef;
	}
}

sub confirm {
	my ($self, $confirm) = @_;

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

sub force {
        my ($self, $force) = @_;

        unless(defined($force)) {
                # if no parameter, the treat as "get" method
                return $self->{ 'force' };
        }

        $self->error(undef);
        $self->errorString(undef);

        $force = lc($force);
        if($force eq 'no' or $force eq 'yes') {
                return $self->{ 'force' } = $force;
        } else {
                $self->error(1);
                $self->errorString("Invalid force value: $force");
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
		'state',			'closed',
		'action',			'close',
		# subscription parameters
		'subscriptionId',		undef,
		# retrieval parameters
		'sessionId',                    undef,
		'startTime',                    undef,
		'events',                       'evIdsAlert',
		'idsAlertSeverities',           undef,
		'errorSeverities',              undef,
		'timeout',                      1,
		'maxNbrOfEvents',               20,     # set this just so we don't crush the box
		'confirm',                      'yes',
		'force',                        'yes',
		# results
		'missedEvents', undef,
		'error',        undef,
		'errorString',  undef
	}, $class;


	foreach my $attribute ( keys %attr ) {
		$self->$attribute( $attr{ $attribute });
	}

        #if(defined($self->{debug})) { $DEBUG_FLAG = 1; }

	$self->state('closed');
	$self->missedEvents(undef);
	$self->error(undef);
	$self->errorString(undef);

        return $self;
}

#
##########################################################################################

1;
__END__
