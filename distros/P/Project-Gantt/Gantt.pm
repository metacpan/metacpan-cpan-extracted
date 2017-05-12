##########################################################################
#
#	File:	Project/Gantt.pm
#
#	Author:	Alexander Westholm
#
#	Purpose: This object represents a Project within this Gantt chart
#		module. It can also recursively represent a sub-project.
#		It provides methods for drawing the chart. This is also
#		the location of the User Documentation.
#
#	Client:	CPAN
#
#	CVS: $Id: Gantt.pm,v 1.15 2004/08/03 17:58:12 awestholm Exp $
#
##########################################################################
=head1 NAME

Project::Gantt - Create Gantt charts to manage project scheduling

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 # a fun, imaginary wednesday
 use strict;
 use Project::Gantt;
 use Project::Gantt::Skin;
 
 my $skin= new Project::Gantt::Skin(
 	doTitle		=>	0);
 
 my $day = new Project::Gantt(
 	file		=>	'hourly.png',
 	skin		=>	$skin,
 	mode		=>	'hours',
 	description	=>	'A day in the life');
 
 my $al	= $day->addResource(
 	name		=>	'Alex');	
 
 $day->addTask(
 	description	=>	'Finish sleep',
 	resource	=>	$al,
 	start		=>	'2004-07-21 00:00:00',
 	end		=>	'2004-07-21 08:30:00');
 
 $day->addTask(
 	description	=>	'Breakfast/Wakeup',
 	resource	=>	$al,
 	start		=>	'2004-07-21 08:30:00',
 	end		=>	'2004-07-21 10:00:00');
 
 my $sub = $day->addSubProject(
 	description	=>	'Important Stuff');
 $sub->addTask(
 	description	=>	'Contemplate my navel',
 	resource	=>	$al,
 	start		=>	'2004-07-21 10:00:00',
 	end		=>	'2004-07-21 11:00:00');
 
 $day->addTask(
 	description	=>	'Lunch',
 	resource	=>	$al,
 	start		=>	'2004-07-21 11:00:00',
 	end		=>	'2004-07-21 12:30:00');
 $sub->addTask(
 	description	=>	'Wonder about life',
 	resource	=>	$al,
 	start		=>	'2004-07-21 11:00:00',
 	end		=>	'2004-07-21 11:22:00');
 
 $day->addTask(
 	description	=>	'Code for a while',
 	resource	=>	$al,
 	start		=>	'2004-07-21 12:30:00',
 	end		=>	'2004-07-21 17:00:00');
 
 $day->addTask(
 	description	=>	'Sail',
 	resource	=>	$al,
 	start		=>	'2004-07-21 17:00:00',
 	end		=>	'2004-07-21 20:30:00');
 $day->display();

=head1 DESCRIPTION

B<Project::Gantt> provides the ability to easily draw Gantt charts for managing the schedules of projects and many other things. Gantt charts provide a simple, easy to comprehend visual representation of a schedule.

The code above creates a simple chart to display the hour-by-hour breakdown of a sample day. Notice the B<Project::Gantt::Skin> object in use. This allows the look and feel of a Gantt chart to be customized. Also note that tasks are divided into two main categories: those that fall directly under the project, and those which are members of the subproject B<"Important Stuff">. Note also that the chart itself will be written to a file in the current working directory called B<"hourly.png">. This filename attribute may be set to something such as B<"png:-"> to send output directly to B<STDOUT>.

As can be seen from the example, the methods that will be called by a user of this module include: I<addResource>,I<addTask>, I<addSubProject>, and I<display>. The names of these methods suggest their purpose, but they will be further explained.

=over

=item new()

I<new> takes the following parameters: the skin object in use (if not using the default), the filename to use when writing the chart (use B<"png:-"> to write to B<STDOUT>), an overall description for the chart, and the time mode for output. The filename and description are fairly self explanatory. The B<Project::Gantt::Skin> object will be covered later in this document. The time mode selects which unit of time to use when displaying the chart. This unit can be one of the following: B<hours>, B<days>, and B<months>. Note that when using the months mode, small overflows of pixels may be present (i.e., one pixel more than should be). Normally these are not noticeable. They are a result of the calculation used to determine how many pixels a timespan should fill when using month more. This is because of the discrepancies between days in various months. If swim lanes are not in use (see the section on B<Project::Gantt::Skin>), these errors are unnoticeable.

=item addResource()

I<addResource> really only requires a B<name> parameter at this point. The method will accept whatever you give it, but currently only the B<name> parameter has any impact on the resulting chart.

=item addTask()

I<addTask> attaches a B<Project::Gantt::Task> object to the B<Project::Gantt> instance that called it. The calling instance may be the root project, or any subproject. The task will be anchored directly underneath it. Parameters that must be passed to this method are as follows: a description of the task, the resource assigned to its undertaking, the starting date of the task and its end date.

=item addSubProject()

I<addSubProject> returns an instance of B<Project::Gantt> anchored underneath the instance that called it. Thanks to Peter Weatherdon, you can now create nested sub-projects using this method on an existing sub-project object. This reference may then be used to call I<addTask> and create a container relationship with B<Project::Gantt::Task> objects. Currently, the only necesarry parameter is a description of the sub-project.

=item display()

Oddly enough, I<display> writes the chart to a file.

=head2 SKIN OBJECTS

B<Project::Gantt::Skin> objects allow users to customize the color scheme of a chart. The skin object is passed to B<Project::Gantt> during construction. All aspects of the skin are set during its construction as well. The following facets of the chart may be modified:

=over

=item primaryText

B<primaryText> controls the font fill color for all but the sub-project description. The default is black.

=item secondaryText

B<secondaryText> controls the font fill for sub-projects. It defaults to a grey color (#969696).

=item primaryFill

B<primaryFill> is the color that fills the information boxes for rows representing tasks. The default is a blue color (#c4dbed).

=item secondaryFill

B<secondaryFill> is the color used by sub-project rows for informational boxes, as well as the fill for the calendar header. The default is a grey color (#e5e5e5).

=item infoStroke

B<infoStroke> is the stroke color for the informational boxes. This defaults to black.

=item containerStroke

B<containerStroke> is the stroke color for sub-projects on the chart. This defaults to black.

=item containerFill

B<containerFill> is the fill color for sub-project items. This defaults to grey (as defined by B<Image::Magick>).

=item itemFill

B<itemFill> is the fill color for task items on the chart. This defaults to blue. Note that there is no stroke color for tasks (it is set to the fill).

=item background

B<background> is quite obviously the background color. This defaults to white.

=item font

B<font> is the name of the font file as it is passed to B<Image::Magick>. See the docs for that module for more information. The default value for this property is determined by searching @INC for the directory of your Project::Gantt installation, and is set to the copy of Bitstream Vera included in the distribution.

=item doTitle

B<doTitle> is a boolean that determines whether the title of the chart is drawn on it.

=item doSwimLanes

B<doSwimLanes> is a boolean that determines whether lines should be drawn seperating each time interval from the header to the end of the graph. This makes it easy to see the exact values.

=back

=head1 AUTHOR

Alexander Christian Westholm, E<lt>awestholm AT verizon.netE<gt>

=head1 CHANGES

August, 2004: Original Version

January 2005: Modifications made by Peter Weatherdon (peter.weatherdon AT us.cd-adapco.com), including various bug fixes, and nested sub-projects.

=head1 SEE ALSO

L<Image::Magick>, L<Class::Date>

=head1 COPYRIGHT

Copyright 2005, Alexander Christian Westholm.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
 
package Project::Gantt;
use strict;
use warnings;
use Project::Gantt::Resource;
use Project::Gantt::Task;
use Project::Gantt::ImageWriter;
use Project::Gantt::DateUtils qw[:compare];
use Project::Gantt::Skin;

our $VERSION = '1.01';

#params:
#name
sub new {
	my $class	= shift;
	my %args	= @_;
	if(not $args{description}){
		die "Must provide description of project!";
	}
	if(not $args{file} and not $args{parent}){
		die "Must provide filename for output!";
	}
	$args{mode}	= 'days' if not $args{mode};
	$args{tasks}	= [];
	$args{subprojs}	= [];
	$args{resources}= {};
	$args{parent}	= 0 if not defined $args{parent};
	$args{subNodes}	= 0;
	# startDate must be now because comparison against
	# a value that's better will cause handleDates to
	# still get called, resetting the startDate to 0, if
	# startDate is allowed to stay 0
	$args{startDate}= -1;
	$args{endDate}	= 0;
	$args{skin}	= $args{skin} || new Project::Gantt::Skin();
	my $me = bless \%args, $class;
	return $me;
}

sub addResource {
	my $me	= shift;
	my %opts= @_;
	my $res	= new Project::Gantt::Resource(%opts);
	$me->{resources}->{$opts{name}} = $res;
	return $res;
}

sub addTask {
	my $me	= shift;
	my %opts= @_;
	die "Must provide resource for task!" if not $opts{resource};
	die "Must provide start date for task!" if not $opts{start};
	die "Must provide end date for task!" if not $opts{end};
	if(not $me->{parent}){
		if(not $me->{resources}->{$opts{resource}->getName()}){
			die "Mis-assignment of task resources!!";
		}
	}else{
		if(not $me->{parent}->{resources}->{
			$opts{resource}->getName()}){

			#die "Mis-assignment of task resources!";
		}
	}
	$opts{start}	.= " 09:00:00" if $opts{start} !~ /\:/;
	$opts{end}	.= " 17:00:00" if $opts{end} !~ /\:/;
	# handle addition to sub-project
	my $tsk = new Project::Gantt::Task(%opts);
	$tsk->setParent($me);
	$tsk->addResource($opts{resource});
	$tsk->_handleDates();
	push @{$me->{tasks}}, $tsk;
	$me->incrNodeCount();
}

# allow resource to be assignmed for every sub-task
sub addSubProject {
	my $me	= shift;
	my %opts= @_;
	$opts{parent} = $me;
	my $prj	= new Project::Gantt(%opts);
	push @{$me->{subprojs}}, $prj;
	$me->incrNodeCount();
	return $prj;
}

sub display {
	my $me	= shift;
	if($me->{parent}){
		die "Must not call display on sub-project!";
	}
	my $wtr = new Project::Gantt::ImageWriter(
		root	=>	$me,
		skin	=>	$me->{skin},
		mode	=>	$me->{mode});
	$wtr->display($me->{file});
}

sub _display {
	my $me		= shift;
	my $start	= $me->{startDate};
	my $end		= $me->{endDate};
	if($me->{parent}){
		# print container bar
		print "SUBPROJECT: $me->{description}\n";
	}else{
		# print header
		print "MASTER PROJECT: $me->{description}\n";
	}
	print "RUNS FROM: $start to $end\n";

	for my $tsk (@{$me->{tasks}}){
		print "TASK: ".$tsk->getDescription()."\n";
		print "TASK START: ".$tsk->getStartDate()."\n";
		print "TASK END: ".$tsk->getEndDate()."\n";
	}

	for my $sub (@{$me->{subprojs}}){
		$sub->display();
	}
}

sub getResources { 0 }

sub getTasks {
	my $me	= shift;
	return @{$me->{tasks}};
}

sub getSubProjs {
	my $me	= shift;
	return @{$me->{subprojs}};
}

sub _handleDates {
	my $me	= shift;
	my $prnt= $me->{parent};
	return if not $prnt;
	my $oStrt	= $prnt->getStartDate() || -1;
	my $oEnd	= $prnt->getEndDate() || 0;
	if(($oStrt > $me->{startDate}) or ($oStrt == -1)){
		$prnt->getStartDate($me->{startDate});
	}

    # Peter Weatherdon Jan 25, 2005 
    # Added check for $oEnd == 0
    if(($oEnd < $me->{endDate}) or ($oEnd == 0)){ 
		$prnt->getEndDate($me->{endDate});
	}

    # Peter Weatherdon: Jan 19, 2005
    # Recursively call handleDates to support nested sub-projects
    $prnt->_handleDates();  
}

sub setParent {
	my $me	= shift;
	$me->{parent} = shift;
}

sub getNodeCount {
	my $me	= shift;
	return $me->{subNodes};
}

sub incrNodeCount {
	my $me	= shift;
	if(not $me->{parent}){
		$me->{subNodes}++;
	}else{
		$me->{parent}->incrNodeCount();
	}
}

sub getStartDate {
	my $me	= shift;
	my $val	= shift;
	$me->{startDate} = $val if defined $val;
	return $me->{startDate};
}

sub getEndDate {
	my $me	= shift;
	my $val	= shift;
	$me->{endDate} = $val if defined $val;
	return $me->{endDate};
}

sub getDescription {
	my $me	= shift;
	return $me->{description};
}

sub timeSpan {
	my $me	= shift;
	my $span= $me->{mode};
	my $copyEnd	= $me->{endDate}->clone();
	my $copyStr	= $me->{startDate}->clone();
	if($span eq 'days'){
		return daysBetween($copyStr, $copyEnd);
	}elsif($span eq 'months'){
		return monthsBetween($copyStr, $copyEnd);
	}elsif($span eq 'hours'){
		return hoursBetween($copyStr, $copyEnd);
	}else{
		die 'Bad argument to timeSpan!';
	}
}

1;
