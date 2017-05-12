#!/usr/local/bin/perl

use Getopt::Std;

use NBU;

my %opts;
getopts('d', \%opts);

NBU->debug($opts{'d'});

print NBU->me->name." is part of this cluster of NetBackup servers:\n";
for my $s (NBU->servers) {
  print " ".$s->name."(".$s->NBUVersion.")\n";
}

print "Where";
for my $s (NBU->masters) {
  print " ".$s->name;
}
print " acts as master and job notifications are ";
print !defined(NBU->adminAddress) ? "not sent out" : "sent to ".NBU->adminAddress;
print "\nMaximum ".NBU->maxJobsPerClient." jobs per client\n";
print "\n";
