# -*- perl -*-

# t/900_media.t - check media endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
my $result = $digg->get_media();

ok(defined $result->{'media'}[0]->{'name'} );
