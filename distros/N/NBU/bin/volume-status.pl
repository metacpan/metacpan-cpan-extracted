#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;
use Time::Local;

my %opts;
getopts('?rdclsgpuUaAfFe:m:', \%opts);

use NBU;
NBU->debug($opts{'d'});

NBU::Media->populate(1);
NBU::Media->loadErrors;

print "\"".join('","',
             "id", "pool", "group", "errors", "mounts", "limit", "expires",
              "robot", "slot").
      "\"\n" if ($opts{'c'});

while (<STDIN>) {
  next if (/^[\s]*\#/);

  chop;
  my $mediaID = $_;
  my $volume = NBU::Media->byID($mediaID);

  my $reportOn = 1;

  my $status = "$mediaID: ";
  if (!defined($volume)) {
    $status .= "? not in volume database!";
    $volume = NBU::Media->new($mediaID);
    $reportOn = 0 unless exists($opts{'U'});
  }
  else {
    $reportOn = 0 if exists($opts{'U'});
  }
  {
    $status .=  sprintf("%3d", $volume->mountCount);
    $status .= sprintf("/%3d", $volume->maxMounts) if ($volume->maxMounts);
    $status .= " mounts: ";
    if ($opts{'p'}) {
      $status = $volume->pool->name.": ".$status;
    }
    if ($opts{'g'}) {
      my $g = defined($volume->group) ? $volume->group : "NONE";
      $status = $g.": ".$status;
    }

    if (exists($opts{'m'})) {
      if ($opts{'m'} >= 0) {
        $reportOn &&= ($volume->mountCount >= $opts{'m'});
      }
      else {
        $reportOn &&= ($volume->mountCount < -$opts{'m'});
      }
    }

    if ($volume->errorCount) {
      $status .= $volume->errorCount." errors: ";
    }
    if (exists($opts{'e'}) && defined($volume->errorCount)) {
      if ($opts{'e'} == 0) {
        $reportOn &&= ($volume->errorCount == 0)
      }
      elsif ($opts{'e'} > 0) {
        $reportOn &&= ($volume->errorCount >= $opts{'e'})
      }
      else {
        $reportOn &&= ($volume->errorCount < -$opts{'e'})
      }
    }

    if ($volume->suspended) {
      $status .= "Suspended: ";
    }

    if ($volume->frozen) {
      $status .= "Frozen: ";
    }
    $reportOn &&= $volume->frozen if (exists($opts{'f'}));
    $reportOn &&= !$volume->frozen if (exists($opts{'F'}));

    if ($volume->robot) {
      $status .= "in R".$volume->robot->id.".".sprintf("%03d", $volume->slot);
    }
    else {
    }

    if ($volume->allocated) {
      $status .= "Allocated to ".$volume->mmdbHost->name.": ";
      if ($volume->expires > time) {
        $status .= "Expires ".localtime($volume->expires).": ";
      }
      else {
        $status .= "Expired ".localtime($volume->expires).": ";
      }
      $status .= "Retention level ".$volume->retention->level." " if ($opts{'r'});
    }
    $reportOn &&= $volume->allocated if (exists($opts{'a'}));
    $reportOn &&= !$volume->allocated if (exists($opts{'A'}));
  }

  if ($reportOn) {
    if ($opts{'c'}) {
      print "\"".join('","', $volume->id, $volume->pool->name, $volume->group,
                  $volume->errorCount, $volume->mountCount, $volume->maxMounts,
                  $volume->allocated ? substr(localtime($volume->expires), 4) : "",
                  $volume->robot ? $volume->robot->id : "",
                  $volume->robot ? $volume->slot : "",
            ).
            "\"\n";
    }
    else {
      print "$status\n";
      if ($opts{'l'} && $volume->allocated) {
	my $n = 1;
	foreach my $fragment ($volume->tableOfContents) {
	  printf(" %3u:", $n);

	  my $image = $fragment->image;
	  print "Fragment ".$fragment->id." of ".$image->class->name." from ".$image->client->name.": ";
	  print "Expires ".localtime($image->expires)."\n";

	  $n++;
	}
      }
    }
  }

  if ($opts{'s'} && ($volume->errorCount > 1)) {
    $volume->freeze;
  }
}

=head1 NAME

volume-status.pl - Volume attribute analysis tool

=head1 SYNOPSIS

    volume-status.pl [-c] [-pgr] [-lsU] [-fF] [-aA] [-e error-threshold] [-m mount-threshold]

=head1 DESCRIPTION

For each volume label provided on standard input, subject to numerous options, the
following information is printed on STDOUT:

=over 4

=item volume label

=item mount count

=item volume pool only if B<-p> is set

=item volume group only if B<-g> is set

=item error count (if non-zero)

The error count assigned to a volume is simply read from the file /usr/local/etc/media-errors.csv;
it is up to the local system administrators to gather the output of the tool L<volstats.pl|volstats.pl> from
each media server and concatenate the data-sets into the above mentioned file.

=item suspended or frozen status

=item robot number if the volume is currently in a robot

=back

The following information only applies to volumes that are currently in use:

=over 4

=item expiration status

=item retention level only if B<-r> is set

=back

=head1 SEE ALSO

=over 4

=item L<volume-list.pl|volume-list.pl>, L<toc.pl|toc.pl>

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
