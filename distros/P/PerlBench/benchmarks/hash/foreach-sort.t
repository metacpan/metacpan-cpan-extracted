#!perl

# Name: Traverse hash with foreach (sort keys %hash)
# Require: 4
# Desc:
#


require 'benchlib.pl';

$i = "abc";
for (1..70) {
    $hash{$i} = $j++;
    $i++;
}
#print "keys %hash = ", int(keys %hash), "\n";

&runtest(0.75, <<'ENDTEST');

   foreach $k (sort keys %hash) {
       $v = $hash{$k};
       # 
   }

ENDTEST
