#!/usr/bin/perl

use strict;
use warnings;

# Test fisher_yates_shuffle. There are two tests we can do:
#
# correctness (make sure that we have correct number of unique picks)
# distribution (chi-squared over n!/(n-p)! bins)

use lib '../lib';
use Net::OnlineCode::Encoder;
use Net::OnlineCode::Decoder;
use Net::OnlineCode::RNG;

print "Testing: SHUFFLE\n";

my ($size,$picks,$trials) =  @ARGV;
my $bins;

$size   = 15  unless defined($size);
$picks  = 4   unless defined($picks);

# In order for the chi-squared test to give meaningful results, we
# need to have ten times more trials than there are bins. I'm using
# more than that so we have a safety margin. Note that it's easy to
# end up requiring a very high number of bins if size and/or picks are
# high due to the n factorial above the line:

# calculate n!/(n-p)!
sub count_bins {
  my ($size,$picks) = @_;

  my $product = $size;
  $product *= --$size while (--$picks > 0);

  return $product;
}

$bins = count_bins($size,$picks);
$trials = 15 * $bins unless defined($trials);

print "Array Size: $size\nPicks: $picks\nTrials: $trials\n";

if ($trials < 10 * $bins) {
  warn "Only $trials trials is not enough to test $bins bins.\n";
}


sub correctness_check {
  my ($picks, $array) = @_;

  die "Failed correctness check: wrong number of picks in array\n"
    unless $picks == @$array;

  my @sorted = sort { $a <=> $b } @$array;

  my $prev = shift @sorted;
  while (@sorted) {
    my $next = shift @sorted;
    if ($next == $prev) {
      die "fisher_yates_shuffle failed uniqueness test\n";
    }
    $prev = $next;
  }
}

# if the original array has elements 1..n then there's a natural way
# of turning a selection into a bin number

sub bin_number {

  my ($n, $picks, $array) = @_;

  # as we consume each number from the array, we assign it a value
  # based on where it appears in the list of remaining choices
  my $index;
  my @choices = (1 .. $n);

  # at the start, we could choose from any of the 1..n values
  my $product    = (shift @$array) - 1;	# range [0 .. n - 1]
     $index      = $product;
  my $multiplier = $n;


#  print "product is $product, multiplier $multiplier, picks $picks \n";

  while (--$picks > 0) {

    $product *= --$multiplier;

    # remove previous choice from list
    splice @choices, $index, 1;

    my $value = shift @$array;

    # find the index of this value in the list of remaining choices
    $index = undef;
    for my $i (0 .. scalar(@choices) - 1) {
      if ($value == $choices[$i]) {
	$index = $i;
	last;
      }
    }
    # following shouldn't happen (also already tested in correctness_check)
    die "BUG: failed to find list element in \@choices\n" unless defined($index);

    #print "updating product with value $value, index $index\n";

    $product += $index;
    #print "product is $product, multiplier $multiplier, picks $picks \n";

  }

  #print "returning from sub\n";

  return $product;
}

my $rng = Net::OnlineCode::RNG->new_random;
my @bin_counts = ((0) x $bins);

# routine now takes a packed string rather than an array
my $string = pack "L*", (1 .. $size);

for (1..$trials) {

  my $array =  [1 .. $size ];

  @$array = Net::OnlineCode::fisher_yates_shuffle($rng, $string, $picks);

  correctness_check($picks, $array);

  my $bin = bin_number($size,$picks,$array);

  if ($bin > $bins) {
    die "bin_number returned an invalid value: $bin > $bins\n";
  }

  $bin_counts[$bin]++;
}

# do the chi-squared test
my $expected_density = $trials / $bins;
my $sum = 0;
my $checksum = 0;
my $zeros = 0;			# count bins with nothing in them

foreach my $count (@bin_counts) {

  $checksum += $count;		# should count up to $trials
  $sum      += ($count - $expected_density) * ($count - $expected_density);
  ++$zeros unless $count;
}

$sum /= $expected_density;

print "BUG! checksum $checksum != $trials\n" unless $checksum == $trials;
print "(got $zeros empty bins)\n";

my ($deviation, $stddevs);
$deviation = $bins - $sum;
$stddevs   = $deviation / sqrt($bins);

print "Number of bins: $bins\n";
print "Number of trials: $trials\n";
print "Expected counts for each bin: $expected_density\n";
print "Chi-squared standard deviation for $bins bins is " . sqrt($bins). "\n\n";

print "Chi-squared value: $sum\n";
print "Chi-squared value is $stddevs standard deviations from expected value of $bins\n";
print "Values between +/-2 standard deviations are good, between +/-3 marginal:\n";

$stddevs = abs $stddevs;
if ($stddevs < 2) {
  print "$stddevs < 2: GOOD RNG\n";
} elsif ($stddevs < 3) {
  print "2 < $stddevs < 3:  MARGINAL RNG\n";
} else {
  print "$stddevs > 3: BAD RNG\n";
}

