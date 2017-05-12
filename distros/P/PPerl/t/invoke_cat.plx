#!perl -w
use strict;
open STDIN,  "<t/cat.plx" or die "couldn't reopen STDIN";
exec "$^X t/cat.plx";
