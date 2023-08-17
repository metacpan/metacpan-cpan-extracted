# NAME

Schedule::SGELK

# SYNOPSIS

A module for submitting jobs to an SGE queue.

    use Schedule::SGELK
    my $sge=Schedule::SGELK->new(verbose=>1,numnodes=>5,numcpus=>8,workingdir=>"SGE/",waitForEachJobToStart=>1);
    $sge->set("jobname","thisisaname");
    # run a series of jobs and wait for them all to finish
    my $job=$sge->pleaseExecute("sleep 60");
    my $job2=$sge->pleaseExecute("sleep 60");
    $sge->wrapItUp();
    # or you can specify which jobs to wait for
    $sge->waitOnJobs([$job,$job2],1); # 1 means wait for all jobs to finish; 0 to wait for any free node
    # or in one step
    $sge->pleaseExecute_andWait("sleep 60");

A quick test for this module is the following one-liner

    perl -MSchedule::SGELK -e '$sge=Schedule::SGELK->new(numnodes=>5); for(1..3){$sge->pleaseExecute("sleep 3");}$sge->wrapItUp();'

Another quick test is to use the test() method, if you want to see standardized text output (see test() below)

    perl -MSchedule::SGELK -e '$sge=Schedule::SGELK->new(-numnodes=>2,-numcpus=>8); $sge->test(\%tmpSettings);'

# DESCRIPTION

A module for submitting jobs to an SGE queue. Monitoring is 
performed using a combination of monitoring files 
written to the hard drive and qstat.
Submitting is performed internally by making a perl script.

# AUTHOR

Author: Lee Katz <lkatz@cdc.gov>

## METHODS

- `sub new` create a new instance of a scheduler.

Arguments and their defaults:

      numnodes=>50 maximum nodes to use
      numcpus=>128 maximum cpus that will be used per node in a script
      maxslots=>9999 maximum slots that you can use. Useful if you want to be limited by total slots instead of nodes or CPUs. E.g. {numnodes=>100,numcpus=>1,maxslots=>20}
      verbose=>0
      workingdir=>$ENV{PWD} a directory that all nodes can access to read/write jobs and log files
      waitForEachJobToStart=>0 Allow each job to start as it's run (0), or to wait until the qstat sees the job before continuing (1)
      jobname=>... This is the name given to the job when you view it with qstat. By default, it will be named after the script that calls this module.
      warn_on_error=>1 This will make the script give a warning instead of exiting
      qsubxopts=>... These are extra options to pass to qsub.  E.g., {qsubxopts=>"-V"}  Options are overwritten by appending them to the within-script options. Therefore this is not the best way to choose a different queue but it is a way to change a job name or the number of processors.
      noqsub=>1 Force performing a system call instead of using qsub
      queue=>all.q    Choose the queue to use for a new job.  Default: all.q

Examples:

        {numnodes=>100,numcpus=>1,maxslots=>50} # for many small jobs
        {numnodes=>5,numcpus=>8,maxslots=>40} # for a few larger jobs. NOTE: maxslots should be >= numnodes * maxslots

- `sub error($msg,$exit_code) or error()`

Get or set the error. Can set the error code too, if provided.

- `sub set() get() settings()`

Get or set a setting. All settings are listed under sub new().
If a setting is provided without a value, then nothing new will be set,
and only the value of the specified setting will be returned.

- `pleaseExecute()`

This is the main method. It will submit a command to the cluster.

      $sge->set("jobname","a_nu_start");
      $sge->pleaseExecute("someCommand with parameters");

If you are already occupying more than numnodes, then it will pause before 
executing the command. It will also create many files under workingdir, so
be sure to specify it. The workingdir is the current directory by default.

You can also specify temporary settings for this one command with a referenced hash.

      $sge->pleaseExecute("someCommand with parameters",{jobname=>"a_nu_start",numcpus=>2});

- `pleaseExecute_andWait()`

Exact same as pleaseExecute(), except it will wait for the command to finish 
before continuing. Internally calls pleaseExecute() and then waitOnJobs().
However one key difference between pleaseExecute() and this sub is that you can
give a list of commands.

    # this will take 100 seconds because all commands have to finish.
    $sge->pleaseExecute_andWait(["sleep 60","sleep 100","sleep 3"]);

- `checkJob($jobHash)`

Checks the status of a given job. The job variable is obtained from pleaseExecute().
$self->error can be set if there is an error in the job. Return values:
1 for finished; 0 for still running or hasn't started; -1 for error.

- `jobStatus(jobid)`

Given an SGE job id, it returns its qstat status

- `qstat`

Runs qstat and caches the result for one second. Or, returns the cached result of qstat

- `wrapItUp()`

Waits on all jobs to finish before pausing the program.
Calls waitOnJobs or joinAllThreads internally. Does not take any parameters.

- `joinAllThreads($jobList)`

Joins all threads.  This is if you have ithreads and if the scheduler is not set.
For example, if you specify noqsub or if qsub executable is not found.

- `waitOnJobs($jobList,[$mustFinish])`

Waits on all given jobs to finish. The job list are jobs as given by pleaseExecute().
If $mustFinish evaluates to true, then the program will pause until
all jobs are finished.
Calls on checkJob() internally. Will die with an error message if a job dies.

- `cleanAJob`

This is internally used for cleaning up files after a job is done. 
Do not use externally.

- `test`

Use this method to perform a test. The test sends 
ten jobs that print debugging information.

You can give an optional hash argument to send other settings as described in new().

    perl -MSchedule::SGELK -e '$sge=Schedule::SGELK->new(-numnodes=>2,-numcpus=>8); $sge->test(\%tmpSettings);'

