#!perl

# Name: Searching for a variable string using index()
# Require: 4
# Desc:
#


require 'benchlib.pl';

$a = "xx" x 100;
$b = "foobar";
$c = "xxx";

&runtest(15, <<'ENDTEST');

   $c = index($a, $b);
   $c = index($a, $c);

   $c = index($a, $b);
   $c = index($a, $c);

ENDTEST
