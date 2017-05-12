package Task::Pluggable::AbstractTaskManager;
use strict;
use warnings;
use Task::Pluggable::PluginManager;
use base qw(Class::Data::Inheritable Class::Accessor);
__PACKAGE__->mk_accessors(qw/config tasks args task_name/);

sub new{
	my $class = shift;
	my $config = shift;
	my $self = $class->SUPER::new();
	$self->config($config);
	$self->init();
	return $self;
}

sub init{
	my $self = shift;
	my $tasks = {};
	foreach my $task (Task::Pluggable::PluginManager->tasks()){
		die "task name repeat" if(exists $tasks->{$task->task_name});
		$task->task_manager($self);
		$tasks->{$task->task_name} = $task;	
	}
	$self->tasks($tasks);
}

sub load_args{
	my $self = shift;
	my @args = @_;
	$self->task_name(shift @args);
	$self->args(\@args);
}

sub do_task{
	my $self = shift;
	eval{
		die "task not exist" unless($self->task_name());
		die "task not exist" unless(exists $self->tasks->{$self->task_name()});
		print 'Task '.$self->task_name.'start'."\n";
		print '-----------------------------------------------------------------------'."\n";
		print 'Pre task excute'."\n";
		$self->tasks->{$self->task_name()}->pre_execute($self);	
		print 'Task excute'."\n";
		$self->tasks->{$self->task_name()}->execute($self);	
		print 'Post task excute'."\n";
		$self->tasks->{$self->task_name()}->post_execute($self);	
		print 'Task finished'."\n";
	};
	if($@){
		print '-----------------------------------------------------------------------'."\n";
		print 'Task Execute Error: '.$@;
		print '-----------------------------------------------------------------------'."\n";
		$self->help();
	}
}

sub help{
	my $self = shift;
}


1;
