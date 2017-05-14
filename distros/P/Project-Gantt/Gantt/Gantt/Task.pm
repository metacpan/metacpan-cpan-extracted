##########################################################################
#
#	File:	Project/Gantt/Task.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: The Task class is the data representation of a task
#		within a Gantt chart. It communicates date information
#		up to its containing class, allowing the root object to
#		know the start and end dates of the chart.
#
#	Client:	CPAN
#
#	CVS: $Id: Task.pm,v 1.6 2004/08/03 06:08:24 awestholm Exp $
#
##########################################################################
package Project::Gantt::Task;
use strict;
use warnings;
use Class::Date;

##########################################################################
#
#	Method:	new(%opts)
#
#	Purpose: Constructor. Takes as parameters the description of a
#		task, its starting date, ending date, and a list of
#		resources associated with its undertaking.
#
##########################################################################
sub new {
	my $class	= shift;
	my %opts	= @_;
	if(not $opts{description}){
		die "Task must have description!";
	}
	if(not($opts{start} and $opts{end})){
		die "Must provide task dates!";
	}
	$opts{startDate}= _makeDate($opts{start});
	$opts{endDate}	= _makeDate($opts{end});
	my $me = bless \%opts, $class;
	return $me;
}

##########################################################################
#
#	Function: _makeDate(dateString)
#
#	Purpose: Appends hour/minute/second information (all zeroed) to
#		a Class::Date string that does not have it, and returns
#		the created Class::Date object.
#
#	NOTE:	Perhaps this should be moved to TextUtils?
#
##########################################################################
sub _makeDate {
	my $dateStr	= shift;
	my $add		= "";
	$add =	" 00:00:00" if($dateStr !~ /\:/);
	return new Class::Date($dateStr.$add);
}

sub setParent {
	my $me	= shift;
	$me->{parent} = shift;
}

sub addResource {
	my $me	= shift;
	my $res	= shift;
	push @{$me->{resources}}, $res;
}

sub getResources {
	my $me	= shift;
	return $me->{resources};
}

sub getStartDate {
	my $me	= shift;
	return $me->{startDate};
}

sub getEndDate {
	my $me	= shift;
	return $me->{endDate};
}

sub getDescription {
	my $me	= shift;
	return $me->{description};
}

##########################################################################
#
#	Method:	_handleDates()
#
#	Purpose: Checks to see whether this object's starting date is
#		before its parent's, and if so, resets the parent date.
#		Does similar for end date.
#
##########################################################################
sub _handleDates {
	my $me	= shift;
	my $prnt= $me->{parent};
	my $oStrt	= $prnt->getStartDate() || -1;
	my $oEnd	= $prnt->getEndDate() || 0;
	if(($oStrt > $me->{startDate}) or ($oStrt == -1)){
		$prnt->getStartDate($me->{startDate});
	}

    # Peter Weatherdon added check for $oEnd == 0
	if(($oEnd < $me->{endDate}) or ($oEnd == 0)) {
		$prnt->getEndDate($me->{endDate});
	}
	$prnt->_handleDates();
}

1;
