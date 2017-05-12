#!/usr/bin/perl

use Sys::Virt;

if (int(@ARGV) < 2) {
    die "syntax: $0 URI PAGESIZE=1COUNT1 PAGESIZE2=COUNT2...";
}

my $uri = shift @ARGV;

my $c = Sys::Virt->new(uri => $uri);

my @pages;
foreach (@ARGV) {
    my @bits = split /=/;

    push @pages, \@bits;
}


$c->node_alloc_pages(\@pages, -1, -1);
