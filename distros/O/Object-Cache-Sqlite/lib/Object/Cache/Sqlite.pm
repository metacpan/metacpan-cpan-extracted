package Object::Cache::Sqlite;
use strict;
use warnings;
use 5.014;

use Carp qw(croak);
use DBI;
use Cpanel::JSON::XS;

our $VERSION = 'v0.1.2';

my $JSON = Cpanel::JSON::XS->new->utf8->allow_nonref;

sub new {
	my ($class, %args) = @_;

	my $db_file = $args{db_file} or croak("db_file is required");
	my $silent  = $args{silent} // 1;

	my $self = {
		db_file => $db_file,
		dbh     => undef,
		silent  => $silent,
	};

	bless $self, $class;
	$self->_init_db();

	return $self;
}

sub _init_db {
	my ($self) = @_;

	my $opts = {
		RaiseError => 1,
		AutoCommit => 1,
	};

	my $dbh = DBI->connect("dbi:SQLite:dbname=$self->{db_file}", '', '', $opts);

	$self->{dbh} = $dbh;

	my $sth = $dbh->prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='cache'");
	$sth->execute();

	my $table_exists = $sth->fetchrow_array();


	if (!$table_exists) {
		$dbh->do("CREATE TABLE cache (
			CreateTime  INT,
			ExpireTime  INT,
			Key         VARCHAR(255) PRIMARY KEY UNIQUE,
			Value       BLOB
			)");
		$dbh->do("CREATE INDEX ExpireTimeIndex ON cache (ExpireTime)");

		if (!$self->{silent}) {
			warn "Created cache table in $self->{db_file}\n";
		}
	}

	return 1;
}

sub _store_value {
	my ($self, $value) = @_;
	return $JSON->encode($value);
}

sub _load_value {
	my ($self, $data) = @_;
	return undef unless defined $data;
	return eval { $JSON->decode($data) };
}

sub get {
	my ($self, $key) = @_;

	return undef unless defined $key;

	my $dbh = $self->{dbh};
	my $now = time();

	my $sth = $dbh->prepare("SELECT Value, ExpireTime FROM cache WHERE Key = ?");
	$sth->execute($key);

	my ($value, $expire_time) = $sth->fetchrow_array();


	if (!defined $value) {
		return undef;
	}

	if (defined $expire_time && $expire_time < $now) {
		$self->delete($key);
		$self->remove_expired_entries(0);
		return undef;
	}

	return $self->_load_value($value);
}

sub set {
	my ($self, $key, $value, $expires) = @_;

	if (!defined($key)) {
		return 0;
	}

	$expires //= 3600;

	if ($expires < 100000) {
		$expires = time() + $expires;
	}

	if ($expires < time()) {
		return 0;
	}

	my $dbh = $self->{dbh};
	my $now = time();

	my $data   = $self->_store_value($value);
	my $sth    = $dbh->prepare("REPLACE INTO cache (CreateTime, ExpireTime, Key, Value) VALUES (?, ?, ?, ?)");
	my $result = $sth->execute($now, $expires, $key, $data);


	return $result ? 1 : 0;
}

sub delete {
	my ($self, $key) = @_;

	return 0 unless defined $key;

	my $dbh    = $self->{dbh};
	my $sth    = $dbh->prepare("DELETE FROM cache WHERE Key = ?");
	my $result = $sth->execute($key);


	return $result ? 1 : 0;
}

sub cached_item_count {
	my ($self) = @_;

	my $dbh = $self->{dbh};
	my $now = time();

	my $sth = $dbh->prepare("SELECT COUNT(*) FROM cache WHERE ExpireTime >= ? OR ExpireTime IS NULL");
	$sth->execute($now);

	my ($count) = $sth->fetchrow_array();


	return $count // 0;
}

sub cached_item_keys {
	my ($self) = @_;

	my $dbh = $self->{dbh};
	my $now = time();

	my $sth = $dbh->prepare("SELECT Key FROM cache WHERE ExpireTime >= ? OR ExpireTime IS NULL");
	$sth->execute($now);

	my @keys;
	while (my ($key) = $sth->fetchrow_array()) {
		push @keys, $key;
	}



	return \@keys;
}

sub remove_expired_entries {
	my ($self, $vacuum) = @_;

	$vacuum //= 1;

	my $dbh = $self->{dbh};
	my $now = time();

	my $sth = $dbh->prepare("DELETE FROM cache WHERE ExpireTime < ?");
	$sth->execute($now);
	my $deleted = $sth->rows;


	if ($vacuum && $deleted > 0) {
		$self->vacuum();
	}

	return $deleted > 0 ? 1 : 0;
}

sub vacuum {
	my ($self) = @_;

	my $dbh = $self->{dbh};
	$dbh->do("VACUUM");

	return 1;
}

sub empty_cache {
	my ($self) = @_;

	my $dbh = $self->{dbh};
	my $sth = $dbh->prepare("DELETE FROM cache");
	$sth->execute();

	my $deleted = $sth->rows;


	$self->vacuum();

	return $deleted;
}

sub init_db {
	my ($self) = @_;

	my $dbh = $self->{dbh};

	$dbh->do("DROP TABLE IF EXISTS cache");
	$dbh->do("CREATE TABLE cache (
		CreateTime  INT,
		ExpireTime  INT,
		Key         VARCHAR(255) PRIMARY KEY UNIQUE,
		Value       BLOB
		)");

	$dbh->do("CREATE INDEX ExpireTimeIndex ON cache (ExpireTime)");

	return 1;
}

sub disconnect {
	my ($self) = @_;

	if ($self->{dbh}) {
		$self->{dbh}->disconnect();
		$self->{dbh} = undef;
	}

	return 1;
}

sub DESTROY {
	my ($self) = @_;
	eval { $self->disconnect() };
}

1;

__END__

=head1 NAME

Object::Cache::Sqlite - SQLite-based object cache with automatic expiration

=head1 SYNOPSIS

  use Object::Cache::Sqlite;

  my $cache = Object::Cache::Sqlite->new(
      db_file => '/tmp/cache.sqlite',
  );

  my $scalar   = 42;
  my $list_ref = [ 1, 3, 5, 7, 9 ];
  my $hash_ref = { name => 'John', email => 'john@example.com' };

  my $cache_key = "user:123";

  # Store some data for 15 minutes
  $cache->set('age'     , $scalar  , time() + 900);
  $cache->set('ids'     , $list_ref, time() + 900);
  $cache->set($cache_key, $hash_ref, time() + 900);

  # Retrieve a value
  my $user = $cache->get($cache_key);

  # Delete a value
  $cache->delete($cache_key);

  # Get cache statistics
  my $count = $cache->cached_item_count();
  my $keys  = $cache->cached_item_keys();

  # Cleanup expired entries
  $cache->remove_expired_entries();

  # Clear entire cache
  $cache->empty_cache();

=head1 DESCRIPTION

Object::Cache::Sqlite provides a simple, fast object cache backed by SQLite.
Data is automatically expired based on TTL values. Uses Cpanel::JSON::XS
for fast, portable serialization.

=head1 CONSTRUCTOR

=head2 new(%args)

Creates a new cache object. Required arguments:

=over 4

=item db_file

Path to the SQLite database file. The file will be created if it doesn't exist.

=back

Optional arguments:

=over 4

=item silent

If true, suppresses initialization messages. Default: 1

=back

=head1 METHODS

=head2 get($key)

Retrieves a cached value by key. Returns C<undef> if the key doesn't exist or
has expired.

=head2 set($key, $value, $expires)

Stores a value in the cache. C<$expires> is the time-to-live in seconds.
If C<$expires> is less than 100000, it's treated as relative (seconds from now).
If C<$expires> is 100000 or greater, it's treated as an absolute Unix timestamp.

Returns true on success.

=head2 delete($key)

Removes a single entry from the cache. Returns true on success.

=head2 cached_item_count()

Returns the number of non-expired entries in the cache.

=head2 cached_item_keys()

Returns an arrayref of all non-expired cache keys.

=head2 remove_expired_entries($vacuum)

Deletes all expired entries from the cache. If C<$vacuum> is true (default),
runs SQLite C<VACUUM> to reclaim space.

=head2 empty_cache()

Deletes ALL entries from the cache and runs C<VACUUM>. Returns the number
of deleted entries.

=head1 EXPIRATION

Cache entries can have two types of expiration:

=over 4

=item Relative TTL

Values less than 100000 are treated as seconds from now.

=item Absolute timestamp

Values 100000 or greater are treated as Unix timestamps.

=back

Expired entries are automatically cleaned up on cache hits and can be
manually cleaned with remove_expired_entries().

=head1 SEE ALSO

=over 4

=item Cache::File::Simple

A simple file-based cache that stores serialized data in individual files.

=back

=head1 AUTHOR

Scott Baker - https://www.perturb.org/

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Scott Baker.

This is free software; you can redistribute it and/or modify it under
the terms of the MIT License.

=cut

# vim: tabstop=4 shiftwidth=4 noexpandtab autoindent softtabstop=4
