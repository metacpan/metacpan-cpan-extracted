use strict;
use warnings;
use Net::PcapWriter;
use Test;
BEGIN { plan tests => 5 }

my $pcap = '';
open( my $fh,'>',\$pcap );
my $w = Net::PcapWriter->new($fh);

my $conn = $w->tcp_conn('2000::1:2:3:4',2000,'2000::5:6:7:8',80) or die;
$conn->write(0,"GET / HTTP/1.0\r\n\r\n");
$conn->write(1,"HTTP/1.0 200 ok\r\nContent-length: 0\r\n\r\n");
undef $conn;

# output of tcpdump can be different on each platform, and maybe
# no tcpdump is installed. So just check some stuff in file

ok( length($pcap) == 800 );
ok( substr($pcap,0x180,18) eq "GET / HTTP/1.0\r\n\r\n" );
ok( substr($pcap,0x154,8) eq "\x00\x01\x00\x02\x00\x03\x00\x04");
ok( substr($pcap,0x164,8) eq "\x00\x05\x00\x06\x00\x07\x00\x08");
ok( substr($pcap,0x14,1) eq "\001");
