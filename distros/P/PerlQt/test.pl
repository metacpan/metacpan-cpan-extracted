BEGIN{ chdir("PerlQt/t") or die "couldn't chdir to PerlQt: $!\n" }   
END{ chdir("../..") or die "couldn't chdir to ../..\n" }   

use blib;
use Test::Harness;

$Test::Harness::switches = "-w -Mblib=../blib";

@t = glob("*.t");

runtests(@t);