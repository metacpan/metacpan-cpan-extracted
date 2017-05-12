#!/usr/bin/env  perl
use strict;
use Data::Dumper;
use IO::All;

use Test::More tests => 14;

use_ok('Parallel::Mpich::MPD' );
$Parallel::Mpich::MPD::Common::TEST=1;

use File::Basename;
my $contents=io(dirname($0)."/mpdlistjobs-1.txt")->slurp;

Parallel::Mpich::MPD::listJobs(mpdlistjobs_contents=>$contents);

#check  empty results
ok(! defined Parallel::Mpich::MPD::findJob(jobid=>'blabla', return=>'getone'), "not possible to find such a jobid");
ok(! defined Parallel::Mpich::MPD::findJob(jobalias=>'blabla', return=>'getone'), "not possible to find such a jobalias");
ok(! defined Parallel::Mpich::MPD::findJob(username=>'blabla', return=>'getone'), "not possible to find such a username");


#check one el results
my $job=Parallel::Mpich::MPD::findJob(jobid=>'4@olavdev_43130', return=>'getone');
ok($job, "one job selected on unique jobid");
is($job->username, 'joe', "check for good username");


#waiting one el produce multiple!
eval{
  $job=Parallel::Mpich::MPD::findJob(username=>'joe', return=>'getone');
};
#check error message (a die should have been thrown)
if($@){
  ok($@=~/too many matches/, "too many have been correctly detected with findJob return=>'getone' argument");
}else{
  fail("not error was rejected with findJob return=>'getone' argument, on multiple results");
}


#waiting multiple
my %jobs=Parallel::Mpich::MPD::findJob(jobid=>['4@olavdev_43130', '62@olavdev_43130']);
is(scalar keys %jobs, 2, "located two jobs");
is($jobs{'4@olavdev_43130'}->username, 'joe', "job valkue seems coherent 1");
is($jobs{'62@olavdev_43130'}->username, 'alex', "job valkue seems coherent 2");

%jobs=Parallel::Mpich::MPD::findJob(username=>['joe']);
is(scalar keys %jobs, 3, "located  jobs on username");

%jobs=Parallel::Mpich::MPD::findJob(jobalias=>['alias-1']);
is(scalar keys %jobs, 2, "located  jobs on jobalias");


#getting the a hash host=>array of pids on the host
my %h2pids=Parallel::Mpich::MPD::findJob(username=>'joe', return=>'host2pidlist');


ok(%h2pids, "return a hash host2pidlist for given username");
is (scalar keys %{$h2pids{'vs-node-1'}}, 1, "number of proc for given host seems coherent");
