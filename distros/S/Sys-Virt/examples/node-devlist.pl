#!/usr/bin/perl

use Sys::Virt;

my $conn = Sys::Virt->new();

my @nodelist = $conn->list_all_node_devices();
foreach my $dev (@nodelist){
    my $parent = $dev->get_parent();
    printf "%s: < %s\n", $dev->get_name(), $parent;
}
