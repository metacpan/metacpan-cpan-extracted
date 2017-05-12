#!/usr/bin/perl
use strict;
use Parse::Syslog::Mail;

my $maillog = Parse::Syslog::Mail->new(shift) or die $!;
while(my $log = $maillog->next) {
    for my $field (sort keys %$log) { print "  \e[1m$field\e[0m = $$log{$field}\n" }
    print $/
}
