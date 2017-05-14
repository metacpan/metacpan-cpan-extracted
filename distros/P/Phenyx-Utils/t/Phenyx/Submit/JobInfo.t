#!/usr/bin/env perl
use Test::More tests=>7;
use File::Basename;
use strict;

my $dn=dirname $0;
use_ok('Phenyx::Utils::LSF::JobInfo');

$Phenyx::Utils::LSF::JobInfo::CHEAT_BJOBS_COMMAND="cat $dn/bjobs.out";
my %jobs=Phenyx::Utils::LSF::JobInfo::parseBJobs();
is (keys %jobs, 2, "two jobs registered in demo output");
is (scalar  @{$jobs{850381}{EXEC_HOST}}, 4, "4 host for job 850381");
is (Phenyx::Utils::LSF::JobInfo::jobInfo(850380, 'STAT', ), 'DONE', "job 850380 returns STAT='DONE'");
