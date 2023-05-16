#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw{basename};
use RPM::Query;

my $syntax   = sprintf("%s package\n", basename($0));
my $input    = shift or die($syntax);
my $rpm      = RPM::Query->new;
my $pkg      = $rpm->query($input) or die("Package: $input not found\n");

printf "Input: %s, Package: %s\n", $input, $pkg->package_name;

my $requires = $pkg->requires;

foreach my $capability (@$requires) {
  printf "Capability: %s\n", $capability->name;
  my $whatprovides = $capability->whatprovides;
  foreach my $package (@$whatprovides) { #could be zero or more but normally one
    printf "  Package: %s\n", $package->package_name;
  } 
}

__END__

=head1 NAME

perl-RPM-Query-dependencies.pl - Script to display capabilities that a packages requires

=cut
