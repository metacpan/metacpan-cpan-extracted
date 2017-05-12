#!/usr/bin/perl
use strict;
use Module::ThirdParty;

print "Known third-party software:\n";
my @softs = Module::ThirdParty::provides;
for my $soft (sort {$a->{name} cmp $b->{name}} @softs) {
    print " - $$soft{name} by $$soft{author} \n"
}
