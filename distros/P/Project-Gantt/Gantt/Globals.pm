##########################################################################
#
#	File:	Project/Gantt/Globals.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: A collection of globals used through the Gantt chart
#		module. Currently only has pixel sizes for days/hours
#		and months.
#
##########################################################################
package Project::Gantt::Globals;
use strict;
use warnings;
use Exporter ();
use vars qw[$DAYSIZE $MONTHSIZE @ISA @EXPORT];

@ISA		= qw[Exporter];

$DAYSIZE	= 15;
$MONTHSIZE	= 60;

@EXPORT		= qw[$DAYSIZE $MONTHSIZE];

1;
