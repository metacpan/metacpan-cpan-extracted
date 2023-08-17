#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests=>2;
use FindBin qw/$RealBin/;
use lib "$RealBin/../lib";

use_ok 'Schedule::SGELK';

subtest 'general' => sub{
  mkdir "SGELK.log";
  my $sge=Schedule::SGELK->new(verbose=>1,numnodes=>1,numcpus=>2,workingdir=>"SGELK.log/",waitForEachJobToStart=>1,noqsub=>1);

  my $job = $sge->pleaseExecute("ls $0 > $RealBin/ls.out");
  my $job2= $sge->pleaseExecute("hostname > $RealBin/hostname.txt");
  $sge->wrapItUp();

  $sge->waitOnJobs([$job,$job2], 1);

  my $lsContent = readFile("$RealBin/ls.out");
  is($lsContent, "$0\n", "ran ls correctly");

  my $hostnameContent = readFile("$RealBin/hostname.txt");
  is($hostnameContent, `hostname`, "ran hostname correctly");
};

sub readFile{
  my($file) = @_;
  local $/ = undef;

  open(my $fh, $file) or die "ERROR: could not read $file: $!";
  my $content = <$fh>;
  close $fh;

  return $content;
}

