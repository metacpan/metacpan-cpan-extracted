#!/usr/bin/perl
use warnings;
use strict;
use Sys::Virt;

my $pagetoscan = shift @ARGV || 200;
my $sleepmillis = shift @ARGV || 100;

my $uri = "qemu:///system";
my $con = Sys::Virt->new(address => $uri);

my $params = $con->get_node_memory_parameters();
foreach my $key (keys %{$params}) {
    printf "%s: %d\n", $key, $params->{$key};
}

my %param = (Sys::Virt::NODE_MEMORY_SHARED_PAGES_TO_SCAN => $pagetoscan,
	     Sys::Virt::NODE_MEMORY_SHARED_SLEEP_MILLISECS => $sleepmillis);
$con->set_node_memory_parameters(\%param);

$params = $con->get_node_memory_parameters();
foreach my $key (keys %{$params}) {
    printf "%s: %d\n", $key, $params->{$key};
}
