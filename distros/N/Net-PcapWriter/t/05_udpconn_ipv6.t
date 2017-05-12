use strict;
use warnings;
use Net::PcapWriter;
use Test;
BEGIN { plan tests => 3 }

my $pcap = '';
open( my $fh,'>',\$pcap );
my $w = Net::PcapWriter->new($fh);

my $conn = $w->udp_conn('2000::1:2:3:4',2000,'2000::5:6:7:8',7543) or die;
$conn->write(0,"foo");
$conn->write(1,"bar");
undef $conn;

# output of tcpdump can be different on each platform, and maybe
# no tcpdump is installed. So just check some stuff in file

ok( length($pcap) == 186 );
ok( substr($pcap,0x66,3) eq "foo" );
ok( substr($pcap,0xb7,3) eq "bar" );
