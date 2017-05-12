#!/usr/bin/perl -w

# Exercise default random number generator
#
# Shows output from random_uuid_160 method

use lib '../lib';
use Net::OnlineCode::RNG qw(random_uuid_160);

print "Testing: RNG\n";

for (1..3) {
  # use explicit package::method name for random_uuid_160:
  my $bits = Net::OnlineCode::RNG->random_uuid_160();

  print "UUID: " . (unpack "H*", $bits) . "\n";
}

my $rng1 = Net::OnlineCode::RNG->new;
my $rng2 = Net::OnlineCode::RNG->new;

die "Failed to create RNG objects" unless ref($rng1) and ref($rng2);

print "Testing RNGs with default seed: ";
for (1..1000) {
  my ($r1) = $rng1->rand;
  my ($r2) = $rng2->rand;

  die "rng mismatch! $r1 != $r2\n" if $r1 != $r2;
  die "bad rng value $r1\n" if $r1 >= 1;
}
print "OK\n";

# use exported random_uuid_160 sub
my $bits = random_uuid_160();
my $uuid = unpack "H*", $bits;
print "Testing RNGs with random seed $uuid: ";
for (1..1000) {
  my ($r1) = $rng1->rand;
  my ($r2) = $rng2->rand;

  die "rng mismatch! $r1 != $r2\n" if $r1 != $r2;
  die "bad rng value $r1\n" if $r1 >= 1;
}
print "OK\n";

# should probably add some conformance tests to ensure that the same
# values are calculated on different platforms. The SHA-1
# implementation can probably be trusted, but we may have some
# slight precision-related problems depending on how floating point
# numbers and division are done on the platform.

# While I'm calculating lots of RNG values for the conformance test,
# I'll also do a chi-squared test on the values to test whether the
# RNG is biased. I only test the first two decimal digits here, but
# this should give a good indication of acceptability.

# chi-squared test stuff, taken from pseudocode at:
# http://en.wikibooks.org/wiki/Algorithm_Implementation/Pseudorandom_Numbers/Chi-Square_Test

my $nbins = 100;		# 100 possible 2-digit decimal numbers
my $nkeys = 15000;		# run RNG this many times; should be at
				# least 10 times $nbins for chi-squared
my @bins  = ((0) x $nbins);	# counts for leading log_10(nbins) digits
my $p        = $nkeys / $nbins;

# This is the simplest cross-platform conformance test: if output
# doesn't match when run on different machines, we have a problem.
open RANDOM, ">random.localhost" or die "couldn't create test file: $!\n";

# while generating our random numbers, also check for cycles
my %unique;			# random key => iteration first seen
my $cycle_length = undef;

$rng1->seed_random;
for (1..$nkeys) {
  my $r1 = $rng1->rand;

  if (exists($unique{$r1})) {
    $cycle_length = $_ - $unique{$r1};
  }
  $unique{$r1} = $_;

  my $s = sprintf "%0.15f", $r1;
  print RANDOM "$s\n";

#  $s =~ s/^0\.(\d\d).*$/$1/;

  # pick a different number to go in the bins
  $s=$rng1->randint(99);
  $bins[$s]++;
}

# we shouldn't have any empty bins
for (@bins) {
  die "Empty bin\n" unless $_;
}

print "\nTesting RNG for cycles ($nkeys trials): ";
if (defined($cycle_length)) {
  print "NOT OK, RNG appears to cycle with period length $cycle_length\n";
} else {
  print "OK, no cycle detected\n";
}

my $chisquared = 0;
my  $checksum = 0;
for my $i (0..$nbins-1) {
  $checksum += $bins[$i];
  $chisquared += ($bins[$i] - $p) ** 2;
}
$chisquared /= ($nkeys / $nbins);
my ($deviation, $stddevs);
$deviation = $nbins - $chisquared;
$stddevs   = $deviation / sqrt($nbins);
print "BUG! checksum $checksum != $nkeys\n" unless $checksum == $nkeys;

print "\nChi-squared tests (test RNG for bias):\n\n";
print "Number of bins: $nbins\n";
print "Number of samples: $nkeys\n";
print "Expected counts for each bin: $p\n";
print "Chi-squared standard deviation for $nbins bins is " . sqrt($nbins). "\n\n";

print "Chi-squared value: $chisquared\n";
print "Chi-squared value is $stddevs standard deviations from expected value of $nbins\n";
print "Values between +/-2 standard deviations are good, between +/-3 marginal:\n";

$stddevs = abs $stddevs;
if ($stddevs < 2) {
  print "$stddevs < 2: GOOD RNG\n";
} elsif ($stddevs < 3) {
  print "2 < $stddevs < 3:  MARGINAL RNG\n";
} else {
  print "$stddevs > 3: BAD RNG\n";
}

# The above test gave the same output on:
# * AMD x86_64, 64-bit Debian 7.0 "wheezy"
# * ARMv6 Raspberry Pi Model B, 32-bit hard-float Raspbian "wheezy"
# * ARMv7 ODROID-U2, 32-bit Linaro Ubuntu 12.11
