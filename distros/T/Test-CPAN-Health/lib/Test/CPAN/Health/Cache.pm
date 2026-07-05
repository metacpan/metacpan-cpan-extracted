package Test::CPAN::Health::Cache;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak carp);
use DBI;
use File::Path qw(make_path);
use File::Spec;
use JSON::MaybeXS qw(encode_json decode_json);
use Readonly;
use Params::Validate::Strict qw(validate_strict);

our $VERSION = '0.1.0';

# Default TTLs in seconds, keyed by check id prefix convention.
# Network-heavy checks have shorter TTLs so stale data is not kept too long;
# package metadata is stable enough for 24 hours.
Readonly::Hash my %DEFAULT_TTLS => (
	cpan_testers        => 3_600,     #  1 hour  -- changes as smoke results arrive
	security_advisories => 3_600,     #  1 hour  -- advisory DB updated frequently
	stale_deps          => 86_400,    # 24 hours -- release cadence is daily at most
	abandoned_deps      => 86_400,    # 24 hours
	reverse_deps        => 86_400,    # 24 hours
	kwalitee            => 86_400,    # 24 hours
	DEFAULT             => 86_400,    # 24 hours for everything else
);

Readonly::Scalar my $SCHEMA_VERSION => 1;

=head1 NAME

Test::CPAN::Health::Cache - Persistent SQLite cache for network check results

=head1 SYNOPSIS

    use Test::CPAN::Health::Cache;

    my $cache = Test::CPAN::Health::Cache->new(
        cache_dir => "$ENV{HOME}/.cache/cpan-health",
    );

    $cache->store('sem_ver:Foo-Bar:1.00', { status => 'pass', score => 100 });
    my $data = $cache->get('sem_ver:Foo-Bar:1.00');

=head1 DESCRIPTION

A lightweight SQLite-backed key/value store that persists health check
results between runs to avoid hammering rate-limited external APIs.

Each entry has a TTL (seconds); C<get> returns C<undef> and behaves as a
cache miss for expired entries.  TTLs are keyed by check id prefix against
the C<%DEFAULT_TTLS> table; unknown checks fall back to 24 hours.

The database is created automatically on first use under C<cache_dir>.

=head1 LIMITATIONS

=over 4

=item * No row-level locking; concurrent processes writing the same key may
race.  SQLite's journal mode provides transaction safety but not write ordering.

=item * Expired rows are pruned lazily on C<get> and on a scheduled sweep;
disk usage may grow unboundedly if C<purge> is never called.

=back

=cut

sub new {
	my ($class, %args) = @_;

	%args = %{ validate_strict(
		schema => {
			cache_dir => { type => 'string',  optional => 1, default => _default_cache_dir() },
			ttls      => { type => 'hashref', optional => 1 },
		},
		input => \%args,
	) };

	my %ttls = (%DEFAULT_TTLS, %{ $args{ttls} // {} });

	my $self = bless {
		_cache_dir => $args{cache_dir},
		_ttls      => \%ttls,
		_dbh       => undef,
	}, $class;

	return $self;
}

=head2 get

Retrieve a cached value by key.  Returns C<undef> on cache miss or if the
entry has expired.

=head3 API SPECIFICATION

=head4 INPUT

  key  Scalar  required  opaque cache key (e.g. 'sem_ver:Foo-Bar:1.00')

=head4 OUTPUT

Hashref of the stored data, or C<undef> on miss/expiry.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  CAC01 | WARNING  | Cache read error: {msg}            | Check DB permissions

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  GetOp
  key?    : String
  value!  : Hashref | undefined
  now     : Timestamp
  -------------------------------------------------------
  key? /= ""
  value! /= undefined <=> exists entry(key?) /\ entry(key?).expires > now

=head3 SIDE EFFECTS

May delete expired rows from the SQLite database.

=head3 USAGE EXAMPLE

    my $data = $cache->get('security_advisories:Foo-Bar:1.00');

=cut

sub get {
	my ($self, $key) = @_;

	croak 'key is required' unless defined $key && length $key;

	my $dbh = $self->_dbh;
	my $now = time;

	my $row = eval {
		$dbh->selectrow_hashref(
			'SELECT value FROM cache WHERE key = ? AND expires > ?',
			undef, $key, $now,
		);
	};

	if ($@) {
		carp "Cache read error: $@";
		return;
	}

	return unless defined $row;

	my $data = eval { decode_json($row->{value}); };
	if ($@) {
		carp "Cache JSON decode error for key '$key': $@";
		return;
	}

	return $data;
}

=head2 store

=head3 PURPOSE

Store a value in the cache under the given key.  The TTL is determined
automatically from the check id embedded in the key (first colon-delimited
segment) using the C<%DEFAULT_TTLS> table.

=head3 API SPECIFICATION

=head4 INPUT

  key    Scalar   required
  value  Hashref  required
  ttl    Scalar   optional  override TTL in seconds

=head4 OUTPUT

Returns C<$self>.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  CAC02 | WARNING  | Cache write error: {msg}           | Check DB permissions/disk space

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  SetOp
  Cache
  Cache'
  key?   : String
  value? : Hashref
  ttl?   : N | undefined
  now    : Timestamp
  -------------------------------------------------------
  Cache'.entries = Cache.entries (+) {key? |-> {value: value?, expires: now + ttl?}}

=head3 SIDE EFFECTS

Writes to the SQLite database.

=head3 USAGE EXAMPLE

    $cache->store('sem_ver:Foo-Bar:1.00', { status => 'pass', score => 100 });

=cut

sub store {
	my ($self, $key, $value, $ttl) = @_;

	croak 'key is required'   unless defined $key   && length $key;
	croak 'value is required' unless defined $value && ref $value eq 'HASH';

	$ttl //= $self->_ttl_for($key);

	my $json    = encode_json($value);
	my $expires = time + $ttl;
	my $dbh     = $self->_dbh;

	eval {
		$dbh->do(
			'INSERT OR REPLACE INTO cache (key, value, expires) VALUES (?, ?, ?)',
			undef, $key, $json, $expires,
		);
		1;
	} or do {
		carp "Cache write error: $@";
	};

	return $self;
}

=head2 record_history

=head3 PURPOSE

Record an overall health score for a distribution version.  Used by the
Runner to build a score-over-time trend.

=head3 API SPECIFICATION

=head4 INPUT

  dist     Scalar  required  Distribution name (e.g. 'LWP-UserAgent')
  version  Scalar  required  Version string
  score    Scalar  required  Integer score 0..100

=head4 OUTPUT

Returns C<$self>.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  CAC04 | WARNING  | History write error: {msg}         | Check DB permissions

=head3 FORMAL SPECIFICATION

  Post: score_history table gains one row (dist, version, score, time())

=head3 SIDE EFFECTS

Writes to the SQLite database.

=head3 USAGE EXAMPLE

    $cache->record_history('LWP-UserAgent', '6.77', 95);

=cut

sub record_history {
	my ($self, $dist, $version, $score) = @_;

	croak 'dist is required'    unless defined $dist    && length $dist;
	croak 'version is required' unless defined $version && length $version;
	croak 'score is required'   unless defined $score;

	eval {
		$self->_dbh->do(
			'INSERT INTO score_history (dist, version, score, recorded) VALUES (?, ?, ?, ?)',
			undef, $dist, $version, $score + 0, time,
		);
		1;
	} or do {
		carp "History write error: $@";
	};

	return $self;
}

=head2 score_history

=head3 PURPOSE

Retrieve recent score history for a distribution in reverse-chronological
order.

=head3 API SPECIFICATION

=head4 INPUT

  dist   Scalar   required  Distribution name
  limit  Integer  optional  Maximum rows to return (default: 10)

=head4 OUTPUT

Arrayref of hashrefs with keys C<dist>, C<version>, C<score>, C<recorded>
(Unix timestamp).  Most-recent first.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  CAC05 | WARNING  | History read error: {msg}          | Check DB permissions

=head3 FORMAL SPECIFICATION

  Post: result is an arrayref of at most limit rows for dist, ordered by recorded DESC

=head3 SIDE EFFECTS

Reads from the SQLite database.

=head3 USAGE EXAMPLE

    for my $row (@{ $cache->score_history('LWP-UserAgent') }) {
        printf "%s: %d\n", scalar localtime($row->{recorded}), $row->{score};
    }

=cut

sub score_history {
	my ($self, $dist, $limit) = @_;

	croak 'dist is required' unless defined $dist && length $dist;
	$limit //= 10;

	my $rows = eval {
		$self->_dbh->selectall_arrayref(
			'SELECT dist, version, score, recorded FROM score_history'
			. ' WHERE dist = ? ORDER BY recorded DESC LIMIT ?',
			{ Slice => {} }, $dist, $limit,
		);
	};

	if ($@) {
		carp "History read error: $@";
		return [];
	}

	return $rows // [];
}

=head2 purge

=head3 PURPOSE

Delete all expired entries from the cache database.  Intended to be called
periodically (e.g. at CLI startup) to reclaim disk space.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

Integer: number of rows deleted.

=head3 MESSAGES

  Code  | Severity | Message                            | Resolution
  ------+----------+------------------------------------+---------------------
  CAC03 | WARNING  | Cache purge error: {msg}           | Check DB permissions

=head3 FORMAL SPECIFICATION

  -- Z schema (placeholder) --
  PurgeOp
  Cache
  Cache'
  now     : Timestamp
  deleted : N
  -------------------------------------------------------
  Cache'.entries = {e : Cache.entries | e.expires > now}
  deleted = #Cache.entries - #Cache'.entries

=head3 SIDE EFFECTS

Deletes rows from the SQLite database.

=head3 USAGE EXAMPLE

    printf "Purged %d stale cache entries\n", $cache->purge;

=cut

sub purge {
	my ($self) = @_;

	my $dbh     = $self->_dbh;
	my $deleted = 0;

	eval {
		$deleted = $dbh->do('DELETE FROM cache WHERE expires <= ?', undef, time);
		$deleted = 0 if $deleted eq '0E0';
		1;
	} or do {
		carp "Cache purge error: $@";
	};

	return $deleted;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

# Return or create the DBI handle, creating the schema on first connect.
sub _dbh {
	my ($self) = @_;

	return $self->{_dbh} if $self->{_dbh};

	make_path($self->{_cache_dir}) unless -d $self->{_cache_dir};

	my $db_file = File::Spec->catfile($self->{_cache_dir}, 'cpan-health.db');

	$self->{_dbh} = DBI->connect(
		"dbi:SQLite:dbname=$db_file", '', '',
		{
			RaiseError => 1,
			AutoCommit => 1,
			PrintError => 0,
		},
	) or croak "Cannot open cache database '$db_file': " . DBI->errstr;

	# WAL mode: allows concurrent reads while a write is in progress.
	$self->{_dbh}->do('PRAGMA journal_mode=WAL');
	$self->_ensure_schema;

	return $self->{_dbh};
}

sub _ensure_schema {
	my ($self) = @_;

	$self->{_dbh}->do(<<'SQL');
CREATE TABLE IF NOT EXISTS cache (
    key     TEXT PRIMARY KEY,
    value   TEXT NOT NULL,
    expires INTEGER NOT NULL
)
SQL

	$self->{_dbh}->do('CREATE INDEX IF NOT EXISTS idx_cache_expires ON cache (expires)');

	$self->{_dbh}->do(<<'SQL');
CREATE TABLE IF NOT EXISTS score_history (
    dist      TEXT    NOT NULL,
    version   TEXT    NOT NULL,
    score     INTEGER NOT NULL,
    recorded  INTEGER NOT NULL
)
SQL

	$self->{_dbh}->do(
		'CREATE INDEX IF NOT EXISTS idx_history_dist ON score_history (dist, recorded)'
	);

	return;
}

# Look up TTL for a key by matching the check id (first colon-segment).
sub _ttl_for {
	my ($self, $key) = @_;

	my ($check_id) = split / : /x, $key, 2;

	return $self->{_ttls}{$check_id} // $self->{_ttls}{DEFAULT} // 86_400;
}

sub _default_cache_dir {
	my $base = $ENV{CACHEDIR} || $ENV{CACHE_DIR}
		|| File::Spec->catdir(
			$ENV{HOME} // $ENV{USERPROFILE} // File::Spec->tmpdir(),
			'.cache',
		);
	return File::Spec->catdir($base, 'cpan-health');
}

sub DESTROY {
	my ($self) = @_;

	if ($self->{_dbh}) {
		$self->{_dbh}->disconnect;
		$self->{_dbh} = undef;
	}

	return;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut

1;
