#!/usr/bin/perl
# vim:set nocompatible expandtab tabstop=4 shiftwidth=4 ai:
#
# jcline@ieee.org 2009-06-26
#
#
# Test for Tecan Gemini using named pipe & control 

use Test::More tests => 2;

SKIP: { 
    # Actually there is no good way to test "if running under cygwin plus
    # activestate perl"
    skip "this test is only for cygwin+activeperl".
        "(not cygwin-perl and not windows cmd.exe+activeperl)", 2
        unless 
        (($ENV{"PATH"} =~ m^\\cygwin\\^) && !($^X =~ m^Perl\\bin^i));

    # Notes on gemini named pipe:
    #   - must run gemini application first
    $pipename="\\\\.\\pipe\\gemini";
    my $version;
    my $status;
    use Fcntl;
    $| = 1;
    sysopen(CMD, $pipename, O_RDWR) || die "cant open $pipename";
    binmode(CMD);
    print "\nversion: ";
    print CMD "GET_VERSION\0";
    do { read(CMD, $_, 1); $version .= $_; } while ($_ ne "\0");
    $version =~ s/[\t\n\r\0]//g;
    print "$version\n";
    if ($version) { pass("version"); } else { fail("version"); }
    print "status: ";
    print CMD "GET_STATUS\0";
    do { read(CMD, $_, 1); $status .= $_; } while ($_ ne "\0");
    $status =~ s/[\t\n\r\0]//g;
    print "$status\n";
    if ($status) { pass("status"); } else { fail("status"); }

    close(CMD);
    if (!$version || !$status) {
        diag("TEST FAIL");
    }
}
1;
