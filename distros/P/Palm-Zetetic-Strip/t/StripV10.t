#!/usr/bin/perl -w

use strict;
require "t/StripCommon.ph";

eval "use Digest::SHA256";
if ($@) {
    warn "Digest::256 not installed\n";
    print "1..0\n";
    exit;
}

eval "use Crypt::Rijndael";
if ($@) {
    warn "Crypt::Rijndael not installed\n";
    print "1..0\n";
    exit;
}


my $next;
my $num_tests;

$num_tests = &get_number_of_tests()*2;
print "1..${num_tests}\n";

# First try giving version
$next = &run_common_tests(1, "t/data/v1.0", "1.0", 1);

# Next try autodetect
$next = &run_common_tests($next, "t/data/v1.0", "1.0", 0);
