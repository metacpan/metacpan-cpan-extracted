#!/usr/bin/perl

use strict;
use warnings;

use Sys::Virt;
use Sys::Virt::Domain;

my $uri = @ARGV ? shift @ARGV : undef;

my $c = Sys::Virt->new(uri => $uri);

my $dom = $c->get_domain_by_name(shift @ARGV);

my @fs = $dom->get_fs_info();

foreach my $fs (@fs) {
    printf "%s (%s) at %s\n", $fs->{name}, $fs->{fstype}, $fs->{mountpoint};
}
