package # hide from indexers
  ShardedKV::Test;
use strict;
use warnings;
use Test::More;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
  get_mysql_conf
  mysql_connect_hook
  mysql_storage

  get_redis_conf
  redis_string_storage
  redis_hash_storage

  simple_test_one_server_ketama
  simple_test_multiple_servers_ketama

  extension_test_by_one_server_ketama
  extension_test_by_multiple_servers_ketama
  make_skv
);

SCOPE: { # mysql

  my @mysql_connect_args;
  my $mysql_conf_file = 'testmysqldsn.conf';
  sub get_mysql_conf {
    return @mysql_connect_args if @mysql_connect_args;

    if (-f $mysql_conf_file) {
      open my $fh, "<", $mysql_conf_file or die $!;
      @mysql_connect_args = <$fh>;
      chomp $_ for @mysql_connect_args;
      die "Failed to read DSN" if not @mysql_connect_args;
      return @mysql_connect_args;
    }

    note("There are not connection details.");
    return();
  }

  sub mysql_endpoint {
    return $mysql_connect_args[0];
  }

  my $shared_connection;
  sub mysql_connect_hook {
    require DBI;
    require DBD::mysql;

    undef($shared_connection) if $shared_connection and not eval {$shared_connection->ping};
    return $shared_connection if $shared_connection;
    $shared_connection = DBI->connect(get_mysql_conf());
    # low WAIT_TIMEOUT for manual testing of the connect retry logic
    #$shared_connection->do("SET WAIT_TIMEOUT=5");
    return $shared_connection;
  }

  my $itable;
  sub mysql_storage {
    $itable ||= 1;
    my $table_name = "KVShardTable_$itable";
    note("Creating test shard table $table_name");
    # We set the col types since the timestamp will not roundtrip
    # nicely as a string
    my $st = ShardedKV::Storage::MySQL->new(
      mysql_connector => \&mysql_connect_hook,
      mysql_endpoint => \&mysql_endpoint,
      table_name => $table_name,
      value_col_names => [qw(val last_change)],
      value_col_types => ['MEDIUMBLOB NOT NULL', 'INTEGER UNSIGNED NOT NULL'],
    );
    $st->prepare_table or die "Failed to set up shard table for shard $itable";
    $itable++;
    return $st;
  }

} # end mysql SCOPE

SCOPE: { # redis

  my $redis_connect_str;
  my $redis_conf_file = 'testredis.conf';
  sub get_redis_conf {
    return $redis_connect_str if defined $redis_connect_str;

    if (-f $redis_conf_file) {
      open my $fh, "<", $redis_conf_file or die $!;
      $redis_connect_str = <$fh>;
      chomp $redis_connect_str;
      die "Failed to read Redis connect info"
        if not defined $redis_connect_str;
      return $redis_connect_str;
    }

    note("There are not connection details.");
    return();
  }

  my $idatabase;
  sub redis_string_storage {
    $idatabase ||= 0;
    note("Setting connection to Redis db number $idatabase");
    my $st = ShardedKV::Storage::Redis::String->new(
      redis_connect_str => get_redis_conf(),
      database_number => $idatabase,
      expiration_time => 30, # 30s
      redis_reconnect_timeout => 10,
      redis_retry_every => 1000,
    );
    $idatabase++;
    return $st;
  }

  sub redis_hash_storage {
    $idatabase ||= 0;
    note("Setting connection to Redis db number $idatabase");
    my $st = ShardedKV::Storage::Redis::Hash->new(
      redis_connect_str => get_redis_conf(),
      database_number => $idatabase,
      expiration_time => 30, # 30s
    );
    $idatabase++;
    return $st;
  }

} # end redis SCOPE


sub test_setget {
  my ($name, $skv, $refmaker) = @_;

  my @keys;
  push @keys, qw(virgin foo);
  is_deeply($skv->get("virgin"), undef, "$name - getting non-existant key is undef");
  $skv->set("foo", $refmaker->("bar"));
  is_deeply($skv->get("foo"), $refmaker->("bar"), "$name - getting existant key returns corr. value");
  is_deeply($skv->get("foo"), $refmaker->("bar"), "$name - and does so multiple times");
  $skv->set("foo", $refmaker->("bar2"));
  is_deeply($skv->get("foo"), $refmaker->("bar2"), "$name - updating existing value");
  $skv->delete("foo");
  is_deeply($skv->get("foo"), undef, "$name - deleted key returns undef");
  is_deeply($skv->get("virgin"), undef, "$name - non-existant key still undef");

  srand(0);
  my %data = map {(substr(rand(), 0, 16), rand())} 0..1000;

  foreach (sort keys %data) {
    # randomly induce reconnects about 5% of the time
    # the set should spin up another connection and things
    # should just work.
    if(int(rand(100)) < 5) {
        $skv->reset_connection($_);
    }
    push @keys, $refmaker->($_);
    $skv->set($_, $refmaker->($data{$_}));
  }
  foreach (reverse sort keys %data) {
    is_deeply( $skv->get($_), $refmaker->($data{$_}), "$name key $_" );
  }

  return \@keys;
}


sub simple_test_one_server_ketama {
  my $storage_maker = shift;

  require ShardedKV::Continuum::Ketama;
  my $continuum_spec = [
    ["server1", 100],
  ];
  my $continuum = ShardedKV::Continuum::Ketama->new(from => $continuum_spec);

  my $skv = ShardedKV->new(
    storages => {},
    continuum => $continuum,
  );
  foreach (@$continuum_spec) {
    $skv->storages->{$_->[0]} = $storage_maker->();#ShardedKV::Storage::Memory->new();
  }

  isa_ok($skv, "ShardedKV");
  isa_ok($skv->continuum, "ShardedKV::Continuum::Ketama");
  is(ref($skv->storages), "HASH");
  #isa_ok($_, "ShardedKV::Storage::Memory") foreach values %{$skv->storages};

  my $keys;
  if (grep $_->isa("ShardedKV::Storage::Redis::Hash"), values %{$skv->storages}) {
    $keys = test_setget("one server redis hash", $skv, sub {return +{"somekey" => $_[0]}});
  } elsif (grep $_->isa("ShardedKV::Storage::MySQL"), values %{$skv->storages}) {
    $keys = test_setget("one server mysql", $skv, sub {return [@_, 0]});
  } elsif ((values(%{$skv->storages}))[0]->isa("ShardedKV::Storage::Redis::String")) {
    $keys = test_setget("one server redis string", $skv, sub {\$_[0]});
  } else {
    $keys = test_setget("one server memory", $skv, sub {return \$_[0]});
  }

  if (ref($keys) eq 'ARRAY') {
    $skv->delete($_) for @$keys;
  }
}

sub simple_test_multiple_servers_ketama {
  my $storage_maker = shift;

  my $continuum_spec = [
    ["server1", 100],
    ["server2", 15],
    ["server3", 200],
  ];
  my $continuum = ShardedKV::Continuum::Ketama->new(from => $continuum_spec);

  my $skv = ShardedKV->new(
    storages => {},
    continuum => $continuum,
  );
  foreach (@$continuum_spec) {
    $skv->storages->{$_->[0]} = $storage_maker->();
  }

  isa_ok($skv, "ShardedKV");
  isa_ok($skv->continuum, "ShardedKV::Continuum::Ketama");
  is(ref($skv->storages), "HASH");
  #isa_ok($_, "ShardedKV::Storage::Memory") foreach values %{$skv->storages};

  my $keys;
  if ((values(%{$skv->storages}))[0]->isa("ShardedKV::Storage::Redis::Hash")) {
    $keys = test_setget("multiple servers redis hash", $skv, sub {+{"somekey" => $_[0]}});
  } elsif ((values(%{$skv->storages}))[0]->isa("ShardedKV::Storage::MySQL")) {
    $keys = test_setget("multiple servers mysql", $skv, sub {[@_, 0]});
  } elsif ((values(%{$skv->storages}))[0]->isa("ShardedKV::Storage::Redis::String")) {
    $keys = test_setget("multiple servers redis string", $skv, sub {\$_[0]});
  } else {
    $keys = test_setget("multiple servers memory", $skv, sub {\$_[0]});
  }

  my $is_mem = (values(%{$skv->storages}))[0]->isa("ShardedKV::Storage::Memory");
  if ($is_mem) {
    my $servers_with_keys = 0;
    foreach my $server (values %{$skv->{storages}}) {
      # Breaking encapsulation, since we know it's of type Memory
      $servers_with_keys++ if keys %{$server->hash};
    }
    ok($servers_with_keys > 1); # technically probabilistic, but chances of failure are nil
  }

  if (ref($keys) eq 'ARRAY') {
    $skv->delete($_) for @$keys;
  }
}

sub extension_test_by_one_server_ketama {
  my $storage_maker = shift;
  my $storage_type = shift;

  # yes, yes, this blows.
  my $make_ref = $storage_type =~ /^(?:memory|redis_string)$/i ? sub {\$_[0]} : sub {[$_[0], 0]};

  my $continuum_spec = [
    ["server1", 100],
    ["server2", 150],
    ["server3", 200],
  ];

  my $skv = make_skv($continuum_spec, $storage_maker);
  my @keys = (1..1000);
  $skv->set($_, $make_ref->("v$_")) for @keys;
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;

  # Setup new server and an extended continuum
  $skv->storages->{server4} = $storage_maker->();
  my $new_cont = $skv->continuum->clone;
  $new_cont->extend([
    ["server4", 120],
  ]);
  isa_ok($new_cont, "ShardedKV::Continuum::Ketama");

  # set continuum
  $skv->begin_migration($new_cont);
  isa_ok($skv->migration_continuum, "ShardedKV::Continuum::Ketama");

  # Check that reads still work and return the old values
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;

  # Rewrite part of the keys
  my @first_half_keys = splice(@keys, 0, int(@keys/2));
  foreach (@first_half_keys) {
    # randomly induce reconnects about 5% of the time
    # the set should spin up another connection and things
    # should just work.
    if(int(rand(100)) < 5) {
      $skv->reset_connection($_);
    }
    $skv->set($_, $make_ref->("N$_"));
  }

  # Check old and new keys
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;
  foreach (@first_half_keys) {
    # randomly induce reconnects about 5% of the time
    # the set should spin up another connection and things
    # should just work.
    if(int(rand(100)) < 5) {
      $skv->reset_connection($_);
    }
    is_deeply($skv->get($_), $make_ref->("N$_"))
  }

  if ($storage_type =~ /memory/i) {
    # FIXME support this part of the test for mysql and redis!
    check_old_new("Single new server", $skv, qr/^server4$/);
  }

  $skv->end_migration;

  ok(!defined($skv->migration_continuum),
     "no migration continuum after migration end");
}

sub extension_test_by_multiple_servers_ketama {
  my $storage_maker = shift;
  my $storage_type = shift;

  # yes, yes, this blows.
  my $make_ref = $storage_type =~ /^(?:memory|redis_string)$/i ? sub {\$_[0]} : sub {[$_[0], 0]};

  my $continuum_spec = [
    ["server1", 10],
    ["server2", 1000],
    ["server3", 200],
  ];

  my $skv = make_skv($continuum_spec, $storage_maker);
  my @keys = (1..2000);
  $skv->set($_, $make_ref->("v$_")) for @keys;
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;

  # Setup new servers and an extended continuum
  $skv->storages->{"server$_"} = $storage_maker->() for 4..8;
  my $new_cont = $skv->continuum->clone;
  $new_cont->extend([
    ["server5", 120], ["server6", 1200],
    ["server7", 10], ["server8", 700],
  ]);
  isa_ok($new_cont, "ShardedKV::Continuum::Ketama");

  # set continuum
  $skv->begin_migration($new_cont);
  isa_ok($skv->migration_continuum, "ShardedKV::Continuum::Ketama");

  # Check that reads still work and return the old values
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;

  # Rewrite part of the keys
  my @first_half_keys = splice(@keys, 0, int(@keys/2));
  $skv->set($_, $make_ref->("N$_")) for @first_half_keys;

  # Check old and new keys
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;
  foreach (@first_half_keys) {
    # randomly induce reconnects about 5% of the time
    # the set should spin up another connection and things
    # should just work.
    if(int(rand(100)) < 5) {
      $skv->reset_connection($_);
    }
    is_deeply($skv->get($_), $make_ref->("N$_"))
  }

  if ($storage_type =~ /memory/i) {
    # FIXME support this part of the test for mysql and redis!
    check_old_new("Many new servers", $skv, qr/^server[5-8]$/);
  }
}

# make sure that old values are on old servers, new values on either
# Breaking encapsulation of the in-Memory storage...
sub check_old_new {
  my ($name, $skv, $new_server_regex) = @_;

  # combined keys in new server
  my %new_exists;
  foreach my $sname (keys %{$skv->storages}) {
    my $server = $skv->storages->{$sname};
    my $hash = $server->hash;
    if ($sname =~ $new_server_regex) {
      $new_exists{$_} = undef for keys %$hash;
    }
  }

  foreach my $sname (keys %{$skv->storages}) {
    my $server = $skv->storages->{$sname};
    my $hash = $server->hash;
    if ($sname =~ $new_server_regex) {
      foreach (keys %$hash) {
        my $str = "$name: Old value 'v$_' for key '$_' in new server!";
        ok(${$hash->{$_}} =~ /^N/, $str);
      }
    }
    else {
      foreach (keys %$hash) {
        my $str = "$name: New value 'N$_' for key '$_' in old server as 'v$_'!";
        if (exists $new_exists{$_}) {
          ok(${$hash->{$_}} =~ /^v/, $str);
        }
      }
    }
  }
}

# make a new ShardedKV from a continuum spec
sub make_skv {
  my $cont_spec = shift;
  my $storage_maker = shift;
  my $continuum = ShardedKV::Continuum::Ketama->new(from => $cont_spec);

  my $skv = ShardedKV->new(
    storages => {},
    continuum => $continuum,
  );
  foreach (@$cont_spec) {
    $skv->storages->{$_->[0]} = $storage_maker->();
  }
  return $skv;
}

1;
# vim: ts=2 sw=2 et
