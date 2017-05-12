#!/usr/bin/perl -w

use Set::Files;

my $obj = new Set::Files ('path' => './dir');

# List the sets

@sets = $obj->list_sets();
print "Sets:\n";
foreach my $set (sort @sets) {
   print "   Set: $set\n";

   @members = $obj->members($set);
   foreach my $member (@members) {
      print "      $member\n";
   }
}



