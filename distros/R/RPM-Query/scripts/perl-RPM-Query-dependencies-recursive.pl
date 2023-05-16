#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw{basename};
use Tie::IxHash;
use RPM::Query;
use RPM::Query::Package;

my $syntax               = sprintf("%s package\n", basename($0));
my $input                = shift or die($syntax);
my $query                = RPM::Query->new->query($input) or die("Package: $input not found\n");
my $input_pkg            = $query->package_name or die;

printf "Input: %s, Package: %s\n", $input, $input_pkg;

my $job_cache            = {};
tie %$job_cache, 'Tie::IxHash';
$job_cache->{$input_pkg} = {type=>'implemetation', todo=>1};
my $whatprovides_cache   = {};
my $loop                 = 0;

while (1) {
  $loop++;
  print "Loop: $loop\n";
  my @todo = grep {$job_cache->{$_}->{'todo'}} keys %$job_cache;
  foreach my $job_package_name (@todo) {
    printf "Job: $job_package_name\n";
    my $package_obj = RPM::Query::Package->new(package_name=>$job_package_name);
    my $requires    = $package_obj->requires;
    foreach my $capability (@$requires) {
      printf "  Capability: %s\n", $capability->name;
      my $whatprovides = $whatprovides_cache->{$capability->name} ||= $capability->whatprovides;
      foreach my $package (@$whatprovides) { #could be zero or more but normally one
        printf "    Package: %s\n", $package->package_name;
        last if $job_cache->{$package->package_name}; #skip if in job queue
        printf "      Adding...\n";
        $job_cache->{$package->package_name} = {type=>"dependency", todo=>1};
      }
    }
    $job_cache->{$job_package_name}->{'todo'} = 0;
  }
  @todo = grep {$job_cache->{$_}->{'todo'}} keys %$job_cache;
  last unless @todo;
}

foreach my $pkg (keys %$job_cache) {
  my $hash = $job_cache->{$pkg};
  printf "Package: %s, Type: %s\n", $pkg, $hash->{'type'};
}

__END__

=head1 NAME

perl-RPM-Query-dependencies-recursive.pl - Script to display all packages that a packages requires

=cut

