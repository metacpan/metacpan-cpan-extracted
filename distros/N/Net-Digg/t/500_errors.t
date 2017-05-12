# -*- perl -*-

# t/500_errors.t - check errors endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_errors();

ok( defined $result->{ 'errors' }[0]->{'message'} );
