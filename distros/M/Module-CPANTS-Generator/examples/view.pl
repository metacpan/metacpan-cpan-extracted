#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use FindBin;
use File::Spec::Functions;
use Storable;
use lib "$FindBin::Bin/../lib";
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

my $arg = shift || die "Pass a string to search for";

my $cpants = retrieve (catfile "$FindBin::Bin/../", "cpants.store")
  || die "Unable to find data";
$cpants = $cpants->{cpants};

foreach my $dist (sort keys %$cpants) {
  next unless $dist =~ /$arg/;
  print Dumper({$dist => $cpants->{$dist}});
  print "\n";
}

