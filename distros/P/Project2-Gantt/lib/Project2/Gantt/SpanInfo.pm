package Project2::Gantt::SpanInfo;

use Mojo::Base -base,-signatures;

use Project2::Gantt::TextUtils;

use Mojo::Log;

our $DATE = '2023-02-02'; # DATE
our $VERSION = '0.006';

has canvas => undef;
has task   => undef;
has skin   => undef;

has log    => sub { Mojo::Log->new };

use constant DESCRIPTION_SIZE => 145;

sub write($self,$height) {
	$self->_writeInfo($height);
}

sub _writeInfo($self, $height) {
	my $log      = $self->log;
	my $task	 = $self->task;
	my $bgcolor	 = $self->skin->primaryFill;
	my $fontFill = $self->skin->primaryText;
	my $canvas	 = $self->canvas;

	$bgcolor     = $self->skin->secondaryFill if $task->isa("Project2::Gantt");
	$fontFill    = $self->skin->secondaryText if $task->isa("Project2::Gantt");

	$canvas->box(
		color  => $bgcolor,
		xmin   => 0,
		ymin   => $height,
		xmax   => DESCRIPTION_SIZE,
		ymax   => $height + 17,
		filled => 1,
	);

	$canvas->box(
		color  => $bgcolor,
		xmin   => DESCRIPTION_SIZE,
		ymin   => $height,
		xmax   => 200,
		ymax   => $height + 17,
		filled => 1,
	);

	$log->debug(truncate($task->description,DESCRIPTION_SIZE));

	my $description = truncate($task->description, DESCRIPTION_SIZE);
	$log->debug("_writeInfo description=$description");
	$canvas->string(
		x      => 2,
		y      => $height + 12,
		string => $description,
		font   => $self->skin->font,
		size   => 10,
		aa     => 1,
		color  => $fontFill,
	);

	# if this is a task, write name... sub-projects aren't associated with a specific resource
	if($task->isa("Project2::Gantt::Task")){
		my $name = truncate($task->resources->[0]->name,55);
		$log->debug("_writeInfo name=$name");
		$canvas->string(
			x      => 147,
			y      => $height + 12,
			string => $name,
			font   => $self->skin->font,
			size   => 10,
			aa     => 1,
			color  => 'black',
		);
	}
}

1;
