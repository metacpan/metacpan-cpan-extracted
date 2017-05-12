use lib './blib';
use lib './blib/arch/';
use lib './blib/lib/';
use Net::MDNS::Client ':all';

my $service = shift;
my $q = make_query("host by service", "", "local.", $service, "tcp");
print "Query for hostname is: ".$q."\n";
my $r = make_query("data by hostname", "luciole", "local.", $service, "tcp");
print "Query for data is: ".$r."\n";
my $s = make_query("ip by hostname", "luciole", "local.", $service, "tcp");
print "Query for ip is: ".$s."\n";
query( "host by service", $q);
query( "data by hostname", $r);
query( "ip by hostname", $r);
my $t = "luciole.local.";
query( "ip by hostname", $t);

while (1)
	{
		if (process_network_events())
			{
				while (1) {
				print "Found host: ",join(", ", get_a_result("host by service", $q)), "\n";
				print "Found data: ",join(", ", get_a_result("data by hostname", $r)), "\n";
				print "Found ip: ",join(", ", get_a_result("ip by hostname", $s)), "\n";
				print "Found ip: ",join(", ", get_a_result("ip by hostname", $t)), "\n";
				#print "Found host: ",scalar(get_a_result("host by service", $q)), "\n";
				sleep 1;
				}
			}
	}
				
