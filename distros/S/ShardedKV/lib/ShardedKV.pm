package ShardedKV;
$ShardedKV::VERSION = '0.20';
use Moose;
# ABSTRACT: An interface to sharded key-value stores

require ShardedKV::Storage;
require ShardedKV::Storage::Memory;
require ShardedKV::Continuum;



has 'continuum' => (
  is => 'rw',
  does => 'ShardedKV::Continuum',
  required => 1,
);


has 'migration_continuum' => (
  is => 'rw',
  does => 'ShardedKV::Continuum',
);


has 'storages' => (
  is => 'ro',
  isa => 'HashRef', # of ShardedKV::Storage doing-things
  default => sub { +{} },
);



has 'logger' => (
  is => 'rw',
);


# bypassing accessors since this is a hot path
sub get {
  my ($self, $key) = @_;
  my ($mig_cont, $cont) = @{$self}{qw(migration_continuum continuum)};

  # dumb code for efficiency (otherwise, this would be a loop or in methods)

  my $logger = $self->{logger};
  my $do_debug = ($logger and $logger->is_debug) ? 1 : 0;

  my $storages = $self->{storages};
  my $chosen_shard;
  my $value_ref;
  if (defined $mig_cont) {
    $chosen_shard = $mig_cont->choose($key);
    $logger->debug("get()using migration continuum, got storage '$chosen_shard'") if $do_debug;
    my $storage = $storages->{ $chosen_shard };
    die "Failed to find chosen storage (server) for id '$chosen_shard' via key '$key'"
      if not $storage;
    $value_ref = $storage->get($key);
  }

  if (not defined $value_ref) {
    my $where = $cont->choose($key);
    $logger->debug("get()using regular continuum, got storage '$where'") if $do_debug;
    if (!$chosen_shard or $where ne $chosen_shard) {
      my $storage = $storages->{ $where };
      die "Failed to find chosen storage (server) for id '$where' via key '$key'"
        if not $storage;
      $value_ref = $storage->get($key);
    }
  }

  return $value_ref;
}


# bypassing accessors since this is a hot path
sub set {
  my ($self, $key, $value_ref) = @_;
  my $continuum = $self->{migration_continuum};
  $continuum = $self->{continuum} if not defined $continuum;

  my $where = $continuum->choose($key);
  my $storage = $self->{storages}{$where};
  if (not $storage) {
    die "Failed to find chosen storage (server) for id '$where' via key '$key'";
  }

  $storage->set($key, $value_ref);
}


sub delete {
  my ($self, $key) = @_;

  my ($mig_cont, $cont) = @{$self}{qw(migration_continuum continuum)};

  # dumb code for efficiency (otherwise, this would be a loop or in methods)

  my $logger = $self->{logger};
  my $do_debug = ($logger and $logger->is_debug) ? 1 : 0;

  my $storages = $self->{storages};
  my $chosen_shard;
  # Try deleting from shard pointed at by migr. cont. first
  if (defined $mig_cont) {
    $chosen_shard = $mig_cont->choose($key);
    $logger->debug("Deleting from migration continuum, got storage '$chosen_shard'") if $do_debug;
    my $storage = $storages->{ $chosen_shard };
    die "Failed to find chosen storage (server) for id '$chosen_shard' via key '$key'"
      if not $storage;
    $storage->delete($key);
  }

  # ALWAYS also delete from the shard pointed at by the main continuum
  my $where = $cont->choose($key);
  $logger->debug("Deleting from continuum, got storage '$where'") if $do_debug;
  if (!$chosen_shard or $where ne $chosen_shard) {
    my $storage = $storages->{ $where };
    die "Failed to find chosen storage (server) for id '$where' via key '$key'"
      if not $storage;
    $storage->delete($key);
  }
}


sub reset_connection {
  my ($self, $key) = @_;

  my ($mig_cont, $cont) = @{$self}{qw(migration_continuum continuum)};

  # dumb code for efficiency (otherwise, this would be a loop or in methods)

  my $logger = $self->{logger};
  my $do_debug = ($logger and $logger->is_debug) ? 1 : 0;

  my $storages = $self->{storages};
  my $chosen_shard;
  # Reset the shard pointed at by migr. cont. first
  if (defined $mig_cont) {
    $chosen_shard = $mig_cont->choose($key);
    $logger->debug("Resetting the connection to the shard from migration continuum, got storage '$chosen_shard'") if $do_debug;
    my $storage = $storages->{ $chosen_shard };
    die "Failed to find chosen storage (server) for id '$chosen_shard' via key '$key'"
      if not $storage;
    $storage->reset_connection();
  }

  # Reset the shard from the main continuum
  my $where = $cont->choose($key);
  $logger->debug("Resetting the connection to the shard from the main continuum, got storage '$where'") if $do_debug;
  if (!$chosen_shard or $where ne $chosen_shard) {
    my $storage = $storages->{ $where };
    die "Failed to find chosen storage (server) for id '$where' via key '$key'"
      if not $storage;
    $storage->reset_connection();
  }
}


sub begin_migration {
  my ($self, $migration_continuum) = @_;

  my $logger = $self->{logger};
  if ($self->migration_continuum) {
    my $err = "Cannot start a continuum migration in the middle of another migration";
    $logger->fatal($err) if $logger;
    Carp::croak($err);
  }
  $logger->info("Starting continuum migration") if $logger;

  $self->migration_continuum($migration_continuum);
}


sub end_migration {
  my ($self) = @_;
  my $logger = $self->{logger};
  $logger->info("Ending continuum migration") if $logger;

  $self->continuum($self->migration_continuum);
  delete $self->{migration_continuum};
}

no Moose;
__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

ShardedKV - An interface to sharded key-value stores

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Continuum::Ketama;
  use ShardedKV::Storage::Redis;
  
  my $continuum_spec = [
    ["shard1", 100], # shard name, weight
    ["shard2", 150],
  ];
  my $continuum = ShardedKV::Continuum::Ketama->new(from => $continuum_spec);
  
  # Redis storage chosen here, but can also be "Memory" or "MySQL".
  # "Memory" is for testing. Mixing storages likely has weird side effects.
  my %storages = (
    shard1 => ShardedKV::Storage::Redis->new(
      redis_connect_str => 'redisserver:6379',
    ),
    shard2 => ShardedKV::Storage::Redis->new(
      redis_connect_str => 'redisserver:6380',
    ),
  );
  
  my $skv = ShardedKV->new(
    storages => \%storages,
    continuum => $continuum,
  );
  
  my $value = $skv->get($key);
  $skv->set($key, $value);
  $skv->delete($key);

=head1 DESCRIPTION

This module implements an abstract interface to a sharded key-value store.
The storage backends as well as the "continuum" are pluggable. "Continuum"
is to mean "the logic that decides in which shard a particular key lives".
Typically, people use consistent hashing for this purpose and very commonly
the choice is to use ketama specifically. See below for references.

Beside the abstract querying interface, this module also implements logic
to add one or more servers to the continuum and use passive key migration
to extend capacity without downtime. Do make it a point to understand the
logic before using it. More on that below.

=head2 LOGGING

ShardedKV allows instrumentation for logging and debugging by setting
the C<logger> attribute of the main ShardedKV object, and/or its
continuum and/or any or all storage sub-objects. If set, the
C<logger> attribute must be an object implementing the following methods:

=over 4

=item *

trace

=item *

debug

=item *

info

=item *

warn

=item *

error

=item *

fatal

=back

which take a string parameter that is to be logged.
These logging levels might be familiar since they are taken from L<Log::Log4perl>,
which means that you can use a C<Log::Log4perl::Logger> object here.

Additionally, the following methods must return whether or not the given log
level is enabled, to potentially avoid costly construction of log messages:

=over 4

=item *

is_trace

=item *

is_debug

=item *

is_info

=item *

is_warn

=item *

is_error

=item *

is_fatal

=back

=head1 PUBLIC ATTRIBUTES

=head2 continuum

The continuum object decides on which shard a given key lives.
This is required for a C<ShardedKV> object and must be an object
that implements the C<ShardedKV::Continuum> role.

=head2 migration_continuum

This is a second continuum object that has additional shards configured.
If this is set, a passive key migration is in effect. See C<begin_migration>
below!

=head2 storages

A hashref of storage objects, each of which represents one shard.
Keys in the hash must be the same labels/shard names that are used
in the continuum. Each storage object must implement the
C<ShardedKV::Storage> role.

=head2 logger

If set, this must be a user-supplied object that implements
a certain number of methods which are called throughout ShardedKV
for logging/debugging purposes. See L</LOGGING> for details.

=head1 PUBLIC METHODS

=head2 get

Given a key, fetches the value for that key from the correct shard
and returns that value or undef on failure.

Different storage backends may return a reference to the value instead.
For example, the Redis and Memory backends return scalar references,
whereas the mysql backend returns an array reference. This might still
change, likely, all backends may be required to return scalar references
in the future.

=head2 set

Given a key and a value, saves the value into the key within the
correct shard.

The value needs to be a reference of the same type that would be
returned by the storage backend when calling C<get()>. See the
discussion above.

=head2 delete

Given a key, deletes the key's entry from the correct shard.

In a migration situation, this might attempt to delete the key from
multiple shards, see below.

=head2 reset_connection

Given a key, it retrieves to which shard it would have communicated and calls
reset_connection() upon it. This allows doing a reconnect only for the shards
that have problems. If there is a migration_continuum it will also reset the
connection to that shard as well in an abundance of caution.

=head2 begin_migration

Given a C<ShardedKV::Continuum> object, this sets the
C<migration_continuum> property of the C<ShardedKV>, thus
beginning a I<passive> key migration. Right now, the only
kind of migration that is supported is I<adding> shards!
Only one migration may be in effect at a time. The
I<passive> qualification there is very significant. If you are,
for example, using the Redis storage backend with a key
expiration of one hour, then you B<know>, that after letting
the passive migration run for one hour, all keys that are
still relevant will have been migrated (or expired if they
were not relevant).

Full migration example:

  use ShardedKV;
  use ShardedKV::Continuum::Ketama;
  use ShardedKV::Storage::Redis;
  
  my $continuum_spec = [
    ["shard1", 100], # shard name, weight
    ["shard2", 150],
  ];
  my $continuum = ShardedKV::Continuum::Ketama->new(from => $continuum_spec);
  
  # Redis storage chosen here, but can also be "Memory" or "MySQL".
  # "Memory" is for testing. Mixing storages likely has weird side effects.
  my %storages = (
    shard1 => ShardedKV::Storage::Redis->new(
      redis_connect_str => 'redisserver:6379',
      expiration_time => 60*60,
    ),
    shard2 => ShardedKV::Storage::Redis->new(
      redis_connect_str => 'redisserver:6380',
      expiration_time => 60*60,
    ),
  );
  
  my $skv = ShardedKV->new(
    storages => \%storages,
    continuum => $continuum,
  );
  # ... use the skv ...
  
  # Oh, we need to extend it!
  # Add storages:
  $skv->storages->{shard3} = ShardedKV::Storage::Redis->new(
    redis_connect_str => 'NEWredisserver:6379',
    expiration_time => 60*60,
  );
  # ... could add more at the same time...
  my $old_continuum = $skv->continuum;
  my $extended_continuum = $old_continuum->clone;
  $extended_continuum->extend([shard3 => 120]);
  $skv->begin_migration($extended_continuum);
  # ... use the skv normally...
  # ... after one hour (60*60 seconds), we can stop the migration:
  $skv->end_migration();

The logic for the migration is fairly simple:

If there is a migration continuum, then for get requests, that continuum
is used to find the right shard for the given key. If that shard does not
have the key, we check the original continuum and if that points the key
at a different shard, we query that.

For delete requests, we also attempt to delete from the shard pointed to
by the migration continuum AND the shard pointed to by the main continuum.

For set requests, we always only use the shard deduced from the migration
continuum

C<end_migration()> will promote the migration continuum to the regular
continuum and set the C<migration_continuum> property to undef.

=head2 end_migration

See the C<begin_migration> docs above.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV::Storage>

=item *

L<ShardedKV::Storage::Redis>

=item *

L<Redis>

=item *

L<ShardedKV::Storage::Memory>

=item *

L<ShardedKV::Storage::MySQL>

=item *

L<DBI>

=item *

L<DBD::mysql>

=back

=over 4

=item *

L<ShardedKV::Continuum>

=item *

L<ShardedKV::Continuum::Ketama>

=item *

L<Algorithm::ConsistentHash::Ketama>

=item *

L<https://github.com/RJ/ketama>

=item *

L<ShardedKV::Continuum::StaticMapping>

=back

=head1 ACKNLOWLEDGMENT

This module was originally developed for Booking.com.
With approval from Booking.com, this module was generalized
and put on CPAN, for which the authors would like to express
their gratitude.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Nick Perez <nperez@cpan.org>

=item *

Damian Gryski <dgryski@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# vim: ts=2 sw=2 et
