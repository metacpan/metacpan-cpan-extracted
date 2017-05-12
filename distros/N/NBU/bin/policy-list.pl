#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('d?exasfaimvnp:t:', \%opts);

if ($opts{'?'}) {
  print STDERR <<EOT;
Usage: policy-list.pl [-sfm] [-ai] [-n] [-p <policy>] [-t <type>] [-ex]
Options:
  -s          List schedules for each policy
  -f          List files for each policy
  -m          List client members of each policy

  -a          Only list active policies
  -i          Only list in-active policies

  -n          Restrict schedules to NetBackup schedules

  -p          Match policies against argument (reg-exp)
  -t          Restrict listing to policy type argument

  -e          Explode policy/schedule/file/member attributes on each line
  -x          XML output
EOT

  exit;
}

use NBU;
NBU->debug($opts{'d'});

NBU::Class->populate;

sub printDetail {
  my $h = shift;
  my $d = shift;

  if ($opts{'x'}) {
    print $h;
  }
  else {
    my @elements = split(/\|/, $d);
    my $sep = "";
    foreach my $e (@elements) {
      print $sep."\"$e\"";
      $sep = ",";
    }
    print "\n";
  }
}


sub listSchedules {
  my $c = shift;
  my $lastHeader = shift;
  my $prefix = shift;
  my @detail = @_;

  my $nextDetail = shift(@detail);

  my @sl = ($c->schedules, $c->policies);

  if ($opts{'n'}) {
    my @internal;
    for my $s (@sl) {
      push @internal, $s if ($s->type ne "UBAK");
    }
    @sl = @internal;
  }

  my $eCounter = 0;
  if (@sl) {
    for my $s (@sl) {
      my $scheduleName = $s->name;
      my $maximumMPX = $s->maximumMPX;
      my $residence = $s->residence;
      my ($header, $footer);
      if ($opts{'x'}) {
	my $f = $s->frequency;
	my ($minutes, $hours, $days, $weeks);
	$minutes = $f % (60 * 60);
	$hours = int($f / (60 * 60));
	$days = int($hours / 24); $hours = $hours % 24;
	$weeks = int($days / 7); $days = $days % 7;

	my $frequency = "";  my $sep = "";
	if ($weeks) {
	  $frequency .= $sep."$weeks W";
	  $sep = ";";
	}
	if ($days) {
	  $frequency .= $sep."$days D";
	  $sep = ";";
	}
	if ($hours) {
	  $frequency .= $sep."$hours H";
	  $sep = ";";
	}
	if ($minutes) {
	  $frequency .= $sep."$minutes M";
	  $sep = ";";
	}

	$header = "<schedule name=\"$scheduleName\" type=\"".$s->type."\" frequency=\"$frequency\"";
	$header .= " storage-unit=\"".$residence->label."\"" if (defined($residence));
	$header .= " mpx=\"$maximumMPX\"" if (defined($maximumMPX));
	$header .= ">\n";
	$footer = "</schedule>\n";
      }
      else {
	$header = $scheduleName."\n";
	$footer = "";
      }
      if ($opts{'e'}) {
	my $level = $prefix.'|'.$scheduleName;
	if (defined($nextDetail)) {
          $eCounter += &$nextDetail($c, $lastHeader.$header, $level, @detail)
	}
	else {
	  printDetail($lastHeader.$header, $level);
	  $eCounter += 1;
	}
      }
      else {
        print $lastHeader.$prefix.$header;
	$eCounter += 1;
      }
      print $prefix.$footer if ($eCounter);
      $lastHeader = "";
    }
  }
  if (!$opts{'e'}) {
    $eCounter += &$nextDetail($c, $lastHeader, $prefix."  ", @detail) if (defined($nextDetail));
  }
  return $eCounter;
}

sub listMembers {
  my $c = shift;
  my $lastHeader = shift;
  my $prefix = shift;
  my @detail = @_;

  my $nextDetail = shift(@detail);

  #
  # All members of the policy
  my $eCounter = 0;
  my @cl = (sort {$a->name cmp $b->name} $c->clients);
  if (@cl) {
    for my $client (@cl) {
      my $clientName = $client->name;
      my $header = $opts{'x'} ? "<client name=\"$clientName\">\n" : $clientName."\n";
      my $footer = $opts{'x'} ? "</client>\n" : "";
      if ($opts{'e'}) {
	my $level = $prefix.'|'.$clientName;
	if (defined($nextDetail)) {
          $eCounter += &$nextDetail($c, $lastHeader.$header, $level, @detail)
	}
	else {
	  printDetail($lastHeader.$header, $level);
	  $eCounter += 1;
	}
      }
      else {
	print $lastHeader.$prefix.$header;
	$eCounter += 1;
      }
      print $footer if ($eCounter);
      $lastHeader = "";
    }
  }
  if (!$opts{'e'}) {
    $eCounter += &$nextDetail($c, $lastHeader, $prefix."  ", @detail) if (defined($nextDetail));
  }
  return $eCounter;
}

sub listFiles {
  my $c = shift;
  my $lastHeader = shift;
  my $prefix = shift;
  my @detail = @_;

  my $nextDetail = shift(@detail);

  #
  # All included and excluded files of the policy
  my $eCounter = 0;
  my @ifl = $c->include;
  if (@ifl) {
    for my $if (@ifl) {
      next if ($if eq "NEW_STREAM");
      my $header = $opts{'x'} ? "<file path=\"$if\">\n" : $if."\n";
      my $footer = $opts{'x'} ? "</file>\n" : "";
      if ($opts{'e'}) {
	my $level = $prefix.'|'.$if;
	if (defined($nextDetail)) {
          $eCounter += &$nextDetail($c, $lastHeader.$header, $level, @detail)
	}
	else {
	  printDetail($lastHeader.$header, $level);
	  $eCounter += 1;
	}
      }
      else {
	print $lastHeader.$prefix.$header;
	$eCounter += 1;
      }
      print $footer if ($eCounter);
      $lastHeader = "";
    }
  }
  if (!$opts{'e'}) {
    $eCounter += &$nextDetail($c, $lastHeader, $prefix."  ", @detail) if (defined($nextDetail));
  }
  return $eCounter;
}

my @detail;
push @detail, \&listSchedules if ($opts{'s'});
push @detail, \&listMembers if ($opts{'m'});
push @detail, \&listFiles if ($opts{'f'});

my @list;
if ($#ARGV > -1 ) {
  for my $className (@ARGV) {
    my $class = NBU::Class->byName($className);
    push @list, $class if (defined($class));
  }
}
else {
  
  @list = (sort {
		  my $r = $a->type cmp $b->type;
		  $r = $a->name cmp $b->name if ($r == 0);
		  return $r;
		} (NBU::Class->list));
}

if ($opts{'x'}) {
  print "<?xml version=\"1.0\"?>\n";
  print "<policy-list>\n";
}

my $nextDetail = shift(@detail);
for my $c (@list) {

  next if (!$c->active && !(defined($opts{'a'}) || defined($opts{'i'})));
  next if ($c->active && defined($opts{'i'}));
  next unless (!defined($opts{'p'}) || ($c->name =~ /$opts{'p'}/));
  next unless (!defined($opts{'t'}) || ($c->type =~ /$opts{'t'}/));

  my $policyDescription = "";
  $policyDescription .=  $c->name;

  my $eCounter = 0;
  my ($header, $footer);
  if ($opts{'x'}) {
    $header = "<policy name=\"$policyDescription\"";
    $header .= " type=\"".$c->type."\"";
    $header .= " storage-unit=\"".$c->residence->label."\"" if (defined($c->residence));
    $header .= " maxjobs=\"".$c->maxJobs."\"" if ($c->maxJobs != 2147483647);
    $header .= ">\n";
    $footer = "</policy>\n";
  }
  else {
    $header = $policyDescription."\n";
    $footer = "";
  }

  if ($opts{'e'}) {
    if (defined($nextDetail)) {
      $eCounter += &$nextDetail($c, $header, $policyDescription, @detail)
    }
    else {
      printDetail($header, $policyDescription);
      $eCounter += 1;
    }
    print $footer if ($eCounter);
  }
  else {
    if (defined($nextDetail)) {
      $eCounter += &$nextDetail($c, $header, "  ", @detail)
    }
    else {
      print $header;
      $eCounter += 1;
    }
    print $footer if ($eCounter);
  }
}
if ($opts{'x'}) {
  print "</policy-list>\n";
}
