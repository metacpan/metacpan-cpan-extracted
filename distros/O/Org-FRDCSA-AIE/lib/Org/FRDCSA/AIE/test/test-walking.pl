#!/usr/bin/perl -w

use Org::FRDCSA::Method::Walking;

use Data::Dumper;

# walk through all the strings simultaneously, and figure out how to resync them

my $entries;
if (0) {
  $entries =
    [
     "this is the first and the second",
     "this is the second and the third",
     "this is the third and the first",
    ];
} else {
  $entries =
    [
     "So Andy and Lidda went to the store, where they bought a dog.",
     "So Kate and Eva went to the grocery, where they shopped for food.",
     "So Mary went to the church, where she got to know God",
    ];
}

# it will walk to the point where there is the first, second and third.

# then it will search until it finds "and the" common to all of them.
# Perhaps what it can do is search all combinations of lengths less
# than a given range and look for the shared string using LCS.  once it has found a shared string, it continues on from that point

print Dumper
  (AIE
   (
    Entries => $entries,
   ));
