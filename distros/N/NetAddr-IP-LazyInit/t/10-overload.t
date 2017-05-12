use Test::More;
use strict;
use warnings;
use lib './lib';

use NetAddr::IP::LazyInit;

my $ipcidr = NetAddr::IP::LazyInit->new( '10.10.10.5/24' );
my $ip = NetAddr::IP::LazyInit->new( '10.10.10.5' );

is($ipcidr, '10.10.10.5/24', 'Does stringify work');
is($ip, '10.10.10.5/32', 'Stringify without netmask');

done_testing();
