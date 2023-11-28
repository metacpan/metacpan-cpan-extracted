#!/usr/bin/perl

use 5.014000;
use warnings;

use Test::More;

use_ok ("Test::CVE");

ok (my $cve = Test::CVE->new, "New");

done_testing;
