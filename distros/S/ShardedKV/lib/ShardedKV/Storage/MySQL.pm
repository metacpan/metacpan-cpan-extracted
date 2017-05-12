package ShardedKV::Storage::MySQL;
$ShardedKV::Storage::MySQL::VERSION = '0.20';
use Moose;
# ABSTRACT: MySQL storage backend for ShardedKV

use Time::HiRes qw(sleep);
use Carp ();

use ShardedKV::Error::ConnectFail;
use ShardedKV::Error::DeleteFail;
use ShardedKV::Error::ReadFail;

with 'ShardedKV::Storage';


has 'mysql_connector' => (
  is => 'ro',
  isa => 'CodeRef',
  required => 1,
);


has 'mysql_endpoint' => (
  is => 'ro',
  isa => 'CodeRef',
  required => 1,
);


# This could be shared among many "::Storage::MySQL" objects since we're
# single-threaded (and they would not work across multiple ithreads anyway).
# All that fancy logic would be done by the user-supplied connector code ref
# above which needs to know how to obtain a new or existing connection.
# This means that we can make each Storage::MySQL object be specific to
# a particular table!
has 'mysql_connection' => (
  is => 'rw',
  lazy => 1,
  builder => 'build_mysql_connection',
  clearer => 'clear_mysql_connection',
  predicate => 'has_mysql_connection',
);


sub build_mysql_connection {
  my $self = shift;
  my $logger = $self->logger;
  $logger->debug("Getting mysql connection") if $logger;
  my $dbh = $self->mysql_connector->();
  if ($dbh) {
    $logger->debug("Get connection") if $logger;
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    #$dbh->{AutoCommit} = 1;
  }
  else {
    my $endpoint = $self->mysql_endpoint->();
    ShardedKV::Error::ConnectFail->throw({
      endpoint => $endpoint,
      storage_type => 'mysql',
      message => "Failed to make a connection to MySQL ($endpoint): ${\$DBI::errstr}",
    });
    $logger->warn("Failed to get connection") if $logger;
  }
  return $dbh;
}


has 'table_name' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);


has 'key_col_name' => (
  is => 'ro',
  default => "keystr",
);


has 'key_col_type' => (
  is => 'ro',
  default => "VARBINARY(16) NOT NULL",
);


has 'auto_increment_col_name' => (
  is => 'ro',
  default => 'id',
);


has 'auto_increment_col_type' => (
  is => 'ro',
  default => "BIGINT UNSIGNED NOT NULL AUTO_INCREMENT",
);


has 'value_col_names' => (
  is => 'ro',
  # isa => 'ArrayRef[Str]',
  default => sub {[qw(val last_change)]}
);


has 'value_col_types' => (
  is => 'ro',
  # isa => 'ArrayRef[Str]',
  default => sub {[
    'MEDIUMBLOB NOT NULL',
    'TIMESTAMP NOT NULL',
    #'TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  ]},
);


has 'extra_indexes' => (
  is => 'ro',
  isa => 'Str',
  default => '',
);


has 'max_num_reconnect_attempts' => (
  is => 'rw',
  isa => 'Int',
  default => 5,
);


has 'reconnect_interval' => (
  is => 'rw',
  isa => 'Num',
  default => 1,
);


has 'refresh_mysql_connection_on_error_regex' => (
  is => 'rw',
  isa => 'Maybe[Regexp]',
  lazy => 1,
  builder => '_make_refresh_mysql_connection_on_error_regex',
);

# Could be prepared, but that is kind of nasty wrt. reconnects, so let's not go
# there unless we have to!
has '_get_query' => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_make_get_query',
);

has '_set_query' => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_make_set_query',
);

has '_delete_query' => (
  is => 'ro',
  isa => 'Str',
  lazy => 1,
  builder => '_make_delete_query',
);

has '_number_of_params' => (
  is => 'ro',
  # isa => 'Int',
  lazy => 1,
  builder => '_calc_no_params',
);

sub BUILD {
  $_[0]->_number_of_params;
  $_[0]->refresh_mysql_connection_on_error_regex;
};

sub _calc_no_params {
  my $self = shift;
  return 1 + scalar(@{$self->value_col_names});
}


sub _make_get_query {
  my $self = shift;
  $self->_number_of_params; # prepopulate
  my $tbl = $self->table_name;
  my ($key_col, $v_cols) = map $self->$_, qw(key_col_name value_col_names);
  my $v_col_str = join ',', @$v_cols;
  my $q = qq{SELECT $v_col_str FROM $tbl WHERE $key_col = ? LIMIT 1};

  my $logger = $self->logger;
  $logger->debug("Generated the following get-query:\n$q") if $logger;

  return $q;
}

sub _make_set_query {
  my $self = shift;
  my $tbl = $self->table_name;
  my ($key_col, $v_cols) = map $self->$_, qw(key_col_name value_col_names);
  my $vcol_str = join ", ", @$v_cols;
  my $vcol_assign_str = '';
  $vcol_assign_str .= "$_ = VALUES($_)," for @$v_cols;
  chop $vcol_assign_str;
  my $qs = join( ',', ('?') x $self->_number_of_params );
  my $q = qq{
    INSERT INTO $tbl ($key_col, $vcol_str) VALUES ($qs)
    ON DUPLICATE KEY UPDATE
    $vcol_assign_str
  };

  my $logger = $self->logger;
  $logger->debug("Generated the following set-query:\n$q") if $logger;

  return $q;
}

sub _make_delete_query {
  my $self = shift;
  $self->_number_of_params; # prepopulate
  my $tbl = $self->table_name;
  my $key_col = $self->key_col_name;
  my $q = qq{DELETE FROM $tbl WHERE $key_col = ? LIMIT 1};

  my $logger = $self->{logger};
  $logger->debug("Generated the following delete-query:\n$q") if $logger;

  return $q;
}

sub _make_refresh_mysql_connection_on_error_regex {
  my $self = shift;
  # Does this really need to be /i and can't it just be bounded? Not
  # changing how it was in the original source because I didn't have
  # time to check.
  return qr/(?:MySQL server has gone away|Lost connection to MySQL server during query)/i;
}


sub prepare_table {
  my $self = shift;
  $self->_number_of_params; # prepopulate
  my $tbl = $self->table_name;
  my ($key_col, $key_type, $ainc_col, $ainc_type, $v_cols, $v_types)
    = map $self->$_,
      qw(key_col_name key_col_type
         auto_increment_col_name auto_increment_col_type
         value_col_names value_col_types);
  my @vcoldefs = map "$v_cols->[$_] $v_types->[$_]", 0..$#$v_cols;
  my $vcol_str = join ",\n", @vcoldefs;
  my $extra_indexes = $self->extra_indexes;
  if (not defined $extra_indexes or $extra_indexes !~ /\S/) {
    $extra_indexes = '';
  }
  else {
    $extra_indexes = ",\n$extra_indexes";
  }
  my $pk;
  my $ainc_col_spec = '';
  if (defined $ainc_col) {
    $pk = "PRIMARY KEY($ainc_col),\n"
          . "UNIQUE KEY ($key_col)";
    $ainc_col_spec = "$ainc_col $ainc_type,";
  }
  else {
    $pk = "PRIMARY KEY($key_col)";
  }
  my $q = qq{
      CREATE TABLE IF NOT EXISTS $tbl (
        $ainc_col_spec
        $key_col $key_type,
        $vcol_str,
        $pk
        $extra_indexes
      ) ENGINE=InnoDb
  };

  my $logger = $self->logger;
  $logger->info("Creating shard storage table:\n$q") if $logger;

  $self->mysql_connection->do($q);
}


# Might not reconnect if the mysql_connector code ref just returns
# a cached connection.
sub refresh_connection {
  my $self = shift;

  my $logger = $self->logger;
  $logger->info("Refreshing mysql connection") if $logger;

  $self->clear_mysql_connection;
  return $self->mysql_connection;
}

sub _run_sql {
  my ($self, $method, $query, @args) = @_;

  my $iconn;
  my $rv;
  my $refresh_mysql_connection_on_error_regex = $self->{refresh_mysql_connection_on_error_regex};
  while (1) {
    my $dbh = $self->mysql_connection;
    eval {
      $rv = $dbh->$method($query, @args);
      1;
    } or do {
      my $error = $@ || "Zombie Error";
      ++$iconn;
      if (defined $refresh_mysql_connection_on_error_regex
          and $error =~ $refresh_mysql_connection_on_error_regex
          and $iconn <= $self->max_num_reconnect_attempts)
      {
        sleep($self->reconnect_interval * 2 ** ($iconn-2)) if $iconn > 1;
        $self->refresh_connection;
        redo;
      }
      Carp::confess("Despite trying hard: $error");
    };
    last;
  }

  return $rv;
}

sub get {
  my ($self, $key) = @_;
  my $rv;
  eval {
    $rv = $self->_run_sql('selectall_arrayref', $self->_get_query, undef, $key);
    1;
  } or do {
    my $error = $@ || "Zombie Error";
    my $endpoint = $self->mysql_endpoint->();
    ShardedKV::Error::ReadFail->throw({
      endpoint => $endpoint,
      key => $key,
      storage_type => 'mysql',
      message => "Failed to fetch key ($key) from MySQL ($endpoint): $error, ${\$DBI::errstr} ",
    });
  };
  return ref($rv) ? $rv->[0] : undef;
}

sub set {
  my ($self, $key, $value_ref) = @_;

  Carp::croak("Need exactly " . ($self->{_number_of_params}-1) . " values, got " . scalar(@$value_ref))
    if not scalar(@$value_ref) == $self->_number_of_params-1;
  
  my $rv;
  eval {
    $rv = $self->_run_sql('do', $self->_set_query, undef, $key, @$value_ref);
    1;
  } or do {
    my $error = $@ || "Zombie Error";
    my $endpoint = $self->mysql_endpoint->();
    ShardedKV::Error::ReadFail->throw({
      endpoint => $endpoint,
      key => $key,
      storage_type => 'mysql',
      message => "Failed to fetch key ($key) from MySQL ($endpoint): $error, ${\$DBI::errstr}",
    });
  };
  return $rv ? 1 : 0;
}

sub delete {
  my ($self, $key) = @_;
  my $rv;
  eval {
    $rv = $self->_run_sql('do', $self->_delete_query, undef, $key);
    1;
  } or do {
    my $error = $@ || "Zombie Error";
    my $endpoint = $self->mysql_endpoint->();
    ShardedKV::Error::DeleteFail->throw({
      endpoint => $endpoint,
      key => $key,
      storage_type => 'mysql',
      message => "Failed to delete key ($key) to MySQL ($endpoint): $error, ${\$DBI::errstr}",
    });
  };
  return $rv ? 1 : 0;
}

sub reset_connection {
  my ($self) = @_;
  $self->clear_mysql_connection();
}

no Moose;
__PACKAGE__->meta->make_immutable;

=pod

=head1 NAME

ShardedKV::Storage::MySQL - MySQL storage backend for ShardedKV

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  use ShardedKV;
  use ShardedKV::Storage::MySQL;
  ... create ShardedKV...
  my $storage = ShardedKV::Storage::MySQL->new(
  );
  ... put storage into ShardedKV...
  
  # values are array references
  $skv->set("foo", ["bar"]);
  my $value_ref = $skv->get("foo");

=head1 DESCRIPTION

A C<ShardedKV> storage backend that C<DBI> and C<DBD::mysql> to
store data in a MySQL table.

Implements the C<ShardedKV::Storage> role.

Each shard (== C<ShardedKV::Storage::MySQL> object) is represented by a
single table in some schema on some database server.

=head1 PUBLIC ATTRIBUTES

=head2 mysql_connector

A callback that must be supplied at object creation time. The storage
object will invoke the callback whenever it needs to get a NEW mysql
database handle. This means when:

  - first connecting
  - Error matches refresh_mysql_connection_on_error_regex => reconnect

The callback allows users to hook into the connection logic to implement
things such as connection caching. If you do use connection caching, then
do assert that the dbh is alive (eg. using C<$dbh-E<gt>ping()> before
returning a cached connection.

=head2 mysql_endpoint

A callback that should return a unique string that represents the endpoint. In
most cases this should be a hostname to allow for debugging connection issues.

The callback allows users to hook into the connection logic and update the
string that represents the particular endpoint that this storage instance
represents.

=head2 mysql_connection

This is the public attribute holding a MySQL database handle (which was
created using the C<mysql_connector>). Do not supply this at object
creation.

=head2 table_name

The name of the table that represents this shard.
Must be supplied at object creation.

=head2 key_col_name

The name of the column to be used for the key.
If C<ShardedKV::Storage::MySQL> creates the shard table for you, then
this column is also used as the primary key unless
C<auto_increment_col_name> is set (see below).

There can only be one key column.

Defaults to 'keystr'.

=head2 key_col_type

The MySQL type of the key column.

Defaults to 'VARBINARY(16) NOT NULL'.

=head2 auto_increment_col_name

The name of the column to be used for the auto-increment pimrary key.
This is a virtually unused (by ShardedKV) column that, IF DEFINED, will
be used as an auto-increment primary key. It is not the column used to
fetch rows by, but rather facilitates faster insertion of new records
by allowing append instead of insertion at random order within the PK
tree.

If C<ShardedKV::Storage::MySQL> creates the shard table for you, then
this column is also used as the primary key.

There can only be one auto-increment key column.

Defaults to 'id'.

=head2 auto_increment_col_type

The MySQL type of the auto increment column.

Defaults to 'BIGINT UNSIGNED NOT NULL AUTO_INCREMENT'.

=head2 value_col_names

An array reference containing the names of all value columns in
the shard table. Needs to contain at least one value column.

Defaults to C<[qw(val last_change)]>.

=head2 value_col_types

An array reference containing the MySQL types of each value column
given in C<value_col_names>.

Defaults to: C<['MEDIUMBLOB NOT NULL', 'TIMESTAMP NOT NULL']>.

=head2 extra_indexes

A string that is included verbatim after the PRIMARY KEY line of the
CREATE TABLE IF NOT EXISTS statement that this class generates. This can be
used to add additional indexes to the shard tables, such as indexes on the
last modification (for expiration from the database, not handled by ShardedKV).

=head2 max_num_reconnect_attempts

The maximum number of reconnect attempts that the storage object
should perform if the MySQL server has gone away.
Reconnects are done with exponential back-off (see below).

Defaults to 5.

=head2 reconnect_interval

The base interval for reconnection attempts. Do note that
exponential reconnect back-off is used, so if the base reconnect_interval
is 1 second, then the first reconnect attempt is done immediately,
the second after one second, the third after two seconds, the fourth
after four seconds, and so on.

Default: 1 second

Can also be fractional seconds.

=head2 refresh_mysql_connection_on_error_regex

A regular expression that we'll match MySQL errors against, if it
matches the error is considered recoverable and we'll refresh the
connection. Set to C<Undef> to disable this feature.

Default: Matches "MySQL server has gone away" and "Lost connection to
MySQL server during query" errors. See the source.

=head1 PUBLIC METHODS

=head2 prepare_table

This method will generate a C<CREATE TABLE> statement from the
various properties of the storage object and execute it on the MySQL
server to prepare the shard table.

=head2 refresh_connection

Explicitly drops the MySQL connection object and calls back into
the provided connect handler to get a new connection.

=head1 SEE ALSO

=over 4

=item *

L<ShardedKV>

=item *

L<ShardedKV::Storage>

=item *

L<DBI>

=item *

L<DBD::mysql>

=back

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
