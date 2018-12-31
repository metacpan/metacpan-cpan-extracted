use strict;
use warnings;

use Test::More;

use NetPacket::ICMPv6 qw(:types :codes);
use NetPacket::IPv6;
use NetPacket::Ethernet;

my @test_data = (
  { type => ICMPv6_ECHOREQ, code => 0, cksum => 39252, len => 60 },
  { type => ICMPv6_ECHOREPLY, code => 0, cksum => 38996, len => 60 },
  { type => ICMPv6_NEIGHBORSOLICIT, code => 0, cksum => 43237, len => 28 },
  { type => ICMPv6_ROUTERSOLICIT, code => 0, cksum => 21054, len => 12 },
  { type => ICMPv6_NEIGHBORADVERT, code => 0, cksum => 61573, len => 20 },
);

my @datagrams = map { chomp; length($_) ? join('', map { chr hex } split /\./) : () } <DATA>;

foreach my $datagram (@datagrams) {
  my $test = shift @test_data;

  my $eth = NetPacket::Ethernet->decode( $datagram );

  my $ipv6 = NetPacket::IPv6->decode( $eth->{data} );

  my $icmpv6 = NetPacket::ICMPv6->decode( $ipv6->{data} );

  is $icmpv6->{type} => $test->{type}, 'Right message type';
  is $icmpv6->{code} => $test->{code}, 'Right message code';
  is $icmpv6->{cksum} => $test->{cksum}, 'Right message checksum';
  is length($icmpv6->{data}) => $test->{len}, 'Right message length';

  my $q = NetPacket::ICMPv6->decode( $icmpv6->encode( $ipv6 ) );

  foreach my $key (grep { !m/^_/ } keys %$icmpv6) {
    is_deeply $q->{$key}, $icmpv6->{$key}, "Round-trip $key";
  }
}

done_testing;

__DATA__
0.0.5E.0.2.F0.FA.90.3C.6A.DB.7C.86.DD.60.0.0.0.0.40.3A.40.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1.26.7.F8.B0.40.6.8.19.0.0.0.0.0.0.20.E.80.0.99.54.5B.D9.0.1.4E.9D.AD.5A.0.0.0.0.9.A6.7.0.0.0.0.0.10.11.12.13.14.15.16.17.18.19.1A.1B.1C.1D.1E.1F.20.21.22.23.24.25.26.27.28.29.2A.2B.2C.2D.2E.2F.30.31.32.33.34.35.36.37
FA.90.3C.6A.DB.7C.5C.45.27.78.FB.30.86.DD.60.0.0.0.0.40.3A.39.26.7.F8.B0.40.6.8.19.0.0.0.0.0.0.20.E.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1.81.0.98.54.5B.D9.0.1.4E.9D.AD.5A.0.0.0.0.9.A6.7.0.0.0.0.0.10.11.12.13.14.15.16.17.18.19.1A.1B.1C.1D.1E.1F.20.21.22.23.24.25.26.27.28.29.2A.2B.2C.2D.2E.2F.30.31.32.33.34.35.36.37
0.0.5E.0.2.F0.FA.90.3C.6A.DB.7C.86.DD.60.0.0.0.0.20.3A.FF.FE.80.0.0.0.0.0.0.F8.90.3C.FF.FE.6A.DB.7C.26.4.A8.80.8.0.0.A1.0.0.0.0.0.0.0.1.87.0.A8.E5.0.0.0.0.26.4.A8.80.8.0.0.A1.0.0.0.0.0.0.0.1.1.1.FA.90.3C.6A.DB.7C
33.33.0.0.0.2.FE.90.3C.6A.DB.7C.86.DD.60.0.0.0.0.10.3A.FF.FE.80.0.0.0.0.0.0.FC.90.3C.FF.FE.6A.DB.7C.FF.2.0.0.0.0.0.0.0.0.0.0.0.0.0.2.85.0.52.3E.0.0.0.0.1.1.FE.90.3C.6A.DB.7C
0.0.5E.0.2.F0.FA.90.3C.6A.DB.7C.86.DD.60.0.0.0.0.18.3A.FF.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1.26.4.A8.80.8.0.0.A1.0.0.0.0.0.0.0.1.88.0.F0.85.40.0.0.0.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1
