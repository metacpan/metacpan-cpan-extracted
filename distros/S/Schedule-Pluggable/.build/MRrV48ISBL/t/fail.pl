#!/usr/bin/env perl

my $sleep = shift;
sleep $sleep if $sleep;
warn "something went wrong\n";
exit 1;
