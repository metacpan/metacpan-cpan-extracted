#!/usr/bin/env  perl
use Data::Dumper;
use English;
use Test::More tests => ($ENV{MPICH_MPD_TEST})?15:3;

use_ok('Parallel::Mpich::MPD');
use File::Basename;

my ($cmd, $parms)=0?("burncpu.pl", "--time=20 --cpu=1"):("sleep", "20");

### THIS TEST COULD BE AUTOMATIZED
#$Parallel::Mpich::MPD::Common::DEBUG=1;
$Parallel::Mpich::MPD::Common::WARN=1;
$Parallel::Mpich::MPD::Common::TEST=1;
my $jobs;
my $job;

ok(Parallel::Mpich::MPD::Common::env_Hostsfile(dirname(0)."/t/localhost"),"set hostfile :".dirname(0)."/localhost");
Parallel::Mpich::MPD::Common::env_Check();
ok(Parallel::Mpich::MPD::Common::env_Print(), "print environment ");

exit 0 unless $ENV{MPICH_MPD_TEST};

print STDERR "\n\n# ------------------->the «ssh localhost» will be called for each command...\n";
print STDERR "# ------------------->ENTER PASSWORD \n\n";

ok(print Parallel::Mpich::MPD::check(), "check mpd if not already up");

unless(ok(Parallel::Mpich::MPD::boot(), "boot mpd if not already up")) {
  die "";
}


my $alias1=Parallel::Mpich::MPD::makealias();
ok(Parallel::Mpich::MPD::createJob(cmd => $cmd, params => $parms, ncpu => '2', alias => $alias1, spawn=>1), "create a new spawned job $alias1");
Parallel::Mpich::MPD::waitJobRegistration($alias1);
my $alias2=Parallel::Mpich::MPD::makealias();
ok(Parallel::Mpich::MPD::createJob(cmd => $cmd, params => $parms, ncpu => '2', alias => $alias2, spawn=>1), "create a new a new spawned job $alias2");
ok(defined(Parallel::Mpich::MPD::listJobs()), "get all jobs information");

print "#\n";
print "#\n";
print "# find one job\n"; 
ok(defined($job=Parallel::Mpich::MPD::findJob(jobalias => $alias1, return => 'getone')), "find a job information");
print "JOB=".$job."\n";




ok($job->sigstop(),"stop the current job for 8 sec.");
ok($job->sigcont(),"continue the current job");
ok($job->kill(),"kill the current job");
my %trace="";
ok(Parallel::Mpich::MPD::trace(hosts=>\%trace), "trace jobs");
print "mpdtrace: ".Dumper \%trace;
ok(Parallel::Mpich::MPD::shutdown(), "shutdown mpd");
ok(Parallel::Mpich::MPD::clean(pkill=>1), "clean jobs");

