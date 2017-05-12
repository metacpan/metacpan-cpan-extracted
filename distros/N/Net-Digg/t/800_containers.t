# -*- perl -*-

# t/800_containers.t - check containers endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
my $result = $digg->get_containers();

ok(defined $result->{'containers'}[0]->{'name'} );
