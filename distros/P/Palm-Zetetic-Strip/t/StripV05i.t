#!/usr/bin/perl -w

use strict;
require "t/StripCommon.ph";

eval "use Digest::MD5";
if ($@) {
    warn "Digest::MD5 not installed\n";
    print "1..0\n";
    exit;
}

eval "use Crypt::IDEA";
if ($@) {
    warn "Crypt::IDEA not installed\n";
    print "1..0\n";
    exit;
}


my $next;
my $num_tests;

$num_tests = &get_number_of_tests() * 2;
print "1..${num_tests}\n";

# First try giving version
$next = &run_common_tests(1, "t/data/v0.5i", "0.5i", 1);

# Next try with autodetect
&run_common_tests($next, "t/data/v0.5i", "0.5i", 0);
