use strict;
use warnings;

use Test::More;

use NetPacket::IPv6 qw(:protos :extheaders);
use NetPacket::Ethernet;
use Socket 1.87 qw(AF_INET6 inet_pton);

my @test_data = (
  { proto => IP_PROTO_TCP, len => 210, hop_limit => 53,
    src_ip => '2a02:2f0d:bff0:1:81:18:73:123', dest_ip => '2604:a880:800:a1::d9:6001' },
  { proto => IP_PROTO_ICMPv6, len => 32, hop_limit => 255,
    src_ip => 'fe80::f890:3cff:fe6a:db7c', dest_ip => '2604:a880:800:a1::1' },
  { proto => IP_PROTO_UDP, len => 56, hop_limit => 64,
    src_ip => '2604:a880:800:a1::d9:6001', dest_ip => '2604:a880:800:10::1:9001' },
  { proto => IP_PROTO_UDP, len => 31, hop_limit => 57,
    src_ip => '2001:67c:6ec:224:f816:3eff:feee:9b4', dest_ip => '2604:a880:800:a1::d9:6001',
    extheaders => [{type => IPv6_EXTHEADER_DESTOPT, len => 0}] },
  { proto => IP_PROTO_UDP, len => 80, hop_limit => 57,
    src_ip => '2001:67c:6ec:224:f816:3eff:feee:9b4', dest_ip => '2604:a880:800:a1::d9:6001',
    extheaders => [{type => IPv6_EXTHEADER_ROUTING, len => 2}] },
  { proto => IP_PROTO_COMP, len => 166, hop_limit => 174,
    src_ip => '878e:f1f0:cdab:dcc6:232e:b88c:15c6:55ce', dest_ip => '4ab2:d018:cbf0:4462:c125:7300:d51a:42cd',
    extheaders => [{type => IPv6_EXTHEADER_TESTING2, len => 3}] },
  { proto => IPv6_EXTHEADER_ESP, len => 198, hop_limit => 40,
    src_ip => '584c:2ead:4dbf:2a8f:4ef:e5e9:b823:8b33', dest_ip => 'e1c5:2c79:5ab8:701e:d885:c2d:eee9:57ef' },
);

my @datagrams = map { chomp; length($_) ? join('', map { chr hex } split /\./) : () } <DATA>;

foreach my $datagram (@datagrams) {
  my $test = shift @test_data;

  my $eth = NetPacket::Ethernet->decode( $datagram );

  my $ipv6 = NetPacket::IPv6->decode( $eth->{data} );

  is $ipv6->{ver} => 6, 'IP version 6';
  is $ipv6->{proto} => $test->{proto}, 'Right protocol';
  is $ipv6->{len} => $test->{len}, 'Right payload length header';
  is $ipv6->{hop_limit} => $test->{hop_limit}, 'Right hop limit';
  is inet_pton(AF_INET6, $ipv6->{src_ip}), inet_pton(AF_INET6, $test->{src_ip}), 'Right source IP';
  is inet_pton(AF_INET6, $ipv6->{dest_ip}), inet_pton(AF_INET6, $test->{dest_ip}), 'Right destination IP';

  my $total_len = length($ipv6->{data});
  if (@{$ipv6->{extheaders} || []} or @{$test->{extheaders} || []}) {
    is 0+@{$ipv6->{extheaders} || []}, 0+@{$test->{extheaders} || []}, 'Extension header count';
    foreach my $extheader (@{$ipv6->{extheaders} || []}) {
      my $testheader = shift @{$test->{extheaders} || []};
      is $extheader->{type}, $testheader->{type}, 'Right extension header type';
      is $extheader->{len}, $testheader->{len}, 'Right extension header length header';
      is length($extheader->{data}), $testheader->{len} * 8 + 6, 'Right extension header length';
      $total_len += length($extheader->{data}) + 2;
    }
  }

  is $total_len, $test->{len}, 'Right payload size';

  my $q = NetPacket::IPv6->decode( $ipv6->encode );

  foreach my $key (grep { !m/^_/ } keys %$ipv6) {
    is_deeply $q->{$key}, $ipv6->{$key}, "Round-trip $key";
  }
}

done_testing;

__DATA__
FA.90.3C.6A.DB.7C.5C.45.27.78.FB.30.86.DD.60.8.FC.F7.0.D2.6.35.2A.2.2F.D.BF.F0.0.1.0.81.0.18.0.73.1.23.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1.1A.29.DA.E.28.54.4.7B.8A.75.17.6A.80.18.1.5F.D8.8B.0.0.1.1.8.A.13.86.D1.D6.1E.C0.E9.70.17.3.3.0.AD.FA.41.75.30.CB.7A.54.25.AD.81.41.10.C0.86.6B.A4.5D.9.EF.A6.C0.5C.A9.D8.E9.45.41.7.EE.12.C1.76.1F.5.AB.B2.48.FE.54.D4.56.42.7D.1C.F4.F.0.91.18.6E.2.90.F6.BF.41.8A.67.B2.BA.82.0.8.50.36.9E.FE.73.65.9D.3C.BA.5D.8A.89.4C.8B.AA.28.1E.75.DD.71.A6.7A.D0.1B.96.73.6B.ED.4E.87.11.AA.B9.4E.D1.F3.DB.DC.C6.E3.50.3B.7E.42.A7.83.FB.4.69.2B.2D.47.8A.BE.D9.BB.E9.FF.90.14.94.57.98.B6.F6.CD.37.7D.2B.D1.35.62.B0.4.8C.BC.27.B4.8F.DA.D0.D5.17.4D.A8.EF.63.57.3C.CF.D4.A7.64.71.D0.C7.50.AE.34.E2.65.0.F2.1D.59.15.16.8C.45.60.EE
0.0.5E.0.2.F0.FA.90.3C.6A.DB.7C.86.DD.60.0.0.0.0.20.3A.FF.FE.80.0.0.0.0.0.0.F8.90.3C.FF.FE.6A.DB.7C.26.4.A8.80.8.0.0.A1.0.0.0.0.0.0.0.1.87.0.A8.E5.0.0.0.0.26.4.A8.80.8.0.0.A1.0.0.0.0.0.0.0.1.1.1.FA.90.3C.6A.DB.7C
0.0.5E.0.2.F0.FA.90.3C.6A.DB.7C.86.DD.60.0.0.0.0.38.11.40.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1.26.4.A8.80.8.0.0.10.0.0.0.0.0.1.90.1.BB.7F.0.7B.0.38.9E.E0.23.0.9.20.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.DE.56.C0.8.71.2.98.B9.29.7C.5B.8D.B4.DE.EA.E.EB.68.E8.86.28.2.B2.2
FA.90.3C.6A.DB.7C.5C.45.27.78.FB.30.86.DD.60.0.0.0.0.1F.3C.39.20.1.6.7C.6.EC.2.24.F8.16.3E.FF.FE.EE.9.B4.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1.11.0.1.4.0.0.0.0.83.2.2B.CB.0.17.57.B5.0.0.0.0.0.1.0.0.73.74.61.74.73.D.A
FA.90.3C.6A.DB.7C.5C.45.27.78.FB.30.86.DD.60.0.0.0.0.50.2B.39.20.1.6.7C.6.EC.2.24.F8.16.3E.FF.FE.EE.9.B4.26.4.A8.80.8.0.0.A1.0.0.0.0.0.D9.60.1.11.2.2.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.83.2.0.7B.0.38.1D.D.E3.0.3.FA.0.1.0.0.0.1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.DE.57.F2.58.0.0.0.0
FF.FF.FF.FF.FF.FF.1.1.1.1.1.1.86.DD.60.8D.87.94.00.A6.FE.AE.87.8E.F1.F0.CD.AB.DC.C6.23.2E.B8.8C.15.C6.55.CE.4A.B2.D0.18.CB.F0.44.62.C1.25.73.0.D5.1A.42.CD.6C.3.31.12.5C.D4.24.B4.E2.36.27.59.79.71.BE.51.CC.99.4C.80.4E.80.3D.29.AB.D3.22.E5.A.E7.C5.6A.A6.B6.58.13.31.25.EE.25.73.0.94.7A.43.35.9C.CE.AF.FA.8C.2B.DD.44.D1.98.46.43.21.8C.80.5.E8.56.AE.5B.B2.75.C4.A9.25.73.0.C8.D5.86.AB.21.8A.F5.15.DD.F2.A2.DC.E4.4B.EE.75.6D.4E.C0.A.1D.FA.4B.D8.9A.4B.71.45.CC.6F.A3.3F.C2.19.9F.A3.ED.61.96.5F.8E.28.13.E6.FB.D2.EA.B3.4A.B3.ED.AA.67.4F.47.F0.3D.8.D0.9B.7C.68.2F.8D.28.25.73.0.6.5D.32.D.79.8.71.EA.E.1D.57.77.C5.95.2A.75.17.18.C8.AB.E8.6.FD.47.E.25.73.0.81.41.99.CE.C.B2.3F.18.5E.FD.9F.E5.CB.2E.2A.90.90.3D.B8.70.40.4F.67.6E.A5.93.A6.D5.0
FF.FF.FF.FF.FF.FF.1.1.1.1.1.1.86.DD.60.7F.20.FD.00.C6.32.28.58.4C.2E.AD.4D.BF.2A.8F.4.EF.E5.E9.B8.23.8B.33.E1.C5.2C.79.5A.B8.70.1E.D8.85.C.2D.EE.E9.57.EF.B5.A8.56.F2.E9.AA.17.63.7.1E.F8.10.52.9E.8B.F5.97.7F.6C.28.1.1D.98.1.9D.37.A4.66.82.D9.9A.37.D7.B.E.8F.8.25.73.0.F.F0.8E.CD.B2.CA.75.43.DA.E4.1A.42.38.C5.B5.5B.19.40.39.20.ED.3A.8.37.71.0.25.7D.53.49.17.E9.CA.2E.CC.F5.27.3.97.6C.8.FC.F5.64.81.AD.C3.4A.C5.3C.97.44.27.F7.D2.58.63.B5.8D.9A.CE.69.E3.9.3E.40.6D.91.2C.5B.A.4F.F3.86.C0.19.BD.CA.25.73.0.2E.1E.17.2C.54.E0.5E.1A.E2.2A.3D.99.23.46.5D.AE.50.81.D7.25.75.F6.70.E8.88.53.20.5D.16.22.28.80.5D.E0.48.4F.A3.2A.A.87.FB.F5.4.22.25.73.0.8D.6E.7E.D8.DF.2B.87.87.56.76.9B.F7.BD.7E.5C.3C.A3.84.EA.8E.79.A4.F7.20.E0.82.5C.94.1E.24
