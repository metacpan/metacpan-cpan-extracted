package Task::Pluggable::Tasks::CreateTask;
use base Task::Pluggable::AbstractTask;

__PACKAGE__->task_name('create_task');
__PACKAGE__->task_description('create task package');
__PACKAGE__->task_args_description('<task_name> <task_class_name> <task_description>');

sub execute{
	my $self = shift;
	my $manager = shift;
	$self->create_task_package($manager);
}
	
sub create_task_package{
	my $self = shift;
	my $manager = shift;
	my $perl_path = $ENV{_};
	my $pwd = $ENV{'PWD'};
	die "not task name" if($#{$manager->args} < 0);
	die "not task class name" if($#{$manager->args} < 1);
	die "not task description" if($#{$manager->args} < 2);

	my $task_name        = $manager->args->[0];
	my $task_class_name  = $manager->args->[1];
	my $task_description = $manager->args->[2];

	die "invalid task name ".$task_name if($task_name =~ /[^a-z0-9_]/);
	die "invalid task class name ". $task_class_name if($task_class_name =~ /[^a-zA-Z0-9]/);
	die "already exist task" if(exists $manager->tasks->{$task_name});
			

	my $script = 'package Tasks::'.$task_class_name.";\n";
	$script   .= 'use base Task::Pluggable::AbstractTask;'."\n";
	$script   .= '__PACKAGE__->task_name(\''.$task_name.'\');'."\n";
	$script   .= '__PACKAGE__->task_description(\''.$task_description.'\');'."\n\n";
	$script   .= '=head1 NAME'." \n\n";
	$script   .= 'Task::'.$task_class_name." - " .$task_description."\n\n";
	$script   .= <<'__END_SCRIPT__';

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 pre_execute

pre execute task

=cut

sub pre_execute{
	my $self = shift;	
	my $manager = shift;
	# pre task implement here;
}

=head2 execute

execute task

=cut

sub execute{
	my $self = shift;	
	my $manager = shift;
	# task implement here;
	print "TODO: implement task here\n";
}

=head2 post_execute

post execute task

=cut

sub post_execute{
	my $self = shift;	
	my $manager = shift;
	# post task implement here;
}


1;
__END_SCRIPT__

	my $package_path = $pwd."/lib/Tasks/".$task_class_name .'.pm';
	
	die "Already exists package: " .$package_path if(-f $package_path);
	print "Create task package\n";
	print $package_path ."\n";

	open my $fh,">".$package_path or die $!;
	flock($fh,2) or die $!;
	print $fh $script;
	close $fh;
}


1;
