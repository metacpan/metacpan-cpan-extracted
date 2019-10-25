package PostgreSQLHosting::Provider::HCloud::Box;

use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use Moo;
use strictures 2;
extends 'PostgreSQLHosting::Box';

use Term::ANSIScreen qw(cls);
use Term::ANSIColor;
use constant GB => 1024;


#has _api_client => (is => 'ro', init_arg => 'api_client', required => 1);

has _plans => (is => 'ro', init_arg => 'plans');

sub type {'hcloud'}

sub private_iface {'eth0'}

sub remove {
  my $self = shift;
  $self->_api_client->del_server($self->id);
}

sub _build_private_ip {
  return;
}

sub _build_public_ip {
  my $self   = shift;
  my $server = $self->_api_client->get_server($self->id);
  my $ip = $server->{public_net}->{ipv4}->{ip} or die 'No public_ip provided';
  return $ip;
}

sub _build_id {
  my $self = shift;

  return $self->_id if $self->_id;    # use id provided in ->new


  print sprintf("Creating %s %s ",
    $self->_name, ('.' x (30 - length($self->_name))));
  my $image_id = 1;                   #Ubuntu 16.04 LTS

  my $box
    = $self->_api_client->add_server($self->_name, $self->_size, $image_id,
    {datacenter => $self->_region, ssh_keys => [$self->_ssh_public_key]});

  print colored(['bright_green'], "✔\n");
  print color('reset');
  return $box->{id};
}

sub _build_name { shift->_name }

1;
