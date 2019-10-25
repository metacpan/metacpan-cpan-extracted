package MongoHosting::Role::Instance;
use v5.22;
use Moo::Role;
use strictures 2;
use Rex::Commands::File;
use Rex::Commands::Pkg;
use Rex::Commands::Run;
use Rex::Commands::Service;
use Rex::Group::Entry::Server;
use Rex::Task;
use Rex::Resource::firewall;

#use namespace::clean;
has type => (is => 'ro');
has host => (is => 'ro',);
has ip   => (is => 'ro', default => '127.0.0.1');
has public_ip =>
  (is => 'ro', builder => sub { shift->box->public_ip }, lazy => 1,);
has private_ip =>
  (is => 'ro', builder => sub { shift->box->private_ip }, lazy => 1);
has port => (is => 'ro', default => sub {'27001'});
has box => (is => 'ro', handles => {private_iface => 'private_iface'});
has checked => (is => 'lazy');

requires '_install_package';
requires '_configure_mongodb';
requires 'check';
requires 'start';
requires 'setup_firewall';


sub dsn {
  my $self = shift;
  $self->host . ':' . $self->port;
}

sub shard_dsn {
  my $self = shift;
  $self->parent->name . '/' . $self->host . ':' . $self->port;
}

sub _build_checked {
  !!eval { shift->check };
}

sub setup {
  my ($self, %args) = @_;
  Rex::Logger::info('Setup repository');
  $self->_setup_repository;

  Rex::Logger::info('Installing packages');
  $self->_install_package;

  Rex::Logger::info('Configuring');
  $self->_configure_mongodb;

  Rex::Logger::info('Creating working directories');
  $self->_setup_directories;
}


sub _setup_repository {
  repository
    add        => "mongodb-org-3.6",
    arch       => 'amd64,arm64',
    url        => 'https://repo.mongodb.org/apt/ubuntu',
    distro     => "xenial/mongodb-org/3.6",
    repository => "multiverse",
    key_id     => '2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5',
    key_server => 'hkp://keyserver.ubuntu.com:80';

  update_package_db;

  # for testing
  pkg 'at',
    ensure    => 'present',
    on_change => sub {
    service atd => ensure => 'started';
    };

}

sub _setup_directories {
  file "/data",
    ensure => "directory",
    owner  => "mongodb",
    group  => "mongodb";

  file "/var/log/mongodb",
    ensure => "directory",
    owner  => "mongodb",
    group  => "mongodb";

  file "/var/run/mongodb",
    ensure => "directory",
    owner  => "mongodb",
    group  => "mongodb";
}

sub deploy {
  my $self = shift;
  $self->just_setup_etc_hosts,
    Rex::Logger::info(
    sprintf('Already deployed: %s [%s] ', $self->host, $self->type)), return
    if $self->checked;
  $self->_deploy;
}

sub just_setup_etc_hosts {
  my $self = shift;
  $self->_setup_etc_hosts if $self->does('MongoHosting::Role::WithSiblings');
}

sub _deploy {
  my ($self) = @_;

  Rex::Logger::info(sprintf('Deploying: %s [%s] ', $self->host, $self->type));
  $self->setup;
  $self->start;
  Rex::Logger::info('Done!');
}

around [qw(_deploy check _init setup_firewall just_setup_etc_hosts)] => sub {
  my $orig   = shift;
  my $self   = shift;
  my (@args) = @_;
  my $server
    = Rex::Group::Entry::Server->new(name => $self->public_ip, user => 'root',);
  my $task = Rex::Task->new(name => 'connect');

  $task->set_server($server);
  $task->set_code(sub { $self->$orig(@args) });

  $task->run($server);

};


# before setup_firewall => sub {
#   update_package_db;
#   pkg 'ufw', ensure => 'present';
#   run 'ufw enable';
# };

after _configure_mongodb => sub {
  if (service mongod => 'service_exists') {
    service mongod => ensure => 'stopped';
  }
  run 'systemctl daemon-reload';
};

before start => sub {
  Rex::Logger::info('Starting server instance');
};


1;
__DATA__

