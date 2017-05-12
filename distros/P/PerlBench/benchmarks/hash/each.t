#!perl

# Name: Traverse hash with each()
# Require: 4
# Desc:
#


require 'benchlib.pl';

$i = "abc";
for (1..1000) {
    $hash{$i} = 1;
    $i++;
}
#print "keys %hash = ", int(keys %hash), "\n";

&runtest(0.05, <<'ENDTEST');

   while (($k,$v) = each %hash) {
       # 
   }

ENDTEST
