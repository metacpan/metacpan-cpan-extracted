#!/usr/local/bin/perl -w

use strict;

use XML::XPath;
use XML::XPath::XMLParser;

use Getopt::Std;
use Time::Local;
use Date::Parse;

my %opts;
getopts('rldf:sa:p:M:', \%opts);

use NBU;
NBU->debug($opts{'d'});


my $config = "/usr/local/etc/sla.xml";
if (defined($opts{'f'})) {
  $config = $opts{'f'};
  die "No such configuration file: $config\n" if (! -f $config);
}

my $xp;
if (-f $config) {
  $xp = XML::XPath->new(filename => $config);
  die "sla.pl: Could not parse XML configuration file $config\n" unless (defined($xp));
}

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

my $asOf = NBU::Job->loadJobs($master, $opts{'r'}, $opts{'l'});
my $mm;  my $dd;  my $yyyy;
  my ($s, $m, $h, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($asOf);
  $year += 1900;
  $mm = $mon + 1;
  $dd = $mday;
  $yyyy = $year;

my $since;
if ($opts{'a'}) {
  $asOf = str2time($opts{'a'});
}
$since = $asOf - ($period *  (24 * 60 * 60));

my %businessNames;
my %businesses;
my $nodeset = $xp->find('//business');
if ($nodeset->size <= 0) {
  print "No business definitions found in $config\n";
  exit 1;
}
foreach my $node ($nodeset->get_nodelist) {
  my $name = $node->getAttribute("id");
  $businessNames{$name} += 1;
  $businesses{$name} = [];
}


my $notClassified = 0;
for my $job (NBU::Job->list) {
  next if ($job->active || $job->queued);

  next if ($job->stop < $since);
  if ($job->start < $since) {
    next unless ($job->stop <= $asOf);
  }
  next if ($job->start > $asOf);
  next if ($job->stop > $asOf);

  next if (!defined($job->storageUnit));

  #
  # See if any policy elements fit this job
  my $nodeset = $xp->find(
    '//policy[@name=\''.$job->class->name.'\'][@client=\''.$job->client->name.'\']'
      .' | '.
    '//policy[@name=\''.$job->class->name.'\'][not(@client)]');

  if ($nodeset->size > 0) {
    #print "We appear to care about job ".$job->class->name;
    #
    # When this job does appear to have someones's interest, find out which
    # business that is by looking among the policy element's ancestors for a
    # business element
    foreach my $node ($nodeset->get_nodelist) {
      my $business = $node->find('ancestor::business')->pop;
      $job->business(my $businessName = $business->getAttribute("id"));
      my $list = $businesses{$businessName};
      push @$list, $job;

      if (defined(my $system = $node->find('ancestor::system')->pop)) {
        $job->system($system->getAttribute("name"));
      }
    }
  }
  else {
    $notClassified += 1;
  }
}

print "<?xml version=\"1.0\"?>\n";
print "<business-list>\n";
foreach my $businessName (sort (keys %businessNames)) {
  my $list = $businesses{$businessName};
  my $total = @$list;
  my %distribution;
  my %successes;  my %failures;

  $distribution{"hcart2"} = 0;


  foreach my $job (@$list) {
    $distribution{my $density = $job->storageUnit->density} += 1;
    if ($job->success) {
      $successes{$density} += 1;
    }
    else {
      $failures{$density} += 1;
    }
  }

  my $converted = $total ? sprintf("%.2f", $distribution{"hcart2"} / $total * 100) : "-.--";
  print "  <business id=\"$businessName\" total=\"$total\" converted=\"$converted%\">\n";
  if ($opts{'s'}) {
    foreach my $job (@$list) {
      my $jid = $job->id;
      my $density = $job->storageUnit->density;
      my $policyName = $job->class->name;
      my $scheduleName = $job->schedule->name;
      print "    <stream  policy=\"$policyName\" schedule=\"$scheduleName\"";
      #print " id=\"$jid\";
      if (($job->elapsedTime > 0) && defined($job->dataWritten) && ($job->dataWritten > 0)) {
	print " elapsed=\"".dispInterval($job->elapsedTime)."\"";
	print " kbytes=\"".$job->dataWritten."\"";
        my $speed = sprintf("%.2f", ($job->dataWritten / $job->elapsedTime / 1024));
	print " speed=\"$speed\"";
        print " density=\"$density\"" if (defined($density));
      }
      print "/>\n";
    }
  }
  print "  </business>\n";
}
print "<!-- $notClassified streams were not associated with a specific business) -->\n";
print "</business-list>\n";
