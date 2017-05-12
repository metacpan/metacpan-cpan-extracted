use strict;
use POE;
use POE::Component::Server::NRPE;
use POE::Component::Server::NRPE::Constants qw(NRPE_STATE_OK);

my $port = 5666;

my $nrped = POE::Component::Server::NRPE->spawn(
	port => $port;
);

$nrped->add_command( command => 'meep', program => \&_meep );

$poe_kernel->run();
exit 0;

sub _meep {
	print STDOUT "OK meep\n";
	exit NRPE_STATE_OK;
}
