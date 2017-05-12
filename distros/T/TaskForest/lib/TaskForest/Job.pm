################################################################################
#
# $Id: Job.pm 280 2010-03-17 02:20:17Z aijaz $
#
################################################################################

=head1 NAME

TaskForest::Job - A representation of a program that can be run by the operating system

=head1 SYNOPSIS

 use TaskForest::Job;

 $job = TaskForest::Job->new(name => $job_name);
 # now $job->{status} eq 'Waiting'
 # and $job->check() == 0

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

A job is a program that can be run.  It is represented as a file in
the files system whose name is the same as the job name.  Most of the
manipulation of the attributes of jobs is done by objects of type
TaskForest::Family.

A job name may only contain the characters a-z, A-Z, 0-9, and '_'.

When a job is run by the run wrapper (bin/run), two status files are
created in the log directory.  The first is created when a job starts and
has a name of $FamilyName.$JobName.pid.  This file contains some
attributes of the job.  When the job completes, more attributes are
written to this file.  See the list of attributes below.

When the job completes, another file is written to the log directory.  The
name of this file will be $FamilyName.$JobName.0 if the job ran
successfully, and $FamilyName.$JobName.1 if the job failed.  In either
case, the file will contain the exit code of the job (0 in the case of
success and non-zero otherwise).  

The system tracks the following properties of a job:

=over 2

=item * Status.

Valid status are:

=over 2

=item * Waiting

One or more dependencies of the job have not been met

=item * Ready

All dependencies have been met; the job will run the next time around.

=item * Running

The job is currently running

=item * Success

The job has run successfully

=item * Failure

The job was run, but the program exited with a non-zero return code

=back    

=item * Return Code

The exit code of the program associated with the job.  0 implies success.  Anything else implies failure.

=item * Time Zone

The time zone with which this job's time dependency is tracked.

=item * Scheduled Start

The scheduled start time of the job, as specified in the family config file.  This is to be interpreted with the timezone above.

=item * Actual Start

The time that the job actually started (in the timezone above).

=item * Stop Time

The time that the job completed (succeeded or faild).

=back

=head1 METHODS

=cut    

package TaskForest::Job;

use strict;
use warnings;
use Data::Dumper;
use Carp;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}

my $n = 0;

# ------------------------------------------------------------------------------
=pod

=over 4

=item new()

 Usage     : my $job = TaskForest::Job->new();
 Purpose   : The Job constructor creates a simple job data
             structure.  Other classes will set and examine status
             and return code. 
 Returns   : Self
 Argument  : None
 Throws    : "No job name specified" if the required parameter "name"
             is not provided. 

=back

=cut

# ------------------------------------------------------------------------------
sub new {
    my $arg = shift;
    my $class = (ref $arg) || $arg;
    my $pid = $$;
    $n++;
    my $unique_id = join("_", time, $pid, $n);

    my $self = {
        name         => '',
        rc           => '',                       # exit code
        status       => 'Waiting',
        unique_id    => $unique_id,
        
        params       => '',
        
    };

    my %args = @_;

    # set up any other parameters that the caller may have passed in 
    #
    foreach my $key (keys %args) {
        $self->{$key} = $args{$key};
    }

    croak "No Job name specified" unless $self->{name};

    bless $self, $class;
    return $self;
}

# ------------------------------------------------------------------------------
=pod

=over 4

=item check()

 Usage     : $job->check();
 Purpose   : Checks to see whether the job succeeded.  Implies that
             it has already run.
 Returns   : 1 if it succeeded.  0 otherwise.
 Argument  : None
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub check {
    my $self = shift;

    if ($self->{family}) {
        
        # this is an external dependency
        
        # TODO: What time zone should we look at? The time zone of the
        # family that owns this job?  Or the time zone of the family
        # in which this job is present?
        
        # To make matters simpler, I think it should be the time zone
        # of the family that includes this external dependency.  It's
        # more obvious. Just look for the file in today's log
        # dir. Period.

        my $foreign_status = shift;
        if ($foreign_status->{$self->{name}}) {
            return 1;
        }

        return 0;
    }


    if ($self->{status} eq 'Success') {
        return 1;
    }

    return 0;
}

1;

__END__

    
