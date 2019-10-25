package PostgreSQLHosting::Provider::Linode;
use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use constant GB => 1024;

use Moo;
use strictures 2;
with 'PostgreSQLHosting::Role::Provider';

use WebService::Linode;
use PostgreSQLHosting::Provider::Linode::Box;
use Term::ANSIScreen qw(cls);
use Term::ANSIColor;
use Path::Tiny qw(path);
use LWP::UserAgent::Determined;

sub _build__api_client {
  my $client = WebService::Linode->new(apikey => shift->api_key);
  $client->{_ua} = LWP::UserAgent::Determined->new;
  return $client;
}

sub _build_boxes {
  my $self  = shift;
  my $conf  = $self->config;
  my @plans = @{$self->_api_client->avail_linodeplans || []};

  my (@hosts) = @{$conf->{hosts} || []};

  my %boxes = $self->_list_boxes();

  my @not_created = grep { not exists $boxes{$_->{name}} } @hosts;
  return \%boxes unless @not_created;

  my $ssh_public_key = path($self->ssh_public_key)->slurp;

  foreach my $host (@not_created) {
    warn $host->{name};
    $boxes{$host->{name}} = PostgreSQLHosting::Provider::Linode::Box->new(
      name   => $host->{name},
      type   => $host->{type},
      size   => int($host->{size} || 3),
      region => int($self->config->{region} || 10),    #frankfurt as default
      ssh_public_key => $ssh_public_key,
      root_pass      => $self->config->{root_pass},
      api_client     => $self->_api_client,
      plans          => [@plans],
    );
  }
  return \%boxes;
}

sub _list_boxes {
  my $self = shift;
  my %type_map = map { $_->{name} => $_->{type} } @{$self->config->{hosts}};

  map {
    $_->{label} => PostgreSQLHosting::Provider::Linode::Box->new(
      id         => $_->{linodeid},
      name       => $_->{label},
      type       => $type_map{$_->{label}},
      api_client => $self->_api_client
      )
  } grep { index($_->{label}, $self->config->{prefix}) == 0 }
    @{$self->_api_client->linode_list() || []};
}

sub existing_boxes {
  my %boxes = shift->_list_boxes;
  return values %boxes;
}

1;
