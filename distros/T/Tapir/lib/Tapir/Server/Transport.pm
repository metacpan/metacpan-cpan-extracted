package Tapir::Server::Transport;

use Moose;

has 'server' => (is => 'ro', isa => 'Tapir::Server');
has 'logger' => (is => 'ro');

1;
