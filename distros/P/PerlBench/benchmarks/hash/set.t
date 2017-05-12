#!perl

# Name: Add keys to a hash
# Require: 4
# Desc:
#


require 'benchlib.pl';

$key = "abc";
for (1..1000) {
    $hash{$key} = 1;
    $key++;
}

&runtest(10, <<'ENDTEST');

   $key = "abc";

   $hash{$key} = 1;
   $hash{$key} = 2;
   $hash{$key} = 3;
   $hash{$key} = 4;
   $hash{$key} = 5;
   $key++;

   $hash{$key} = 1;
   $hash{$key} = 2;
   $hash{$key} = 3;
   $hash{$key} = 4;
   $hash{$key} = 5;
   $key++;

   $hash{$key} = 1;
   $hash{$key} = 2;
   $hash{$key} = 3;
   $hash{$key} = 4;
   $hash{$key} = 5;
   $key++;
ENDTEST
