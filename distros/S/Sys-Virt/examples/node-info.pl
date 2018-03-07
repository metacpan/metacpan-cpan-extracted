#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;

my $addr = @ARGV ? shift @ARGV : "";

my $hv = Sys::Virt->new(address => $addr, readonly => 1);

my $info = $hv->get_node_info();

my @models = $hv->get_cpu_model_names($info->{model});

print "Available CPU model names:\n";
print join ("\n", map { "  " . $_ } sort{ lc $a cmp lc $b } @models), "\n";

my @pagesizes = (
    4, 2048, 1048576
    );

my @info = $hv->get_node_free_pages(\@pagesizes, 0, 0);

print "Free pages per NUMA node:\n";
foreach my $info (@info) {
    print "  Node: ", $info->{cell}, "\n";
    print "  Free: ";
    for (my $i = 0; $i <= $#pagesizes; $i++) {
	my $pagesize = $pagesizes[$i];
	printf "%d @ %d KB, ", $info->{pages}->{$pagesize}, $pagesize;
    }
    print "\n";
}

my $xml = $hv->get_domain_capabilities(undef, "x86_64", undef, "kvm");
print $xml;
