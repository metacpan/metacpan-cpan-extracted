package PostgreSQLHosting::Provider::Linode::Box;

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

sub provider {'linode'}

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

sub _build_id {
  my $self = shift;

  return $self->_id if $self->_id;    # use id provided in ->new

  my $distribution_id = 146;          #Ubuntu 16.04 LTS
  my $kernel_id       = 138;          # Latest 64 bit (4.15.8-x86_64-linode103)
  my @plans = @{$self->_plans || []};

  print sprintf("Creating %s %s ",
    $self->_name, ('.' x (30 - length($self->_name))));


  my $box = $self->_api_client->linode_create(
    planid       => $self->_size,
    datacenterid => $self->_region,
  );

  $self->_api_client->linode_update(
    linodeid => $box->{linodeid},
    label    => $self->_name
  );


  my ($plan) = grep { $_->{planid} == $self->_size } @plans;
  my $swap_size = 1;                            # 1 GB
  my $root_size = $plan->{disk} - $swap_size;

  #  Rex::Logger::info('Adding root disk to '. $box->{linodeid});

  my $root = $self->_api_client->linode_disk_createfromdistribution(
    linodeid       => $box->{linodeid},
    rootpass       => $self->_root_pass,
    distributionid => $distribution_id,
    rootsshkey     => $self->_ssh_public_key,
    label          => 'root',
    size           => $root_size * GB
  );

  #   Rex::Logger::info('Adding swap disk to '. $box->{linodeid});
  my $swap = $self->_api_client->linode_disk_create(
    linodeid => $box->{linodeid},
    label    => 'swap',
    size     => $swap_size * GB,
    type     => 'swap'
  );


#    Rex::Logger::info('Finishing config for '. $box->{linodeid});
  my $linode_config = $self->_api_client->linode_config_create(
    linodeid => $box->{linodeid},
    label    => $self->_name,
    disklist => sprintf("%s,%s,,,,,,,", $root->{diskid}, $swap->{diskid}),
    kernelid => $kernel_id
  );
  my $private_ip
    = $self->_api_client->linode_ip_addprivate(linodeid => $box->{linodeid});

  $self->_api_client->linode_boot(
    linodeid => $box->{linodeid},
    configid => $linode_config->{configid}
  );
  sleep(120);
  print colored(['bright_green'], "✔\n");
  print color('reset');
  return $box->{linodeid};
}

sub _build_name { shift->_name }

1;
