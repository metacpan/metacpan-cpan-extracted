package TestServer;

use warnings;
use strict;

use POE;
use POE::Component::Server::TCP;
use Socket qw(sockaddr_in);

my %clients;
my %servers;
my $seq = 0;

sub spawn {
  my ($class, $port) = @_;

  my $alias = 'TestServer_' . ++$seq;

  POE::Component::Server::TCP->new(
    Alias              => $alias,
    Port               => $port,   # Random one if 0.
    Address            => "127.0.0.1",
    ClientInput        => \&discard_client_input,
    ClientConnected    => \&register_client,
    ClientDisconnected => \&unregister_client,
    Started            => sub {
      # Switch $port to the port this server actually bound on.
      my $listener_sockname = $_[HEAP]{listener}->getsockname();
      if (defined $listener_sockname) {
        ($port, undef) = sockaddr_in($listener_sockname);
      }
      else {
        $port = undef;
      }
    },
    InlineStates       => {
      send_something   => \&internal_send_something,
    },
  );

  $servers{$port} = $alias;

  return $port;
}

sub register_client {
  $clients{$_[SESSION]->ID} = 1;
}

sub unregister_client {
  delete $clients{$_[SESSION]->ID};
}

sub discard_client_input {
  # Do nothing.
}

sub send_something {
  foreach my $client (keys %clients) {
    $poe_kernel->call($client, "send_something");
  }
}

sub internal_send_something {
  $_[HEAP]->{client}->put(scalar localtime);
}

sub shutdown {
  foreach my $alias (values(%servers), keys(%clients)) {
    $poe_kernel->post($alias => "shutdown");
  }
}

sub shutdown_clients {
  foreach my $session (keys(%clients)) {
    $poe_kernel->call($session => "shutdown");
  }
}

1;
