use strict;
use warnings;
use Net::PcapWriter;
use Test;
BEGIN { plan tests => 4 }

my $pcap = '';
open( my $fh,'>',\$pcap );
my $w = Net::PcapWriter->new($fh);

my $conn = $w->icmp_echo_conn('1.2.3.4','5.6.7.8',0x3456) or die;
$conn->ping(1,'foo');
$conn->ping(2,'bar');
$conn->pong(2,'bar'); # packet foo lost
undef $conn;

# output of tcpdump can be different on each platform, and maybe
# no tcpdump is installed. So just check some stuff in file

ok( length($pcap) == 207 );
ok( substr($pcap,0x52,3) eq "foo" );
ok( substr($pcap,0x8f,3) eq "bar" );
ok( substr($pcap,0xcc,3) eq "bar" );
