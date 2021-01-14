use strict;
use warnings;

use Test::More tests => 1;                      # last test to print
use Data::Dumper;

require_ok('Net::OBS::Client');

my $obs_client = Net::OBS::Client->new();

print Dumper(
  $obs_client->request('GET'=>'/source/openSUSE:Tools')
);

my $oc2 = Net::OBS::Client->new(use_oscrc=>1);

print Dumper(
  $oc2->request('GET'=>'/source/openSUSE:Tools')
);

exit 0;

