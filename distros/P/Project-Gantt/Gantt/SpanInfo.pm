##########################################################################
#
#	File:	Project/Gantt/SpanInfo.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: This class visually presents data about a given span.
#		It lists the span's description and resource, in a box
#		whose color varies based on whether the task is a
#		container or task.
#
#	Client: CPAN
#
#	CVS: $Id: SpanInfo.pm,v 1.4 2004/08/03 17:56:52 awestholm Exp $
#
##########################################################################
package Project::Gantt::SpanInfo;
use strict;
use warnings;
use Project::Gantt::TextUtils;

##########################################################################
#
#	Method:	new(%opts)
#
#	Purpose: Constructor. Takes as parameters the canvas, skin and
#		task object it will describe.
#
##########################################################################
sub new {
	my $cls	= shift;
	my %ops	= @_;
	die "Improper args to SpanInfo!" if(not($ops{canvas} and $ops{task}));
	return bless {
		canvas	=>	$ops{canvas},
		skin	=>	$ops{skin},
		task	=>	$ops{task},
	}, $cls;
}

##########################################################################
#
#	Method: display(height)
#
#	Purpose: Functions as a placeholder to call _writeInfo. Exists
#		incase a preprocessing need arises later.
#
##########################################################################
sub display {
	my $me	= shift;
	my $hgt	= shift;
	$me->_writeInfo($hgt);
}

##########################################################################
#
#	Method:	_writeInfo(height)
#
#	Purpose: Writes information for the task associated with this
#		object onto the canvas. Creates a box for description
#		and another for resource. Background color of these
#		boxes depends on whether the task is a Project::Gantt
#		instance or a Project::Gantt::Task instance.
#
##########################################################################
sub _writeInfo {
	my $me		= shift;
	my $height	= shift;
	my $tsk		= $me->{task};
	my $bgcolor	= $me->{skin}->primaryFill();
	my $fontFill	= $me->{skin}->primaryText();
	my $canvas	= $me->{canvas};
	$bgcolor = $me->{skin}->secondaryFill() if $tsk->isa("Project::Gantt");
	$fontFill = $me->{skin}->secondaryText() if $tsk->isa("Project::Gantt");
	# rectangle for description
	$canvas->Draw(
		stroke		=>	$me->{skin}->infoStroke(),
		fill		=>	$bgcolor,
		primitive	=>	'rectangle',
		points		=>	"0, $height 145, ".($height+17));
	# rectangle for name
	$canvas->Draw(
		stroke		=>	$me->{skin}->infoStroke(),
		fill		=>	$bgcolor,
		primitive	=>	'rectangle',
		points		=>	"145, $height 200, ".($height+17));
	# write description
	$canvas->Annotate(
		text		=>	truncateStr(
			$tsk->getDescription(),
			145),
		font		=>	$me->{skin}->font(),
		fill		=>	$fontFill,
		pointsize	=>	10,
		x		=>	2,
		y		=>	$height+12);
	# if this is a task, write name... sub-projects aren't associated with
	# a specific resource
	if($tsk->isa("Project::Gantt::Task")){
		$canvas->Annotate(
			text		=>	truncateStr(
				$tsk->getResources()->[0]->getName(),
				55),
			font		=>	$me->{skin}->font(),
			fill		=>	$fontFill,
			pointsize	=>	10,
			x		=>	147,
			y		=>	$height+12);
	}
}

1;
