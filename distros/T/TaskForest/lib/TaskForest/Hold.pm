################################################################################
#
# $Id: Hold.pm 271 2010-02-12 04:49:25Z aijaz $
# 
################################################################################

=head1 NAME

TaskForest::Hold - Functions related to releasing all dependencies of a job.

=head1 SYNOPSIS

 use TaskForest::Hold;

 &TaskForest::Hold::hold($family_name, $job_name, $log_dir, $cascade, $dependents_only, $family_dir)

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

This is a simple package that provides a location for the hold
function, so that it can be used in the test scripts as well. 

=head1 METHODS

=cut

package TaskForest::Hold;
use strict;
use warnings;
use Carp;
use File::Copy;
use TaskForest::Family;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.34';
}


# ------------------------------------------------------------------------------
=pod

=over 4

=item hold()

 Usage     : hold($family_name, $job_name, $log_dir)
 Purpose   : Hold the specified job as success or failure.  This job
             creates a special file that's used to override the logic that
             determines whether or not a job is ready to run.
 Returns   : Nothing
 Arguments : $family_name - the family name
             $job_name - the job name
             $log_dir - the root log directory
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub hold {
    my ($family_name, $job_name, $log_dir, $family_dir, $quiet) = @_;

    my $jobs;


    $ENV{TF_JOB_DIR}     = 'unnecessary' unless $ENV{TF_JOB_DIR};
    $ENV{TF_RUN_WRAPPER} = 'unnecessary' unless $ENV{TF_RUN_WRAPPER};
    $ENV{TF_LOG_DIR}     = $log_dir      unless $ENV{TF_LOG_DIR};
    $ENV{TF_FAMILY_DIR}  = $family_dir   unless $ENV{TF_FAMILY_DIR};
    
    my $family = TaskForest::Family->new(name => $family_name);
    $family->getCurrent();
    
    if ($family->{jobs}->{$job_name} && $family->{jobs}->{$job_name}->{status} eq 'Waiting') {
        holdHelp($family_name, $job_name, $log_dir, $quiet);
    }
    else {
        carp "Cannot hold job ${family_name}::$job_name since it is not in the 'Waiting' state - it's in the ".
            $family->{jobs}->{$job_name}->{status}.
            " state.\n";
    }
    
    
}


sub releaseHold {
    my ($family_name, $job_name, $log_dir, $family_dir, $quiet) = @_;

    my $jobs;


    $ENV{TF_JOB_DIR}     = 'unnecessary' unless $ENV{TF_JOB_DIR};
    $ENV{TF_RUN_WRAPPER} = 'unnecessary' unless $ENV{TF_RUN_WRAPPER};
    $ENV{TF_LOG_DIR}     = $log_dir      unless $ENV{TF_LOG_DIR};
    $ENV{TF_FAMILY_DIR}  = $family_dir   unless $ENV{TF_FAMILY_DIR};
    
    my $family = TaskForest::Family->new(name => $family_name);
    $family->getCurrent();
    
    if ($family->{jobs}->{$job_name} && $family->{jobs}->{$job_name}->{status} eq 'Hold') {
        releaseHoldHelp($family_name, $job_name, $log_dir, $quiet);
    }
    else {
        carp "Cannot release hold on job ${family_name}::$job_name since it is not in the 'Hold' state - it's in the ".
            $family->{jobs}->{$job_name}->{status}.
            " state.\n";
    }
    
    
}


sub holdHelp {
    my ($family_name, $job_name, $log_dir, $quiet) = @_;

    print "Holding job $family_name","::","$job_name\n" unless $quiet;
    
    my $hold_file      = "$log_dir/$family_name.$job_name.hold";    
    
    if (-e $hold_file) {
        carp("$family_name.$job_name is already on hold.  Not doing anything.");
    }
    else {
        open (F, ">$hold_file") || croak "Cannot touch file $hold_file";
        
        print F "\n";;
    
        close F;
    }
    
}
 
sub releaseHoldHelp {
    my ($family_name, $job_name, $log_dir, $quiet) = @_;

    print "Releasing hold on job $family_name","::","$job_name\n" unless $quiet;
    
    my $hold_file      = "$log_dir/$family_name.$job_name.hold";    
    
    if (-e $hold_file) {
        my $num_deleted = unlink $hold_file;
        if ($num_deleted == 1) {
            # we're ok
        }
        else {
            croak ("ERROR: Cannot delete hold file $hold_file\n");
        }
    }
    else {
        carp ("Hold file doesn't exist.  The Hold may have already been released.");
    }
}
 
1;
