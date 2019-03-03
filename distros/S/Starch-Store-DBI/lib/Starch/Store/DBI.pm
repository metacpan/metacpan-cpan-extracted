package Starch::Store::DBI;
use 5.008001;
use strictures 2;
our $VERSION = '0.04';

=head1 NAME

Starch::Store::DBI - Starch storage backend using DBI.

=head1 SYNOPSIS

    my $starch = Starch->new(
        store => {
            class => '::DBI',
            dbh => [
                $dsn,
                $username,
                $password,
                { RaiseError=>1, AutoCommit=>1 },
            ],
        },
    );

=head1 DESCRIPTION

This L<Starch> store uses L<DBI> to set and get state data.

Consider using L<Starch::Store::DBIx::Connector> instead
of this store as L<DBIx::Connector> provides superior re-connection
and transaction handling capabilities.

The table in your database should contain three columns.  This
is the SQLite syntax for creating a compatible table which you
can modify to work for your particular database's syntax:

    CREATE TABLE starch_states (
        key TEXT NOT NULL PRIMARY KEY,
        data TEXT NOT NULL,
        expiration INTEGER NOT NULL
    )

=cut

use DBI;
use Types::Standard -types;
use Types::Common::String -types;
use Scalar::Util qw( blessed );
use Data::Serializer::Raw;

use Moo;
use namespace::clean;

with qw(
    Starch::Store
);

=head1 REQUIRED ARGUMENTS

=head2 dbh

This must be set to either array ref arguments for L<DBI/connect>
or a pre-built object (often retrieved using a method proxy).

When configuring Starch from static configuration files using a
L<method proxy|Starch/METHOD PROXIES>
is a good way to link your existing L<DBI> object constructor
in with Starch so that starch doesn't build its own.

=cut

has _dbh_arg => (
    is       => 'ro',
    isa      => (InstanceOf[ 'DBI::db' ]) | ArrayRef,
    init_arg => 'dbh',
    required => 1,
);

has dbh => (
    is       => 'lazy',
    isa      => InstanceOf[ 'DBI::db' ],
    init_arg => undef,
);
sub _build_dbh {
    my ($self) = @_;

    my $dbh = $self->_dbh_arg();
    return $dbh if blessed $dbh;

    return DBI->connect( @$dbh );
}

=head1 OPTIONAL ARGUMENTS

=head2 serializer

A L<Data::Serializer::Raw> for serializing the state data for storage
in the L</data_column>.  Can be specified as string containing the
serializer name, a hash ref of Data::Serializer::Raw arguments, or as a
pre-created Data::Serializer::Raw object.  Defaults to C<JSON>.

Consider using the C<JSON::XS> or C<Sereal> serializers for speed.

C<Sereal> will likely be the fastest and produce the most compact data.

=cut

has _serializer_arg => (
    is       => 'ro',
    isa      => ((InstanceOf[ 'Data::Serializer::Raw' ]) | HashRef) | NonEmptySimpleStr,
    init_arg => 'serializer',
    default  => 'JSON',
);

has serializer => (
    is       => 'lazy',
    isa      => InstanceOf[ 'Data::Serializer::Raw' ],
    init_arg => undef,
);
sub _build_serializer {
    my ($self) = @_;

    my $serializer = $self->_serializer_arg();
    return $serializer if blessed $serializer;

    if (ref $serializer) {
        return Data::Serializer::Raw->new( %$serializer );
    }

    return Data::Serializer::Raw->new(
        serializer => $serializer,
    );
}

=head2 table

The table name where states are stored in the database.
Defaults to C<starch_states>.

=cut

has table => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'starch_states',
);

=head2 key_column

The column in the L</table> where the state ID is stored.
Defaults to C<key>.

=cut

has key_column => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'key',
);

=head2 data_column

The column in the L</table> which will hold the state
data.  Defaults to C<data>.

=cut

has data_column => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'data',
);

=head2 expiration_column

The column in the L</table> which will hold the epoch time
when the state should be expired.  Defaults to C<expiration>.

=cut

has expiration_column => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => 'expiration',
);

=head1 ATTRIBUTES

=head2 insert_sql

The SQL used to create state data.

=cut

has insert_sql => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);
sub _build_insert_sql {
    my ($self) = @_;

    return sprintf(
        'INSERT INTO %s (%s, %s, %s) VALUES (?, ?, ?)',
        $self->table(),
        $self->key_column(),
        $self->data_column(),
        $self->expiration_column(),
    );
}

=head2 update_sql

The SQL used to update state data.

=cut

has update_sql => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);
sub _build_update_sql {
    my ($self) = @_;

    return sprintf(
        'UPDATE %s SET %s=?, %s=? WHERE %s=?',
        $self->table(),
        $self->data_column(),
        $self->expiration_column(),
        $self->key_column(),
    );
}

=head2 exists_sql

The SQL used to confirm whether state data already exists.

=cut

has exists_sql => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);
sub _build_exists_sql {
    my ($self) = @_;

    return sprintf(
        'SELECT 1 FROM %s WHERE %s = ?',
        $self->table(),
        $self->key_column(),
    );
}

=head2 select_sql

The SQL used to retrieve state data.

=cut

has select_sql => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);
sub _build_select_sql {
    my ($self) = @_;

    return sprintf(
        'SELECT %s, %s FROM %s WHERE %s = ?',
        $self->data_column(),
        $self->expiration_column(),
        $self->table(),
        $self->key_column(),
    );
}

=head2 delete_sql

The SQL used to delete state data.

=cut

has delete_sql => (
    is       => 'lazy',
    isa      => NonEmptyStr,
    init_arg => undef,
);
sub _build_delete_sql {
    my ($self) = @_;

    return sprintf(
        'DELETE FROM %s WHERE %s = ?',
        $self->table(),
        $self->key_column(),
    );
}

=head1 METHODS

=head2 set

Set L<Starch::Store/set>.

=head2 get

Set L<Starch::Store/get>.

=head2 remove

Set L<Starch::Store/remove>.

=cut

sub set {
    my ($self, $id, $namespace, $data, $expires) = @_;

    my $key = $self->stringify_key( $id, $namespace );

    my $dbh = $self->dbh();

    my $sth = $dbh->prepare_cached(
        $self->exists_sql(),
    );

    my ($exists) = $dbh->selectrow_array( $sth, undef, $key );

    $data = $self->serializer->serialize( $data );
    $expires += time();

    if ($exists) {
        my $sth = $self->dbh->prepare_cached(
            $self->update_sql(),
        );

        $sth->execute( $data, $expires, $key );
    }
    else {
        my $sth = $self->dbh->prepare_cached(
            $self->insert_sql(),
        );

        $sth->execute( $key, $data, $expires );
    }

    return;
}

sub get {
    my ($self, $id, $namespace) = @_;

    my $key = $self->stringify_key( $id, $namespace );

    my $dbh = $self->dbh();

    my $sth = $dbh->prepare_cached(
        $self->select_sql(),
    );

    my ($data, $expiration) = $dbh->selectrow_array( $sth, undef, $key );

    return undef if !defined $data;

    if ($expiration and $expiration < time()) {
        $self->remove( $id, $namespace );
        return undef;
    }

    return $self->serializer->deserialize( $data );
}

sub remove {
    my ($self, $id, $namespace) = @_;

    my $key = $self->stringify_key( $id, $namespace );

    my $dbh = $self->dbh();

    my $sth = $dbh->prepare_cached(
        $self->delete_sql(),
    );

    $sth->execute( $key );

    return;
}

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Starch-Store-DBI GitHub issue tracker:

L<https://github.com/bluefeet/Starch-Store-DBI/issues>

=head1 AUTHORS

    Aran Clary Deltac <bluefeet@gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

