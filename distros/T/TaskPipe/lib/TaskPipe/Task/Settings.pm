package TaskPipe::Task::Settings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::Task::Settings - Settings for L<TaskPipe::Task>

=head1 OPTIONS

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


=item cache_results

Cache xtask results. This prevents the same xtask (ie the same task with the same C<pinterp> being executed again (the results will just be piped to the next task without the task being executed).

=cut

has cache_results => (is => 'ro', isa => 'Bool', default => 0);



=item test_result_limit

The maximum number of results to output when testing a task

=cut

has test_result_limit => (is => 'ro', isa => 'Int', default => 10);




=item seen_xbranch_policy

Whether to remember xbranches that have been completed or not. TaskPipe can C<skip> seen xbranches (ie prevent them from being executed more than once) or C<delete> them (if they are not expected to be seen more than once, this option keeps the database trim)

=cut

has seen_xbranch_policy => (is => 'ro', isa => 'Str', default => 'delete');



=item xbranch_key_mode

Choose 'md5' to have taskpipe create xbranch identifiers using md5 hashes. Choose 'id' to use raw id values (less flexible, but also less CPU intensive)

=cut

has xbranch_key_mode => (is => 'ro', isa => 'Str', default => 'md5');



=item resume_record_interval

The number of records to process between recording resume information. For example C<resume_record_interval=1> would mean recording resume information every time a new record is processed. If C<resume_record_interval=100>, 100 records would be processed between recording resume information. This hits the database a lot less, but means after premature termination, the next run may repeat processing for up to 100 records

=cut

has resume_record_interval => (is => 'ro', isa => 'Int', default => '100');



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
