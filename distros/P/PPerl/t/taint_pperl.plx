#!./pperl -Iblib/lib -Iblib/arch -Tw
use strict;
my $arg = shift;
open FOO, ">$arg"
  or die "couldn't open $!";

die "should have died!!!";
print FOO "bar";

#should be dead already
