#!perl

# Name: Regexp matching of /constant/
# Require: 4
# Desc:
#


require 'benchlib.pl';

$a = ("-" x 100) . "foo" . ("-" x 100);

&runtest(15, <<'ENDTEST');

   $a =~ /foo/;
   $a =~ /---/;
   $a =~ /bar/;

   $a =~ /foo/;
   $a =~ /---/;
   $a =~ /bar/;

ENDTEST
