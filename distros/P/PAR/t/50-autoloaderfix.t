#!/usr/bin/perl
# Problem doesn't manifest if Test::More is in effect?
# What the hell?

use File::Temp ();
BEGIN { $ENV{PAR_TMPDIR} = File::Temp::tempdir(TMPDIR => 1, CLEANUP => 1); }

$|=1;
print "1..1\n";
use PAR;

package Bar;
use AutoLoader 'AUTOLOAD';
# Can't use strict and warnings because in case of the
# erroneous recursion, we'll require ourselves and get a
# "subroutine redefined" error which doesn't matter.
sub new {
    return bless {} => $_[0];
}

package main;

$INC{"Bar.pm"} = $0; # <--
{
    my $p = Bar->new();
} # <-- looping while looking for Bar::DESTROY

print "ok 1 - AutoLoader works\n";

