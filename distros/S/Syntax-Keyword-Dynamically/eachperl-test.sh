#!/bin/sh
eachperl -e '
  exit unless $] >= 5.014;
  system($^X, "Build.PL") == 0 && system("./Build clean && ./Build test") == 0 and
     print "\e[32;1m-- PASS --\e[m\n" or
     print "\e[31;1m-- FAIL --\e[m\n";
  kill $?, $$ if $? & 127;'
