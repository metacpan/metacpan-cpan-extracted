package PostgreSQLHosting::Provider::DigitalOcean;

use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use Moo;
use strictures 2;

with 'PostgreSQLHosting::Role::Provider';

use DigitalOcean;
use MIME::Base64 qw(decode_base64);
use Digest::MD5 qw(md5_hex);
use Path::Tiny qw(path);
use Term::ANSIScreen qw(cls);
use Term::ANSIColor;

use PostgreSQLHosting::Provider::DigitalOcean::Box;

sub _build__api_client {
  my $self = shift;
  return DigitalOcean->new(
    oauth_token           => $self->api_key,
    time_between_requests => 5
  );
}

sub _build_boxes {
  my $self = shift;
  my $conf = $self->config;
  my (@hosts) = @{$conf->{hosts} || []};
  my %hosts = map { $_->{name} => $_ } @hosts;

  my %droplets = $self->_find_droplets();

  my @not_created = grep { not exists $droplets{$_->{name}} } @hosts;

  return \%droplets unless @not_created;

  my $fingerprint = join(
    q{:},
    md5_hex(
      decode_base64([split(/ /, path($self->ssh_public_key)->slurp)]->[1])
    ) =~ m/../g
  );
  my $ssh_key = $self->_api_client->ssh_key($fingerprint);

  foreach my $host (@not_created) {
    print sprintf("Creating %s %s ",
      $host->{name}, ('.' x (30 - length($host->{name}))));

    my $droplet = $self->_api_client->create_droplet(
      name               => $host->{name},
      type               => $host->{type},
      size               => $host->{size},
      region             => $conf->{region},
      image              => 'ubuntu-16-04-x64',
      ssh_keys           => [$ssh_key->id],
      private_networking => 1,
      wait_on_event      => 1,
      monitoring         => 1,
      (
        (tags => [$host->{tag} || $conf->{tag}])
        x !!($conf->{tag} || $host->{tag})
      ),
    );
    print colored(['bright_green'], "✔\n");

    $droplets{$droplet->name}
      = PostgreSQLHosting::Provider::DigitalOcean::Box->new(machine => $droplet);
  }
  print color('reset');
  print "\n";

  Rex::Logger::info('Waiting 3min for the droplets to settle');
  sleep(180);

  return +{$self->_find_droplets};
}

sub _find_droplets {
  my $self                = shift;
  my @hosts               = @{$self->config->{hosts} || []};
  my %hosts               = map { $_->{name} => $_ } @hosts;
  my $droplets_collection = $self->_api_client->droplets;
  my $obj;
  my %droplets;

  while ($obj = $droplets_collection->next) {
    next unless exists $hosts{$obj->name};
    $droplets{$obj->name} = PostgreSQLHosting::Provider::DigitalOcean::Box->new(
      machine => $obj,
      type    => $hosts{$obj->name}->{type}
    );
  }
  return %droplets;
}

sub existing_boxes {
  my %boxes = shift->_find_droplets;
  return values %boxes;
}

1;

