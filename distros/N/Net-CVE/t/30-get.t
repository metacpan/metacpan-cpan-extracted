#!/usr/bin/perl

use 5.014002;
use warnings;

use Test::More;
use Test::Warnings;

use Net::CVE;

if ($ENV{NO_NETWORK_TESTING}) {
    print "1..0 # SKIP Live tests disabled due to NO_NETWORK_TESTING\n";
    exit 0;
    }

ok (my $c1 = Net::CVE->new,		"New reporter");
ok ($c1->get ("CVE-2022-26928"),	"Read report with prefix");
ok (my $d1 = $c1->data,			"Generate data");
ok (my $s1 = $c1->summary,		"Generate summary");

ok (my $c2 = Net::CVE->new,		"New reporter");
ok ($c2->get ("2022-26928"),		"Read report without prefix");
ok (my $d2 = $c2->data,			"Generate data");
ok (my $s2 = $c2->summary,		"Generate summary");

isnt ($d1, $d2,				"Not the same data");
isnt ($s1, $s2,				"Not the same structure");

is_deeply ($d1, $d2,			"Same data content");
is_deeply ($s1, $s2,			"Same summary content");

is_deeply (Net::CVE->new->data ("CVE-2022-26928"), $d1, "Data direct");
is_deeply (Net::CVE->new->summary  ("2022-26928"), $s1, "Summary direct");

is_deeply (Net::CVE->new->get ("")->data, {},		"Empty fetch");

done_testing;
