package Parallel::ThreadContext;

=head1 NAME

ThreadContext - Framework for easy creation of multithreaded Perl programs.

=cut

use 5.8.0;
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK @EXPORT $debug);
require Exporter;

use threads;
use threads::shared;
use Thread::Semaphore;
use Thread::Queue;

@ISA = qw(Exporter);
$VERSION = '0.01';
@EXPORT_OK = ();
@EXPORT = ();
$| = 1;
$debug = '';

#global data management
my %QueuesHash:shared; #key = context name, value = queue object
my %QueueStatusHash:shared; #key = name of queue = context name, value = status of queue (finalized or not)
my %ThreadGroupNamesHash:shared; #key = name of thread group = context name, value = underscore separated thread IDs
my %LocksHash:shared; #key = context name '+' lock name, value = lock object

=head1 Features

=head2 version

  return the current version information for this module
  
  arguments: none
  
  returns:
    version info of this module

=cut

sub version
{
  return "ThreadContext.pm v$VERSION\n";
}

=head2 start

  create and run a thread group to perform specific queue jobs 
  all threads in the group will run the same code with different data and will share the same queue and same locks
  we say that they run in the same context.
  
  arguments:
    reference to code to be executed by each thread (mandatory)
    reference to array data (jobs) to be distributed to each thread (mandatory)
    number of threads to be started (mandatory)
    name to assign to this context of execution (optional, default context is assumed otherwise)
  
  returns: none

=cut

sub start
{
  my $function = shift @_;
  my $jobs = shift @_;
  my $nbthreads = shift @_;
  my $contextname = shift @_;
  $contextname = "_DEFAULT_" unless (defined $contextname);
  die "$function is an invalid function reference" unless (ref $function eq "CODE");
  die "$jobs is an invalid array reference" unless (ref $jobs eq "ARRAY");
  die "$contextname is an invalid Context name" unless ($contextname =~ /^\w+$/);
  {
    lock(%QueuesHash);
    unless (defined $QueuesHash{$contextname}) 
    {
      print "DEBUG: Queue in Context '$contextname' does not exist yet, is going to be created\n" if $debug;
      $QueuesHash{$contextname} = Thread::Queue->new(); 
      $QueueStatusHash{$contextname} = 0;
    }
  }
  my $nbjobs = scalar @$jobs;
  print "DEBUG: adding $nbjobs jobs to queue in context '$contextname'\n" if $debug;
  Thread::Queue::enqueue($QueuesHash{$contextname},@$jobs); #workaround for Perl bug: $QueuesHash{$contextname} gets unblessed when it is shared 
    
  unless (defined $ThreadGroupNamesHash{$contextname}) 
    {
      print "DEBUG: ThreadGroup in Context '$contextname' does not exist yet, is going to be created\n" if $debug;
      $ThreadGroupNamesHash{$contextname} = "";
    }   
  
  print "DEBUG: Starting $nbthreads threads to execute $function in context '$contextname'\n" if $debug;
  for (my $i = 1; $i <= $nbthreads; $i++)
  {
    my $thread = async
    {
      while(Thread::Queue::pending($QueuesHash{$contextname}) or not($QueueStatusHash{$contextname}))
      {
        my $job = Thread::Queue::dequeue_nb($QueuesHash{$contextname});
        if (defined $job)
        {
          if (ref $job eq "HASH") #hash reference
          {
            $function->(%$job);           
          }
          elsif (ref $job eq "ARRAY") #array reference
          {
            $function->(@$job);
          }
          else #otherwise
          {
            $function->($job);
          }
        }
      }       
    };    
    $ThreadGroupNamesHash{$contextname} .= $thread->tid()."_";
  } 
  print "DEBUG: ThreadGroup contains thread IDs '$ThreadGroupNamesHash{$contextname}'\n" if $debug; 
}

=head2 end

  terminate execution in the given context
  all affected threads will be asked to return (eventually wait till they have finished processing the queue)
  
  arguments:
    name of context (optional, default context is assumed otherwise)
  
  returns:
    reference to hash containing the return values from each exited thread (thread id is hash key)

=cut

sub end
{
  my $contextname = shift @_;
  $contextname = "_DEFAULT_" unless (defined $contextname);
  die "$contextname is an invalid Context name" unless ($contextname =~ /^\w+$/);
  if (defined $ThreadGroupNamesHash{$contextname})
  {
    if ($QueueStatusHash{$contextname} == 0)
    {
      print "WARNING: Cannot join threads in context '$contextname': still waiting for jobs (queue not finalized)\n";
      return;
    }
    my %return_hash;
    my @helper = split("_",$ThreadGroupNamesHash{$contextname});
    print "DEBUG: Waiting for termination of ".scalar @helper." threads in context '$contextname'\n" if $debug;
    foreach my $tid (@helper)
    {
      my @temp;
      if (defined threads->object($tid))
      {
        @temp = threads->object($tid)->join() ;
        print "INFO: Thread $tid successfully joined\n";
      }           
      $return_hash{$tid} = \@temp;
    }
    print "DEBUG: Deleting thread group in context '$contextname'\n" if $debug;
    delete $ThreadGroupNamesHash{$contextname};
    print "DEBUG: Deleting queue in context '$contextname'\n" if $debug;
    delete $QueuesHash{$contextname};
    delete $QueueStatusHash{$contextname};
    foreach my $lockkey (sort keys %LocksHash)
    {     
      my $patternstring = $contextname."\+";
      if ($lockkey =~ /$patternstring/)
      {
        my $lockname = substr($lockkey,length($contextname)+1);
        print "DEBUG: Deleting lock '$lockname' in context '$contextname'\n" if $debug;
        delete $LocksHash{$lockkey};
      }
    }
    return \%return_hash;
  } 
  else
  {
    print "WARNING: Context '$contextname' does not exist!\n";
  }
}

=head2 addJobsToQueue

  push additional jobs onto the queue in the given context
  
  arguments:
    reference to array data (jobs) which will be pushed onto the queue (mandatory)
    name of context (optional, default context is assumed otherwise)
  
  returns: none

=cut

sub addJobsToQueue
{
  my $jobs = shift @_;
  my $contextname = shift @_;
  die "$jobs is an invalid array reference" unless (ref $jobs eq "ARRAY");
  $contextname = "_DEFAULT_" unless (defined $contextname);
  die "$contextname is an invalid Context name" unless ($contextname =~ /^\w+$/);
  if (defined $QueuesHash{$contextname})
  {
    if ($QueueStatusHash{$contextname} == 0)
    {     
      my $nbjobs = scalar @$jobs;
      print "DEBUG: adding $nbjobs jobs to queue in context '$contextname'\n" if $debug;
      Thread::Queue::enqueue($QueuesHash{$contextname},@$jobs);
    }
    else
    {
      print "WARNING: Queue in Context '$contextname' was already finalized and cannot be altered!\n";
    }
  } 
  else
  {
    print "WARNING: Queue in Context '$contextname' does not exist!\n";
  }
}

=head2 finalizeQueue

  prevent adding jobs in the given context (irreversible)
  affected threads will then known that their task is done and they can safely return as soon as queue is empty
  
  arguments:
    name of context (optional, default context is assumed otherwise)
  
  returns: none

=cut

sub finalizeQueue
{
  my $contextname = shift @_;
  $contextname = "_DEFAULT_" unless (defined $contextname);
  die "$contextname is an invalid Context name" unless ($contextname =~ /^\w+$/);
  if (defined $QueuesHash{$contextname})
  {
    print "DEBUG: Finalizing queue in context '$contextname'\n" if $debug;
    $QueueStatusHash{$contextname} = 1;
  } 
  else
  {
    print "WARNING: Queue in Context '$contextname' does not exist!\n";
  }
}

=head2 reserveLock

  request and lock a resource
  any attempt to reserve the same lock will block until lock is released
  required for synchronisation of threads in the same context
  
  arguments:
    name of lock to be reserved (mandatory)
    name of context (optional, default context is assumed otherwise)
  
  returns: none

=cut

sub reserveLock
{
  my $lockname = shift @_;
  my $contextname = shift @_;
  $contextname = "_DEFAULT_" unless (defined $contextname);
  die "$lockname is an invalid Lock name" unless ($lockname =~ /^\w+$/);
  die "$contextname is an invalid Context name" unless ($contextname =~ /^\w+$/);
  
  {
    lock(%LocksHash);
    unless (defined $LocksHash{$contextname.'+'.$lockname}) 
      {
        print "DEBUG: Lock '$lockname' in Context '$contextname' does not exist yet, is going to be created\n" if $debug;
        $LocksHash{$contextname.'+'.$lockname} = Thread::Semaphore->new();
      } 
    print "DEBUG: Reserving lock '$lockname' in context '$contextname'\n" if $debug;
    Thread::Semaphore::down($LocksHash{$contextname.'+'.$lockname});
  }
}

=head2 releaseLock

  release a previously locked resource
  any attempt to reserve the same lock will succeed after lock is released
  required for synchronisation of threads in the same context
  
  arguments:
    name of lock to be released (mandatory)
    name of context (optional, default context is assumed otherwise)
  
  returns: none

=cut

sub releaseLock
{
  my $lockname = shift @_;
  my $contextname = shift @_;
  $contextname = "_DEFAULT_" unless (defined $contextname);
  die "$lockname is an invalid Lock name" unless ($lockname =~ /^\w+$/);
  die "$contextname is an invalid Context name" unless ($contextname =~ /^\w+$/);
  if (defined $LocksHash{$contextname.'+'.$lockname})
  {
    print "DEBUG: Releasing lock '$lockname' in context '$contextname'\n" if $debug;
    Thread::Semaphore::up($LocksHash{$contextname.'+'.$lockname});
  } 
  else
  {
    print "WARNING: Lock '$lockname' in Context '$contextname' does not exist!\n";
  }   
}

=head2 getContextName

  returns the name of context where calling thread is currently executed
  
  arguments: none
  
  returns:
    context name

=cut

sub getContextName
{
  my $cxt = "";
  foreach my $contextname (keys %ThreadGroupNamesHash)
  {
    my @helper = split("_",$ThreadGroupNamesHash{$contextname});
    foreach my $tid (@helper)
    {
      if (threads->tid() == $tid)
      {
        $cxt = $contextname;
        last;
      }
    }
    last unless ($cxt eq "");
  }
  return $cxt;
}

=head2 getNoProcessors

  returns the number of machine processors as returned by underlying OS
  Most of Windows and UNIX-like systems supported
  
  arguments: none
  
  returns:
    number of processors on machine

=cut

sub getNoProcessors
{
  abort("Platform $^O not supported") unless ($^O eq "MSWin32" or $^O =~ /(linux|unix)/i);
  my $nbprocs;
  my $env;
  if ($^O eq "MSWin32")
  {
    print "DEBUG: Trying to get number of processors under Windows\n" if $debug;
    $env = `set`;
    $env =~ /NUMBER_OF_PROCESSORS=(\d+)/;
    if (defined $1) 
    {
      $nbprocs = $1;
    }
  }
  elsif ($^O =~ /(linux|unix)/i)
  {
    print "DEBUG: Trying to get number of processors under UNIX/Linux\n" if $debug;
    $env = `cat /proc/cpuinfo | grep processor | wc -l`;
    if ($env =~ /^\d+$/)
    {
      $nbprocs = $env;
    }
  }
  return $nbprocs;
}

=head2 shareVariable

  Make the variable (scalar, array, hash) referenced by the given argument visible to all threads (shared variable)
  A depth of up to 10 references is allowed (reference to reference to ... to variable)
  
  arguments:
    reference to variable to be shared (mandatory)
  
  returns: none

=cut

sub shareVariable
{
  my $variable = shift @_;
  die "$variable is an invalid reference" unless ((ref $variable eq "SCALAR") or (ref $variable eq "ARRAY") or (ref $variable eq "HASH") or (ref $variable eq "REF"));
  my $loopcnt = 1;
  my $helper = $variable;
  while(ref $helper eq "REF")
  {
    $helper = $$helper; #traverse down reference one level
    $loopcnt++;
    die "Cannot share variable $variable: Maximum referencing depth of 10 was exceeded" if ($loopcnt > 10);
  } 
  share($helper); #share referenced scalar, array or hash 
  while($loopcnt > 1)
  {
    $helper = \$helper; #traverse up reference one level
    share($helper);
    $loopcnt--;
  }
  
}

=head2 yieldRuntime

  ask threads in the given context to yield some runtime to threads in other contexts
  how long they will let processor to other threads depend on the underlying OS
  
  arguments:
    name of context (optional, default context is assumed otherwise)
  
  returns: none

=cut

sub yieldRuntime
{
  my $contextname = shift @_;
  $contextname = "_DEFAULT_" unless (defined $contextname);
  die "$contextname is an invalid Context name" unless ($contextname =~ /^\w+$/);
  if (defined $ThreadGroupNamesHash{$contextname})
  {
    my @helper = split("_",$ThreadGroupNamesHash{$contextname});
    foreach my $tid (@helper)
    {
      threads->object($tid)->yield() unless (not defined threads->object($tid));
      print "INFO: Thread $tid yielded runtime to other threads\n";
    }     
  } 
  else
  {
    print "WARNING: Context '$contextname' does not exist!\n";
  }   
}

=head2 pauseCurrentThread

  pause the calling thread for the given time length in seconds.

  arguments:
    time length the thread shall pause
  
  returns: none

=cut

sub pauseCurrentThread
{
  my $pauselength = shift @_;
  die "$pauselength is an invalid pause length" unless ($pauselength =~ /^\d+$/ and $pauselength > 0);
  my $currenttime = 0;
  my $starttime = time();   
  while(1) {
    $currenttime = time();
    if ($currenttime >= $starttime+$pauselength) {
      last;
    }
  }
}

=head2 println

  print the given message by indicating source (Thread ID) and timestamp.

  arguments:
    message to be printed out
    
  returns: none

=cut

sub println
{
  my $text = shift @_;
  $text = "" unless (defined $text);
  my $tid = threads->tid();
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = gmtime();
  #some formatting
  $year += 1900;
  $mon += 1;
  $mon = '0'.$mon if ($mon < 10);
  $mday = '0'.$mon if ($mday < 10);
  $hour = '0'.$hour if ($hour < 10);
  $min = '0'.$min if ($min < 10);
  $sec = '0'.$sec if ($sec < 10);
  $tid = 'Main' if $tid == 0;  
  print "$year-$mon-$mday $hour:$min:$sec - Thread $tid: $text\n";
}

=head2 abortCurrentThread

  abort calling thread and print the given message by indicating source (Thread ID) and timestamp before

  arguments:
    message to be printed before exit
    
  returns: none

=cut

sub abortCurrentThread
{
  my $text = shift @_;
  $text = "" unless (defined $text);
  my $tid = threads->tid();
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday) = gmtime();
  #some formatting
  $year += 1900;
  $mon += 1;
  $mon = '0'.$mon if ($mon < 10);
  $mday = '0'.$mon if ($mday < 10);
  $hour = '0'.$hour if ($hour < 10);
  $min = '0'.$min if ($min < 10);
  $sec = '0'.$sec if ($sec < 10);  
  $tid = 'Main' if $tid == 0;
  die "$year-$mon-$mday $hour:$min:$sec - Thread $tid: $text";
}

1;

__END__

=head1 Synopsis

  use Parallel::ThreadContext;

  my $counter = 0;
  my $counter_ref = \$counter;
  
  sub op1
  {
    my $job = shift @_;
    Parallel::ThreadContext::abortCurrentThread("I am tired of living") if ($job == 30);
    Parallel::ThreadContext::println("performing job $job in Context ".Parallel::ThreadContext::getContextName());
    Parallel::ThreadContext::pauseCurrentThread(1);
    Parallel::ThreadContext::reserveLock("counterlock","computation");
    $counter++;
    Parallel::ThreadContext::releaseLock("counterlock","computation");
  }
  
  $Parallel::ThreadContext::debug = 1;
  print STDOUT Parallel::ThreadContext::version();
  my $nbthreads = Parallel::ThreadContext::getNoProcessors();
  if (defined $nbthreads)
  {
  $nbthreads *= 3; #3 threads per processor
  }
  else
  {
  $nbthreads = 3;
  }
  Parallel::ThreadContext::shareVariable($counter_ref);
  Parallel::ThreadContext::start(\&op1,[1..10],$nbthreads,"computation");
  Parallel::ThreadContext::addJobsToQueue([11..20],"computation");
  Parallel::ThreadContext::pauseCurrentThread(2);
  Parallel::ThreadContext::addJobsToQueue([21..26],"computation");
  Parallel::ThreadContext::pauseCurrentThread(4);
  Parallel::ThreadContext::end("computation"); #would give a warning if queue in the context is still open (not finalized yet)
  Parallel::ThreadContext::addJobsToQueue([27..30],"computation"); #warning since mentioned context does no longer exist
  Parallel::ThreadContext::addJobsToQueue([27..30],"computation");
  Parallel::ThreadContext::start(\&op1,[],1,"computation2");
  Parallel::ThreadContext::finalizeQueue("computation2");
  Parallel::ThreadContext::yieldRuntime("computation2");
  Parallel::ThreadContext::end("computation2");
  Parallel::ThreadContext::println("final counter value is $counter");

=head1 Description

  This module provides a framework and some utilities for easy creation of multithreaded Perl programs.
  It introduces and uses the concept of context based concurrent threads. 
  A context specifies a kind of name and work space for thread execution and consists of a queue + threads working on that queue + locks used by threads working on that queue.
  User can freely define as many contexts as he wants depending on its application logic e.g. 'prefetch', 'decode', 'execute', ...
  In each context threads are performing concurrent similar jobs on the same queue.
  All threads in the same context represent a thread group. Of course a group can consist of one thread only.
  Resources locked in one context do not affect other contexts.

=head1 Bugs and Caveats

  No known bugs at this time, but this doesn't mean there are aren't any. Use it at your own risk.
  Note that there may be other bugs or limitations that the author is not aware of.

=head1 Author

  Serge Tsafak <tsafserge2001@yahoo.fr>

=head1 Copyright

  This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 History

 Version 0.0.1: first release; August 2008

=cut

