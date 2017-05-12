#
# $Id: State.pm,v 0.1 2001/04/25 10:41:48 ram Exp $
#
#  Copyright (c) 2000-2001, Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: State.pm,v $
# Revision 0.1  2001/04/25 10:41:48  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package Pod::PP::State;

use Carp::Datum;
use Log::Agent;

use Pod::PP::State::Info;

#
# ->make
#
# Creation routine
#
sub make {
	DFEATURE my $f_;
	my $self = bless [], shift;
	return DVAL $self;
}

#
# ->push
#
# Add nested branch.
#
sub push {
	DFEATURE my $f_;
	my $self = shift;
	my ($cmd, $state, $podinfo) = @_;

	my $sinfo = Pod::PP::State::Info->make($cmd, $state, $podinfo);
	push(@$self, $sinfo);

	return DVOID;
}

#
# ->pop
#
# Leaving nested branch.
#
sub pop {
	DFEATURE my $f_;
	my $self = shift;
	my ($podinfo) = @_;

	unless (@$self) {
		my ($file, $line) = $podinfo->file_line();
		logwarn "improper Pod::PP 'endif' ('if' missing?) at \"%s\", line %d",
			$file, $line;
		return DVOID;
	}

	pop @$self;
	return DVOID;
}

#
# ->state
#
# Return current state
#
sub state {
	DFEATURE my $f_;
	my $self = shift;

	return DVAL POD_PP_STATE_OK unless @$self;
	return DVAL $self->[-1]->state;		# State of latest item
}

#
# ->replace
#
# Return state of topmost element.
#
sub replace {
	DFEATURE my $f_;
	my $self = shift;
	my ($cmd, $state, $podinfo) = @_;

	unless (@$self) {
		my ($file, $line) = $podinfo->file_line();
		logwarn "improper Pod::PP '%s' ('if' missing?) at \"%s\", line %d",
			$cmd, $file, $line;
		return DVOID;
	}

	$self->[-1]->replace($cmd, $state, $podinfo);

	return DVOID;
}

#
# ->pending
#
# Returns ($cmd, $podinfo) of last branch taken.
# Returns () when stack is empty, indicating no pending branch.
#
sub pending {
	DFEATURE my $f_;
	my $self = shift;

	return DARY () unless @$self;

	my $top = $self->[-1];
	return DARY ($top->cmd, $top->podinfo);
}

#
# ->reset
#
# Empty stack, warning them if there are pending branches.
#
sub reset {
	DFEATURE my $f_;
	my $self = shift;

	my ($cmd, $podinfo) = $self->pending;
	if (defined $cmd) {
		my ($file, $line) = $podinfo->file_line;
		logwarn "unclosed Pod::PP '%s' directive (started at \"%s\", line %d)",
			$cmd, $file, $line;
	}

	@$self = ();

	return DVOID;
}

1;

