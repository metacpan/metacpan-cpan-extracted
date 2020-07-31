#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::IP')                        || print "Bail out!\n";
  use_ok( 'Net::IPAM::Util', qw(incr_n decr_n) ) || print "Bail out!\n";
}

my $tt = {
  pack( 'C4', 10, 0, 0, 1 ) => pack( 'C4', 10, 0, 0, 2 ),
  pack( 'n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 ) => pack( 'n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 2 ),
  pack( 'n8', 0x2001, (0xffff) x 7 ) => pack( 'n8', 0x2002, (0x0) x 7 ),
};

for my $k ( sort keys %$tt ) {
  ok( incr_n($k) eq $tt->{$k}, 'incr_n ' . unpack( 'H*', $k ) );
}

$tt = {
  pack( 'C4', 10, 0, 0, 1 ) => pack( 'C4', 10, 0, 0, 0 ),
  pack( 'n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 1 ) => pack( 'n8', 0x2001, 0xdb8, 0, 0, 0, 0, 0, 0 ),
  pack( 'n8', 0x1000, (0x0000) x 7 ) => pack( 'n8', 0x0fff, (0xffff) x 7 ),
};

for my $k ( sort keys %$tt ) {
  ok( decr_n($k) eq $tt->{$k}, 'decr_n ' . unpack( 'H*', $k ) );
}

ok( !incr_n( pack( 'C4', 255, 255, 255, 255 ) ), 'overflow  32bit' );
ok( !incr_n( pack( 'n8', (0xffff) x 8 ) ),       'overflow 128bit' );

ok( !decr_n( pack( 'C4', 0, 0, 0, 0 ) ),   'underflow  32bit' );
ok( !decr_n( pack( 'n8', (0x0000) x 8 ) ), 'underflow 128bit' );

eval { incr_n() };
like( $@, qr/missing/, 'incr_n(), missing argument' );

eval { decr_n() };
like( $@, qr/missing/, 'decr_n(), missing argument' );

#############################

my $good = [
  { ip => '10.0.0.1',        expect => '10.0.0.2', test => 'IPv4 incr' },
  { ip => '::ffff:10.0.0.1', expect => '10.0.0.2', test => 'IPv4mappedv6 incr' },
  { ip => '2001::1',         expect => '2001::2',  test => 'IPv6 incr' },
];

foreach my $item (@$good) {
  my $ip = Net::IPAM::IP->new( $item->{ip} );
  ok( $ip->incr->to_string eq $item->{expect}, $item->{test} );
}

$good = [
  { ip => '10.0.0.1',        expect => '10.0.0.0', test => 'IPv4 decr' },
  { ip => '::ffff:10.0.0.1', expect => '10.0.0.0', test => 'IPv4mappedv6 decr' },
  { ip => '2001::1',         expect => '2001::',   test => 'IPv6 decr' },
];

foreach my $item (@$good) {
  my $ip = Net::IPAM::IP->new( $item->{ip} );
  ok( $ip->decr->to_string eq $item->{expect}, $item->{test} );
}

my $overflow = [
  { ip => '255.255.255.255',        test => 'overflow IPv4 incr' },
  { ip => '::ffff:255.255.255.255', test => 'overflow IPv4mappedv6 incr' },
  { ip => 'ffff:' x 7 . 'ffff',     test => 'overflow IPv6 incr' },
];

foreach my $item (@$overflow) {
  my $ip = Net::IPAM::IP->new( $item->{ip} );
  ok( !$ip->incr, $item->{test} );
}

my $underflow = [
  { ip => '0.0.0.0',        test => 'underflow IPv4 decr' },
  { ip => '::ffff:0.0.0.0', test => 'underflow IPv4mappedv6 decr' },
  { ip => '::',             test => 'underflow IPv6 decr' },
];

foreach my $item (@$underflow) {
  my $ip = Net::IPAM::IP->new( $item->{ip} );
  ok( !$ip->decr, $item->{test} );
}

done_testing();
