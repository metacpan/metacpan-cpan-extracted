package TaskPipe::Tool::Command_TestTask;

use Moose;
use MooseX::ClassAttribute;
use TaskPipe::Task::ModuleMap;
use TaskPipe::SchemaManager;
use Module::Runtime 'require_module';
extends 'TaskPipe::Tool::Command';
with 'MooseX::ConfigCascade';



has schema_manager => (is => 'rw', isa => 'TaskPipe::SchemaManager', lazy => 1, default => sub{ TaskPipe::SchemaManager->new( scope => 'project' ) });


class_has option_specs => (is => 'ro', isa => 'ArrayRef', default => sub{[{
    module => __PACKAGE__,
    is_config => 0
}]});


sub execute{
    my $self = shift;

    my $mod_map = TaskPipe::Task::ModuleMap->new(
        task_name => $self->name
    );

    my $mod_name = $mod_map->load_module;

    my $task = $mod_name->new(
        test_label => $self->test,
        gm => $self->job_manager->gm,
        sm => $self->schema_manager,
        job_id => $self->run_info->job_id
    );

    $task->test;
}

=head1 NAME

TaskPipe::Tool::Command_TestTask - command to test an individual TaskPipe task

=head1 PURPOSE

Test an individual task by running it against test data  

=head1 DESCRIPTION

C<test task> can be used to run test data against an individual task and check the output. This effectively enables "unit testing" of tasks to make sure they are working correctly before running them as part of a plan.

A list of test data should be supplied within the task module itself by providing a C<test_pinterp> subroutine. 

=head2 What is C<pinterp> ?

There are 3 words that are important when discussing the data going into a task. Those words are:

=over

=item 1. input(s)

The inputs are the raw data which the task is provided with. When running a plan, this is the data which is provided by the previous task. To give an example, let's say a previous task provides our task C<Scrape_Example> with this set of data:

    {
        url => 'http://www.example.com/some-list',
        headers => {
            Referer => 'http://www.example.com'
        },
        date => '2018-17-10'
    }

This data is the C<input> or C<inputs>.

=item 2. parameters (or C<params>):

You specify parameters in your plan. For example:

    task:
        _name: Scrape_Example
        url: $this
        headers:
            Referer: $this

This part of the task specification are the parameters:

        url: $this
        headers:
            Referer: $this

The parameters tell TaskPipe I<which part> of the input data to accept and use.

=item 3. "Interpolated parameters" or C<pinterp>

The parameters are interpolated using the input data. The result is the C<pinterp>.

The combination of the parameters and the input data results in the following data being accepted and used in the task:

    url => 'http://www.example.com/some-list'
    headers => {
        Referer => 'http://www.example.com'
    }

These are the C<pinterp>. Note that in the original set of inputs there was a C<date> input. This is not included in C<pinterp> because we didn't include a C<date> parameter in the plan. So C<inputs> and C<pinterp> are different.

In fact C<inputs> and C<pinterp> can be really very different, because we can specify that we want to accept data from I<earlier> tasks (e.g. instead of accepting data from the previous task, we accept it from the task previous to the previous task (ie 2 tasks before, instead of one). Consider the following parameters:

    url: $this
    headers:
        Referer: $this[1]{url}

These parameters are telling TaskPipe to take the url from the output named C<url> of the I<previous> task, but take the C<Referer> from the output named C<url> of the task previous to the previous task (2 tasks ago). 

Specifying the C<url> and C<Referer> header like this is a common situation, because this mirrors how web pages progress when a human is clicking around in a web browser: the C<Referer> is always the previous url to the one you are visiting.

=back

=head2 Including test data in your Task module

When testing tasks, we cut to the data that the task is actually accepting - so that means supplying the pinterp directly. Making sure the C<inputs> are correct is a job to consider when we are putting the plan together as a whole.

To give an example of how testing works, let's say our scraping task C<TaskPipe::Task_Scrape_Example> has a C<test_pinterp> subroutine which looks like

 sub test_pinterp{[{
    url => 'http://www.example.com/list-something',
    headers => {
        Referer => 'http://www.example.com'
    }
 }]}

so this subroutine returns a list containing one item of test data - the hashref

    {
        url => 'http://www.example.com/list-something',
        headers => {
            Referer => 'http://www.example.com'
        }
    }

Let's say our scraping task is in the module C<TaskPipe::Task_Scrape_Example>. That means the name of the task is C<Scrape_Example>. To test our task we would type

    taskpipe test task --name=Scrape_Example --test=0

The C<--test=0> parameter tells TaskPipe to use the first item in the C<test_pinterp> list to run the task over.

If you prefer to name your test data, you can write your C<test_pinterp> subroutine so it returns a hashref:

 sub test_pinterp{{

    mytest => {
        url => 'http://www.example.com/list-something',
        headers => {
            Referer => 'http://www.example.com'
        }
    }
 }}

In this example we have one test set of test data named C<mytest> and we can test the task against this data using:

    taskpipe test task --test=mydata

=head2 Test output

The results of the test are normally output to a file in your log directory. The filename will be a concatenation of (C<file_prefix> + the task name + the date and time + the C<file_suffix>) where C<file_prefix> and C<file_suffix> come from the project config settings in the C<TaskPipe::Task::TestSettings> section. C<test task> should print the filename it produced to the terminal when you execute the command.

You can also set C<output> in C<TaskPipe::Task::TestSettings> to C<screen> to echo output to the screen instead of to a file (but potentially a lot of output depending on the task), or C<screen,file> for both.
    
=head1 OPTIONS

=over

=item name

The "name" of the task to test. The name of a task is found from the module name via

    TaskPipe::Task_<name>

or

    MyProject::Task_<name>

e.g. the task corresponding to module TaskPipe::Task_Record has name="Record"

=cut

has name => (is => 'rw', isa => 'Str');


=item test

The name or index of the test to run. (Specify test_pinterp as a 'HashRef[HashRef]' to use names, or 'ArrayRef[HashRef]' to use indices.

=back

=cut

has test => (is => 'rw', isa => 'Str', default => '0');

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
    
