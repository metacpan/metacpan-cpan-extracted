#!/usr/bin/perl -w
# vim:set ft=perl:

use strict;
use Test::More;

my @modules = ();

local *MANIFH;
open MANIFH, "MANIFEST" or die "No MANIFEST?!: $!";
while (<MANIFH>) {
    chomp;
    if (s/\.pm$//) {
        s#/#::#g;
        s#^lib::##;
        push @modules, $_;
    }
}
close MANIFH;

plan tests => scalar @modules;
use_ok($_) for @modules;
