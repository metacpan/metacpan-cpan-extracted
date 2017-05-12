#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;

use XML::XPath;
use XML::XPath::XMLParser;

use NBU;

my %opts;
getopts('d?ohispf:', \%opts);

if ($opts{'?'}) {
  print STDERR <<EOT;
Usage: robot-snapshot.pl [-s] [-hi] [-p] [-o] [-f <configfile>] [robot# [robot# ...]]
Options:
  -s       Provide robot content summary

  -h       Preface each robot's listing with a header section
  -i       List full robot inventory

  -p       Gather and display volume pool data

  -o       List volume id of next volume to expire

  -f       Provide alternate robot configuration control file
EOT
  exit;
}


NBU->debug($opts{'d'});

my $file = "/usr/local/etc/robot-conf.xml";
if (defined($opts{'f'})) {
  $file = $opts{'f'};
  die "No such configuration file: $file\n" if (! -f $file);
}

my $xp;
if (-f $file) {
  $xp = XML::XPath->new(filename => $file);
  die "robot-snapshot.pl: Could not parse XML configuration file $file\n" unless (defined($xp));
}

NBU::Media->populate(1);

my @list;
if ($#ARGV > -1 ) {
  for my $robotNumber (@ARGV) {
    my $robot = NBU::Robot->byID($robotNumber);
    push @list, $robot if (defined($robot));
  }
}
else {
  @list = (NBU::Robot->farm);
}

for my $robot (@list) {

  next unless defined($robot);

  my $r = $robot->id;
  my @l = $robot->slotList;

  my $prefix;
  if ($opts{'h'}) {
    print "Robot number $r";
    if (defined($robot->host)) {
      print " on ".$robot->host->name
    }
    else {
      print " cannot be located!\n";
      next;
    }
    print "\n";
    $prefix = "   ";
  }
  else {
    $prefix = "$r\: ";
  }

  my $volumeCount = 0;
  my $netbackupCount = 0;
  my $cleanCount = 0;  my $cleanings = 0;
  my %poolCount;
  my %emptyCount;  my %fullCount;
  my %frozenCount;  my %suspendedCount;

  my $firstExpiration;
  for my $position (1..$robot->capacity) {
    $position = sprintf("%03d", $position);
    my $slot;
    my $display = $opts{'i'};
    my $comments = "";
    if (my $volume = $l[$position]) {
      $volumeCount += 1;
      $slot = "$prefix$position\: ".$volume->id;
      if (defined($volume)) {
	if ($volume->netbackup) {
	  $netbackupCount += 1;
	  $slot .= " ".$volume->pool->name if ($opts{'p'});
	  $slot .= " *";
          $poolCount{$volume->pool->name} += 1;
	}
        elsif (!$volume->cleaningTape) {
	  $slot .= " ".$volume->pool->name if ($opts{'p'});
          if ($volume->allocated) {
            $slot .= " ALLOCATED";
	    if ($volume->full) {
              $slot .= " FULL";
              $fullCount{$volume->pool->name} += 1;
	      if (!defined($firstExpiration) || ($volume->expires < $firstExpiration->expires)) {
		$firstExpiration = $volume;
	      }
	    }
	    if ($volume->suspended) {
              $slot .= " SUSPENDED";
              $suspendedCount{$volume->pool->name} += 1;
	    }
	    if ($volume->frozen) {
              $slot .= " FROZEN";
              $frozenCount{$volume->pool->name} += 1;
	    }
            if ($volume->expires < time) {
              $slot .= " EXPIRED";
	    }
	    else {
	      $slot .= " expires ".substr(localtime($volume->expires), 4);
	    }
	    $slot .= " rl=".$volume->retention->level;
          }
          else {
            $emptyCount{$volume->pool->name} += 1;
          }
          $poolCount{$volume->pool->name} += 1;
        }
        elsif ($volume->cleaningTape) {
          $cleanCount += 1;
          $cleanings += $volume->cleaningCount;
	  if ($volume->cleaningCount == 0) {
	    $display ||= 1;
	    $comments = " <-- No cleanings left!";
	  }

        }
      }
    }
    else {
      $slot = "$prefix$position\: <EMPTY>";
    }
    print "$slot$comments\n" if ($display);
  }

  my $emptyCount = 0;
  my $fullCount = 0;

  my ($nodeset, $robotConfig);
  if (defined($xp)) {
    $nodeset = $xp->find('//robot[@id=\''.$r.'\']');
    $robotConfig = ($nodeset->size == 1) ? $nodeset->pop : undef;
  }

  if (defined($robotConfig)) {
    $nodeset = $robotConfig->find('pool[@name=\'NetBackup\']');
    if ($nodeset->size == 1) {
      my $constraint = $nodeset->pop;
      my $target = $constraint->getAttribute('total');
      if ((my $n = ($target - $netbackupCount)) > 0) {
	print "${prefix}  Add $n NetBackup volumes\n";
      }
    }
  }

  foreach my $pool (keys %poolCount) {
    my $poolSpecs;

    if (defined($robotConfig)) {
      $nodeset = $robotConfig->find('pool[@name=\''.$pool.'\']');
      if ($nodeset->size == 1) {
	$poolSpecs = $nodeset->pop;
      }
    }

    my $total = sprintf("%3u", $poolCount{$pool});
    my $empty = $emptyCount{$pool} += 0;
    my $full = $fullCount{$pool} += 0;
    my $partial = $total - $full - $empty;
    my $frozen = $frozenCount{$pool} += 0;
    my $suspended = $suspendedCount{$pool} += 0;

    if (defined($poolSpecs)) {

      print "${prefix}$total $pool\: $empty/$partial/$full\n";

      if ((my $limit = $poolSpecs->find('suspended | ancestor::*/suspended'))->size > 0) {
	if ($suspended > (my $value = $limit->pop->string_value)) {
	  my $count = $suspended - $value;
	  print "${prefix}     Remove $count suspended $pool volumes\n";
	}
      }
      if ((my $limit = $poolSpecs->find('frozen | ancestor::*/frozen'))->size > 0) {
	if ($frozen > (my $value = $limit->pop->string_value)) {
	  my $count = $frozen - $value;
	  print "${prefix}     Remove $count frozen $pool volumes\n";
	}
      }
      if ((my $limit = $poolSpecs->find('full'))->size == 1) {
	if ($full > (my $value = $limit->pop->string_value)) {
	  my $count = $full - $value;
	  print "${prefix}     Remove $count full $pool volumes\n";
	}
      }
      if ((my $limit = $poolSpecs->find('empty'))->size == 1) {
	if ($empty < (my $value = $limit->pop->string_value)) {
	  my $count = $value - $empty;
	  print "${prefix}     Add $count empty $pool volumes\n";
	}
      }

      $emptyCount += $empty;
      $fullCount += $full;
    }
    elsif (defined($robotConfig)) {
      my $count = $total - 0;
      print "${prefix}$total $pool\n";
      print "${prefix}     Remove $count disallowed $pool volumes\n";
    }
    else {
      $emptyCount += $empty;
      $fullCount += $full;
    }
  }

  if ($opts{'s'}) {
    print "${prefix}$volumeCount out of ".$robot->capacity." occupied\n";
    print "${prefix}$emptyCount completely empty volumes available\n";
    print "${prefix}$cleanings cleanings left on $cleanCount cleaning volumes\n";
  }
  if ($opts{'o'} && defined($firstExpiration)) {
    print "${prefix}Oldest full volume is ".$firstExpiration->id." expiring on ".localtime($firstExpiration->expires)."\n";
  }
}

=head1 NAME

robot-snapshot.pl - Report and Analyze Tape Robot Contents

=head1 SYNOPSIS

    robot-snapshot.pl [-s] [-hi] [-p] [-o] [-f <configfile>] [robot#1 [robot#2 ...]]

=head1 DESCRIPTION

Taking a snapshot of a robot involves taking an inventory of its tape volumes, optionally
listing them in robot slot number order, and commenting on the quantity of volumes in
various volume pools.  The observations robot-snapshot.pl makes with regards to the various
volume pools are driven by a set of robot content rules defined in a configuration file.  By
default this is the file /usr/local/etc/robot-conf.xml

=head1 SEE ALSO

=over 4

=item L<volume-list.pl|volume-list.pl>, L<volume-status.pl|volume-status.pl>, L<scratch.pl|scratch.pl>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
