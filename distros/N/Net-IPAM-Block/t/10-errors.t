#!perl -T

use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

can_ok( 'Net::IPAM::Block', 'new' );

eval { Net::IPAM::Block->new };
like( $@, qr/missing/i, 'new: missing arg' );

ok( defined( Net::IPAM::Block->new('/') ) eq '',          'new: wrong cidr' );
ok( defined( Net::IPAM::Block->new('/20') ) eq '',        'new: wrong prefix' );
ok( defined( Net::IPAM::Block->new('1.2.3.4/') ) eq '',   'new: wrong bits' );
ok( defined( Net::IPAM::Block->new('1.2.3.4/33') ) eq '', 'new: wrong bits' );
ok( defined( Net::IPAM::Block->new('1.2.3.4/-2') ) eq '', 'new: wrong bits' );
ok( defined( Net::IPAM::Block->new('1.2.3.4-') ) eq '',   'new: wrong range' );
ok( defined( Net::IPAM::Block->new('-fe80::1') ) eq '',   'new: wrong range' );

my $b1 = Net::IPAM::Block->new('1.2.3.4/24');

done_testing();
