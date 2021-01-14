use strict;
use warnings;

use Test::More tests => 1;                      # last test to print
use Data::Dumper;

require_ok('Net::OBS::Client::BuildResults');

my $build_results = Net::OBS::Client::BuildResults->new(
  project     => "OBS:Server:Unstable",
  repository  => "images",
  arch        => "x86_64",
  package     => "OBS-Appliance-qcow2",
  use_oscrc   => 1
);
  

my $bl = $build_results->binarylist();
print Dumper($bl);
my $bin = undef;
foreach my $result (@$bl) {
  if ($result->{filename} =~ /\.qcow2$/ ) {
    $bin = $result->{filename};
  }
}
if ($bin) {
  print "bin: $bin\n";
  print Dumper($build_results->fileinfo($bin));
}
exit 0;

