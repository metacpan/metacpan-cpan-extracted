#!/usr/bin/perl -w
use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Module::CPANTS;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

my $arg = shift || die "Pass a string to search for";

my $cpants = Module::CPANTS->new->data;

foreach my $dist (sort keys %$cpants) {
  next unless $dist =~ /$arg/;
  use Data::Dumper; print Dumper({ $dist => $cpants->{$dist}});
  print "\n";
}

