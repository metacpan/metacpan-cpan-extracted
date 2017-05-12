################################################################################
#
# $Id: Rerun.pm 219 2009-06-09 03:30:29Z aijaz $
#
################################################################################

=head1 NAME

TaskForest::Rerun - Functions related to rerunning a job

=head1 SYNOPSIS

 use TaskForest::Rerun;

 &TaskForest::Rerun::rerun($family_name, $job_name)

=head1 DOCUMENTATION

If you're just looking to use the taskforest application, the only
documentation you need to read is that for TaskForest.  You can do this
either of the two ways:

perldoc TaskForest

OR

man TaskForest

=head1 DESCRIPTION

This is a simple package that provides a location for the rerun
function, so that it can be used in the test scripts as well. 

=head1 METHODS

=cut

package TaskForest::Rerun;
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

=item rerun()

 Usage     : rerun($family_name, $job_name, $log_dir)
 Purpose   : Rerun the specified job.  The existing job files will be
             renamed to $family_name.$job_name--Orig_$n--.* where $n
             is the next sequence number (starting from 1). 
 Returns   : Nothing
 Arguments : $family_name - the family name
             $job_name - the job name
             $log_dir - the root log directory
 Throws    : Nothing

=back

=cut

# ------------------------------------------------------------------------------
sub rerun {
    my ($family_name, $job_name, $log_dir, $cascade, $dependents_only, $family_dir, $quiet) = @_;

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
        rerunHelp($family_name, $job, $log_dir, $quiet);
    }
}


sub rerunHelp {
    my ($family_name, $job_name, $log_dir, $quiet) = @_;

    my $rc = 0;
    
    
    print "Making job $family_name $job_name available for rerun.\n" unless $quiet;

    my $rc_file      = "$log_dir/$family_name.$job_name.0";
    my $pid_file     = "$log_dir/$family_name.$job_name.pid";
    my $started_file = "$log_dir/$family_name.$job_name.started";
    my $actual_start;
    my $pid;

    if (!(-e $pid_file)) {
        confess("The pid file $pid_file is missing.  You will need to rerun the job manually.  See rerun --help for instructions.");
    }
    if (!(-e $started_file)) {
        confess("The started file $started_file is missing.  You will need to rerun the job manually.  See rerun --help for instructions.");
    }
    if (!(-e $rc_file)) {
        $rc = 1;
        substr($rc_file, -1, 1) = "1";
        if (!(-e $rc_file)) {
            substr($rc_file, -1, 1) = "[01]";
            confess("The rc file $rc_file is missing.  This means that the job is currently running or has been terminated abnormally.  You will need to rerun the job manually.  See rerun --help for instructions.");
        }
    }

    open (S, $pid_file) || confess ("Can't open $started_file: $!");
    while (<S>) {
        if (/^actual_start: (\d+)/) {
            $actual_start = $1;
        }
        if (/^pid: (\d+)/) {
            $pid = $1;
        }
        last if ($actual_start && $pid);
    }
    close (S);
    my $log_file = "$log_dir/$family_name.$job_name.$pid.$actual_start.stdout";


    my @origs = glob("$log_dir/$family_name.$job_name"."--Orig_*--.pid");
    my $next_id = 1;
    if (@origs) {
        my @ids = sort {$a <=> $b} map { /--Orig_(\d+)--/; $1 } @origs;
        my $max = pop(@ids);
        $next_id = $max + 1;
    }

    my $new_rc_file      = "$log_dir/$family_name.$job_name--Orig_$next_id--.$rc";
    my $new_pid_file     = "$log_dir/$family_name.$job_name--Orig_$next_id--.pid";
    my $new_started_file = "$log_dir/$family_name.$job_name--Orig_$next_id--.started";
    my $new_log_file     = "$log_dir/$family_name.$job_name--Orig_$next_id--.$pid.$actual_start.stdout";

    move($pid_file, $new_pid_file)         || confess ("couldn't move $pid_file to $new_pid_file: $!");
    move($started_file, $new_started_file) || confess ("couldn't move $started_file to $new_started_file: $!");
    move($rc_file, $new_rc_file)           || confess ("couldn't move $rc_file to $new_rc_file: $!");
    if (-e $log_file) { 
        move($log_file, $new_log_file)     || confess ("couldn't move $log_file to $new_log_file: $!");
    }

}

1;
