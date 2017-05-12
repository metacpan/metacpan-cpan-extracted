#!/usr/bin/env  perl

# read pidlist avery N seconds and (kill -9|STOP) a random pid
# usage mpd-kill.pl --time=5 --hostname=node-0.phenyxtest --username=evaleto --loop

use Data::Dumper;
use Parallel::Mpich::MPD;
use threads;

use Getopt::Long;
my($time, $verbose, $loop, $parallel, $hosts);
$time=1;
$usename="evaleto";
if (!GetOptions(
		"time=s"=>\$time,
		"verbose" =>\$verbose,
 		"parallel=s" =>\$parallel,
 		"hosts=s" =>\$hosts,
		"loop" =>\$loop,
)|!defined($time)|!defined($parallel)){
  printf STDERR "Usage:\n";
  printf STDERR "mpdruns --time=20 --parallel=5\n\n";
  exit 1;
}



$Parallel::Mpich::MPD::Common::DEBUG=1;
#$Parallel::Mpich::MPD::Common::WARN=1;

Parallel::Mpich::MPD::Common::env_Check();
Parallel::Mpich::MPD::Common::env_Print();
Parallel::Mpich::MPD::boot();
print "#running mpiexec\n";
print "#\n";


sub thread_entry{
  my $stdout="";
  my $stderr="";
  my $pid="";
  my $alias=Parallel::Mpich::MPD::makealias();
  print "\nrunning: /opt/rockAround 100000 100 [alias=$alias]\n";
  print "------------------------------------------------------\n";
  Parallel::Mpich::MPD::createJob(cmd => '/opt/rockAround', params => '100000 100', alias => $alias, machinesfile => $hosts, pid=>\$pid, stdout => \$stdout, stderr=> \$stderr);
  
  print "job->alias[$alias] --->[pid=$pid]\n"; 
  print "                   +-->[out]\n$stdout\n"; 
  print "                   +-->[err]\n$stderr\n";  
  print "------------------------------------------------------\n\n\n\n";
}

do{
  for ($i=0;$i<$parallel;$i++){
    threads->new(\&thread_entry);
  }
  sleep $time;
}while (1 && defined($loop));

