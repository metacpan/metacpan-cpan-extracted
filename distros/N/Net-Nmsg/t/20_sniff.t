use FindBin;
use lib $FindBin::Bin;
use nmsgtest;

use Test::More tests => 18;

use Net::Nmsg::Util qw( :sniff );

ok(  is_file     ($_), 'is file'     ) for (are_files());
ok(  is_nmsg_file($_), 'is nmsg file') for (nmsg_files());
ok(  is_pcap_file($_), 'is pcap file') for (pcap_files());

ok(! is_file     ($_), 'not file'     ) for (not_files());
ok(! is_nmsg_file($_), 'not nmsg file') for (not_nmsg_files());
ok(! is_pcap_file($_), 'not pcap file') for (not_pcap_files());
