package Project2::Gantt::ImageWriter;

use Mojo::Base -base,-signatures;

use Imager;

use Project2::Gantt::DateUtils qw[:round];
use Project2::Gantt::Globals;
use Project2::Gantt::GanttHeader;
use Project2::Gantt::TimeSpan;
use Project2::Gantt::SpanInfo;

use Mojo::Log;

our $DATE = '2023-02-02'; # DATE
our $VERSION = '0.006';

has root   => undef;
has mode   => 'days';
has skin   => undef;
has canvas => undef;
has start  => undef;
has end    => undef;

has log    => sub { Mojo::Log->new };

use constant SPAN_INFO_WIDTH => 205;
use constant HEADER_HEIGHT   => 40;
use constant ROW_HEIGHT      => 20;

sub new {
	my $self = shift->SUPER::new(@_);
	$self->_get_canvas();
	return $self;
}

sub _get_canvas($self) {
	my $log    = $self->log;

	my $width  = SPAN_INFO_WIDTH;
	my $height = HEADER_HEIGHT;

	$log->debug("_get_canvas start=" . $self->start) if defined $self->start;
	$log->debug("_get_canvas end="   . $self->end)   if defined $self->end;

	my $node_count = $self->root->getNodeCount($self->start, $self->end);

	$log->debug("_get_canvas getNodeCount=$node_count");

	# add height for each row
	$height += ROW_HEIGHT for (1..$node_count);

	my $incr = $DAYSIZE;
	$incr = $MONTHSIZE if $self->mode eq 'months';

	# add width for each time unit
	$width += $incr for (1..$self->root->timeSpan($self->start, $self->end));

	my $canvas = Imager->new(xsize => $width, ysize => $height);
	$log->debug("Size: " . $canvas->getwidth() . "x" . $canvas->getheight());

	$canvas->box(filled => 1, color => $self->skin->background);

	$self->canvas($canvas);
}

sub write($self, $image, $start = undef, $end =  undef) {
	my $log = $self->log;
	my $header	= Project2::Gantt::GanttHeader->new(
		canvas => $self->canvas,
		skin   => $self->skin,
		root   => $self->root,
		log    => $log,
	);

	$header->write($self->mode, $start, $end);

    $self->writeBars($self->root, 40, $start, $end);

	$self->canvas->write(file => $image) or die $self->canvas->errstr;
}

sub writeBars($self, $project, $height, $start = undef, $end = undef) {
	my $log     = $self->log;
	my $stDate  = $start // $self->root->start;
    my $tasks   = $project->tasks;
    my $projs   = $project->subprojs;

	$log->debug("="x60);
	$log->debug("Project2::Gantt")       if $project->isa("Project2::Gantt");
	$log->debug("Project2::Gantt::Task") if $project->isa("Project2::Gantt::Task");
	$log->debug("writeBars height=$height");

	# write tasks before sub-projects.. adjust height as we go
	for my $task ($tasks->@*,$projs->@*){
		my $info= Project2::Gantt::SpanInfo->new(
			canvas => $self->canvas,
			skin   => $self->skin,
			task   => $task,
			log    => $log,
		);
		$info->write($height);
		my $bar	= Project2::Gantt::TimeSpan->new(
			canvas  => $self->canvas,
			skin    => $self->skin,
			task    => $task,
			rootStr => $stDate,
			log     => $log,
		);
		$bar->write($self->mode,$height, $start, $end);
		$height	+= 20;

        # if the task is a sub-project then draw recursively
		if($task->isa("Project2::Gantt")){
			$log->debug("Calling writeBars for project " . $task->description);
            $height = $self->writeBars ($task, $height, $start, $end);
		}
	}
	return $height;
}

1;
