#!/usr/local/bin/perl -w

use strict;

use Getopt::Std;

my %opts;
getopts('?ucxd', \%opts);

if ($opts{'?'}) {
  print STDERR <<EOT;
Usage: coverage.pl [-x] [-u|-c] [hostname [hostname ...]]
Options:
  -u       Only list uncovered mountpoints
  -c       Only list covered mountpoints

  -x       Produce xml output
EOT
  exit;
}


use NBU;
NBU->debug($opts{'d'});

NBU::Class->populate;

my @clients;
if ($#ARGV > -1 ) {
  for my $clientName (@ARGV) {
    push @clients, NBU::Host->new($clientName);
  }
}
else {
  NBU::Host->populate(1);
  @clients = (sort {$a->name cmp $b->name} (NBU::Host->list));
}

if ($opts{'x'}) {
  print "<?xml version=\"1.0\"?>\n";
  print "<coverage>\n";
}
foreach my $client (@clients) {
  my $cn = $client->name;

  if ($opts{'x'}) {
    print "  <host name=\"$cn\">";
  }
  else {
    print "$cn:";
  }
  my %mountPointList = $client->coverage;
  foreach my $mp (sort (keys %mountPointList)) {
    my $clR = $mountPointList{$mp};
    my $mpStatus = ($opts{'x'} ? "    <mountpoint path=\"$mp\">" : "\t$mp:");
    my $disposition;
    my $covered;
    if ($clR) {
      foreach my $class (@$clR) {
	my $cn = $class->name;
	if ($class->active) {
          if ($opts{'c'} || !$opts{'u'}) {
	    $mpStatus .= ($opts{'x'} ? "\n      <covered policy=\"$cn\" active=\"1\" />" : " $cn");
          }
	  $covered += 1;
	}
	else {
	  if ($opts{'u'} || !$opts{'c'}) {
	    $mpStatus .= ($opts{'x'} ? "\n    <covered policy=\"$cn\" active=\"0\" />" : " ($cn)");
          }
	}
      }
    }
    else {
      $mpStatus .= " not covered" if (!$opts{'x'});
    }
    $mpStatus .= "\n    </mountpoint>" if ($opts{'x'});
    if ((!$opts{'u'} && !$opts{'c'}) ||
	($opts{'u'} && !$covered) ||
	($opts{'c'} && $covered)) {
      print "\n$mpStatus";
    }
  }

  if (!$opts{'x'}) {
    if ($opts{'c'} || !$opts{'u'}) {
      my $sep = "\n\tadditional active classes are: ";
      foreach my $class ($client->classes) {
        if ($class->active && !$class->providesCoverage) {
  	print $sep.$class->name;
  	$sep = " ";
        }
      }
    }
  
    if ($opts{'u'} || !$opts{'c'}) {
      my $sep = "\n\tadditional inactive classes are: ";
      foreach my $class ($client->classes) {
        if (!$class->active && !$class->providesCoverage) {
  	print $sep."(".$class->name.")";
  	$sep = " ";
        }
      }
    }
  }
  print "\n";
  if ($opts{'x'}) {
    print "  </host>\n\n";
  }
}
print "</coverage>\n" if ($opts{'x'});

=head1 NAME

coverage.pl - Analyze Which File-Systems (if any) Are Backed Up

=head1 SYNOPSIS

coverage.pl [options...] [hostname [hostname ...]]

=head1 DESCRIPTION

NetBackup's command line utility B<bpcoverage> provides most of the fodder
for this script.  However, by pulling in information on all the policies
of which the list of hosts are members a more complete picture can be drawn.

By default all file-systems on each host are listed along with all policies that
explicitly reference them.  Inactive policies are shown in parentheses.

Policies which apply to the client but do not reference a particular file-system
are listed separately.  These could be policies associated with database extension
agents, or simply policies with file-lists with entries starting somewhere below
any file-system mount-points.

For Windows based hosts substitute the concept of mount-point with drive-letter.  Note that
NetBackup is very strict about wanting the drive-letter references in the policy file-list
in upper case, with the colon but without a leading back-slash.

Without any hostnames, coverage.pl will list coverage information on all
clients known to the master server.

=head1 OPTIONS

=item L<-c|-c>

Only list file-systems that are covered.

=item L<-u|-u>

Only list file-systems that are uncovered.

=item L<-x|-x>

Produce output in XML format

=over 4

=back

=head1 AUTHOR

Winkeler, Paul pwinkeler@pbnj-solutions.com

=head1 COPYRIGHT

Copyright (C) 2002 Paul Winkeler

=cut
