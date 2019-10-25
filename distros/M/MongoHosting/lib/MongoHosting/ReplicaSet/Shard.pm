package MongoHosting::ReplicaSet::Shard;

use Moo;
with 'MongoHosting::Role::Instance';
with 'MongoHosting::Role::WithSiblings';

use strictures 2;
use Rex::Commands::Run;
use Rex::Commands::Pkg;
use Rex::Commands::File;
use Rex::Commands::Run;
use Rex::Commands::Service;
use namespace::clean;
use Rex::Resource::firewall;
use JSON qw(decode_json);

has is_arbiter => (is => 'ro', init_arg => 'arbiter', default => sub {0});

sub init {
  my $self = shift;
  return if $self->checked;
  $self->_init;
}

sub _init {
  my $self = shift;

  return unless $self->is_primary;

  Rex::Logger::info('Initializing replica set');

  file '/tmp/mongod_init.js',
    content => template('@init', {c => $self, index => 1});

  my $out = run 'mongo',
    [sprintf('%s:%s/admin', $self->host, $self->port), '/tmp/mongod_init.js'];

#  print "$out\n";
}

sub _install_package {
  pkg 'mongodb-org-server', ensure => 'present';
  pkg 'mongodb-org-shell',  ensure => 'present';
}


sub _configure_mongodb {
  my $self    = shift;
  my $host    = $self->host;
  my $port    = $self->port;
  my $datadir = "/data/mongod/$host-$port";

  file $datadir,
    ensure => "directory",
    owner  => "mongodb",
    group  => "mongodb";

  file "/etc/mongod-$host-$port.conf",
    content => template(
    '@config',
    args => {
      host        => $self->host,
      datadir     => $datadir,
      replSetName => $self->parent->name,
      bindIp      => $self->private_ip,
      port        => $self->port,
      journal     => $self->journal_enabled,
      is_arbiter  => $self->is_arbiter,
    },
    ),
    chmod => 644;
  my $service_name = $self->service_name;

  file "/etc/systemd/system/$service_name.service",
    content =>
    template('@service', args => {host => $self->host, port => $self->port}),
    chmod => 644;

}

sub service_name {
  my $self = shift;
  my $host = $self->host;
  my $port = $self->port;

  return "mongod-$host-$port";
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
  if ($self->is_arbiter) {
    my $host = $self->host;
    my $port = $self->port;
    my $out  = run "stat /var/run/mongodb/mongod-$host-$port.pid";

    return if $?;
    return unless $out;
    return 1;
  }

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
  my $json = eval { decode_json($out) } or warn $@, return;
  my ($ok, $rs) = @$json;

  return 1 if $ok && defined $rs && $rs eq $self->parent->name;

  return;

}

sub start {
  my $self = shift;
  my $host = $self->host;
  my $port = $self->port;

  service "mongod-$host-$port" => 'restart';
  service "mongod-$host-$port" => ensure => 'started';
}

sub journal_enabled {
  shift->is_arbiter ? 'false' : 'true';
}

1;


__DATA__

@config
storage:
  dbPath: <%= $args->{datadir} %>
  journal:
    enabled: <%= $args->{journal} %>

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod-<%= $args->{host} %>-<%= $args->{port} %>.log

net:
  port: <%= $args->{port} %>
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo
  fork: true
  pidFilePath: /var/run/mongodb/mongod-<%= $args->{host} %>-<%= $args->{port} %>.pid

replication:
  replSetName: <%= $args->{replSetName} %>

<% if(!$args->{is_arbiter}) { %>
sharding:
  clusterRole: shardsvr
<% } %>
@end

@service
[Unit]
Description=MongoDB data server
After=network.target

[Service]
User=mongodb
Type=forking
ExecStart=/usr/bin/mongod --fork --quiet --config /etc/mongod-<%= $args->{host} %>-<%= $args->{port} %>.conf

[Install]
WantedBy=multi-user.target

@end

@init
rs.initiate(
  {
    _id: "<%= $c->parent->name %>",
    settings: {
      electionTimeoutMillis : 2000,
    },
    members: [
    <% foreach my $host (grep {!$_->is_arbiter} @{$c->siblings}) { %>
      { _id : <%= ($index++) %>, host: "<%= $host->dsn %>" },
    <% } %>
    ]
  }
);
sleep(10000);
<% if($c->is_primary) { %>
rs.addArb("<%= $c->parent->arbiter->dsn %>");
<% } %>

printjson(rs.status());
@end
