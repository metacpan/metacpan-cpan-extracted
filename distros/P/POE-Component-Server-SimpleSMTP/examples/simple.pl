use strict;
use warnings;
use POE qw(Component::Server::SimpleSMTP);
use Getopt::Long;

my ($port,$name,$relay);

GetOptions( 
		'port' => \$port, 
		'name' => \$name,
		'relay' => \$relay,
);

POE::Component::Server::SimpleSMTP->spawn(
	hostname => $name,
	port     => $port,
	relay    => $relay,
);

$poe_kernel->run();
exit 0;
