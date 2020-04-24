#!/usr/bin/perl -w

use Org::FRDCSA::AIE::Method::SimpleLCS;

use Data::Dumper;

my $entries =
  [
   "This is a more involved example test again",
   "This is a thing again",
   "This is a ghong again",
   "This is a test again",
  ];

print Dumper(AIE(Entries => $entries));
