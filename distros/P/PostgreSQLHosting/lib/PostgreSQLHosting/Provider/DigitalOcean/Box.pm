package PostgreSQLHosting::Provider::DigitalOcean::Box;
use Moo;
use strictures 2;

extends 'PostgreSQLHosting::Box';

has _machine => (is => 'ro', init_arg => 'machine');

sub provider          {'digital_ocean'}
sub private_iface {'eth1'}

sub _build_name {
  shift->_machine->name;
}

sub _build_id {
  shift->_machine->id;
}

sub _build_private_ip {
  my ($network)
    = grep { $_->type eq 'private' } @{shift->_machine->networks->v4};
  return $network->ip_address if $network;
  die 'No private_ip provided';
}

sub _build_public_ip {
  my ($network)
    = grep { $_->type eq 'public' } @{shift->_machine->networks->v4};
  return $network->ip_address if $network;
  die 'No public_ip provided';

}

sub _build__machine { }
sub remove          { shift->_machine->delete }

1;
