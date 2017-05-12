#!/usr/local/bin/perl

use strict;

use Getopt::Std;

use NBU;

my %opts;
getopts('dR', \%opts);

NBU->debug($opts{'d'});


my $name = $0;  $name =~ s /^.*\/([^\/]+)\.pl$/$1/;

NBU::Media->populate(1);

my $m = NBU::Media->new($ARGV[0]);
while (<STDIN>) {
  my $m;
  chop;
  if (!defined($m = NBU::Media->byID($_))) {
    print STDERR "No such volume as $_\n";
  }

  if ($name =~ /^freeze$/) {
print STDERR "Freezing ".$m->id."\n";
    $m->freeze;
  }
  elsif ($name =~ /^(unfreeze|thaw)$/) {
print STDERR "Thawing ".$m->id."\n";
    $m->unfreeze;
  }
}
