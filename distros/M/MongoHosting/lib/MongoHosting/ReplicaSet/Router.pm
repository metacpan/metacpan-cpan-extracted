package MongoHosting::ReplicaSet::Router;

use Moo;
use strictures 2;
use namespace::clean;
with 'MongoHosting::Role::Instance';
with 'MongoHosting::Role::WithSiblings';

use Rex::Commands::Run;
use Rex::Commands::Pkg;
use Rex::Commands::File;
use Rex::Commands::Run;
use Rex::Commands::Service;
use Rex::Commands::Host;
use Rex::Commands::User;
use Rex::Resource::firewall;
use List::Util qw(all);

sub init {
  my $self = shift;
  return if all { $_->checked } @{$self->parent->siblings};
  $self->_init;
}

sub _init {
  my $self = shift;

  Rex::Logger::info('Initializing replica set');

  file '/tmp/mongos_init.js', content => template('@init', {c => $self});

  run 'mongo',
    [sprintf('%s:%s/admin', $self->host, $self->port), '/tmp/mongos_init.js'];
}


sub _install_package {
  pkg 'mongodb-org-mongos', ensure => 'present';
  pkg 'mongodb-org-shell',  ensure => 'present';
}

before _setup_directories => sub {
  create_group mongodb => {system => 1};
  create_user mongodb => {create_home => 0, groups => [qw(mongodb)]};
};

sub _configure_mongodb {
  my $self = shift;

  file "/etc/mongos.conf",
    content => template('@config', {c => $self,},),
    chmod   => 644;

  file "/etc/systemd/system/mongos.service",
    content => template('@service', args => {host => $self->host,}),
    chmod   => 644;
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
    sprintf('%s:%s/admin', $self->host, $self->port), '--quiet',
    '--eval', 'sh.status()'
  ];
  return 1 unless $?;
  return if $out =~ /failed|refused/i;
  return 1;
}

sub start {
  service mongos => 'restart';
  service mongos => ensure => 'started';
}

sub _shards {
  map    { $_->shard_dsn }
    map  { @{$_->members} }
    grep { $_->type eq 'shard' } @{shift->parent->siblings};
}

sub _configdb {
  my ($c) = grep { $_->type eq 'config' } @{shift->parent->siblings};
  return $c->sharding_dsn;
}

1;


__DATA__
@config
systemLog:
  destination: file
  path: /var/log/mongodb/mongos.log
  logAppend: true

processManagement:
  fork: true
  pidFilePath: /var/run/mongodb/mongos.pid

net:
  port: <%= $c->port %>
  bindIp: 0.0.0.0

sharding:
   configDB: <%= $c->_configdb %>

@end

@service
[Unit]
Description=Mongos - MongoDB Query Router
After=network.target

[Service]
User=mongodb
Type=forking
ExecStart=/usr/bin/mongos --fork --quiet --config /etc/mongos.conf

[Install]
WantedBy=multi-user.target
@end

@init
<% foreach my $shard ($c->_shards) { %>
sh.addShard('<%= $shard %>');
<% } %>
printjson(sh.status());
@end
