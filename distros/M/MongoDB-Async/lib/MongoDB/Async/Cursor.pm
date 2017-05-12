#
#  Copyright 2009 10gen, Inc.
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

package MongoDB::Async::Cursor;
{
  $MongoDB::Async::Cursor::VERSION = '0.702.3';
}


# ABSTRACT: A cursor/iterator for Mongo query results
use Moose;
use boolean;
use Tie::IxHash;


$MongoDB::Async::Cursor::_request_id = int(rand(1000000));


$MongoDB::Async::Cursor::slave_okay = 0;


$MongoDB::Async::Cursor::timeout = 30000;

# $MongoDB::Async::Cursor::inflate_dbrefs;
# cache refresher tied here, see BSON.pm

has started_iterating => (
    is => 'rw',
    isa => 'Bool',
    required => 1,
    default => 0,
);

has _client => (
    is => 'ro',
    isa => 'MongoDB::Async::MongoClient',
    required => 1,
);

has _ns => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has _query => (
    is => 'rw',
    required => 1,
);

has _fields => (
    is => 'rw',
    required => 0,
);

has _limit => (
    is => 'rw',
    isa => 'Int',
    required => 0,
    default => 0,
);

has _skip => (
    is => 'rw',
    isa => 'Int',
    required => 0,
    default => 0,
);

has _tailable => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);






has immortal => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);



has partial => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);


has slave_okay => (
    is => 'rw',
    isa => 'Bool',
    required => 0,
    default => 0,
);




has _request_id => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);


sub _ensure_special {
    my ($self) = @_;

    return if ($self->{_grrrr}); # stupid hack for inconsistent database handling of queries

    $self->{_grrrr} = 1;
    $self->{_query} = {'query' => $self->{_query} };
}

# this does the query if it hasn't been done yet
sub _do_query {
    my ($self) = @_;

    return if $self->{started_iterating};

    my $opts = ($self->{_tailable} << 1) |
        (($MongoDB::Async::Cursor::slave_okay | $self->{slave_okay}) << 2) |
        ($self->{immortal} << 4) |
        ($self->{partial} << 7);

    my ($query, $info) = MongoDB::Async::write_query(
		$self->{_ns}, 
		$opts, 
		$self->{_skip}, 
		$self->{_limit}, 
		$self->{_query}, 
		$self->{_fields});
    $self->{_request_id} = $info->{'request_id'};

    # $self->{_client}->send($query); # now this in XS too
	return $query;
	
	
    # $self->_client->recv($self);
	
	#Weird shit happens with perl stack if we call perl from XS and try to switch Coro threads in recv. 
	#I think problem is in macros that used to call perl sub from xs.
	#Maybe it's some "static" global(per file) var in one of perl .h files used by those macro, and when coro switches stacks: 
	#  -> Cursor xs uses macros (with global var) [point 1] to call perl do_query sub -> perl sub calls XS recv() sub -> recv() switches coro threads while waiting response -> another coro perl thread calls Cursorxs sub thath calls do_query from XS using perl macros, and here shit happens, some used in [point 1] structures got overwritten and when stack goes back to [point 1] it segfaults
	#But i'm not sure about it, maybe i'm wrong. 
	#So call recv from Cursor.xs
	

    # $self->{started_iterating}(1);
	# now XS sets this
}


sub fields {
    my ($self, $f) = @_;
    confess "cannot set fields after querying"
	if $self->{started_iterating};
    confess 'not a hash reference'
		unless ref $f eq 'HASH' || ref $f eq 'Tie::IxHash';

    $self->{_fields} = $f;
    return $self;
}


sub sort {
    my ($self, $order) = @_;
	
    confess "cannot set sort after querying"
	if $self->{started_iterating};
	
    confess 'not a hash reference'
		unless ref $order eq 'HASH' || ref $order eq 'Tie::IxHash';

	
    $self->_ensure_special;
    $self->{_query}->{'orderby'} = $order;
    return $self;
}



sub limit {
    my ($self, $num) = @_;
    confess "cannot set limit after querying"
	if $self->{started_iterating};

    $self->{_limit} = $num;
    return $self;
}



sub tailable {
	my($self, $bool) = @_;
	confess "Cannot set tailable after querying"
	if $self->{started_iterating};
	
	$self->{_tailable} = $bool;
	return $self;
}




sub skip {
    my ($self, $num) = @_;
    confess "cannot set skip after querying"
	if $self->{started_iterating};

    $self->_skip($num);
    return $self;
}


sub snapshot {
    my ($self) = @_;
    confess "cannot set snapshot after querying"
	if $self->{started_iterating};

    $self->_ensure_special;
    $self->{_query}{'$snapshot'} = 1;
    return $self;
}


sub hint {
    my ($self, $index) = @_;
    confess "cannot set hint after querying"
	if $self->{started_iterating};
    confess 'not a hash reference'
		unless ref $index eq 'HASH' || ref $index eq 'Tie::IxHash';

    $self->_ensure_special;
    $self->{_query}{'$hint'} = $index;
    return $self;
}


sub explain {
    my ($self) = @_;
    my $temp = $self->{_limit};
    if ($self->{_limit} > 0) {
        $self->{_limit} *= -1;
    }

    $self->_ensure_special;
    $self->{_query}{'$explain'} = boolean::true;

    my $retval = $self->reset->next;
	
    $self->reset->{limit} = $temp;

    undef $self->{_query}{'$explain'};

    return $retval;
}


sub count {
    my ($self, $all) = @_;

    my ($db, $coll) = $self->_ns =~ m/^([^\.]+)\.(.*)/;
    my $cmd = new Tie::IxHash(count => $coll);

    if ($self->{_grrrr}) {
        $cmd->Push(query => $self->{_query}{'query'});
    }
    else {
        $cmd->Push(query => $self->{_query});
    }

    if ($all) {
        $cmd->Push(limit => $self->{_limit}) if $self->{_limit};
        $cmd->Push(skip => $self->{_skip}) if $self->{_skip};
    }

    my $result = $self->_client->get_database($db)->run_command($cmd);

    # returns "ns missing" if collection doesn't exist
    return 0 unless ref $result eq 'HASH';
    return $result->{'n'};
}



sub all {@{$_[0]->data}};


__PACKAGE__->meta->make_immutable (inline_destructor => 0);

1;

__END__

=pod

=head1 NAME

MongoDB::Async::Cursor - A cursor/iterator for Mongo query results

=head1 VERSION

version 0.702.3

=head1 SYNOPSIS

    while (my $object = $cursor->next) {
        ...
    }

    my @objects = $cursor->all;

=head2 Multithreading

Cloning instances of this class is disabled in Perl 5.8.7+, so forked threads
will have to create their own database queries.

=head1 NAME

MongoDB::Async::Cursor - A cursor/iterator for Mongo query results

=head1 SEE ALSO

Core documentation on cursors: L<http://dochub.mongodb.org/core/cursors>.

=head1 STATIC ATTRIBUTES

=head2 slave_okay

    $MongoDB::Async::Cursor::slave_okay = 1;

Whether it is okay to run queries on the slave.  Defaults to 0.

=head2 timeout

B<Deprecated, use MongoDB::Async::Connection::query_timeout instead.>

How many milliseconds to wait for a response from the server.  Set to 30000
(30 seconds) by default.  -1 waits forever (or until TCP times out, which is
usually a long time).

This value is overridden by C<MongoDB::Async::Connection::query_timeout> and never
used.

=head1 ATTRIBUTES

=head2 started_iterating

If this cursor has queried the database yet. Methods
mofifying the query will complain if they are called
after the database is queried.

=head2 immortal

    $cursor->immortal(1);

Ordinarily, a cursor "dies" on the database server after a certain length of
time (approximately 10 minutes), to prevent inactive cursors from hogging
resources.  This option sets that a cursor should not die until all of its
results have been fetched or it goes out of scope in Perl.

Boolean value, defaults to 0.

C<immortal> is not equivalent to setting a client-side timeout.  If you are
getting client-side timeouts (e.g., "recv timed out"), set C<query_timeout> on
your connection.

    # wait forever for a query to return results
    $connection->query_timeout(-1);

See L<MongoDB::Async::Connection/query_timeout>.

=head2 partial

If a shard is down, mongos will return an error when it tries to query that
shard.  If this is set, mongos will just skip that shard, instead.

Boolean value, defaults to 0.

=head2 slave_okay

    $cursor->slave_okay(1);

If a query can be done on a slave database server.

Boolean value, defaults to 0.

=head1 METHODS

=head2 fields (\%f)

    $coll->insert({name => "Fred", age => 20});
    my $cursor = $coll->query->fields({ name => 1 });
    my $obj = $cursor->next;
    $obj->{name}; "Fred"
    $obj->{age}; # undef

Selects which fields are returned.
The default is all fields.  _id is always returned.

=head2 sort ($order)

    # sort by name, descending
    my $sort = {"name" => -1};
    $cursor = $coll->query->sort($sort);

Adds a sort to the query.  Argument is either
a hash reference or a Tie::IxHash.
Returns this cursor for chaining operations.

=head2 limit ($num)

    $per_page = 20;
    $cursor = $coll->query->limit($per_page);

Returns a maximum of N results.
Returns this cursor for chaining operations.

=head2 tailable ($bool)

    $cursor->query->tailable(1);

If a cursor should be tailable.  Tailable cursors can only be used on capped
collections and are similar to the C<tail -f> command: they never die and keep
returning new results as more is added to a collection.

They are often used for getting log messages.

Boolean value, defaults to 0.

Returns this cursor for chaining operations.

=head2 skip ($num)

    $page_num = 7;
    $per_page = 100;
    $cursor = $coll->query->limit($per_page)->skip($page_num * $per_page);

Skips the first N results. Returns this cursor for chaining operations.

See also core documentation on limit: L<http://dochub.mongodb.org/core/limit>.

=head2 snapshot

    my $cursor = $coll->query->snapshot;

Uses snapshot mode for the query.  Snapshot mode assures no
duplicates are returned, or objects missed, which were present
at both the start and end of the query's execution (if an object
is new during the query, or deleted during the query, it may or
may not be returned, even with snapshot mode).  Note that short
query responses (less than 1MB) are always effectively
snapshotted.  Currently, snapshot mode may not be used with
sorting or explicit hints.

=head2 hint

    my $cursor = $coll->query->hint({'x' => 1});

Force Mongo to use a specific index for a query.

=head2 explain

    my $explanation = $cursor->explain;

This will tell you the type of cursor used, the number of records the DB had to
examine as part of this query, the number of records returned by the query, and
the time in milliseconds the query took to execute.  Requires L<boolean> package.

C<explain> resets the cursor, so calling C<next> or C<has_next> after an explain
will requery the database.

See also core documentation on explain:
L<http://dochub.mongodb.org/core/explain>.

=head2 count($all?)

    my $num = $cursor->count;
    my $num = $cursor->skip(20)->count(1);

Returns the number of document this query will return.  Optionally takes a
boolean parameter, indicating that the cursor's limit and skip fields should be
used in calculating the count.

=head2 reset

Resets the cursor.  After being reset, pre-query methods can be
called on the cursor (sort, limit, etc.) and subsequent calls to
next, has_next, or all will re-query the database.

=head2 has_next

    while ($cursor->has_next) {
        ...
    }

Checks if there is another result to fetch.

=head2 next

    while (my $object = $cursor->next) {
        ...
    }

Returns the next object in the cursor. Will automatically fetch more data from
the server if necessary. Returns undef if no more data is available.

=head2 info

Returns a hash of information about this cursor.  Currently the fields are:

=over 4

=item C<cursor_id>

The server-side id for this cursor.  A C<cursor_id> of 0 means that there are no
more batches to be fetched.

=item C<num>

The number of results returned so far.

=item C<at>

The index of the result the cursor is currently at.

=item C<flag>

If the database could not find the cursor or another error occurred, C<flag> may
be set (depending on the error).
See L<http://www.mongodb.org/display/DOCS/Mongo+Wire+Protocol#MongoWireProtocol-OPREPLY>
for a full list of flag values.

=item C<start>

The index of the result that the current batch of results starts at.

=back

=head2 all

    my @objects = $cursor->all;

Returns a list of all objects in the result.

=head1 AUTHOR

  Kristina Chodorow <kristina@mongodb.org>

=head1 AUTHORS

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Kristina Chodorow <kristina@mongodb.org>

=item *

Mike Friedman <mike.friedman@10gen.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by 10gen, Inc..

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
