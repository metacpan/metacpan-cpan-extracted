#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std;

# Test promises made by paper regarding how many checkblocks should be
# needed to recover the message.
#
# n  = number of message blocks
# n' = number of message blocks plus auxiliary blocks
#
# There are three distinct promises made in the paper:
#
# 1) knowing a (1 - e/2) fraction of all the composite blocks (n') should
#    be enough to decode the full message. This may fail to be true
#    with probability (e/2) ** (q+1)
#
# 2) any set of (1 + e) * n' check blocks should be enough to recover
#    the above (1-e/2) fraction of all composite blocks. No error
#    probability is given with this
#
# 3) any set of (1 + 3e)n check blocks should be sufficient to recover
#    the message "with a high degree of probability". It is unclear to
#    me where this constant value 3 comes from.  It seems to me that
#    perhaps it should be "q" instead.
#

# Two optional arguments:
#
# -d         Use a default/deterministic seed value (160 zero bits)
# -s seed    Use a user-supplied seed (overrides -d)
#
# These seed values apply to the first trial. Any successive trials
# will continue to use the existing RNG so each trial will generate
# different values but overall the results will be the same across
# different runs.

my $seed = undef;

# optional args
our ($opt_d, $opt_s) = (0,undef); # seems we need 'our' instead of 'my'
getopts('ds:');
if ($opt_d) {
  $seed = "\0" x20;
}
if (defined($opt_s)) {
  $seed = $opt_s;
  die "Option -s requires a 20-character seed value\n"
    unless length($opt_s) == 20;
}

# remaining args
my ($mblocks, $trials, @junk) = @ARGV;

use lib '../lib';
use Net::OnlineCode;
use Net::OnlineCode::Decoder;
use Net::OnlineCode::RNG;

print "Testing: PROMISES\n";

$mblocks = 100 unless defined($mblocks);
$trials  = 1   unless defined($trials);

# set up RNG
my $rng;
if (defined($seed)) {
  $rng=Net::OnlineCode::RNG->new($seed);
} else {
  $rng=Net::OnlineCode::RNG->new_random;
}
print "RNG seed: ". $rng->as_hex() . "\n";

# use a trial Net::OnlineCode object to fix e, q, ablocks
# parameters. By using Net::OnlineCode instead of a Decoder object, we
# avoid overheads involved with creating the auxiliary blocks (though
# not the probability table)

my $o=Net::OnlineCode->
  new(mblocks=>$mblocks);

my $e = $o->get_e;
my $q = $o->get_q;
my $coblocks = $o->get_coblocks;
my $ablocks  = $o->get_ablocks;

print "mblocks = $mblocks\n";
print "ablocks = $ablocks\n";
print "e = $e\n";
print "q = $q\n";

print "Expected number of check blocks: " .
#  int (0.5 + ($mblocks * (1 + $e * $q))) .  "\n";
#print "Failure probability: " . (($e/2)**($q + 1)) . "\n";

#print "Alt. check block count: " .
  int (0.5 + (1 + $e) * $coblocks) . "\n";

$o = undef;                     # destroy trial decoder


# variable to track actual results versus the promises made

my $composites_solved;

# promise 1:
my $composite_fraction = (1 - $e/2);
my $composite_promise = undef;
my $promise_1_total = 0;

# promise 2:

my $expected_check_count_1 =  int (0.5 + (1 + $e) * $coblocks);
my $promise_2_total = 0;


# promise 3:
my $expected_check_count_2 = int ( 0.5 + ((1 + 3 * $e) * $mblocks));
my $promise_3_total = 0;

# calculate the average number of check blocks
my $average = 0;

for my $trial (1 .. $trials) {

  $o=Net::OnlineCode::Decoder->
    new(mblocks=>$mblocks, initial_rng=>$rng, expand_aux=>0);

  # check that parameters are still the same as for our trial decoder
  die "e changed\n"        unless $e == $o->get_e;
  die "q changed\n"        unless $q == $o->get_q;
  die "coblocks changed\n" unless $coblocks == $o->get_coblocks;
  die "ablocks  changed\n" unless $ablocks  == $o->get_ablocks;

  $composites_solved = 0;
  $composite_promise = undef;

  my @A=();
  my $done = 0;
  my $i = 0;
  until ($done) {
    ++$i;
    $o->accept_check_block($rng);

    while(1) {
      ($done,@A) = $o->resolve;
      last unless @A;
      
      $composites_solved += @A;

      die "solved $composites_solved blocks, but there are only $coblocks to solve\n"
        if $composites_solved > $coblocks;

      # promise 1 says that if we know 1-e/2 fraction of the composite
      # blocks, it's enough to decode the entire message with failure
      # probability (e/2)**(q+1)
      unless (defined($composite_promise)) {
        if ($composites_solved >= $coblocks * $composite_fraction) {
          if ($done) {
            $composite_promise = "true";
            ++$promise_1_total;
          } else {
            $composite_promise = "false";
          }
        }
      }
      last if $done;
    }
  }

  # check promise 2
  if ($i <= $expected_check_count_1) {
    ++ $promise_2_total;
  }

  # check promise 3
  if ($i <= $expected_check_count_2) {
    ++ $promise_3_total;
  }

  $average += $i;

}

# report results

print "Promise 1:\n";
print "Succeeded $promise_1_total / $trials times = " .
  sprintf("%0.8f%%\n", 100 * ($promise_1_total / $trials));
print "Expected success rate is " .
  sprintf("%0.8f%%\n", 100 *(1-(($e/2)**($q+1))));

if ((1-(($e/2)**($q+1))) <= ($promise_1_total / $trials)) {
  print "Promise 1: SUCCESS!\n";
} else {
  print "Promise 1: FAILURE!\n";
}

print "Promise 2:\n";
print "Decoded message in $expected_check_count_1 or fewer check blocks " .
  "$promise_2_total / $trials times = " .
  sprintf("%0.8f%%\n", 100 * ($promise_2_total / $trials));

print "Promise 3:\n";
print "Decoded message in  $expected_check_count_2 or fewer check blocks " .
  "$promise_3_total / $trials times = " .
  sprintf("%0.8f%%\n", 100 * ($promise_3_total / $trials));

$average /= $trials;
print "Average:\n";
print "It took an average of $average check blocks to decode the message\n";
