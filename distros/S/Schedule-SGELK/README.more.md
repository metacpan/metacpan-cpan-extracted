Schedule--SGELK
===============

Perl module for scheduling tasks, with only using qsub/qstat/qdel.  A very portable scheduler.

Author: Lee Katz <lkatz / CDC.gov>

INSTALLATION

Copy the file to a PERL5LIB directory under $perl5lib/Schedule/SGELK.pm

EXAMPLES
    
  One-liner

    perl -MSchedule::SGELK -e '$sge=Schedule::SGELK->new(numnodes=>5); for(1..3){$sge->pleaseExecute("sleep 3");}$sge->wrapItUp();'

  Within your code
  
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


DOCUMENTATION

`perldoc SGELK` for extensive documentation.
