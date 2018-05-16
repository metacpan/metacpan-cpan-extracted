package TaskPipe::Task::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::Task::Settings - Settings for L<TaskPipe::Task>

=head1 METHODS

=over

=item plan_mode

The format that taskpipe expects to find your plan in. There are 2 modes, C<tree> and C<branch>. If your tasks will always be executed in order (ie your plan is completely linear) then this is the mode to choose. This way you can write your plan thus:

    ---

    - name: Scrape_Example
      url: www.example.com

    - name: Record
      example_param: $this

C<tree> format is slightly more complex, offering the ability to execute different tasks in parallel (ie the plan can have more than one branch). In C<tree> format, tasks should be designated using the keyword C<task:> and cascaded using C<pipe_to:>. For example:

    ---
    task:
        _name: Scrape_Example
        url: www.example.com

    pipe_to:
        task:
            name: Record
            example_param: $this

An example of how to achieve branching in tree format is as follows:
   
    ---
    task:
        _name: Scrape_Example
        url: www.example.com
    
    pipe_to:

        - task:
            name: Record
            example_param: $this

        - task:
            name: Scrape_SomethingElse
            another_param: $this[1]

The tasks C<Record> and C<Scrape_SomethingElse> execute in parallel. See the general documentation for more information on plan modes and branching

=cut

has plan_mode => (is => 'ro', isa => 'Str', default => 'branch');

=item persist_xbranch_record

Once an xbranch has been 'seen' - ie all the sub-xbranches have been executed, taskpipe can clear all records of those sub-xbranches in order to keep the database trim. The upside to persisting the xbranch cache is that any (sub) xbranch can be targetted in a rerun so that only that xbranch gets executed without executing the whole plan. The downside is a substantially larger database. 

Persisting the xbranch cache may be a good idea during development when errors are expected frequently, but is probably less desirable in production with less frequent errors and a much larger amount of data.

=cut

has persist_xbranch_record => (is => 'ro', isa => 'Bool', default => 0);


=item persist_result_cache

Once an xbranch has been 'seen' without errors, taskpipe can clear all cached results associated with the xtasks that appear on the xbranch, in order to keep the database trim. The upside to persisting the result cache is that if the plan is changed, taskpipe will only execute any new or changed xtasks without needing to execute unchanged ones (since the unchanged xtasks are cached). The downside is considerable database overhead.

Like persisting the xbranch record, persisting the result cache may be a good idea during development when errors and changes are expected frequently, but is probably less desirable in production with a much larger amount of data.

=cut

has persist_result_cache => (is => 'ro', isa => 'Bool', default => 0);


=item threads

The maximum number of threads to use when running a plan. Taskpipe tries to adhere strictly to the number of threads you specify here - so parent threads are included in the value. You should experiment with your setup to determine the optimum value for your system

=cut

has threads => (is => 'ro', isa => 'Int', default => 10);


=item on_task_error

What to do if an error is encountered. Options are C<stop> (ie attempt to stop all threads), and C<continue> (which will log the error and continue)

=back

=cut

has on_task_error => (is => 'ro', isa => 'Str', default => 'stop');


=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;
