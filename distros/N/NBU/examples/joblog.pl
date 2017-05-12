#!/usr/local/bin/perl

use strict;
use Getopt::Std;
use Time::Local;

use NBU;

my %opts;
getopts('dutbseiDjmfc:C:a:p:n:l:o:', \%opts);

#
# The -a <yyyymmdd> option controls the starting date for the log file analysis
# process.  If absent, today's date is assumed to be of interest
my $period = 1;
my $mm;  my $dd;  my $yyyy;
if (!$opts{'a'}) {
  my ($s, $m, $h, $mday, $mon, $year, $wday, $yday, $isdst) = localtime();
  $year += 1900;
  $mm = $mon + 1;
  $dd = $mday;
  $yyyy = $year;

}
else {
  $opts{'a'} =~ /^([\d]{4})([\d]{2})([\d]{2})$/;
  if ($opts{'p'}) {
    $period = $opts{'p'};
  }
  $mm = $2;
  $dd = $3;
  $yyyy = $1;
}

#
# The parseTime function and its static companions $lastParsedTime and
# $midnight are used to translate the time-stamps from the input log file into
# un*x timestamps
my $lastParsedTime;
my $midnight;
sub parseTime {
  my $line = shift;

  $line =~ /^(\d\d):(\d\d):(\d\d)/;
  my $hr = $1;  my $min = $2;  my $sec = $3;
  my $tm = $midnight + $sec + ($min + ($hr * 60)) * 60;

  if ($tm < $lastParsedTime) {
    $tm += (24 * 60 * 60);
    $midnight += (24 * 60 * 60);
  }

  return $lastParsedTime = $tm;
}

#
# Delta un*x timestamps are converted into human readable format by this
# function, dispInterval
sub dispInterval {
  my $i = shift;

  my $seconds = $i % 60;
  my $i = int($i / 60);
  my $minutes = $i % 60;
  my $hours = int($i / 60);

  my $fmt = sprintf("%02d", $seconds);
  $fmt = sprintf("%02d:", $minutes).$fmt if ($minutes || $hours);
  $fmt = sprintf("%02d:", $hours).$fmt if ($hours);
  return $fmt;
}

#
# Symantec (formerly Veritas) succumbed to changing the log file names based
# on the host OS.  The -o option allows one to specify which OS's logfiles
# we are dealing with and thus switch name patterns
my $logFilePattern = "log.%s";
if ($opts{'o'} =~ /indow/) {
  $logFilePattern = "%s.log";
}

#
# Without further reference to a location for the log files we assume the
# standard lcoation for the OS type.  The log file directory can be overriden
# with the -l option.
my $logPath = "/opt/openv/netbackup/logs";
my $bptmLogPath = $logPath."/bptm";
if ($opts{'l'}) {
  $bptmLogPath = $opts{'l'};
}

my @monthDays = ( 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );

my $asOf;
my $daysLeft = $period;
while ($daysLeft--) {
  my $mmddyy = sprintf("%02d%02d%02d", $mm, $dd, ($yyyy % 100));
  my $logFile = $bptmLogPath.sprintf($logFilePattern, $mmddyy);

  if (!open(LOG, "<$logFile")) {
    print STDERR "Could not open $logFile\n";
    exit;
  }
  if ($opts{'d'}) {
    print STDERR "Processing data for $yyyy$mm$dd\n";
  }

  $midnight = timelocal(0, 0, 0, $dd, $mm-1, $yyyy);
  $lastParsedTime = undef;
  $asOf = $midnight unless(defined($asOf));

  while (<LOG>) {
    #
    if (/\[([\d\.]+)\] <2> bptm: INITIATING(|[\s]*\(.+\)): -([\S]+)/) {
      my $pid = $1;
      my $flags = $2;
      my $option = $3;
      my $job;

      #
      # "w" jobs are your basic archive operations
      # Setting the job's backupID is really short hand for allocating
      # an image (which it therefore promptly returns) and the remaining
      # attributes are part of the image, not the job 
      if ($option eq "w") {
        /-jobid ([\d]+) /;  {
	  my $id = $1;

	  #
	  # Check to see if a job with this id already exists; then we might
	  # be the child (reader) process and no new job needs be created.
	  if (my $parent = NBU::Job->byID($id)) {
	    if ($parent->readerPID eq $pid) {
	      next;
	    }
	    else {
	      $id = $id.".1";
	    }
	  }
	  $job = NBU::Job->new($pid);
	  $job->start(parseTime($_));
	  $job->id($id);
          /-stunit ([\S]+) /;  $job->storageUnit($1);
          /-mediasvr ([\S]+) /;  $job->mediaServer(NBU::Host->new($1));
          /-b ([\S]+) /;  my $image = $job->image($1);
          /-cl ([\S]+) /;  $image->class(NBU::Class->new($1));
          /-c ([\S]+) /;  $image->client(NBU::Host->new($1));
	}
      }
      # when handed a "pid" we will likely be involved in a restore
      elsif ($option eq "pid") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      # deleting images
      elsif ($option eq "d") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      # some jobs operate on a single media
      elsif ($option eq "ev") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "count") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "countmedia") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "delete_expired") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "U") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "load") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "unload") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "change_exp_date") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      elsif ($option eq "mlist") {
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
      else {
print STDERR "Unknown job option $option\n";
	$job = NBU::Job->new($pid);
	$job->start(parseTime($_));
      }
    }

    if (/\[([\d\.]+)\] <2> write_backup: backup child process is pid ([\d\.]+)/) {
      my $job = NBU::Job->byPID($1);
      next if (!defined($job));

      $job->readerPID($2);
    }

    if (/\[([\d\.]+)\] <2> select_media: selected media id ([\S]+) for backup/) {
      my $job = NBU::Job->byPID($1);

      next if (!defined($job));

      my $volume = NBU::Media->byID($2);

      $job->startMounting(parseTime($_), $volume);
    }
    if (/\[([\d\.]+)\] <2> write_backup: media id ([\S]+) mounted on drive index ([\d]+)/) {
      my $job = NBU::Job->byPID($1);

      next if (!defined($job));

      my $mediaID = $2;
      my $drive = NBU::Drive->byIndex($3, $job->mediaServer);

      $job->mounted(parseTime($_), $drive);
    }

    if (/\[([\d\.]+)\] <2> io_init: using ([\d]+) data buffer size/) {
      my $job = NBU::Job->byPID($1);

      if (!defined($job)) {
        print STDERR "No job initiated by PID $1?\n";
        next
      }

      $job->dataBufferSize($2);
    }
    if (/\[([\d\.]+)\] <2> io_init: using ([\d]+) data buffers/) {
      my $job = NBU::Job->byPID($1);

      next if (!defined($job));
      $job->dataBufferCount($2);
    }
    if (/\[([\d\.]+)\] <2> io_init: child delay = ([\d]+), parent delay = ([\d]+) \((milliseconds)\)/) {
      my $job = NBU::Job->byPID($1);

      next if (!defined($job));
      $job->delayCycles($1, $2);
    }

    if (/\[([\d\.]+)\] <4> write_backup: successfully wrote/) {
      my $job = NBU::Job->byPID($1);

      next if (!defined($job));

      /fragment ([\d]+), ([\d]+) Kbytes at ([\d]+\.[\d]+)/;
      my $fragment = $1;
      my $size = $2;
      my $speed = $3;

      $job->write($fragment, $size, $speed);
    }
    if (/\[([\d\.]+)\] <2> fill_buffer: \[([\d]+)\] socket is closed, waited for empty buffer ([\d]+) times, delayed ([\d]+) times, read ([\d]+) bytes/) {
      my $job = NBU::Job->byPID($1);

      if (!defined($job)) {
	print STDERR "No job for fill_buffer stats, PID: $1\n";
	next;
      }
      $job->networkReadStats($3, $4);
    }
    if (/\[([\d\.]+)\] <2> write_data: waited for full buffer ([\d]+) times, delayed ([\d]+) times/) {

      my $job = NBU::Job->byPID($1);
      next if (!defined($job));

      $job->driveWriteStats($2, $3);
    }
    if (/\[([\d\.]+)\] <2> .* tpunmount.ing .*tpreq\/([\S]+)/) {
      if (my $media = NBU::Media->byID($2)) {
        $media->unmount(parseTime($_));
      }
    }
    if (/\[([\d\.]+)\] <2> (bptm|catch_signal|mpx_terminate_exit|mm_terminate): EXITING with status ([\d]+)/) {
      my $job = NBU::Job->byPID($1);

      if (!$job) {
print STDERR "EXITING non existent job from pid \"$1\"\n";
        next;
      }

      #
      # Jobs that never had an id associated with them are not of interest
      if (!defined($job->id)) {
        $job->forget;
      }
      else {
        my $result = $3;
        $job->stop(parseTime($_), $result);
      }
    }
  }
  $dd += 1;
  if ($monthDays[$mm] < $dd) {
    $mm += 1;
    $dd = 1;
  }
}

my @list = NBU::Job->list;
@list = sort { $a->start <=> $b->start } @list;

my $j;
my $jobCounter = 0;
my $firstJob;  my $lastJob;
my $overallDataWritten = 0;  my $overallElapsedTime = 0;
my %volumesUsed;
foreach $j (@list) {
 my $totalWriteTime = 0;
 my $totalKbytes = 0;

if (!$j->id) {
    print STDERR "Process was not eliminated? ".$j->pid."\n";
    next;
}

  if ($opts{'e'}) {
    next unless ($j->status);
  }

  if ($opts{'c'}) {
    my $classPattern = $opts{'c'};
    next unless ($j->class->name =~ /$classPattern/);
  }
  if ($opts{'C'}) {
    my $clientPattern = $opts{'C'};
    next unless ($j->client->name =~ /$clientPattern/);
  }

  $firstJob = $j if (!defined($firstJob));

  $jobCounter++;

  my $jid = $j->id;
  if ($opts{'j'}) {
    my $tmb = sprintf("%.2f", $j->dataWritten / 1024);  my $tunits = "MB";
    if ($tmb > 1024) {
      $tmb = sprintf("%.2f", $j->dataWritten / 1024 / 1024);  $tunits = "GB";
    }
    my $sp = sprintf("%.2f", ($j->dataWritten / $j->elapsedTime / 1024));
    print "J:$jid".":".sprintf("%5s", $j->pid).":".$j->class->name." ".localtime($j->start);
    if (defined($j->status)) {
      print " ${tmb}${tunits} in ".dispInterval($j->elapsedTime)." (${sp}MB/s)";
      print " status ".$j->status."\n";
    }
    else {
      print " still running\n";
    }
    if ($opts{'b'}) {
      my ($s, $m, $h, $dd, $mon, $year, $wday, $yday, $isdst) = localtime($j->start);
      my $mm = $mon + 1;
      my $yy = sprintf("%02d", ($year + 1900) % 100);
      print "sudo /opt/openv/netbackup/bin/admincmd/bpflist -t ANY -option GET_ALL_FILES".
								" -client ".$j->client->name.
                " -backupid ".$j->image->id.
                " -d ${mm}/${dd}/${yy}"."\n";
    }
 }

  my %mountList = $j->mountList;

  foreach my $tm (sort (keys %mountList)) {
    my $mount = $mountList{$tm};
    my $volume = $mount->volume;
    my $mediaID = $volume->id;

    $volumesUsed{$mediaID} += 1;

    if ($opts{'m'}) {
      my $wt = sprintf("%.2f", $mount->writeTime);
      my $mb = sprintf("%.2f", ($mount->dataWritten / 1024));  my $units = "MB";
      if ($mb > 1024) {
        $mb = sprintf("%.2f", ($mount->dataWritten / 1024 / 1024));  $units = "GB";
      }
      my $sp = 0;
      if ($mount->writeTime) {
        $sp = sprintf("%.2f", ($mount->dataWritten / $mount->writeTime / 1024));
      }
      print "M:${jid}:${mediaID}".sprintf(" in %2u ", $mount->drive->id).localtime($mount->start).
            " ${mb}${units} over ".dispInterval($wt).
            " at ${sp}MB/s\n";
    }

    $totalWriteTime += $mount->writeTime;
  }

  if ($opts{'j'}) {
    if ($opts{'s'} && defined($j->status)) {
      my $overHeadLength = sprintf("%.2f", ($j->elapsedTime - $totalWriteTime));
      my $overHead = sprintf("%.2f", ($overHeadLength * 100)/ $j->elapsedTime);
      my $overHeadTime = dispInterval(sprintf("%u", $overHeadLength));

      my ($noFullBuffer, $fullDelayCount, $fullDelay) = $j->driveWriteStats();
      my ($noEmptyBuffer, $emptyDelayCount, $emptyDelay) = $j->networkReadStats();
      if ($emptyDelayCount && $totalWriteTime) {
	my $overHead = sprintf("%.2f", ($emptyDelay * 100)/ $totalWriteTime);
	print "J:${jid}:delays reading $emptyDelayCount cycles for ".dispInterval($emptyDelay)." or $overHead\%\n"
      }
      if ($fullDelayCount && $totalWriteTime) {
	my $overHead = sprintf("%.2f", ($fullDelay * 100)/ $totalWriteTime);
	print "J:${jid}:delays writing $fullDelayCount cycles for ".dispInterval($fullDelay)." or $overHead\%\n"
      }
      print "J:${jid}:ended ".localtime($j->stop)." overhead ${overHeadTime} ($overHead\%)\n";
    }
  }
  $lastJob = $j;

  $overallDataWritten += $j->dataWritten;
  $overallElapsedTime += $j->elapsedTime;
}

if (!$opts{'D'} && !$opts{'u'}) {
  my $overallVolumesUsed = (keys %volumesUsed);
  $overallDataWritten = sprintf("%.2f", ($overallDataWritten / 1024 / 1024));
  print "$jobCounter jobs wrote ${overallDataWritten}GB over ".
    dispInterval($overallElapsedTime).
    " to $overallVolumesUsed distinct volumes\n";
}

#print "Jobs ran from ".localtime($firstJob->start)." until ".localtime($lastJob->stop)."\n";

if ($opts{'D'}) {
  my @dl = NBU::Drive->pool;

  @dl = sort { $a->id <=> $b->id} (@dl);

  if (!$opts{'i'}) {
    foreach my $d (@dl) {
      my $header = "Drive ".$d->id."\n";
      my $usage = $d->usage;
      @$usage = (sort {$$a{START} <=> $$b{START} } @$usage);
      foreach my $use (@$usage) {

        my $mount = $$use{'MOUNT'};
        # Was this mount part of a job from a specific class?
        if ($opts{'c'}) {
          my $p = $opts{'c'};
          my $j = $mount->job;
          next unless ($j->class->name =~ /$p/);
        }
        print $header;  $header = "";
        my $mediaID = $mount->volume->id;
        if ($$use{'STOP'}) {
          my $u = "MB";
          my $dw = sprintf("%.2f", ($mount->dataWritten / 1024));
          if ($dw > 1024) {
            $dw = sprintf("%.2f", $mount->dataWritten / 1024 / 1024);  $u = "GB";
          }
          my $sp = "-.--";
          if ($mount->writeTime) {
            $sp = sprintf("%.2f", ($mount->dataWritten / $mount->writeTime / 1024));
          }
          print localtime($$use{'START'})." ${dw}${u} over ".
                dispInterval($mount->writeTime).
                " at ${sp}MB/s onto $mediaID";
        }
        else {
          print localtime($$use{'START'})." still running onto $mediaID";
        }
	print " from ".$mount->job->client->name."\n";
      }
    }
  }
  else {
    my $idleThreshold = 5 * 60;
    my $endOfPeriod = $asOf + (24 * 60 * 60) * $period;
    foreach my $d (@dl) {
      print "Drive ".$d->id."\n";
      my $usage = $d->usage;
      my $lastUsed = $asOf;
      my $idleTime = 0;
      foreach my $use (@$usage) {
        my $startBusy = $$use{'START'};
        $startBusy = $endOfPeriod if ($startBusy > $endOfPeriod);
        if (($startBusy - $lastUsed) > $idleThreshold) {
          print " idle from ".localtime($lastUsed)." for ";
          print dispInterval($startBusy - $lastUsed)."\n";;
          $idleTime += ($startBusy - $lastUsed);
        }
        $lastUsed = $$use{'STOP'};
        next unless (!$lastUsed || ($lastUsed > $endOfPeriod));
      }
      if ($lastUsed && ($lastUsed < $endOfPeriod)) {
        if (($endOfPeriod - $lastUsed) > $idleThreshold) {
          print " idle from ".localtime($lastUsed)." for ";
          print dispInterval($endOfPeriod - $lastUsed)."\n";
          $idleTime += ($endOfPeriod - $lastUsed);
        }
      }
      print " Total idle time for drive ".$d->id." is ";
      print dispInterval($idleTime).
          sprintf("(%.2f%%)\n", (($idleTime * 100) / (24 * 60 * 60 * $period)));
    }
  }
}

if ($opts{'u'}) {
  my @dl = NBU::Drive->pool;

  @dl = sort { $a->id <=> $b->id} (@dl);

  my $stepSize = 5 * 60;
  my $endOfPeriod = $asOf + (24 * 60 * 60) * $period;

  print "Time,Drive,Busy\n";
  foreach my $d (@dl) {
    my $id = $d->id;
    my $usage = $d->usage;
    @$usage = (sort {$$a{START} <=> $$b{START} } @$usage);

    my $step = $asOf;
    my $use = shift @$usage;
    my $mount = $$use{MOUNT};
    my $job = $mount->job;
    my $du = 1;
    if ($opts{'t'}) {
      $du = sprintf("%.2f", ($mount->speed / 1024));
      $du = 0 if ($job->client->name eq $opts{'n'});
    }

    while ($step < $endOfPeriod) {
      if (!defined($use) || ($step < $$use{START})) {
        print "\"".localtime($step)."\",$id,0\n";
      }
      elsif ($step < $$use{STOP}) {
        print "\"".localtime($step)."\",$id,$du\n";
      }
      else {
        $use = shift @$usage;
        if (defined($use) && defined($mount = $$use{MOUNT})) {
          $du = 1;
          if ($opts{'t'}) {
            $du = sprintf("%.2f", ($mount->speed / 1024));
            $du = 0 if ($job->client->name eq $opts{'n'});
          }
        }
        else {
          $du = 0;
        }
        next;
      }
      $step += $stepSize;
    }
  }
}
