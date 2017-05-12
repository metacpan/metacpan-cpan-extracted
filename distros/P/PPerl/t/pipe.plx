#!perl -w
use strict;

open FOO, "$^X t/cat.plx t/cat.plx |"
  or die "can't open pipe $!";
close FOO
  or die "couldn't close pipe '$!' $?";
