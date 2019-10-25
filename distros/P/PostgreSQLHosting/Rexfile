use utf8;
binmode(STDOUT, ":utf8");

use open qw/:std :utf8/;
use Rex -feature => ['1.6', 'disable_strict_host_key_checking'];
use Rex::Config;
use Rex::Logger;
use YAML ();
use PostgreSQLHosting::Provider;
use Time::HiRes qw(time);

use constant ALLOWED_PROVIDERS => qw(linode digitalocean h_cloud);
use feature 'say';

$Rex::Logger::debug  = 0;
$Rex::Logger::format = '%D - [%l] - {%h} - %s';

$|++;

my $conf = YAML::LoadFile($ENV{DEPLOY_CONFIG} || 'config.yml');
#

die('Missing providers')
  unless scalar grep { exists $conf->{providers}->{$_} } ALLOWED_PROVIDERS;

BEGIN {
  user 'root';
  private_key($ENV{PRIVATE_KEY} || die 'Missing PRIVATE_KEY');
  public_key(
    (
      -r $ENV{PRIVATE_KEY} . '.pub'
      ? $ENV{PRIVATE_KEY} . '.pub'
      : $ENV{PUBLIC_KEY}
    )
      || die 'Missing PUBLIC_KEY'
  );

  key_auth;
}

my @providers = map {
  PostgreSQLHosting::Provider->make_instance(
    {
      %$conf,
      provider => $_,
      secret   => $conf->{providers}->{$_}->{secret},
      hosts    => [
        (
          map {
            +{
              type => 'master',
              size => $_->{size},
              name => $conf->{prefix} . '_' . $_->{name}
              }
          } ($conf->{providers}->{$_}->{master})
        ),
        (
          map {
            +{
              type => 'slave',
              size => $_->{size},
              name => $conf->{prefix} . '_' . $_->{name}
              }
          } (@{$conf->{providers}->{$_}->{slaves}})
        ),
      ]
    }
    )
} keys %{$conf->{providers}};


sub _generate_ssl_keys {
  Rex::Logger::info('Installing openssl');
  file '/etc/ssl/postgres', ensure => 'directory';
  pkg 'openssl',            ensure => 'present';
  Rex::Logger::info('Generating ssl keys');
  run 'openssl req \
    -new \
    -newkey rsa:4096 \
    -days 3650 \
    -nodes \
    -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=www.example.com" \
    -keyout /etc/ssl/postgres/pgserver.key \
    -out /etc/ssl/postgres/pgserver.cert';

  file '/etc/ssl/postgres/pgserver.key',
    owner => "postgres",
    group => "postgres",
    mode  => 400;

  file '/etc/ssl/postgres/pgserver.cert',
    owner => "postgres",
    group => "postgres",
    mode  => 400;

}

sub _setup_apt {
  Rex::Logger::info('Setup aptitude');

  # run 'echo "precedence ::ffff:0:0/96 100" >> /etc/gai.conf';
  # run 'rm -r /var/lib/apt/lists/*';
  # run 'apt-get clean';
  run 'rm -rf /var/lib/apt/lists/partial';
  run 'apt-get update -o Acquire::CompressionTypes::Order::=gz';

  run 'apt-get -o Acquire::ForceIPv4=true update -y';
  pkg 'apt-transport-https', ensure => 'present';
}

sub _install_pg {
  Rex::Logger::info('Installing PostgreSQL apt keys');
  pkg 'wget',            ensure => 'present';
  pkg 'ca-certificates', ensure => 'present';
  run
'wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -';

  my $distro = run 'lsb_release -cs';
  Rex::Logger::info('Setup Pg repo');
  repository
    add        => "postgresql-10",
    arch       => 'amd64',
    url        => 'http://apt.postgresql.org/pub/repos/apt/',
    distro     => "$distro-pgdg",
    repository => "main";

  update_package_db;
  Rex::Logger::info('Installing PostgreSQL');
  pkg 'pgdg-keyring';
  pkg 'postgresql-10',            ensure => 'present';
  pkg 'postgresql-server-dev-10', ensure => 'present';

  service 'postgresql' , ensure => 'started';

}

sub _backup_from_master {
  my $master = shift;

}


task deploy => sub {
  foreach my $provider (@providers) {
    Rex::Logger::info('PROVIDER:' . $provider);

    foreach my $box ($provider->all_boxes) {
      Rex::Logger::info('Starting deploy in ' . $box->name);

   # box build happens here when ->public_id calls ->id and triggers the builder
      my $ip = $box->public_ip;
    }
    my ($master) = grep { $_->type eq 'master' } $provider->all_boxes;

    $_->wait_for_ssh, run_task 'setup_master',
      on     => $_->public_ip,
      params => {box => $_},
      for ($master);

    my @slaves = grep { $_->type eq 'slave' } $provider->all_boxes;

    $_->wait_for_ssh, run_task 'setup_slave',
      on     => $_->public_ip,
      params => {box => $_}
      for @slaves;

    run_task finish_setup => params => {master => $master, slaves => \@slaves};
  }
};

task finish_setup => sub {
  my $params = shift;
  my $master = $params->{master};
  my @slaves = @{$params->{slaves}};

  run_task slave_auth => on      => $master->public_ip,
    params            => {slaves => \@slaves};

  run_task restart_postgresql => on => $master->public_ip;

  run_task create_physical_replication_slot => on      => $master->public_ip,
    params                                  => {slaves => \@slaves};


  run_task setup_recovery => on => $_->public_ip,
    params => {master => $master, hostname => $_->name}
    for @slaves;

};

task restart_postgresql => sub {
  service postgresql => 'restart';
  service postgresql => "ensure", "started";
};

task create_physical_replication_slot => sub {
  my $params = shift;
  my @slaves = @{$params->{slaves}};

  sudo {
    command =>
      sprintf(
q{psql -A -t -q -c "SELECT * FROM pg_create_physical_replication_slot('standby_%s')"},
      $_->name),
    user => 'postgres'
    }
    for @slaves;

};

task slave_auth => sub {
  my $params = shift;
  my @slaves = @{$params->{slaves}};

  my $pg_hba_file =
    sudo {command => "psql -A -t -q -c 'show hba_file'", user => 'postgres'};

  Rex::Logger::info(
    sprintf('Adding %s(%s) to %s', $_->name, $_->private_ip, $pg_hba_file)),
    append_if_no_such_line $pg_hba_file,
    sprintf(
    'hostssl     replication     replicate       %s/32      scram-sha-256',
    $_->private_ip)
    for @slaves;
};

task setup_recovery => sub {
  my $params   = shift;
  my $master   = $params->{master};
  my $hostname = $params->{hostname};
  Rex::Logger::info('Creating .pgpass');

  file '/var/lib/postgresql/.pgpass',
    content => sprintf(
    '%s:*:*:replicate:%s',
    $master->private_ip, $conf->{replication_password}
    ),
    mode  => '600',
    owner => "postgres",
    group => "postgres";


  my $data_dir =
    sudo {command => "psql -A -t -q -c 'show data_directory'",
    user => 'postgres'};

  service 'postgresql', ensure => 'stopped';

  Rex::Logger::info("Resetting $data_dir");

  file $data_dir, ensure => 'absent';

  file $data_dir,
    ensure => 'directory',
    owner  => "postgres",
    group  => "postgres",
    mode   => 700;

  Rex::Logger::info("Backing up from master");

  sudo {
    command => sprintf(
'pg_basebackup -h %s -D %s/ -R -c fast -l "Initial clone" -P -U replicate -X stream',
      $master->private_ip, $data_dir
    ),
    user => 'postgres'
  };

  Rex::Logger::info("Setup recovery");

  append_if_no_such_line "$data_dir/recovery.conf", $_
    for ("primary_slot_name = 'standby_$hostname'",);
  
  service 'postgresql', ensure => 'started';  
  
#   file "$data_dir/recovery.conf",
#     owner   => 'postgres',
#     group   => 'postgres',
#     content => sprintf(
#     q{
# standby_mode          = 'on'
# primary_conninfo      = 'host=%s port=5432 user=replicate password=%s'
# trigger_file = '/tmp/MasterNow'
# primary_slot_name = 'standby-%s'
# }, $master->private_ip, $conf->{replication_password}, $hostname
#  );


};


task setup_slave => sub {
  my $box = shift->{box};
  
#  return if is_readable('/tmp/setup_done');
  _setup_apt;
  _install_pg;

  my $pg_config_file =
    sudo {command => "psql -A -t -q -c 'show config_file'", user => 'postgres'};

  Rex::Logger::info("Setup $pg_config_file => " . $box->name);
  
  append_if_no_such_line $pg_config_file, $_ for ("hot_standby = on",);

  file '/tmp/setup_done', content => '';
};
task remove => sub {
  Rex::Logger::info('Removing ' . $_->name), $_->remove
    for @{delete shift->{existing_boxes} || []};
};

task wipe => sub {
  Rex::Logger::info('Removing ' . $_->name), $_->remove
    for map { $_->existing_boxes } @providers;
};

task setup_master => sub {
  my $box = shift->{box};

  return if is_readable('/tmp/setup_done');
  _setup_apt;
  _install_pg;
  _generate_ssl_keys;

  my $pg_config_file =
    sudo {command => "psql -A -t -q -c 'show config_file'", user => 'postgres'};

  Rex::Logger::info("Setup $pg_config_file => " . $box->name);
  append_if_no_such_line $pg_config_file,
    $_
    for (
    "ssl = on",
    "ssl_cert_file = '/etc/ssl/postgres/pgserver.cert'",
    "ssl_key_file = '/etc/ssl/postgres/pgserver.key'",
    'wal_level = replica',
    'max_wal_senders = 3',
    'wal_keep_segments = 64',
    sprintf(q{listen_addresses = '%s'}, $box->private_ip),
    );
  my $replication_password = $conf->{replication_password};
  sudo {
    command =>
qq{psql -c "SET password_encryption = 'scram-sha-256'; CREATE ROLE replicate WITH REPLICATION LOGIN ENCRYPTED PASSWORD '$replication_password'"},
    user => 'postgres'
  };

  file '/tmp/setup_done', content => '';

};


task inventory => sub {
  say sprintf('[%s] %s => %s', $_->type, $_->name, $_->public_ip)
    for map { $_->existing_boxes } @providers;
};


__DATA__

