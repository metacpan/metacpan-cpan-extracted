#  Copyright 2015 - present MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

use strict;
use warnings;
package MongoDB::IndexView;

# ABSTRACT: Index management for a collection

use version;
our $VERSION = 'v2.2.2';

use Moo;
use MongoDB::Error;
use MongoDB::Op::_CreateIndexes;
use MongoDB::Op::_DropIndexes;
use MongoDB::ReadPreference;
use MongoDB::_Types qw(
    BSONCodec
    IxHash
    is_IndexModelList
    is_OrderedDoc
);
use Types::Standard qw(
    InstanceOf
    Str
    is_Str
);
use boolean;
use namespace::clean -except => 'meta';

#pod =attr collection
#pod
#pod The L<MongoDB::Collection> for which indexes are being created or viewed.
#pod
#pod =cut

#--------------------------------------------------------------------------#
# constructor attributes
#--------------------------------------------------------------------------#

has collection => (
    is       => 'ro',
    isa      => InstanceOf( ['MongoDB::Collection'] ),
    required => 1,
);

#--------------------------------------------------------------------------#
# private attributes
#--------------------------------------------------------------------------#

has _bson_codec => (
    is      => 'lazy',
    isa     => BSONCodec,
    builder => '_build__bson_codec',
);

sub _build__bson_codec {
    my ($self) = @_;
    return $self->collection->bson_codec->clone( ordered => 1 );
}

has _client => (
    is      => 'lazy',
    isa     => InstanceOf( ['MongoDB::MongoClient'] ),
    builder => '_build__client',
);

sub _build__client {
    my ($self) = @_;
    return $self->collection->client;
}

has _coll_name => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build__coll_name',
);

sub _build__coll_name {
    my ($self) = @_;
    return $self->collection->name;
}

has _db_name => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build__db_name',
);

sub _build__db_name {
    my ($self) = @_;
    return $self->collection->database->name;
}

has _write_concern => (
    is      => 'lazy',
    isa     => InstanceOf( ['MongoDB::WriteConcern'] ),
    builder => '_build__write_concern',
);

sub _build__write_concern {
    my ($self) = @_;
    return $self->collection->write_concern;
}

#--------------------------------------------------------------------------#
# public methods
#--------------------------------------------------------------------------#

#pod =method list
#pod
#pod     $result = $indexes->list;
#pod
#pod     while ( my $index = $result->next ) {
#pod         ...
#pod     }
#pod
#pod     for my $index ( $result->all ) {
#pod         ...
#pod     }
#pod
#pod This method returns a L<MongoDB::QueryResult> which can be used to
#pod retrieve index information either one at a time (with C<next>) or
#pod all at once (with C<all>).
#pod
#pod If the list can't be retrieved, an exception will be thrown.
#pod
#pod =cut

my $list_args;

sub list {
    my ($self) = @_;

    my $op = MongoDB::Op::_ListIndexes->_new(
        client              => $self->_client,
        db_name             => $self->_db_name,
        full_name           => '',                                # unused
        coll_name           => $self->_coll_name,
        bson_codec          => $self->_bson_codec,
        monitoring_callback => $self->_client->monitoring_callback,
        read_preference     => MongoDB::ReadPreference->new( mode => 'primary' ),
        session             => $self->_client->_maybe_get_implicit_session,
    );

    return $self->_client->send_retryable_read_op($op);
}

#pod =method create_one
#pod
#pod     $name = $indexes->create_one( [ x => 1 ] );
#pod     $name = $indexes->create_one( [ x => 1, y => 1 ] );
#pod     $name = $indexes->create_one( [ z => 1 ], { unique => 1 } );
#pod
#pod This method takes an ordered index specification document and an optional
#pod hash reference of index options and returns the name of the index created.
#pod It will throw an exception on error.
#pod
#pod The index specification document is an ordered document (array reference,
#pod L<Tie::IxHash> object, or single-key hash reference) with index keys and
#pod direction/type.
#pod
#pod See L</create_many> for important information about index specifications
#pod and options.
#pod
#pod The following additional options are recognized:
#pod
#pod =for :list
#pod * C<maxTimeMS> — maximum time in milliseconds before the operation will
#pod   time out.
#pod
#pod =cut

my $create_one_args;

sub create_one {
    my ( $self, $keys, $opts ) = @_;

    MongoDB::UsageError->throw("Argument to create_one must be an ordered document")
      unless is_OrderedDoc($keys);

    my $global_opts = {};
    if (exists $opts->{maxTimeMS}) {
        $global_opts->{maxTimeMS} = delete $opts->{maxTimeMS};
    }

    my ($name) = $self->create_many(
        { keys => $keys, ( $opts ? ( options => $opts ) : () ) },
        $global_opts,
    );
    return $name;
}

#pod =method create_many
#pod
#pod     @names = $indexes->create_many(
#pod         { keys => [ x => 1, y => 1 ] },
#pod         { keys => [ z => 1 ], options => { unique => 1 } }
#pod     );
#pod
#pod     @names = $indexes->create_many(
#pod         { keys => [ x => 1, y => 1 ] },
#pod         { keys => [ z => 1 ], options => { unique => 1 } }
#pod         \%global_options,
#pod     );
#pod
#pod This method takes a list of index models (given as hash references)
#pod and returns a list of index names created.  It will throw an exception
#pod on error.
#pod
#pod If the last value is a hash reference without a C<keys> entry, it will
#pod be assumed to be a set of global options. See below for a list of
#pod accepted global options.
#pod
#pod Each index module is described by the following fields:
#pod
#pod =for :list
#pod * C<keys> (required) — an index specification as an ordered document (array
#pod   reference, L<Tie::IxHash> object, or single-key hash reference)
#pod   with index keys and direction/type.  See below for more.
#pod * C<options> — an optional hash reference of index options.
#pod
#pod The C<keys> document needs to be ordered.  You are B<STRONGLY> encouraged
#pod to get in the habit of specifying index keys with an array reference.
#pod Because Perl randomizes the order of hash keys, you may B<ONLY> use a hash
#pod reference if it contains a single key.
#pod
#pod The form of the C<keys> document differs based on the type of index (e.g.
#pod single-key, multi-key, text, geospatial, etc.).
#pod
#pod For single and multi-key indexes, the value is "1" for an ascending index
#pod and "-1" for a descending index.
#pod
#pod     [ name => 1, votes => -1 ] # ascending on name, descending on votes
#pod
#pod See L<Index Types|http://docs.mongodb.org/manual/core/index-types/> in the
#pod MongoDB Manual for instructions for other index types.
#pod
#pod The C<options> hash reference may have a mix of general-purpose and
#pod index-type-specific options.  See L<Index
#pod Options|http://docs.mongodb.org/manual/reference/method/db.collection.createIndex/#options>
#pod in the MongoDB Manual for specifics.
#pod
#pod Some of the more commonly used options include:
#pod
#pod =for :list
#pod * C<background> — when true, index creation won't block but will run in the
#pod   background; this is strongly recommended to avoid blocking other
#pod   operations on the database.
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<unique> — enforce uniqueness when true; inserting a duplicate document
#pod   (or creating one with update modifiers) will raise an error.
#pod * C<name> — a name (string) for the index; one will be generated if this is
#pod   omitted.
#pod
#pod Global options specified as the last value can contain the following
#pod keys:
#pod
#pod =for :list
#pod * C<maxTimeMS> — maximum time in milliseconds before the operation will
#pod   time out.
#pod
#pod =cut

my $create_many_args;

sub create_many {
    my ( $self, @models ) = @_;

    my $opts;
    if (@models and ref $models[-1] eq 'HASH' and not exists $models[-1]{keys}) {
        $opts = pop @models;
    }

    MongoDB::UsageError->throw("Argument to create_many must be a list of index models")
      unless is_IndexModelList(\@models);

    my $indexes = [ map __flatten_index_model($_), @models ];
    my $op = MongoDB::Op::_CreateIndexes->_new(
        db_name             => $self->_db_name,
        coll_name           => $self->_coll_name,
        full_name           => '',                                # unused
        bson_codec          => $self->_bson_codec,
        indexes             => $indexes,
        write_concern       => $self->_write_concern,
        monitoring_callback => $self->_client->monitoring_callback,
        (defined($opts->{maxTimeMS})
            ? (max_time_ms   => $opts->{maxTimeMS})
            : ()
        ),
    );

    # succeed or die; we don't care about response document
    $self->_client->send_write_op($op);

    return map $_->{name}, @$indexes;
}

#pod =method drop_one
#pod
#pod     $output = $indexes->drop_one( $name );
#pod     $output = $indexes->drop_one( $name, \%options );
#pod
#pod This method takes the name of an index and drops it.  It returns the output
#pod of the dropIndexes command (a hash reference) on success or throws a
#pod exception if the command errors.  However, if the index does not exist, the
#pod command output will have the C<ok> field as a false value, but no exception
#pod will e thrown.
#pod
#pod Valid options are:
#pod
#pod =for :list
#pod * C<maxTimeMS> — maximum time in milliseconds before the operation will
#pod   time out.
#pod
#pod =cut

my $drop_one_args;

sub drop_one {
    my ( $self, $name, $opts ) = @_;

    MongoDB::UsageError->throw("Argument to drop_one must be a string")
      unless is_Str($name);

    if ( $name eq '*' ) {
        MongoDB::UsageError->throw("Can't use '*' as an argument to drop_one");
    }

    my $op = MongoDB::Op::_DropIndexes->_new(
        db_name             => $self->_db_name,
        coll_name           => $self->_coll_name,
        full_name           => '',                                 # unused
        bson_codec          => $self->_bson_codec,
        write_concern       => $self->_write_concern,
        index_name          => $name,
        monitoring_callback => $self->_client->monitoring_callback,
        (defined($opts->{maxTimeMS})
            ? (max_time_ms   => $opts->{maxTimeMS})
            : ()
        ),
    );

    $self->_client->send_write_op($op)->output;
}

#pod =method drop_all
#pod
#pod     $output = $indexes->drop_all;
#pod     $output = $indexes->drop_all(\%options);
#pod
#pod This method drops all indexes (except the one on the C<_id> field).  It
#pod returns the output of the dropIndexes command (a hash reference) on success
#pod or throws a exception if the command fails.
#pod
#pod Valid options are:
#pod
#pod =for :list
#pod * C<maxTimeMS> — maximum time in milliseconds before the operation will
#pod   time out.
#pod
#pod =cut

my $drop_all_args;

sub drop_all {
    my ($self, $opts) = @_;

    my $op = MongoDB::Op::_DropIndexes->_new(
        db_name             => $self->_db_name,
        coll_name           => $self->_coll_name,
        full_name           => '',                                 # unused
        bson_codec          => $self->_bson_codec,
        write_concern       => $self->_write_concern,
        index_name          => '*',
        monitoring_callback => $self->_client->monitoring_callback,
        (defined($opts->{maxTimeMS})
            ? (max_time_ms   => $opts->{maxTimeMS})
            : ()
        ),
    );

    $self->_client->send_write_op($op)->output;
}

#--------------------------------------------------------------------------#
# private functions
#--------------------------------------------------------------------------#

sub __flatten_index_model {
    my ($model) = @_;

    my ( $keys, $orig ) = @{$model}{qw/keys options/};

    $keys = IxHash->coerce($keys);

    # copy the original so we don't modify it
    my $opts = { $orig ? %$orig : () };

    for my $k (qw/keys key/) {
        MongoDB::UsageError->throw("Can't specify '$k' in options to index creation")
          if exists $opts->{$k};
    }

    # add name if not provided
    $opts->{name} = __to_index_string($keys)
      unless defined $opts->{name};

    # convert some things to booleans
    for my $k (qw/unique background sparse dropDups/) {
        next unless exists $opts->{$k};
        $opts->{$k} = boolean( $opts->{$k} );
    }

    # return is document ready for the createIndexes command
    return { key => $keys, %$opts };
}

# utility function to generate an index name by concatenating key/value pairs
sub __to_index_string {
    my $keys = shift;

    if ( ref $keys eq 'Tie::IxHash' ) {
        my @name;
        my @ks = $keys->Keys;
        my @vs = $keys->Values;

        for ( my $i = 0; $i < $keys->Length; $i++ ) {
            push @name, $ks[$i];
            push @name, $vs[$i];
        }

        return join( "_", @name );
    }
    else {
        MongoDB::InternalError->throw("expected Tie::IxHash for __to_index_string");
    }

}


1;


# vim: set ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::IndexView - Index management for a collection

=head1 VERSION

version v2.2.2

=head1 SYNOPSIS

    my $indexes = $collection->indexes;

    # listing indexes

    @names = map { $_->{name} } $indexes->list->all;

    my $result = $indexes->list;

    while ( my $index_doc = $result->next ) {
        # do stuff with each $index_doc
    }

    # creating indexes

    $name = $indexes->create_one( [ x => 1, y => -1 ], { unique => 1 } );

    @names = $indexes->create_many(
        { keys => [ x => 1, y => -1 ], options => { unique => 1 } },
        { keys => [ z => 1 ] },
    );

    # dropping indexes

    $indexes->drop_one( "x_1_y_-1" );

    $indexes->drop_all;

=head1 DESCRIPTION

This class models the indexes on a L<MongoDB::Collection> so you can
create, list or drop them.

For more on MongoDB indexes, see the L<MongoDB Manual pages on
indexing|http://docs.mongodb.org/manual/core/indexes/>

=head1 ATTRIBUTES

=head2 collection

The L<MongoDB::Collection> for which indexes are being created or viewed.

=head1 METHODS

=head2 list

    $result = $indexes->list;

    while ( my $index = $result->next ) {
        ...
    }

    for my $index ( $result->all ) {
        ...
    }

This method returns a L<MongoDB::QueryResult> which can be used to
retrieve index information either one at a time (with C<next>) or
all at once (with C<all>).

If the list can't be retrieved, an exception will be thrown.

=head2 create_one

    $name = $indexes->create_one( [ x => 1 ] );
    $name = $indexes->create_one( [ x => 1, y => 1 ] );
    $name = $indexes->create_one( [ z => 1 ], { unique => 1 } );

This method takes an ordered index specification document and an optional
hash reference of index options and returns the name of the index created.
It will throw an exception on error.

The index specification document is an ordered document (array reference,
L<Tie::IxHash> object, or single-key hash reference) with index keys and
direction/type.

See L</create_many> for important information about index specifications
and options.

The following additional options are recognized:

=over 4

=item *

C<maxTimeMS> — maximum time in milliseconds before the operation will time out.

=back

=head2 create_many

    @names = $indexes->create_many(
        { keys => [ x => 1, y => 1 ] },
        { keys => [ z => 1 ], options => { unique => 1 } }
    );

    @names = $indexes->create_many(
        { keys => [ x => 1, y => 1 ] },
        { keys => [ z => 1 ], options => { unique => 1 } }
        \%global_options,
    );

This method takes a list of index models (given as hash references)
and returns a list of index names created.  It will throw an exception
on error.

If the last value is a hash reference without a C<keys> entry, it will
be assumed to be a set of global options. See below for a list of
accepted global options.

Each index module is described by the following fields:

=over 4

=item *

C<keys> (required) — an index specification as an ordered document (array reference, L<Tie::IxHash> object, or single-key hash reference) with index keys and direction/type.  See below for more.

=item *

C<options> — an optional hash reference of index options.

=back

The C<keys> document needs to be ordered.  You are B<STRONGLY> encouraged
to get in the habit of specifying index keys with an array reference.
Because Perl randomizes the order of hash keys, you may B<ONLY> use a hash
reference if it contains a single key.

The form of the C<keys> document differs based on the type of index (e.g.
single-key, multi-key, text, geospatial, etc.).

For single and multi-key indexes, the value is "1" for an ascending index
and "-1" for a descending index.

    [ name => 1, votes => -1 ] # ascending on name, descending on votes

See L<Index Types|http://docs.mongodb.org/manual/core/index-types/> in the
MongoDB Manual for instructions for other index types.

The C<options> hash reference may have a mix of general-purpose and
index-type-specific options.  See L<Index
Options|http://docs.mongodb.org/manual/reference/method/db.collection.createIndex/#options>
in the MongoDB Manual for specifics.

Some of the more commonly used options include:

=over 4

=item *

C<background> — when true, index creation won't block but will run in the background; this is strongly recommended to avoid blocking other operations on the database.

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<unique> — enforce uniqueness when true; inserting a duplicate document (or creating one with update modifiers) will raise an error.

=item *

C<name> — a name (string) for the index; one will be generated if this is omitted.

=back

Global options specified as the last value can contain the following
keys:

=over 4

=item *

C<maxTimeMS> — maximum time in milliseconds before the operation will time out.

=back

=head2 drop_one

    $output = $indexes->drop_one( $name );
    $output = $indexes->drop_one( $name, \%options );

This method takes the name of an index and drops it.  It returns the output
of the dropIndexes command (a hash reference) on success or throws a
exception if the command errors.  However, if the index does not exist, the
command output will have the C<ok> field as a false value, but no exception
will e thrown.

Valid options are:

=over 4

=item *

C<maxTimeMS> — maximum time in milliseconds before the operation will time out.

=back

=head2 drop_all

    $output = $indexes->drop_all;
    $output = $indexes->drop_all(\%options);

This method drops all indexes (except the one on the C<_id> field).  It
returns the output of the dropIndexes command (a hash reference) on success
or throws a exception if the command fails.

Valid options are:

=over 4

=item *

C<maxTimeMS> — maximum time in milliseconds before the operation will time out.

=back

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
