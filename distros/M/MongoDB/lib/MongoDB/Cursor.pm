#  Copyright 2009 - present MongoDB, Inc.
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
package MongoDB::Cursor;


# ABSTRACT: A lazy cursor for Mongo query results

use version;
our $VERSION = 'v2.2.2';

use Moo;
use MongoDB::Error;
use MongoDB::QueryResult;
use MongoDB::ReadPreference;
use MongoDB::_Protocol;
use MongoDB::Op::_Explain;
use MongoDB::_Types -types, qw/to_IxHash is_OrderedDoc/;
use Types::Standard qw(
    InstanceOf
    is_Str
);
use boolean;
use Tie::IxHash;
use namespace::clean -except => 'meta';

#pod =attr started_iterating
#pod
#pod A boolean indicating if this cursor has queried the database yet. Methods
#pod modifying the query will complain if they are called after the database is
#pod queried.
#pod
#pod =cut

with $_ for qw(
  MongoDB::Role::_CursorAPI
  MongoDB::Role::_DeprecationWarner
);

# attributes for sending a query
has client => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf ['MongoDB::MongoClient'],
);

has _query => (
    is => 'ro',
    isa => InstanceOf['MongoDB::Op::_Query'],
    required => 1,
    init_arg => 'query',
);

# lazy result attribute
has result => (
    is        => 'lazy',
    isa       => InstanceOf['MongoDB::QueryResult'],
    builder   => '_build_result',
    predicate => 'started_iterating',
    clearer   => '_clear_result',
);

# this does the query if it hasn't been done yet
sub _build_result {
    my ($self) = @_;

    return $self->{client}->send_retryable_read_op( $self->_query );
}

#--------------------------------------------------------------------------#
# methods that modify the query
#--------------------------------------------------------------------------#

#pod =head1 QUERY MODIFIERS
#pod
#pod These methods modify the query to be run.  An exception will be thrown if
#pod they are called after results are iterated.
#pod
#pod =head2 immortal
#pod
#pod     $cursor->immortal(1);
#pod
#pod Ordinarily, a cursor "dies" on the database server after a certain length of
#pod time (approximately 10 minutes), to prevent inactive cursors from hogging
#pod resources.  This option indicates that a cursor should not die until all of its
#pod results have been fetched or it goes out of scope in Perl.
#pod
#pod Boolean value, defaults to 0.
#pod
#pod Note: C<immortal> only affects the server-side timeout.  If you are getting
#pod client-side timeouts you will need to change your client configuration.
#pod See L<MongoDB::MongoClient/max_time_ms> and
#pod L<MongoDB::MongoClient/socket_timeout_ms>.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub immortal {
    my ( $self, $bool ) = @_;
    MongoDB::UsageError->throw("cannot set immortal after querying")
        if $self->started_iterating;

    $self->_query->set_noCursorTimeout($bool);
    return $self;
}

#pod =head2 fields
#pod
#pod     $coll->insert({name => "Fred", age => 20});
#pod     my $cursor = $coll->find->fields({ name => 1 });
#pod     my $obj = $cursor->next;
#pod     $obj->{name}; "Fred"
#pod     $obj->{age}; # undef
#pod
#pod Selects which fields are returned.  The default is all fields.  When fields
#pod are specified, _id is returned by default, but this can be disabled by
#pod explicitly setting it to "0".  E.g.  C<< _id => 0 >>. Argument must be either a
#pod hash reference or a L<Tie::IxHash> object.
#pod
#pod See L<Limit fields to
#pod return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>
#pod in the MongoDB documentation for details.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub fields {
    my ($self, $f) = @_;
    MongoDB::UsageError->throw("cannot set fields after querying")
      if $self->started_iterating;
    MongoDB::UsageError->throw("not a hash reference")
      unless ref $f eq 'HASH' || ref $f eq 'Tie::IxHash';

    $self->_query->set_projection($f);
    return $self;
}

#pod =head2 sort
#pod
#pod     # sort by name, descending
#pod     $cursor->sort([name => -1]);
#pod
#pod Adds a sort to the query.  Argument is either a hash reference or a
#pod L<Tie::IxHash> or an array reference of key/value pairs.  Because hash
#pod references are not ordered, do not use them for more than one key.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub sort {
    my ( $self, $order ) = @_;
    MongoDB::UsageError->throw("cannot set sort after querying")
      if $self->started_iterating;

    $self->_query->set_sort($order);
    return $self;
}


#pod =head2 limit
#pod
#pod     $cursor->limit(20);
#pod
#pod Sets cursor to return a maximum of N results.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub limit {
    my ( $self, $num ) = @_;
    MongoDB::UsageError->throw("cannot set limit after querying")
      if $self->started_iterating;
    $self->_query->set_limit($num);
    return $self;
}


#pod =head2 max_await_time_ms
#pod
#pod     $cursor->max_await_time_ms( 500 );
#pod
#pod The maximum amount of time in milliseconds for the server to wait on new
#pod documents to satisfy a tailable cursor query. This only applies to a
#pod cursor of type 'tailble_await'.  This is ignored if the cursor is not
#pod a 'tailable_await' cursor or the server version is less than version 3.2.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub max_await_time_ms {
    my ( $self, $num ) = @_;
    $num = 0 unless defined $num;
    MongoDB::UsageError->throw("max_await_time_ms must be non-negative")
      if $num < 0;
    MongoDB::UsageError->throw("can not set max_await_time_ms after querying")
      if $self->started_iterating;

    $self->_query->set_maxAwaitTimeMS( $num );
    return $self;
}

#pod =head2 max_time_ms
#pod
#pod     $cursor->max_time_ms( 500 );
#pod
#pod Causes the server to abort the operation if the specified time in milliseconds
#pod is exceeded.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub max_time_ms {
    my ( $self, $num ) = @_;
    $num = 0 unless defined $num;
    MongoDB::UsageError->throw("max_time_ms must be non-negative")
      if $num < 0;
    MongoDB::UsageError->throw("can not set max_time_ms after querying")
      if $self->started_iterating;

    $self->_query->set_maxTimeMS( $num );
    return $self;

}

#pod =head2 tailable
#pod
#pod     $cursor->tailable(1);
#pod
#pod If a cursor should be tailable.  Tailable cursors can only be used on capped
#pod collections and are similar to the C<tail -f> command: they never die and keep
#pod returning new results as more is added to a collection.
#pod
#pod They are often used for getting log messages.
#pod
#pod Boolean value, defaults to 0.
#pod
#pod If you want the tailable cursor to block for a few seconds, use
#pod L</tailable_await> instead.  B<Note> calling this with a false value
#pod disables tailing, even if C<tailable_await> was previously called.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub tailable {
    my ( $self, $bool ) = @_;
    MongoDB::UsageError->throw("cannot set tailable after querying")
        if $self->started_iterating;

    $self->_query->set_cursorType($bool ? 'tailable' : 'non_tailable');
    return $self;
}

#pod =head2 tailable_await
#pod
#pod     $cursor->tailable_await(1);
#pod
#pod Sets a cursor to be tailable and block for a few seconds if no data
#pod is immediately available.
#pod
#pod Boolean value, defaults to 0.
#pod
#pod If you want the tailable cursor without blocking, use L</tailable> instead.
#pod B<Note> calling this with a false value disables tailing, even if C<tailable>
#pod was previously called.
#pod
#pod =cut

sub tailable_await {
    my ( $self, $bool ) = @_;
    MongoDB::UsageError->throw("cannot set tailable_await after querying")
        if $self->started_iterating;

    $self->_query->set_cursorType($bool ? 'tailable_await' : 'non_tailable');
    return $self;
}

#pod =head2 skip
#pod
#pod     $cursor->skip( 50 );
#pod
#pod Skips the first N results.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub skip {
    my ( $self, $num ) = @_;
    MongoDB::UsageError->throw("skip must be non-negative")
      if $num < 0;
    MongoDB::UsageError->throw("cannot set skip after querying")
      if $self->started_iterating;

    $self->_query->set_skip($num);
    return $self;
}

#pod =head2 hint
#pod
#pod Hint the query to use a specific index by name:
#pod
#pod     $cursor->hint("index_name");
#pod
#pod Hint the query to use index based on individual keys and direction:
#pod
#pod     $cursor->hint([field_1 => 1, field_2 => -1, field_3 => 1]);
#pod
#pod Use of a hash reference should be avoided except for single key indexes.
#pod
#pod The hint must be a string or L<ordered document|MongoDB::Collection/Ordered
#pod document>.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub hint {
    my ( $self, $index ) = @_;
    MongoDB::UsageError->throw("cannot set hint after querying")
      if $self->started_iterating;
    MongoDB::UsageError->throw("hint must be string or ordered document, not '$index'")
      if ! (is_Str($index) || is_OrderedDoc($index));

    $self->_query->set_hint( $index );

    return $self;
}

#pod =head2 partial
#pod
#pod     $cursor->partial(1);
#pod
#pod If a shard is down, mongos will return an error when it tries to query that
#pod shard.  If this is set, mongos will just skip that shard, instead.
#pod
#pod Boolean value, defaults to 0.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub partial {
    my ($self, $value) = @_;
    MongoDB::UsageError->throw("cannot set partial after querying")
      if $self->started_iterating;

    $self->_query->set_allowPartialResults( $value );

    # returning self is an API change but more consistent with other cursor methods
    return $self;
}

#pod =head2 read_preference
#pod
#pod     $cursor->read_preference($read_preference_object);
#pod     $cursor->read_preference('secondary', [{foo => 'bar'}]);
#pod
#pod Sets read preference for the cursor's connection.
#pod
#pod If given a single argument that is a L<MongoDB::ReadPreference> object, the
#pod read preference is set to that object.  Otherwise, it takes positional
#pod arguments: the read preference mode and a tag set list, which must be a valid
#pod mode and tag set list as described in the L<MongoDB::ReadPreference>
#pod documentation.
#pod
#pod Returns this cursor for chaining operations.
#pod
#pod =cut

sub read_preference {
    my $self = shift;
    MongoDB::UsageError->throw("cannot set read preference after querying")
      if $self->started_iterating;

    my $type = ref $_[0];
    if ( $type eq 'MongoDB::ReadPreference' ) {
        $self->_query->read_preference( $_[0] );
    }
    else {
        my $mode     = shift || 'primary';
        my $tag_sets = shift;
        my $rp       = MongoDB::ReadPreference->new(
            mode => $mode,
            ( $tag_sets ? ( tag_sets => $tag_sets ) : () )
        );
        $self->_query->read_preference($rp);
    }

    return $self;
}

#pod =head1 QUERY INTROSPECTION AND RESET
#pod
#pod These methods run introspection methods on the query conditions and modifiers
#pod stored within the cursor object.
#pod
#pod =head2 explain
#pod
#pod     my $explanation = $cursor->explain;
#pod
#pod This will tell you the type of cursor used, the number of records the DB had to
#pod examine as part of this query, the number of records returned by the query, and
#pod the time in milliseconds the query took to execute.
#pod
#pod See also core documentation on explain:
#pod L<http://dochub.mongodb.org/core/explain>.
#pod
#pod =cut

sub explain {
    my ($self) = @_;

    my $explain_op = MongoDB::Op::_Explain->_new(
        db_name             => $self->_query->db_name,
        coll_name           => $self->_query->coll_name,
        full_name           => $self->_query->full_name,
        bson_codec          => $self->_query->bson_codec,
        query               => $self->_query,
        read_preference     => $self->_query->read_preference,
        read_concern        => $self->_query->read_concern,
        session             => $self->_query->session,
        monitoring_callback => $self->client->monitoring_callback,
    );

    return $self->_query->client->send_retryable_read_op($explain_op);
}

#pod =head1 QUERY ITERATION
#pod
#pod These methods allow you to iterate over results.
#pod
#pod =head2 result
#pod
#pod     my $result = $cursor->result;
#pod
#pod This method will execute the query and return a L<MongoDB::QueryResult> object
#pod with the results.
#pod
#pod The C<has_next>, C<next>, and C<all> methods call C<result> internally,
#pod which executes the query "on demand".
#pod
#pod Iterating with a MongoDB::QueryResult object directly instead of a
#pod L<MongoDB::Cursor> will be slightly faster, since the L<MongoDB::Cursor>
#pod methods below just internally call the corresponding method on the result
#pod object.
#pod
#pod =cut

#--------------------------------------------------------------------------#
# methods delgated to result object
#--------------------------------------------------------------------------#

#pod =head2 has_next
#pod
#pod     while ($cursor->has_next) {
#pod         ...
#pod     }
#pod
#pod Checks if there is another result to fetch.  Will automatically fetch more
#pod data from the server if necessary.
#pod
#pod =cut

sub has_next { $_[0]->result->has_next }

#pod =head2 next
#pod
#pod     while (my $object = $cursor->next) {
#pod         ...
#pod     }
#pod
#pod Returns the next object in the cursor. Will automatically fetch more data from
#pod the server if necessary. Returns undef if no more data is available.
#pod
#pod =cut

sub next { $_[0]->result->next }

#pod =head2 batch
#pod
#pod     while (my @batch = $cursor->batch) {
#pod         ...
#pod     }
#pod
#pod Returns the next batch of data from the cursor. Will automatically fetch more
#pod data from the server if necessary. Returns an empty list if no more data is available.
#pod
#pod =cut

sub batch { $_[0]->result->batch }

#pod =head2 all
#pod
#pod     my @objects = $cursor->all;
#pod
#pod Returns a list of all objects in the result.
#pod
#pod =cut

sub all { $_[0]->result->all }

#pod =head2 reset
#pod
#pod Resets the cursor.  After being reset, pre-query methods can be
#pod called on the cursor (sort, limit, etc.) and subsequent calls to
#pod result, next, has_next, or all will re-query the database.
#pod
#pod =cut

sub reset {
    my ($self) = @_;
    $self->_clear_result;
    return $self;
}

#pod =head2 info
#pod
#pod Returns a hash of information about this cursor.  This is intended for
#pod debugging purposes and users should not rely on the contents of this method for
#pod production use.  Currently the fields are:
#pod
#pod =for :list
#pod * C<cursor_id>  -- the server-side id for this cursor.  See below for details.
#pod * C<num> -- the number of results received from the server so far
#pod * C<at> -- the (zero-based) index of the document that will be returned next from L</next>
#pod * C<flag> -- if the database could not find the cursor or another error occurred, C<flag> may
#pod   contain a hash reference of flags set in the response (depending on the error).  See
#pod   L<http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol#MongoWireProtocol-OPREPLY>
#pod   for a full list of flag values.
#pod * C<start> -- the index of the result that the current batch of results starts at.
#pod
#pod If the cursor has not yet executed, only the C<num> field will be returned with
#pod a value of 0.
#pod
#pod The C<cursor_id> could appear in one of three forms:
#pod
#pod =for :list
#pod * MongoDB::CursorID object (a blessed reference to an 8-byte string)
#pod * A perl scalar (an integer)
#pod * A Math::BigInt object (64 bit integer on 32-bit perl)
#pod
#pod When the C<cursor_id> is zero, there are no more results to fetch.
#pod
#pod =cut

sub info {
    my $self = shift;
    if ( $self->started_iterating ) {
        return $self->result->_info;
    }
    else {
        return { num => 0 };
    }
}

#--------------------------------------------------------------------------#
# Deprecated methods
#--------------------------------------------------------------------------#

sub snapshot {
    my ($self, $bool) = @_;

    $self->_warn_deprecated_method(
        'snapshot' => "Snapshot is deprecated as of MongoDB 3.6" );

    MongoDB::UsageError->throw("cannot set snapshot after querying")
      if $self->started_iterating;

    MongoDB::UsageError->throw("snapshot requires a defined, boolean argument")
      unless defined $bool;

    $self->_query->set_snapshot($bool);
    return $self;
}

1;



# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::Cursor - A lazy cursor for Mongo query results

=head1 VERSION

version v2.2.2

=head1 SYNOPSIS

    while (my $object = $cursor->next) {
        ...
    }

    my @objects = $cursor->all;

=head1 USAGE

=head2 Multithreading

B<NOTE>: Per L<threads> documentation, use of Perl threads is discouraged by the
maintainers of Perl and the MongoDB Perl driver does not test or provide support
for use with threads.

Cursors are cloned in threads, but not reset.  Iterating the same cursor from
multiple threads will give unpredictable results.  Only iterate from a single
thread.

=head1 ATTRIBUTES

=head2 started_iterating

A boolean indicating if this cursor has queried the database yet. Methods
modifying the query will complain if they are called after the database is
queried.

=head1 QUERY MODIFIERS

These methods modify the query to be run.  An exception will be thrown if
they are called after results are iterated.

=head2 immortal

    $cursor->immortal(1);

Ordinarily, a cursor "dies" on the database server after a certain length of
time (approximately 10 minutes), to prevent inactive cursors from hogging
resources.  This option indicates that a cursor should not die until all of its
results have been fetched or it goes out of scope in Perl.

Boolean value, defaults to 0.

Note: C<immortal> only affects the server-side timeout.  If you are getting
client-side timeouts you will need to change your client configuration.
See L<MongoDB::MongoClient/max_time_ms> and
L<MongoDB::MongoClient/socket_timeout_ms>.

Returns this cursor for chaining operations.

=head2 fields

    $coll->insert({name => "Fred", age => 20});
    my $cursor = $coll->find->fields({ name => 1 });
    my $obj = $cursor->next;
    $obj->{name}; "Fred"
    $obj->{age}; # undef

Selects which fields are returned.  The default is all fields.  When fields
are specified, _id is returned by default, but this can be disabled by
explicitly setting it to "0".  E.g.  C<< _id => 0 >>. Argument must be either a
hash reference or a L<Tie::IxHash> object.

See L<Limit fields to
return|http://docs.mongodb.org/manual/tutorial/project-fields-from-query-results/>
in the MongoDB documentation for details.

Returns this cursor for chaining operations.

=head2 sort

    # sort by name, descending
    $cursor->sort([name => -1]);

Adds a sort to the query.  Argument is either a hash reference or a
L<Tie::IxHash> or an array reference of key/value pairs.  Because hash
references are not ordered, do not use them for more than one key.

Returns this cursor for chaining operations.

=head2 limit

    $cursor->limit(20);

Sets cursor to return a maximum of N results.

Returns this cursor for chaining operations.

=head2 max_await_time_ms

    $cursor->max_await_time_ms( 500 );

The maximum amount of time in milliseconds for the server to wait on new
documents to satisfy a tailable cursor query. This only applies to a
cursor of type 'tailble_await'.  This is ignored if the cursor is not
a 'tailable_await' cursor or the server version is less than version 3.2.

Returns this cursor for chaining operations.

=head2 max_time_ms

    $cursor->max_time_ms( 500 );

Causes the server to abort the operation if the specified time in milliseconds
is exceeded.

Returns this cursor for chaining operations.

=head2 tailable

    $cursor->tailable(1);

If a cursor should be tailable.  Tailable cursors can only be used on capped
collections and are similar to the C<tail -f> command: they never die and keep
returning new results as more is added to a collection.

They are often used for getting log messages.

Boolean value, defaults to 0.

If you want the tailable cursor to block for a few seconds, use
L</tailable_await> instead.  B<Note> calling this with a false value
disables tailing, even if C<tailable_await> was previously called.

Returns this cursor for chaining operations.

=head2 tailable_await

    $cursor->tailable_await(1);

Sets a cursor to be tailable and block for a few seconds if no data
is immediately available.

Boolean value, defaults to 0.

If you want the tailable cursor without blocking, use L</tailable> instead.
B<Note> calling this with a false value disables tailing, even if C<tailable>
was previously called.

=head2 skip

    $cursor->skip( 50 );

Skips the first N results.

Returns this cursor for chaining operations.

=head2 hint

Hint the query to use a specific index by name:

    $cursor->hint("index_name");

Hint the query to use index based on individual keys and direction:

    $cursor->hint([field_1 => 1, field_2 => -1, field_3 => 1]);

Use of a hash reference should be avoided except for single key indexes.

The hint must be a string or L<ordered document|MongoDB::Collection/Ordered
document>.

Returns this cursor for chaining operations.

=head2 partial

    $cursor->partial(1);

If a shard is down, mongos will return an error when it tries to query that
shard.  If this is set, mongos will just skip that shard, instead.

Boolean value, defaults to 0.

Returns this cursor for chaining operations.

=head2 read_preference

    $cursor->read_preference($read_preference_object);
    $cursor->read_preference('secondary', [{foo => 'bar'}]);

Sets read preference for the cursor's connection.

If given a single argument that is a L<MongoDB::ReadPreference> object, the
read preference is set to that object.  Otherwise, it takes positional
arguments: the read preference mode and a tag set list, which must be a valid
mode and tag set list as described in the L<MongoDB::ReadPreference>
documentation.

Returns this cursor for chaining operations.

=head1 QUERY INTROSPECTION AND RESET

These methods run introspection methods on the query conditions and modifiers
stored within the cursor object.

=head2 explain

    my $explanation = $cursor->explain;

This will tell you the type of cursor used, the number of records the DB had to
examine as part of this query, the number of records returned by the query, and
the time in milliseconds the query took to execute.

See also core documentation on explain:
L<http://dochub.mongodb.org/core/explain>.

=head1 QUERY ITERATION

These methods allow you to iterate over results.

=head2 result

    my $result = $cursor->result;

This method will execute the query and return a L<MongoDB::QueryResult> object
with the results.

The C<has_next>, C<next>, and C<all> methods call C<result> internally,
which executes the query "on demand".

Iterating with a MongoDB::QueryResult object directly instead of a
L<MongoDB::Cursor> will be slightly faster, since the L<MongoDB::Cursor>
methods below just internally call the corresponding method on the result
object.

=head2 has_next

    while ($cursor->has_next) {
        ...
    }

Checks if there is another result to fetch.  Will automatically fetch more
data from the server if necessary.

=head2 next

    while (my $object = $cursor->next) {
        ...
    }

Returns the next object in the cursor. Will automatically fetch more data from
the server if necessary. Returns undef if no more data is available.

=head2 batch

    while (my @batch = $cursor->batch) {
        ...
    }

Returns the next batch of data from the cursor. Will automatically fetch more
data from the server if necessary. Returns an empty list if no more data is available.

=head2 all

    my @objects = $cursor->all;

Returns a list of all objects in the result.

=head2 reset

Resets the cursor.  After being reset, pre-query methods can be
called on the cursor (sort, limit, etc.) and subsequent calls to
result, next, has_next, or all will re-query the database.

=head2 info

Returns a hash of information about this cursor.  This is intended for
debugging purposes and users should not rely on the contents of this method for
production use.  Currently the fields are:

=over 4

=item *

C<cursor_id>  -- the server-side id for this cursor.  See below for details.

=item *

C<num> -- the number of results received from the server so far

=item *

C<at> -- the (zero-based) index of the document that will be returned next from L</next>

=item *

C<flag> -- if the database could not find the cursor or another error occurred, C<flag> may contain a hash reference of flags set in the response (depending on the error).  See L<http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol#MongoWireProtocol-OPREPLY> for a full list of flag values.

=item *

C<start> -- the index of the result that the current batch of results starts at.

=back

If the cursor has not yet executed, only the C<num> field will be returned with
a value of 0.

The C<cursor_id> could appear in one of three forms:

=over 4

=item *

MongoDB::CursorID object (a blessed reference to an 8-byte string)

=item *

A perl scalar (an integer)

=item *

A Math::BigInt object (64 bit integer on 32-bit perl)

=back

When the C<cursor_id> is zero, there are no more results to fetch.

=head1 SEE ALSO

Core documentation on cursors: L<http://dochub.mongodb.org/core/cursors>.

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
