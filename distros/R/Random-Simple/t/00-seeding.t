#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Random::Simple;
use Config;

########################################################
# Testing random numbers is hard so we do basic sanity #
# checking of the bounds                               #
########################################################

# If for some reason the automatic seeding does not work the first eight
# bytes will be zero. With a seed of (0,0) you can see this
#Random::Simple::seed(0,0); # Uncomment this to see the failure
my $bytes = random_bytes(16);
my $ok    = ok(substr($bytes, 0, 4) ne "\0\0\0\0", "First  four random bytes are NOT zero");
my $ok2   = ok(substr($bytes, 4, 4) ne "\0\0\0\0", "Second four random bytes are NOT zero");

if (!$ok || !$ok2) {
	my $str = sprintf('%v02X', $bytes);
	diag("First ten bytes: $str");
}

# Perl API
$bytes = Random::Simple::os_random_bytes(16);
$ok    = ok(substr($bytes, 0, 4) ne "\0\0\0\0", "First  four Perl random bytes are NOT zero");
$ok2   = ok(substr($bytes, 4, 4) ne "\0\0\0\0", "Second four Perl random bytes are NOT zero");

if (!$ok || !$ok2) {
	my $str = sprintf('%v02X', $bytes);
	diag("First ten bytes: $str");
}

done_testing();
