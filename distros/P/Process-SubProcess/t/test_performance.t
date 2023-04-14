#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2020-09-20
# @package Test for the Process::SubProcess Module
# @subpackage test_performance.t

# This Module runs tests on the Process::SubProcess Module
#
#---------------------------------
# Requirements:
# - The Perl Module "Process::SubProcess" must be installed
#



use warnings;
use strict;

use Cwd qw(abs_path);

use Time::HiRes qw(gettimeofday);

use Capture::Tiny qw(capture);

use Test::More;

BEGIN
{
  use lib "lib";
  use lib "../lib";
}  #BEGIN

require_ok('Process::SubProcess');

use Process::SubProcess qw(runSubProcess);



my $smodule = "";
my $spath = abs_path($0);


($smodule = $spath) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;


my $stestscript = "test_script.pl";
my $itestpause = 3;
my $iteststatus = 4;

my $proctest = undef;

my $rscriptlog = undef;
my $rscripterror = undef;
my $iscriptstatus = -1;


#------------------------
#Test: 'Read Timeout'

my $itm = -1;
my $itmstrt = -1;
my $itmend = -1;
my $itmtst = -1;
my $itmexe = -1;

$itestpause = 3;


print "Test: 'Read Timeout' do ...\n";

$proctest = Process::SubProcess::->new(('command' => $spath . $stestscript . ' ' . $itestpause
  , 'check' => 2, 'profiling' => 1));

isnt($proctest->getReadTimeout, 0, 'Read Timeout activated');
is($proctest->isProfiling, 1, 'Profiling activated');

$itmstrt = gettimeofday();

print "script '$stestscript' Start - Time Now: '$itmstrt' s\n";

is($proctest->Run, 1, "script '$stestscript': Execution correct");

$itmend = gettimeofday();

$itm = ($itmend - $itmstrt) * 1000;

print "script '$stestscript' End - Time Now: '$itmend' s\n";

print "script '$stestscript' run in '$itm' ms\n";

$rscriptlog = $proctest->getReportString;
$rscripterror = $proctest->getErrorString;
$iscriptstatus = $proctest->getProcessStatus;

isnt($proctest->getExecutionTime, -1 , "Execution Time was measured");

print("Read Timeout: '", $proctest->getReadTimeout, "'\n");
print("Execution Time: '", $proctest->getExecutionTime, "'\n");

print("EXIT CODE: '$iscriptstatus'\n");

if(defined $rscriptlog)
{
  print("STDOUT: '$$rscriptlog'\n");
}
else
{
  isnt($$rscriptlog, undef, "STDOUT was captured");
} #if(defined $rscriptlog)

if(defined $rscripterror)
{
  print("STDERR: '$$rscripterror'\n");
}
else
{
  isnt($$rscripterror, undef, "STDERR was captured");
} #if(defined $rscripterror)

print "\n";


#------------------------
#Test: 'Read Timeout Quiet'

$proctest = undef;

$stestscript = 'quiet_script.pl';
$itestpause = 3;

$itm = -1;
$itmstrt = -1;
$itmend = -1;
$itmtst = -1;
$itmexe = -1;


print "Test: 'Read Timeout Quiet' do ...\n";

$proctest = Process::SubProcess::->new(('command' => $spath . $stestscript . ' ' . $itestpause));

$proctest->setReadTimeout(2);
#Reenable Profiling
$proctest->setProfiling;

is($proctest->getReadTimeout, 2, 'Read Timeout activated');
is($proctest->isProfiling, 1, 'Profiling enabled');

$itmstrt = gettimeofday();

print "script '$stestscript' Start - Time Now: '$itmstrt' s\n";

is($proctest->Run, 1, "script '$stestscript': Execution finished correctly");

$itmend = gettimeofday();

$itm = ($itmend - $itmstrt) * 1000;

print "script '$stestscript' End - Time Now: '$itmend' s\n";

print "script '$stestscript' run in '$itm' ms\n";

$rscriptlog = $proctest->getReportString;
$rscripterror = $proctest->getErrorString;
$iscriptstatus = $proctest->getProcessStatus;

$itmtst = sprintf('%d', ($itm / 1000));
$itmexe = sprintf('%d', $proctest->getExecutionTime);

is($itmexe, $itmtst, "Execution Time = Test Time");

isnt($itmexe % $proctest->getReadTimeout, 0, "Execution Time does not depend on Read Timeout");

print("Read Timeout: '", $proctest->getReadTimeout, "'\n");
print("Execution Time: '", $proctest->getExecutionTime, "'\n");

print("EXIT CODE: '$iscriptstatus'\n");

if(defined $rscriptlog)
{
  print("STDOUT: '$$rscriptlog'\n");
}
else
{
  isnt($$rscriptlog, undef, "STDOUT was captured");
} #if(defined $rscriptlog)

if(defined $rscripterror)
{
  print("STDERR: '$$rscripterror'\n");
}
else
{
  isnt($$rscripterror, undef, "STDERR was captured");
} #if(defined $rscripterror)

print "\n";


#------------------------
#Test: 'Capture::Tiny Profiling'

print "Test: 'Capture::Tiny Profiling' do ...\n";

$stestscript = 'test_script.pl';

$itmstrt = gettimeofday();

print "script '$stestscript' Start - Time Now: '$itmstrt' s\n";

($$rscriptlog, $$rscripterror, $iscriptstatus) = capture { system($spath . $stestscript); };

$itmend = gettimeofday();

$itm = ($itmend - $itmstrt) * 1000;

print "script '$stestscript' End - Time Now: '$itmend' s\n";

print "script '$stestscript' run in '$itm' ms\n";

print("EXIT CODE: '$iscriptstatus'\n");

if(defined $rscriptlog)
{
  print("STDOUT: '$$rscriptlog'\n");
}
else
{
  isnt($$rscriptlog, undef, "STDOUT was captured");
} #if(defined $rscriptlog)

if(defined $rscripterror)
{
  print("STDERR: '$$rscripterror'\n");
}
else
{
  isnt($$rscripterror, undef, "STDERR was captured");
} #if(defined $rscripterror)

print "\n";


#------------------------
#Test: 'Profiling'

$proctest = undef;

$itm = -1;
$itmstrt = -1;
$itmend = -1;
$itmexe = -1;

print "Test: 'Profiling' do ...\n";

$proctest = Process::SubProcess::->new(('command' => $spath . $stestscript
  , 'profiling' => 1));

is($proctest->isProfiling, 1, 'Profiling activated');

$itmstrt = gettimeofday();

print "script '$stestscript' Start - Time Now: '$itmstrt' s\n";

is($proctest->Run, 1, "script '$stestscript': Execution correct");

$itmend = gettimeofday();

$itm = ($itmend - $itmstrt) * 1000;

print "script '$stestscript' End - Time Now: '$itmend' s\n";

print "script '$stestscript' run in '$itm' ms\n";

$rscriptlog = $proctest->getReportString;
$rscripterror = $proctest->getErrorString;
$iscriptstatus = $proctest->getProcessStatus;

isnt($proctest->getExecutionTime, -1 , "Execution Time was measured");

print("Execution Time: '", $proctest->getExecutionTime, "'\n");

print("EXIT CODE: '$iscriptstatus'\n");

if(defined $rscriptlog)
{
  print("STDOUT: '$$rscriptlog'\n");
}
else
{
  isnt($$rscriptlog, undef, "STDOUT was captured");
} #if(defined $rscriptlog)

if(defined $rscripterror)
{
  print("STDERR: '$$rscripterror'\n");
}
else
{
  isnt($$rscripterror, undef, "STDERR was captured");
} #if(defined $rscripterror)

print "\n";


done_testing();

