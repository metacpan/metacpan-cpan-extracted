package Schedule::Pluggable;

use Moose;
use Carp qw/ croak /;
use Try::Tiny;

our $VERSION = '0.0.7';
with 'MooseX::Workers';
with 'MooseX::Object::Pluggable';

with 'Schedule::Pluggable::Config';
with 'Schedule::Pluggable::Run';
with 'Schedule::Pluggable::EventHandler';
with 'Schedule::Pluggable::Status';

our %imports = ();  # Anything supplied in the use statement goes in here e.g. use Schedule::Pluggable (something => value);

# merge anything specied in %imports with any parameters passed on object creation
sub BUILDARGS {
   my $class = shift;

   my %params = ( %imports, @_ );
   return \%params;
}
sub BUILD {
    my $self = shift;
}

# Populate %imports with whatever gets supplied on the use line
sub import {
    my $class = shift;
    if (scalar(@_) % 2 == 0) {
        %imports = @_;
    }
}

no Moose;


1; # Magic true value required at end of module
__END__


=head1 NAME

Schedule::Pluggable - Flexible Perl Process Scheduler

=head1 SYNOPSIS

 EXAMPLE #1:    Simple Run in Series
    use Schedule::Pluggable;
    my $p = Schedule::Pluggable->new;
    my $status = $p->run_in_series( [ qw/command1 command2 command3/ ] );

 EXAMPLE #2:    Simple Run in Parallel
    use Schedule::Pluggable;
    my $p = Schedule::Pluggable->new;
    my $status = $p->run_in_parallel( [ qw/command1 command2 command3/ ] );


 EXAMPLE #3:    With Job  Names
    use Schedule::Pluggable;
    my $p = Schedule::Pluggable->new;
    my @jobs = (
                { name => "FirstJob", command => "somescript.sh" },
                { name => "2nd Job", command => sub { do_something; } },
                );
    my $status = $p->run_schedule( \@jobs );

  EXAMPLE #4:    With Prerequsites
    use Schedule::Pluggable;
    my $p = Schedule::Pluggable->new;
    my $jobs = [ { name => "FirstJob",
                   command => "somescript.sh" },
                 { name => "SecondJob",
                   command => sub { do_something; },
                   prerequisites => [qw/FirstJob/] },
               ];
    my $status = $p->run_schedule( $jobs );

  EXAMPLE #5:    Same as #4 but with dependencies
    use Schedule::Pluggable;
    my $p = Schedule::Pluggable->new;
    my $jobs = [ { name => "FirstJob",
                   command => "somescript.sh",
                   dependencies => [qw/SecondJob/] },
                 { name => "SecondJob",
                   command => sub { do_something; } },
               ];
    my $status = $ps->run_schedule( $jobs );

  EXAMPLE #5:  With Groups 
    use Schedule::Pluggable;
    my $p = Schedule::Pluggable->new;
    my $jobs = ( { name => "one", command => "one.sh", dependencies => [ qw/Reports/ ] }, 
                 { name => "two", command => "two.pl" }, groups => [ qw/Reports/] },             
                 { name => "three", command => "three.pl" }, groups => [ qw/Reports/] },
                 { name => "four", command => "four.ksh" }, prerequisites => [ qw/Reports/] },
                );
    my $status = $p->run_schedule( $jobs );

  EXAMPLE #6: Getting the config from an XML file

    use Schedule::Pluggable (JobsConfig => 'JobsFromXML');
    my $p = Schedule::Pluggable->new;
    my $status = $p->run_schedule({XMLFile => 'path to xml file'});

    XMlFile in following format :-
    <?xml version="1.0"?>
    <Jobs>
        <Job name='Job1' command='succeed.pl'>
            <params>3</params>
            <dependencies>second</dependencies>
        </Job>
        <Job name='Job2' command='fail.pl'>
            <params>3</params>
            <group>second</group>
        </Job>
        ...
    <Jobs>


=head1 DESCRIPTION

Schedule::Pluggable is a perl module which provides a simple but powerful way of running processes in a controlled way.
In true perl fashion it makes simple things easy and complicated things possible.
It also uses a system of plugins so you can change it's behaviour to suit your requirements by supplying your own plugins.
For most cases the default plugins will suffice however.

=head1 OPTIONS

You can override the default behaviour of Schedule::Pluggable by supplying options with the use statement in for form of a hash

i.e.

use Schedule::Pluggable ( Option => "value' );

The Following options are supported :-


=head2 B<JobsConfig>

Specifies which plugin to use to provide the job configuration - defaults to JobsFromData which expects you to supply the job configuration in an array

Each plugin is expected to 

e.g.

use Schedule::Pluggable ( JobsConfig => 'JobsFromSomeWhere' );

Currently the available values are :-

=over 

=item B<JobsFromArray>

The default which activates the role 'Schedule::Pluggable::Plugin::JobsFromData' which as the name suggests expects the job configuration to be be supplied as an reference to an array of jobs to run.

=item B<JobsFromXML>

Activates plugin Schedule::Pluggable::Plugin::JobsFromXML which obtains the jobs configuration from an XML file

=back

This enables you to specify a different source for the config by supplying an appropriate plugin for it - see writing Plugins for details


=head2 B<EventHandler>

Controls what happens when an event happens like a jobs starting a job failing e.t.c
Defaults to DefaultEventHandler which is a plugin Schedule::Pluggable::Plugin::DefaultEventHandler
Here is what is passed depending on event type

=over

=item JobName     - Always passed 

=item Command     - Always passed

=item Stdout      - Passed on JobStdout and JobSucceeded only

=item Stderr      - Passed on JobStderr and JobFailed

=item ReturnValue - Passed on JobFailed

=back

This handler uses other configuration options to control it's behaviour as follows :-

=head3 B<EventsToReport>

Comma separated list of events to report on or 'all' for al of them of 'none' for none of them 
Defaults to qq/JobFailed,JobSucceeded,JobStderr/

e.g.

use Schedule::Pluggable ( EventsToReport => qw/JobQueued,JobFailed,JobSucceeded,JobStderr/ );

=head3 B<PrefixWithTimeStamp>

whether to prefix messages with the current time in dd/mm/yyyy HH::MM::SS format.

Defaults to 1 (timestamp is produced)

=head2 B<MessagesTo>  

where messages are sent - stdout by default

If supplied a filehandle, will call the print method on it and pass the details, for anything else
will call directly.
So this could be a Log::Log4perl method e.g. $log->info or $log->{ Category }->info

=head2 B<ErrorsTo> 

where error messages are sent - stderr by default

If supplied a filehandle, will call the print method on it and pass the details, for anything else
will call directly.
So this could be a Log::Log4perl method e.g. $log->error or $log->{ Category }->error


e.g. 

use Schedule::Pluggable ( ErrorsTo => \&my_logger );

or

use Schedule::Pluggable;
my $p = Schedule::Pluggable->new( MessagesTo => \&my_logger );


=head1 JOB CONIFIGURATION FORMAT

A Job entry can be a scalar value in which case it is assumed to contain a command to run or a hash containing some or all of the following :-

=over

=item name

the name of the job

=item command        - command to run

=item params         - array of parameters to the command

=item groups         - array of groups to which the job belongs

=item prerequisites  - array of jobs or groups which must have completed successfully before job with start

=item dependencies   - array of jobs or groups which must wait until this job has completed successfully before they will start

=back

Obviously the bare minimum is to supply a command to run
If a name is not supplied, it will be allocated one in the format Jobn where n is an incrementing number starting at 1 and increases with each job specified

=head1 METHODS

=over

=item run_in_series ( $job_specification )

Utility method to run the supplied jobs in series by creating dependencies where each job is dependant on the previous one and then calls run_schedule with the revised definition

=item run_in_parallel ( $job_specification )

Runs the supplied jobs in parallel

Utility method to run the supplied jobs in parallel by removing and dependencies which are defined and the  call run_schedule

=item run_schedule ( $job_specification )

The main method of the module - takes a supplied job definition - processes the information to validate and expand the definition and then runs the jobs as specified.
When any event occurs, the appropriate callback is called if required to report on progress and on completion returns a structure detailing what happened in the following format :-

$status = { TotalJobs       => <total number of jobs in schedule>,
            TotalFailed     => <number of jobs which failed>,
            TotalFinished   => <number of jobs which finished>,
            TotalSucceeded' => <number of successfull jobs>'
            LastUpdate      => 'dd/mm/yyyy hh::mm::ss',
            Failed          => {
                                 <Job which failed> => {
                                                         status => <return value of job>,
                                                         stderr => [
                                                                    'error line 1',
                                                                    .... 
                                                                    ],
                                                       },
                                },
            Jobs            => {
                                <Job Name> => {
                                                name        => <Job Name>,
                                                command     => <command>
                                                status      => <return value of command>
                                                Pid         => <Process Id>,
                                                timestarted => 'dd/mm/yyyy hh::mm::ss',
                                                timefinished=> 'dd/mm/yyyy hh::mm::ss',
                                                stderr      => [
                                                                 'error line 1',
                                                                 .... 
                                                               ],
                                                stdout      => [ 
                                                                 'output line 1',
                                                                 ....
                                                               ],
                                                },
                                ........
                                },
            };

=item BUILDARGS       Handles module options via import or passed on objet creation

=item BUILD           Handles loading plugins

=back

=head1 JOB DEFINITIONS

Jobs are specified as reference to an array which can contain either a list of commands ot run or as hash values

=over

=item scalar values containing commands to run

=item hashes containing at least one key 'command' with the value containing the command to run

=back


=head1 AUTHOR

Tony Edwardson <Tony@Edwardson.co.uk>

=head1 KNOWN ERRORS

None yet - let me know if you find any

=head1 TODO

=over

=item Improve Test Suite

=item Improve Error Handling

=item Add more Plugins

=item Handle Job Timeouts

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Tony Edwardson.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
