#!/usr/local/bin/perl -w

use strict;

use POSIX;
use Getopt::Std;
use Time::Local;

my %opts;
getopts('d?xveflrj:aAt:p:c:o:C:O:M:', \%opts);

if ($opts{'?'}) {
  print STDERR <<EOT;
Usage: js.pl [-v] [-r|-l] [-j <jobfile>] [-ef] [-aA] [-o <order>]
             [-x]
             [-t <policy-type>] [-c <policy>] [-C <client>] [-O <OS>]
             [-M <master>]
Options:
  -v       Verbose policy listing

  -l       Log this monitoring session
  -r       Replay previous job monitoring session
  -j       Provide alternate job history session data

  -e       More detailed error information
  -f       List files directed to be backed up

  -a       List all jobs from the last 24 hours
  -A       List all jobs.

  -o       Order jobs by one of id, client or speed

  -x       Produce xml output

  -t       Restrict listing to jobs of <policy-type> type
  -c       Only list policies matching the provided pattern
  -C       Restrict listing to clients matching the provided pattern
  -O       Control which client OS jobs are presented

  -M       Alternate NetBackup <master> server
EOT
  exit;
}

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

  return "--:--:--" if (!defined($i));

  my $seconds = $i % 60;  $i = int($i / 60);
  my $minutes = $i % 60;
  my $hours = int($i / 60);

  my $fmt = sprintf("%02d", $seconds);
  $fmt = sprintf("%02d:", $minutes).$fmt;
  $fmt = sprintf("%02d:", $hours).$fmt;
  return $fmt;
}
my $period = 1;
if ($opts{'p'}) {
  $period = $opts{'p'};
}


sub sortBySpeed {
  my $result = 0;
  my $aSpeed = $a->success ? ($a->dataWritten / $a->elapsedTime) : -1;
  my $bSpeed = $b->success ? ($b->dataWritten / $b->elapsedTime) : -1;

  $result = ($bSpeed <=> $aSpeed);
  $result = ($b->id <=> $a->id) if ($result == 0);
  return $result;
}

sub sortByClient {
  my $result;

  $result = ($a->client->name cmp $b->client->name);
  $result = ($b->id <=> $a->id) if ($result == 0);
  return $result;
}

sub sortByID {
  my $result;

  $result = ($b->id <=> $a->id);
  return $result;
}

my $sortOrder = \&sortByID;
if ($opts{'o'}) {
  $sortOrder = \&sortByClient if ($opts{'o'} eq 'client');
  $sortOrder = \&sortBySpeed if ($opts{'o'} eq 'speed');
}


my %stateCodes = (
  'active' => 'A',
  'done' => 'D',
  'queued' => 'Q',
  're-queued' => 'R',
  'incomplete' => 'I',
);

my $totalWritten = 0;

$opts{'r'} = 1 if ($opts{'j'});

my $asOf = NBU::Job->loadJobs($master, $opts{'r'}, $opts{'l'}, ($opts{'j'} ? $opts{'j'} : undef));
my $mm;  my $dd;  my $yyyy;
  my ($s, $m, $h, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($asOf);
  $year += 1900;
  $mm = $mon + 1;
  $dd = $mday;
  $yyyy = $year;
#my $since = timelocal(0, 0, 0, $dd, $mm-1, $yyyy);
my $since = $asOf - ($period *  (24 * 60 * 60));


my $CLIENTWIDTH = 25;

if ($opts{'x'}) {
  print "<?xml version=\"1.0\"?>\n";
  print "<job-list>\n";
}
else {
  my $hdr = sprintf("%${CLIENTWIDTH}s", "CLIENT    ");
  if ($opts{'v'}) {
    $hdr .= " ".sprintf("%-40s", "             CLASS/SCHEDULE");
  }
  else {
    $hdr .= " ".sprintf("%-23s", "         CLASS");
  }
  $hdr .= " ".sprintf("%9s", "  JOBID  ");
  $hdr .= " ".sprintf("%8s", "  START ");
  $hdr .= " ".sprintf("%1s", "R");
  $hdr .= " ".sprintf("%-10s", "   STU");
  $hdr .= " ".sprintf("%3s", "OP");
  $hdr .= " ".sprintf("%-8s", "  TIME");
  $hdr .= " ".sprintf("%-7s", "  FILES");
  $hdr .= " ".sprintf("%-10s", "   KBYTES");
  $hdr .= " ".sprintf("%4s", "SPD");
  print "$hdr\n";
}

NBU::Class->populate if ($opts{'t'});

my $jobCount = 0;
my %activeClients;
my $MBytes = 0;

my @jl = NBU::Job->list;
for my $job (sort $sortOrder (@jl)) {
  next if (!$opts{'a'} && !$job->active);
  next if (!$opts{'A'} && ($job->start < $since));

  # Skip jobs of the wrong ilk
  my $fits = !($opts{'t'} || $opts{'c'} || $opts{'C'} || $opts{'O'});
  if (!$fits) {
    $fits ||= (defined($job->class) && defined($job->class->type) && ($job->class->type =~ $opts{'t'})) if (!$fits && $opts{'t'});
    $fits ||= (defined($job->class) && ($job->class->name =~ $opts{'c'})) if (!$fits && $opts{'c'});
    $fits ||= (defined($job->client) && ($job->client->name =~ $opts{'C'})) if (!$fits && $opts{'C'});
    $fits ||= (defined($job->client) && defined($job->client->os) && ($job->client->os =~ $opts{'O'})) if (!$fits && $opts{'O'});
  }
  next if (!$fits);

  {
    $jobCount += 1;

    my $who = $job->client->name;
    $activeClients{$who} += 1;
    $who = sprintf("%${CLIENTWIDTH}s", $who) unless ($opts{'x'});

    my $policyName = my $classID = $job->class->name;
    my $scheduleName = $job->schedule->name;
    my $classIDlength = 23;
    if ($opts{'v'}) {
      $classID .= "/".$scheduleName;
      $classIDlength = 40;
    }
    $classID = sprintf("%-".$classIDlength."s", $classID);

    my $jid = $job->id;
    $jid = sprintf("%7u", $job->id) unless ($opts{'x'});
    my $try = defined($job->try) ? $job->try : 0;
    my $state = $stateCodes{$job->state};


    if ($opts{'x'}) {
      my $startTime = substr(localtime($job->start), 4);
      print "  <job id=\"$jid\"";
      print " try=\"$try\"" if ($try);
      print " policy=\"$policyName\" schedule=\"$scheduleName\" client=\"$who\" start=\"$startTime\"";
    }
    else {
      my $startTime = ((time - $job->start) < (24 * 60 * 60)) ?
	  substr(localtime($job->start), 11, 8) :
	  " ".substr(localtime($job->start), 4, 6)." ";
      print "$who $classID ${jid}-${try} $startTime $state";
    }

    if (my $stu = $job->storageUnit) {
      if ($opts{'x'}) {
	print " storageunit=\"".$stu->label."\"";
      }
      else {
        printf(" %10s ", $stu->label);
      }
    }
    else {
      printf(" %10s ", "") unless ($opts{'x'});
    }

    if ($state eq "D") {
      if ($opts{'x'}) {
	print " exitcode=\"".$job->status."\" elapsed=\"".dispInterval($job->elapsedTime)."\"";
      }
      else {
        printf(" %3d ", $job->status);
        print dispInterval($job->elapsedTime);
      }
      if ($job->status == 0) {
	if (defined($job->dataWritten)) {
	  $totalWritten += ($job->dataWritten / 1024);
	  $MBytes += $job->dataWritten / 1024;
	}
      }
    }
    elsif ($state eq "A") {
      my $op = $job->operation;
      if ($opts{'x'}) {
	print " operation=\"$op\" elapsed=\"".dispInterval($job->elapsedTime)."\"";
      }
      else {
        print " $op ".dispInterval($job->busy);
      }
    }

    if ($state ne "Q") {
      if (defined($job->filesWritten)) {
	if ($opts{'x'}) {
	  print " files=\"".$job->filesWritten."\"";
	}
	else {
          printf(" %7d", $job->filesWritten);
	}
      }
      else {
	printf(" 7%s", "") unless ($opts{'x'});
      }
      if (defined($job->dataWritten)) {
	if ($opts{'x'}) {
	  print " kbytes=\"".$job->dataWritten."\"";
	}
	else {
          printf(" %10d", $job->dataWritten);
	}
      }
      else {
	printf(" 10%s", "") unless ($opts{'x'});
      }
      if (($job->elapsedTime > 0) && defined($job->dataWritten)) {
        my $speed = sprintf("%.2f", ($job->dataWritten / $job->elapsedTime / 1024));
	if ($opts{'x'}) {
	  print " speed=\"$speed\"";
	}
	else {
          print " $speed";
	}
      }

      if (($state eq "A") && ($job->volume)) {
	print " ".$job->volume->id if (!$opts{'x'});
      }
    }

    print ">" if ($opts{'x'});

    if ($opts{'f'}) {
      for my $f ($job->files) {
	next if ($f =~ /NEW_STREAM/);
	if ($opts{'x'}) {
	  print "\n    <file name=\"$f\"/>";
	}
	else {
	  print "\n  $f";
	}
      }
    }
    if ($opts{'e'}) {
      my @el = $job->errors;
      for my $e (@el) {
	my $tm = $$e{tod};
	my $msg = $$e{message};

	next if ($msg =~ /backup of client [\S]+ exited with status 1 /);

	my $windowsComment = $1 if ($msg =~ s/(\(WIN32.*\))//);

	printf("\n%${CLIENTWIDTH}s - %s", "  +".dispInterval($tm-$job->start), $msg);
	if (defined($windowsComment) && ($windowsComment !~ /WIN32 32:/)) {
	  printf("\n%${CLIENTWIDTH}s   %s", "", $windowsComment);
	}
      }
    }
    if ($opts{'x'}) {
      print "\n  </job>";
    }
    print "\n";
  }
}
print "</job-list>\n" if ($opts{'x'});

=head1 NAME

js.pl - NetBackup job status reporting

=head1 SYNOPSIS

    js.pl [-v] [-r|-l] [-j <jobfile>] [-ef] [-aA] [-o <order>]
          [-x]
          [-t <policy-type>] [-c <policy>] [-C <client>] [-O <OS>]
          [-M <master>]

=head1 DESCRIPTION

In the vein of L<ps|ps> js.pl lists the currently running NetBackup jobs.  However, it
is also capable of regurgitating the fate of jobs already completed by using the B<-a> and
B<-A> options.

=head1 OPTIONS

=over 4

=item B<-v>

Verbose output only adds the job's schedule to the output display.

=item B<-a>

By default, js.pl only lists active jobs.  With the B<-a> option it lists
inactive (more commonly known as completed) jobs as well.

=item B<-A>

By default, js.pl only lists jobs from the past 24 hours of operation.  Setting
B<-A> lists all jobs in the NetBackup job database.

=item B<-o> speed|client

The most common way to list NetBackup jobs is in descending job-id order, i.e. the most recent
jobs first.  The B<-o> option allows for two other orderings, namely speed and client.  Speed
ordering lists jobs from fastest to slowest; client ordering lists jobs by client, leaving the
original reverse chronological ordering intact as much as possible.

=item B<-x>

The standard fixed width column output format can be exchanged for XML data by setting the B<-x>
option.  XML data can easily be viewed in web browsers and is also manipulatable in Excel.

=item B<-l>

This option enables the logging of the raw job data transmitted from the NetBackup master
being monitored to a file in the user's home directory called ".alljobs.allcolumns".  This
can then be used with the B<-r> option to replay the session.

=item B<-r>

Report on a set of data previously logged using the B<-l> option.

=item B<-j> jobfile

Using B<-r> without the B<-j> option will result in a replace of the data contained in the
file ~/.alljobs.allcolumns, i.e. the location where the B<-l> dropped off the last recorded
session.  When reaching farther back in time, copies of these job logs can be maintained and
replayed by overriding the file being reported on.

=item B<-e>

More detailed job error information will be displayed when this option is given.  NetBackup's
bperror command is used to retrieve this additional data but its output is distilled some to
keep the display more compact.

=item B<-f>

Those jobs with explicit file lists, the list is displayed below the job information.  In cases
where the jobs list consists of the directive "ALL_LOCAL_DRIVES", the list is expanded to the
actual set of mounts/drives assigned to each job.  ("NEW_STREAM" directives are filtered out.)

=back

=head1 SEE ALSO

=over 4

=item L<nbutop.pl|nbutop.pl>

=back

=head1 BUGS

The B<-j> option should be made more intelligent so it can pull a collection of job history files
from a directory.

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
