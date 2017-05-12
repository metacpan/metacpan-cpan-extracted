use strict;
use warnings;

use POE;
use POE::Component::Server::TCP;
use POE::Filter::Stackable;
use POE::Filter::Line;
use POE::Filter::KennySpeak;

POE::Component::Server::TCP->new(
    Port => 12345,
    ClientInputFilter => POE::Filter::Stackable->new(
	Filters => [
		POE::Filter::Line->new(),
		POE::Filter::KennySpeak->new(),
	],
    ),
    ClientOutputFilter => POE::Filter::Line->new(),
    ClientInput => sub {
      $_[HEAP]{client}->put($_[ARG0]);
      return;
    },
);

POE::Kernel->run();
exit;
