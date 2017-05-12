package # hide from indexers
  ShardedKV::Test::CHash;
use strict;
use warnings;
use Test::More;

require Exporter;
our @ISA = qw(Exporter);

our @EXPORT = qw(
  simple_test_one_server_chash
  simple_test_multiple_servers_chash
  extension_test_by_one_server_chash
  extension_test_by_multiple_servers_chash
  make_skv
);

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


sub simple_test_one_server_chash {
  require ShardedKV::Continuum::CHash;
  my $continuum_spec = {
    ids => ["server1"],
    replicas => 100,
  };
  my $continuum = ShardedKV::Continuum::CHash->new(from => $continuum_spec);

  my $skv = ShardedKV->new(
    storages => {},
    continuum => $continuum,
  );
  foreach (@{$continuum_spec->{ids}}) {
    $skv->storages->{$_} = ShardedKV::Storage::Memory->new();
  }

  isa_ok($skv, "ShardedKV");
  isa_ok($skv->continuum, "ShardedKV::Continuum::CHash");
  is(ref($skv->storages), "HASH");

  my $keys;
  $keys = test_setget("one server memory", $skv, sub {return \$_[0]});

  if (ref($keys) eq 'ARRAY') {
    $skv->delete($_) for @$keys;
  }
}

sub simple_test_multiple_servers_chash {
  my $continuum_spec = {
    ids => [qw(server1 server2 server3)],
    replicas => 200,
  };
  my $continuum = ShardedKV::Continuum::CHash->new(from => $continuum_spec);

  my $skv = ShardedKV->new(
    storages => {},
    continuum => $continuum,
  );
  foreach (@{ $continuum_spec->{ids} }) {
    $skv->storages->{$_} = ShardedKV::Storage::Memory->new();
  }

  isa_ok($skv, "ShardedKV");
  isa_ok($skv->continuum, "ShardedKV::Continuum::CHash");
  is(ref($skv->storages), "HASH");

  my $keys = test_setget("multiple servers memory", $skv, sub {\$_[0]});

  my $servers_with_keys = 0;
  foreach my $server (values %{$skv->{storages}}) {
    # Breaking encapsulation, since we know it's of type Memory
    $servers_with_keys++ if keys %{$server->hash};
  }
  ok($servers_with_keys > 1); # technically probabilistic, but chances of failure are nil

  if (ref($keys) eq 'ARRAY') {
    $skv->delete($_) for @$keys;
  }
}

sub extension_test_by_one_server_chash {
  my $storage_maker = shift;
  my $storage_type = shift;

  # yes, yes, this blows.
  my $make_ref = $storage_type =~ /^(?:memory|redis_string)$/i ? sub {\$_[0]} : sub {[$_[0], 0]};

  my $continuum_spec = {
    replicas => 300,
    ids => [qw(server1 server2 server3)],
  };

  my $skv = make_skv($continuum_spec, $storage_maker);
  my @keys = (1..1000);
  $skv->set($_, $make_ref->("v$_")) for @keys;
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;

  # Setup new server and an extended continuum
  $skv->storages->{server4} = $storage_maker->();
  my $new_cont = $skv->continuum->clone;
  $new_cont->extend({ids => ["server4"]});
  isa_ok($new_cont, "ShardedKV::Continuum::CHash");

  # set continuum
  $skv->begin_migration($new_cont);
  isa_ok($skv->migration_continuum, "ShardedKV::Continuum::CHash");

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

sub extension_test_by_multiple_servers_chash {
  my $storage_maker = shift;
  my $storage_type = shift;

  # yes, yes, this blows.
  my $make_ref = $storage_type =~ /^(?:memory|redis_string)$/i ? sub {\$_[0]} : sub {[$_[0], 0]};

  my $continuum_spec = {
    replicas => 300,
    ids => [qw(server1 server2 server3)],
  };

  my $skv = make_skv($continuum_spec, $storage_maker);
  my @keys = (1..2000);
  $skv->set($_, $make_ref->("v$_")) for @keys;
  is_deeply($skv->get($_), $make_ref->("v$_")) for @keys;

  # Setup new servers and an extended continuum
  $skv->storages->{"server$_"} = $storage_maker->() for 4..8;
  my $new_cont = $skv->continuum->clone;
  $new_cont->extend({ids => [qw(server5 server6 server7 server8)]});
  isa_ok($new_cont, "ShardedKV::Continuum::CHash");

  # set continuum
  $skv->begin_migration($new_cont);
  isa_ok($skv->migration_continuum, "ShardedKV::Continuum::CHash");

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
  my $continuum = ShardedKV::Continuum::CHash->new(from => $cont_spec);

  my $skv = ShardedKV->new(
    storages => {},
    continuum => $continuum,
  );
  foreach (@{ $cont_spec->{ids} }) {
    $skv->storages->{$_} = $storage_maker->();
  }
  return $skv;
}

=cut

1;
# vim: ts=2 sw=2 et
