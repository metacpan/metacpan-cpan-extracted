# Net::SDEE::Query.pm
#
# $Id: Query.pm,v 1.1 2004/12/23 12:02:30 jminieri Exp $
#
# Copyright (c) 2004 Joe Minieri <jminieri@mindspring.com> and OpenService (www.open.com).
# All rights reserved.
# This program is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
#

package Net::SDEE::Query;

use 5.006001;
use strict;
use warnings;

require Net::SDEE::Common;
our @ISA = qw/ Net::SDEE::Common /;
our $VERSION = '0.01';

##########################################################################################
#
# Non-generic get/set methods
#

##########################################################################################
#
sub new {
        my $caller = shift;
        my %attr = @_;

	my $class = (ref($caller) or $caller);
        my $self = bless {
		# retrieval parameters
		'startTime',                    undef,
		'stopTime',                     undef,  # only for queries
		'events',                       'evIdsAlert',
		'idsAlertSeverities',           undef,
		'errorSeverities',              undef,
		'maxNbrOfEvents',               20,     # set this just so we don't crush the box
		# results
		'error',        undef,
		'errorString',  undef
	}, $class;


	foreach my $attribute ( keys %attr ) {
		$self->$attribute( $attr{ $attribute });
	}

        #if(defined($self->{debug})) { $DEBUG_FLAG = 1; }

	$self->error(undef);
	$self->errorString(undef);

        return $self;

}

#
##########################################################################################

1;
__END__
