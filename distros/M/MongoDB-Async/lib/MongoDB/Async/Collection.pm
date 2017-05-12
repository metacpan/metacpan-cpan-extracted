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

package MongoDB::Async::Collection;
{
  $MongoDB::Async::Collection::VERSION = '0.702.3';
}


# ABSTRACT: A Mongo Collection


use Tie::IxHash;
use Moose;
use Carp 'carp';
use boolean;

use base 'MongoDB::Async::GetCollCache';

has _database => (
    is       => 'ro',
    isa      => 'MongoDB::Async::Database',
    required => 1,
);


has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

# MongoDB author, why so oop? Fuck, this is not C++ or Java, all this shit is just slow!


sub full_name {
    $_[0]->{_database}{name}.'.'.$_[0]->{name}
}




no strict 'refs';

sub AUTOLOAD {
    my ($self) =@_;
    our $AUTOLOAD;

     my $coll = $AUTOLOAD;
    $coll =~ s/.*:://;
	
	my $sub = eval q/ sub {  $_[0]->{_database}->get_collection('/.$self->{name}.'.'.$coll.q/') } /;
	
	*{'MongoDB::Async::GetCollCache::'.$coll} = $sub;
	
    return $sub->($self);
}
use strict;

sub get_collection { 
	#self, coll
    return $_[0]->{_database}->get_collection($_[0]->{name}.'.'.$_[1]);
}


sub to_index_string {
    my ($keys) = @_;

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
        confess 'expected Tie::IxHash, hash, or array reference for keys';
    }

    return join("_", @name);
}


sub find {
    my ($self, $query, $attrs) = @_;
    # old school options - these should be set with MongoDB::Async::Cursor methods
    my ($limit, $skip, $sort_by) = @{ $attrs || {} }{qw/limit skip sort_by/};
	
    my $cursor = MongoDB::Async::Cursor->new(
	_client => $self->{_database}{_client},
	_ns => $self->{_database}{name}.'.'.$self->{name},
	_query => ($query || {}),
	_limit => ($limit || 0),
	_skip =>  ($skip  || 0)
    );

    $cursor->_init;
	$cursor->sort($sort_by) if ($sort_by);
	
    return $cursor;
}

*query = \&find; 


sub find_one {
    # my ($self, $query, $fields) = @_;

    return $_[0]->find( $_[1] || {} )->limit(-1)->fields( $_[2] || {} )->next;
}



sub insert {
    my ($self, $object, $options) = @_;
    return scalar $self->batch_insert([$object], $options);
}


sub batch_insert {
    my ($self, $object, $options) = @_;
    confess 'not an array reference' unless ref $object eq 'ARRAY';



    my $conn = $self->{_database}{_client};

    my ($insert, $ids) = MongoDB::Async::write_insert(
		$self->{_database}{name}.'.'.$self->{name},
		$object, 
		!$options->{'no_ids'} # add ids
	);
    if (length($insert) > $conn->max_bson_size) {
        Carp::croak("insert is too large: ".length($insert)." max: ".$conn->max_bson_size);
        return 0;
    }
	
    if ( ( defined($options) && $options->{safe} ) or $conn->_w_want_safe ) {
	  return 0 unless ($self->_make_safe($insert));
    }
    else {
		
        $conn->send($insert);
    }

    return $ids ? (wantarray ? @$ids : @{$ids}[0]) : $ids;
}



sub update {
    my ($self, $query, $object, $opts) = @_;

    # there used to be one option: upsert=0/1
    # now there are two, there will probably be
    # more in the future.  So, to support old code,
    # passing "1" will still be supported, but not
    # documentd, so we can phase that out eventually.
    #
    # The preferred way of passing options will be a
    # hash of {optname=>value, ...}
    my $flags = 0;
    if ($opts && ref $opts eq 'HASH') {
        $flags |= $opts->{'upsert'} << 0
            if exists $opts->{'upsert'};
        $flags |= $opts->{'multiple'} << 1
            if exists $opts->{'multiple'};
    }
    else {
        $flags = !(!$opts);
    }

    my $conn = $self->{_database}{_client};

    my $update = MongoDB::Async::write_update(
		$self->{_database}{name}.'.'.$self->{name},
		$query,
		$object, 
		$flags
	);
	
    return $self->_make_safe($update) if ($opts->{safe}  or $conn->_w_want_safe  );


   $conn->send($update);

    return 1;
}




sub find_and_modify { 
    my ( $self, $opts ) = @_;

    my $result = $self->{_database}->run_command( [ findAndModify => $self->{name}, %$opts ] );
    if ( not $result->{ok} ) { 
        return if ( $result->{errmsg} eq 'No matching object found' );
    }

    return $result->{value};
}



sub aggregate { 
    my ( $self, $pipeline ) = @_;

    my $result = $self->{_database}->run_command( [ aggregate => $self->{name}, pipeline => $pipeline ] );

    # TODO: handle errors?

    return $result->{result};
}




sub rename {
    my ($self, $collectionname) = @_;


	my $conn = $self->{_database}{_client};
	
    my $obj = 
	$conn->get_database( 'admin' )->run_command([ 
		'renameCollection' => $self->{_database}{name}.'.'.$self->{name} ,
		'to' => $self->{_database}{name}.'.'.$collectionname
	]);

    if(ref($obj) eq "HASH"){
      return $conn->get_database( $self->{_database}{name} )->get_collection( $collectionname );
    }
    else {
      die $obj;
    }
}


sub remove {
    my ($self, $query, $options) = @_;

    my ($just_one, $safe);
    if (defined $options && ref $options eq 'HASH') {
        $just_one = exists $options->{just_one} ? $options->{just_one} : 0;
        $safe =  $options->{safe} or $self->{_database}{_client}->_w_want_safe;
    }
    else {
        $just_one = $options || 0;
    }


    $query ||= {};

    my $remove = MongoDB::Async::write_remove(
		$self->{_database}{name}.'.'.$self->{name} , # ns
		$query,
		$just_one
	);
	
    return $self->_make_safe($remove) if ($safe);

    $self->{_database}{_client}->send($remove);

    return 1;
}


sub ensure_index {
    my ($self, $keys, $options, $garbage) = @_;
    # we need to use the crappy old api if...
    #  - $options isn't a hash, it's a string like "ascending"
    #  - $keys is a one-element array: [foo]
    #  - $keys is an array with more than one element and the second
    #    element isn't a direction (or at least a good one)
    #  - Tie::IxHash has values like "ascending"
    if (($options && ref $options ne 'HASH') ||
        (ref $keys eq 'ARRAY' &&
         ($#$keys == 0 || $#$keys >= 1 && !($keys->[1] =~ /-?1/))) ||
        (ref $keys eq 'Tie::IxHash' && $keys->[2][0] =~ /(de|a)scending/)) {
        Carp::croak("you're using the old ensure_index format, please upgrade");
    }

	$keys = Tie::IxHash->new(@$keys) if ref $keys eq 'ARRAY';
	
    my $obj = Tie::IxHash->new(
		"ns" => $self->{_database}{name}.'.'.$self->{name} ,  
		"key" => $keys
	);

    if (exists $options->{name}) {
        $obj->Push("name" => $options->{name});
    }
    else {
        $obj->Push("name" => MongoDB::Async::Collection::to_index_string($keys));
    }

    foreach ("unique", "drop_dups", "background", "sparse") {
        if (exists $options->{$_}) {
            $obj->Push("$_" => ($options->{$_} ? boolean::true : boolean::false));
        }
    }
    $options->{'no_ids'} = 1;
	
	if (exists $options->{expire_after_seconds}) {
        $obj->Push("expireAfterSeconds" => int($options->{expire_after_seconds}));
    }

    return $self->{_database}->get_collection("system.indexes")->insert($obj, $options);
}


sub _make_safe {
    my ($self, $req) = @_;
    my $conn = $self->{_database}{_client};

    my $last_error = Tie::IxHash->new(getlasterror => 1, w => $conn->w, wtimeout => $conn->wtimeout, j => $conn->j);
    my ($query, $info) = MongoDB::Async::write_query( $self->{_database}{name}.'.$cmd', 0, 0, -1, $last_error);

    $conn->send("$req$query");

    my $cursor = MongoDB::Async::Cursor->new(_ns => $info->{ns}, _client => $conn, _query => {});
    $cursor->_init;
    $cursor->_request_id($info->{'request_id'});

    $conn->recv($cursor);
    $cursor->started_iterating(1);
    $cursor->_started_iterating(1);

    my $ok = $cursor->next();

    # $ok->{ok} is 1 if err is set
    Carp::croak $ok->{err} if $ok->{err};
    # $ok->{ok} == 0 is still an error
    Carp::croak $ok->{errmsg} unless $ok->{ok};

    return $ok;
}


sub save {
    my ($self, $doc, $options) = @_;

    if (exists $doc->{"_id"}) {

        if (!$options || !ref $options eq 'HASH') {
            $options = {"upsert" => boolean::true};
        }
        else {
            $options->{'upsert'} = boolean::true;
        }

        return $self->update({"_id" => $doc->{"_id"}}, $doc, $options);
    }
    else {
        return $self->insert($doc, $options);
    }
}


sub count {
    my ($self, $query) = @_;

    my $obj;
    eval {
        $obj = $self->{_database}->run_command([
            count => $self->{name},
            query => ($query || {}),
        ]);
    };

    # if there was an error, check if it was the "ns missing" one that means the
    # collection hasn't been created or a real error.
    if ($@) {
        # if the request timed out, $obj might not be initialized
        if ($obj && $obj =~ m/^ns missing/) {
            return 0;
        }
        else {
            die $@;
        }
    }

    return $obj->{n};
}


sub validate {
    my ($self, $scan_data) = @_;
    $scan_data = 0 unless defined $scan_data;
    my $obj = $self->{_database}->run_command([ validate => $self->{name} ]);
}


sub drop_indexes {
    my ($self) = @_;
    return $self->drop_index('*');
}


sub drop_index {
    my ($self, $index_name) = @_;
	
	return $self->{_database}->run_command([
        deleteIndexes => $self->{name},
        index => $index_name,
    ]);
}


sub get_indexes {
    my ($self) = @_;
    return $self->{_database}->get_collection('system.indexes')->query({
        ns => $self->full_name,
    })->all;
}


sub drop {
    my ($self) = @_;
    $self->{_database}->run_command({ drop => $self->{name} });
    return;
}



__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

MongoDB::Async::Collection - A Mongo Collection

=head1 VERSION

version 0.702.3

=head1 SYNOPSIS

An instance of a MongoDB collection.

    # gets the foo collection
    my $collection = $db->foo;

Collection names can be chained together to access subcollections.  For
instance, the collection C<foo.bar> can be accessed with:

    my $collection = $db->foo->bar;

You can also access collections with the L<MongoDB::Async::Database/get_collection>
method.

=head1 NAME

MongoDB::Async::Collection - A Mongo collection

=head1 SEE ALSO

Core documentation on collections: L<http://dochub.mongodb.org/core/collections>.

=head1 ATTRIBUTES

=head2 name

The name of the collection.

=head2 full_name

The full_name of the collection, including the namespace of the database it's
in.

=head1 STATIC METHODS

=head2 to_index_string ($keys)

    $name = MongoDB::Async::Collection::to_index_string({age : 1});

Takes a L<Tie::IxHash>, hash reference, or array reference.  Converts it into
an index string.

=head1 METHODS

=head2 find($query)

    my $cursor = $collection->find({ i => { '$gt' => 42 } });

Executes the given C<$query> and returns a C<MongoDB::Async::Cursor> with the results.
C<$query> can be a hash reference, L<Tie::IxHash>, or array reference (with an
even number of elements).

The set of fields returned can be limited through the use of the
C<MongoDB::Async::Cursor::fields> method on the resulting L<MongoDB::Async::Cursor> object.
Other commonly used cursor methods are C<MongoDB::Async::Cursor::limit>,
C<MongoDB::Async::Cursor::skip>, and C<MongoDB::Async::Cursor::sort>.

See also core documentation on querying:
L<http://dochub.mongodb.org/core/find>.

=head2 query($query, $attrs?)

Identical to C<MongoDB::Async::Collection::find>, described above.

    my $cursor = $collection->query->limit(10)->skip(10);

    my $cursor = $collection->query({ location => "Vancouver" })->sort({ age => 1 });

Valid query attributes are:

=over 4

=item limit

Limit the number of results.

=item skip

Skip a number of results.

=item sort_by

Order results.

=back

=head2 find_one ($query, $fields?)

    my $object = $collection->find_one({ name => 'Resi' });
    my $object = $collection->find_one({ name => 'Resi' }, { name => 1, age => 1});

Executes the given C<$query> and returns the first object matching it.
C<$query> can be a hash reference, L<Tie::IxHash>, or array reference (with an
even number of elements).  If C<$fields> is specified, the resulting document
will only include the fields given (and the C<_id> field) which can cut down on
wire traffic.

=head2 insert ($object, $options?)

    my $id1 = $coll->insert({ name => 'mongo', type => 'database' });
    my $id2 = $coll->insert({ name => 'mongo', type => 'database' }, {safe => 1});

Inserts the given C<$object> into the database and returns it's id
value. C<$object> can be a hash reference, a reference to an array with an
even number of elements, or a L<Tie::IxHash>.  The id is the C<_id> value
specified in the data or a L<MongoDB::Async::OID>.

The optional C<$options> parameter can be used to specify if this is a safe
insert.  A safe insert will check with the database if the insert succeeded and
croak if it did not.  You can also check if the insert succeeded by doing an
unsafe insert, then calling L<MongoDB::Async::Database/"last_error($options?)">.

See also core documentation on insert: L<http://dochub.mongodb.org/core/insert>.

=head2 batch_insert (\@array, $options)

    my @ids = $collection->batch_insert([{name => "Joe"}, {name => "Fred"}, {name => "Sam"}]);

Inserts each of the documents in the array into the database and returns an
array of their _id fields.

The optional C<$options> parameter can be used to specify if this is a safe
insert.  A safe insert will check with the database if the insert succeeded and
croak if it did not. You can also check if the inserts succeeded by doing an
unsafe batch insert, then calling L<MongoDB::Async::Database/"last_error($options?)">.

=head2 update (\%criteria, \%object, \%options?)

    $collection->update({'x' => 3}, {'$inc' => {'count' => -1} }, {"upsert" => 1, "multiple" => 1});

Updates an existing C<$object> matching C<$criteria> in the database.

Returns 1 unless the C<safe> option is set. If C<safe> is set, this will return
a hash of information about the update, including number of documents updated
(C<n>).  If C<safe> is set and the update fails, C<update> will croak. You can
also check if the update succeeded by doing an unsafe update, then calling
L<MongoDB::Async::Database/"last_error($options?)">.

C<update> can take a hash reference of options.  The options currently supported
are:

=over

=item C<upsert>
If no object matching C<$criteria> is found, C<$object> will be inserted.

=item C<multiple>
All of the documents that match C<$criteria> will be updated, not just
the first document found. (Only available with database version 1.1.3 and
newer.)

=item C<safe>
If the update fails and safe is set, the update will croak.

=back

See also core documentation on update: L<http://dochub.mongodb.org/core/update>.

=head2 find_and_modify

    my $result = $collection->find_and_modify( { query => { ... }, update => { ... } } );

Perform an atomic update. C<find_and_modify> guarantees that nothing else will come along
and change the queried documents before the update is performed. 

Returns the old version of the document, unless C<new => 1> is specified. If no documents
match the query, it returns nothing.

=head2 aggregate

    my $result = $collection->aggregate( [ ... ] );

Run a query using the MongoDB 2.2+ aggregation framework. The argument is an array-ref of 
aggregation pipeline operators. Returns an array-ref containing the results of 
the query. See L<Aggregation|http://docs.mongodb.org/manual/aggregation/> in the MongoDB manual
for more information on how to construct aggregation queries.

=head2 rename ("newcollectionname")

    my $newcollection = $collection->rename("mynewcollection");

Renames the collection.  It expects that the new name is currently not in use.  

Returns the new collection.  If a collection already exists with that new collection name this will
die.

=head2 remove ($query?, $options?)

    $collection->remove({ answer => { '$ne' => 42 } });

Removes all objects matching the given C<$query> from the database. If no
parameters are given, removes all objects from the collection (but does not
delete indexes, as C<MongoDB::Async::Collection::drop> does).

Returns 1 unless the C<safe> option is set.  If C<safe> is set and the remove
succeeds, C<remove> will return a hash of information about the remove,
including how many documents were removed (C<n>).  If the remove fails and
C<safe> is set, C<remove> will croak.  You can also check if the remove
succeeded by doing an unsafe remove, then calling
L<MongoDB::Async::Database/"last_error($options?)">.

C<remove> can take a hash reference of options.  The options currently supported
are

=over

=item C<just_one>
Only one matching document to be removed.

=item C<safe>
If the update fails and safe is set, this function will croak.

=back

See also core documentation on remove: L<http://dochub.mongodb.org/core/remove>.

=head2 ensure_index ($keys, $options?)

    use boolean;
    $collection->ensure_index({"foo" => 1, "bar" => -1}, { unique => true });

Makes sure the given C<$keys> of this collection are indexed. C<$keys> can be an
array reference, hash reference, or C<Tie::IxHash>.  C<Tie::IxHash> is preferred
for multi-key indexes, so that the keys are in the correct order.  1 creates an
ascending index, -1 creates a descending index.

If the C<safe> option is not set, C<ensure_index> will not return anything
unless there is a socket error (in which case it will croak).  If the C<safe>
option is set and the index creation fails, it will also croak. You can also
check if the indexing succeeded by doing an unsafe index creation, then calling
L<MongoDB::Async::Database/"last_error($options?)">.

See the L<MongoDB::Async::Indexing> pod for more information on indexing.

=head2 save($doc, $options)

    $collection->save({"author" => "joe"});
    my $post = $collection->find_one;

    $post->{author} = {"name" => "joe", "id" => 123, "phone" => "555-5555"};

    $collection->save($post);

Inserts a document into the database if it does not have an _id field, upserts
it if it does have an _id field.

=over

=item C<safe => boolean>

If the save fails and safe is set, this function will croak.

=back

The return types for this function are a bit of a mess, as it will return the
_id if a new document was inserted, 1 if an upsert occurred, and croak if the
safe option was set and an error occurred.  You can also check if the save
succeeded by doing an unsafe save, then calling
L<MongoDB::Async::Database/"last_error($options?)">.

=head2 count($query?)

    my $n_objects = $collection->count({ name => 'Bob' });

Counts the number of objects in this collection that match the given C<$query>.
If no query is given, the total number of objects in the collection is returned.

=head2 validate

    $collection->validate;

Asks the server to validate this collection.
Returns a hash of the form:

    {
        'ok' => '1',
        'ns' => 'foo.bar',
        'result' => info
    }

where C<info> is a string of information
about the collection.

=head2 drop_indexes

    $collection->drop_indexes;

Removes all indexes from this collection.

=head2 drop_index ($index_name)

    $collection->drop_index('foo_1');

Removes an index called C<$index_name> from this collection.
Use C<MongoDB::Async::Collection::get_indexes> to find the index name.

=head2 get_indexes

    my @indexes = $collection->get_indexes;

Returns a list of all indexes of this collection.
Each index contains C<ns>, C<name>, and C<key>
fields of the form:

    {
        'ns' => 'db_name.collection_name',
        'name' => 'index_name',
        'key' => {
            'key1' => dir1,
            'key2' => dir2,
            ...
            'keyN' => dirN
        }
    }

where C<dirX> is 1 or -1, depending on if the
index is ascending or descending on that key.

=head2 drop

    $collection->drop;

Deletes a collection as well as all of its indexes.

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
