#!perl -Ilib -I../lib -Iexample/lib

# from the perlpragma manpage

use strict;
use warnings;


use MyMaths;

my $l = MyMaths->new(1.2);
my $r = MyMaths->new(3.4);

print "A: ", $l + $r, "\n";

use myint;
print "B: ", $l + $r, "\n";

{
    no myint;
    print "C: ", $l + $r, "\n";
}

print "D: ", $l + $r, "\n";

no myint;
print "E: ", $l + $r, "\n";

