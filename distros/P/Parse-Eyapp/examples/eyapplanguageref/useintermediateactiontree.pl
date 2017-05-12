#!/usr/bin/perl -w
use strict;
use intermediateactiontree;

{ no warnings;
*A::info = *B::info = sub { $_[0]{attr} };
}

my $parser = intermediateactiontree->new();
my $t = $parser->Run;
print $t->str,"\n";
