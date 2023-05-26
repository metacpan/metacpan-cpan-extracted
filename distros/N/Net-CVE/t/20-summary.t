#!/usr/bin/perl

use 5.014002;
use warnings;

use Test::More;
use Test::Warnings;

use Net::CVE;

my $jf = "Files/CVE-2022-26928.json";

ok (my $cr = Net::CVE->new,	"New reporter");
ok ($cr->get ($jf),		"Read stored report");
ok (my $r = $cr->summary,	"Generate summary");

my $expect = {
    date        => "2022-09-13T18:41:25",
    description => "Windows Photo Import API Elevation of Privilege Vulnerability",
    id          => "CVE-2022-26928",
    platforms   => [
        "32-bit Systems",
        "ARM64-based Systems",
        "x64-based Systems"
        ],
    problem     => "Elevation of Privilege",
    product     => [
        "Windows 10 Version 1507",
        "Windows 10 Version 1607",
        "Windows 10 Version 1809",
        "Windows 10 Version 20H2",
        "Windows 10 Version 21H1",
        "Windows 10 Version 21H2",
        "Windows 11 version 21H2",
        "Windows Server 2016",
        "Windows Server 2019",
        "Windows Server 2022"
        ],
    score       => "7",
    severity    => "high",
    status      => "PUBLISHED",
    vendor      => [ "Microsoft" ],
    };

is_deeply ($r, $expect, "Report returned a summary");

is_deeply (Net::CVE->get ($jf)->summary, $expect, "->get->summary (file)");
is_deeply (Net::CVE->summary ($jf),      $expect, "->summary (file)");

done_testing;
