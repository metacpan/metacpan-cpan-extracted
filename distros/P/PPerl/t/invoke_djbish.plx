#!perl -w
use strict;
open STDIN,  "<t/djbish.plx" or die "couldn't reopen STDIN";
open STDOUT, "<t/djbish.plx" or die "couldn't reopen STDOUT";
exec "$^X t/djbish.plx";
