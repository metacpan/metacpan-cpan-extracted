# $Id: Tutorial.pm,v 1.20 2005-04-22 12:19:17 mike Exp $

package Net::Z3950::DBIServer::Tutorial;
use strict;


=head1 NAME

Net::Z3950::DBIServer::Tutorial - The zSQLgate Tutorial


=head1 SYNOPSIS

server$ B<mysql>

 mysql> create database books;
 mysql> use books;
 mysql> GRANT ALL PRIVILEGES ON books.* TO ""@"localhost";
 mysql> CREATE TABLE author(id INT, name TEXT);
 mysql> INSERT INTO author(id, name) VALUES('1','Douglas Adams');
 mysql> INSERT INTO author(id, name) VALUES('2','Stephen Notley');
 mysql> INSERT INTO author(id, name) VALUES('3','Dave Barry');

server$ B<cat trivial.nzd>

 datasource = "DBI:mysql:dbname=books"
 database "artists" {
     table = "author"
     search attrset bib1 {
         access 12 = "id"
         access 1 = "name"
     }
     data format xml {
         record = "author"
         field "authorId" = "id"
         field "authorName" = "name"
     }
 }

server$ B<zSQLgate trivial.nzd @:3950>

 13:04:54-12/04 [server] Adding dynamic Z3950 listener on tcp:@:9999
 13:04:54-12/04 [server] Starting server zSQLgate pid=28488
 13:04:57-12/04 zSQLgate(1) [session] Starting session from tcp:127.0.0.1 (pid=28490)
 ...

client$ B<yaz-client @:3950>

 Z> base artists
 Z> find @attr 1=12 @attr 2=1 3
 Number of hits: 2
 Z> format xml
 Z> show 1+2
 <author>
  <authorId>1</authorId>
  <authorName>Douglas Adams</authorName>
 </author>
 <author>
  <authorId>2</authorId>
  <authorName>Stephen Notley</authorName>
 </author>


=head1 DESCRIPTION

This document is a tutorial for C<zSQLgate>, the Z39.50 server for
relational databases.

If you don't know what C<zSQLgate> is, then you should start by
reading
L<Net::Z3950::DBIServer::Intro>
(the introduction to C<zSQLgate>) and
L<Net::Z3950::DBIServer::LICENCE>,
(the licence under which it is available).

This tutorial informally walks through the main features of
C<zSQLgate>, and for many people will be the only part of the
C<zSQLgate> documentation that they ever read.  That's fine - much of
what you need to know will be here.  But please be aware that some of
the more esoteric features will not be discussed here: if you don't
find what you want, you may need to dig into two more rigorous
documents that are supplied with this tutorial:

=over 4

=item *

L<Net::Z3950::DBIServer::Run>
describes the command-line options available to tailor the behaviour
of C<zSQLgate> at run-time.

Z<>

=item *

L<Net::Z3950::DBIServer::Spec>
describes the C<zSQLgate> configuration file format in more detail
than this document, explaining the precise meaning of its various
directives.

Z<>

=back

In general, those two documents describe the sorts of things you can
say to C<zSQLgate> and what they mean - but this one explains why you
might want to say those things.  The reference documents are there to
answer I<what> questions; this tutorial aims to tell you I<how>.


=head1 A WALK THROUGH THE SYNOPSIS

The synopsis shows the process of
creating a database, a C<zSQLgate> configuration file for that
database, how to start a Z39.50 server for it, and a session with a
Z39.50 client accessing it.

Let's look at the four sections separately.  They will introduce us to
pretty much all of the main C<zSQLgate> features: everything else is
just refinement of these core facilities.

=head2 Database Creation

server$ B<mysql>

 mysql> create database books;
 mysql> use books;
 mysql> GRANT ALL PRIVILEGES ON books.* TO ""@"localhost";
 mysql> CREATE TABLE author(id INT, name TEXT);
 mysql> INSERT INTO author(id, name) VALUES('1','Douglas Adams');
 mysql> INSERT INTO author(id, name) VALUES('2','Stephen Notley');
 mysql> INSERT INTO author(id, name) VALUES('3','Dave Barry');

Here, we are creating a relational database.  This is the one part
of the whole process that C<zSQLgate> can't really help you with,
because the details of how you create and populate a database are very
much down to the specific RDBMS that you happen to be using.  The
commands above create a tiny but self-contained database called
C<books> in the MySQL RDBMS: the actual SQL commands to do
this will be very similar in most or all relational databases, but the
front-end program will be different.

How do you choose which RDBMS to use?  Well, for most projects, this
will be a non-issue: if you're be putting a C<zSQLgate> front-end on an
existing database, that choice will already have been made for you.
(You also won't need to worry about building and populating the database!)

If you don't already have a database, and you're building one from
scratch, then one good choice is PostgreSQL, which is included in
recent Red Hat Linux distributions, along with support for using it in
PHP3, Perl, Java (via JDBC), C (via native or ODBC interfaces), Perl,
Python and Tcl.  If you're not using Red Hat, you can get it from
http://www.postgresql.org/ - but there are plenty of other good RDBMSs
around, and I'm not really in a position to recommend one above
another.

Anyway.  You need to get a database from somewhere if you're going to
build a Z39.50 interface to it.

=head2 zSQLgate Configuration

server$ B<cat trivial.nzd>

 datasource = "DBI:mysql:dbname=books"
 database "artists" {
     table = "author"
     search attrset bib1 {
         access 12 = "id"
         access 1 = "name"
     }
     data format xml {
         record = "author"
         field "authorId" = "id"
         field "authorName" = "name"
     }
 }

90% of the work of setting up a C<zSQLgate> server is writing the
configuration file.  Its job is to describe the relational database
that is to be made available, couching its tables in terms of Z39.50
databases, and to express how the columns in those tables are mapped
to access points (for searching) and data elements (for retrieval).

What we have here is just about the simplest possible complete
C<zSQLgate> configuration file.  Apart from specifying the datasource
(roughly, the relational database), it provides mapping details for a
single Z39.50 database (that is, in relational terms, a single table), to
be known as C<artists> in the Z39.50 world.  The details for that
database consist of a statement of the name of the table that is to
provide its records (C<author>), plus sections about how that database
is to be searched, and how its data is to be formatted.

The search specification says that Z39.50 searching is done using the BIB-1
attribute set, and that two access-points are
recognised: searches against access point 12 (``Local number'' in the
BIB-1 attribute set) are mapped into C<SELECT> statements on the C<id>
column, and those against access point 1 (``Personal name'') to the
C<name> column.

The data specification says that C<zSQLgate> is to support record
retrieval using the XML format, building records wrapped in an
<C<artist>>...<C</artist>> pair, and that each record should contain
the contents of the C<id> and C<name> columns, wrapped in
<C<artistId>>...<C</artistId>> and C<<artistName>>...C<</artistName>>
tag-pairs respectively.

See?  It's easy!

Yes, it's possible to say much, much more in a configuration file; but
you can start by writing a simple one, and add in the
more sophisticated stuff as you need it, rather than needing to learn
everything in one go.

=head2 Running the zSQLgate server

server$ B<zSQLgate trivial.nzd @:3950>

 13:04:54-12/04 [server] Adding dynamic Z3950 listener on tcp:@:9999
 13:04:54-12/04 [server] Starting server zSQLgate pid=28488
 13:04:57-12/04 zSQLgate(1) [session] Starting session from tcp:127.0.0.1 (pid=28490)
 ...

Once you've got your configuration file written, it's time to start
the server.  Generally, you'll need to give it two arguments: the name
of the configuration file you want to use, and the ``listener
address'' which specifies which port to receive incoming connections
on.  Generally, this should be C<@:>I<number>, where I<number> is
the IP port number.  This is conventionally 210 for Z39.50 servers,
but you'll need to pick a number above 1024 if your server is not
running as root, as the lower-number ports are considered to be
``privileged''.

If there's something wrong with your configuration file, the server
will refuse to start up, giving a hopefully useful message to help you
track down what you've done wrong.  If all is well, it will go into a
loop waiting for connections, C<fork()>ing for each incoming client
and serving its requests in a subprocess.  Unless you've turned
logging off, you'll see startup messages similar to those above.

=head2 Connecting to the zSQLgate server

client$ B<yaz-client @:3950>

 Z> base artists
 Z> find @attr 1=12 @attr 2=1 3
 Number of hits: 2
 Z> format xml
 Z> show 1+2
 <author>
  <authorId>1</authorId>
  <authorName>Douglas Adams</authorName>
 </author>
 <author>
  <authorId>2</authorId>
  <authorName>Stephen Notley</authorName>
 </author>

Once your C<zSQLgate> server is up, you'll want to connect a Z39.50
client to it to check that it's doing what you intended.  You can use
whatever client you're used to - that's the point of an interoperable
standard like Z39.50.

In this example, I'm using the simple command-line client provided by
with the YAZ toolkit, because it's the one client you're guaranteed to
have.  (You wouldn't have been able to build C<zSQLgate> and the
libraries it depends on without YAZ.)  Start the client with a
single command-line argument which specifies what host and port to connect to.
(The hostname C<@> is shorthand for the same host the client's running on.)

Once the client is connected, you can do what you like.  In the short
session above, we've set the name of the database we want to use to
C<artists> (which is the Z39.50 database name that we specified in the
C<zSQLgate> configuration file), then fired off a search in the rather
opaque but general Prefix Query Format.  The search C<@attr 1=12
@attr 2=1 3> says to search for the term C<3> with two attributes
attached: the first, C<1=12>, means to use access point 12 (which we
defined to mean a C<SELECT> condition on the C<id> column); and the second,
C<2=1> is a relation attribute, meaning to search for values less than
the specified one.  Inside C<zSQLgate>, this search is translated into

 SELECT * FROM author WHERE id < 3

Finally, having received a response to our search (which found two
records, presumably with C<id>s 1 and 2), we set the desired retrieval
format to XML, and fetch the records, which are rendered to the
screen.  (The YAZ client includes more protocol information than this
in its output, but the substance of it is the two tiny XML records
listed above.)

=head2 Conclusion

An ounce of example is worth a ton of explanation, isn't it?


=head1 BUILDING ON THE FIRST EXAMPLE

=head2 Comments

The C<zSQLgate> configuration file can contain comments, which are
introduced by a hash character (C<#>), and run to the end of the line.
They are ignored.  Comments are the only part of the configuration
file syntax that treats lines specially: otherwise the syntax is
totally free-form.

For example, we could begin our configuration file like this:

 # books.nzd - a sample configuration file for Net::Z39.50::DBIServer
 # $Id: Tutorial.pm,v 1.20 2005-04-22 12:19:17 mike Exp $
 #
 # See Net::Z3950::DBIServer::Spec for a formal description of this
 # file's format, if you need it.  But it's actually pretty obvious.

(The Id line allows a version-control system such as CVS to insert
information into the file, such as the date and time it was last
checked in.)

Comments need not start at the beginning of a line: for example, we
might want to add a note that the datasource is MySQL-specific, and
perhaps to add the equivalent line for PostgreSQL, commented out:

 datasource = "DBI:mysql:dbname=books"           # If using MySQL
 #datasource = "DBI:Pg:dbname=books"             # If using PostgreSQL

Similarly, we might annotate the access-point lines with comments
indicating the interpretation of the BIB-1 access points, since they
are specified as rather opaque numbers:

 access 12 = "id"                       # local number
 access 1 = "name"                      # author

=head2 Authentication

If the relational database requires a username and password, these can
be specified at the top level:

 username = "simon"                             # If needed
 password = "pieman"                            # If needed

=head2 Multiple Databases

A Z39.50 database corresponds roughly to a single table from a
relational database.  Within a relational database, a single
C<zSQLgate> process can serve data from multiple tables, representing
multiple Z39.50 databases.  So let's add another table to the
database, and add some records:

 mysql> CREATE TABLE book(id INT, author_id INT, name TEXT,
        year INT, notes TEXT, fulltext index (name));
 mysql> INSERT INTO book(id,author_id,name,year)
        VALUES('1','1','The Hitch Hiker''s Guide to the Galaxy','1979');        [etc.]

Now we can add a new C<database> section to the C<zSQLgate>
configuration, indicating how to search in, and retrieve from, the new
table:

 database "works" {
     table = "book"
     search {
         attrset bib1 {
             access 12 = "id"                    # local number
             access 4 = "name"                   # title
             access 30 = "year"                  # year
         }
     }
     data format xml {
         record = "book"
         field "bookId" = "id"
         field "authorId" = "author_id"
         field "authorName" = "author.name"
         field "bookName" = "name"
         field "bookYear" = "year"
         field "bookNotes" = "?notes"
     }
 }

This works exactly the same way as the similar section for the
"artists" database: Z39.50 searches against the BIB-1 access-points 12
(local number), 4 (title) and 30 (year) are implemented using the
C<id>, C<name> and C<year> columns respectively.  XML records are
returned as a C<<book>> element containing C<<bookId>> derived from
the C<id> column, etc.

=head2 Searching in Multiple Columns

The specification on the right-hand side of an C<access> declaration
may be a comma-separated list of multiple columns to search when the
specified access point is used:

 access 1016 = "name,year,notes"     # any

=head2 Searching with Multiple Attribute Sets

It is possible to support access points drawn from more than one
attribute set.  Often this is not necessary, as the BIB-1 attribute
set is so nearly ubiquitous.  However, supporting Z39.50 profiles
developed in accordance with the Attribute Architecture, such as the
Zthes and ZeeRex profiles, does require that attributes from multiple
sets can be mixed - for example, the use of both a Dublin Core "title"
and a Network Metadata "host" access points.  Another use for multiple
attribute sets is to support different access points that refer to the
same columns - for example, BIB-1 "title" (4) and the attribute
architecture cross-domain set's "title" (1).

In this case, simply provide multiple C<attrset> clauses within the
database's C<search> section, enclosed in curly braces:

 search {
     attrset bib1 {
         access 4 = "name"                      # BIB-1 title
         access 30 = "year"                     # BIB-1 year
         # ... etc. ...
     }
     attrset xd1 {                              # test for multiple attrsets
         access 1 = "name"                      # AA cross-domain title
         access 5 = "year"                      # AA cross-domain date
     }
 }

Then the following searches are equivalent: they are both title
searches, using the attributes from the two different sets:

 @attr 1=4 flower
 @attr xd1 1=1 flower

=head2 Specifying Attribute Sets by OID

C<zSQLgate> knows the names of the most commonly used attribute sets;
however, if it is necessary to support access points in an attribute
set that it doesn't know - for example, a private one - that attribute
set can be specfied by its OID rather than its name:

 attrset 1.2.840.10003.3.1000.169.42 {	# Private attribute-set
     access 609 = "notes"
 }

This can be useful for providing a way to search against a column that
can't be mapped to any of the access points in the standard sets: for
example, the C<notes> column of our books database.

Depending on what Z39.50 client you use, it should be possible to
search using any attribute set by spelling out its OID in the query.
For example, the YAZ command-line client lets you use:

 @attr 1.2.840.10003.3.1000.169.42 1=609 guess

=head2 Specifying Default Attributes for Searching

It's possible to specify a set of default attributes that are used in
every query unless overridden by attributes explicitly provided by the
query itself.  The attributes are listed after the C<defaultattrs>
keyword within the C<search> section.  This facility can be used to
choose a default access point:

 defaultattrs 1=4

Or default truncation:

 defaultattrs 5=3

Or indeed both:

 defaultattrs 1=4, 5=3

B<Note that default attributes specified in this manner are always
taken from the BIB-1 attribute set.  To make an access point in a
different attribute set the default, make a "private" BIB-1 access
point that searches in the same column, and make that the default.>

=head2 Restricting Searches to a Subset of Available Records

it is sometime useful to hide some records from all searching - for
example, records that have a "deleted" flag set, or that are marked as
requiring revision before they can be published.  This kind of
restriction can be specified within a C<database> section, specifying
an SQL clause to be ANDed with the query generated from what the
Z39.50 client submits.  For example:

 restriction = "author_id != 1"

ensures that only records whose C<author_id> is different from 1 are
included in the result sets returned to the client.

=head2 Linking Between Tables

We now approach the key to C<zSQLgate>'s power, which is the ability
to exploit relational links between tables (or, in Z39.50 terms,
between databases).  This is done using an C<auxiliary> clause within
a C<database> sections, specifying what other table is related to the
one in question, and by what relations.  For example, in our toy
database, every C<book> record has an C<author_id> which is the C<id>
of a record in the C<author> table.  This is expressed as follows:

 database "works" {
     table = "book"
     auxiliary "author" with "author.id = book.author_id"
     # ... etc. ...

This opens up the use of the auxiliary table's columns in both
searching and retrieval.  For example, it's possible to search the
C<works> database by author name as follows:

 access 1 = "author.name"		# personal name

And to include the author's name in the retrieved records as follows:

 field "authorName" = "author.name"

B<This only works correctly for many-to-one and one-to-many links.  If
an auxiliary table is specified that has many matches for the
condition, then too many records will be generated - one for each
linked record rather than one for each record in the primary table
associated with the Z39.50 database.>

=head2 Setting Attributes on XML Records

By default, the XML elements in the records generated by C<zSQLgate>
are wrapped in a simple document element, whose name is specified by
the C<record=> directive.  Sometimes, though, it is useful to include
attributes in this top-level element.  This can be done using the
C<attrs=> directive.

For example, the I<Guidelines for Implementing Dublin Core in XML> -
http://dublincore.org/documents/dc-xml-guidelines/index.shtml
- specify that Dublin Core elements should be in the XML namespace
http://purl.org/dc/elements/1.1/ .
This namespace can be declared with a C<dc> prefix in the document
element by specifying an C<xmlns:dc> attribute as follows:

 attrs = "xmlns:dc='http://purl.org/dc/elements/1.1/'"

=head2 Transforming XML Records with XSLT

The facilities for constructing XML records in C<zSQLgate> allow only
simple records to be created: a flat list of elements, each containing
a field from the database, wrapped in a top-level element that may
have some attributes specified.  For many applications, this is
sufficient.  But more flexibility is required if it's necessary to
construct records according to a pre-defined schema: for example, the
RDF representation of Dublin Core records as described in
I<Expressing Simple Dublin Core in RDF/XML> -
http://dublincore.org/documents/dcmes-xml/index.shtml
- describe a structure in which the data elements are contained in a
subelement of the document element, like this:

 <rdf:RDF ...>
   <rdf:Description ...>
     <dc:title>Dave Beckett's Home Page</dc:title>
     <dc:creator>Dave Beckett</dc:creator>
   </rdf:Description>
 </rdf:RDF>

In order to generate complex XML document such as this, zSQLgate
allows an arbitrary XSLT stylesheet to be applied to the generated
XML, and delivers the result of this transformation to the client.
This functionality is requested using the C<transform> directive

 transform = "dc-rdf.xsl"

within the C<format xml> section of the relevant database.  The
argument is the name of a file containing the stylesheet to be
applied, interpreted relative to the working directory of the
C<zSQLgate> server process.

Here is an example stylesheet, C<dc-rdf.xml>, which generates Dublin
Core RDF/XML records from the raw XML records generated by the
C<zsQLgate> core:

 <?xml version="1.0"?>
 <!-- $Id: Tutorial.pm,v 1.20 2005-04-22 12:19:17 mike Exp $ -->

 <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
   <xsl:output method="xml" indent="yes"
         doctype-public="-//DUBLIN CORE//DCMES DTD 2002/07/31//EN"
         doctype-system="http://dublincore.org/documents/2002/07/31/dcmes-xml/dcmes-xml-dtd.dtd"/>
   <xsl:template match="/book">
     <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
              xmlns:dc="http://purl.org/dc/elements/1.1/">
       <rdf:Description>
         <dc:title><xsl:value-of select="bookName"/></dc:title>
         <dc:creator><xsl:value-of select="authorName"/></dc:creator>
       </rdf:Description>
     </rdf:RDF>
   </xsl:template>
 </xsl:stylesheet>

=head2 Conditional Fields

I<"?notes">

=head2 Compound Fields

I<"%{field1} - %{field2}">

=head2 Complex String Constants

I<"foo" + "bar">

=head2 Generating MARC Records

I<format marc>

=head2 Generating GRS-1 Records

I<format grs1>

=head2 Generating Cutomised SUTRS Records

I<format sutrs>

=head2 Tuning Cache Size

I<cachesize>


=head1 PUTTING IT TOGETHER

Here, then, is the complete configuration file using all of the
facilities we've discussed:

 # books.nzd - a sample configuration file for Net::Z39.50::DBIServer
 # $Id: Tutorial.pm,v 1.20 2005-04-22 12:19:17 mike Exp $
 #
 # See Net::Z3950::DBIServer::Spec for a formal description of this
 # file's format, if you need it.  But it's actually pretty obvious.
 
 datasource = "DBI:mysql:dbname=books"           # If using MySQL
 #datasource = "DBI:Pg:dbname=books"             # If using PostgreSQL
 #username = "simon"                             # If needed
 #password = "pieman"                            # If needed
 
 database "artists" {
     table = "author"
     search attrset bib1 {
         access 12 = "id"                        # local number
         access 1 = "name"                       # author
     }
     data format xml {
         record = "author"
         field "authorId" = "id"
         field "authorName" = "name"
     }
 }
 
 database "works" {
     table = "book"
     auxiliary "author" with "author.id = book.author_id"
     restriction = "author_id != 1"              # Omit Douglas Adams books
     search {
         defaultattrs 1=4
         attrset bib1 {
             access 12 = "id"                    # local number
             access 4 = fulltext "name"          # title (fulltext for MySQL)
             access 30 = "year"                  # year
             access 1016 = "name,year,notes"     # any
         }
         attrset xd1 {                           # test for multiple attrsets
             access 1 = "name"                   # AA cross-domain title
             access 5 = "year"                   # AA cross-domain date
         }
         attrset 1.2.840.10003.3.1000.169.42 {   # Private attribute-set
             access 609 = "notes"
         }
     }
     data {
         cachesize = 2
         format grs1 {
             field (1,14) = "id"         # tagSet-M local control number
             field (3,"artistId") = "author_id"
             field (2,1) = "name"                # tagSet-G title
             field (2,4) = "year"                # tagSet-G date
             field (3,"notes") = "?notes"
         }
         format xml {
             record = "book"
             #attrs = "xmlns='http://sql.z3950.org/schema/books/1.0'"
             transform = "default.xsl"
             field "bookId" = "id"
             field "authorId" = "author_id"
             field "authorName" = "author.name"
             field "bookName" = "name"
             field "bookYear" = "year"
             field "bookNotes" = "?notes"
         }
         format marc {
             field "001" = "id"
             field "100/1$a" = "author.name"
             field "245/1/0$a" = "name"
             field "260$c" = "year"
             field "500$a" = "*MARC record generated by zSQLgate from MySQL"
             field "500$a" = "?notes"
         }
         format sutrs {
             field "LocalIdentifier" = "id"
             field "Title" = "name"
             field "Author" = "author.name"
             field "Published" = "year"
             field "Notes" = "?notes"
             field "titleStatement" = "<b>%{name}</b> -- <i>%{author.name}</i>"
         }
     }
 }


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Sunday 24th February 2002.

=cut

1;
