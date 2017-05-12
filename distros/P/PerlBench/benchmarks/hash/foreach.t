#!perl

# Name: Traverse hash with foreach (sort keys %hash)
# Require: 5
# Desc:
#


require 'benchlib.pl';

$i = "abc";
for (1..80) {
    $hash{$i} = $j++;
    $i++;
}
#print "keys %hash = ", int(keys %hash), "\n";

&runtest(1, <<'ENDTEST');

   my $k;
   foreach $k (keys %hash) {
       my $v = $hash{$k};
       # 
   }

ENDTEST
