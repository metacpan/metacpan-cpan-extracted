use strict;
use warnings;

use Test::More tests => 1;                      # last test to print
use Data::Dumper;

require_ok('Net::OBS::Client::Package');

my $pkg = Net::OBS::Client::Package->new(
  name=> "obs-server",
  project=> "home:M0ses:branches:OBS:Server:Unstable",
  repository => "openSUSE_42.1", 
  arch=> "x86_64",
  use_oscrc => 1
);
 
#print Dumper($build_results->resultlist());

#print Dumper($build_results->result());

print Dumper($pkg->fetch_status);

print $pkg->code . "\n";

exit 0;

