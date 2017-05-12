package Task::Pluggable::AbstractTask;
use base qw(Class::Data::Inheritable Class::Accessor);
__PACKAGE__->mk_classdata('task_category'=>'');
__PACKAGE__->mk_classdata('task_name'=>'abstracttask');
__PACKAGE__->mk_classdata('task_manager');
__PACKAGE__->mk_classdata('task_args_description');
__PACKAGE__->mk_classdata('task_description'=>'task description');

sub loaded{
	my $self = shift;
}

sub pre_execute{
	my $self = shift;
	# implement
}

sub execute{
	my $self = shift;
	# implement
}

sub post_execute{
	my $self = shift;
	# implement
}
1;
