# -*- perl -*-

# t/603_diggs_user.t - check user/diggs endpoint

use Test::Simple tests => 1;
use Net::Digg;
use Data::Dumper;

my $digg = Net::Digg->new();
my $result = $digg->get_diggs_by_user('kwilms');

ok( $result->{ 'count' } == 10 );
