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

use v5.10.0;
use strict;
use warnings;

package MongoDB::Async;
{
  $MongoDB::Async::VERSION = '0.702.3';
}
# ABSTRACT: A Mongo Driver for Perl

use XSLoader;
use MongoDB::Async::Connection;
use MongoDB::Async::MongoClient;
use MongoDB::Async::Database;
use MongoDB::Async::Collection;

use MongoDB::Async::DBRef;
# use MongoDB::Async::OID;

use EV;
use Coro;
use Coro::EV;


XSLoader::load(__PACKAGE__, $MongoDB::Async::VERSION, int rand(2 ** 24));

1;

__END__

=pod

=head1 NAME

MongoDB::Async - Asynchronous Mongo Driver for Perl

=head1 ABOUT ASYNC DRIVER

Changes relative to L<MongoDB>:

L<MongoDB::Async::Pool> - pool of persistent connects

Added ->data method to L<MongoDB::Async::Cursor>. Same as ->all, but returns array ref. 

dt_type now $MongoDB::Async::BSON::dt_type global variable, not connection object property 

inflate_dbrefs now $MongoDB::Async::Cursor::inflate_dbrefs global variable


This module is 20-100% (in single-(coro)threaded test , mulithreaded will be even faster) faster than original L<MongoDB>. See benchmark L<http://pastebin.com/vFWENzW7> or run benchmark_compare.pl from archive. It might be 1-5% slower than original on many small queries because of overhead to start and get io callback, but usually it faster because of deserealization/cursor optimizations. 

This driver NOT ithreads safe

SASL and SSL unsupported (ssl may work in blocking mode, not tested it). 

PLEASE DON'T USE documentation of this module and refere to doc of original MongoDB module with corresponding version. Because I'm porting here only features and too lazy to copy-paste docs.

Don't work with this module inside Coro::unblock_sub, it leaks memory. Use separate coro thread to work with database, and if you need callback interface you need to write it yourself.

Please report bugs/suggestions to I<nyaknyan@gmail.com> or cpan's RT.


TODO:

Make async connection - currently it may block for some time while trying to connect to node which is down.

Implement SSL support using normal SSL module object. 

May (or may not, not tested it) segfault if intesively trying reconnect to servers under heavy load. Fix it.

Minimize Moose usage, because perl isn't C++ or Java and all this getter/setter shit if just slow. 

=head1 VERSION

version 0.702.3

=head1 SYNOPSIS

    use MongoDB::Async;

    my $client     = MongoDB::Async::MongoClient->new(host => 'localhost', port => 27017);
    my $database   = $client->get_database( 'foo' );
    my $collection = $database->get_collection( 'bar' );
    my $id         = $collection->insert({ some => 'data' });
    my $data       = $collection->find_one({ _id => $id });

=head1 DESCRIPTION

MongoDB is a database access module.

MongoDB (the database) store all strings as UTF-8.  Non-UTF-8 strings will be
forcibly converted to UTF-8.  To convert something from another encoding to
UTF-8, you can use L<Encode>:

    use Encode;

    my $name = decode('cp932', "\x90\xbc\x96\xec\x81\x40\x91\xbe\x98\x59");
    my $id = $coll->insert( { name => $name, } );

    my $object = $coll->find_one( { name => $name } );

Thanks to taronishino for this example.

=head2 Notation and Conventions

The following conventions are used in this document:

    $client Database client object
    $db     Database
    $coll   Collection
    undef   C<null> values are represented by undefined values in Perl
    \@arr   Reference to an array passed to methods
    \%attr  Reference to a hash of attribute values passed to methods

Note that Perl will automatically close and clean up database connections if
all references to them are deleted.

=head2 Outline Usage

To use MongoDB, first you need to load the MongoDB module:

    use strict;
    use warnings;
    use MongoDB::Async;

Then you need to connect to a MongoDB database server.  By default, MongoDB listens
for connections on port 27017.  Unless otherwise noted, this documentation
assumes you are running MongoDB locally on the default port.

MongoDB can be started in I<authentication mode>, which requires clients to log in
before manipulating data.  By default, MongoDB does not start in this mode, so no
username or password is required to make a fully functional connection.  If you
would like to learn more about authentication, see the C<authenticate> method.

To connect to the database, create a new MongoClient object:

    my $client = MongoDB::Async::MongoClient->new("host" => "localhost:27017");

As this is the default, we can use the equivalent shorthand:

    my $client = MongoDB::Async::MongoClient->new;

Connecting is relatively expensive, so try not to open superfluous connections.

There is no way to explicitly disconnect from the database.  However, the
connection will automatically be closed and cleaned up when no references to
the C<MongoDB::Async::MongoClient> object exist, which occurs when C<$client> goes out of
scope (or earlier if you undefine it with C<undef>).

=head2 INTERNALS

=head3 Class Hierarchy

The classes are arranged in a hierarchy: you cannot create a
L<MongoDB::Async::Collection> instance before you create L<MongoDB::Async::Database> instance,
for example.  The full hierarchy is:

    MongoDB::Async::MongoClient -> MongoDB::Async::Database -> MongoDB::Async::Collection

This is because L<MongoDB::Async::Database> has a field that is a
L<MongoDB::Async::MongoClient> and L<MongoDB::Async::Collection> has a L<MongoDB::Async::Database>
field.

When you call a L<MongoDB::Async::Collection> function, it "trickles up" the chain of
classes.  For example, say we're inserting C<$doc> into the collection C<bar> in
the database C<foo>.  The calls made look like:

=over

=item C<< $collection->insert($doc) >>

Calls L<MongoDB::Async::Database>'s implementation of C<insert>, passing along the
collection name ("foo").

=item C<< $db->insert($name, $doc) >>

Calls L<MongoDB::Async::MongoClient>'s implementation of C<insert>, passing along the
fully qualified namespace ("foo.bar").

=item C<< $client->insert($ns, $doc) >>

L<MongoDB::Async::MongoClient> does the actual work and sends a message to the database.

=back

=head1 INTRO TO MONGODB

This is the Perl driver for MongoDB, a document-oriented database.  This section
introduces some of the basic concepts of MongoDB.  There's also a L<MongoDB::Async::Tutorial/"Tutorial">
POD that introduces using the driver.  For more documentation on MongoDB in
general, check out L<http://www.mongodb.org>.

=head1 GETTING HELP

If you have any questions, comments, or complaints, you can get through to the
developers most dependably via the MongoDB user list:
I<mongodb-user@googlegroups.com>.  You might be able to get someone quicker
through the MongoDB IRC channel, I<irc.freenode.net#mongodb>.

=head1 FUNCTIONS

These functions should generally not be used.  They are very low level and have
nice wrappers in L<MongoDB::Async::Collection>.

=head2 write_insert($ns, \@objs)

    my ($insert, $ids) = MongoDB::Async::write_insert("foo.bar", [{foo => 1}, {bar => -1}, {baz => 1}]);

Creates an insert string to be used by C<MongoDB::Async::MongoClient::send>.  The second
argument is an array of hashes to insert.  To imitate the behavior of
C<MongoDB::Async::Collection::insert>, pass a single hash, for example:

    my ($insert, $ids) = MongoDB::Async::write_insert("foo.bar", [{foo => 1}]);

Passing multiple hashes imitates the behavior of
C<MongoDB::Async::Collection::batch_insert>.

This function returns the string and an array of the the _id fields that the
inserted hashes will contain.

=head2 write_query($ns, $flags, $skip, $limit, $query, $fields?)

    my ($query, $info) = MongoDB::Async::write_query('foo.$cmd', 0, 0, -1, {getlasterror => 1});

Creates a database query to be used by C<MongoDB::Async::MongoClient::send>.  C<$flags>
are query flags to use (see C<MongoDB::Async::Cursor::Flags> for possible values).
C<$skip> is the number of results to skip, C<$limit> is the number of results to
return, C<$query> is the query hash, and C<$fields> is the optional fields to
return.

This returns the query string and a hash of information about the query that is
used by C<MongoDB::Async::MongoClient::recv> to get the database response to the query.

=head2 write_update($ns, $criteria, $obj, $flags)

    my ($update) = MongoDB::Async::write_update("foo.bar", {age => {'$lt' => 20}}, {'$set' => {young => true}}, 0);

Creates an update that can be used with C<MongoDB::Async::MongoClient::send>.  C<$flags>
can be 1 for upsert and/or 2 for updating multiple documents.

=head2 write_remove($ns, $criteria, $flags)

    my ($remove) = MongoDB::Async::write_remove("foo.bar", {name => "joe"}, 0);

Creates a remove that can be used with C<MongoDB::Async::MongoClient::send>.  C<$flags>
can be 1 for removing just one matching document.

=head2 read_documents($buffer)

  my @documents = MongoDB::Async::read_documents($buffer);

Decodes BSON documents from the given buffer.

=head1 SEE ALSO

MongoDB main website L<http://www.mongodb.org/>

Core documentation L<http://www.mongodb.org/display/DOCS/Manual>

L<MongoDB::Async::Tutorial>, L<MongoDB::Async::Examples>

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
