#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2023-12-30
# @package Test for the Process::SubProcess::Group Module
# @subpackage t/test_group.t

# This Module runs tests on the Process::SubProcess::Group Module
#
#---------------------------------
# Requirements:
# - The Perl Module "Process::SubProcess::Group" must be installed
#

use warnings;
use strict;

use Cwd qw(abs_path);

use Time::HiRes qw(gettimeofday);

use Test::More;

BEGIN {
    use lib "lib";
    use lib "../lib";
}    #BEGIN

require_ok('Process::SubProcess');
require_ok('Process::SubProcess::Group');

use Process::SubProcess;
use Process::SubProcess::Group;

my $smodule = "";
my $spath   = abs_path($0);

( $smodule = $spath ) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;

my $stestscript = "test_script.pl";
my $itestpause  = 3;
my $iteststatus = 4;

my $procgroup = undef;
my $proctest  = undef;

my $rscriptlog    = undef;
my $rscripterror  = undef;
my $iscriptstatus = -1;

my $itm     = -1;
my $itmstrt = -1;
my $itmend  = -1;
my $itmexe  = -1;

my $iprc    = -1;
my $iprccnt = -1;

my $iprctmoutcnt = -1;

subtest 'Process::SubProcess::Group::Run' => sub {

    $procgroup = Process::SubProcess::Group::->new;

    $itestpause = 2;

    $proctest = Process::SubProcess::->new(
        (
            'name'    => 'test-script:2s',
            'command' => $spath . $stestscript . ' ' . $itestpause
        )
    );

    $procgroup->add($proctest);

    $itestpause = 3;

    $proctest = Process::SubProcess::->new(
        (
            'name'    => 'test-script:3s',
            'command' => $spath . $stestscript . ' ' . $itestpause
        )
    );

    $procgroup->add($proctest);

    $itestpause = 1;

    $proctest = Process::SubProcess::->new(
        (
            'name'    => 'test-script:1s',
            'command' => $spath . $stestscript . ' ' . $itestpause
        )
    );

    $procgroup->add($proctest);

    $iprccnt = $procgroup->getProcessCount;

    is( $iprccnt, 3, "scripts (count: '$iprccnt'): added correctly" );

    $itmstrt = gettimeofday();

    print "Process Group Execution Start - Time Now: '$itmstrt' s\n";

    is( $procgroup->Run, 1, "Process Group Execution: Execution correct" );

    $itmend = gettimeofday();

    $itm = ( $itmend - $itmstrt ) * 1000;

    print "Process Group Execution End - Time Now: '$itmend' s\n";

    print "Process Group Execution finished in '$itm' ms\n";

    for ( $iprc = 0 ; $iprc < $iprccnt ; $iprc++ ) {
        $proctest = $procgroup->getiProcess($iprc);

        isnt( $proctest, undef, "Process No. '$iprc': Listed correctly" );

        if ( defined $proctest ) {
            print( "Process ", $proctest->getNameComplete, ":\n" );

            $rscriptlog    = $proctest->getReportString;
            $rscripterror  = $proctest->getErrorString;
            $iscriptstatus = $proctest->getProcessStatus;

            print( "ERROR CODE: '", $proctest->getErrorCode, "'\n" );
            print("EXIT CODE: '$iscriptstatus'\n");

            if ( defined $rscriptlog ) {
                print("STDOUT: '$$rscriptlog'\n");
            }
            else {
                isnt( $rscriptlog, undef, "STDOUT was captured" );
            }    #if(defined $rscriptlog)

            if ( defined $rscripterror ) {
                print("STDERR: '$$rscripterror'\n");
            }
            else {
                isnt( $rscripterror, undef, "STDERR was captured" );
            }    #if(defined $rscripterror)
        }    #if(defined $proctest)
    }    #for($iprc = 0; $iprc < $iprccnt; $iprc++)
};

subtest 'Process::SubProcess::Group Profiling' => sub {

    subtest 'Process::SubProcess::Group Profiling Verbose' => sub {

        $procgroup = Process::SubProcess::Group::->new( ( 'check' => 2 ) );

        $itestpause = 3;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:3s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 5;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:5s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 9;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:9s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $iprccnt = $procgroup->getProcessCount;

        is( $iprccnt, 3, "scripts (count: '$iprccnt'): added correctly" );

        $itmstrt = gettimeofday();

        print "Process Group Execution Start - Time Now: '$itmstrt' s\n";

        is( $procgroup->Run, 1, "Process Group Execution: Execution correct" );

        $itmend = gettimeofday();

        $itm = ( $itmend - $itmstrt ) * 1000;

        print "Process Group Execution End - Time Now: '$itmend' s\n";

        print "Process Group Execution finished in '$itm' ms\n";

        for ( $iprc = 0 ; $iprc < $iprccnt ; $iprc++ ) {
            $proctest = $procgroup->getiProcess($iprc);

            isnt( $proctest, undef, "Process No. '$iprc': Listed correctly" );

            if ( defined $proctest ) {
                print( "Process ", $proctest->getNameComplete, ":\n" );

                $rscriptlog    = $proctest->getReportString;
                $rscripterror  = $proctest->getErrorString;
                $iscriptstatus = $proctest->getProcessStatus;

                isnt( $proctest->getExecutionTime,
                    -1, "Execution Time was measured" );

                print( "Read Timeout: '", $proctest->getReadTimeout, "'\n" );
                print( "Execution Time: '", $proctest->getExecutionTime,
                    "'\n" );

                print("EXIT CODE: '$iscriptstatus'\n");

                if ( defined $rscriptlog ) {
                    print("STDOUT: '$$rscriptlog'\n");
                }
                else {
                    isnt( $rscriptlog, undef, "STDOUT was captured" );
                }    #if(defined $rscriptlog)

                if ( defined $rscripterror ) {
                    print("STDERR: '$$rscripterror'\n");
                }
                else {
                    isnt( $rscripterror, undef, "STDERR was captured" );
                }    #if(defined $rscripterror)
            }    #if(defined $proctest)
        }    #for($iprc = 0; $iprc < $iprccnt; $iprc++)
    };
    subtest 'Process::SubProcess::Group Profiling Quiet' => sub {

        my $itesttime = -1;

        $procgroup = Process::SubProcess::Group::->new( ( 'check' => 2 ) );

        $stestscript = 'quiet_script.pl';
        $itestpause  = 3;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'quiet-script:3s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 5;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'quiet-script:5s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 9;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'quiet-script:9s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $iprccnt = $procgroup->getProcessCount;

        is( $iprccnt, 3, "scripts (count: '$iprccnt'): added correctly" );

        $procgroup->setCheckInterval(6);

        isnt( $procgroup->getCheckInterval, -1, "Read Timeout activated" );

        $itmstrt = gettimeofday();

        print "Process Group Execution Start - Time Now: '$itmstrt' s\n";

        is( $procgroup->Run, 1, "Process Group Execution: Execution correct" );

        $itmend = gettimeofday();

        $itm = ( $itmend - $itmstrt ) * 1000;

        print "Process Group Execution End - Time Now: '$itmend' s\n";

        print "Process Group Execution finished in '$itm' ms\n";

        for ( $iprc = 0 ; $iprc < $iprccnt ; $iprc++ ) {
            $proctest = $procgroup->getiProcess($iprc);

            isnt( $proctest, undef, "Process No. '$iprc': Listed correctly" );

            if ( defined $proctest ) {
                print(
                    "Process ",
                    $proctest->getNameComplete,
                    " finished with [" . $proctest->getErrorCode . "]:\n"
                );

                $rscriptlog    = $proctest->getReportString;
                $rscripterror  = $proctest->getErrorString;
                $iscriptstatus = $proctest->getProcessStatus;

                isnt( $proctest->getExecutionTime,
                    -1, "Execution Time was measured" );

                print( "Read Timeout: '", $proctest->getReadTimeout, "'\n" );
                print( "Execution Time: '", $proctest->getExecutionTime,
                    "'\n" );

                print( "ERROR CODE: '", $proctest->getErrorCode, "'\n" );
                print("EXIT CODE: '$iscriptstatus'\n");

                if ( defined $rscriptlog ) {
                    print("STDOUT: '$$rscriptlog'\n");
                }
                else {
                    isnt( $rscriptlog, undef, "STDOUT was captured" );
                }    #if(defined $rscriptlog)

                if ( defined $rscripterror ) {
                    print("STDERR: '$$rscripterror'\n");
                }
                else {
                    isnt( $rscripterror, undef, "STDERR was captured" );
                }    #if(defined $rscripterror)
            }    #if(defined $proctest)
        }    #for($iprc = 0; $iprc < $iprccnt; $iprc++)
    };
};

subtest 'Process::SubProcess::Group Runtime Checks' => sub {

    subtest 'Process::SubProcess::Group Execution Timeout' => sub {

        $iprctmoutcnt = -1;

        $procgroup =
          Process::SubProcess::Group::->new( ( 'timeout' => 7, 'debug' => 1 ) );

        $stestscript = "test_script.pl";
        $itestpause  = 3;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:3s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 5;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:5s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 15;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:15s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $iprccnt = $procgroup->getProcessCount;

        is( $iprccnt, 3, "scripts (count: '$iprccnt'): added correctly" );

        $procgroup->setCheckInterval(6);

        isnt( $procgroup->getCheckInterval, -1, "Check Interval activated" );
        isnt( $procgroup->getTimeout,       -1, "Execution Timeout activated" );

        $itmstrt = gettimeofday();

        print "Process Group Execution Start - Time Now: '$itmstrt' s\n";

        is( $procgroup->Run, 0,
            "Process Group Execution: Execution failed as expected" );

        $itmend = gettimeofday();

        $itm = ( $itmend - $itmstrt ) * 1000;

        print "Process Group Execution End - Time Now: '$itmend' s\n";

        print "Process Group Execution finished in '$itm' ms\n";

        print(
            "Process Group ERROR CODE: '" . $procgroup->getErrorCode . "'\n" );

        is( $procgroup->getErrorCode, 4,
            "Process Group Execution: ERROR CODE '4' as expected" );

        print(  "Process Group STDOUT: '"
              . ${ $procgroup->getReportString }
              . "'\n" );
        print(  "Process Group STDERR: '"
              . ${ $procgroup->getErrorString }
              . "'\n" );

        $iprctmoutcnt = 0 if ( $procgroup->getErrorCode == 4 );

        for ( $iprc = 0 ; $iprc < $iprccnt ; $iprc++ ) {
            $proctest = $procgroup->getiProcess($iprc);

            isnt( $proctest, undef, "Process No. '$iprc': Listed correctly" );

            if ( defined $proctest ) {
                print(
                    "Process ",
                    $proctest->getNameComplete,
                    " finished with [" . $proctest->getErrorCode . "]:\n"
                );

                $rscriptlog    = $proctest->getReportString;
                $rscripterror  = $proctest->getErrorString;
                $iscriptstatus = $proctest->getProcessStatus;

                print( "ERROR CODE: '", $proctest->getErrorCode, "'\n" );
                print("EXIT CODE: '$iscriptstatus'\n");

                if ( $proctest->getErrorCode == 4 ) {
                    $iprctmoutcnt++;

                    is( $iscriptstatus, -1,
                        "Exit Code not captured as expected" );
                    is( $proctest->getExecutionTime,
                        -1, "Execution Time not measured as expected" );
                }
                else    # Process finished normally
                {
                    isnt( $iscriptstatus, -1, "Exit Code was captured" );
                    isnt( $proctest->getExecutionTime,
                        -1, "Execution Time was measured" );
                }       #if($proctest->getErrorCode == 4)

                print( "Read Timeout: '", $proctest->getReadTimeout, "'\n" );
                print( "Execution Time: '", $proctest->getExecutionTime,
                    "'\n" );

                isnt( $rscriptlog, undef, "STDOUT was captured" );

                print("STDOUT: '$$rscriptlog'\n") if ( defined $rscriptlog );

                isnt( $rscripterror, undef, "STDERR was captured" );

                print("STDERR: '$$rscripterror'\n")
                  if ( defined $rscripterror );
            }    #if(defined $proctest)
        }    #for($iprc = 0; $iprc < $iprccnt; $iprc++)

        is( $iprctmoutcnt, 1, "'1' Process timed out as expected" );

        print("Process Group Execution Timeout - Count: '$iprctmoutcnt'\n");
    };
    subtest 'Process::SubProcess::Group::Wait() Method' => sub {

        $iprctmoutcnt = -1;

        $procgroup = Process::SubProcess::Group::->new( ( 'timeout' => 7 ) );

        $stestscript = "test_script.pl";
        $itestpause  = 3;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:3s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 5;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:5s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $itestpause = 13;

        $proctest = Process::SubProcess::->new(
            (
                'name'      => 'test-script:13s',
                'command'   => $spath . $stestscript . ' ' . $itestpause,
                'profiling' => 1
            )
        );

        is( $proctest->isProfiling, 1, 'Profiling activated' );

        $procgroup->add($proctest);

        $iprccnt = $procgroup->getProcessCount;

        is( $iprccnt, 3, "scripts (count: '$iprccnt'): added correctly" );

        $procgroup->setCheckInterval(6);

        isnt( $procgroup->getCheckInterval, -1, "Check Interval activated" );
        isnt( $procgroup->getTimeout,       -1, "Execution Timeout activated" );

        $itmstrt = gettimeofday();

        print "Process Group Execution Start - Time Now: '$itmstrt' s\n";

        for ( $iprc = 0 ; $iprc < $iprccnt ; $iprc++ ) {
            $proctest = $procgroup->getiProcess($iprc);

            isnt( $proctest, undef, "Process No. '$iprc': Listed correctly" );

            if ( defined $proctest ) {
                is( $proctest->Launch, 1,
                    "Process No. '$iprc': Launch succeeded" );
            }    #if(defined $proctest)
        }    #for($iprc = 0; $iprc < $iprccnt; $iprc++)

        is( $procgroup->getRunningCount,
            3, "Process Group Execution: All Processes are launched" );

        is( $procgroup->Wait(), 0,
            "Process Group Execution: Execution failed as expected" );

        $itmend = gettimeofday();

        $itm = ( $itmend - $itmstrt ) * 1000;

        print "Process Group Execution End - Time Now: '$itmend' s\n";

        print "Process Group Execution finished in '$itm' ms\n";

        print(
            "Process Group ERROR CODE: '" . $procgroup->getErrorCode . "'\n" );

        is( $procgroup->getErrorCode, 4,
            "Process Group Execution: ERROR CODE is correct" );

        print(  "Process Group STDOUT: '"
              . ${ $procgroup->getReportString }
              . "'\n" );
        print(  "Process Group STDERR: '"
              . ${ $procgroup->getErrorString }
              . "'\n" );

        $iprctmoutcnt = 0 if ( $procgroup->getErrorCode == 4 );

        for ( $iprc = 0 ; $iprc < $iprccnt ; $iprc++ ) {
            $proctest = $procgroup->getiProcess($iprc);

            isnt( $proctest, undef, "Process No. '$iprc': Listed correctly" );

            if ( defined $proctest ) {
                print(
                    "Process ",
                    $proctest->getNameComplete,
                    " finished with [" . $proctest->getErrorCode . "]:\n"
                );

                $rscriptlog    = $proctest->getReportString;
                $rscripterror  = $proctest->getErrorString;
                $iscriptstatus = $proctest->getProcessStatus;

                print( "ERROR CODE: '", $proctest->getErrorCode, "'\n" );
                print("EXIT CODE: '$iscriptstatus'\n");

                if ( $proctest->getErrorCode == 4 ) {
                    $iprctmoutcnt++;

                    is( $proctest->getExecutionTime,
                        -1, "Execution Time not measured as expected" );
                }
                else    #Timeout Error
                {
                    isnt( $proctest->getExecutionTime,
                        -1, "Execution Time was measured" );
                }       #if($proctest->getErrorCode == 4)

                print( "Read Timeout: '", $proctest->getReadTimeout, "'\n" );
                print( "Execution Time: '", $proctest->getExecutionTime,
                    "'\n" );

                if ( defined $rscriptlog ) {
                    print("STDOUT: '$$rscriptlog'\n");
                }
                else {
                    isnt( $rscriptlog, undef, "STDOUT was captured" );
                }       #if(defined $rscriptlog)

                if ( defined $rscripterror ) {
                    print("STDERR: '$$rscripterror'\n");
                }
                else {
                    isnt( $rscripterror, undef, "STDERR was captured" );
                }       #if(defined $rscripterror)
            }    #if(defined $proctest)
        }    #for($iprc = 0; $iprc < $iprccnt; $iprc++)

        is( $iprctmoutcnt, 1, "'1' Process timed out as expected" );

        print("Process Group Execution Timeout - Count: '$iprctmoutcnt'\n");
    };
};

done_testing();
