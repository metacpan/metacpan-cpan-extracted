#!/usr/bin/perl


use strict;
use warnings;

use Sys::Virt;
use Sys::Virt::Domain;

my $uri = @ARGV ? shift @ARGV : undef;

my $c = Sys::Virt->new(uri => $uri);

my @doms;
foreach my $name (@ARGV) {
    push @doms, $c->get_domain_by_name($name);
}

my @stats = $c->get_all_domain_stats(Sys::Virt::Domain::STATS_STATE,
				     \@doms,
				     Sys::Virt::Domain::GET_ALL_STATS_ENFORCE_STATS);

foreach my $stats (@stats) {
    print "Guest ", $stats->{'dom'}->get_name(), "\n";
    print "  State: ", $stats->{'data'}->{'state.state'}, "\n";
}
