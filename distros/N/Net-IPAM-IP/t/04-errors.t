#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::IP') || print "Bail out!\n"; }

can_ok( 'Net::IPAM::IP', 'new' );
can_ok( 'Net::IPAM::IP', 'new_from_bytes' );

eval { Net::IPAM::IP->new };
like( $@, qr/wrong/i, 'new: missing arg' );

eval { Net::IPAM::IP->new_from_bytes };
like( $@, qr/wrong/i, 'new_from_bytes: missing arg' );

my $ip    = Net::IPAM::IP->new('1.2.3.4');
my $bytes = substr( $ip->bytes, 1 );
eval { Net::IPAM::IP->new_from_bytes($bytes) };
like( $@, qr/illegal input/i, 'new_from_bytes: wrong number of bytes' );

$ip    = Net::IPAM::IP->new('fe80::1');
$bytes = substr( $ip->bytes, 1 );
eval { Net::IPAM::IP->new_from_bytes($bytes) };
like( $@, qr/illegal input/i, 'new_from_bytes: wrong number of bytes' );

$ip    = Net::IPAM::IP->new('fe80::1');
eval { $ip->cmp() };
like( $@, qr/wrong or missing/i, 'cmp: wrong or missing arg' );

eval { $ip->cmp('foo') };
like( $@, qr/wrong or missing/i, 'cmp: wrong or missing arg' );

eval { $ip->cmp(bless {}, 'foo') };
like( $@, qr/wrong or missing/i, 'cmp: wrong or missing arg' );

$ip = Net::IPAM::IP->new('fe80::1');
$ip->{binary} = substr( $ip->{binary}, 1 );
eval { $ip->expand };
like( $@, qr/logic error/i, 'expand: logic error' );

$ip = Net::IPAM::IP->new('0.0.0.0');
$ip->{binary} = substr( $ip->{binary}, 1 );
eval { $ip->reverse };
like( $@, qr/logic error/i, 'expand: logic error' );

done_testing();
