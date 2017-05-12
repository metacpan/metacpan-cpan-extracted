use Test;
BEGIN { plan(tests => 9) }

use strict;
use warnings;

my $NO_HAVE_NetFrameSimple = 0;
eval "use Net::Frame::Simple 1.05";
if($@) {
    $NO_HAVE_NetFrameSimple = "Net::Frame::Simple 1.05 required";
}

use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::IPv4 qw(:consts);
use Net::Frame::Layer::UDP qw(:consts);
use Net::Frame::Layer::DNS qw(:consts);
use Net::Frame::Layer::DNS::Question qw(:consts);
use Net::Frame::Layer::DNS::RR qw(:consts);

my ($packet, $decode, $expectedOutput);

# A
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad400800454000b0000040003a11e8b3445747e6c0a80a640035fd92009c0965c4e1818000010007000000000377777706676f6f676c6503636f6d0000010001c00c000500010001e338000803777777016cc010c02c000100010000009e00044a7d7163c02c000100010000009e00044a7d7169c02c000100010000009e00044a7d7168c02c000100010000009e00044a7d7193c02c000100010000009e00044a7d716ac02c000100010000009e00044a7d7167";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:176  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe8b3
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:64914  length:156  checksum:0x965
DNS: id:50401  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:7
DNS: nsCount:0  arCount:0
DNS::Question: name:www.google.com
DNS::Question: type:1  class:1
DNS::RR: name:[@12(www.google.com)]
DNS::RR: type:5  class:1  ttl:123704  rdlength:8
DNS::RR::CNAME: cname:www.l.[@16(google.com)]
DNS::RR: name:[@44(www.l.[@16(google.com)])]
DNS::RR: type:1  class:1  ttl:158  rdlength:4
DNS::RR::A: address:74.125.113.99
DNS::RR: name:[@44(www.l.[@16(google.com)])]
DNS::RR: type:1  class:1  ttl:158  rdlength:4
DNS::RR::A: address:74.125.113.105
DNS::RR: name:[@44(www.l.[@16(google.com)])]
DNS::RR: type:1  class:1  ttl:158  rdlength:4
DNS::RR::A: address:74.125.113.104
DNS::RR: name:[@44(www.l.[@16(google.com)])]
DNS::RR: type:1  class:1  ttl:158  rdlength:4
DNS::RR::A: address:74.125.113.147
DNS::RR: name:[@44(www.l.[@16(google.com)])]
DNS::RR: type:1  class:1  ttl:158  rdlength:4
DNS::RR::A: address:74.125.113.106
DNS::RR: name:[@44(www.l.[@16(google.com)])]
DNS::RR: type:1  class:1  ttl:158  rdlength:4
DNS::RR::A: address:74.125.113.103';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# AAAA
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad4008004540006e000040003a11e8f5445747e6c0a80a640035d89e005a6f626fcf81800001000200000000046970763606676f6f676c6503636f6d00001c0001c00c0005000100093a8000090469707636016cc011c02d001c00010000012c001020014860800600000000000000000063";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:110  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe8f5
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:55454  length:90  checksum:0x6f62
DNS: id:28623  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:2
DNS: nsCount:0  arCount:0
DNS::Question: name:ipv6.google.com
DNS::Question: type:28  class:1
DNS::RR: name:[@12(ipv6.google.com)]
DNS::RR: type:5  class:1  ttl:604800  rdlength:9
DNS::RR::CNAME: cname:ipv6.l.[@17(google.com)]
DNS::RR: name:[@45(ipv6.l.[@17(google.com)])]
DNS::RR: type:28  class:1  ttl:300  rdlength:16
DNS::RR::AAAA: address:2001:4860:8006::63';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# HINFO
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad4008004540005a000040003a11e909445747e6c0a80a640035e6a90046bc6a11ed81800001000100000000037a7a7a0564616d74700363616d02616302756b00000d0001c00c000d00010002a300000d025043094c696e75782f783836";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:90  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe909
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:59049  length:70  checksum:0xbc6a
DNS: id:4589  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:1
DNS: nsCount:0  arCount:0
DNS::Question: name:zzz.damtp.cam.ac.uk
DNS::Question: type:13  class:1
DNS::RR: name:[@12(zzz.damtp.cam.ac.uk)]
DNS::RR: type:13  class:1  ttl:172800  rdlength:13
DNS::RR::HINFO: cpu:PC  os:Linux/x86';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# MX
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad400800454000d2000040003a11e891445747e6c0a80a640035dcde00be8afce7c68180000100050000000205676d61696c03636f6d00000f0001c00c000f000100000d7a0020001404616c74320d676d61696c2d736d74702d696e016c06676f6f676c65c012c00c000f000100000d7a00040005c02ec00c000f000100000d7a0009001e04616c7433c02ec00c000f000100000d7a0009000a04616c7431c02ec00c000f000100000d7a0009002804616c7434c02ec02e00010001000000cc00044a7d731bc08f000100010000005400044a7d7f1b";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:210  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe891
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:56542  length:190  checksum:0x8afc
DNS: id:59334  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:5
DNS: nsCount:0  arCount:2
DNS::Question: name:gmail.com
DNS::Question: type:15  class:1
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:15  class:1  ttl:3450  rdlength:32
DNS::RR::MX: preference:20
DNS::RR::MX: exchange:alt2.gmail-smtp-in.l.google.[@18(com)]
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:15  class:1  ttl:3450  rdlength:4
DNS::RR::MX: preference:5
DNS::RR::MX: exchange:[@46(gmail-smtp-in.l.google.[@18(com)])]
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:15  class:1  ttl:3450  rdlength:9
DNS::RR::MX: preference:30
DNS::RR::MX: exchange:alt3.[@46(gmail-smtp-in.l.google.[@18(com)])]
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:15  class:1  ttl:3450  rdlength:9
DNS::RR::MX: preference:10
DNS::RR::MX: exchange:alt1.[@46(gmail-smtp-in.l.google.[@18(com)])]
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:15  class:1  ttl:3450  rdlength:9
DNS::RR::MX: preference:40
DNS::RR::MX: exchange:alt4.[@46(gmail-smtp-in.l.google.[@18(com)])]
DNS::RR: name:[@46(gmail-smtp-in.l.google.[@18(com)])]
DNS::RR: type:1  class:1  ttl:204  rdlength:4
DNS::RR::A: address:74.125.115.27
DNS::RR: name:[@143(alt4.[@46(gmail-smtp-in.l.google.[@18(com)])])]
DNS::RR: type:1  class:1  ttl:84  rdlength:4
DNS::RR::A: address:74.125.127.27';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# NS
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad400800454000c6000040003a11e89d445747e6c0a80a640035c82b00b26e2d5eba8180000100040000000405676d61696c03636f6d0000020001c00c00020001000544fe000d036e733106676f6f676c65c012c00c00020001000544fe0006036e7332c02bc00c00020001000544fe0006036e7334c02bc00c00020001000544fe0006036e7333c02bc040000100010000f5470004d8ef220ac052000100010000f6e50004d8ef260ac064000100010000f5bf0004d8ef240ac027000100010000f4d70004d8ef200a";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:198  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe89d
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:51243  length:178  checksum:0x6e2d
DNS: id:24250  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:4
DNS: nsCount:0  arCount:4
DNS::Question: name:gmail.com
DNS::Question: type:2  class:1
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:2  class:1  ttl:345342  rdlength:13
DNS::RR::NS: nsdname:ns1.google.[@18(com)]
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:2  class:1  ttl:345342  rdlength:6
DNS::RR::NS: nsdname:ns2.[@43(google.[@18(com)])]
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:2  class:1  ttl:345342  rdlength:6
DNS::RR::NS: nsdname:ns4.[@43(google.[@18(com)])]
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:2  class:1  ttl:345342  rdlength:6
DNS::RR::NS: nsdname:ns3.[@43(google.[@18(com)])]
DNS::RR: name:[@64(ns2.[@43(google.[@18(com)])])]
DNS::RR: type:1  class:1  ttl:62791  rdlength:4
DNS::RR::A: address:216.239.34.10
DNS::RR: name:[@82(ns4.[@43(google.[@18(com)])])]
DNS::RR: type:1  class:1  ttl:63205  rdlength:4
DNS::RR::A: address:216.239.38.10
DNS::RR: name:[@100(ns3.[@43(google.[@18(com)])])]
DNS::RR: type:1  class:1  ttl:62911  rdlength:4
DNS::RR::A: address:216.239.36.10
DNS::RR: name:[@39(ns1.google.[@18(com)])]
DNS::RR: type:1  class:1  ttl:62679  rdlength:4
DNS::RR::A: address:216.239.32.10';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# PTR
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad40080045400064000040003a11e8ff445747e6c0a80a640035c35a00506431803881800001000100000000023130023334033233390332313607696e2d61646472046172706100000c0001c00c000c0001000151800010036e733206676f6f676c6503636f6d00";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:100  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe8ff
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:50010  length:80  checksum:0x6431
DNS: id:32824  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:1
DNS: nsCount:0  arCount:0
DNS::Question: name:10.34.239.216.in-addr.arpa
DNS::Question: type:12  class:1
DNS::RR: name:[@12(10.34.239.216.in-addr.arpa)]
DNS::RR: type:12  class:1  ttl:86400  rdlength:16
DNS::RR::PTR: ptrdname:ns2.google.com';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# SOA
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad40080045400084000040003a11e8df445747e6c0a80a640035f5e800701676db4a81800001000100010000046970763606676f6f676c6503636f6d0000010001c00c0005000100093a5e00090469707636016cc011c032000600010000003c0026036e7333c01109646e732d61646d696ec01100167e750000038400000384000007080000003c";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:132  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe8df
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:62952  length:112  checksum:0x1676
DNS: id:56138  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:1
DNS: nsCount:1  arCount:0
DNS::Question: name:ipv6.google.com
DNS::Question: type:1  class:1
DNS::RR: name:[@12(ipv6.google.com)]
DNS::RR: type:5  class:1  ttl:604766  rdlength:9
DNS::RR::CNAME: cname:ipv6.l.[@17(google.com)]
DNS::RR: name:[@50(l.[@17(google.com)])]
DNS::RR: type:6  class:1  ttl:60  rdlength:38
DNS::RR::SOA: mname:ns3.[@17(google.com)]  rname:dns-admin.[@17(google.com)]
DNS::RR::SOA: serial:1474165  refresh:900  retry:900
DNS::RR::SOA: expire:1800  minimum:60';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# SRV
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad40080045400139000040003a11e82a445747e6c0a80a640035f0a5012577d7e445818000010005000000000c5f786d70702d736572766572045f74637005676d61696c03636f6d0000210001c00c0021000100000384002500140000149504616c74330b786d70702d736572766572016c06676f6f676c6503636f6d00c00c0021000100000384002500140000149504616c74310b786d70702d736572766572016c06676f6f676c6503636f6d00c00c0021000100000384002500140000149504616c74340b786d70702d736572766572016c06676f6f676c6503636f6d00c00c0021000100000384002500140000149504616c74320b786d70702d736572766572016c06676f6f676c6503636f6d00c00c002100010000038400200005000014950b786d70702d736572766572016c06676f6f676c6503636f6d00";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:313  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe82a
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:61605  length:293  checksum:0x77d7
DNS: id:58437  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:5
DNS: nsCount:0  arCount:0
DNS::Question: name:_xmpp-server._tcp.gmail.com
DNS::Question: type:33  class:1
DNS::RR: name:[@12(_xmpp-server._tcp.gmail.com)]
DNS::RR: type:33  class:1  ttl:900  rdlength:37
DNS::RR::SRV: priority:20  weight:0  port:5269
DNS::RR::SRV: target:alt3.xmpp-server.l.google.com
DNS::RR: name:[@12(_xmpp-server._tcp.gmail.com)]
DNS::RR: type:33  class:1  ttl:900  rdlength:37
DNS::RR::SRV: priority:20  weight:0  port:5269
DNS::RR::SRV: target:alt1.xmpp-server.l.google.com
DNS::RR: name:[@12(_xmpp-server._tcp.gmail.com)]
DNS::RR: type:33  class:1  ttl:900  rdlength:37
DNS::RR::SRV: priority:20  weight:0  port:5269
DNS::RR::SRV: target:alt4.xmpp-server.l.google.com
DNS::RR: name:[@12(_xmpp-server._tcp.gmail.com)]
DNS::RR: type:33  class:1  ttl:900  rdlength:37
DNS::RR::SRV: priority:20  weight:0  port:5269
DNS::RR::SRV: target:alt2.xmpp-server.l.google.com
DNS::RR: name:[@12(_xmpp-server._tcp.gmail.com)]
DNS::RR: type:33  class:1  ttl:900  rdlength:32
DNS::RR::SRV: priority:5  weight:0  port:5269
DNS::RR::SRV: target:xmpp-server.l.google.com';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});

# TXT
skip ($NO_HAVE_NetFrameSimple,
sub {
$packet = pack "H*", "c417fe127d75586d8f78ad40080045400063000040003a11e900445747e6c0a80a640035e79b004f0f0342468180000100010000000005676d61696c03636f6d0000100001c00c001000010000012c00201f763d737066312072656469726563743d5f7370662e676f6f676c652e636f6d";

$decode = Net::Frame::Simple->new(
    raw => $packet,
    firstLayer => 'ETH'
);

$expectedOutput = 'ETH: dst:c4:17:fe:12:7d:75  src:58:6d:8f:78:ad:40  type:0x0800
IPv4: version:4  hlen:5  tos:0x40  length:99  id:0
IPv4: flags:0x02  offset:0  ttl:58  protocol:0x11  checksum:0xe900
IPv4: src:68.87.71.230  dst:192.168.10.100
UDP: src:53  dst:59291  length:79  checksum:0xf03
DNS: id:16966  qr:1  opcode:0  flags:0x18  rcode:0
DNS: qdCount:1  anCount:1
DNS: nsCount:0  arCount:0
DNS::Question: name:gmail.com
DNS::Question: type:16  class:1
DNS::RR: name:[@12(gmail.com)]
DNS::RR: type:16  class:1  ttl:300  rdlength:32
DNS::RR::TXT: txtdata:v=spf1 redirect=_spf.google.com';

print $decode->print;
print "\n";

$decode->print eq $expectedOutput;
});
