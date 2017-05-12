#!/usr/local/bin/perl -w
#
# Don't be intimidated by the GUI logic.  The juicy, useful bits are in the
# main loop where we call NBU::Drive->updateStatus and NBU::Job->refreshJobs
# to get NBU's data structures synchronized with the real world.
# After that updating the display with information on the active jobs is trivial

use strict;

use Getopt::Std;
use Time::Local;

#
# Download this one from CPAN
use Curses;

my $program = $0;  $program =~ s /^.*\/([^\/]+)$/$1/;

my %opts;
getopts('d?ievlrs:p:M:', \%opts);

if ($opts{'?'}) {
  print STDERR <<EOT;
Usage: nbutop.pl [-v] [-i] [-e] [-r|-l] [-s <interval>] [-p <limit>] [-M <master>]
Options:
  -v       Verbose policy listing
  -i       Instantaneous throughput (instead of cumulative)
  -e       Elapsed time (instead of starting time)

  -r       Replay previous job monitoring session
  -l       Log this monitoring session

  -s       Refresh after <interval> seconds
  -p       Exit after <limit> passes

  -M       Alternate NetBackup <master> server
EOT
  exit;
}

my $interval = 60;
if (defined($opts{'s'})) {
  $interval = $opts{'s'};
}

my $instant = $opts{'i'};
my $elapsed = $opts{'e'};

my $passLimit = $opts{'p'};
my $refreshCounter = 0;

use NBU;
NBU->debug($opts{'d'});

my $master;
if ($opts{'M'}) {
  $master = NBU::Host->new($opts{'M'});
}
else {
  my @masters = NBU->masters;  $master = $masters[0];
}

sub dispInterval {
  my $i = shift;

  my $seconds = $i % 60;  $i = int($i / 60);
  my $minutes = $i % 60;
  my $hours = int($i / 60);

  my $fmt = sprintf("%02d", $seconds);
  $fmt = sprintf("%02d:", $minutes).$fmt;
  $fmt = sprintf("%02d:", $hours).$fmt;
  return $fmt;
}

sub sortByDrive {

  my $aDrive = defined($a->volume) && defined($a->volume->drive) ? $a->volume->drive->id : undef;
  my $bDrive = defined($b->volume) && defined($b->volume->drive) ? $b->volume->drive->id : undef;

  return 1 if (!defined($aDrive));
  return -1 if (!defined($bDrive));
  return ($aDrive <=> $bDrive);
}
sub sortByVolume {

  my $aVolume = defined($a->volume) ? $a->volume->id : undef;
  my $bVolume = defined($b->volume) ? $b->volume->id : undef;

  return 1 if (!defined($aVolume));
  return -1 if (!defined($bVolume));
  return ($aVolume cmp $bVolume);
}
sub sortByThroughput {

  my $aSpeed = $instant ? $a->ispeed : $a->speed;
  my $bSpeed = $instant ? $b->ispeed : $b->speed;

  return 1 if (!defined($aSpeed));
  return -1 if (!defined($bSpeed));


  return ($aSpeed <=> $bSpeed);
}
sub sortBySize {

  my $aSize = defined($a->dataWritten) ? $a->dataWritten : 0;
  my $bSize = defined($b->dataWritten) ? $b->dataWritten : 0;

  return ($bSize <=> $aSize);
}
sub sortByMediaServer {

  return ($a->mediaServer->name cmp $b->mediaServer->name);
}
sub sortByStorageUnit {

  return ($a->storageUnit->label cmp $b->storageUnit->label);
}
sub sortByClient {

  return ($a->client->name cmp $b->client->name);
}
sub sortByID {
  my $result;

  $result = ($b->id <=> $a->id);
  return $result;
}
my $sortOrder = \&sortByID;
my $sortColumn = "JOBID";

sub menu {
  my $answer = shift;
  my $win = shift;

  if ($answer eq 'o') {
    $win->addstr(2, 0, "Order by: (v)olume (d)rive (s)ize (t)hroughput (i)d (c)lient (m)ediaserver?");
    my $o = $win->getch();
    if ($o eq 'd') {
      $sortOrder = \&sortByDrive;
      $sortColumn = "DRIVE";
    }
    elsif ($o eq 'v') {
      $sortOrder = \&sortByVolume;
      $sortColumn = "VOLUME";
    }
    elsif ($o eq 'i') {
      $sortOrder = \&sortByID;
      $sortColumn = "JOBID";
    }
    elsif ($o eq 's') {
      $sortOrder = \&sortBySize;
      $sortColumn = "SIZE";
    }
    elsif ($o eq 'c') {
      $sortOrder = \&sortByClient;
      $sortColumn = "CLIENT";
    }
    elsif ($o eq 'm') {
      $sortOrder = \&sortByMediaServer;
      $sortColumn = "SRVR";
    }
    elsif ($o eq 'u') {
      $sortOrder = \&sortByStorageUnit;
      $sortColumn = "STU";
    }
    elsif ($o eq 't') {
      $sortOrder = \&sortByThroughput;
      $sortColumn = "SPD";
    }
  }
  elsif ($answer eq 's') {
    $win->addstr(2, 0, "Seconds to delay between refresh:");
    echo();  $win->getstr(2, 34, $answer);  noecho();
    if ($answer =~ /^[\d]+$/) {
      $interval = $answer;
    }
  }
  elsif ($answer eq 'd') {
    $win->addstr(2, 0, "Number of display passes:");
    echo();  $win->getstr(2, 26, $answer);  noecho();
    if ($answer =~ /^[\d]+$/) {
      $passLimit = $refreshCounter + $answer;
    }
  }
  if ($answer eq 't') {
    $win->addstr(2, 0, "Measure speed: (c)umulative (i)nstantaneously?");
    my $t = $win->getch();
    if ($t eq 'i') {
      $instant = 1;
    }
    elsif ($t eq 'c') {
      $instant = 0;
    }
  }
  elsif (($answer eq '?') || ($answer eq 'h')) {
    my $lines = $LINES-10;  my $cols = $COLS-10;
    my $help = $win->subwin($lines, $cols, 5, 5);
    $help->clear();  $help->box('|', '-');

    $help->addstr(1, 2, "$program - A NetBackup job monitoring tool written in Perl");
    $help->addstr(3, 2, "These single-character commands are available:");

    my $r = 5;
    $help->addstr($r, 2, "h or ?");
      $help->addstr($r, 9, "- help; show this text");
    $help->addstr($r+=1, 2, "s");
      $help->addstr($r, 9, "- change number of seconds to delay between updates");
    $help->addstr($r+=1, 2, "d");
      $help->addstr($r, 9, "- set number of display passes");
    $help->addstr($r+=1, 2, "o");
      $help->addstr($r, 9, "- specify sort order");
    $help->addstr($r+=1, 2, "r");
      $help->addstr($r, 9, "- force a refresh");
    $help->addstr($r+=1, 2, "t");
      $help->addstr($r, 9, "- throughput calculation method");
    $help->addstr($r+=1, 2, "q");
      $help->addstr($r, 9, "- quit");

    $help->attron(A_REVERSE);
    $help->addstr($lines-2, 2, "Hit any key to continue:");
    $help->attroff(A_REVERSE);

    $win->touchwin();
    $help->refresh();
    $win->getch();
  }
  else {
    return 'r';
  }

  $win->move(2, 0);  $win->clrtoeol();
  $win->refresh();

  return ' ';
}

#
# Gather first round of drive data if we're running live
if (!$opts{'r'}) {
  foreach my $server (NBU::StorageUnit->mediaServers($master)) {
    NBU::Drive->populate($server) if ($server->mediaManager());
  }
}

#
# Load the first round of Job data
print STDERR "Loading...";
NBU::Job->loadJobs($master, $opts{'r'}, $opts{'l'});

my $win = new Curses;
noecho();  cbreak();
$win->clear();
$win->refresh();

local $SIG{WINCH} = sub {
  print STDERR "Terminal resized...";
#  initscr();
  $win = new Curses;
  $win->clear();
  $win->refresh()
};

my $CLIENTWIDTH = 25;

my $hdr = sprintf("%${CLIENTWIDTH}s", "CLIENT    ");
if ($opts{'v'}) {
  $hdr .= " ".sprintf("%-40s", "             CLASS/SCHEDULE");
}
else {
  $hdr .= " ".sprintf("%-23s", "         CLASS");
}
$hdr .= " ".sprintf("%7s", " JOBID ");
$hdr .= " ".sprintf("%8s", "  TIME  ");
$hdr .= " ".sprintf("%3s", "OP ");
$hdr .= " ".sprintf("%6s", "VOLUME");
$hdr .= " ".sprintf("%6s", " SIZE ");
$hdr .= " ".sprintf("%4s", " SPD ");
if ($opts{'r'}) {
  $hdr .= " ".sprintf("%10s", "  STU  ");
}
else {
  $hdr .= " ".sprintf("%11s", "   DRIVE");
}

while (!$passLimit || ($refreshCounter <= $passLimit)) {
  my $jobCount = 0;
  my $queueCount = 0;  my $doneCount = 0;
  my $totalSpeed = 0;
  my $totalWireSpeed = 0;
  my @jl = NBU::Job->list;

  #
  # Sort the job list according to the order du jour
  # For each active job, a description is built up and added to the display
  # in one fell swoop.
  $win->addstr(3, 1, $hdr);
  for my $job (sort $sortOrder (@jl)) {
    if (!$job->active) {
      $queueCount += 1 if ($job->queued);
      $doneCount += 1 if ($job->done);
      next;
    }


    my $who = sprintf("%${CLIENTWIDTH}s", $job->client->name);

    my $classID = $job->class->name;
    my $classIDlength = 23;
    if ($opts{'v'}) {
      $classID .= "/".$job->schedule->name;
      $classIDlength = 40;
    }
    $classID = sprintf("%-".$classIDlength."s", $classID);

    my $jid = sprintf("%7u", $job->id);

    my $displayTime;
    if ($elapsed) {
	$displayTime = dispInterval(time - $job->start);
    }
    else {
      my $startTime = ((time - $job->start) < (24 * 60 * 60)) ?
	  substr(localtime($job->start), 11, 8) :
	  " ".substr(localtime($job->start), 4, 6)." ";
      $displayTime = $startTime;
    }

    my $jobDescription = "$who $classID $jid $displayTime ".$job->operation;

    my $speed;
    $jobDescription .= " ".sprintf("%8s", (defined($job->volume) ? $job->volume->id : ""));
    $jobDescription .= " ".sprintf("%6d", int($job->dataWritten/1024));
    if (defined($speed = ($instant ? $job->ispeed : $job->speed))) {
      $speed /= 1024;
      $jobDescription .= " ".sprintf("%5.2f", $speed)
	if ($job->elapsedTime);
    }
    else {
      $jobDescription .= " --.--";
    }
    

    $jobDescription .= " ".sprintf("%10s", defined($job->storageUnit) ? $job->storageUnit->label : "");

    if (!$opts{'r'} && defined($job->volume)) {
      if ($job->volume->drive) {
	$jobDescription .= sprintf(":%2d", $job->volume->drive->index);
      }
    }

    #
    # Alert viewer to certain jobs based on configuration data from
    # job-alert.xml in /usr/local/etc
    my $alert = 0;
    if (defined($speed)) {

      $totalSpeed += $speed;
      $totalWireSpeed += $speed if ($job->mediaServer->IPaddress ne $job->client->IPaddress);

      if ($job->dataWritten > (30 * 1024)) {
	$alert |= ($job->class->name eq "NBUPR2") && ($speed < 5);
	$alert |= ($job->class->name eq "PR2_SAP_ARCHIVES") && ($speed < 1.5);
      }
    }
    $win->attron(A_REVERSE) if ($alert);
    $win->addstr(4 + $jobCount++, 1, $jobDescription);
    $win->attroff(A_REVERSE) if ($alert);
  }

  my $down = 0;
  my $total = 0;
  if (!$opts{'r'}) {
    for my $d (NBU::Drive->pool) {
      next unless ($d->known);
      $total++;
      $down++ if ($d->down);
    }
  }
  $win->addstr(0, 0, "Pass $refreshCounter; $jobCount active jobs, $queueCount queued jobs; Drives: $down down out of $total");
  $refreshCounter++;
  my $timestamp = localtime;
  $win->addstr(0, $COLS-length($timestamp), $timestamp);

  $totalSpeed = sprintf("%.2f", $totalSpeed);
  $totalWireSpeed = sprintf("%.2f", $totalWireSpeed);
  $win->addstr(1, 0, ($instant ? "Instantaneous" : "Cumulative")." throughput ${totalSpeed}Mb/s; Network load ${totalWireSpeed}MB/s");

  $win->refresh;

  my $answer;
  eval {
    local $SIG{ALRM} = sub { die "timed out\n"; };

    alarm $interval if ($interval);
    $answer = getch;
    alarm 0 if ($interval);
  };
  if ($@) {
    $answer = 'r';
  }

  last if ($answer eq 'q');

  if ($answer eq 'k') {
    # Choose which job to kill
  }
  elsif ($answer ne 'r') {
    $answer = menu($answer, $win);
  }

  if ($answer eq 'r') {
    $win->addstr(2, 0, "Refreshing...");  $win->refresh();

    #
    # If we're not doing a 'r'eplay, fetch the current status of the drives
    # in the storage units so we can correlate the jobs to them.
    if (!$opts{'r'}) {
      foreach my $server (NBU::StorageUnit->mediaServers($master)) {
	NBU::Drive->updateStatus($server) if ($server->mediaManager());
      }
    }
    if (!defined(NBU::Job->refreshJobs($master))) {
      last;
    }
  }

  $win->clear;
}
endwin();

=head1 NAME

nbutop.pl - An active backup job monitoring utility for NetBackup

=head1 SYNOPSIS

    nbutop.pl [-v] [-i] [-r|-l] [-s <interval>] [-p <limit>] [-M <master>]

=head1 DESCRIPTION

In the vein of L<top|top> this utility presents a dynamically refreshing list of
running NetBackup jobs.  It adapts (somewhat) to your display size but a minimum
of 100 columns is definitely required.

By combining information from bpdbjobs and vmoprcmd, the exact tape drive
each job is using can be inferred making many trouble-shooting tasks that much
easier.  (This obviously does not apply when replaying prior monitoring sessions
using the B<-r> option.)

After a looooong initial delay during which NetBackup's bpdbjobs utility gathers
all information it has on all its jobs and sends it across to nbutop.pl the screen
will show the running jobs as well as some statistics on queued jobs.  Additionally
you will see a reference to the number of drives nbutop.pl thinks are available
for use.  Subsequent refreshes do not take nearly as long to calculate since
bpdbjobs' undocumented "refresh" command is used to gather the raw data for them.

The throughput calculation is simply a matter of adding up all the speeds from all
the running streams.  By default nbutop.pl will start out displaying cumulative speeds
meaning it simply divides a job's total amount of data written by the time spent writing
that data.  Switching to instantaneous throughput causes it to examine the amount
data written most recently instead thus giving a measurement more indicative of the
rate at which the job is writing right now.  (See the B<-i> option below.)

Only media servers actually write data to tape.  Some of that data is available local
to that media server, some (most?) of it arrives via one or more network connections.
Nbutop.pl separately adds up the throughout on only those jobs whose data arrives via
a network connection to quickly give you a sense of the load on the network.

There are a few single character commands you may now issue to control nbutop.pl's
run-time behavior, the most important of which are 'q' to quit out of nbutop.pl and
'?' for a splash screen describing all the other commands.

=head1 OPTIONS

=over 4

=item B<-v>

Verbose output only adds the job's schedule to the output display.

=item B<-i>

Start out listing all job throughput information using a trailing "instantaneous"
calculation rather than the default cumulative one.  This can be changed while nbutop.pl
is running.  Instantaneous throughput number can fluctuate wildly but are helpful
when you suspect a job is slowly slowing down.

=item B<-l>

This option enables the logging of the raw job data transmitted from the NetBackup master
being monitored to a file in the user's home directory called ".alljobs.allcolumns".  This
can then be used with the B<-r> option to replay the session.

=item B<-r>

Upon replaying a previously loggged series of job reports from a master server, nbutop.pl is
no longer able to correlate the mounting of volumes to the current state of the tape drives and
thus is not able to show which drives are (were?) being used.

=back

=head1 SEE ALSO

=over 4

=item L<js.pl|js.pl>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
