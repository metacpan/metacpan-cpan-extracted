use Test::More tests => 1;

use Net::Lookup::DotTel;

my $lookup = Net::Lookup::DotTel->new;

ok ( ! $lookup->lookup( 'probablydoesnotexist1785728579238532.tel' ), 'looking up a non-existing .tel name' );
