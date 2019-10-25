package MongoHosting::Box::Linode;
use Moo;
use strictures 2;

extends 'MongoHosting::Box';

has _api_client => (is => 'ro', init_arg => 'api_client', required => 1);

sub type {'linode'}

sub private_iface {'eth0'}

sub remove {
  my $self = shift;
  $self->_api_client->linode_shutdown(linodeid => $self->id,);

  $self->_api_client->linode_disk_delete(
    linodeid => $self->id,
    diskid   => $_->{diskid}
  ) for @{$self->_api_client->linode_disk_list(linodeid => $self->id) || []};

  $self->_api_client->linode_delete(linodeid => $self->id, skipchecks => 1);
}

sub _build_private_ip {
  my $self = shift;
  my ($network)
    = grep { !$_->{ispublic} }
    @{$self->_api_client->linode_ip_list(linodeid => $self->id) || []};
  return $network->{ipaddress} if $network;
  die 'No private_ip provided';
}

sub _build_public_ip {
  my $self = shift;
  my ($network)
    = grep { $_->{ispublic} }
    @{$self->_api_client->linode_ip_list(linodeid => $self->id) || []};
  return $network->{ipaddress} if $network;
  die 'No public_ip provided';

}


1;
