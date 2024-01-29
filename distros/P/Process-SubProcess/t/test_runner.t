#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2023-12-30
# @package Test for the 'run_subprocess.pl' Runner Script
# @subpackage t/test_runner.t

# This Module runs tests on the 'run_subprocess.pl' Runner Script
#
#---------------------------------
# Requirements:
# - The Perl Script "run_subprocess.pl" must be installed
#

use warnings;
use strict;

use Config;
use Cwd qw(abs_path);

use JSON qw(decode_json);
use YAML qw(Load);
use Time::HiRes qw(gettimeofday);

use Test::More;

my $smodule = "";
my $spath   = abs_path($0);

( $smodule = $spath ) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;

my $srunnerscript = '../bin/run_subprocess.pl';
my $stestscript   = 'test_script.pl';
my $itestpause    = 3;
my $iteststatus   = 4;

my $procgroup = undef;
my $proctest  = undef;

my $runnerresult   = undef;
my $srunnerresult  = undef;
my $sscriptsummary = undef;
my $sscriptlog     = undef;
my $scripterror    = undef;
my $iscriptpid     = -2;
my $irunnerstatus  = -2;
my $iscriptstatus  = -2;
my $ierror         = -2;

my $itm     = -1;
my $itmstrt = -1;
my $itmend  = -1;
my $itmexe  = -1;

my $iprc    = -1;
my $iprccnt = -1;

my $iprctmoutcnt = -1;

print "Perl Interpreter Path: '", $Config{perlpath}, "'\n";

subtest 'Runner Script Usage' => sub {

    $srunnerresult =
      `$Config{perlpath} ${spath}${srunnerscript} -n "runner usage" -h`;
    $irunnerstatus = $?;

    print("Runner Result:\n'$srunnerresult'\n");
    print("Runner EXIT CODE: '$irunnerstatus'\n");

    isnt( $srunnerresult, undef, "Runner Result is returned" );
    ok( $irunnerstatus =~ qr/^-?\d$/, "Runner EXIT CODE is numeric" );
    is( $irunnerstatus, 0, "Runner EXIT CODE '0' is correct" );

    ok(
        $srunnerresult =~ qr/-h\s+--help/
          || $srunnerresult =~ qr/--help[^\(]*\(?[^\)]*-h\)?/,
        "Runner Usage Message is printed"
    );
};

subtest 'Runner Plain Text Result' => sub {

    $itestpause  = 1;
    $iteststatus = 4;

    $srunnerresult =
`$Config{perlpath} ${spath}${srunnerscript} -n "script exit code '4' - plain" -c "${spath}${stestscript} $itestpause $iteststatus"`;
    $irunnerstatus = $?;

    print("Runner Result:\n'$srunnerresult'\n");
    print("Runner EXIT CODE: '$irunnerstatus'\n");

    isnt( $srunnerresult, undef, "Runner Result is returned" );
    ok( $irunnerstatus =~ qr/^-?\d$/, "Runner EXIT CODE is numeric" );
    is( $irunnerstatus, 0, "Runner EXIT CODE '0' is correct" );

    $sscriptsummary = undef;
    $sscriptlog     = undef;
    $scripterror    = undef;
    $iscriptpid     = -2;
    $iscriptstatus  = -2;
    $ierror         = -2;

    $sscriptsummary = $1
      if ( $srunnerresult =~ qr/>>>>summary:\n(.*)>>>>stdout/si );
    $sscriptlog = $1 if ( $srunnerresult =~ qr/>>>>stdout:\n(.*)>>>>stderr/si );
    $scripterror = $1 if ( $srunnerresult =~ qr/>>>>stderr:\n(.*)>>>>end/si );

    isnt( $sscriptsummary, undef, "Script Summary is returned" );
    isnt( $sscriptlog,     undef, "Script STDOUT is returned" );
    isnt( $scripterror,    undef, "Script STDERR is returned" );

    $iscriptpid    = $1 if ( $sscriptsummary =~ qr/^pid: ([\-0-9]+)$/mi );
    $iscriptstatus = $1 if ( $sscriptsummary =~ qr/^exit code: ([\-0-9]+)$/mi );
    $ierror = $1 if ( $sscriptsummary =~ qr/^error code: ([\-0-9]+)$/mi );

    isnt( $iscriptpid,    -2, "Script Process ID is returned" );
    isnt( $iscriptstatus, -2, "Script EXIT CODE is returned" );
    isnt( $ierror,        -2, "Process Error Code is returned" );

    ok( $iscriptpid > 0, "Script Process ID > 0 is a valid Process ID" );
    is( $iscriptstatus, $iteststatus,
        "Script EXIT CODE '$iteststatus' is correct" );
    is( $ierror, 1, "Process Error Code '1' is correct" );

    if ( defined $sscriptlog ) {
        print("STDOUT: '$sscriptlog'\n");

        isnt( $sscriptlog, '', "Script STDOUT was captured" );
        ok( $sscriptlog =~ qr/EXIT '4'/i, "Script STDOUT is correct" );
    }    #if(defined $rscriptlog)

    if ( defined $scripterror ) {
        print("STDERR: '$scripterror'\n");

        isnt( $scripterror, '', "Script STDERR was captured" );
        ok( $scripterror =~ qr/END 1 ERROR/i, "Script STDERR is correct" );
    }    #if(defined $rscripterror)
};

subtest 'Runner JSON Result' => sub {

    $itestpause  = 1;
    $iteststatus = 4;

    $srunnerresult =
`$Config{perlpath} ${spath}${srunnerscript} -n "script exit code '4' - json" -c "${spath}${stestscript} $itestpause $iteststatus" -f json`;
    $irunnerstatus = $?;

    print("Runner Result:\n'$srunnerresult'\n");
    print("Runner EXIT CODE: '$irunnerstatus'\n");

    isnt( $srunnerresult, undef, "Runner Result is returned" );
    ok( $irunnerstatus =~ qr/^-?\d$/, "Runner EXIT CODE is numeric" );
    is( $irunnerstatus, 0, "Runner EXIT CODE '0' is correct" );

    $runnerresult   = undef;
    $sscriptsummary = undef;
    $sscriptlog     = undef;
    $scripterror    = undef;
    $iscriptpid     = -2;
    $iscriptstatus  = -2;
    $ierror         = -2;

    eval { $runnerresult = decode_json($srunnerresult); };

    if ($@) {
        fail("Runner Result is not valid JSON: $@");
    }

    isnt( $runnerresult, undef, "Runner Result is valid JSON" );

    $sscriptlog  = $runnerresult->{'stdout'};
    $scripterror = $runnerresult->{'stderr'};

    isnt( $sscriptlog,  undef, "Script STDOUT is returned" );
    isnt( $scripterror, undef, "Script STDERR is returned" );

    $iscriptpid    = $runnerresult->{'pid'};
    $iscriptstatus = $runnerresult->{'exit_code'};
    $ierror        = $runnerresult->{'error_code'};

    isnt( $iscriptpid,    -2, "Script Process ID is returned" );
    isnt( $iscriptstatus, -2, "Script EXIT CODE is returned" );
    isnt( $ierror,        -2, "Process Error Code is returned" );

    ok( $iscriptpid > 0, "Script Process ID > 0 is a valid Process ID" );
    is( $iscriptstatus, $iteststatus,
        "Script EXIT CODE '$iteststatus' is correct" );
    is( $ierror, 1, "Process Error Code '1' is correct" );

    if ( defined $sscriptlog ) {
        print("STDOUT: '$sscriptlog'\n");

        isnt( $sscriptlog, '', "Script STDOUT was captured" );
        ok( $sscriptlog =~ qr/EXIT '4'/i, "Script STDOUT is correct" );
    }    #if(defined $rscriptlog)

    if ( defined $scripterror ) {
        print("STDERR: '$scripterror'\n");

        isnt( $scripterror, '', "Script STDERR was captured" );
        ok( $scripterror =~ qr/END 1 ERROR/i, "Script STDERR is correct" );
    }    #if(defined $rscripterror)
};

subtest 'Runner YAML Result' => sub {

    $itestpause  = 1;
    $iteststatus = 4;

    $srunnerresult =
`$Config{perlpath} ${spath}${srunnerscript} -n "script exit code '4' - yaml" -c "${spath}${stestscript} $itestpause $iteststatus" -f yaml`;
    $irunnerstatus = $?;

    print("Runner Result:\n'$srunnerresult'\n");
    print("Runner EXIT CODE: '$irunnerstatus'\n");

    isnt( $srunnerresult, undef, "Runner Result is returned" );
    ok( $irunnerstatus =~ qr/^-?\d$/, "Runner EXIT CODE is numeric" );
    is( $irunnerstatus, 0, "Runner EXIT CODE '0' is correct" );

    $runnerresult   = undef;
    $sscriptsummary = undef;
    $sscriptlog     = undef;
    $scripterror    = undef;
    $iscriptpid     = -2;
    $iscriptstatus  = -2;
    $ierror         = -2;

    eval { $runnerresult = Load($srunnerresult); };

    if ($@) {
        fail("Runner Result is not valid YAML: $@");
    }

    isnt( $runnerresult, undef, "Runner Result is valid YAML" );

    $sscriptlog  = $runnerresult->{'stdout'};
    $scripterror = $runnerresult->{'stderr'};

    isnt( $sscriptlog,  undef, "Script STDOUT is returned" );
    isnt( $scripterror, undef, "Script STDERR is returned" );

    $iscriptpid    = $runnerresult->{'pid'};
    $iscriptstatus = $runnerresult->{'exit_code'};
    $ierror        = $runnerresult->{'error_code'};

    isnt( $iscriptpid,    -2, "Script Process ID is returned" );
    isnt( $iscriptstatus, -2, "Script EXIT CODE is returned" );
    isnt( $ierror,        -2, "Process Error Code is returned" );

    ok( $iscriptpid > 0, "Script Process ID > 0 is a valid Process ID" );
    is( $iscriptstatus, $iteststatus,
        "Script EXIT CODE '$iteststatus' is correct" );
    is( $ierror, 1, "Process Error Code '1' is correct" );

    if ( defined $sscriptlog ) {
        print("STDOUT: '$sscriptlog'\n");

        isnt( $sscriptlog, '', "Script STDOUT was captured" );
        ok( $sscriptlog =~ qr/EXIT '4'/i, "Script STDOUT is correct" );
    }    #if(defined $rscriptlog)

    if ( defined $scripterror ) {
        print("STDERR: '$scripterror'\n");

        isnt( $scripterror, '', "Script STDERR was captured" );
        ok( $scripterror =~ qr/END 1 ERROR/i, "Script STDERR is correct" );
    }    #if(defined $rscripterror)
};

subtest 'Runner Plain Text Boundary' => sub {

    my $soutputboundary = ':====';

    $itestpause = 1;

    $srunnerresult =
`$Config{perlpath} ${spath}${srunnerscript} -n "script - plain boundary" -c "${spath}${stestscript} $itestpause" -b "$soutputboundary"`;
    $irunnerstatus = $?;

    print("Runner Result:\n'$srunnerresult'\n");
    print("Runner EXIT CODE: '$irunnerstatus'\n");

    isnt( $srunnerresult, undef, "Runner Result is returned" );
    ok( $irunnerstatus =~ qr/^-?\d$/, "Runner EXIT CODE is numeric" );
    is( $irunnerstatus, 0, "Runner EXIT CODE '0' is correct" );

    $sscriptsummary = undef;
    $sscriptlog     = undef;
    $scripterror    = undef;
    $iscriptpid     = -2;
    $iscriptstatus  = -2;
    $ierror         = -2;

    $sscriptsummary = $1
      if ( $srunnerresult =~
        /${soutputboundary}summary:\n(.*)${soutputboundary}stdout/si );
    $sscriptlog = $1
      if ( $srunnerresult =~
        /${soutputboundary}stdout:\n(.*)${soutputboundary}stderr/si );
    $scripterror = $1
      if ( $srunnerresult =~
        /${soutputboundary}stderr:\n(.*)${soutputboundary}end/si );

    isnt( $sscriptsummary, undef, "Script Summary is returned" );
    isnt( $sscriptlog,     undef, "Script STDOUT is returned" );
    isnt( $scripterror,    undef, "Script STDERR is returned" );

    $iscriptpid    = $1 if ( $sscriptsummary =~ qr/^pid: ([\-0-9]+)$/mi );
    $iscriptstatus = $1 if ( $sscriptsummary =~ qr/^exit code: ([\-0-9]+)$/mi );
    $ierror = $1 if ( $sscriptsummary =~ qr/^error code: ([\-0-9]+)$/mi );

    isnt( $iscriptpid,    -2, "Script Process ID is returned" );
    isnt( $iscriptstatus, -2, "Script EXIT CODE is returned" );
    isnt( $ierror,        -2, "Process Error Code is returned" );

    ok( $iscriptpid > 0, "Script Process ID > 0 is a valid Process ID" );
    is( $iscriptstatus, 0, "Script EXIT CODE '0' is correct" );
    is( $ierror,        0, "Process Error Code '0' is correct" );

    if ( defined $sscriptlog ) {
        print("STDOUT: '$sscriptlog'\n");

        isnt( $sscriptlog, '', "Script STDOUT was captured" );
        ok( $sscriptlog =~ qr/EXIT '0'/i, "Script STDOUT is correct" );
    }    #if(defined $rscriptlog)

    if ( defined $scripterror ) {
        print("STDERR: '$scripterror'\n");

        isnt( $scripterror, '', "Script STDERR was captured" );
        ok( $scripterror =~ qr/END 1 ERROR/i, "Script STDERR is correct" );
    }    #if(defined $rscripterror)
};

subtest 'Runner Timeout Error' => sub {

    $itestpause = 5;

    $srunnerresult =
`$Config{perlpath} ${spath}${srunnerscript} -n "script - times out" -c "${spath}${stestscript} $itestpause" -t 1`;
    $irunnerstatus = $?;

    print("Runner Result:\n'$srunnerresult'\n");
    print("Runner EXIT CODE: '$irunnerstatus'\n");

    isnt( $srunnerresult, undef, "Runner Result is returned" );
    ok( $irunnerstatus =~ qr/^-?\d+$/, "Runner EXIT CODE is numeric" );
    is( $irunnerstatus, 0, "Runner EXIT CODE '0' is correct" );

    $sscriptsummary = undef;
    $sscriptlog     = undef;
    $scripterror    = undef;
    $iscriptpid     = -2;
    $iscriptstatus  = -2;
    $ierror         = -2;

    $sscriptsummary = $1
      if ( $srunnerresult =~ qr/>>>>summary:\n(.*)>>>>stdout/si );
    $sscriptlog = $1 if ( $srunnerresult =~ qr/>>>>stdout:\n(.*)>>>>stderr/si );
    $scripterror = $1 if ( $srunnerresult =~ qr/>>>>stderr:\n(.*)>>>>end/si );

    isnt( $sscriptsummary, undef, "Script Summary is returned" );
    isnt( $sscriptlog,     undef, "Script STDOUT is returned" );
    isnt( $scripterror,    undef, "Script STDERR is returned" );

    $iscriptpid    = $1 if ( $sscriptsummary =~ qr/^pid: ([\-0-9]+)$/mi );
    $iscriptstatus = $1 if ( $sscriptsummary =~ qr/^exit code: ([\-0-9]+)$/mi );
    $ierror = $1 if ( $sscriptsummary =~ qr/^error code: ([\-0-9]+)$/mi );

    isnt( $iscriptpid,    -2, "Script Process ID is returned" );
    isnt( $iscriptstatus, -2, "Script EXIT CODE is returned" );
    isnt( $ierror,        -2, "Process Error Code is returned" );

    ok( $iscriptpid > 0, "Script Process ID > 0 is a valid Process ID" );
    is( $iscriptstatus, -1, "Script EXIT CODE '-1' is correct" );
    is( $ierror,        4,  "Process Error Code '4' is correct" );

    if ( defined $sscriptlog ) {
        print("STDOUT: '$sscriptlog'\n");

        is( $sscriptlog, '', "Script STDOUT is empty" );
    }    #if(defined $rscriptlog)

    if ( defined $scripterror ) {
        print("STDERR: '$scripterror'\n");

        isnt( $scripterror, '', "Script STDERR was captured" );
        ok(
            $scripterror =~ qr/Execution timed out/i,
            "Script STDERR 'timed out' is correct"
        );
    }    #if(defined $rscripterror)
};

subtest 'Runner Exit Code' => sub {

    subtest 'Runner returns Script Exit Code' => sub {
        $itestpause  = 1;
        $iteststatus = 6;

        $srunnerresult =
`$Config{perlpath} ${spath}${srunnerscript} -n "script - exit code" -c "${spath}${stestscript} $itestpause $iteststatus" -x`;
        $irunnerstatus = ( $? >> 8 );

        print("Runner Result:\n'$srunnerresult'\n");
        print("Runner EXIT CODE: '$irunnerstatus'\n");

        isnt( $srunnerresult, undef, "Runner Result is returned" );
        ok( $irunnerstatus =~ qr/^-?\d+$/, "Runner EXIT CODE is numeric" );
        is( $irunnerstatus, $iteststatus,
            "Runner EXIT CODE '$iteststatus' is correct" );

        $sscriptsummary = undef;
        $sscriptlog     = undef;
        $scripterror    = undef;
        $iscriptpid     = -2;
        $iscriptstatus  = -2;
        $ierror         = -2;

        $sscriptsummary = $1
          if ( $srunnerresult =~ qr/>>>>summary:\n(.*)>>>>stdout/si );
        $sscriptlog = $1
          if ( $srunnerresult =~ qr/>>>>stdout:\n(.*)>>>>stderr/si );
        $scripterror = $1
          if ( $srunnerresult =~ qr/>>>>stderr:\n(.*)>>>>end/si );

        isnt( $sscriptsummary, undef, "Script Summary is returned" );
        isnt( $sscriptlog,     undef, "Script STDOUT is returned" );
        isnt( $scripterror,    undef, "Script STDERR is returned" );

        $iscriptpid    = $1 if ( $sscriptsummary =~ qr/^pid: ([\-0-9]+)$/mi );
        $iscriptstatus = $1
          if ( $sscriptsummary =~ qr/^exit code: ([\-0-9]+)$/mi );
        $ierror = $1 if ( $sscriptsummary =~ qr/^error code: ([\-0-9]+)$/mi );

        isnt( $iscriptpid,    -2, "Script Process ID is returned" );
        isnt( $iscriptstatus, -2, "Script EXIT CODE is returned" );
        isnt( $ierror,        -2, "Process Error Code is returned" );

        ok( $iscriptpid > 0, "Script Process ID > 0 is a valid Process ID" );
        is( $iscriptstatus, $iteststatus,
            "Script EXIT CODE '$iteststatus' is correct" );
        is( $ierror, 1, "Process Error Code '1' is correct" );

        if ( defined $sscriptlog ) {
            print("STDOUT: '$sscriptlog'\n");

            isnt( $sscriptlog, '', "Script STDOUT was captured" );
            ok( $sscriptlog =~ qr/EXIT '6'/i, "Script STDOUT is correct" );
        }    #if(defined $rscriptlog)

        if ( defined $scripterror ) {
            print("STDERR: '$scripterror'\n");

            isnt( $scripterror, '', "Script STDERR was captured" );
            ok( $scripterror =~ qr/END 1 ERROR/i, "Script STDERR is correct" );
        }    #if(defined $rscripterror)
    };
    subtest 'Runner returns Error Code' => sub {
        $itestpause = 10;

        $srunnerresult =
`$Config{perlpath} ${spath}${srunnerscript} -n "script - times out" -c "${spath}${stestscript} $itestpause" -t 1 -x`;
        $irunnerstatus = ( $? >> 8 );

        print("Runner Result:\n'$srunnerresult'\n");
        print("Runner EXIT CODE: '$irunnerstatus'\n");

        isnt( $srunnerresult, undef, "Runner Result is returned" );
        ok( $irunnerstatus =~ qr/^-?\d+$/, "Runner EXIT CODE is numeric" );
        is( $irunnerstatus, 4, "Runner EXIT CODE '4' is correct" );

        $sscriptsummary = undef;
        $sscriptlog     = undef;
        $scripterror    = undef;
        $iscriptpid     = -2;
        $iscriptstatus  = -2;
        $ierror         = -2;

        $sscriptsummary = $1
          if ( $srunnerresult =~ qr/>>>>summary:\n(.*)>>>>stdout/si );
        $sscriptlog = $1
          if ( $srunnerresult =~ qr/>>>>stdout:\n(.*)>>>>stderr/si );
        $scripterror = $1
          if ( $srunnerresult =~ qr/>>>>stderr:\n(.*)>>>>end/si );

        isnt( $sscriptsummary, undef, "Script Summary is returned" );
        isnt( $sscriptlog,     undef, "Script STDOUT is returned" );
        isnt( $scripterror,    undef, "Script STDERR is returned" );

        $iscriptpid    = $1 if ( $sscriptsummary =~ qr/^pid: ([\-0-9]+)$/mi );
        $iscriptstatus = $1
          if ( $sscriptsummary =~ qr/^exit code: ([\-0-9]+)$/mi );
        $ierror = $1 if ( $sscriptsummary =~ qr/^error code: ([\-0-9]+)$/mi );

        isnt( $iscriptpid,    -2, "Script Process ID is returned" );
        isnt( $iscriptstatus, -2, "Script EXIT CODE is returned" );
        isnt( $ierror,        -2, "Process Error Code is returned" );

        ok( $iscriptpid > 0, "Script Process ID > 0 is a valid Process ID" );
        is( $iscriptstatus, -1, "Script EXIT CODE '-1' is correct" );
        is( $ierror,        4,  "Process Error Code '4' is correct" );

        if ( defined $sscriptlog ) {
            print("STDOUT: '$sscriptlog'\n");

            is( $sscriptlog, '', "Script STDOUT is empty" );
        }    #if(defined $rscriptlog)

        if ( defined $scripterror ) {
            print("STDERR: '$scripterror'\n");

            isnt( $scripterror, '', "Script STDERR was captured" );
            ok(
                $scripterror =~ qr/Execution timed out/i,
                "Script STDERR 'times out' is correct"
            );
        }    #if(defined $rscripterror)
    };
};

done_testing();

