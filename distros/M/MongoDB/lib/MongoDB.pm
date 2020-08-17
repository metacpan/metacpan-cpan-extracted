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

use 5.010001;
use strict;
use warnings;

package MongoDB;
# ABSTRACT: Official MongoDB Driver for Perl (EOL)

use version;
our $VERSION = 'v2.2.2';

# regexp_pattern was unavailable before 5.10, had to be exported to load the
# function implementation on 5.10, and was automatically available in 5.10.1
use if ($] eq '5.010000'), 're', 'regexp_pattern';

use Carp ();
use MongoDB::MongoClient;
use MongoDB::Database;
use MongoDB::Collection;
use MongoDB::BulkWrite;
use MongoDB::_Link;
use MongoDB::_Protocol;
use BSON::Types;

# regexp_pattern was unavailable before 5.10, had to be exported to load the
# function implementation on 5.10, and was automatically available in 5.10.1
if ( $] eq '5.010' ) {
    require re;
    re->import('regexp_pattern');
}

#pod =method connect
#pod
#pod     $client = MongoDB->connect(); # localhost, port 27107
#pod     $client = MongoDB->connect($host_uri);
#pod     $client = MongoDB->connect($host_uri, $options);
#pod
#pod This function returns a L<MongoDB::MongoClient> object.  The first parameter is
#pod used as the C<host> argument and must be a host name or L<connection string
#pod URI|MongoDB::MongoClient/CONNECTION STRING URI>.  The second argument is
#pod optional.  If provided, it must be a hash reference of constructor arguments
#pod for L<MongoDB::MongoClient::new|MongoDB::MongoClient/ATTRIBUTES>.
#pod
#pod If an error occurs, a L<MongoDB::Error> object will be thrown.
#pod
#pod B<NOTE>: To connect to a replica set, a replica set name must be provided.
#pod For example, if the set name is C<"setA">:
#pod
#pod     $client = MongoDB->connect("mongodb://example.com/?replicaSet=setA");
#pod
#pod =cut

sub connect {
    my ($class, $host, $options) = @_;
    $host ||= "mongodb://localhost";
    $options ||= {};
    $options->{host} = $host;
    return MongoDB::MongoClient->new( $options );
}

1;

=pod

=encoding UTF-8

=head1 NAME

MongoDB - Official MongoDB Driver for Perl (EOL)

=head1 VERSION

version v2.2.2

=head1 END OF LIFE NOTICE

Version v2.2.0 was the final feature release of the MongoDB Perl driver and
version v2.2.2 is the final patch release.

B<As of August 13, 2020, the MongoDB Perl driver and related libraries have
reached end of life and are no longer supported by MongoDB.> See the
L<August 2019 deprecation
notice|https://www.mongodb.com/blog/post/the-mongodb-perl-driver-is-being-deprecated>
for rationale.

If members of the community wish to continue development, they are welcome
to fork the code under the terms of the Apache 2 license and release it
under a new namespace.  Specifications and test files for MongoDB drivers
and libraries are published in an open repository:
L<mongodb/specifications|https://github.com/mongodb/specifications/tree/master/source>.

=head1 SYNOPSIS

    use MongoDB;

    my $client     = MongoDB->connect('mongodb://localhost');
    my $collection = $client->ns('foo.bar'); # database foo, collection bar
    my $result     = $collection->insert_one({ some => 'data' });
    my $data       = $collection->find_one({ _id => $result->inserted_id });

=head1 DESCRIPTION

This is the official Perl driver for L<MongoDB|http://www.mongodb.com>.
MongoDB is an open-source document database that provides high performance,
high availability, and easy scalability.

A MongoDB server (or multi-server deployment) hosts a number of databases. A
database holds a set of collections. A collection holds a set of documents. A
document is a set of key-value pairs. Documents have dynamic schema. Using dynamic
schema means that documents in the same collection do not need to have the same
set of fields or structure, and common fields in a collection's documents may
hold different types of data.

Here are some resources for learning more about MongoDB:

=over 4

=item *

L<MongoDB Manual|http://docs.mongodb.org/manual/contents/>

=item *

L<MongoDB CRUD Introduction|http://docs.mongodb.org/manual/core/crud-introduction/>

=item *

L<MongoDB Data Modeling Introductions|http://docs.mongodb.org/manual/core/data-modeling-introduction/>

=back

To get started with the Perl driver, see these pages:

=over 4

=item *

L<MongoDB Perl Driver Tutorial|MongoDB::Tutorial>

=item *

L<MongoDB Perl Driver Examples|MongoDB::Examples>

=back

Extensive documentation and support resources are available via the
L<MongoDB community website|http://www.mongodb.org/>.

=head1 USAGE

The MongoDB driver is organized into a set of classes representing
different levels of abstraction and functionality.

As a user, you first create and configure a L<MongoDB::MongoClient> object
to connect to a MongoDB deployment.  From that client object, you can get a
L<MongoDB::Database> object for interacting with a specific database.

From a database object, you can get a L<MongoDB::Collection> object for
CRUD operations on that specific collection, or a L<MongoDB::GridFSBucket>
object for working with an abstract file system hosted on the database.
Each of those classes may return other objects for specific features or
functions.

See the documentation of those classes for more details or the
L<MongoDB Perl Driver Tutorial|MongoDB::Tutorial> for an example.

L<MongoDB::ClientSession> objects are generated from a
L<MongoDB::MongoClient> and allow for advanced consistency options, like
causal-consistency and transactions.

=head2 Error handling

Unless otherwise documented, errors result in fatal exceptions.  See
L<MongoDB::Error> for a list of exception classes and error code
constants.

=head1 METHODS

=head2 connect

    $client = MongoDB->connect(); # localhost, port 27107
    $client = MongoDB->connect($host_uri);
    $client = MongoDB->connect($host_uri, $options);

This function returns a L<MongoDB::MongoClient> object.  The first parameter is
used as the C<host> argument and must be a host name or L<connection string
URI|MongoDB::MongoClient/CONNECTION STRING URI>.  The second argument is
optional.  If provided, it must be a hash reference of constructor arguments
for L<MongoDB::MongoClient::new|MongoDB::MongoClient/ATTRIBUTES>.

If an error occurs, a L<MongoDB::Error> object will be thrown.

B<NOTE>: To connect to a replica set, a replica set name must be provided.
For example, if the set name is C<"setA">:

    $client = MongoDB->connect("mongodb://example.com/?replicaSet=setA");

=begin Pod::Coverage




=end Pod::Coverage

=head1 SUPPORTED MONGODB VERSIONS

The driver has been tested against MongoDB versions 2.6 through 4.2.  All
features of these versions are supported, except for field-level
encryption.  The driver may work with future versions of MongoDB, but will
not include support for new MongoDB features and should be B<thoroughly
tested> within applications before deployment.

=head1 SEMANTIC VERSIONING SCHEME

Starting with MongoDB C<v1.0.0>, the driver reverts to the more familiar
three-part version-tuple numbering scheme used by both Perl and MongoDB:
C<vX.Y.Z>

=over 4

=item *

C<X> will be incremented for incompatible API changes.

=item *

Even-value increments of C<Y> indicate stable releases with new functionality.  C<Z> will be incremented for bug fixes.

=item *

Odd-value increments of C<Y> indicate unstable ("development") releases that should not be used in production.  C<Z> increments have no semantic meaning; they indicate only successive development releases.

=back

See the Changes file included with releases for an indication of the nature of
changes involved.

=head1 ENVIRONMENT VARIABLES

If the C<PERL_MONGO_WITH_ASSERTS> environment variable is true before the
MongoDB module is loaded, then its various classes will be generated with
internal type assertions enabled.  This has a severe performance cost and
is not recommended for production use.  It may be useful in diagnosing
bugs.

If the C<PERL_MONGO_NO_DEP_WARNINGS> environment variable is true, then
deprecated methods will not issue warnings when used.  (Normally, a
deprecation warning is issued once per call-site for deprecated methods.)

=head1 THREADS

Per L<threads> documentation, use of Perl threads is discouraged by the
maintainers of Perl and the MongoDB Perl driver does not test or provide support
for use with threads.

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

=head1 CONTRIBUTORS

=for stopwords Andrew Page Andrey Khozov Ashley Willis Ask Bjørn Hansen Bernard Gorman Brendan W. McAdams Brian Moss Casey Rojas Christian Sturm Walde Colin Cyr Danny Raetzsch David Morrison Nadle Steinbrunner Storch diegok D. Ilmari Mannsåker Eric Daniels Finn Kempers (Shadowcat Systems Ltd) Gerard Goossen Glenn Fowler Graham Barr Hao Wu Harish Upadhyayula Jason Carey Toffaletti Johann Rolschewski John A. Kunze Joseph Harnish Josh Matthews Joshua Juran J. Stewart Kamil Slowikowski Ken Williams Matthew Shopsin Matt S Trout Michael Langner Rotmanov Mike Dirolf Mohammad Anwar Nickola Trupcheff Nigel Gregoire Niko Tyni Nuno Carvalho Orlando Vazquez Othello Maurer Pan Fan Pavel Denisov Rahul Dhodapkar Robert Sedlacek Robin Lee Roman Yerin Ronald J Kimball Ryan Chipman Slaven Rezic Stephen Oberholtzer Steve Sanbeg Stuart Watt Thomas Bloor Tobias Leich Uwe Voelker Wallace Reis Wan Bachtiar Whitney Jackson Xavier Guimard Xtreak Zhihong Zhang

=over 4

=item *

Andrew Page <andrew@infosiftr.com>

=item *

Andrey Khozov <avkhozov@gmail.com>

=item *

Ashley Willis <ashleyw@cpan.org>

=item *

Ask Bjørn Hansen <ask@develooper.com>

=item *

Bernard Gorman <bernard.gorman@mongodb.com>

=item *

Brendan W. McAdams <brendan@mongodb.com>

=item *

Brian Moss <kallimachos@gmail.com>

=item *

Casey Rojas <casey.j.rojas@gmail.com>

=item *

Christian Hansen <chansen@cpan.org>

=item *

Christian Sturm <kind@gmx.at>

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

Colin Cyr <ccyr@sailingyyc.com>

=item *

Danny Raetzsch <danny@paperskymedia.com>

=item *

David Morrison <dmorrison@venda.com>

=item *

David Nadle <david@nadle.com>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

David Storch <david.storch@mongodb.com>

=item *

diegok <diego@freekeylabs.com>

=item *

D. Ilmari Mannsåker <ilmari.mannsaker@net-a-porter.com>

=item *

Eric Daniels <eric.daniels@mongodb.com>

=item *

Finn Kempers (Shadowcat Systems Ltd) <toyou1995@gmail.com>

=item *

Gerard Goossen <gerard@ggoossen.net>

=item *

Glenn Fowler <cebjyre@cpan.org>

=item *

Graham Barr <gbarr@pobox.com>

=item *

Hao Wu <echowuhao@gmail.com>

=item *

Harish Upadhyayula <hupadhyayula@dealersocket.com>

=item *

Jason Carey <jason.carey@mongodb.com>

=item *

Jason Toffaletti <jason@topsy.com>

=item *

Johann Rolschewski <rolschewski@gmail.com>

=item *

John A. Kunze <jak@ucop.edu>

=item *

Joseph Harnish <bigjoe1008@gmail.com>

=item *

Josh Matthews <joshua.matthews@mongodb.com>

=item *

Joshua Juran <jjuran@metamage.com>

=item *

J. Stewart <jstewart@langley.theshire>

=item *

Kamil Slowikowski <kslowikowski@gmail.com>

=item *

Ken Williams <kwilliams@cpan.org>

=item *

Matthew Shopsin <matt.shopsin@mongodb.com>

=item *

Matt S Trout <mst@shadowcat.co.uk>

=item *

Michael Langner <langner@fch.de>

=item *

Michael Rotmanov <rotmanov@sipgate.de>

=item *

Mike Dirolf <mike@mongodb.com>

=item *

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=item *

Nickola Trupcheff <n.trupcheff@gmail.com>

=item *

Nigel Gregoire <nigelg@airg.com>

=item *

Niko Tyni <ntyni@debian.org>

=item *

Nuno Carvalho <mestre.smash@gmail.com>

=item *

Orlando Vazquez <ovazquez@gmail.com>

=item *

Othello Maurer <omaurer@venda.com>

=item *

Pan Fan <nightsailer@gmail.com>

=item *

Pavel Denisov <pavel.a.denisov@gmail.com>

=item *

Rahul Dhodapkar <rahul@mongodb.com>

=item *

Robert Sedlacek (Shadowcat Systems Ltd) <phaylon@cpan.org>

=item *

Robin Lee <cheeselee@fedoraproject.org>

=item *

Roman Yerin <kid@cpan.org>

=item *

Ronald J Kimball <rkimball@pangeamedia.com>

=item *

Ryan Chipman <ryan@ryanchipman.com>

=item *

Slaven Rezic <slaven.rezic@idealo.de>

=item *

Slaven Rezic <srezic@cpan.org>

=item *

Stephen Oberholtzer <stevie@qrpff.net>

=item *

Steve Sanbeg <stevesanbeg@buzzfeed.com>

=item *

Stuart Watt <stuart@morungos.com>

=item *

Thomas Bloor (Shadowcat Systems Ltd) <tbsliver@cpan.org>

=item *

Tobias Leich <email@froggs.de>

=item *

Uwe Voelker <uwe.voelker@xing.com>

=item *

Wallace Reis <wallace@reis.me>

=item *

Wan Bachtiar <sindbach@gmail.com>

=item *

Whitney Jackson <whjackson@gmail.com>

=item *

Xavier Guimard <x.guimard@free.fr>

=item *

Xtreak <tirkarthi@users.noreply.github.com>

=item *

Zhihong Zhang <zzh_621@yahoo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: set ts=4 sts=4 sw=4 et tw=75:
