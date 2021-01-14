use strict;
use warnings;

use Test::More tests => 1;                      # last test to print
use Data::Dumper;

require_ok('Net::OBS::Client::Project');

my $prj = Net::OBS::Client::Project->new(
  name     => "home:M0ses:branches:OBS:Server:Unstable",
);
  
#print Dumper($build_results->resultlist());

#print Dumper($build_results->result());

#print Dumper($prj->resultlist);

print $prj->code("images","x86_64") . "\n";
print $prj->dirty("images","x86_64") . "\n";

exit 0;

