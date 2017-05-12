# Net::SDEE::Common.pm
#
# $Id: Common.pm,v 1.1 2004/12/23 12:02:30 jminieri Exp $
#
# Copyright (c) 2004 Joe Minieri <jminieri@mindspring.com> and OpenService (www.open.com).
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

package Net::SDEE::Common;

use 5.006001;
use strict;
use warnings;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our $VERSION = '0.01';

my %_eventTypes = (
        'evIdsError',              1,
        'evIdsAlert',              1,
        'evIdsStatus',             1,
        'evIdsLogTransaction',     1,
        'evIdsShunRqst',           1
);

my %_idsAlertSeverities = (
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
                                                                                                                
        my $method =($AUTOLOAD =~ /.*::([_\w]+)$/)[0];
	return if $method eq 'DESTROY';
                                                                                                                
        unless(defined($method) and exists($self->{ $method })) {
                $self->error(1);
                $self->errorString("No such parameter $method");
                return undef;
        }
                                                                                                                
        # set this up for next time
        *{$AUTOLOAD} = sub {
                my ($self, $value) = @_;
                if (defined($value)) {
                        return $self->{ $method } = $value;
                } else {
                        return defined($self->{ $method })?$self->{ $method }:undef;
                }
        };
                                                                                                                
	goto &$AUTOLOAD;
}

##########################################################################################
#
# Non-generic get/set methods
#
sub errorSeverities {
	my ($self, $error) = @_;

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

sub idsAlertSeverities {
	my $self = shift;

	$self->error(undef);
	$self->errorString(undef);

	unless(defined($_[0])) {
		# if no parameter, the treat as "get" method
		return $self->{ 'idsAlertSeverities' };
	}

	my @alertseverities;
	foreach my $s ( @_ ) {
		my $severity = lc($s);
		if(exists($_idsAlertSeverities{ $severity })) {
			push(@alertseverities, $severity);
		}
	}

	if($#alertseverities > -1) {
		return $self->{ 'idsAlertSeverities' } = join('+', @alertseverities);
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

#
##########################################################################################

##########################################################################################
#
sub getParameters {
	my $self = shift;

	my %parameters;
	my @wanted_parameters;
	if($#_ > -1) {
		# requesting particular parameters
		@wanted_parameters = @_;
	} else {
		# requesting ALL parameters
		@wanted_parameters = keys %$self;
	}

	%parameters = map { $_, $self->{ $_ }} grep { $self->{ $_ } } @wanted_parameters;

	return \%parameters;
}

sub printAttributes {
	my $self = shift;

	my %parameters = map { $_, ($self->{ $_ } or 'undef') } keys %$self;

        foreach my $attr (sort keys %parameters) {
                       print "ATTRIBUTE: $attr\tVALUE: $parameters{ $attr }\n";
        }
}

#
##########################################################################################

1;
__END__
