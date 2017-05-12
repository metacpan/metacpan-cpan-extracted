# -*- perl -*-

# t/201_users_username.t - check user/<username> endpoint

use Test::Simple tests => 1;
use Net::Digg;

my $digg = Net::Digg->new();
my $result = $digg->get_user_by_name('kwilms');

ok( $result->{ 'users' }[0]->{'name'} eq 'kwilms' );
