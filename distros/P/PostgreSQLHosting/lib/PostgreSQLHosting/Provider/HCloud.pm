package PostgreSQLHosting::Provider::HCloud;
use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use constant GB => 1024;

use Moo;
use strictures 2;
with 'PostgreSQLHosting::Role::Provider';

use PostgreSQLHosting::Provider::HCloud::API;
use PostgreSQLHosting::Provider::HCloud::Box;
use Path::Tiny qw(path);
use Term::ANSIScreen qw(cls);
use Term::ANSIColor;
sub provider {'hcloud'}

sub _build__api_client {
  PostgreSQLHosting::Provider::HCloud::API->new(api_key => shift->api_key);
}


sub _build_boxes {
  my $self  = shift;
  my $conf  = $self->config;
  my @plans = @{$self->_api_client->get_server_types || []};

  my (@hosts) = @{$conf->{hosts} || []};

  my %boxes = $self->_list_boxes();

  my @not_created = grep { not exists $boxes{$_->{name}} } @hosts;
  return \%boxes unless @not_created;

  my $ssh_public_key      = path($self->ssh_public_key)->slurp;
  my $ssh_public_key_name = $self->config->{prefix} . '-proxy-ssh-key';

  my ($ssh_key)
    = @{$self->_api_client->get_ssh_keys({name => $ssh_public_key_name}) || []};
  if (!$ssh_key) {
    $self->_api_client->add_ssh_key($ssh_public_key_name, $ssh_public_key);
  }
  foreach my $host (@not_created) {
    $boxes{$host->{name}} = PostgreSQLHosting::Provider::HCloud::Box->new(
      name   => $host->{name},
      type   => $host->{type},
      size   => int($host->{size} || 1),              # CX11, 2GG, 1 CPU core
      region => int($self->config->{region} || 2),    #Nuremberg 1 DC 3
      ssh_public_key => $ssh_public_key_name,
      api_client     => $self->_api_client,
      root_pass      => $self->config->{root_pass},
      plans          => [@plans],
    );
  }
  return \%boxes;
}

sub _list_boxes {
  my $self = shift;
  my %type_map = map { $_->{name} => $_->{type} } @{$self->config->{hosts}};

  map {
    (
      $_->{name} => PostgreSQLHosting::Provider::HCloud::Box->new(
        id         => $_->{id},
        name       => $_->{name},
        type       => $type_map{$_->{name}},
        api_client => $self->_api_client,
      )
      )
  } grep { index($_->{name}, $self->config->{prefix}) == 0 }
    @{$self->_api_client->get_servers || []};
}

sub existing_boxes {
  my %boxes = shift->_list_boxes;
  return values %boxes;
}

1;
