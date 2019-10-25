use utf8;
binmode(STDOUT, ":utf8");
use open qw/:std :utf8/;

use Time::HiRes ();
use Rex -feature => ['1.6', 'disable_strict_host_key_checking'];
use Rex::Config;
use Scalar::Util qw(refaddr);
use Class::Load qw(load_class);
use String::CamelCase qw(camelize);
use DigitalOcean;
use YAML ();
use MongoHosting::ReplicaSet;
use Term::ANSIScreen qw(cls);
use UI::Dialog::Backend::CDialog;
use Mango;
use Mojo::IOLoop;
use Mojo::Promise;
use List::Util qw(all);


$|++;

my $conf = YAML::LoadFile($ENV{DEPLOY_CONFIG} || 'config.yml');

$Rex::Logger::debug  = 0;
$Rex::Logger::format = '%D - [%l] - {%h} - %s';

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

# my $provider_class_name
#   = camelize($conf->{provider} or die 'Missing provider in config');

# my $provider = load_class('MongoHosting::Provider::' . $provider_class_name)->new(
#   config         => $conf,
#   ssh_public_key => Rex::Config::get_public_key,
#   api_key        => $ENV{PROVIDER_API_KEY} || die 'missing PROVIDER_API_KEY'
# );

sub build_provider {
  my $conf = shift;
  my $provider_class_name
    = camelize($conf->{provider} or die 'Missing provider in config');

  my $provider
    = load_class('MongoHosting::Provider::' . $provider_class_name)->new(
    config         => $conf,
    ssh_public_key => Rex::Config::get_public_key,
    api_key        => $ENV{PROVIDER_API_KEY} || die 'missing PROVIDER_API_KEY'
    );
  return $provider;
}

task deploy => sub {
  my @replica_sets = deploy_helper($conf);
};


sub deploy_helper {
  my ($conf)       = @_;
  my $provider     = build_provider($conf);
  my @replica_sets = ();
  foreach my $replica (@{$conf->{replicas}}) {
    push @replica_sets,
      MongoHosting::ReplicaSet->new(
      name    => $replica->{name},
      type    => $replica->{type},
      members => [
        map { +{%$_, box => $provider->get_box($_->{host})} }
          @{$replica->{members}}
      ]
      );
  }

  my @all = map { @{$_->members} } @replica_sets;

  foreach my $member (@all) {
    $member->setup_firewall(
      $conf->{app_host},      
#      ($member->type eq 'router' ? ($conf->{app_host} || undef) : ()),
      grep { $_->host ne $member->host } @all);
  }

  foreach my $type (qw(shard config router)) {    # it must be in this order
    foreach my $r (grep { $_->type eq $type } @replica_sets) {
      $r->siblings([grep { refaddr($r) != refaddr($_) } @replica_sets]);
      Rex::Logger::info('Processing replica set: ' . $r->name);
      eval { $r->deploy };
      warn $@ if $@;
    }
  }
  return @replica_sets;
}


task remove => sub {
  my $provider = build_provider($conf);
  my @boxes    = $provider->existing_boxes;
  Rex::Logger::info('No droplets to remove.'), return unless @boxes;
  my $d = UI::Dialog::Backend::CDialog->new(
    backtitle  => 'MongoDB Cluster Management',
    title      => 'MongoDB',
    height     => 20,
    width      => 65,
    listheight => 10,
    order      => ['zenity', 'xdialog']
  ) or die $@;

  my @selection = $d->checklist(
    text => 'Select one:',
    list => [
      map { $_->name => ['id:' . $_->id, 0] }
      sort { $a->name cmp $b->name } @boxes
    ]
  );

  my $list = "\n" . join('', map { "\n\t* " . $_ } @selection);
  if (
    $d->yesno(
      text => 'Do you really want to remove the following hosts?' . $list
    )
    )
  {
    print cls();
    foreach my $host (@selection) {
      print sprintf("\nRemoving %s %s ", $host, ('.' x (30 - length($host))));
      $_->remove for grep { $host eq $_->name } @boxes;
      print colored(['bright_green'], '✔');
    }
    print color('reset');
    print "\n";

  }
  else {
    print cls();
  }
};


task test => sub {
  my @replica_sets = ();
  my $provider     = build_provider($conf);

#  return add_replica_set($conf);
  foreach my $replica (@{$conf->{replicas}}) {
    push @replica_sets,
      MongoHosting::ReplicaSet->new(
      name    => $replica->{name},
      type    => $replica->{type},
      members => [
        map { +{%$_, box => $provider->get_box($_->{host})} }
          @{$replica->{members}}
      ]
      );
  }


  run_task 'test_restart_primary', params => {replica_sets => \@replica_sets};
  run_task 'test_restart_routers', params => {replica_sets => \@replica_sets};
  run_task 'test_restart_configs', params => {replica_sets => \@replica_sets};
  run_task 'test_new_replica_increases_storage',
    params => {replica_sets => \@replica_sets};
};

sub add_replica_set {
  my $c = shift;
  use DDP;

  my %hosts = map { $_->{name} => $_ } @{$c->{hosts}};
  my ($replica_set) = grep { $_->{type} eq 'shard' } @{$c->{replicas}};

  my @new_hosts       = ();
  my %new_replica_set = (
    name    => $replica_set->{name} =~ s/(\d+)/${\($1+1)}/r,
    type    => 'shard',
    members => []
  );
  foreach my $member (@{$replica_set->{members}}) {
    my $new_name = $member->{host} =~ s/(\d+)/${\($1+1)}/r;
    push @{$new_replica_set{members}}, {%$member, host => $new_name,};
    push @new_hosts, {%{$hosts{$member->{host}}}, name => $new_name};
  }
  push @{$c->{hosts}},    @new_hosts;
  push @{$c->{replicas}}, \%new_replica_set;


  return \@new_hosts, deploy_helper($c);

}

task test_new_replica_increases_storage => sub {
  my $params = shift;

  my (@routers)
    = grep { $_->type eq 'router' }
    map    { @{$_->members} } @{delete $params->{replica_sets}};

  my @mongos = map { Mango->new('mongodb://' . $_->public_ip . ':' . $_->port) }
    @routers;

  my $elapsed;

  {
    my @promises = ();


    run_task enable_sharding => on => $routers[0]->public_ip;
    sleep(10);
    my ($__done, $__error) = __line(q{Inserting data});

    $elapsed = run_task run_insert => on => $routers[0]->public_ip;
    chomp($elapsed);


    # foreach my $i (1 .. 10_000) {
    #   my $promise = Mojo::Promise->new;
    #   ($mongos[$i % scalar @mongos])->db('examplex')->collection('examplex')
    #     ->insert(
    #     {abc => rand(time)},
    #     sub {
    #       my ($col, $err) = @_;
    #       say $err if $err;
    #       $promise->resolve;
    #     }
    #     );
    #   push @promises, $promise;
    # }
    # my $start = Time::HiRes::time;
    # Mojo::Promise->all(@promises)->wait;
    # $elapsed = Time::HiRes::time - $start;
    $__done->("Took ${elapsed}ms");
  }

  Rex::Logger::info('Adding new replica set');
  my ($new_hosts, @replica_sets) = add_replica_set($conf);

  {
    my @promises = ();

    run_task enable_sharding => on => $routers[0]->public_ip;
    sleep(10);
    my ($__done, $__error) = __line(q{Inserting data});
    my $previous_elapsed = $elapsed;
    $elapsed = run_task run_insert => on => $routers[0]->public_ip;
    chomp($elapsed);

    # foreach my $i (1 .. 10_000) {
    #   my $promise = Mojo::Promise->new;
    #   ($mongos[$i % scalar @mongos])->db('examplex')->collection('examplex')
    #     ->insert(
    #     {abc => rand(time)},
    #     sub {
    #       my ($col, $err) = @_;
    #       say $err if $err;
    #       $promise->resolve;
    #     }
    #     );
    #   push @promises, $promise;
    # }
    # my $start = Time::HiRes::time;
    # Mojo::Promise->all(@promises)->wait;
    # my $previous_elapsed = $elapsed;
    # $elapsed = Time::HiRes::time - $start;
    $__done->("Took ${elapsed}ms");
    ($__done, $__error) = __line(q{Comparing timings});
    $previous_elapsed > $elapsed
      ? $__done->("Took less time than before: $previous_elapsed > $elapsed")
      : $__error->();
  }

  my %host_map = map { $_->{name} => $_ } @$new_hosts;
  my @shards = keys %{+{map { $_ => 1 } map {/^(.*?)-/} keys %host_map}};
  my $stats = $mongos[0]->db('examplex')->stats;

#  p($stats);
  {
    my ($__done, $__error) = __line(q{Testing shards data distribution});
    (
      all { $_ > 0 }
      map { $_->{dataSize} } values %{$stats->{raw}}
    ) ? $__done->("All shards got data") : $__error->();
  }

  run_task remove_shards => on      => $routers[0]->public_ip,
    params               => {shards => [@shards]};
  sleep(10);

  # eval {
  #   $mongos[0]->db('examplex')->command('dropDatabase' => 'examplex');
  #   sleep(10);
  #   $mongos[0]->db(q{admin})->command(removeShard => $_) for @shards;
  # };
  # warn $@ if $@;

  Rex::Logger::info('Removing: ' . $_->name), $_->remove
    for grep { $host_map{$_->name} }
    map { $_->box } map { @{$_->members} } @replica_sets;
  use DDP;
};


task test_restart_routers => sub {
  my $params       = shift;
  my @replica_sets = @{delete $params->{replica_sets}};

  my (@routers)
    = grep { $_->type eq 'router' } map { @{$_->members} } @replica_sets;

  my @mongos = map { Mango->new('mongodb://' . $_->public_ip . ':' . $_->port) }
    @routers;

  my $testdb_name = 'tttest';

  my @outages = ();


  foreach my $m (@mongos) {
    my $stop = 0;
    my $got_error;
    my $timer;
    $timer = Mojo::IOLoop->recurring(
      0.5 => sub {
        $m->db($testdb_name)->collection('foo')->insert(
          {abc => rand(time) . rand(time)},
          sub {
            my ($col, $err) = @_;
            use Time::HiRes qw(time);

#	    say "$timer: $err" if $err;
            $got_error = time if $err && !$got_error;
            push(@outages, time - $got_error), Mojo::IOLoop->remove($timer)
              if $got_error && !$err && @outages < 2;
          }
        );
      }
    );
  }

  {
    my ($__done, $__error);

    ($__done, $__error) = __line(q{Scheduling router's restart});
    run_task schedule_restart_router => on => $_->public_ip for @routers;
    $__done->();
  }

  my ($__done, $__error);
  ($__done, $__error) = __line(q{Inserting data and waiting for outages});

  Mojo::IOLoop->recurring(
    1 => sub {
      $__done->(), Mojo::IOLoop->stop
        if Mojo::IOLoop->is_running && scalar @outages == scalar @mongos;
    }
  );
  Mojo::IOLoop->timer(
    60 => sub {
      $__error->('Timed out'), Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
    }
  );


  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  ($__done, $__error) = __line(q{Checking outages});
  scalar @outages == 2 && all { $_ > 0 }
  @outages ? $__done->() : $__error->('Not enough outages');
  print "\n";

  $mongos[0]->db($testdb_name)->command('dropDatabase' => $testdb_name);
};

task test_restart_primary => sub {
  my $params       = shift;
  my @replica_sets = @{delete $params->{replica_sets}};

  my (@routers)
    = grep { $_->type eq 'router' } map { @{$_->members} } @replica_sets;

  my @mongos = map { Mango->new('mongodb://' . $_->public_ip . ':' . $_->port) }
    @routers;

  my ($primary)
    = grep { $_->is_primary && $_->type eq 'shard' }
    map { @{$_->members} } @replica_sets;

  my $testdb_name = 'tttest';

  my @outages = ();


  foreach my $m (@mongos) {
    my $stop = 0;
    my $got_error;
    my $timer;
    $timer = Mojo::IOLoop->recurring(
      0.5 => sub {
        $m->db($testdb_name)->collection('foo')->insert(
          {abc => rand(time) . rand(time)},
          sub {
            my ($col, $err) = @_;
            use Time::HiRes qw(time);

#            say "$timer: $err" if $err;
            $got_error = time if $err && !$got_error;
            push(@outages, time - $got_error), Mojo::IOLoop->remove($timer)
              if $got_error && !$err && @outages < 2;
          }
        );
      }
    );
  }

  {
    my ($__done, $__error);

    ($__done, $__error) = __line(q{Scheduling primary replica restart});
    run_task schedule_restart_primary => on => $primary->public_ip,
      params => {service_name => $primary->service_name};
    $__done->();
  }

  my ($__done, $__error);
  ($__done, $__error) = __line(q{Inserting data and waiting for outages});

  Mojo::IOLoop->recurring(
    1 => sub {
      $__done->(), Mojo::IOLoop->stop
        if Mojo::IOLoop->is_running && scalar @outages == scalar @mongos;
    }
  );
  Mojo::IOLoop->timer(
    60 => sub {
      $__error->('Timed out'), Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
    }
  );


  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  ($__done, $__error) = __line(q{Checking outages});
  scalar @outages == 2 && all { $_ > 0 }
  @outages ? $__done->() : $__error->('Not enough outages');
  print "\n";

  $mongos[0]->db($testdb_name)->command('dropDatabase' => $testdb_name);
};


task test_restart_configs => sub {
  my $params       = shift;
  my @replica_sets = @{delete $params->{replica_sets}};

  my (@routers)
    = grep { $_->type eq 'router' } map { @{$_->members} } @replica_sets;

  my @mongos = map { Mango->new('mongodb://' . $_->public_ip . ':' . $_->port) }
    @routers;

  my @configs
    = grep { $_->type eq 'config' } map { @{$_->members} } @replica_sets;

  my $testdb_name = 'tttest';

  my @outages = ();
  my @timers  = ();

  foreach my $m (@mongos) {
    my $stop = 0;
    my $got_error;
    my $timer;
    $timer = Mojo::IOLoop->recurring(
      0.5 => sub {
        $m->db($testdb_name)->collection('foo')->insert(
          {abc => rand(time) . rand(time)},
          sub {
            my ($col, $err) = @_;
            use Time::HiRes qw(time);
            push(@outages, time), Mojo::IOLoop->remove($timer) if $err;
          }
        );
      }
    );
    push @timers, $timer;
  }

  {
    my ($__done, $__error);

    ($__done, $__error) = __line(q{Scheduling configs restart});
    run_task schedule_restart_config => on => $_->public_ip for @configs;
    $__done->();
  }

  my ($__done, $__error);
  ($__done, $__error) = __line(q{Inserting data and waiting for outages});

  Mojo::IOLoop->recurring(
    1 => sub {
      if (Mojo::IOLoop->is_running && scalar @outages) {
        $__error->('Got outage');
        Mojo::IOLoop->remove($_) for @timers;
        Mojo::IOLoop->stop;
      }
    }
  );
  Mojo::IOLoop->timer(
    60 => sub {
      Mojo::IOLoop->remove($_) for @timers;
      Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
    }
  );


  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  ($__done, $__error) = __line(q{Checking outages});
  @outages ? $__error->('Got outage') : $__done->('No outages');
  print "\n";

  $mongos[0]->db($testdb_name)->command('dropDatabase' => $testdb_name);
};


task schedule_restart_router => sub {
  run q{echo "sleep 20 ; service mongos restart" | at now};
};

task schedule_restart_config => sub {
  run q{echo "sleep 20 ; service mongoc restart" | at now};
};

task enable_sharding => sub {
  my $params      = shift;
  my $testdb_name = $params->{db_name};
  file '/tmp/init_shard.js', content => template('@sharding');
  run qq{mongo localhost:27001/examplex /tmp/init_shard.js};
};

task run_insert => sub {
  run
    q|mongo --quiet localhost:27001/examplex --eval 'var start = Date.now(); for (var i = 1; i <= 5000; i++) db.examplex.insert( { score : i + _rand() } ); print(Date.now() - start)'|;
};

task remove_shards => sub {
  my $params = shift;
  my @shards = @{$params->{shards} || []};
  run qq|mongo --quiet localhost:27001/examplex --eval 'db.dropDatabase()'|;
  sleep(30);
  run
    qq|mongo --quiet localhost:27001/admin --eval 'db.runCommand({ removeShard: "$_"})'|
    for @shards;

  sleep(30);
  run
    qq|mongo --quiet localhost:27001/admin --eval 'db.runCommand({ removeShard: "$_"})'|
    for @shards;


};

task schedule_restart_primary => sub {
  my $params       = shift;
  my $service_name = $params->{service_name};
  run qq{echo "sleep 15 ; service $service_name restart" | at now};
};


sub __line {
  my $msg = shift;
  print sprintf("%s %s ", $msg, ('.' x (60 - length($msg))));
  return (
    sub {
      print colored(['bright_green'],
        '✔' . (@_ ? ' [' . shift . ']' : '') . "\n");
      print color('reset');
    },
    sub {
      print colored(['bright_red'],
        '󠀢✘' . (@_ ? ' [' . shift . ']' : '') . "\n");
      print color('reset');
    }
  );
}
#+db.examplex.createIndex( { score: "hashed" } );
#+sh.shardCollection("examplex.examplex", {score: "hashed"});

__DATA__

@sharding
sh.enableSharding("examplex");
db.createCollection("examplex");
db.examplex.createIndex( { score: 'hashed' } );
sh.shardCollection("examplex.examplex", {score: 'hashed'});
db.examplex.findOne();
use config;
db.settings.save( { "_id" : "chunksize", value : 1 } );
@end
