package MongoHosting::ReplicaSet::Config;
use Moo;
use strictures 2;
use namespace::clean;
with 'MongoHosting::Role::Instance';
with 'MongoHosting::Role::WithSiblings';

use Rex::Commands::Run;
use Rex::Commands::File;
use Rex::Commands::Service;
use Rex::Commands::Pkg;
use Rex::Commands::Host;
use Rex::Resource::firewall;
use JSON qw(decode_json);

sub init {
  my $self = shift;

  return unless $self->is_primary;
  return if $self->checked;

  $self->_init;
}

sub _init {
  my $self = shift;

  Rex::Logger::info('Initializing replica set');

  file '/tmp/mongoc_init.js',
    content => template('@init', {c => $self, index => 1});

  run 'mongo',
    [sprintf('%s:%s/admin', $self->host, $self->port), '/tmp/mongoc_init.js'];
}

sub _install_package {
  pkg 'mongodb-org-server', ensure => 'present';
  pkg 'mongodb-org-shell',  ensure => 'present';
}

sub setup_firewall {
  my ($self, $app_host, @others) = @_;
  update_package_db;
  Rex::Logger::info('Ensuring ufw is present');
  pkg 'ufw', ensure => 'present';
  Rex::Logger::info('Deny as default');
  run 'ufw disable';
  run 'ufw default deny';
  Rex::Logger::info('Allowing ssh via public interface');
  run 'ufw allow ssh';

  # firewall 'allow ssh',
  #   provider => 'ufw',
  #   action   => 'allow',
  #   ensure   => "present",
  #   app      => 'OpenSSH',
  #   iniface  => 'eth0';

  Rex::Logger::info('Allowing private network access to ' . $_->host),
    firewall 'allow ' . $_->host,
    provider => 'ufw',
    action   => 'allow',
    ensure   => "present",
    iniface  => $self->private_iface,
    source   => $_->private_ip,
    port     => $self->port
    for @others;

  Rex::Logger::info('Allowing network access to app host');
  firewall 'allow ' . $app_host,
    provider => 'ufw',
    action   => 'allow',
    ensure   => "present",
    iniface  => 'eth0',
    source   => $app_host,
    port     => $self->port;


  Rex::Logger::info('Enabling ufw');
  run 'ufw --force enable';
}


sub check {
  my $self = shift;

  $self->_setup_repository;
  pkg 'mongodb-org-shell', ensure => 'present';
  my $out = run 'mongo',
    [
    sprintf('%s:%s/admin', $self->host, $self->port),
    '--quiet',
    '--eval',
    'var s = rs.status(); printjson([s.ok, s.set])'
    ];

  return if $?;
  my $json = eval { decode_json($out) } or return;
  my ($ok, $rs) = @$json;
  return 1 if $ok && defined $rs && $rs eq $self->parent->name;
  return;
}

sub start {
  service mongoc => 'restart';
  service mongoc => ensure => 'started';
}

sub _configure_mongodb {
  my $self = shift;
  file "/data/configdb",
    ensure => "directory",
    owner  => "mongodb",
    group  => "mongodb";


  file '/etc/mongoc.conf',
    content => template(
    '@config',
    args => {
      hostname    => $self->host,
      replSetName => $self->parent->name,
      bindIp      => $self->private_ip,
      port        => $self->port
    },
    ),
    chmod => 644;

  file '/etc/systemd/system/mongoc.service',
    content => template('@service'),
    chmod   => 644;
}

1;


__DATA__

@config
storage:
  dbPath: /data/configdb
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongoc.log

net:
  port: <%= $args->{port} %>
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

replication:
  replSetName: <%= $args->{replSetName} %>
sharding:
  clusterRole: configsvr
@end

@service
[Unit]
Description=MongoDB Config server
After=network.target

[Service]
User=mongodb
Type=forking
ExecStart=/usr/bin/mongod --fork --quiet --config /etc/mongoc.conf

[Install]
WantedBy=multi-user.target
  
@end
  
@init
rs.initiate(
  {
    _id: "<%= $c->parent->name %>",
    configsvr: true,
    members: [
    <% foreach my $host (@{$c->siblings}) { %>
      { _id : <%= ($index++) %>, host: "<%= $host->dsn %>" },
    <% } %>
    ]
  }
)

printjson(rs.status());
@end
