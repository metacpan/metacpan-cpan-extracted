#!/usr/bin/perl
use strict;
use warnings;
use RPM::Query;

my $query        = shift || 'perl';
my $rpm          = RPM::Query->new;
my $package      = $rpm->query($query); #isa RPM::Query::Package
my $name         = $package->package_name;
my $description  = $package->description;
my $capabilities = $package->requires;    #isa list of RPM::Query::Capability
foreach my $capability (@$capabilities) {
  my $packages = $capability->whatprovides;
  printf "%s - %s\n", $capability->name, join(", ", map {$_->package_name} @{$packages});
}

__END__

=head1 NAME

perl-RPM-Query-capabilities.pl - Script to display capabilities given a package name

=cut
