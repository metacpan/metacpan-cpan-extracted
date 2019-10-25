package MongoHosting::Provider::Linode;
use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use constant GB => 1024;

use Moo;
use strictures 2;
with 'MongoHosting::Role::Provider';

use WebService::Linode;
use MongoHosting::Box::Linode;
use Term::ANSIScreen qw(cls);
use Term::ANSIColor;
use Path::Tiny qw(path);

sub _build__api_client {
  return WebService::Linode->new(apikey => shift->api_key);
}


sub _build_boxes {
  my $self  = shift;
  my $conf  = $self->config;
  my @plans = @{$self->_api_client->avail_linodeplans || []};

  my (@hosts) = @{$conf->{hosts} || []};

  my %boxes = $self->_list_boxes();

  my @not_created = grep { not exists $boxes{$_->{name}} } @hosts;
  return \%boxes unless @not_created;

  my $distribution_id = 146;    #Ubuntu 16.04 LTS
  my $kernel_id       = 138;    # Latest 64 bit (4.15.8-x86_64-linode103)
  my $ssh_public_key = path($self->ssh_public_key)->slurp;

#  use DDP;p(\@plans);exit;

  foreach my $host (@not_created) {
    print sprintf("Creating %s %s ",
      $host->{name}, ('.' x (30 - length($host->{name}))));

    # Rex::Logger::info('Creating box');

    my $box = $self->_api_client->linode_create(
      planid       => int($host->{size}),
      datacenterid => int($self->config->{region})
    );

    $self->_api_client->linode_update(
      linodeid => $box->{linodeid},
      label    => $host->{name},
    );


    my ($plan) = grep { $_->{planid} == int($host->{size}) } @plans;
    my $swap_size = 1;                            # 1 GB
    my $root_size = $plan->{disk} - $swap_size;

    #  Rex::Logger::info('Adding root disk to '. $box->{linodeid});

    my $root = $self->_api_client->linode_disk_createfromdistribution(
      linodeid       => $box->{linodeid},
      rootpass       => $self->config->{root_pass},
      distributionid => $distribution_id,
      rootsshkey     => $ssh_public_key,
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
      label    => $host->{name},
      disklist => sprintf("%s,%s,,,,,,,", $root->{diskid}, $swap->{diskid}),
      kernelid => $kernel_id
    );
    my $private_ip
      = $self->_api_client->linode_ip_addprivate(linodeid => $box->{linodeid});

    $self->_api_client->linode_boot(
      linodeid => $box->{linodeid},
      configid => $linode_config->{configid}
    );

    # my $public_ip
    #   = $self->_api_client->linode_ip_addpublic(linodeid => $box->{linodeid});
    $boxes{$host->{name}} = MongoHosting::Box::Linode->new(
      id         => $box->{linodeid},
      name       => $host->{name},
      api_client => $self->_api_client
    );
    print colored(['bright_green'], "✔\n");


  }
  print color('reset');

  Rex::Logger::info('Waiting 3min for the boxes to settle');
  sleep(180);

  return \%boxes;
}

sub _list_boxes {
  my $self  = shift;
  my %list  = map { $_->{label} => $_ } @{$self->_api_client->linode_list() || []};
  my @hosts = @{$self->config->{hosts} || []};
  my %hosts = map { $_->{name} => $_ } @hosts;

  map {
    $_ => MongoHosting::Box::Linode->new(
      id         => $list{$_}->{linodeid},
      name       => $_,
      api_client => $self->_api_client
      )
  } grep { $list{$_} } keys %hosts;

}

sub existing_boxes {
  my %boxes = shift->_list_boxes;
  return values %boxes;
}

1;
