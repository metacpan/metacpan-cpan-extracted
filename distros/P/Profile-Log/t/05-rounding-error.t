#  -*- perl -*-

# this test script checks that rounding errors do not accumulate in
# output.

use Test::More tests => 1;
use YAML qw(Load);
use Profile::Log;

my $profile = Load <<YAML;
--- !perl/Profile::Log
  0:
    - 85102
    - 544547
  Z:
    - 85104
    - 509547
  mc: 0
  t:
    - read
    - 0.0014
    - parseXML
    - 0.0064
  tag:
    ID: '4,463623'
    what: FE
YAML

is($profile->logline, "ID=4,463623; what=FE; 0=11:38:22.544; tot=1.965; read=0.001; parseXML=0.007", "rounding errors distributed over times");
