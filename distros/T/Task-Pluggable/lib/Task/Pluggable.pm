package Task::Pluggable;
use warnings;
use strict;
use base qw(Class::Data::Inheritable Class::Accessor);
use Task::Pluggable::CommandLineTaskManager;
__PACKAGE__->mk_classdata('task_manager');

=head1 NAME

Task::Pluggable - Pluggable task module

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Create new task directory

for example

	mkdir task_dir
	cd task_dir
	perl -MTask::Pluggable -e "Task::Pluggable::create"
	./bin/ptm 

=head1 FUNCTIONS

=head2 new

create instanse 
	

=cut

sub new{
	my $class = shift;
	my $application_name  = shift;
	my $self = $class->SUPER::new();
	return $self;
}

=head2 create
	
create task directory and task script

=cut
sub create {
	my $self  = shift;
	my $command_line = Task::Pluggable::CommandLineTaskManager->new();
	$command_line->task_name('create_task_env');
	$command_line->do_task();
}


=head2 run

run task 
	./bin/ptm <task_name>

internel code is 

	$task = new Task::Pluggable();
	$task->run(Task::Pluggable::CommandLineTaskManager);

=cut
sub run{
	my $self = shift;
	my $manager = shift;
	$self->task_manager($manager);
	$self->task_manager->load_args();
	$self->task_manager->do_task();
}


=head1 AUTHOR

Masafumi Yoshida, C<< <masafumi.yoshida820 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-task-pluggable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Task-Pluggable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Task::Pluggable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Task-Pluggable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Task-Pluggable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Task-Pluggable>

=item * Search CPAN

L<http://search.cpan.org/dist/Task-Pluggable/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Masafumi Yoshida, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Task::Pluggable
