#
#  Copyright 2009-2013 MongoDB, Inc.
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
#

use strict;
use warnings;
package MongoDB::Collection;


# ABSTRACT: A MongoDB Collection

use version;
our $VERSION = 'v1.8.1';

use MongoDB::Error;
use MongoDB::IndexView;
use MongoDB::InsertManyResult;
use MongoDB::QueryResult;
use MongoDB::WriteConcern;
use MongoDB::Op::_Aggregate;
use MongoDB::Op::_BatchInsert;
use MongoDB::Op::_BulkWrite;
use MongoDB::Op::_Count;
use MongoDB::Op::_CreateIndexes;
use MongoDB::Op::_Delete;
use MongoDB::Op::_Distinct;
use MongoDB::Op::_DropCollection;
use MongoDB::Op::_FindAndDelete;
use MongoDB::Op::_FindAndUpdate;
use MongoDB::Op::_InsertOne;
use MongoDB::Op::_ListIndexes;
use MongoDB::Op::_ParallelScan;
use MongoDB::Op::_RenameCollection;
use MongoDB::Op::_Query;
use MongoDB::Op::_Update;
use MongoDB::_Types qw(
    BSONCodec
    NonNegNum
    ReadPreference
    ReadConcern
    WriteConcern
);
use Types::Standard qw(
    HashRef
    InstanceOf
    Str
);
use Tie::IxHash;
use Carp 'carp';
use boolean;
use Safe::Isa;
use Scalar::Util qw/blessed reftype/;
use Try::Tiny;
use Moo;
use namespace::clean -except => 'meta';

#--------------------------------------------------------------------------#
# constructor attributes
#--------------------------------------------------------------------------#

#pod =attr database
#pod
#pod The L<MongoDB::Database> representing the database that contains
#pod the collection.
#pod
#pod =cut

has database => (
    is       => 'ro',
    isa      => InstanceOf['MongoDB::Database'],
    required => 1,
);

#pod =attr name
#pod
#pod The name of the collection.
#pod
#pod =cut

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

#pod =attr read_preference
#pod
#pod A L<MongoDB::ReadPreference> object.  It may be initialized with a string
#pod corresponding to one of the valid read preference modes or a hash reference
#pod that will be coerced into a new MongoDB::ReadPreference object.
#pod By default it will be inherited from a L<MongoDB::Database> object.
#pod
#pod =cut

has read_preference => (
    is       => 'ro',
    isa      => ReadPreference,
    required => 1,
    coerce   => ReadPreference->coercion,
);

#pod =attr write_concern
#pod
#pod A L<MongoDB::WriteConcern> object.  It may be initialized with a hash
#pod reference that will be coerced into a new MongoDB::WriteConcern object.
#pod By default it will be inherited from a L<MongoDB::Database> object.
#pod
#pod =cut

has write_concern => (
    is       => 'ro',
    isa      => WriteConcern,
    required => 1,
    coerce   => WriteConcern->coercion,
);

#pod =attr read_concern
#pod
#pod A L<MongoDB::ReadConcern> object.  May be initialized with a hash
#pod reference or a string that will be coerced into the level of read
#pod concern.
#pod
#pod By default it will be inherited from a L<MongoDB::Database> object.
#pod
#pod =cut

has read_concern => (
    is       => 'ro',
    isa      => ReadConcern,
    required => 1,
    coerce   => ReadConcern->coercion,
);

#pod =attr max_time_ms
#pod
#pod Specifies the default maximum amount of time in milliseconds that the
#pod server should use for working on a query.
#pod
#pod B<Note>: this will only be used for server versions 2.6 or greater, as that
#pod was when the C<$maxTimeMS> meta-operator was introduced.
#pod
#pod =cut

has max_time_ms => (
    is      => 'ro',
    isa     => NonNegNum,
    required => 1,
);

#pod =attr bson_codec
#pod
#pod An object that provides the C<encode_one> and C<decode_one> methods, such
#pod as from L<MongoDB::BSON>.  It may be initialized with a hash reference that
#pod will be coerced into a new MongoDB::BSON object.  By default it will be
#pod inherited from a L<MongoDB::Database> object.
#pod
#pod =cut

has bson_codec => (
    is       => 'ro',
    isa      => BSONCodec,
    coerce   => BSONCodec->coercion,
    required => 1,
);

#--------------------------------------------------------------------------#
# computed attributes
#--------------------------------------------------------------------------#

#pod =method client
#pod
#pod     $client = $coll->client;
#pod
#pod Returns the L<MongoDB::MongoClient> object associated with this
#pod object.
#pod
#pod =cut

has _client => (
    is      => 'lazy',
    isa     => InstanceOf['MongoDB::MongoClient'],
    reader  => 'client',
    init_arg => undef,
    builder => '_build__client',
);

sub _build__client {
    my ($self) = @_;
    return $self->database->_client;
}

#pod =method full_name
#pod
#pod     $full_name = $coll->full_name;
#pod
#pod Returns the full name of the collection, including the namespace of the
#pod database it's in prefixed with a dot character.  E.g. collection "foo" in
#pod database "test" would result in a C<full_name> of "test.foo".
#pod
#pod =cut

has _full_name => (
    is      => 'lazy',
    isa     => Str,
    reader  => 'full_name',
    init_arg => undef,
    builder => '_build__full_name',
);

sub _build__full_name {
    my ($self) = @_;
    my $name    = $self->name;
    my $db_name = $self->database->name;
    return "${db_name}.${name}";
}

#pod =method indexes
#pod
#pod     $indexes = $collection->indexes;
#pod
#pod     $collection->indexes->create_one( [ x => 1 ], { unique => 1 } );
#pod     $collection->indexes->drop_all;
#pod
#pod Returns a L<MongoDB::IndexView> object for managing the indexes associated
#pod with the collection.
#pod
#pod =cut

has _indexes => (
    is      => 'lazy',
    isa     => InstanceOf['MongoDB::IndexView'],
    reader  => 'indexes',
    init_arg => undef,
    builder => '_build__indexes',
);

sub _build__indexes {
    my ($self) = @_;
    return MongoDB::IndexView->new( collection => $self );
}

# these are constant, so we cache them
has _op_args => (
    is       => 'lazy',
    isa      => HashRef,
    init_arg => undef,
    builder  => '_build__op_args',
);

sub _build__op_args {
    my ($self) = @_;
    return {
        client          => $self->client,
        db_name         => $self->database->name,
        bson_codec      => $self->bson_codec,
        coll_name       => $self->name,
        write_concern   => $self->write_concern,
        read_concern    => $self->read_concern,
        read_preference => $self->read_preference,
        full_name       => join( ".", $self->database->name, $self->name ),
    };
}

with $_ for qw(
  MongoDB::Role::_DeprecationWarner
);

#--------------------------------------------------------------------------#
# public methods
#--------------------------------------------------------------------------#

#pod =method clone
#pod
#pod     $coll2 = $coll1->clone( write_concern => { w => 2 } );
#pod
#pod Constructs a copy of the original collection, but allows changing
#pod attributes in the copy.
#pod
#pod =cut

sub clone {
    my ($self, @args) = @_;
    my $class = ref($self);
    if ( @args == 1 && ref( $args[0] ) eq 'HASH' ) {
        return $class->new( %$self, %{$args[0]} );
    }

    return $class->new( %$self, @args );
}

#pod =method with_codec
#pod
#pod     $coll2 = $coll1->with_codec( $new_codec );
#pod     $coll2 = $coll1->with_codec( prefer_numeric => 1 );
#pod
#pod Constructs a copy of the original collection, but clones the C<bson_codec>.
#pod If given an object that does C<encode_one> and C<decode_one>, it is
#pod equivalent to:
#pod
#pod     $coll2 = $coll1->clone( bson_codec => $new_codec );
#pod
#pod If given a hash reference or a list of key/value pairs, it is equivalent
#pod to:
#pod
#pod     $coll2 = $coll1->clone(
#pod         bson_codec => $coll1->bson_codec->clone( @list )
#pod     );
#pod
#pod =cut

sub with_codec {
    my ( $self, @args ) = @_;
    if ( @args == 1 ) {
        my $arg = $args[0];
        if ( eval { $arg->can('encode_bson') && $arg->can('decode_bson') } ) {
            return $self->clone( bson_codec => $arg );
        }
        elsif ( ref $arg eq 'HASH' ) {
            return $self->clone( bson_codec => $self->bson_codec->clone(%$arg) );
        }
    }
    elsif ( @args % 2 == 0 ) {
        return $self->clone( bson_codec => $self->bson_codec->clone(@args) );
    }

    # fallthrough is argument error
    MongoDB::UsageError->throw(
        "argument to with_codec must be new codec, hashref or key/value pairs" );
}

#pod =method insert_one
#pod
#pod     $res = $coll->insert_one( $document );
#pod     $res = $coll->insert_one( $document, $options );
#pod     $id = $res->inserted_id;
#pod
#pod Inserts a single L<document|/Document> into the database and returns a
#pod L<MongoDB::InsertOneResult> or L<MongoDB::UnacknowledgedResult> object.
#pod
#pod If no C<_id> field is present, one will be added when a document is
#pod serialized for the database without modifying the original document.
#pod The generated C<_id> may be retrieved from the result object.
#pod
#pod An optional hash reference of options may be given.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod
#pod =cut

# args not unpacked for efficiency; args are self, document
sub insert_one {
    MongoDB::UsageError->throw("document argument must be a reference")
      unless ref( $_[1] );

    return $_[0]->client->send_write_op(
        MongoDB::Op::_InsertOne->_new(
            ( defined $_[2] ? (%{$_[2]}) : () ),
            document => $_[1],
            %{ $_[0]->_op_args },
        )
    );
}

#pod =method insert_many
#pod
#pod     $res = $coll->insert_many( [ @documents ] );
#pod     $res = $coll->insert_many( [ @documents ], { ordered => 0 } );
#pod
#pod Inserts each of the L<documents|/Documents> in an array reference into the
#pod database and returns a L<MongoDB::InsertManyResult> or
#pod L<MongoDB::UnacknowledgedResult>.  This is syntactic sugar for doing a
#pod L<MongoDB::BulkWrite> operation.
#pod
#pod If no C<_id> field is present, one will be added when a document is
#pod serialized for the database without modifying the original document.
#pod The generated C<_id> may be retrieved from the result object.
#pod
#pod An optional hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod * C<ordered> – when true, the server will halt insertions after the first
#pod   error (if any).  When false, all documents will be processed and any
#pod   error will only be thrown after all insertions are attempted.  The
#pod   default is true.
#pod
#pod On MongoDB servers before version 2.6, C<insert_many> bulk operations are
#pod emulated with individual inserts to capture error information.  On 2.6 or
#pod later, this method will be significantly faster than individual C<insert_one>
#pod calls.
#pod
#pod =cut

# args not unpacked for efficiency; args are self, document, options
sub insert_many {
    MongoDB::UsageError->throw("documents argument must be an array reference")
      unless ref( $_[1] ) eq 'ARRAY';

    my $res = $_[0]->client->send_write_op(
        MongoDB::Op::_BulkWrite->_new(
            # default
            ordered => 1,
            # user overrides
            ( defined $_[2] ? ( %{ $_[2] } ) : () ),
            # un-overridable
            queue => [ map { [ insert => $_ ] } @{ $_[1] } ],
            %{ $_[0]->_op_args },
        )
    );

    return $_[0]->write_concern->is_acknowledged
      ? MongoDB::InsertManyResult->_new(
        acknowledged         => 1,
        inserted             => $res->inserted,
        write_errors         => [],
        write_concern_errors => [],
      )
      : MongoDB::UnacknowledgedResult->_new(
        write_errors         => [],
        write_concern_errors => [],
      );
}

#pod =method delete_one
#pod
#pod     $res = $coll->delete_one( $filter );
#pod     $res = $coll->delete_one( { _id => $id } );
#pod     $res = $coll->delete_one( $filter, { collation => { locale => "en_US" } } );
#pod
#pod Deletes a single document that matches a L<filter expression|/Filter expression> and returns a
#pod L<MongoDB::DeleteResult> or L<MongoDB::UnacknowledgedResult> object.
#pod
#pod A hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod
#pod =cut

# args not unpacked for efficiency; args are self, filter, options
sub delete_one {
    MongoDB::UsageError->throw("filter argument must be a reference")
      unless ref( $_[1] );

    return $_[0]->client->send_write_op(
        MongoDB::Op::_Delete->_new(
            ( defined $_[2] ? (%{$_[2]}) : () ),
            filter   => $_[1],
            just_one => 1,
            %{ $_[0]->_op_args },
        )
    );
}

#pod =method delete_many
#pod
#pod     $res = $coll->delete_many( $filter );
#pod     $res = $coll->delete_many( { name => "Larry" } );
#pod     $res = $coll->delete_many( $filter, { collation => { locale => "en_US" } } );
#pod
#pod Deletes all documents that match a L<filter expression|/Filter expression>
#pod and returns a L<MongoDB::DeleteResult> or L<MongoDB::UnacknowledgedResult>
#pod object.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod
#pod =cut

# args not unpacked for efficiency; args are self, filter, options
sub delete_many {
    MongoDB::UsageError->throw("filter argument must be a reference")
      unless ref( $_[1] );

    return $_[0]->client->send_write_op(
        MongoDB::Op::_Delete->_new(
            ( defined $_[2] ? (%{$_[2]}) : () ),
            filter   => $_[1],
            just_one => 0,
            %{ $_[0]->_op_args },
        )
    );
}

#pod =method replace_one
#pod
#pod     $res = $coll->replace_one( $filter, $replacement );
#pod     $res = $coll->replace_one( $filter, $replacement, { upsert => 1 } );
#pod
#pod Replaces one document that matches a L<filter expression|/Filter
#pod expression> and returns a L<MongoDB::UpdateResult> or
#pod L<MongoDB::UnacknowledgedResult> object.
#pod
#pod The replacement document must not have any field-update operators in it (e.g.
#pod C<$set>).
#pod
#pod A hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<upsert> – defaults to false; if true, a new document will be added if one
#pod   is not found
#pod
#pod =cut

# args not unpacked for efficiency; args are self, filter, update, options
sub replace_one {
    MongoDB::UsageError->throw("filter and replace arguments must be references")
      unless ref( $_[1] ) && ref( $_[2] );

    return $_[0]->client->send_write_op(
        MongoDB::Op::_Update->_new(
            ( defined $_[3] ? (%{$_[3]}) : () ),
            filter     => $_[1],
            update     => $_[2],
            multi      => false,
            is_replace => 1,
            %{ $_[0]->_op_args },
        )
    );
}

#pod =method update_one
#pod
#pod     $res = $coll->update_one( $filter, $update );
#pod     $res = $coll->update_one( $filter, $update, { upsert => 1 } );
#pod
#pod Updates one document that matches a L<filter expression|/Filter expression>
#pod and returns a L<MongoDB::UpdateResult> or L<MongoDB::UnacknowledgedResult>
#pod object.
#pod
#pod The update document must have only field-update operators in it (e.g.
#pod C<$set>).
#pod
#pod A hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<upsert> – defaults to false; if true, a new document will be added if
#pod   one is not found by taking the filter expression and applying the update
#pod   document operations to it prior to insertion.
#pod
#pod =cut

# args not unpacked for efficiency; args are self, filter, update, options
sub update_one {
    MongoDB::UsageError->throw("filter and update arguments must be references")
      unless ref( $_[1] ) && ref( $_[2] );

    return $_[0]->client->send_write_op(
        MongoDB::Op::_Update->_new(
            ( defined $_[3] ? (%{$_[3]}) : () ),
            filter     => $_[1],
            update     => $_[2],
            multi      => false,
            is_replace => 0,
            %{ $_[0]->_op_args },
        )
    );
}

#pod =method update_many
#pod
#pod     $res = $coll->update_many( $filter, $update );
#pod     $res = $coll->update_many( $filter, $update, { upsert => 1 } );
#pod
#pod Updates one or more documents that match a L<filter expression|/Filter
#pod expression> and returns a L<MongoDB::UpdateResult> or
#pod L<MongoDB::UnacknowledgedResult> object.
#pod
#pod The update document must have only field-update operators in it (e.g.
#pod C<$set>).
#pod
#pod A hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<upsert> – defaults to false; if true, a new document will be added if
#pod   one is not found by taking the filter expression and applying the update
#pod   document operations to it prior to insertion.
#pod
#pod =cut

# args not unpacked for efficiency; args are self, filter, update, options
sub update_many {
    MongoDB::UsageError->throw("filter and update arguments must be references")
      unless ref( $_[1] ) && ref( $_[2] );

    return $_[0]->client->send_write_op(
        MongoDB::Op::_Update->_new(
            ( defined $_[3] ? (%{$_[3]}) : () ),
            filter     => $_[1],
            update     => $_[2],
            multi      => true,
            is_replace => 0,
            %{ $_[0]->_op_args },
        )
    );
}

#pod =method find
#pod
#pod     $cursor = $coll->find( $filter );
#pod     $cursor = $coll->find( $filter, $options );
#pod
#pod     $cursor = $coll->find({ i => { '$gt' => 42 } }, {limit => 20});
#pod
#pod Executes a query with a L<filter expression|/Filter expression> and returns a
#pod C<MongoDB::Cursor> object.
#pod
#pod The query can be customized using L<MongoDB::Cursor> methods, or with an
#pod optional hash reference of options.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<allowPartialResults> - get partial results from a mongos if some shards are
#pod   down (instead of throwing an error).
#pod * C<batchSize> – the number of documents to return per batch.
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<comment> – attaches a comment to the query. If C<$comment> also exists in
#pod   the C<modifiers> document, the comment field overwrites C<$comment>.
#pod * C<cursorType> – indicates the type of cursor to use. It must be one of three
#pod   string values: C<'non_tailable'> (the default), C<'tailable'>, and
#pod   C<'tailable_await'>.
#pod * C<limit> – the maximum number of documents to return.
#pod * C<maxAwaitTimeMS> – the maximum amount of time for the server to wait on
#pod   new documents to satisfy a tailable cursor query. This only applies
#pod   to a C<cursorType> of 'tailable_await'; the option is otherwise ignored.
#pod   (Note, this will be ignored for servers before version 3.2.)
#pod * C<maxTimeMS> – the maximum amount of time to allow the query to run. If
#pod   C<$maxTimeMS> also exists in the modifiers document, the C<maxTimeMS> field
#pod   overwrites C<$maxTimeMS>. (Note, this will be ignored for servers before
#pod   version 2.6.)
#pod * C<modifiers> – a hash reference of dollar-prefixed L<query
#pod   modifiers|http://docs.mongodb.org/manual/reference/operator/query-modifier/>
#pod   modifying the output or behavior of a query.
#pod * C<noCursorTimeout> – if true, prevents the server from timing out a cursor
#pod   after a period of inactivity
#pod * C<projection> - a hash reference defining fields to return. See "L<limit
#pod   fields to
#pod   return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>"
#pod   in the MongoDB documentation for details.
#pod * C<skip> – the number of documents to skip before returning.
#pod * C<sort> – an L<ordered document|/Ordered document> defining the order in which
#pod   to return matching documents. If C<$orderby> also exists in the modifiers
#pod   document, the sort field overwrites C<$orderby>.  See docs for
#pod   L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.
#pod
#pod For more information, see the L<Read Operations
#pod Overview|http://docs.mongodb.org/manual/core/read-operations-introduction/> in
#pod the MongoDB documentation.
#pod
#pod B<Note>, a L<MongoDB::Cursor> object holds the query and does not issue the
#pod query to the server until the L<result|MongoDB::Cursor/result> method is
#pod called on it or until an iterator method like L<next|MongoDB::Cursor/next>
#pod is called.  Performance will be better directly on a
#pod L<MongoDB::QueryResult> object:
#pod
#pod     my $query_result = $coll->find( $filter )->result;
#pod
#pod     while ( my $next = $query_result->next ) {
#pod         ...
#pod     }
#pod
#pod =cut

sub find {
    my ( $self, $filter, $options ) = @_;
    $options ||= {};

    # backwards compatible sort option for deprecated 'query' alias
    $options->{sort} = delete $options->{sort_by} if $options->{sort_by};

    # possibly fallback to default maxTimeMS
    if ( !exists $options->{maxTimeMS} && $self->max_time_ms ) {
        $options->{maxTimeMS} = $self->max_time_ms;
    }

    # coerce to IxHash
    __ixhash( $options, 'sort' );

    return MongoDB::Cursor->new(
        client => $self->{_client},
        query => MongoDB::Op::_Query->_new(
            modifiers           => {},
            allowPartialResults => 0,
            batchSize           => 0,
            comment             => '',
            cursorType          => 'non_tailable',
            limit               => 0,
            maxAwaitTimeMS      => 0,
            maxTimeMS           => 0,
            noCursorTimeout     => 0,
            oplogReplay         => 0,
            projection          => undef,
            skip                => 0,
            sort                => undef,
            %$options,
            filter => $filter || {},
            %{ $self->_op_args },
        )
    );
}

#pod =method find_one
#pod
#pod     $doc = $collection->find_one( $filter, $projection );
#pod     $doc = $collection->find_one( $filter, $projection, $options );
#pod
#pod Executes a query with a L<filter expression|/Filter expression> and returns a
#pod single document.
#pod
#pod If a projection argument is provided, it must be a hash reference specifying
#pod fields to return.  See L<Limit fields to
#pod return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>
#pod in the MongoDB documentation for details.
#pod
#pod If only a filter is provided or if the projection document is an empty hash
#pod reference, all fields will be returned.
#pod
#pod     my $doc = $collection->find_one( $filter );
#pod     my $doc = $collection->find_one( $filter, {}, $options );
#pod
#pod A hash reference of options may be provided as a third argument. Valid keys
#pod include:
#pod
#pod =for :list
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.  (Note, this will be ignored for servers before version 2.6.)
#pod * C<sort> – an L<ordered document|/Ordered document> defining the order in which
#pod   to return matching documents. If C<$orderby> also exists in the modifiers
#pod   document, the sort field overwrites C<$orderby>.  See docs for
#pod   L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.
#pod
#pod See also core documentation on querying:
#pod L<http://docs.mongodb.org/manual/core/read/>.
#pod
#pod =cut

sub find_one {
    my ( $self, $filter, $projection, $options ) = @_;
    $options ||= {};

    # possibly fallback to default maxTimeMS
    if ( !exists $options->{maxTimeMS} && $self->max_time_ms ) {
        $options->{maxTimeMS} = $self->max_time_ms;
    }

    # coerce to IxHash
    __ixhash( $options, 'sort' );

    return $self->client->send_read_op(
        MongoDB::Op::_Query->_new(
            modifiers           => {},
            allowPartialResults => 0,
            batchSize           => 0,
            comment             => '',
            cursorType          => 'non_tailable',
            limit               => 0,
            maxAwaitTimeMS      => 0,
            maxTimeMS           => 0,
            noCursorTimeout     => 0,
            oplogReplay         => 0,
            skip                => 0,
            sort                => undef,
            %$options,
            filter     => $filter     || {},
            projection => $projection || {},
            limit      => -1,
            %{ $self->_op_args },
        )
    )->next;
}

#pod =method find_id
#pod
#pod     $doc = $collection->find_id( $id );
#pod     $doc = $collection->find_id( $id, $projection );
#pod     $doc = $collection->find_id( $id, $projection, $options );
#pod
#pod Executes a query with a L<filter expression|/Filter expression> of C<< { _id
#pod => $id } >> and returns a single document.
#pod
#pod See the L<find_one|/find_one> documentation for details on the $projection and $options parameters.
#pod
#pod See also core documentation on querying:
#pod L<http://docs.mongodb.org/manual/core/read/>.
#pod
#pod =cut

sub find_id {
    my $self = shift;
    my $id = shift;
    return $self->find_one({ _id => $id }, @_);
}

#pod =method find_one_and_delete
#pod
#pod     $doc = $coll->find_one_and_delete( $filter );
#pod     $doc = $coll->find_one_and_delete( $filter, $options );
#pod
#pod Given a L<filter expression|/Filter expression>, this deletes a document from
#pod the database and returns it as it appeared before it was deleted.
#pod
#pod A hash reference of options may be provided. Valid keys include:
#pod
#pod =for :list
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.  (Note, this will be ignored for servers before version 2.6.)
#pod * C<projection> - a hash reference defining fields to return. See "L<limit
#pod   fields to
#pod   return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>"
#pod   in the MongoDB documentation for details.
#pod * C<sort> – an L<ordered document|/Ordered document> defining the order in
#pod   which to return matching documents.  See docs for
#pod   L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.
#pod
#pod =cut

sub find_one_and_delete {
    MongoDB::UsageError->throw("filter argument must be a reference")
      unless ref( $_[1] );

    my ( $self, $filter, $options ) = @_;
    $options ||= {};

    # rename projection -> fields
    $options->{fields} = delete $options->{projection} if exists $options->{projection};

    # possibly fallback to default maxTimeMS
    if ( ! exists $options->{maxTimeMS} && $self->max_time_ms ) {
        $options->{maxTimeMS} = $self->max_time_ms;
    }

    # coerce to IxHash
    __ixhash($options, 'sort');

    my $op = MongoDB::Op::_FindAndDelete->_new(
        %{ $_[0]->_op_args },
        filter        => $filter,
        options       => $options,
    );

    return $self->client->send_write_op($op);
}

#pod =method find_one_and_replace
#pod
#pod     $doc = $coll->find_one_and_replace( $filter, $replacement );
#pod     $doc = $coll->find_one_and_replace( $filter, $replacement, $options );
#pod
#pod Given a L<filter expression|/Filter expression> and a replacement document,
#pod this replaces a document from the database and returns it as it was either
#pod right before or right after the replacement.  The default is 'before'.
#pod
#pod The replacement document must not have any field-update operators in it (e.g.
#pod C<$set>).
#pod
#pod A hash reference of options may be provided. Valid keys include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.
#pod * C<projection> - a hash reference defining fields to return. See "L<limit
#pod   fields to
#pod   return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>"
#pod   in the MongoDB documentation for details.
#pod * C<returnDocument> – either the string C<'before'> or C<'after'>, to indicate
#pod   whether the returned document should be the one before or after replacement.
#pod   The default is C<'before'>.
#pod * C<sort> – an L<ordered document|/Ordered document> defining the order in
#pod   which to return matching documents.  See docs for
#pod   L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.
#pod * C<upsert> – defaults to false; if true, a new document will be added if one
#pod   is not found
#pod
#pod =cut

sub find_one_and_replace {
    MongoDB::UsageError->throw("filter and replace arguments must be references")
      unless ref( $_[1] ) && ref( $_[2] );

    my ( $self, $filter, $replacement, $options ) = @_;

    return $self->_find_one_and_update_or_replace($filter, $replacement, $options);
}

#pod =method find_one_and_update
#pod
#pod     $doc = $coll->find_one_and_update( $filter, $update );
#pod     $doc = $coll->find_one_and_update( $filter, $update, $options );
#pod
#pod Given a L<filter expression|/Filter expression> and a document of update
#pod operators, this updates a single document and returns it as it was either right
#pod before or right after the update.  The default is 'before'.
#pod
#pod The update document must contain only field-update operators (e.g. C<$set>).
#pod
#pod A hash reference of options may be provided. Valid keys include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.  (Note, this will be ignored for servers before version 2.6.)
#pod * C<projection> - a hash reference defining fields to return. See "L<limit
#pod   fields to
#pod   return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>"
#pod   in the MongoDB documentation for details.
#pod * C<returnDocument> – either the string C<'before'> or C<'after'>, to indicate
#pod   whether the returned document should be the one before or after replacement.
#pod   The default is C<'before'>.
#pod * C<sort> – an L<ordered document|/Ordered document> defining the order in
#pod   which to return matching documents.  See docs for
#pod   L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.
#pod * C<upsert> – defaults to false; if true, a new document will be added if one
#pod   is not found
#pod
#pod =cut

my $foau_args;
sub find_one_and_update {
    MongoDB::UsageError->throw("filter and update arguments must be references")
      unless ref( $_[1] ) && ref( $_[2] );

    my ( $self, $filter, $update, $options ) = @_;

    return $self->_find_one_and_update_or_replace($filter, $update, $options);
}

#pod =method aggregate
#pod
#pod     @pipeline = (
#pod         { '$group' => { _id => '$state,' totalPop => { '$sum' => '$pop' } } },
#pod         { '$match' => { totalPop => { '$gte' => 10 * 1000 * 1000 } } }
#pod     );
#pod
#pod     $result = $collection->aggregate( \@pipeline );
#pod     $result = $collection->aggregate( \@pipeline, $options );
#pod
#pod Runs a query using the MongoDB 2.2+ aggregation framework and returns a
#pod L<MongoDB::QueryResult> object.
#pod
#pod The first argument must be an array-ref of L<aggregation
#pod pipeline|http://docs.mongodb.org/manual/core/aggregation-pipeline/> documents.
#pod Each pipeline document must be a hash reference.
#pod
#pod A hash reference of options may be provided. Valid keys include:
#pod
#pod =for :list
#pod * C<allowDiskUse> – if, true enables writing to temporary files.
#pod * C<batchSize> – the number of documents to return per batch.
#pod * C<bypassDocumentValidation> - skips document validation, if enabled.
#pod   (Note, this will be ignored for servers before version 3.2.)
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<explain> – if true, return a single document with execution information.
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.  (Note, this will be ignored for servers before version 2.6.)
#pod
#pod B<Note> MongoDB 2.6+ added the '$out' pipeline operator.  If this operator is
#pod used to write aggregation results directly to a collection, an empty result
#pod will be returned. Create a new collection> object to query the generated result
#pod collection.  When C<$out> is used, the command is treated as a write operation
#pod and read preference is ignored.
#pod
#pod See L<Aggregation|http://docs.mongodb.org/manual/aggregation/> in the MongoDB manual
#pod for more information on how to construct aggregation queries.
#pod
#pod B<Note> The use of aggregation cursors is automatic based on your server
#pod version.  However, if migrating a sharded cluster from MongoDB 2.4 to 2.6
#pod or later, you must upgrade your mongod servers first before your mongos
#pod routers or aggregation queries will fail.  As a workaround, you may
#pod pass C<< cursor => undef >> as an option.
#pod
#pod =cut

my $aggregate_args;
sub aggregate {
    MongoDB::UsageError->throw("pipeline argument must be an array reference")
      unless ref( $_[1] ) eq 'ARRAY';

    my ( $self, $pipeline, $options ) = @_;
    $options ||= {};

    # boolify some options
    for my $k (qw/allowDiskUse explain/) {
        $options->{$k} = ( $options->{$k} ? true : false ) if exists $options->{$k};
    }

    # possibly fallback to default maxTimeMS
    if ( ! exists $options->{maxTimeMS} && $self->max_time_ms ) {
        $options->{maxTimeMS} = $self->max_time_ms;
    }

    # read preferences are ignored if the last stage is $out
    my ($last_op) = keys %{ $pipeline->[-1] };

    my $op = MongoDB::Op::_Aggregate->_new(
        pipeline     => $pipeline,
        options      => $options,
        read_concern => $self->read_concern,
        has_out      => $last_op eq '$out',
        %{ $self->_op_args },
    );

    return $self->client->send_read_op($op);
}

#pod =method count
#pod
#pod     $count = $coll->count( $filter );
#pod     $count = $coll->count( $filter, $options );
#pod
#pod Returns a count of documents matching a L<filter expression|/Filter expression>.
#pod
#pod A hash reference of options may be provided. Valid keys include:
#pod
#pod =for :list
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<hint> – L<specify an index to
#pod   use|http://docs.mongodb.org/manual/reference/command/count/#specify-the-index-to-use>;
#pod   must be a string, array reference, hash reference or L<Tie::IxHash> object.
#pod * C<limit> – the maximum number of documents to count.
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.  (Note, this will be ignored for servers before version 2.6.)
#pod * C<skip> – the number of documents to skip before counting documents.
#pod
#pod B<NOTE>: On a sharded cluster, C<count> can result in an inaccurate count if
#pod orphaned documents exist or if a chunk migration is in progress.  See L<count
#pod command
#pod documentation|http://docs.mongodb.org/manual/reference/command/count/#behavior>
#pod for details and a work-around using L</aggregate>.
#pod
#pod =cut

sub count {
    my ( $self, $filter, $options ) = @_;
    $filter  ||= {};
    $options ||= {};

    # possibly fallback to default maxTimeMS
    if ( ! exists $options->{maxTimeMS} && $self->max_time_ms ) {
        $options->{maxTimeMS} = $self->max_time_ms;
    }

    # string is OK so we check ref, not just exists
    __ixhash($options, 'hint') if ref $options->{hint};

    my $op = MongoDB::Op::_Count->_new(
        options         => $options,
        filter          => $filter,
        %{ $self->_op_args },
    );

    my $res = $self->client->send_read_op($op);

    return $res->{n};
}

#pod =method distinct
#pod
#pod     $result = $coll->distinct( $fieldname );
#pod     $result = $coll->distinct( $fieldname, $filter );
#pod     $result = $coll->distinct( $fieldname, $filter, $options );
#pod
#pod Returns a L<MongoDB::QueryResult> object that will provide distinct values for
#pod a specified field name.
#pod
#pod The query may be limited by an optional L<filter expression|/Filter
#pod expression>.
#pod
#pod A hash reference of options may be provided. Valid keys include:
#pod
#pod =for :list
#pod * C<collation> - a L<document|/Document> defining the collation for this operation.
#pod   See docs for the format of the collation document here:
#pod   L<https://docs.mongodb.com/master/reference/collation/>.
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.  (Note, this will be ignored for servers before version 2.6.)
#pod
#pod See documentation for the L<distinct
#pod command|http://docs.mongodb.org/manual/reference/command/distinct/> for
#pod details.
#pod
#pod =cut

my $distinct_args;

sub distinct {
    MongoDB::UsageError->throw("fieldname argument is required")
      unless defined( $_[1] );

    my ( $self, $fieldname, $filter, $options ) = @_;
    $filter ||= {};
    $options ||= {};

    # possibly fallback to default maxTimeMS
    if ( ! exists $options->{maxTimeMS} && $self->max_time_ms ) {
        $options->{maxTimeMS} = $self->max_time_ms;
    }

    my $op = MongoDB::Op::_Distinct->_new(
        fieldname       => $fieldname,
        filter          => $filter,
        options         => $options,
        %{ $self->_op_args },
    );

    return $self->client->send_read_op($op);
}


#pod =method parallel_scan
#pod
#pod     @result_objs = $collection->parallel_scan(10);
#pod     @result_objs = $collection->parallel_scan(10, $options );
#pod
#pod Returns one or more L<MongoDB::QueryResult> objects to scan the collection in
#pod parallel. The argument is the maximum number of L<MongoDB::QueryResult> objects
#pod to return and must be a positive integer between 1 and 10,000.
#pod
#pod As long as the collection is not modified during scanning, each document will
#pod appear only once in one of the cursors' result sets.
#pod
#pod B<Note>: the server may return fewer cursors than requested, depending on the
#pod underlying storage engine and resource availability.
#pod
#pod A hash reference of options may be provided. Valid keys include:
#pod
#pod =for :list
#pod * C<maxTimeMS> – the maximum amount of time in milliseconds to allow the
#pod   command to run.  (Note, this will be ignored for servers before version 3.4.)
#pod
#pod =cut

sub parallel_scan {
    my ( $self, $num_cursors, $options ) = @_;
    unless (defined $num_cursors && $num_cursors == int($num_cursors)
        && $num_cursors > 0 && $num_cursors <= 10000
    ) {
        MongoDB::UsageError->throw( "first argument to parallel_scan must be a positive integer between 1 and 10000" )
    }
    $options = ref $options eq 'HASH' ? $options : { };

    my $op = MongoDB::Op::_ParallelScan->_new(
        %{ $self->_op_args },
        num_cursors     => $num_cursors,
        options         => $options,
    );

    my $result = $self->client->send_read_op( $op );
    my $response = $result->output;

    MongoDB::UsageError->throw("No cursors returned")
        unless $response->{cursors} && ref $response->{cursors} eq 'ARRAY';

    my @cursors;
    for my $c ( map { $_->{cursor} } @{$response->{cursors}} ) {
        my $batch = $c->{firstBatch};
        my $qr = MongoDB::QueryResult->_new(
            _client       => $self->client,
            _address      => $result->address,
            _full_name    => $c->{ns},
            _bson_codec   => $self->bson_codec,
            _batch_size   => scalar @$batch,
            _cursor_at    => 0,
            _limit        => 0,
            _cursor_id    => $c->{id},
            _cursor_start => 0,
            _cursor_flags => {},
            _cursor_num   => scalar @$batch,
            _docs         => $batch,
        );
        push @cursors, $qr;
    }

    return @cursors;
}

#pod =method rename
#pod
#pod     $newcollection = $collection->rename("mynewcollection");
#pod
#pod Renames the collection.  If a collection already exists with the new collection
#pod name, this method will throw an exception.
#pod
#pod It returns a new L<MongoDB::Collection> object corresponding to the renamed
#pod collection.
#pod
#pod =cut

sub rename {
    my ( $self, $new_name ) = @_;

    my $op = MongoDB::Op::_RenameCollection->_new(
        src_ns => $self->full_name,
        dst_ns => join( ".", $self->database->name, $new_name ),
        %{ $self->_op_args },
    );

    $self->client->send_write_op($op);

    return $self->database->get_collection($new_name);
}

#pod =method drop
#pod
#pod     $collection->drop;
#pod
#pod Deletes a collection as well as all of its indexes.
#pod
#pod =cut

sub drop {
    my ($self) = @_;

    $self->client->send_write_op( MongoDB::Op::_DropCollection->_new( %{ $self->_op_args } ) );

    return;
}

#pod =method ordered_bulk
#pod
#pod     $bulk = $coll->ordered_bulk;
#pod     $bulk->insert_one( $doc1 );
#pod     $bulk->insert_one( $doc2 );
#pod     ...
#pod     $result = $bulk->execute;
#pod
#pod Returns a L<MongoDB::BulkWrite> object to group write operations into fewer network
#pod round-trips.  This method creates an B<ordered> operation, where operations halt after
#pod the first error. See L<MongoDB::BulkWrite> for more details.
#pod
#pod The method C<initialize_ordered_bulk_op> may be used as an alias.
#pod
#pod A hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod
#pod =cut

sub initialize_ordered_bulk_op {
    my ($self, $args) = @_;
    $args ||= {};
    return MongoDB::BulkWrite->new( %$args, collection => $self, ordered => 1, );
}

#pod =method unordered_bulk
#pod
#pod This method works just like L</ordered_bulk> except that the order that
#pod operations are sent to the database is not guaranteed and errors do not halt processing.
#pod See L<MongoDB::BulkWrite> for more details.
#pod
#pod The method C<initialize_unordered_bulk_op> may be used as an alias.
#pod
#pod A hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod
#pod =cut

sub initialize_unordered_bulk_op {
    my ($self, $args) = @_;
    $args ||= {};
    return MongoDB::BulkWrite->new( %$args, collection => $self, ordered => 0 );
}

#pod =method bulk_write
#pod
#pod     $res = $coll->bulk_write( [ @requests ], $options )
#pod
#pod This method provides syntactic sugar to construct and execute a bulk operation
#pod directly, without using C<initialize_ordered_bulk> or
#pod C<initialize_unordered_bulk> to generate a L<MongoDB::BulkWrite> object and
#pod then calling methods on it.  It returns a L<MongoDB::BulkWriteResponse> object
#pod just like the L<MongoDB::BulkWrite execute|MongoDB::BulkWrite/execute> method.
#pod
#pod The first argument must be an array reference of requests.  Requests consist
#pod of pairs of a MongoDB::Collection write method name (e.g. C<insert_one>,
#pod C<delete_many>) and an array reference of arguments to the corresponding
#pod method name.  They may be given as pairs, or as hash or array
#pod references:
#pod
#pod     # pairs -- most efficient
#pod     @requests = (
#pod         insert_one  => [ { x => 1 } ],
#pod         replace_one => [ { x => 1 }, { x => 4 } ],
#pod         delete_one  => [ { x => 4 } ],
#pod         update_many => [ { x => { '$gt' => 5 } }, { '$inc' => { x => 1 } } ],
#pod     );
#pod
#pod     # hash references
#pod     @requests = (
#pod         { insert_one  => [ { x => 1 } ] },
#pod         { replace_one => [ { x => 1 }, { x => 4 } ] },
#pod         { delete_one  => [ { x => 4 } ] },
#pod         { update_many => [ { x => { '$gt' => 5 } }, { '$inc' => { x => 1 } } ] },
#pod     );
#pod
#pod     # array references
#pod     @requests = (
#pod         [ insert_one  => [ { x => 1 } ] ],
#pod         [ replace_one => [ { x => 1 }, { x => 4 } ] ],
#pod         [ delete_one  => [ { x => 4 } ] ],
#pod         [ update_many => [ { x => { '$gt' => 5 } }, { '$inc' => { x => 1 } } ] ],
#pod     );
#pod
#pod Valid method names include C<insert_one>, C<insert_many>, C<delete_one>,
#pod C<delete_many> C<replace_one>, C<update_one>, C<update_many>.
#pod
#pod An optional hash reference of options may be provided.
#pod
#pod Valid options include:
#pod
#pod =for :list
#pod * C<bypassDocumentValidation> - skips document validation, if enabled; this
#pod   is ignored for MongoDB servers older than version 3.2.
#pod * C<ordered> – when true, the bulk operation is executed like
#pod   L</initialize_ordered_bulk>. When false, the bulk operation is executed
#pod   like L</initialize_unordered_bulk>.  The default is true.
#pod
#pod See L<MongoDB::BulkWrite> for more details on bulk writes.  Be advised that
#pod the legacy Bulk API method names differ slightly from MongoDB::Collection
#pod method names.
#pod
#pod =cut

sub bulk_write {
    my ( $self, $requests, $options ) = @_;

    MongoDB::UsageError->throw("requests not an array reference")
      unless ref $requests eq 'ARRAY';
    MongoDB::UsageError->throw("empty request list") unless @$requests;
    MongoDB::UsageError->throw("options not a hash reference")
      if defined($options) && ref($options) ne 'HASH';

    $options ||= {};

    my $ordered = exists $options->{ordered} ? delete $options->{ordered} : 1;

    my $bulk =
      $ordered ? $self->ordered_bulk($options) : $self->unordered_bulk($options);

    my $i = 0;

    while ( $i <= $#$requests ) {
        my ( $method, $args );

        # pull off document or pair
        if ( my $type = ref $requests->[$i] ) {
            if ( $type eq 'ARRAY' ) {
                ( $method, $args ) = @{ $requests->[$i] };
            }
            elsif ( $type eq 'HASH' ) {
                ( $method, $args ) = %{ $requests->[$i] };
            }
            else {
                MongoDB::UsageError->throw("$requests->[$i] is not a hash or array reference");
            }
            $i++;
        }
        else {
            ( $method, $args ) = @{$requests}[ $i, $i + 1 ];
            $i += 2;
        }

        MongoDB::UsageError->throw("'$method' requires an array reference of arguments")
          unless ref($args) eq 'ARRAY';

        # handle inserts
        if ( $method eq 'insert_one' || $method eq 'insert_many' ) {
            $bulk->insert_one($_) for @$args;
        }
        else {
            my ( $filter, $arg2, $arg3 ) = @$args;

            my $is_delete = $method eq 'delete_one' || $method eq 'delete_many';
            my $update_doc = $is_delete ? undef : $arg2;
            my $opts       = $is_delete ? $arg2 : $arg3;

            my $view = $bulk->find($filter);

            # set collation
            $view = $view->collation( $opts->{collation} ) if $opts && $opts->{collation};

            # handle deletes
            if ( $method eq 'delete_one' ) {
                $view->delete_one;
                next;
            }
            elsif ( $method eq 'delete_many' ) {
                $view->delete_many;
                next;
            }

            # updates might be upserts
            $view = $view->upsert if $opts && $opts->{upsert};

            # handle updates
            if ( $method eq 'replace_one' ) {
                $view->replace_one($update_doc);
            }
            elsif ( $method eq 'update_one' ) {
                $view->update_one($update_doc);
            }
            elsif ( $method eq 'update_many' ) {
                $view->update_many($update_doc);
            }
            else {
                MongoDB::UsageError->throw("unknown bulk operation '$method'");
            }
        }
    }

    return $bulk->execute;
}

BEGIN {
    # aliases
    no warnings 'once';
    *query = \&find;
    *ordered_bulk = \&initialize_ordered_bulk_op;
    *unordered_bulk = \&initialize_unordered_bulk_op;
}

#--------------------------------------------------------------------------#
# private methods
#--------------------------------------------------------------------------#

sub _dynamic_write_concern {
    my ( $self, $opts ) = @_;
    if ( !exists( $opts->{safe} ) || $opts->{safe} ) {
        return $self->write_concern;
    }
    else {
        return MongoDB::WriteConcern->new( w => 0 );
    }
}

sub _find_one_and_update_or_replace {
    my ($self, $filter, $modifier, $options) = @_;
    $options ||= {};

    # rename projection -> fields
    $options->{fields} = delete $options->{projection} if exists $options->{projection};

    # possibly fallback to default maxTimeMS
    if ( ! exists $options->{maxTimeMS} && $self->max_time_ms ) {
        $options->{maxTimeMS} = $self->max_time_ms;
    }

    # coerce to IxHash
    __ixhash($options, 'sort');

    # returnDocument ('before'|'after') maps to field 'new'
    if ( exists $options->{returnDocument} ) {
        MongoDB::UsageError->throw("Invalid returnDocument parameter '$options->{returnDocument}'")
            unless $options->{returnDocument} =~ /^(?:before|after)$/;
        $options->{new} = delete( $options->{returnDocument} ) eq 'after' ? true : false;
    }

    # pass separately for MongoDB::Role::_BypassValidation
    my $bypass = delete $options->{bypassDocumentValidation};

    my $op = MongoDB::Op::_FindAndUpdate->_new(
        filter         => $filter,
        modifier       => $modifier,
        options        => $options,
        bypassDocumentValidation => $bypass,
        %{ $self->_op_args },
    );

    return $self->client->send_write_op($op);
}

#--------------------------------------------------------------------------#
# utility function
#--------------------------------------------------------------------------#

# utility function to coerce array/hashref to Tie::Ixhash
sub __ixhash {
    my ($hash, $key) = @_;
    return unless exists $hash->{$key};
    my $ref = $hash->{$key};
    my $type = ref($ref);
    return if $type eq 'Tie::IxHash';
    if ( $type eq 'HASH' ) {
        $hash->{$key} = Tie::IxHash->new( %$ref );
    }
    elsif ( $type eq 'ARRAY' ) {
        $hash->{$key} = Tie::IxHash->new( @$ref );
    }
    else {
        MongoDB::UsageError->throw("Can't convert $type to a Tie::IxHash");
    }
    return;
}

#--------------------------------------------------------------------------#
# Deprecated legacy methods
#--------------------------------------------------------------------------#

my $legacy_insert_args;
sub insert {
    MongoDB::UsageError->throw("document argument must be a reference")
      unless ref( $_[1] );

    my ( $self, $document, $opts ) = @_;

    $self->_warn_deprecated( 'insert' => ['insert_one'] );

    my $op = MongoDB::Op::_InsertOne->_new(
        document => $document,
        %{ $self->_op_args },
        write_concern => $self->_dynamic_write_concern($opts),
    );

    my $result = $self->client->send_write_op($op);

    return $result->inserted_id;
}

sub batch_insert {
    MongoDB::UsageError->throw("documents argument must be an array reference")
      unless ref( $_[1] ) eq 'ARRAY';

    my ( $self, $documents, $opts ) = @_;

    $self->_warn_deprecated( 'batch_insert' => ['insert_many'] );

    my $op = MongoDB::Op::_BatchInsert->_new(
        documents     => $documents,
        check_keys    => 0,
        ordered       => 1,
        %{ $_[0]->_op_args },
        write_concern => $self->_dynamic_write_concern($opts),
    );

    my $result = $self->client->send_write_op($op);

    return if $result->isa("MongoDB::UnacknowledgedResult");

    my @ids;
    my $inserted_ids = $result->inserted_ids;
    for my $k ( sort { $a <=> $b } keys %$inserted_ids ) {
        push @ids, $inserted_ids->{$k};
    }

    return @ids;
}

sub remove {
    my ($self, $query, $opts) = @_;
    $opts ||= {};

    $self->_warn_deprecated( 'remove' => [qw/delete_many delete_one/] );

    MongoDB::UsageError->throw(
        "deprecated method 'remove' does not support a collation, use one of its replacement methods instead"
    ) if exists $opts->{collation};

    my $op = MongoDB::Op::_Delete->_new(
        filter => $query || {},
        just_one => !!$opts->{just_one},
        %{ $self->_op_args },
        write_concern => $self->_dynamic_write_concern($opts),
    );

    my $result = $self->client->send_write_op( $op );

    # emulate key fields of legacy GLE result
    return {
        ok => 1,
        n => $result->deleted_count,
    };
}

my $legacy_update_args;
sub update {
    my ( $self, $query, $object, $opts ) = @_;
    $opts ||= {};
    $object ||= {};

    $self->_warn_deprecated( 'update' => [qw/update_one update_many replace_one/] );

    MongoDB::UsageError->throw(
        "deprecated method 'update' does not support a collation, use one of its replacement methods instead"
    ) if exists $opts->{collation};

    if ( exists $opts->{multiple} ) {
        if ( exists( $opts->{multi} ) && !!$opts->{multi} ne !!$opts->{multiple} ) {
            MongoDB::UsageError->throw(
                "can't use conflicting values of 'multiple' and 'multi' in 'update'");
        }
        $opts->{multi} = delete $opts->{multiple};
    }

    # figure out if first key based on op_char or '$'
    my $type = ref($object);
    my $fk = (
          $type eq 'HASH' ? each(%$object)
        : $type eq 'ARRAY' ? $object->[0]
        : $type eq 'Tie::IxHash' ? $object->FIRSTKEY
        : each (%$object)
    );
    $fk = defined($fk) ? substr($fk,0,1) : '';

    my $op_char = eval { $self->bson_codec->op_char } || '$';
    my $is_replace = $fk ne $op_char;

    my $op = MongoDB::Op::_Update->_new(
        filter => $query  || {},
        update => $object || {},
        multi  => $opts->{multi},
        upsert => $opts->{upsert},
        is_replace => $is_replace,
        %{ $_[0]->_op_args },
        write_concern => $self->_dynamic_write_concern($opts),
    );

    my $result = $self->client->send_write_op( $op );

    if ( $result->acknowledged ) {
        # emulate key fields of legacy GLE result
        return {
            ok => 1,
            n => $result->matched_count,
            ( $result->upserted_id ? ( upserted => $result->upserted_id ) : () ),
        };
    }
    else {
        return { ok => 1 };
    }
}

sub save {
    MongoDB::UsageError->throw("document argument must be a reference")
      unless ref( $_[1] );

    my ($self, $doc, $options) = @_;

    $self->_warn_deprecated( 'save', "Use 'replace_one' with upsert instead." );

    my $type = ref($doc);
    my $id = (
          $type eq 'HASH' ? $doc->{_id}
        : $type eq 'ARRAY' ? do {
            my $i;
            for ( $i = 0; $i < @$doc; $i++ ) { last if $doc->[$i] eq '_id' }
            $i < $#$doc ? $doc->[ $i + 1 ] : undef;
          }
        : $type eq 'Tie::IxHash' ? $doc->FETCH('_id')
        : $doc->{_id} # hashlike?
    );

    if ( defined($id) ) {
        $options ||= {};
        $options->{'upsert'} = boolean::true;
        return $self->update( { _id => $id }, $doc, $options );
    }
    else {
        return $self->insert( $doc, ( $options ? $options : () ) );
    }
}

sub find_and_modify {
    my ( $self, $opts ) = @_;
    $opts ||= {};

    $self->_warn_deprecated( 'find_and_modify' =>
          [qw/find_one_and_update find_one_and_replace find_one_and_delete/] );

    MongoDB::UsageError->throw(
        "deprecated method 'find_and_modify' does not support a collation, use one of its replacement methods instead"
    ) if exists $opts->{collation};

    MongoDB::UsageError->throw("find_and_modify requires a 'query' option")
        unless $opts->{query};

    MongoDB::UsageError->throw("find_and_modify requires a 'remove' or 'update' option")
        unless $opts->{remove} || $opts->{update};

    my $query = delete $opts->{query};
    my $remove = delete $opts->{remove};
    my $update = delete $opts->{update};

    return $remove
        ? $self->find_one_and_delete($query, $opts)
        : $self->find_one_and_update($query, $update, $opts);
}

sub get_collection {
    my $self = shift @_;
    my $coll = shift @_;

    $self->_warn_deprecated( 'get_collection',
        "Use \$coll->database->coll(join('.', \$coll->name, 'subname')) instead." );

    return $self->database->get_collection($self->name.'.'.$coll);
}

sub ensure_index {
    my ( $self, $keys, $opts ) = @_;

    $self->_warn_deprecated( 'ensure_index' => "Use 'indexes' to work with a MongoDB::IndexView instead." );

    MongoDB::UsageError->throw("ensure_index options must be a hash reference")
      if $opts && !ref($opts) eq 'HASH';

    MongoDB::UsageError->throw(
        "deprecated method 'ensure_index' does not support a collation, use 'indexes' instead"
    ) if exists $opts->{collation};

    $keys = Tie::IxHash->new(@$keys) if ref $keys eq 'ARRAY';
    $opts = $self->_clean_index_options( $opts, $keys );

    # always use safe write concern for index creation
    my $wc =
        $self->write_concern->is_acknowledged
      ? $self->write_concern
      : MongoDB::WriteConcern->new;

    my $op = MongoDB::Op::_CreateIndexes->_new(
        db_name       => $self->database->name,
        coll_name     => $self->name,
        full_name     => $self->full_name,
        bson_codec    => $self->bson_codec,
        indexes       => [ { key => $keys, %$opts } ],
        write_concern => $wc,
    );

    $self->client->send_write_op($op);

    return 1;
}

sub _clean_index_options {
    my ( $self, $orig, $keys ) = @_;

    # copy the original so we don't modify it
    my $opts = { $orig ? %$orig : () };

    # add name if not provided
    $opts->{name} = __to_index_string($keys)
      unless defined $opts->{name};

    # safe is no more
    delete $opts->{safe} if exists $opts->{safe};

    # convert snake case
    if ( exists $opts->{drop_dups} ) {
        $opts->{dropDups} = delete $opts->{drop_dups};
    }

    # convert snake case and turn into an integer
    if ( exists $opts->{expire_after_seconds} ) {
        $opts->{expireAfterSeconds} = int( delete $opts->{expire_after_seconds} );
    }

    # convert some things to booleans
    for my $k (qw/unique background sparse dropDups/) {
        next unless exists $opts->{$k};
        $opts->{$k} = boolean( $opts->{$k} );
    }

    return $opts;
}

sub __to_index_string {
    my $keys = shift;

    my @name;
    if (ref $keys eq 'ARRAY') {
        @name = @$keys;
    }
    elsif (ref $keys eq 'HASH' ) {
        @name = %$keys
    }
    elsif (ref $keys eq 'Tie::IxHash') {
        my @ks = $keys->Keys;
        my @vs = $keys->Values;

        for (my $i=0; $i<$keys->Length; $i++) {
            push @name, $ks[$i];
            push @name, $vs[$i];
        }
    }
    else {
        MongoDB::UsageError->throw("expected Tie::IxHash, hash, or array reference for keys");
    }

    return join("_", @name);
}

sub get_indexes {
    my ($self) = @_;

    $self->_warn_deprecated( 'get_indexes'  => "Use 'indexes' to work with a MongoDB::IndexView instead." );

    my $op = MongoDB::Op::_ListIndexes->_new(
        %{ $_[0]->_op_args },
    );

    my $res = $self->client->send_primary_op($op);

    return $res->all;
}

sub drop_indexes {
    my ($self) = @_;

    $self->_warn_deprecated( 'drop_indexes'  => "Use 'indexes' to work with a MongoDB::IndexView instead." );

    return $self->drop_index('*');
}

sub drop_index {
    my ($self, $index_name) = @_;

    $self->_warn_deprecated( 'drop_index'  => "Use 'indexes' to work with a MongoDB::IndexView instead." );

    return $self->_run_command([
        dropIndexes => $self->name,
        index => $index_name,
    ]);
}

sub validate {
    my ($self, $scan_data) = @_;

    $self->_warn_deprecated( 'validate'  => "Use 'validate' manually via MongoDB::Database::run_command" );

    $scan_data = 0 unless defined $scan_data;
    my $obj = $self->_run_command({ validate => $self->name });
}

# we have a private _run_command rather than using the 'database' attribute
# so that we're using our BSON codec and not the source database one
sub _run_command {
    my ( $self, $command ) = @_;

    my $op = MongoDB::Op::_Command->_new(
        db_name     => $self->database->name,
        query       => $command,
        query_flags => {},
        bson_codec  => $self->bson_codec,
    );

    my $obj = $self->client->send_read_op($op);

    return $obj->output;
}

1;

=pod

=encoding UTF-8

=head1 NAME

MongoDB::Collection - A MongoDB Collection

=head1 VERSION

version v1.8.1

=head1 SYNOPSIS

    # get a Collection via the Database object
    $coll = $db->get_collection("people");

    # insert a document
    $coll->insert_one( { name => "John Doe", age => 42 } );

    # insert one or more documents
    $coll->insert_many( \@documents );

    # delete a document
    $coll->delete_one( { name => "John Doe" } );

    # update a document
    $coll->update_one( { name => "John Doe" }, { '$inc' => { age => 1 } } );

    # find a single document
    $doc = $coll->find_one( { name => "John Doe" } )

    # Get a MongoDB::Cursor for a query
    $cursor = $coll->find( { age => 42 } );

    # Cursor iteration
    while ( my $doc = $cursor->next ) {
        ...
    }

=head1 DESCRIPTION

This class models a MongoDB collection and provides an API for interacting
with it.

Generally, you never construct one of these directly with C<new>.  Instead, you
call C<get_collection> on a L<MongoDB::Database> object.

=head1 USAGE

=head2 Error handling

Unless otherwise explicitly documented, all methods throw exceptions if
an error occurs.  The error types are documented in L<MongoDB::Error>.

To catch and handle errors, the L<Try::Tiny> and L<Safe::Isa> modules
are recommended:

    use Try::Tiny;
    use Safe::Isa; # provides $_isa

    try {
        $coll->insert_one( $doc )
    }
    catch {
        if ( $_->$_isa("MongoDB::DuplicateKeyError" ) {
            ...
        }
        else {
            ...
        }
    };

To retry failures automatically, consider using L<Try::Tiny::Retry>.

=head2 Terminology

=head3 Document

A collection of key-value pairs.  A Perl hash is a document.  Array
references with an even number of elements and L<Tie::IxHash> objects may also
be used as documents.

=head3 Ordered document

Many MongoDB::Collection method parameters or options require an B<ordered
document>: an ordered list of key/value pairs.  Perl's hashes are B<not>
ordered and since Perl v5.18 are guaranteed to have random order.  Therefore,
when an ordered document is called for, you may use an array reference of pairs
or a L<Tie::IxHash> object.  You may use a hash reference if there is only
one key/value pair.

=head3 Filter expression

A filter expression provides the L<query
criteria|http://docs.mongodb.org/manual/tutorial/query-documents/> to select a
document for deletion.  It must be an L</Ordered document>.

=head1 ATTRIBUTES

=head2 database

The L<MongoDB::Database> representing the database that contains
the collection.

=head2 name

The name of the collection.

=head2 read_preference

A L<MongoDB::ReadPreference> object.  It may be initialized with a string
corresponding to one of the valid read preference modes or a hash reference
that will be coerced into a new MongoDB::ReadPreference object.
By default it will be inherited from a L<MongoDB::Database> object.

=head2 write_concern

A L<MongoDB::WriteConcern> object.  It may be initialized with a hash
reference that will be coerced into a new MongoDB::WriteConcern object.
By default it will be inherited from a L<MongoDB::Database> object.

=head2 read_concern

A L<MongoDB::ReadConcern> object.  May be initialized with a hash
reference or a string that will be coerced into the level of read
concern.

By default it will be inherited from a L<MongoDB::Database> object.

=head2 max_time_ms

Specifies the default maximum amount of time in milliseconds that the
server should use for working on a query.

B<Note>: this will only be used for server versions 2.6 or greater, as that
was when the C<$maxTimeMS> meta-operator was introduced.

=head2 bson_codec

An object that provides the C<encode_one> and C<decode_one> methods, such
as from L<MongoDB::BSON>.  It may be initialized with a hash reference that
will be coerced into a new MongoDB::BSON object.  By default it will be
inherited from a L<MongoDB::Database> object.

=head1 METHODS

=head2 client

    $client = $coll->client;

Returns the L<MongoDB::MongoClient> object associated with this
object.

=head2 full_name

    $full_name = $coll->full_name;

Returns the full name of the collection, including the namespace of the
database it's in prefixed with a dot character.  E.g. collection "foo" in
database "test" would result in a C<full_name> of "test.foo".

=head2 indexes

    $indexes = $collection->indexes;

    $collection->indexes->create_one( [ x => 1 ], { unique => 1 } );
    $collection->indexes->drop_all;

Returns a L<MongoDB::IndexView> object for managing the indexes associated
with the collection.

=head2 clone

    $coll2 = $coll1->clone( write_concern => { w => 2 } );

Constructs a copy of the original collection, but allows changing
attributes in the copy.

=head2 with_codec

    $coll2 = $coll1->with_codec( $new_codec );
    $coll2 = $coll1->with_codec( prefer_numeric => 1 );

Constructs a copy of the original collection, but clones the C<bson_codec>.
If given an object that does C<encode_one> and C<decode_one>, it is
equivalent to:

    $coll2 = $coll1->clone( bson_codec => $new_codec );

If given a hash reference or a list of key/value pairs, it is equivalent
to:

    $coll2 = $coll1->clone(
        bson_codec => $coll1->bson_codec->clone( @list )
    );

=head2 insert_one

    $res = $coll->insert_one( $document );
    $res = $coll->insert_one( $document, $options );
    $id = $res->inserted_id;

Inserts a single L<document|/Document> into the database and returns a
L<MongoDB::InsertOneResult> or L<MongoDB::UnacknowledgedResult> object.

If no C<_id> field is present, one will be added when a document is
serialized for the database without modifying the original document.
The generated C<_id> may be retrieved from the result object.

An optional hash reference of options may be given.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=back

=head2 insert_many

    $res = $coll->insert_many( [ @documents ] );
    $res = $coll->insert_many( [ @documents ], { ordered => 0 } );

Inserts each of the L<documents|/Documents> in an array reference into the
database and returns a L<MongoDB::InsertManyResult> or
L<MongoDB::UnacknowledgedResult>.  This is syntactic sugar for doing a
L<MongoDB::BulkWrite> operation.

If no C<_id> field is present, one will be added when a document is
serialized for the database without modifying the original document.
The generated C<_id> may be retrieved from the result object.

An optional hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=item *

C<ordered> – when true, the server will halt insertions after the first error (if any).  When false, all documents will be processed and any error will only be thrown after all insertions are attempted.  The default is true.

=back

On MongoDB servers before version 2.6, C<insert_many> bulk operations are
emulated with individual inserts to capture error information.  On 2.6 or
later, this method will be significantly faster than individual C<insert_one>
calls.

=head2 delete_one

    $res = $coll->delete_one( $filter );
    $res = $coll->delete_one( { _id => $id } );
    $res = $coll->delete_one( $filter, { collation => { locale => "en_US" } } );

Deletes a single document that matches a L<filter expression|/Filter expression> and returns a
L<MongoDB::DeleteResult> or L<MongoDB::UnacknowledgedResult> object.

A hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=back

=head2 delete_many

    $res = $coll->delete_many( $filter );
    $res = $coll->delete_many( { name => "Larry" } );
    $res = $coll->delete_many( $filter, { collation => { locale => "en_US" } } );

Deletes all documents that match a L<filter expression|/Filter expression>
and returns a L<MongoDB::DeleteResult> or L<MongoDB::UnacknowledgedResult>
object.

Valid options include:

=over 4

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=back

=head2 replace_one

    $res = $coll->replace_one( $filter, $replacement );
    $res = $coll->replace_one( $filter, $replacement, { upsert => 1 } );

Replaces one document that matches a L<filter expression|/Filter
expression> and returns a L<MongoDB::UpdateResult> or
L<MongoDB::UnacknowledgedResult> object.

The replacement document must not have any field-update operators in it (e.g.
C<$set>).

A hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<upsert> – defaults to false; if true, a new document will be added if one is not found

=back

=head2 update_one

    $res = $coll->update_one( $filter, $update );
    $res = $coll->update_one( $filter, $update, { upsert => 1 } );

Updates one document that matches a L<filter expression|/Filter expression>
and returns a L<MongoDB::UpdateResult> or L<MongoDB::UnacknowledgedResult>
object.

The update document must have only field-update operators in it (e.g.
C<$set>).

A hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<upsert> – defaults to false; if true, a new document will be added if one is not found by taking the filter expression and applying the update document operations to it prior to insertion.

=back

=head2 update_many

    $res = $coll->update_many( $filter, $update );
    $res = $coll->update_many( $filter, $update, { upsert => 1 } );

Updates one or more documents that match a L<filter expression|/Filter
expression> and returns a L<MongoDB::UpdateResult> or
L<MongoDB::UnacknowledgedResult> object.

The update document must have only field-update operators in it (e.g.
C<$set>).

A hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<upsert> – defaults to false; if true, a new document will be added if one is not found by taking the filter expression and applying the update document operations to it prior to insertion.

=back

=head2 find

    $cursor = $coll->find( $filter );
    $cursor = $coll->find( $filter, $options );

    $cursor = $coll->find({ i => { '$gt' => 42 } }, {limit => 20});

Executes a query with a L<filter expression|/Filter expression> and returns a
C<MongoDB::Cursor> object.

The query can be customized using L<MongoDB::Cursor> methods, or with an
optional hash reference of options.

Valid options include:

=over 4

=item *

C<allowPartialResults> - get partial results from a mongos if some shards are down (instead of throwing an error).

=item *

C<batchSize> – the number of documents to return per batch.

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<comment> – attaches a comment to the query. If C<$comment> also exists in the C<modifiers> document, the comment field overwrites C<$comment>.

=item *

C<cursorType> – indicates the type of cursor to use. It must be one of three string values: C<'non_tailable'> (the default), C<'tailable'>, and C<'tailable_await'>.

=item *

C<limit> – the maximum number of documents to return.

=item *

C<maxAwaitTimeMS> – the maximum amount of time for the server to wait on new documents to satisfy a tailable cursor query. This only applies to a C<cursorType> of 'tailable_await'; the option is otherwise ignored. (Note, this will be ignored for servers before version 3.2.)

=item *

C<maxTimeMS> – the maximum amount of time to allow the query to run. If C<$maxTimeMS> also exists in the modifiers document, the C<maxTimeMS> field overwrites C<$maxTimeMS>. (Note, this will be ignored for servers before version 2.6.)

=item *

C<modifiers> – a hash reference of dollar-prefixed L<query modifiers|http://docs.mongodb.org/manual/reference/operator/query-modifier/> modifying the output or behavior of a query.

=item *

C<noCursorTimeout> – if true, prevents the server from timing out a cursor after a period of inactivity

=item *

C<projection> - a hash reference defining fields to return. See "L<limit fields to return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>" in the MongoDB documentation for details.

=item *

C<skip> – the number of documents to skip before returning.

=item *

C<sort> – an L<ordered document|/Ordered document> defining the order in which to return matching documents. If C<$orderby> also exists in the modifiers document, the sort field overwrites C<$orderby>.  See docs for L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.

=back

For more information, see the L<Read Operations
Overview|http://docs.mongodb.org/manual/core/read-operations-introduction/> in
the MongoDB documentation.

B<Note>, a L<MongoDB::Cursor> object holds the query and does not issue the
query to the server until the L<result|MongoDB::Cursor/result> method is
called on it or until an iterator method like L<next|MongoDB::Cursor/next>
is called.  Performance will be better directly on a
L<MongoDB::QueryResult> object:

    my $query_result = $coll->find( $filter )->result;

    while ( my $next = $query_result->next ) {
        ...
    }

=head2 find_one

    $doc = $collection->find_one( $filter, $projection );
    $doc = $collection->find_one( $filter, $projection, $options );

Executes a query with a L<filter expression|/Filter expression> and returns a
single document.

If a projection argument is provided, it must be a hash reference specifying
fields to return.  See L<Limit fields to
return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>
in the MongoDB documentation for details.

If only a filter is provided or if the projection document is an empty hash
reference, all fields will be returned.

    my $doc = $collection->find_one( $filter );
    my $doc = $collection->find_one( $filter, {}, $options );

A hash reference of options may be provided as a third argument. Valid keys
include:

=over 4

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.  (Note, this will be ignored for servers before version 2.6.)

=item *

C<sort> – an L<ordered document|/Ordered document> defining the order in which to return matching documents. If C<$orderby> also exists in the modifiers document, the sort field overwrites C<$orderby>.  See docs for L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.

=back

See also core documentation on querying:
L<http://docs.mongodb.org/manual/core/read/>.

=head2 find_id

    $doc = $collection->find_id( $id );
    $doc = $collection->find_id( $id, $projection );
    $doc = $collection->find_id( $id, $projection, $options );

Executes a query with a L<filter expression|/Filter expression> of C<< { _id
=> $id } >> and returns a single document.

See the L<find_one|/find_one> documentation for details on the $projection and $options parameters.

See also core documentation on querying:
L<http://docs.mongodb.org/manual/core/read/>.

=head2 find_one_and_delete

    $doc = $coll->find_one_and_delete( $filter );
    $doc = $coll->find_one_and_delete( $filter, $options );

Given a L<filter expression|/Filter expression>, this deletes a document from
the database and returns it as it appeared before it was deleted.

A hash reference of options may be provided. Valid keys include:

=over 4

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.  (Note, this will be ignored for servers before version 2.6.)

=item *

C<projection> - a hash reference defining fields to return. See "L<limit fields to return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>" in the MongoDB documentation for details.

=item *

C<sort> – an L<ordered document|/Ordered document> defining the order in which to return matching documents.  See docs for L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.

=back

=head2 find_one_and_replace

    $doc = $coll->find_one_and_replace( $filter, $replacement );
    $doc = $coll->find_one_and_replace( $filter, $replacement, $options );

Given a L<filter expression|/Filter expression> and a replacement document,
this replaces a document from the database and returns it as it was either
right before or right after the replacement.  The default is 'before'.

The replacement document must not have any field-update operators in it (e.g.
C<$set>).

A hash reference of options may be provided. Valid keys include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.

=item *

C<projection> - a hash reference defining fields to return. See "L<limit fields to return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>" in the MongoDB documentation for details.

=item *

C<returnDocument> – either the string C<'before'> or C<'after'>, to indicate whether the returned document should be the one before or after replacement. The default is C<'before'>.

=item *

C<sort> – an L<ordered document|/Ordered document> defining the order in which to return matching documents.  See docs for L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.

=item *

C<upsert> – defaults to false; if true, a new document will be added if one is not found

=back

=head2 find_one_and_update

    $doc = $coll->find_one_and_update( $filter, $update );
    $doc = $coll->find_one_and_update( $filter, $update, $options );

Given a L<filter expression|/Filter expression> and a document of update
operators, this updates a single document and returns it as it was either right
before or right after the update.  The default is 'before'.

The update document must contain only field-update operators (e.g. C<$set>).

A hash reference of options may be provided. Valid keys include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.  (Note, this will be ignored for servers before version 2.6.)

=item *

C<projection> - a hash reference defining fields to return. See "L<limit fields to return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>" in the MongoDB documentation for details.

=item *

C<returnDocument> – either the string C<'before'> or C<'after'>, to indicate whether the returned document should be the one before or after replacement. The default is C<'before'>.

=item *

C<sort> – an L<ordered document|/Ordered document> defining the order in which to return matching documents.  See docs for L<$orderby|http://docs.mongodb.org/manual/reference/operator/meta/orderby/>.

=item *

C<upsert> – defaults to false; if true, a new document will be added if one is not found

=back

=head2 aggregate

    @pipeline = (
        { '$group' => { _id => '$state,' totalPop => { '$sum' => '$pop' } } },
        { '$match' => { totalPop => { '$gte' => 10 * 1000 * 1000 } } }
    );

    $result = $collection->aggregate( \@pipeline );
    $result = $collection->aggregate( \@pipeline, $options );

Runs a query using the MongoDB 2.2+ aggregation framework and returns a
L<MongoDB::QueryResult> object.

The first argument must be an array-ref of L<aggregation
pipeline|http://docs.mongodb.org/manual/core/aggregation-pipeline/> documents.
Each pipeline document must be a hash reference.

A hash reference of options may be provided. Valid keys include:

=over 4

=item *

C<allowDiskUse> – if, true enables writing to temporary files.

=item *

C<batchSize> – the number of documents to return per batch.

=item *

C<bypassDocumentValidation> - skips document validation, if enabled. (Note, this will be ignored for servers before version 3.2.)

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<explain> – if true, return a single document with execution information.

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.  (Note, this will be ignored for servers before version 2.6.)

=back

B<Note> MongoDB 2.6+ added the '$out' pipeline operator.  If this operator is
used to write aggregation results directly to a collection, an empty result
will be returned. Create a new collection> object to query the generated result
collection.  When C<$out> is used, the command is treated as a write operation
and read preference is ignored.

See L<Aggregation|http://docs.mongodb.org/manual/aggregation/> in the MongoDB manual
for more information on how to construct aggregation queries.

B<Note> The use of aggregation cursors is automatic based on your server
version.  However, if migrating a sharded cluster from MongoDB 2.4 to 2.6
or later, you must upgrade your mongod servers first before your mongos
routers or aggregation queries will fail.  As a workaround, you may
pass C<< cursor => undef >> as an option.

=head2 count

    $count = $coll->count( $filter );
    $count = $coll->count( $filter, $options );

Returns a count of documents matching a L<filter expression|/Filter expression>.

A hash reference of options may be provided. Valid keys include:

=over 4

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<hint> – L<specify an index to use|http://docs.mongodb.org/manual/reference/command/count/#specify-the-index-to-use>; must be a string, array reference, hash reference or L<Tie::IxHash> object.

=item *

C<limit> – the maximum number of documents to count.

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.  (Note, this will be ignored for servers before version 2.6.)

=item *

C<skip> – the number of documents to skip before counting documents.

=back

B<NOTE>: On a sharded cluster, C<count> can result in an inaccurate count if
orphaned documents exist or if a chunk migration is in progress.  See L<count
command
documentation|http://docs.mongodb.org/manual/reference/command/count/#behavior>
for details and a work-around using L</aggregate>.

=head2 distinct

    $result = $coll->distinct( $fieldname );
    $result = $coll->distinct( $fieldname, $filter );
    $result = $coll->distinct( $fieldname, $filter, $options );

Returns a L<MongoDB::QueryResult> object that will provide distinct values for
a specified field name.

The query may be limited by an optional L<filter expression|/Filter
expression>.

A hash reference of options may be provided. Valid keys include:

=over 4

=item *

C<collation> - a L<document|/Document> defining the collation for this operation. See docs for the format of the collation document here: L<https://docs.mongodb.com/master/reference/collation/>.

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.  (Note, this will be ignored for servers before version 2.6.)

=back

See documentation for the L<distinct
command|http://docs.mongodb.org/manual/reference/command/distinct/> for
details.

=head2 parallel_scan

    @result_objs = $collection->parallel_scan(10);
    @result_objs = $collection->parallel_scan(10, $options );

Returns one or more L<MongoDB::QueryResult> objects to scan the collection in
parallel. The argument is the maximum number of L<MongoDB::QueryResult> objects
to return and must be a positive integer between 1 and 10,000.

As long as the collection is not modified during scanning, each document will
appear only once in one of the cursors' result sets.

B<Note>: the server may return fewer cursors than requested, depending on the
underlying storage engine and resource availability.

A hash reference of options may be provided. Valid keys include:

=over 4

=item *

C<maxTimeMS> – the maximum amount of time in milliseconds to allow the command to run.  (Note, this will be ignored for servers before version 3.4.)

=back

=head2 rename

    $newcollection = $collection->rename("mynewcollection");

Renames the collection.  If a collection already exists with the new collection
name, this method will throw an exception.

It returns a new L<MongoDB::Collection> object corresponding to the renamed
collection.

=head2 drop

    $collection->drop;

Deletes a collection as well as all of its indexes.

=head2 ordered_bulk

    $bulk = $coll->ordered_bulk;
    $bulk->insert_one( $doc1 );
    $bulk->insert_one( $doc2 );
    ...
    $result = $bulk->execute;

Returns a L<MongoDB::BulkWrite> object to group write operations into fewer network
round-trips.  This method creates an B<ordered> operation, where operations halt after
the first error. See L<MongoDB::BulkWrite> for more details.

The method C<initialize_ordered_bulk_op> may be used as an alias.

A hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=back

=head2 unordered_bulk

This method works just like L</ordered_bulk> except that the order that
operations are sent to the database is not guaranteed and errors do not halt processing.
See L<MongoDB::BulkWrite> for more details.

The method C<initialize_unordered_bulk_op> may be used as an alias.

A hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=back

=head2 bulk_write

    $res = $coll->bulk_write( [ @requests ], $options )

This method provides syntactic sugar to construct and execute a bulk operation
directly, without using C<initialize_ordered_bulk> or
C<initialize_unordered_bulk> to generate a L<MongoDB::BulkWrite> object and
then calling methods on it.  It returns a L<MongoDB::BulkWriteResponse> object
just like the L<MongoDB::BulkWrite execute|MongoDB::BulkWrite/execute> method.

The first argument must be an array reference of requests.  Requests consist
of pairs of a MongoDB::Collection write method name (e.g. C<insert_one>,
C<delete_many>) and an array reference of arguments to the corresponding
method name.  They may be given as pairs, or as hash or array
references:

    # pairs -- most efficient
    @requests = (
        insert_one  => [ { x => 1 } ],
        replace_one => [ { x => 1 }, { x => 4 } ],
        delete_one  => [ { x => 4 } ],
        update_many => [ { x => { '$gt' => 5 } }, { '$inc' => { x => 1 } } ],
    );

    # hash references
    @requests = (
        { insert_one  => [ { x => 1 } ] },
        { replace_one => [ { x => 1 }, { x => 4 } ] },
        { delete_one  => [ { x => 4 } ] },
        { update_many => [ { x => { '$gt' => 5 } }, { '$inc' => { x => 1 } } ] },
    );

    # array references
    @requests = (
        [ insert_one  => [ { x => 1 } ] ],
        [ replace_one => [ { x => 1 }, { x => 4 } ] ],
        [ delete_one  => [ { x => 4 } ] ],
        [ update_many => [ { x => { '$gt' => 5 } }, { '$inc' => { x => 1 } } ] ],
    );

Valid method names include C<insert_one>, C<insert_many>, C<delete_one>,
C<delete_many> C<replace_one>, C<update_one>, C<update_many>.

An optional hash reference of options may be provided.

Valid options include:

=over 4

=item *

C<bypassDocumentValidation> - skips document validation, if enabled; this is ignored for MongoDB servers older than version 3.2.

=item *

C<ordered> – when true, the bulk operation is executed like L</initialize_ordered_bulk>. When false, the bulk operation is executed like L</initialize_unordered_bulk>.  The default is true.

=back

See L<MongoDB::BulkWrite> for more details on bulk writes.  Be advised that
the legacy Bulk API method names differ slightly from MongoDB::Collection
method names.

=for Pod::Coverage initialize_ordered_bulk_op
initialize_unordered_bulk_op
batch_insert
find_and_modify
insert
query
remove
update

=head1 DEPRECATIONS

With the introduction of the common driver CRUD API, these legacy methods
have been deprecated:

=over 4

=item *

batch_insert

=item *

find_and_modify

=item *

insert

=item *

query

=item *

remove

=item *

update

=item *

save

=back

The C<get_collection> method is deprecated; it implied a 'subcollection'
relationship that is purely notional.

The C<ensure_index>, C<drop_indexes>, C<drop_index>, and C<get_index>
methods are deprecated. The new L<MongoDB::IndexView> class is accessible
through the C<indexes> method, and offer greater consistency in behavior
across drivers.

The C<validate> method is deprecated as the return value was inconsistent
over time. Users who need it should execute it via C<run_command> instead.

The methods still exist, but are no longer documented.  In a future version
they will warn when used, then will eventually be removed.

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

This software is Copyright (c) 2018 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
