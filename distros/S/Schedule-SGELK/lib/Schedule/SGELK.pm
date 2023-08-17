#! /usr/bin/env perl

=pod

=head1 NAME

Schedule::SGELK

=head1 SYNOPSIS

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
  

=head1 DESCRIPTION

A module for submitting jobs to an SGE queue. Monitoring is 
performed using a combination of monitoring files 
written to the hard drive and qstat.
Submitting is performed internally by making a perl script.

=head1 AUTHOR

Author: Lee Katz <lkatz@cdc.gov>

=cut

package Schedule::SGELK;
use strict;
use warnings;
use Data::Dumper;
use File::Basename qw/basename/;
use File::Spec;
use File::Slurp qw/read_file write_file/;
use File::Temp qw/tempdir/;
use String::Escape qw/escape/;
use version 0.77;

our $VERSION = version->declare("v1.5");

my $has_threads=eval{
  return 0; # this isn't working yet
  require threads;
  return 1;
};

# some global variables
my @jobsToClean=();
my @jobsToMonitor=();
my $numSlots=0; # number of slots that are being used now

sub logmsg {local $0=basename $0;my $FH = *STDOUT; print $FH "$0: ".(caller(1))[3].": @_\n";}
local $SIG{'__DIE__'} = sub { my $e = $_[0]; $e =~ s/(at [^\s]+? line \d+\.$)/\nStopped $1/; die("$0: ".(caller(1))[3].": ".$e); };
local $SIG{INT} = sub{ cleanAllJobs(); };

# to be called when the script exits
sub cleanAllJobs{
  return if(!@jobsToClean);
  logmsg "Cleaning all jobs";
  for (@jobsToClean){
    cleanAJob($_);
  }
}
END{
  cleanAllJobs();
}

=pod

=head2 METHODS

=over

=item sub new

create a new instance of a scheduler.
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
  {numnodes=>5,numcpus=>8,maxslots=>40} # for a few larger jobs (note: maxslots should be >= numnodes * maxslots

=back

=cut

sub new{
  my($class,%args)=@_;
  my $self=bless{},$class;

  # just start with verbosity = 0. This avoids an error in the >= checks
  $self->{'settings'}={};
  $self->{'error'}="";
  $self->{'exit_code'}=0;

  # load up if we know what we have
  foreach my $key (keys %args) {
    my $nodash=$key;
    $nodash =~ s/^\-//;
    $self->set($nodash,$args{$key});
  }

  # set defaults if they are not set
  my %default=(numnodes=>50,numcpus=>128,verbose=>0,waitForEachJobToStart=>0,maxslots=>9999,queue=>"all.q",scheduler=>"SGE");
  while(my($key,$value)=each(%default)){
    $self->settings($key,$value) if(!defined($self->settings($key)));
  }
  if(!$self->get("workingdir")){
    $self->set("workingdir",$self->mktempdir());
    logmsg "Working directory not set. Using ".$self->get("workingdir");
  }

  # executables
  for(qw(qsub qstat qdel)){
    # See if it exists
    my $exec=`which $_ 2>/dev/null`; 
    $exec="" if $?;
    chomp($exec);
    $self->set($_,$exec);

    $self->set("scheduler","") if(!$exec);
  }

  # See if SGE is present
  if($ENV{SGE_ROOT} && -e $ENV{SGE_ROOT}){
    $self->set("scheduler","SGE");
  } else{
    logmsg "Env variable \$SGE_ROOT is not set. I will not use SGE";
    $self->set("scheduler","");
    $self->set("qsub","");
  }

  # Remove the scheduler option if the user explicitly
  # chooses not to use it.
  $self->set("scheduler","") if($self->get("noqsub"));

  return $self;
}

=pod

=over

=item sub error($msg,$exit_code) or error()

Get or set the error. Can set the error code too, if provided.

=back

=cut

# Sets the error and returns the previous error message.
# Or, simply returns the current error message.
sub error{
  my($self,$msg,$exit_code)=@_;
  return $self->{error} if(!defined($msg));
  my $oldmsg=$self->{error};
  $self->{error}=$msg;
  $self->{exit_code}=$exit_code if(defined($exit_code));
  return $oldmsg;
}
=pod

=over

=item sub set() get() settings()

Get or set a setting. All settings are listed under sub new().
If a setting is provided without a value, then nothing new will be set,
and only the value of the specified setting will be returned.

=back

=cut

sub set{
  my($self,$key,$value)=@_;
  if(defined($key) && defined($value)){
    $self->{'settings'}{$key}=$value;
  } elsif (defined($key)){
    return $self->{'settings'}{$key};
  }
  return %{$self->{'settings'}} if wantarray;
  return $self->{'settings'};
}
# renaming of sub set()
sub get{
  my($self,@args)=@_;
  return $self->set(@args);
}
# renaming of sub set()
sub settings{
  my($self,@args)=@_;
  return $self->set(@args);
}

=pod

=over

=item pleaseExecute()

This is the main method. It will submit a command to the cluster.
  $sge->set("jobname","a_nu_start");
  $sge->pleaseExecute("someCommand with parameters");

If you are already occupying more than numnodes, then it will pause before 
executing the command. It will also create many files under workingdir, so
be sure to specify it. The workingdir is the current directory by default.

You can also specify temporary settings for this one command with a referenced hash.

  $sge->pleaseExecute("someCommand with parameters",{jobname=>"a_nu_start",numcpus=>2});

=back

=cut

sub pleaseExecute{
  my($self,$cmd,$tmpSettings)=@_;
  local $0=basename $0;
  my %settings=%{ $self->settings };

  # read in any temporary settings for this command
  $tmpSettings={} if(!defined($tmpSettings));
  $settings{$_}=$$tmpSettings{$_} for(keys(%$tmpSettings));

  # default settings for undefined settings
  my $jobid=-1; # -1 is an error state
  $settings{jobname}||="sgelk$0";
  $settings{logfile}||="$0.log";
  $settings{numcpus}||=1;
  $settings{timeout}||=60; # how long we will wait for qsub to start
  return 0 if($cmd=~/^\s*$/); # if there's no command, then no worries

  $self->waitOnJobs(\@jobsToMonitor,0); # wait until the job can be submitted

  my $rand=int(rand(999999));
  my $tempdir=$settings{workingdir};
  # create a perl script with the literal command in it
  my $script="$tempdir/qsub.$rand.pl";

  my $prefix=($0 eq '-e')?"STDIN":$0;
  $prefix="$settings{workingdir}/$prefix.$rand";
  my($submitted,$running,$finished,$died,$output)=("$prefix.submitted", "$prefix.running", "$prefix.finished","$prefix.died","$prefix.log");
   
  my $perl=`which perl`; chomp($perl);
  open(SCRIPT,">",$script) or die "Could not write to temporary script $script: $!";
  print SCRIPT "#! $perl\n\n";
  #   It has SGE params in it.
  print SCRIPT "#\$ -N $settings{jobname}\n";
  print SCRIPT "#\$ -S $perl\n";
  print SCRIPT "#\$ -V\n";
  print SCRIPT "#\$ -wd $ENV{PWD}\n";
  print SCRIPT "#\$ -pe smp $settings{numcpus}\n";
  print SCRIPT "#\$ -o $output\n";
  print SCRIPT "#\$ -e $output\n";
  print SCRIPT "#\$ -q $settings{queue}\n";
  #   qsubxopts get to be in here first but will be overwritten by later qsubopts below
  if(my $opts=$settings{qsubxopts}){
    print SCRIPT "# options specified by qsubxopts are in the next line:\n";
    print SCRIPT "#\$ $opts\n";
  }
  print SCRIPT "use strict;\nuse warnings;\n";
  print SCRIPT "use File::Slurp qw/read_file write_file/;\n";

  # announces that it was submitted
  my $sanitized=escape('qqbackslash',$cmd);
  print SCRIPT "write_file('$submitted',$sanitized);\n";
  # it runs the command
  print SCRIPT "write_file('$running',$sanitized);\n";
  print SCRIPT "system($sanitized);\n";
  # let the script try one more time if it fails
  #print SCRIPT "system($sanitized) if \$?;\n";
  # print a parsable error if the script dies. This error will be in $output and in file $died
  print SCRIPT <<END;
if(\$?){
  my \$error=\"QSUB ERROR\\n\$?\\n\$!\";
  write_file('$died',$sanitized);
  write_file('$died',{append=>1},"\\n\$error\\n");
  die \$error;
}
END
  # announces when it is finished
  print SCRIPT "write_file('$finished',$sanitized);\n";
  close SCRIPT;
  system("touch $script"); die if $?; # make the system close the script. Why isn't Perl closing it?
  #system("cat $script");sleep 60;die;

  # now run the script and get the jobid
  my %return=(submitted=>$submitted,running=>$running,finished=>$finished,died=>$died,tempdir=>$tempdir,output=>$output,cmd=>$cmd,script=>$script,jobname=>$settings{jobname},numcpus=>$settings{numcpus});
  my $qsub=$self->get("qsub");
  if(!$settings{scheduler}){
    my $job=command("$perl $script",$has_threads,\%settings);
    $return{thread}=$job if($has_threads);
    $return{jobid}=$job->tid if($has_threads);
    push(@jobsToClean,\%return) if(!$self->settings("keep"));
    push(@jobsToMonitor,\%return);
    $numSlots+=$settings{numcpus}; # claim these cpus
    return %return if wantarray;
    return \%return;
  } 

  # At this point, qsub is on this computer. Submit the job.
  my $out=`$qsub $script`; chomp($out);
  if($out=~/Your job (\d+)/){
    $jobid=$1;
    $out.=" from $script";
    logmsg $out if($settings{verbose});
  } else {
    logmsg "WARNING: the last job submitted did not have an obvious jobid. It can't be tracked!";
  }

  # monitor for the script to be running before moving on
  my $started=time;
  while(!-e $submitted){
    last if(!$self->settings("waitForEachJobToStart"));
    sleep 1;
    die "Command timed out!\n  $cmd" if((time-$started)>$settings{timeout});
    die "Command resulted in an error. qstat -j $jobid for more info\n  $cmd" if($self->jobStatus($jobid) eq 'Eqw');
  }

  # TODO create a link from the jobid to the random id
  
  $return{jobid}=$jobid;
  push(@jobsToClean,\%return) if(!$self->settings("keep"));
  push(@jobsToMonitor,\%return);
  $numSlots+=$settings{numcpus}; # claim these cpus
  return %return if wantarray;
  return \%return;
}

=pod

=over

=item pleaseExecute_andWait()

Exact same as pleaseExecute(), except it will wait for the command to finish 
before continuing. Internally calls pleaseExecute() and then waitOnJobs().
However one key difference between pleaseExecute() and this sub is that you can
give a list of commands.

  # this will take 100 seconds because all commands have to finish.
  $sge->pleaseExecute_andWait(["sleep 60","sleep 100","sleep 3"]);

=back

=cut

sub pleaseExecute_andWait{
  my($self,$cmd)=@_;
  my %settings=$self->settings;
  my $mustfinish=$self->settings("mustfinish"); # should be restored later
  $self->set("mustfinish",0);
  $cmd=[$cmd] if(ref($cmd) eq ""); # let cmd be a string but turn it into a list internally
  my(@jobid);
  for(@$cmd){
    my $jobid=$self->pleaseExecute($_);
    push(@jobid,$jobid);
    $self->waitOnJobs(\@jobid);
  }
  $self->waitOnJobs(\@jobid,1);
}

=pod

=over

=item checkJob($jobHash)

Checks the status of a given job. The job variable is obtained from pleaseExecute().
$self->error can be set if there is an error in the job. Return values:
1 for finished; 0 for still running or hasn't started; -1 for error.

=back

=cut 

sub checkJob{
  my($self,$job)=@_;
  # See what the job status is {jobid} for fast checking
  my $status=$self->jobStatus($$job{jobid});
  if($status eq 'qw'){ # queued but not running
    return 0;
  } elsif($status eq 'Eqw'){  # error
    $self->error("Command resulted in an error. qstat -j $$job{jobid} for more info\n  $$job{cmd}");
    return -1;
  } elsif($status=~/[rt]/){ # running or is delayed
    return 0;
  }

  # look at files to check on the job status, for slower checking.
  # see if the job has even started: {submitted}
  return 0 if(!-e $$job{submitted});
  # if the job finished, then great! {finished}
  return 1 if(-e $$job{finished});
  return 1 if(!keys(%$job)); # sometimes a job is blank... why?
  # if the job died
  if(-e $$job{died}){
    my @content=read_file($$job{output});
    chomp(@content);
    $self->error(join("\n",@content[-3..-1]));
    return -1;
  }
  # It's running if the die-file isn't there and if the running file is there
  return 0 if(-e $$job{running});
  logmsg "ERROR: Could not understand what the status is of job $$job{jobid}!\n".Dumper($job);
  return -1;
}

=pod

=over

=item jobStatus(jobid)

Given an SGE job id, it returns its qstat status

=back

=cut

sub jobStatus{
  my($self,$jobid)=@_;
  my $state=0;
  $jobid||=0;
  my $qstat=$self->qstat;
  for(split(/\n/,$qstat)){
    my @F=split /\s+/;
    if($F[0] eq $jobid){
      $state=$F[4];
    }
  }
  close QSTAT;
  return $state;
}

=pod

=over

=item qstat

Runs qstat and caches the result for one second. Or, returns the cached result of qstat

=back

=cut

sub qstat{
  my($self)=@_;
  # return the cached value if it was just accessed a second ago
  #return $self->get("qstat") if(defined($self->get("qstat")) && $self->get("qstat_timestamp") <= time - 1);

  my $content="";
  open(QSTAT,"qstat|") or die "ERROR: could not execute qstat! $!";
  while(my $line=<QSTAT>){
    $line=~s/^\s+|\s+$//g;
    $content.="$line\n";
  }
  close QSTAT;
  $self->set("qstat",$content);
  $self->set("qstat_timestamp",time);
  return $self->get("qstat");
}

=pod

=over

=item wrapItUp()

Waits on all jobs to finish before pausing the program.
Calls waitOnJobs or joinAllThreads internally. Does not take any parameters.

=back

=cut

# Wait on all jobs to finish and clear out the queue.
sub wrapItUp{
  my($self)=@_;
  if($self->get("scheduler")){
    $self->waitOnJobs(\@jobsToMonitor,1);
  } elsif($has_threads){
    $self->joinAllThreads(\@jobsToMonitor,1);
  }
  return 1;
}

=pod

=over

=item joinAllThreads($jobList)

Joins all threads.  This is if you have ithreads and if the scheduler is not set.
For example, if you specify noqsub or if qsub executable is not found.

=back

=cut

sub joinAllThreads{
  my($self,$job)=@_;

  JOINALLTHREADS:
  for my $j(@$job){
    next if(!$$j{thread});
    next if($$j{thread} && !$$j{thread}->is_joinable);
    logmsg "Joining TID".$$j{jobid};
    $$j{thread}->join;
    $$j{thread}=0;
  }

  # clean out the joined jobs
  my @newjob;
  for my $j(@$job){
    push(@newjob,$j) if($$j{thread});
  }
  $job=\@newjob;

  # if there is still something in @$job, then go for another round
  if(@$job){
    logmsg "Waiting for ".scalar(@$job)." more jobs to finish...";
    sleep 1;
    goto JOINALLTHREADS;
  }

}


=pod

=over

=item waitOnJobs($jobList,[$mustFinish])

Waits on all given jobs to finish. The job list are jobs as given by pleaseExecute().
If $mustFinish evaluates to true, then the program will pause until
all jobs are finished.
Calls on checkJob() internally. Will die with an error message if a job dies.

=back

=cut

# Wait on enough jobs to finish before returning.
# If a job finishes, splice it from the job array.
sub waitOnJobs{
  my($self,$job,$mustfinish)=@_;
  
  # if there is no qsub, then every job is only going one at a time
  my $qsub=$self->get("qsub");
  return @$job if(!$qsub);

  my %settings=$self->settings;
  $settings{mustfinish}=$mustfinish if(defined($mustfinish));
  if($settings{verbose}){
    logmsg "We have reached node capacity ($settings{numnodes})! Waiting for a job to finish." if(@$job >= $settings{numnodes});
    logmsg "We have reached slot capacity ($settings{maxslots})! Waiting for a job to finish." if($numSlots >= $settings{maxslots});
  }
  while(@$job > 0){
    for(my $i=0;$i<@$job;$i++){
      $$job[$i]{jobid}||=0;
      my $state=$self->checkJob($$job[$i]);
      if($state==1){
        logmsg "A job finished: $$job[$i]{jobname} ($$job[$i]{jobid})" if($settings{verbose});
        $numSlots = $numSlots - $$job[$i]{numcpus}; # not using these slots anymore
        splice(@$job,$i,1);
        last;
      } elsif($state==-1){
        my $msg="A job failed ($$job[$i]{jobname} [$$job[$i]{jobid}]! Look at $$job[$i]{output} for more details.\nError message was ".$self->error()."\n".Dumper($$job[$i]);
        die $msg if(!$settings{warn_on_error});
        # just print the warning if the script didn't die and forget about this dead job
        logmsg $msg;
        $numSlots = $numSlots - $$job[$i]{numcpus}; # not using these slots anymore
        $self->error($msg);
        splice(@$job,$i,1);
        last;
      }
    }
    sleep 1;
    # break out if you don't have to finish yet but you can still add in another job
    last if(!$settings{mustfinish} && @$job<$settings{numnodes} && $numSlots<$settings{maxslots});
  }
  return @$job;
}

=pod

=over

=item cleanAJob

This is internally used for cleaning up files after a job is done. 
Do not use externally.

=back

=cut

sub cleanAJob{
  my($job)=@_;
  my $jobid=$$job{jobid} || return 0;
  logmsg $jobid;
  for (qw(running submitted finished output script died)){
    unlink $$job{$_};
  }

  system("qdel $$job{jobid} 2>/dev/null | grep -v 'does not exist'");
  #die "Internal error" if $?;
  return 1;
}

sub mktempdir{
  my ($self,$settings) = @_;
  $settings||={};
  # SGELK.22623.XXXXX
  #my $tempdir_path = File::Spec->join(File::Spec->tmpdir(), (split("::",(caller(1))[3]))[1].".$$.XXXXX");
  mkdir "./.SGELK" if(!-d "./.SGELK");
  die if $?;
  my $tempdir_path = File::Spec->join("./.SGELK",(split("::",(caller(1))[3]))[1].".$$.XXXXX");
  my $tempdir = tempdir($tempdir_path, CLEANUP => !($$settings{keep}));
  return $tempdir;
}

sub command{
  my($cmd,$use_threads,$settings)=@_;
  my $job=0;
  if($use_threads){
    $job=threads->new(\&command,$cmd,0,$settings);
  } else {
    logmsg "Running $cmd";
    system($cmd);
    die "ERROR with command: $!\n  $cmd" if $?;
  }

  return $job;
}

=pod

=over

=item test

Use this method to perform a test. The test sends 
ten jobs that print debugging information.

You can give an optional hash argument to send other settings as described in new().

perl -MSchedule::SGELK -e '$sge=Schedule::SGELK->new(-numnodes=>2,-numcpus=>8); $sge->test(\%tmpSettings);'

=back

=cut

sub test{
  my($self,$tmpSettings)=@_;

  # get settings
  my %settings=%{ $self->settings };
  # read in any temporary settings for this command
  $tmpSettings={} if(!defined($tmpSettings));
  $$tmpSettings{verbose}=1; # make sure it's verbose for debugging
  $settings{$_}=$$tmpSettings{$_} for(keys(%$tmpSettings));

  # execute the jobs
  for(1..$self->get("numnodes")){
    logmsg "Job $_ is being submitted";
    my $text="Job count\t$_\n";
    $text.="$_\t$settings{$_}\n" for(keys(%settings));
    $self->pleaseExecute("echo '$text'|column -t",$tmpSettings);
  }
  $self->wrapItUp();
  return 1;
}

1;
