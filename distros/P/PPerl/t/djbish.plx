#!perl -w
use strict;

local $^W;

open SOUT, "<&=1"
  or die "cannot dup fd 1 - $!";
my $read = <SOUT>;
close SOUT
  or die "cannot close fd 1 - $!";

chomp $read;
exit 20 if $read eq "#!perl -w"; # the top line of this file
exit 1;
