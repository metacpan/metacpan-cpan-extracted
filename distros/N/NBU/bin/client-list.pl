#!/usr/local/bin/perl

use strict;

use Getopt::Std;

my %opts;
getopts('ismodv', \%opts);

use NBU;
NBU->debug($opts{'d'});

NBU::Host->populate(1);
NBU::Class->populate if ($opts{'m'} || $opts{'s'});

my %osList;
foreach my $client (sort {$a->name cmp $b->name} (NBU::Host->list)) {
  my $cn = $client->name;

  print $client->name;
  if ($opts{'v'}) {
      my $version = $client->NBUVersion;
      print ": $version";
      my $release = $client->releaseID;
      print " - $release";
  }
  if ($opts{'i'} || $opts{'s'}) {
    my $ip = $client->IPaddress;
    if (defined($ip)) {
      print ": $ip";
    }
  }
  if ($opts{'o'} || $opts{'s'}) {
    my $os = $client->os;
    if (!defined($os) || ($os =~ /^[\s]*$/)) {
#      print STDERR "Missing os information for $cn\n"
    }
    else {
      print ": $os" if ($opts{'o'});
      $osList{$os} += 1;
    }
  }
  if ($opts{'m'} || $opts{'s'}) {
    my @l = $client->classes;
    print "\n " if ($opts{'m'});
    foreach my $class (@l) {
      print " ".$class->name if ($opts{'m'});
    }
  }
  print "\n";
}

if ($opts{'s'}) {
  for my $os (sort (keys %osList)) {
    printf("%10s: %3d\n", $os, $osList{$os});
  }
}
