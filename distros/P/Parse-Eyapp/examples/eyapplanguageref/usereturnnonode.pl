#!/usr/bin/perl -w
use strict;
use Parse::Eyapp;
use returnnonode;

sub TERMINAL::info { $_[0]{attr} }

my $parser = returnnonode->new();
my $t = $parser->Run;
print $t->str,"\n";
