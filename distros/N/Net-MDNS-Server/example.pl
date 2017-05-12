use lib './blib';
use lib './blib/arch/';
use lib './blib/lib/';
use Net::MDNS::Server ':all';
print "Loaded module\nFinding IP address\n";
my $ifc = join "", `ifconfig`;
$ifc =~ m/addr:(\d+\.\d+\.\d+\.\d+)/s;
my $addr = $1;
service("myhost", $addr, 444, "perl", "tcp");
print "Loaded service\n";
while (1) {process_network_events}
