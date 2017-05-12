#
# $Id: Info.pm,v 0.1 2001/04/25 10:41:49 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Info.pm,v $
# Revision 0.1  2001/04/25 10:41:49  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Pod::PP::State::Info;

require Exporter;

use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);

use Carp::Datum;
use Log::Agent;

use constant POD_PP_STATE_OK	=> 0;	# Can read and process line
use constant POD_PP_STATE_ENDIF	=> 1;	# Skip until endif
use constant POD_PP_STATE_ALT	=> 2;	# Skip until alternate cond. or endif

@EXPORT = qw(
	POD_PP_STATE_OK
	POD_PP_STATE_ENDIF
	POD_PP_STATE_ALT
);

#
# ->make
#
# Creation routine
#
sub make {
	DFEATURE my $f_;
	my $self = bless {}, shift;
	my ($cmd, $state, $podinfo) = @_;

	$self->replace($cmd, $state, $podinfo);

	return DVAL $self;
}

#
# ->replace
#
# Replace attributes.
#
sub replace {
	DFEATURE my $f_;
	my $self = shift;
	my ($cmd, $state, $podinfo) = @_;

	$self->{cmd}     = $cmd;
	$self->{state}   = $state;
	$self->{podinfo} = $podinfo;

	return DVOID;
}

#
# Attribute access
#

sub cmd		{ $_[0]->{cmd} }
sub state	{ $_[0]->{state} }
sub podinfo	{ $_[0]->{podinfo} }

1;

