#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
#
# jcline@ieee.org 2009-06-26
#
#
# Test Tecan Gemini using named pipe & control 

use Test::More tests => 4;
use warnings;
#use strict;

SKIP: {
    skip "this test is only for cygwin-perl", 4
                unless ($ENV{"PATH"} =~ m^/cygdrive/c^);

    my $incompatibility = "Win32::Pipe";
    eval "use $incompatibility";

    warn "this test is for cygwin-perl with Win32::Pipe - the preferred solution\n";

    # Notes on gemini named pipe:
    #   - must run gemini application first
    $pipename="\\\\.\\pipe\\gemini";
    my $version;
    my $status;
    my $e;


    # Test for query()
    # timeout in millisec
    if (-d "c:/Program Files/Tecan/Gemini") {
        pass("query");
        diag("Found gemini OK");
    }
    else {
        fail("query");
        exit -1;
    }


    # Test for attach(), status(), detach()
    $| = 1;
    #my $Pipe = new Win32::Pipe( "\\\\server\\pipe\\My Named Pipe" ) 
    #  || die "Can't Connect To The Named Pipe\n"; 
    my $Pipe = new Win32::Pipe($pipename, NMPWAIT_NOWAIT, 
            PIPE_TYPE_BYTE|PIPE_READMODE_BYTE) 
            || die "\n!! FAIL - cant open $pipename\n"; 
    print "NMPWAIT_NOWAIT = " . NMPWAIT_NOWAIT . "\n";
    print "PIPE_TPE_BYTE = " . PIPE_TYPE_BYTE . "\n";
    #$Pipe->State(PIPE_READMODE_BYTE);
    print "\nversion: ";
    $Pipe->Write("GET_VERSION\0");
    do { $_ = $Pipe->Read(); $version .= $_; } while (!($_ =~ m/\0/));
    $version =~ s/[\t\n\r\0]//g;
    print "$version\n";
    if ($version) { pass("version"); } else { fail("version"); }

    print "RSP: ";
    $Pipe->Write("GET_RSP\0");
    do { $_ = $Pipe->Read(); $rsp .= $_; } while (!($_ =~ m/\0/));
    $rsp =~ s/[\t\n\r\0]//g;
    print "$rsp\n";
    if ($rsp) { pass("rsp"); } else { fail("rsp"); }

    print "status: ";
    $Pipe->Write("GET_STATUS\0");
    do { $_ = $Pipe->Read(); $status .= $_; } while (!($_ =~ m/\0/));
    $status =~ s/[\t\n\r\0]//g;
    print "$status\n";
    if ($status) { pass("status"); } else { fail("status"); }

    $Pipe->Close();
    if (!$version || !$status) {
        diag("TEST FAIL");
    }

    # Repeat-open-close test:
    # XXX TBD
}

1;

