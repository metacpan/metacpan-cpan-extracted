package TaskPipe::PathSettings::Project;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::PathSettings::Project - project path settings for TaskPipe

=head1 METHODS

=over

=item plan

The name of the plan to use

=cut

has plan => (is => 'rw', isa => 'Str', default => 'plan.yml');


=item task_identifier

Normally your task modules will have names in the format C<TaskPipe::Task_(task name)>. This means 'Task_' is identifying the module as a task module. In the unlikely event you need to use another identifier, you can set
C<task_identifier> to a new value.

=cut

has task_identifier => (is => 'ro', isa => 'Str', default => 'Task_');


=item task_module_prefix

Normally your task modules will have names in the format C<TaskPipe::Task_(task name)>. However, lots of modules start with C<TaskPipe>, and if you want to differentiate your project tasks from general TaskPipe tasks you can set C<task_module_prefix> to something else. For example, if you set C<task_module_prefix=MyProject>, then you would create packages with the name format C<MyProject::Task_(taskname)> instead of C<TaskPipe::Task_(taskname)> in your project C<lib> dir.

Note this does not necessarily prevent the potential for a namespace collision when running a plan. For example, if you are planning to use C<TaskPipe::Task_Record> then you should not create a C<MyProject::Task_Record> (unless you are intending to have C<MyProject::Task_Record> inherit from C<TaskPipe::Task_Record>).

=cut

has task_module_prefix => (is => 'ro', isa => 'Str', default => 'TaskPipe');



=item lib_dir

The directory inside the project root where TaskPipe will look for Task packages

=cut

has lib_dir => (is => 'ro', isa => 'Str', default => '/lib');



=item plan_dir

The directory inside the project root where TaskPipe will look for plans

=cut

has plan_dir => (is => 'rw', isa => 'Str', default => '/plans');



=item source_dir

The directory inside the project root where TaskPipe will look for files to use as data sources

=cut

has source_dir => (is => 'ro', isa => 'Str', default => '/sources');



=item log_dir

The directory inside the project root to write log files

=back

=cut

has log_dir => (is => 'ro', isa => 'Str', default => '/logs');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
__END__

