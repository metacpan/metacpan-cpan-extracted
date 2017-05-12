#!perl

# checking that invertion works the way we think it should

use strict;
use warnings;
use Test::More tests => 4;
use Net::IPAddress::Minimal qw( invert_ip num_to_ip ip_to_num );

my $ip_a   = '7.91.205.21';
my $ip_num = 123456789;
is( invert_ip($ip_a), $ip_num,   'invert_ip() ip to num' );
is( invert_ip($ip_num), $ip_a,   'invert_ip() num to ip' );
is( num_to_ip($ip_num), $ip_a,   'num_to_ip()'           );
is( ip_to_num($ip_a),   $ip_num, 'ip_to_num()'           );

