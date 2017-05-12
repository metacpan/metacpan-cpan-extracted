#!/usr/bin/env  perl
use Data::Dumper;

use Test::More tests => 10;

use_ok('Parallel::Mpich::MPD' );


#$Parallel::Mpich::MPD::Common::DEBUG=1;
#$Parallel::Mpich::MPD::Common::WARN=1;
$Parallel::Mpich::MPD::Common::TEST=1;
my $jobs;
my $job;

#
#$in1 normal search
# 
my $in1='
jobid    = 1@genebio-95_33086
jobalias = job1
username = root
host     = genebio-95
pid      = 24553
sid      = 24552
rank     = 1
pgm      = sleep

jobid    = 1@genebio-95_33086
jobalias = job1
username = root
host     = genebio-96
pid      = 24554
sid      = 24551
rank     = 0
pgm      = sleep

jobid    = 2@genebio-95_33086
jobalias =
username = root
host     = genebio-95
pid      = 24561
sid      = 24558
rank     = 0
pgm      = sleep

jobid    = 2@genebio-95_66666
jobalias =
username = root
host     = genebio-95
pid      = 24560
sid      = 24559
rank     = 1
pgm      = sleep';




# create jobs info
Parallel::Mpich::MPD::__jobsFactory($in1);

ok(defined($job=Parallel::Mpich::MPD::findJob(jobalias => 'job1', return=>'getone')), "find ONE job for alias job1");
ok($job->jobid eq '1@genebio-95_33086', "result should contains an object  job->jobid==1\@genebio-95_33086");

$job=Parallel::Mpich::MPD::findJob(jobalias => 'job34', getone => '1');
ok(%$job eq "0", "find the UNDEF job for alias job34");

ok(defined($jobs=Parallel::Mpich::MPD::findJob(jobalias => 'job1')), "find jobs? for alias job1");
ok(defined($jobs->{'1@genebio-95_33086'}), "result should contains 1\@genebio-95_33086");
#print Dumper($jobs);

ok(defined($jobs=Parallel::Mpich::MPD::findJob(username => 'root')), "find jobs for user root");
ok(defined($jobs->{'1@genebio-95_33086'}), "result should contains 1\@genebio-95_33086");
ok(defined($jobs->{'2@genebio-95_33086'}), "result should contains 2\@genebio-95_33086");
ok(defined($jobs->{'2@genebio-95_66666'}), "result should contains 2\@genebio-95_66666");

#ok(defined($jobs=Parallel::Mpich::MPD::findJob(pid => '24560')), "find jobs? for pid 24560");
#ok(defined($jobs->{'2@genebio-95_66666'}), "result should 2@\genebio-95_66666");
#print Dumper($jobs);




