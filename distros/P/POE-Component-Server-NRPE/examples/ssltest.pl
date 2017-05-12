use strict;
use POE qw(Component::Server::NRPE);

my $nrped = POE::Component::Server::NRPE->spawn(
	address => '127.0.0.1',
	version => 2,
	usessl => 1,
        verstring => 'NRPE v2.8.1',
        options => { trace => 1 },
);

$poe_kernel->run();
exit 0;
