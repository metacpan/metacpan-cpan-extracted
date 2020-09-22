# $Header: /home/mike/cvs/mike/zSQLgate/lib/Net/Z3950/DBIServer/Intro.pm,v 1.19 2007-10-23 11:26:20 mike Exp $

package Net::Z3950::DBIServer::Intro;
use strict;


=head1 NAME

Net::Z3950::DBIServer::Intro - An Introduction to zSQLgate

=head1 SYNOPSIS

C<zSQLgate>
provides an Z39.50 interface to your relational databases.
That is, it provides a generic gateway between the Z39.50 Information
Retrieval protocol and pretty much any relational database you
care to mention.

The Perl module L<Net::Z3950::DBIServer> provides the guts of the
gateway.  Both the C<zSQLgate> program and the
C<Net::Z3950::DBIServer> module are included in this distribution.

=head1 DESCRIPTION

The ANSI/NISO Z39.50 information retrieval protocol (now ratified as
international standard ISO 23950) is a mature and powerful protocol
used in application domains as diverse as bibliographic information,
geo-spatial mapping, cultural heritage,
and structured vocabulary navigation.  It's particularly useful in
distributed systems that need to provide uniform access to a variety
of different information resources, and has therefore provided the
technical backbone of many European and international collaborative
projects.  You can read more at the Z39.50 Maintenance Agency, at
http://lcweb.loc.gov/z3950/agency/

Relational database managegement systems (or RDBMSs) have been with us
for decades, but don't seem to be showing any signs of going away yet
:-)  The ubiquitous SQL language, which is used to search them, has its
roots three decades ago in 1973, when an early version (then called
``Sequel'') was described in R. F. Boyce and D. D. Chamberlin's paper
I<Using a Structured English Query Language as a Data Definition
Facility> (I<IBM RJ 1381>, December).

Z39.50 and relational databases may seem to belong to separate
universes, but in practice they often need to play nicely
together.  Many, perhaps most, Z39.50 servers are built on top of
relational databases; and many IR projects need to add Z39.50
interfaces to existing relational databases.

This has traditionally been an awkward and error-prone process, as
most of the available tools are rather low-level, and require
extensive programming.  C<zSQLgate> changes that by providing a
generic gateway - a Z39.50 server which
serves the data from a relational database.  Instead of requiring
programming, setting it up is a matter of writing a relatively
straightforward configuration file.


=head1 WHO NEEDS zSQLgate?

You may need C<zSQLgate> if:

=over 4

=item *

You already have an established project built on Oracle, Sybase,
PostgreSQL, MySQL or any of a seemingly infinite number of
alternatives, and you need to build an Z39.50 interface to it.

Z<>

=item *

You have a wide variety of relational databases, similar in concept
but different in the details, possibly running on different machines
and using different RDBMSs; and you want to build a single interface that
treats them all uniformly.

Z<>

=item *

You want to build a Z39.50 server from scratch, and for some reason
dedicated tools such as Index Data's Zebra -
http://www.indexdata.com/zebra/ - are not suitable.  You may want to
use a relational database because you're used to it, or because you
need industrial-strength data integrity, or commit/rollback, or some
other feature of a particular RDBMS.

Z<>

=back


=head1 Z39.50 CAPABILITIES

Part of the strength, and also part of the weakness, of Z39.50 is the
fact that it is not a monolithic standard: implementations are not
required to implement all of it - indeed, there is probably I<no>
Z39.50 implementation that supports the whole standard - but only
those parts which are useful to it.

In this section, we briefly discuss which parts of the Z39.50 standard
C<zSQLgate> supports.

=head2 Searching

C<zSQLgate> supports the Z39.50 Type-1 query (``RPN''), and the
identical Type-101 query.  Queries may include arbitrary combinations
of the AND, OR and ANDNOT boolean operators, nested to any depth.
Proximity operators are not supported.

Within individual terms, the following attributes are supported:

=over 4

=item Access points (attribute type = 1)

Any access points from any attribute sets may be supported, depending
on the C<attrset> clauses in the configuration file.

The configuration file may specify what access-point is used if none
is explicitly indicated by a query.

=item BIB-1 relations (attribute type = 2)

The ordering relations
1 (less than),
2 (less then or equal),
3 (equal),
4 (greater than or equal),
5 (greater than)
and
6 (not equal)
are all supported; but not the more esoteric relations
100 (phonetic),
101 (stem),
102 (relevance)
and
103 (AlwaysMatches).

If no explicit relation attribute is specified, equality (value = 3)
is assumed unless overridden by the configuration file.

=item BIB-1 truncations (attribute type = 5)

Truncation attributes
1 (right-truncation),
2 (left-truncation),
3 (left- and right-truncation),
100 (do not truncate)
and
101 (process # in search term) are supported;
but not
102 (RegExpr-1)
or
103 (RegExpr-2).

If no explicit relation attribute is specified, no truncation (value =
100) is assumed unless overridden by the configuration file.

=back

Attributes of type 3 (position), 4 (structure) and 6 (completeness)
are ignored.  All search terms are treated as being of type string -
that is, as though an attribute of type 4 (structure) and value 108
(string) had been specified.

=head2 Retrieval

C<zSQLgate> currently supports retrieval using the following record
syntaxes:

=over 4

=item SUTRS

The SUTRS record-syntax is supported natively, with no need for any
configuration.  The returned record is extremely raw, consisting only
of a list of elements, one per line, in the format ``C<field: value>'',
sorted in alphabetical order by fieldname.  This can be useful for
debugging a configuaration because of the minimal munging involved.

This default formatting of SUTRS records may optionally be overridden
by the configuaration file, for servers that need to support
SUTRS-based clients.

=item XML

C<zSQLgate> supports the generation of XML in any format, using a
two-stage process.  An initial, simple, record is formed using a set
of elements whose names are mapped to expressions from the database;
then that record may be passed through an arbitrary XSLT stylesheet to
transform it into the desired format.  In this way, for example,
MarcXML or RDF records can be generated.

=item GRS-1

The GRS-1 record-syntax is supported, but at present the generated
records can include only top-level fields (i.e. tag-paths of a single
element).  Support for sub-records will be added in a subsequent
release if there is demand for it.

=item MARC

MARC records can be generated by a field-mapping specification.  The
precise dialect of MARC (MARC21, UKMARC, etc.) supported by a
particular deployment of C<zSQLgate> is a function of the mapping
specified in the configuration file.  MARC records may contain
repeated fields.

=back

=head2 Other

C<zSQLgate> does not currently include any support for Z39.50's
C<sort>, C<scan> or C<extended services>.  This functionality can be
added if required: contact the author if you wish to build a server
that provides these services.


=head1 LIMITATIONS

C<zSQLgate> is focused on doing one thing well: that is, providing the
means for Z39.50 clients to search in, and fetch data from, relational
databases.  So it does not currently address any of the following:

=over 4

=item *

Database update.  C<zSQLgate> provides a read-only interface.

Z<>

=item *

Z39.50 ``extras'' such as inter-library loan (ILL).

Z<>

=item *

``Fan out'', or the provision of ``union catalogues'' (though this
could be added in subsequent versions if there's demand for it.)

Z<>

=back


=head1 FUTURE DIRECTIONS

Intended enhancements for C<zSQLgate> include the following:

=over 4

=item *

Allow specification of semantics for attributes other than access
points.  (Relation and truncation are handled by hardwired code that
knows about the relevant attributes in the BIB-1 and Utility sets.)

Z<>

=item *

Allow elements to be marked for inclusion in the brief record
(element-set name C<b>).  More generally, provide the wherewithal for
the configuration file to specify the contents of arbitrary element
sets.

Z<>

=item *

Allow the configuration file to override some global parameters on a
per-logical-database basis.  For example, the back-end data-source
(DBI database, or DSN) and authentication parameters.

Z<>

=item *

Allow the configuration file to set other DBI parameters such as
C<auto_commit>.

Z<>

=item *

Allow the configuration file to specify which port or ports the server
should listen on.  Maybe also other Z39.50 server options.

Z<>

=item *

Allow the inclusion of sub-files.  This will be useful to allow, for
example, element sets to be specified in their own files.

Z<>

=item *

Provide the ability to make multiple back-end databases look like a
single large data repository (``union catalogue'').  This is a much
bigger deal the most of the other enhancements mentioned here, and
will probably only happen if there's a real need for it in a specific
project.

Z<>

=back

I plan to implement these enhancements more or less in the order that
customers need them, so do give me a shout if anything listed here (or
indeed anything not listed) is high on your ``must have'' list, and
I'll see what I can do.


=head1 TERMS AND CONDITIONS

This module is released under
non-free terms - see L<Net::Z3950::DBIServer::LICENCE>.  In a
nutshell, you can download, unpack, build and evaluate it for free,
for you may not deploy it without first purchasing a deployment
licence.

The price of a deployment licence is either £2500 as a one-off fee for
perpetual deployment, or £1000 for a one-year deployment licence and
an additional £750 per year thereafter.  That fee includes limited
support and a small amount of development work where appropriate.


=head1 NOW WHAT?

If you've not already read the licence, you should.
L<Net::Z3950::DBIServer::LICENCE>.
If you need help installing, you might find
L<Net::Z3950::DBIServer::Install>
helpful.
Then it's on to the the tutorial,
L<Net::Z3950::DBIServer::Tutorial>,
after which you may wish to go on to some of the more brutally
technical documents, including the configuration file specification,
L<Net::Z3950::DBIServer::Spec>.


=head1 AUTHOR

Mike Taylor E<lt>mike@miketaylor.org.ukE<gt>

First version Sunday 24th February 2002.

=cut

1;
