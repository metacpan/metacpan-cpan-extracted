################################################################################
#
# $Id: Release.pm 269 2010-02-12 04:43:10Z aijaz $
# 
################################################################################

=head1 NAME

TaskForest::Release - Functions related to releasing all dependencies of a job.

=head1 SYNOPSIS

 use TaskForest::Release;

 &TaskForest::Release::release($family_name, $job_name, $log_dir, $cascade, $dependents_only, $family_dir)

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

This is a simple package that provides a location for the release
function, so that it can be used in the test scripts as well. 

=head1 METHODS

=cut

package TaskForest::Release;
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

=item release()

 Usage     : release($family_name, $job_name, $log_dir)
 Purpose   : Release the specified job as success or failure.  This job
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
sub release {
    my ($family_name, $job_name, $log_dir, $family_dir, $quiet) = @_;

    my $jobs;


    $ENV{TF_JOB_DIR}     = 'unnecessary' unless $ENV{TF_JOB_DIR};
    $ENV{TF_RUN_WRAPPER} = 'unnecessary' unless $ENV{TF_RUN_WRAPPER};
    $ENV{TF_LOG_DIR}     = $log_dir      unless $ENV{TF_LOG_DIR};
    $ENV{TF_FAMILY_DIR}  = $family_dir   unless $ENV{TF_FAMILY_DIR};
    
    my $family = TaskForest::Family->new(name => $family_name);
    $family->getCurrent();
    
    if ($family->{jobs}->{$job_name} && ($family->{jobs}->{$job_name}->{status} eq 'Waiting')) {
        releaseHelp($family_name, $job_name, $log_dir, $quiet);
    }
    else {
        die "Cannot release job ${family_name}::$job_name since it is not in the 'Waiting' or 'Hold' state - it's in the ".
            $family->{jobs}->{$job_name}->{status}.
            " state.\n";
    }
    
    
}


sub releaseHelp {
    my ($family_name, $job_name, $log_dir, $quiet) = @_;

    print "Releasing all dependencies on job $family_name","::","$job_name\n" unless $quiet;
    
    my $release_file      = "$log_dir/$family_name.$job_name.release";    
    

    if (-e $release_file) {
        carp("$family_name.$job_name is already released.  Not doing anything.");
    }
    else {
        open (F, ">$release_file") || croak "Cannot touch file $release_file";
        
        print F "\n";;
    
        close F;
    }
    
}

1;
