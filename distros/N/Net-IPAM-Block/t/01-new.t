#!perl -T
use 5.10.0;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Net::IPAM::Block') || print "Bail out!\n"; }

can_ok( 'Net::IPAM::Block', 'new' );

eval { Net::IPAM::Block->new() };
like( $@, qr/missing/i, 'new() without arg croaks' );

my $good = [
  [qw(1.2.3.4-1.2.3.4 1.2.3.4/32)],
  [qw(fe80::1-fe80::1 fe80::1/128)],
  [qw(0.0.0.0 0.0.0.0/32)],
  [qw(255.255.255.255 255.255.255.255/32)],
  [qw(255.255.255.254-255.255.255.255 255.255.255.254/31)],
  [qw(255.255.255.253-255.255.255.255 255.255.255.253-255.255.255.255)],
  [qw(10.11.12.13/8 10.0.0.0/8)],
  [qw(10.0.0.1/0.0.0.0 0.0.0.0/0)],
  [qw(10.0.0.1/255.0.0.0 10.0.0.0/8)],
  [qw(10.0.0.1/255.255.0.0 10.0.0.0/16)],
  [qw(10.0.0.1/255.255.255.0 10.0.0.0/24)],
  [qw(10.0.0.1/255.255.255.255 10.0.0.1/32)],
  [qw(255.255.255.255/1 128.0.0.0/1)],
  [qw(255.255.255.255/2 192.0.0.0/2)],
  [qw(255.255.255.255/3 224.0.0.0/3)],
  [qw(255.255.255.255/4 240.0.0.0/4)],
  [qw(255.255.255.255/5 248.0.0.0/5)],
  [qw(255.255.255.255/6 252.0.0.0/6)],
  [qw(255.255.255.255/7 254.0.0.0/7)],
  [qw(:: ::/128)],
  [qw(::ffff:0.0.0.0 0.0.0.0/32)],
  [qw(ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128)],
  [qw(FE80::/10 fe80::/10)],
  [qw(10.0.0.0-10.0.0.30 10.0.0.0-10.0.0.30)],
  [qw(10.0.0.0-10.0.0.31 10.0.0.0/27)],
  [qw(fe80::0-fe80::fffe fe80::-fe80::fffe)],
  [qw(fe80::0-fe80::ffff fe80::/112)],
  [qw(::ffff:1.2.3.0-::ffff:1.2.3.2 1.2.3.0-1.2.3.2)],
  [qw(::ffff:1.2.3.0-::ffff:1.2.3.3 1.2.3.0/30)],
];

my $b;
foreach my $tt (@$good) {
  my $b = Net::IPAM::Block->new( $tt->[0] );
  #
  # overload '""'
  ok( $b eq $tt->[1], "new('" . $tt->[0] . "') => " . $tt->[1] );
}

my $bad = [
  qw(
    0.0.0.0.0
    0.0.0.0/33
    0.0.0.0/0.0.0.0.0
    0.0.0.0/192.168.0.1
    fe80:::
    1.2.3.4--1.2.3.5 0.0.0.0/33
    ::/129 0.0.0.0-::
    ::-10.0.0.1
    1.1.1.1-1.1.1.0
    fe80::1-fe80::0)
];
foreach my $tt (@$bad) {
  ok( !Net::IPAM::Block->new($tt), "ok, new($tt) returns undef" );
}

$b = Net::IPAM::Block->new('10.1.2.3/16');
ok( $b->base eq '10.1.0.0',        'base' );
ok( $b->last eq '10.1.255.255',    'last' );
ok( $b->mask eq '255.255.0.0',     'mask' );
ok( $b->hostmask eq '0.0.255.255', 'hostmask' );

$b = Net::IPAM::Block->new('::-::2');
ok( $b->base eq '::',  'base' );
ok( $b->last eq '::2', 'last' );
ok( !$b->mask,         '! mask' );
ok( !$b->hostmask,     '! hostmask' );

my $ips = [
  [qw(1.2.3.4 1.2.3.4/32)],  [qw(::ffff:0.0.0.0 0.0.0.0/32)],
  [qw(fe80::1 fe80::1/128)], [qw(::cafe:affe ::cafe:affe/128)],
];

foreach my $tt (@$ips) {
  my $ip = Net::IPAM::IP->new( $tt->[0] );
  my $b  = Net::IPAM::Block->new($ip);

  # overload '""'
  ok( $b eq $tt->[1], "new from IP('" . $tt->[0] . "') => " . $tt->[1] );
}

my $bl = [
  [qw(0.0.0.0/8 24)],        [qw(10.0.0.0/13 19)],
  [qw(10.0.0.2-10.0.0.7 3)], [qw(::/0 128)],
  [qw(2001:db8::/104 24)],   [qw(2001:db8::/32 96)],
  [qw(2001:db8::affe-2001:db8::cafe 15)],
];

my $bi = [ [ '10.0.0.2-10.0.0.7', 6 ], [ '10.0.0.0/19', 2**13 ], [ '2001:db8::affe-2001:db8::cafe', 6913 ], ];

my @tt = (
  { b => '10.0.0.17',               bitlen => 0,  msg => 'bitlen for IPv4 address is 0' },
  { b => '10.0.0.17-10.13.2.3',     bitlen => 20, msg => 'bitlen for IPv4 block is 20' },
  { b => '::',                      bitlen => 0,  msg => 'bitlen for IPv6 address is 0' },
  { b => '2001:db8::-2001:db8::fe', bitlen => 8,  msg => 'bitlen for IPv6 block is 8' },
);

foreach my $t (@tt) {
  my $b = Net::IPAM::Block->new( $t->{b} );
  is( $b->bitlen, $t->{bitlen}, $t->{msg} );
}

# _clone()
foreach my $str (qw(192.168.0.0/16 2001:db8::/32)) {
  my $b = Net::IPAM::Block->new($str);
  my $c = Net::IPAM::Block::Private::_clone($b);
  is_deeply( $b, $c, 'cloned values' );
  cmp_ok( \$b->{base}, '!=', \$c->{base}, 'cloned base IP pointers differ' );
  cmp_ok( \$b->{last}, '!=', \$c->{last}, 'cloned last IP pointers differ' );
}

done_testing();
