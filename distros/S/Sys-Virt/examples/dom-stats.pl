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

use Data::Dumper;

print Dumper(\@stats);

for (my $i = 0 ; $i <= $#stats ; $i++) {
    print $stats[$i]->{'dom'}->get_name(), ": ", $stats[$i]->{'data'}->{'state.state'}, "\n";
}
