#
# Copyright (c) 2002 Paul Winkeler.  All Rights Reserved.
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.
#
package NBU::Job;

use Time::Local;

use strict;
use Carp;

BEGIN {
  use Exporter   ();
  use AutoLoader qw(AUTOLOAD);
  use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);
  $VERSION =	 do { my @r=(q$Revision: 1.64 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
  @ISA =         qw();
  @EXPORT =      qw();
  @EXPORT_OK =   qw();
  %EXPORT_TAGS = qw();
}

my %pids;
my %jobs;

#
# New jobs are registered under their Process IDs
sub new {
  my $Class = shift;
  my $job = {
    MOUNTLIST => {},
    SIZE => 0,
  };

  bless $job, $Class;

  if (@_) {
    $job->{PID} = shift;

    if (exists($pids{$job->pid})) {
      my $pidArray = $pids{$job->pid};
      push @$pidArray, $job;
    }
    else {
      $pids{$job->pid} = [ $job ];
    }
  }
  return $job;
}

sub readerPID {
  my $self = shift;

  if (@_) {
    my $reader = shift;
    $self->{READERPID} = $reader;
    if (exists($pids{$reader})) {
      my $pidArray = $pids{$reader};
      push @$pidArray, $self;
    }
    else {
      $pids{$reader} = [ $self ];
    }
  }
  return $self->{READERPID};
}

#
# Extract all jobs from the hash and return them
# in a simple array
sub list {
  my $Class = shift;

  return (values %jobs);
}

my @jobTypes = ("Backup", "Archive", "Restore", undef, "Duplicate", "Import", "Catalog", "Vault", undef, undef, undef, undef, undef, undef, undef, undef, undef, "Image Cleanup");
my $asOf;
my $fromFile = $ENV{"HOME"}."/.alljobs.allcolumns";
my ($jobPipe, $refreshPipe);
sub loadJobs {
  my $Class = shift;
  my $master = shift;
  my $readFromFile = shift;
  my $logFile = shift;
  my $alternateFromFile = shift;

  if (defined($readFromFile)) {
    my $file = defined($alternateFromFile) ? $alternateFromFile : $fromFile;
    die "Cannot open previous job log file \"$file\"\n" unless open(PIPE, "<$file");

    if (NBU->debug) {
      print STDERR "Reading:   job history file $file\n";
    }
    $jobPipe = *PIPE{IO};
    my @stat = stat(PIPE);  $asOf = $stat[9];
  }
  else {
    $asOf = time;
    my $tee = defined($logFile) ? "| tee $fromFile" : "";
    ($jobPipe, $refreshPipe) = NBU->cmd("| bpdbjobs -report -all_columns -stay_alive -M ".$master->name." $tee |");
  }

  if (!(<$jobPipe> =~ /^C([\d]+)[\s]*$/)) {
    return undef;
  }
  my $jobRowCount = $1;

  while ($jobRowCount--) {
    my $jobDescription;
    if (!($jobDescription = <$jobPipe>)) {
      print STDERR "Failed to read from job pipe ($jobPipe) when $jobRowCount jobs were yet expected...\n";
      last;
    }
    parseJob($master, $jobDescription);
  }

  return $asOf;
}

sub refreshJobs {
  my $Class = shift;
  my $master = shift;

  return undef if (!defined($jobPipe));

  print $refreshPipe "refresh\n" if (defined($refreshPipe));

  if (!(<$jobPipe> =~ /^C([\d]+)[\s]*$/)) {
    return undef;
  }
  my $jobRowCount = $1;

  while ($jobRowCount--) {
    my $jobDescription;
    if (!($jobDescription = <$jobPipe>)) {
      print STDERR "Failed to read from job pipe ($jobPipe)\n";
      last;
    }
    parseJob($master, $jobDescription);
  }

  return $asOf;
}

sub parseJob {
  my $master = shift;
  my $jobDescription = shift;
  chop $jobDescription;

  #
  # Just after midnight, a "refresh" request on active bpdbjobs connection will result in
  # aging out a number of jobs.  This is communicated by sending the jobid's preceded by a minus
  # sign.  Such events are ignored here:
  if ($jobDescription =~ /^\-/) {
    return;
  }

  #
  # Occasionally some well-meaning but severely misguided soul decides that
  # the occasional comma inserted in the midst of an error message is a bad
  # thing indeed (which it is) so it was decided to quote that comma with a
  # back-slash.  It is for occasions such as this that the expression "From
  # the frying pan into the fire" was invented.  'nuff said.
  if ($jobDescription =~ s/([^\\])\\,/${1} -/g) {
  }

  my $KBWritten = 0;
  my (
    $jobID, $jobType, $state, $status, $className, $scheduleName, $clientName,
    $serverName, $started, $elapsed, $ended, $stUnit, $currentTry, $operation,
    $KBytesWritten, $filesWritten, $currentFile, $percent,
    # This is the PID of the bpsched process on the master
    $jobPID,
    $owner,
    $subType, $classType, $scheduleType, $priority,
    $group, $masterServer, $retentionUnits, $retentionPeriod,
    $compression,
    # The next two values are used to compute % complete information, i.e.
    # they represent historical data
    $KBytesLastWritten, $filesLastWritten,
    $pathListCount,
    @rest) = split(/,/, $jobDescription);

  my $job;
  if (!($job = NBU::Job->byID($jobID))) {
    $job = NBU::Job->new($jobPID);
    $job->id($jobID);


    $job->start($started);

    $job->{TYPE} = $jobTypes[$jobType] if ($jobType ne "");
    if (NBU->debug) {
	print STDERR "Undefined job type \"$jobType\" for job $jobID\n" if (!defined($job->{TYPE}));;
    }

    $job->{STUNIT} = NBU::StorageUnit->byLabel($stUnit) if (defined($stUnit) && ($stUnit !~ /^[\s]*$/));
    my $backupID = $clientName."_".$started;
    my $image = $job->image($backupID);
    $job->{CLASS} = my $class = $image->class(NBU::Class->new($className, $classType, $master));
    $job->{SCHEDULE} = $image->schedule(NBU::Schedule->new($class, $scheduleName, $scheduleType));
    $job->{CLIENT} = $image->client(NBU::Host->new($clientName));
  }

  #
  # Record a job's media server at the earliest opportunity
  if (!defined($job->mediaServer) && defined($serverName)) {
    $job->mediaServer(NBU::Host->new($serverName));
    $job->{STUNIT} = NBU::StorageUnit->byLabel($stUnit) if (defined($stUnit) && ($stUnit !~ /^[\s]*$/));
  }

  $job->state($state);
  $job->{TRY} = ($currentTry ne "") ? $currentTry : undef;

  #
  # Extract the list of paths (either in the class definition's include list
  # or the ones provided by the user.
  # As of NBU 6.5 (possibly earlier), the path descriptions have gotten more verbose.
  # Mostly this is a good thing, except that under certain circumstances these
  # descriptions now contain commas!  Specifically, when we see a reference to FITYPE
  # we automatically assume an FSTYPE clause followed and we pull it from the list of items
  # in situ.
  # Other times commas embedded in paths are escaped with a backslash.  As long as the path
  # being constructed ends in a backslash, replace the comma and pull the next item from the
  # list.
  my @paths;
  if (defined($pathListCount)) {
    for my $i (1..$pathListCount) {
      my $p = shift @rest;
      while (($p =~ /\\$/) && ($p !~ /[^\\]\\\\$/)) {
	$p .= ",".shift @rest;
      }
      push @paths, $p;
    }
  }
  $job->{FILES} = \@paths;

  #
  # March through the list of tries and for each of them, extract the progress
  # scenario.  Need to think about a way to do delta's: remember last try and
  # progress indices perhaps?
  if (defined(my $tryCount = shift @rest)) {
    for my $i (1..$tryCount) {
      my ($tryPID, $tryStUnit, $tryServer,
	  $tryStarted, $tryElapsed, $tryEnded,
	  $tryStatus, $description, $tryProgressCount, @tryRest) = @rest;

      
      my $backupID = $job->client."_".$tryStarted;
      my $image = $job->image($backupID);
      $image->class($job->class);
      $image->schedule($job->schedule);
      $image->client($job->client);

      $elapsed = $tryElapsed;
      for my $t (1..$tryProgressCount) {
	my $tryProgress = shift @tryRest;

	if ($tryProgress =~ /\.\.\./) {
	  next;
	}

	my ($dt, $tm, $AMPM, $dash, $msg);
	if ($tryProgress =~ /[\s][AP]M[\s]/) {
	  ($dt, $tm, $AMPM, $dash, $msg) = split(/[\s]+/, $tryProgress, 5);
	}
	else {
	  ($dt, $tm, $dash, $msg) = split(/[\s]+/, $tryProgress, 4);
          $AMPM = "";
	}
	my $mm;  my $dd;  my $yyyy;
	if ($dt =~ /([\d]{1,2})\/([\d]{1,2})\/([\d]{4})/) {
	  $yyyy = $3;
	}
	elsif ($dt =~ /([\d]{1,2})\/([\d]{1,2})\/([\d]{2})/) {
	  $yyyy = $3 + 2000;
	}
	else {
	  print STDERR "No match on date during paring of job ".$job->id." for \"$dt\" from:\n$tryProgress\?\n";
	  exit 0;
	}
	$mm = $1;  $dd = $2;

	$tm =~ /([\d]{1,2}):([\d]{1,2}):([\s\d]{0,2})/;
	my $h = $1;  my $m = $2;  my $s = (($3 eq "") ? 0 : $3);
	if (($AMPM =~ /PM/) && ($h != 12)) {
	  $h += 12;
	}
	elsif (($AMPM =~ /AM/) && ($h == 12)) {
	  $h -= 12;
	}
#print STDERR "$dt and $tm became $s, $m, $h, $d, $mm and $yyyy\n";
	my $now = timelocal($s, $m, $h, $dd, $mm-1, $yyyy);

	#
	# Augment $msg string with more pieces as long as uncover embedded quoted commas
	while (($msg =~ /\\$/) && ($msg !~ /[^\\]\\\\$/)) {
	  $msg .= ",".shift @tryRest;
	}

	if ($msg =~ /connecting/) {
	  $job->startConnecting($now);
	}
	elsif ($msg =~ /connected/) {
	  $job->connected($now);
	}
	elsif ($msg =~ /^using ([\S]+)/) {
	}
	elsif ($msg =~ /^mounting ([\S]+)/) {
	  my $volume = NBU::Media->new($1);
	  $job->startMounting($now, $volume);
	}
	elsif ($msg =~ /mounted/) {
	  # unfortunately this data stream does not tell us which drive :-(
	  $job->mounted($now);
	}
	elsif ($msg =~ /positioning ([\S]+) to file ([\S]+)/) {
	  my $volume = NBU::Media->new($1);
	  my $fileNumber = $2;
	  if (!defined($job->mount)) {
	    $job->startMounting($now, $volume);
	    $job->mounted($now);
	  }
	  $job->startPositioning($fileNumber, $now);
	}
	elsif ($msg =~ /positioned/) {
	  $job->positioned($now);
	}
	elsif ($msg =~ /begin writing/) {
	  $job->startWriting($now);
	}
	elsif ($msg =~ /end writing/) {
	  $job->doneWriting($now);
	}
	elsif ($msg =~ /begin reading/) { }
	elsif ($msg =~ /end reading/) { }
	#
	elsif ($msg =~ /Critical bp/) {  }
	elsif ($msg =~ /Critical vlt/) {  }
	elsif ($msg =~ /Error bp/) {  }
	elsif ($msg =~ /Error vlt/) {  }
	elsif ($msg =~ /Info bp/) {  }
	elsif ($msg =~ /Info vlt/) {  }
	elsif ($msg =~ /Info nbdelete/) {  }
	elsif ($msg =~ /Warning bp/) {  }
	elsif ($msg =~ /Warning vlt/) {  }
	elsif ($msg =~ /begin Catalog/) {  }
	elsif ($msg =~ /begin Eject and Report/) {  }
	elsif ($msg =~ /begin Restore/) {  }
	elsif ($msg =~ /begin Choosing Images/) {  }
	elsif ($msg =~ /begin Duplicating Images/) {  }
	elsif ($msg =~ /begin Duplicate/) {  }
	elsif ($msg =~ /begin Import/) {  }
	elsif ($msg =~ /end Catalog/) {  }
	elsif ($msg =~ /end Eject and Report/) {  }
	elsif ($msg =~ /end Restore/) {  }
	elsif ($msg =~ /end Duplicate/) {  }
	elsif ($msg =~ /end Choosing Images/) {  }
	elsif ($msg =~ /end Duplicating Images/) {  }
	elsif ($msg =~ /end Import/) {  }
	elsif ($msg =~ /images required/) {  }
	elsif ($msg =~ /media/) {  }
	elsif ($msg =~ /started process/) {  }
	elsif ($msg =~ /restarted as job/) {  }
	elsif ($msg =~ /restoring image ([\S]+)/) {  }
	elsif ($msg =~ /restored image ([\S]+) -/) {  }
	#
	# Additions as of NBU 6.5
	elsif ($msg =~ /Error nbjm/) {  }
	elsif ($msg =~ /begin  operation/) { }		# Extra space there on purpose: NB bug?
	elsif ($msg =~ /end  operation/) { }		# Extra space there on purpose: NB bug?
	elsif ($msg =~ /begin operation/) { }
	elsif ($msg =~ /end operation/) { }
	elsif ($msg =~ /requesting resource/) { }
	elsif ($msg =~ /granted resource/) { }
	elsif ($msg =~ /writing to path/) { }
	elsif ($msg =~ /ended process ([\d]+) \(([\d]+)\)/) { }

	elsif ($msg =~ /snapshot client is ([\S]+) - snapshot method is ([\S]+)/) {
	  my $clientName = $1;
	  my $snapShotMethod = $2;
	}
	elsif ($msg =~ /collecting BMR information/) {  }
	elsif ($msg =~ /transferring BMR information to the master server/) {  }
	elsif ($msg =~ /BMR information transfer successful/) {  }

	elsif ($msg =~ /path is /) {  }
	elsif ($msg =~ /estimated ([-]?[\d]+) kbytes needed/) {  }
	elsif ($msg =~ /([\d]+) KB written/) { $KBWritten += $1; }
	elsif ($msg =~ /number of files written/) {  }
	elsif ($msg =~ /waiting for vault session ID lock/) {  }
	elsif ($msg =~ /vault session ID lock acquired/) {  }
	elsif ($msg =~ /vault session ID lock released/) {  }
	elsif ($msg =~ /waiting for vault duplication lock/) {  }
	elsif ($msg =~ /vault duplication lock acquired/) {  }
	elsif ($msg =~ /vault duplication lock released/) {  }
	elsif ($msg =~ /waiting for vault assign slot lock/) {  }
	elsif ($msg =~ /vault assign slot lock acquired/) {  }
	elsif ($msg =~ /vault assign slot lock released/) {  }
	elsif ($msg =~ /vault catalog backup started using policy "(.*)" and schedule "(.*)"/) {  }
	elsif ($msg =~ /waiting for vault assign slot lock/) {  }
	elsif ($msg =~ /vault assign slot lock acquired/) {  }
	elsif ($msg =~ /vault assign slot lock released/) {  }
	elsif ($msg =~ /waiting for vault eject lock/) {  }
	elsif ($msg =~ /vault eject lock acquired/) {  }
	elsif ($msg =~ /vault eject lock released/) {  }
	elsif ($msg =~ /vault job lock released/) {  }
	elsif ($msg =~ /vault duplication started - batch ([\d]+) of ([\d]+) for ([\d]+) images/) {  }
	elsif ($msg =~ /vault duplication batch ([\d]+) of ([\d]+) completed.  ([\d]+) o. ([\d]+) images duplicated/) {  }
	elsif ($msg =~ /vault catalog backup skipped/) {  }
	else {
print "$jobID\:$i\: $msg\n";
	}
      }
      my $tryKBytesWritten = $KBytesWritten = shift @tryRest;
      my $tryFilesWritten = $filesWritten = shift @tryRest;

      @rest = @tryRest;
    }
  }

if (!defined($job->state)) {
  print STDERR "Job ".$job->id." has no state?\n";
}
  if ($job->state eq "active") {
    my $lastSize = $job->{SIZE} if (defined($job->{SIZE}));
    my $lastElapsed = $job->{ELAPSED} if (defined($job->{ELAPSED}));

    $job->{CURRENTFILE} = $currentFile;

    $KBytesWritten = $KBWritten if ($KBWritten > 0);

    my $size = $job->{SIZE} = $KBytesWritten if ($KBytesWritten ne "");
    $job->{FILECOUNT} = $filesWritten if ($filesWritten ne "");

    $job->{OPERATION} = $operation if ($operation ne "");
    $job->{ELAPSED} = $elapsed if ($elapsed ne "");

    if (($job->type eq "Backup") || ($job->type eq "Restore")) {
      if ((defined($lastSize) && defined($size)) && (defined($lastElapsed) && ($elapsed ne ""))) {
	$job->{ISPEED} = ($size - $lastSize) / ($elapsed - $lastElapsed);
      }
    }
  }
  elsif ($job->state eq "done") {
    $job->{SIZE} = $KBytesWritten if ($KBytesWritten ne "");
    $job->{FILECOUNT} = $filesWritten if ($filesWritten ne "");
    $job->stop($ended, $status);
    $job->{ELAPSED} = $elapsed if ($elapsed ne "");
  }
  
  return $job;
}

sub byID {
  my $Class = shift;

  if (@_) {
    my $id = shift;

    return $jobs{$id} if (exists($jobs{$id}));
  }
  return undef;
}

#
# Returns the last job associated with the argument PID.
sub byPID {
  my $Class = shift;
  my $pid = shift;

  if (my $pidArray = $pids{$pid}) {
    my $job = @$pidArray[@$pidArray - 1];
    if (!defined($job)) {
      print STDERR "Strange doings with pid $pid\n";
    }
    return $job;
  }
  return undef;
} 

#
# Some jobs turn out to be worse than useless
sub forget {
  my $self = shift;

  if (my $pidArray = $pids{$self->pid}) {
    my @newArray;
    foreach my $job (@$pidArray) {
      push @newArray, $job unless ($job eq $self);
    }
    if (@newArray < 0) {
      delete $pids{$self->pid};
    }
    else {
      $pids{$self->pid} = \@newArray;
    }
  }
  if ($self->id) {
    delete $jobs{$self->id};
  }

  return $self;
}

sub pid {
  my $self = shift;

  return $self->{PID};
}

sub id {
  my $self = shift;

  if (@_) {
    $jobs{$self->{ID} = shift} = $self;
  }
  return $self->{ID};
}

sub mediaServer {
  my $self = shift;

  if (@_) {
    $self->{MEDIASERVER} = shift;
  }
  return $self->{MEDIASERVER};
}

#
# A job's backup ID really identifies the image that job wrote
# out to the volume(s).
sub backupID {
  my $self = shift;

  if (@_) {
    my $image = NBU::Image->new(shift);
    $self->{IMAGE} = $image;
  }

  return $self->{IMAGE};
}

sub image {
  my $self = shift;

  if (@_) {
    my $backupid = shift;
    my $image;
    if (!defined($image = $self->{IMAGE}) || ($image->id ne $backupid)) {
      $image = NBU::Image->new($backupid);
      $self->{IMAGE} = $image;
    }
    $self->{IMAGE} = $image;
  }

  return $self->{IMAGE};
}

#
sub client {
  my $self = shift;

  if (@_) {
    $self->{CLIENT} = shift;
  }

  if (!defined($self->{CLIENT}) && defined($self->{IMAGE})) {
    $self->{CLIENT} = $self->image->client;
  }

  return $self->{CLIENT};
}

#
# written.
sub class {
  my $self = shift;

  if (@_) {
    $self->{CLASS} = shift;
  }

  if (!defined($self->{CLASS}) && defined($self->{IMAGE})) {
    $self->{CLASS} = $self->image->class;
  }

  return $self->{CLASS};
}
sub schedule {
  my $self = shift;

  return $self->{SCHEDULE};
}

sub start {
  my $self = shift;

  if (@_) {
    $self->{START} = shift;
  }
  return $self->{START};
}

sub stop {
  my $self = shift;

  if (@_) {
    $self->{STOP} = shift;
    if ($self->mount) {
      $self->mount->unmount($self->{STOP});
    }
    $self->{STATUSCODE} = shift;
    $self->{ELAPSED} = undef;
  }
  return $self->{STOP};
}

sub status {
  my $self = shift;

  return $self->{STATUSCODE};
}

my %successCodes = (
  0 => 1,
  1 => 1,
);
sub success {
  my $self = shift;

  return 1 if ($self->state ne "done");
  return exists($successCodes{$self->{STATUSCODE}});
}

sub errors {
  my $self = shift;
  my @errorList;

  my $window = "";
  $window .= "-d ".NBU->date($self->start)
	      ." -e ".NBU->date($self->stop + 60)
	  if (NBU->me->NBUVersion ne "3.2.0");
  unless (!defined($self->status) || !$self->status) {
    my $pipe = NBU->cmd("bperror -jobid ".$self->id." $window -problems");
    while (<$pipe>) {
      chop;
      my ($tm, $version, $type, $severity, $serverName, $jobID, $jobGroupID, $u, $clientName, $who, $msg) =
	split(/[\s]+/, $_, 11);
      $msg =~ s/from client ${clientName}: (WRN|ERR|INF) - //;
      my %e = (
	tod => $tm,
	severity => $severity,
	who => $who,
	message => $msg,
      );
      push @errorList, \%e;
    }
  }
  return (@errorList);
}

sub elapsedTime {
  my $self = shift;

  if ($self->{ELAPSED}) {
    return $self->{ELAPSED};
  }
  else {
    my $stop = $self->stop;
    $stop = time() if (!$stop);

    return ($stop - $self->start);
  }
}

sub storageUnit {
  my $self = shift;

  if (@_) {
    $self->{STUNIT} = shift;
  }
  return $self->{STUNIT};
}

sub mountList {
  my $self = shift;
  my $ml = $self->{MOUNTLIST};

  return %$ml;
}

sub pushState {
  my $self = shift;
  my $newState = shift;
  my $tm = shift;

  my $states = $self->{STATES};
  my $times = $self->{TIMES};
  if (!$states) {
    $states = $self->{STATES} = [];
    $times = $self->{TIMES} = [];
  }
  #
  # If the current state is the same as the last state we replace
  # it rather than layering it.
  elsif (defined(my $lastState = pop @$states)) {
    if ($lastState eq $newState) {
      $tm = pop @$times;
    }
    else {
      push @$states, $lastState;
    }
  }
  push @$states, $newState;
  push @$times, $tm;
  $self->{STARTOP} = $tm;
}

sub popState {
  my $self = shift;
  my $tm = shift;
  my $states = $self->{STATES};
  my $times = $self->{TIMES};

  if (defined(my $lastState = pop @$states)) {
    $self->{$lastState} += ($tm - $self->{STARTOP});
    $self->{STARTOP} = pop @$times;
  }
}

sub volume {
  my $self = shift;

  return $self->{SELECTED};
}

sub startConnecting {
  my $self = shift;
  my $tm = shift;

  $self->pushState('CON', $tm);
}

sub connected {
  my $self = shift;
  my $tm = shift;

  $self->popState($tm);
}

sub fileOpened {
  my $self = shift;
  my $tm = shift;
  my $file = shift;


  my $fileListR = $self->{FILELIST};
  $$fileListR{$tm} = $file;

  my $mount = NBU::Mount->new($self, $file, $self->storageUnit->path, $tm);

  my $mountListR = $self->{MOUNTLIST};
  $$mountListR{$tm} = $mount;

  return $self->mount($mount);
}


sub startMounting {
  my $self = shift;
  my $tm = shift;
  my $volume = shift;

  $self->pushState('MNT', $tm);

  $self->{SELECTED} = $volume;
  $volume->selected($tm);

  return $self;
}

sub mounted {
  my $self = shift;
  my $tm = shift;
  my $drive = shift;

  if (defined(my $volume = $self->{SELECTED})) {
    $self->popState($tm);

    my $mount = NBU::Mount->new($self, $volume, $drive, $tm);

    my $mountListR = $self->{MOUNTLIST};
    $$mountListR{$tm} = $mount;

    return $self->mount($mount);
  }
  else {
    return undef;
  }
}

sub startPositioning {
  my $self = shift;
  my $fileNumber = shift;
  my $tm = shift;

  my $mount = $self->mount;
  if (defined($mount)) {
    $self->pushState('POS', $tm);
#    $self->mount->startPositioning($fileNumber, $tm);
  }
  return $mount;
}

sub positioned {
  my $self = shift;
  my $tm = shift;

  my $mount = $self->mount;
  if (defined($mount)) {
    $self->popState($tm);
#    $self->mount->positioned($tm);
  }
  return $mount;
}

sub startWriting {
  my $self = shift;
  my $tm = shift;

  $self->pushState('WRI', $tm);
  $self->{FRAGMENTCOUNTER}++;
}

sub doneWriting {
  my $self = shift;
  my $tm = shift;

  $self->popState($tm);
}

sub type {
  my $self = shift;

  if (@_) {
    $self->{TYPE} = shift;
  }

  return $self->{TYPE};
}

my @jobStates = ("queued", "active", "re-queued", "done", undef, "incomplete");
sub state {
  my $self = shift;

  if (@_) {
    $self->{STATE} = shift;
  }
  return $jobStates[$self->{STATE}];
}

sub active {
  my $self = shift;

  return ($self->{STATE} == 1);
}

sub done {
  my $self = shift;

  return (($self->{STATE} == 3) || ($self->{STATE} == 5));
}

sub queued {
  my $self = shift;

  return (($self->{STATE} == 0) || ($self->{STATE} == 2));
}

sub busy {
  my $self = shift;

  if (!$self->{STARTOP}) {
#print STDERR "Job ".$self->id." has no start op?\n";
    return undef;
  }
  else  {
    return $asOf - $self->{STARTOP};
  }
}

sub files {
  my $self = shift;

  if (defined(my $fileListR = $self->{FILES})) {
    return@$fileListR;
  }
  else {
    return ();
  }
}

my %opCodes = (
  -1 => '---',
  25 => 'WAI',
  2 =>  'CON',
  26 => 'CON',
  0  => ' ? ',
  27 => 'MNT',
  29 => 'POS',
  3  => 'WRI',
  35 => 'WRI',
);

sub operation {
  my $self = shift;

  return undef if ($self->state ne "active");

  if (@_) {
    my $opCode = shift;
    $self->{OPERATION} = $opCode unless ($opCode == 0);
  }
  my $opCode;
  if (!defined($self->{OPERATION})) {
    return "---";
  }
  elsif (!defined($opCode = $opCodes{$self->{OPERATION}})) {
    $opCode = sprintf("%3d", $self->{OPERATION});
  }

  return $opCode;
}

sub currentFile {
  my $self = shift;

  return ($self->state eq "active") ? $self->{CURRENTFILE} : undef;
}

sub try {
  my $self = shift;

  if (@_) {
    my $try = shift;

    if ($self->{TRY} && ($self->{TRY} != $try)) {
      # Maybe call somebody that we're on our next try?
    }
    $self->{TRY} = $try;
  }

  return $self->{TRY};
}

sub mount {
  my $self = shift;

  if (@_) {
    my $newMount = shift;
    if (defined(my $currentMount = $self->{MOUNT})) {
      $self->{MOUNT} = undef;
      if (defined($newMount)) {
	$currentMount->unmount($newMount->start);
      }
      else {
print STDERR "unmounting without unmount time!\n" if (!$currentMount->stop);
      }
    }
    $self->{MOUNT} = $newMount;
  }
  return $self->{MOUNT};
}

sub read {
  my $self = shift;
  my ($fragment, $size, $speed) = @_;

  $self->{SIZE} += $size;
  $self->mount->read($fragment, $size, $speed);

  return $self;
}

sub write {
  my $self = shift;
  my ($fragment, $size, $speed) = @_;

  $self->{SIZE} += $size;
  $self->mount->write($fragment, $size, $speed);

  return $self;
}

sub networkReadStats {
  my $self = shift;

  if (@_) {
    my ($noBuffer, $count) = @_;

    $self->{NOEMPTYBUFFER} = $noBuffer;
    $self->{NOEMPTYDELAY} = $count;
  }

  return ($self->{NOEMPTYBUFFER}, $self->{NOEMPTYDELAY},
	$self->{NOEMPTYDELAY} * $self->{EMPTYWAIT});
}

sub driveWriteStats {
  my $self = shift;

  if (@_) {
    my ($noBuffer, $count) = @_;

    $self->{NOFULLBUFFER} = $noBuffer;
    $self->{NOFULLDELAY} = $count;
  }

  return ($self->{NOFULLBUFFER}, $self->{NOFULLDELAY},
	$self->{NOFULLDELAY} * $self->{FULLWAIT});
}

sub dataBufferSize {
  my $self = shift;

  if (@_) {
    my ($size) = @_;

    $self->{BUFFERSIZE} = $size;
  }

  return ($self->{BUFFERSIZE});
}

sub dataBufferCount {
  my $self = shift;

  if (@_) {
    my ($count) = @_;

    $self->{BUFFERCOUNT} = $count;
  }

  return ($self->{BUFFERCOUNT});
}

sub delayCycles {
  my $self = shift;

  if (@_) {
    my ($emptyWaitTime, $fullWaitTime) = @_;

    $self->{EMPTYWAIT} = $emptyWaitTime / 1000;
    $self->{FULLWAIT} = $fullWaitTime / 1000;
  }

  return ($self->{EMPTYWAIT}, $self->{FULLWAIT});
}

sub dataWritten {
  my $self = shift;

  return $self->{SIZE};
}

sub speed {
  my $self = shift;

  if ($self->success) {
    return ($self->dataWritten / $self->elapsedTime);
  }
  return undef;
}

sub ispeed {
  my $self = shift;

  return $self->speed if ($self->state eq "done");
  return $self->{ISPEED};
}

sub filesWritten {
  my $self = shift;

  return $self->{FILECOUNT};
}

sub printHeader {
  my $self = shift;

  my $pid = $self->pid;
  my $id = $self->id;
  print "Process $pid manages job $id\n";

  return $self;
}

#
# The business and system methods are here to facilitate job reporting
# that is business system oriented rather than a simple backup stream
# accounting line-item listing
sub business {
  my $self = shift;

  if (@_) {
    $self->{BUSINESS} = shift;
  }
  return $self->{BUSINESS};
}

sub system {
  my $self = shift;

  if (@_) {
    $self->{SYSTEM} = shift;
  }
  return $self->{SYSTEM};
}

1;

__END__

=head1 NAME

NBU::Job - Interface to NetBackup Job manipulation and reporting

=head1 SUPPORTED PLATFORMS

=over 4

=item * 

Solaris

=item * 

Windows/NT

=back

=head1 SYNOPSIS

    To come...

=head1 DESCRIPTION

This module provides support for ...

=head1 SEE ALSO

=over 4

=item L<NBU::Media|NBU::Media>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002-2007 Paul Winkeler

=cut

