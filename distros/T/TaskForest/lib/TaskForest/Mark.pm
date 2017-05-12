################################################################################
#
# $Id: Mark.pm 219 2009-06-09 03:30:29Z aijaz $
# 
################################################################################

=head1 NAME

TaskForest::Mark - Functions related to marking a job as Success or Failure

=head1 SYNOPSIS

 use TaskForest::Mark;

 &TaskForest::Mark::mark($family_name, $job_name, $log_dir, $status, $cascade, $dependents_only, $family_dir)

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

This is a simple package that provides a location for the mark
function, so that it can be used in the test scripts as well. 

=head1 METHODS

=cut

package TaskForest::Mark;
use strict;
use warnings;
use Carp;
use File::Copy;
use TaskForest::Family;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item mark()

 Usage     : mark($family_name, $job_name, $log_dir, $status)
 Purpose   : Mark the specified job as success or failure.  This job
             only changes the name of the status file:
             $family_name.$job_name.[01].  The actual contents of the
             file, the original return code is not changed.  The file
             name is what is used to determine job dependencies. 
 Returns   : Nothing
 Arguments : $family_name - the family name
             $job_name - the job name
             $log_dir - the root log directory
             $status - "Success" or "Failure".  Case does not matter. 
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub mark {
    my ($family_name, $job_name, $log_dir, $status, $cascade, $dependents_only, $family_dir, $quiet) = @_;

    my $jobs;
    
    if ($cascade or $dependents_only) {

        $ENV{TF_JOB_DIR}     = 'unnecessary' unless $ENV{TF_JOB_DIR};
        $ENV{TF_RUN_WRAPPER} = 'unnecessary' unless $ENV{TF_RUN_WRAPPER};
        $ENV{TF_LOG_DIR}     = $log_dir      unless $ENV{TF_LOG_DIR};
        $ENV{TF_FAMILY_DIR}  = $family_dir   unless $ENV{TF_FAMILY_DIR};

        my $family = TaskForest::Family->new(name => $family_name);

        $jobs = $family->findDependentJobs($job_name);

        if ($cascade) {
            push (@$jobs, $job_name);
        }

    }
    else {
        $jobs = [$job_name];
    }

    unless (@$jobs) {
        print STDERR "There are no jobs to rerun.  Did you misspell the job name?\n";
        exit 1;
    }

    
    foreach my $job (@$jobs) { 
        markHelp($family_name, $job, $log_dir, $status, $quiet);
    }
}


sub markHelp {
    my ($family_name, $job_name, $log_dir, $status, $quiet) = @_;

    print "Marking job $family_name","::","$job_name as $status.\n" unless $quiet;
    
    my $rc_file      = "$log_dir/$family_name.$job_name.";
    my $new_rc_file;
    
    if ($status =~ /success/i) {
        $new_rc_file = $rc_file . "0";
        $rc_file .= '1';
    }
    else { 
        $new_rc_file = $rc_file . "1";
        $rc_file .= '0';
    }
    
    if (-e $new_rc_file) {
        carp("$family_name.$job_name is already marked $status.  Not doing anything.");
    }
    else {
        move($rc_file, $new_rc_file) || confess ("couldn't move $rc_file to $new_rc_file: $!");
    }
    
}

1;
