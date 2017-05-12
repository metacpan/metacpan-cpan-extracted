# $Header: /home/cvsroot/NetZ3950/Z3950/Tutorial.pm,v 1.16 2005/07/27 12:27:42 mike Exp $

package Net::Z3950::Tutorial;
use strict;


=head1 NAME

Net::Z3950::Tutorial - tutorial for the Net::Z3950 module


=head1 SYNOPSIS

Apparently, every POD document has to have a SYNOPSIS.  So here's one.


=head1 DESCRIPTION

C<Net::Z3950> is a Perl module for writing Z39.50 clients.  (If you
want to write a Z39.50 server, you want the
C<Net::Z3950::SimpleServer> module.)

Its goal is to hide all the messy details of the Z39.50 protocol - at
least by default - while providing access to all of its glorious
power.  Sometimes, this involves revealing the messy details after
all, but at least this is the programmer's choice.  The result is that
writing Z39.50 clients works the way it should according my favourite
of the various Perl mottos: ``Simple things should be simple, and
difficult things should be possible.''

If you don't know what Z39.50 is, then the best place to find out is
at
http://lcweb.loc.gov/z3950/agency/
the web site of the Z39.50 Maintenance Agency.  Among its many other
delights, this site contains a complete downloadable soft-copy of the
standard itself.  In briefest summary, Z39.50 is the international
standard for distributed searching and retrieval.


=head1 A VERY SIMPLE CLIENT

The C<Net::Z3950> distribution includes a couple of sample clients in
the C<samples> directory.  The simplest of them, C<trivial.pl> reads
as follows:

	use Net::Z3950;
	$conn = new Net::Z3950::Connection('indexdata.dk', 210,
					   databaseName => 'gils');
	$rs = $conn->search('mineral');
	print "found ", $rs->size(), " records:\n";
	my $rec = $rs->record(1);
	print $rec->render();

This complete program retrieves from the database called ``gils'' on
the Z39.50 server on port 210 of C<indexdata.dk> the first record
matching the search ``mineral'', and renders it in human-readable
form.  Typical output would look like this:

	6 fields:
	(1,1) 1.2.840.10003.13.2
	(1,14) "2"
	(2,1) {
	    (1,19) "UTAH EARTHQUAKE EPICENTERS"
	    (3,Acronym) "UUCCSEIS"
	}
	(4,52) "UTAH GEOLOGICAL AND MINERAL SURVEY"
	(4,1) "ESDD0006"
	(1,16) "198903"


=head1 HOW IT WORKS

Let's pick the trivial client apart line by line (it won't take long!)

	use Net::Z3950;

This line simply tells Perl to pull in the C<Net::Z3950> module - a
prerequisite for using types like C<Net::Z3950::Connection>.

	$conn = new Net::Z3950::Connection('indexdata.dk', 210,
					   databaseName => 'gils');

Creates a new connection to the Z39.50 server on port 210 of the host
C<indexdata.dk>, noting that searches on this connection will default
to the database called ``gils''.  A reference to the new connection is
stored in C<$conn>.

	$rs = $conn->search('mineral');

Performs a single-word search on the connection referenced by C<$conn>
(in the previously established default database, ``gils''.)  In
response, the server generates an I<result set>, notionally containing
all the matching records; a reference to the new connection is stored
in C<$rs>.

	print "found ", $rs->size(), " records:\n";

Prints the number of records in the new result set C<$rs>.

	my $rec = $rs->record(1);

Fetches from the server the first record in the result set C<$rs>,
requesting the default record syntax (GRS-1) and the default element
set (brief, ``b''); a reference to the newly retrieved record is
stored in C<$rec>.

	print $rec->render();

Prints a human-readable rendition of the record C<$rec>.  The exact
format of the rendition is dependent on issues like the record syntax
of the record that the server sent.


=head1 MORE COMPLEX BEHAVIOUR

=head2 Searching

Searches may be specified in one of several different syntaxes.
The default
syntax is so-called Prefix Query Notation, or PQN, a bespoke format
invented by Index Data to map simply to the Z39.50 type-1 query
structure.  A second is the Common Command Language (CCL) an
international standard query language often used in libraries.
The third is the Common Query Language (CQL) the query language
used by SRW and SRU.

CCL queries may be interpreted on the client side and translated into
a type-1 query which is forwarded to the server; or it may be sent
``as is'' for the server to interpret as it may.  CQL queries may only
be passed ``as is''.

The interpretation of the search string may be specified by passing an
argument of C<-prefix>, C<-ccl>, C<-ccl2rpn> or C<-cql> to the C<search()>
method before the search string itself, as follows:

B<Prefix Queries>

	$rs = $conn->search(-prefix => '@or rock @attr 1=21 mineral');

Prefix Query Notation is fully described in section 8.1 (B<Query
Syntax Parsers>) of the Yaz toolkit documentation, B<YAZ User's Guide
and Reference>.

Briefly, however, keywords begin with an C<@>-sign, and all other
words are interpreted as search terms.  Keywords include the binary
operators C<@and> and C<@or>, which join together the two operands
that follow them, and C<@attr>, which introduces a I<type>=I<value>
expression specifying an attribute to be applied to the following
term.

So:

=over 4

=item *

C<fruit> searches for the term ``fruit'',

=item *

C<@and fruit fish> searches for records containing both ``fruit'' and
``fish'',

=item *

C<@or fish chicken> searches for records containing either ``fish'' or
``chicken'' (or both),

=item *

C<@and fruit @or fish chicken> searches for records containing both
``fruit'' and at least one of ``fish'' or ``chicken''.

=item *

C<@or rock @attr 1=21 mineral> searches for records either containing
``rock'' or ``mineral'', but with the ``mineral'' search term carrying
an attribute of type 1, with value 21 (typically interpreted to mean
that the search term must occur in the ``subject'' field of the
record.)

=back

B<CCL Queries>

	$rs = $conn->search(-ccl2rpn => 'rock or su=mineral');
	$rs = $conn->search(-ccl => 'rock or su=mineral');

CCL is formally specified in the international standard ISO 8777
(B<Commands for interactive text searching>) and also described in
section 8.1 (B<Query Syntax Parsers>) of the Yaz toolkit
documentation, B<YAZ User's Guide and Reference>.

Briefly, however, there is a set of well-known keywords including
C<and>, C<or> and C<not>.  Words other than these are interpreted as
search terms.  Operating grouping (precedence) is specified by
parentheses, and the semantics of a search term may be modified by
prepending one or more comma-separated qualifiers qualifiers and an
equals sign.

So:

=over 4

=item *

C<fruit> searches for the term ``fruit'',

=item *

C<fruit and fish> searches for records containing both ``fruit'' and
``fish'',

=item *

C<fish or chicken> searches for records containing either ``fish'' or
``chicken'' (or both),

=item *

C<fruit and (fish or chicken)> searches for records containing both
``fruit'' and at least one of ``fish'' or ``chicken''.

=item *

C<rock or su=mineral> searches for records either containing
``rock'' or ``mineral'', but with the ``mineral'' search term modified
by the qualifier ``su'' (typically interpreted to mean that the search
term must occur in the ``subject'' field of the record.)

=back

For CCL searches sent directly to the server (query type C<ccl>), the
exact interpretation of the qualifiers is the server's
responsibility.  For searches compiled on the client side (query side
C<ccl2rpn>) the interpretation of the qualifiers in terms of type-1
attributes is determined by the contents of a file called
I<### not yet implemented>.
The format of this file is described in the Yaz documentation.

B<CQL Queries>

	$rs = $conn->search(-cql => 'au-(kernighan and ritchie)');

CQL syntax is very similar to that of CCL.

B<Setting Search Defaults>

As an alternative to explicitly specifying the query type when
invoking the C<search()> method, you can change the connection's
default query type using its C<option()> method:

	$conn->option(querytype => 'prefix');
	$conn->option(querytype => 'ccl');
	$conn->option(querytype => 'ccl2rpn');

The connection's current default query type can be retrieved using
C<option()> with no ``value'' argument:

	$qt = $conn->option('querytype');

The C<option()> method can be used to set and get numerous other
defaults described in this document and elsewhere; this method exists
not only on connections but also on managers (q.v.) and result sets.

Another important option is C<databaseName>, whose value specifies
which database is to be searched.

=head2 Retrieval

By default, records are requested from the server one at a time;
this can be quite slow when retrieving several records. There are two
ways of improving this. First, the C<present()> method can be used to
explicitly precharge the cache. Its parameters are a start record and
record count. In the following example, the present() is optional and
merely makes the code run faster:

	$rs->present(11, 5) or die ".....";
	foreach my $i (11..15) {
	    my $rec = $rs->record($i);
	    ...
	}

The second way is with the C<prefetch> option. Setting this to a 
positive integer makes the C<record()> method fetch the next N
records and place them in the cache if the the current record
isn't already there. So the following code would cause two bouts of
network activity, each retrieving 10 records.

	$rs->option(prefetch => 10);
	foreach my $i (1..20) {
	    my $rec = $rs->record($i);
	    ...
	}

In asynchronous mode, C<present()> and C<prefetch> merely cause the
records to be scheduled for retrieval.


B<Element Set>

The default element set is ``b'' (brief).  To change this, set the
result set's C<elementSetName> option:

	$rs->option(elementSetName => "f");

B<Record Syntax>

The default record syntax preferred by the C<Net::Z3950> module is
GRS-1 (the One True Record syntax).  If, however, you need to ask the
server for a record using a different record syntax, then the way to
do this is to set the C<preferredRecordSyntax> option of the result
set from which the record is to be fetched:

	$rs->option(preferredRecordSyntax => "SUTRS");

The record syntaxes which may be requested are listed in the
C<Net::Z3950::RecordSyntax> enumeration in the file C<Net/Z3950.pm>;
they include
C<Net::Z3950::RecordSyntax::GRS1>,
C<Net::Z3950::RecordSyntax::SUTRS>,
C<Net::Z3950::RecordSyntax::USMARC>,
C<Net::Z3950::RecordSyntax::TEXT_XML>,
C<Net::Z3950::RecordSyntax::APPLICATION_XML>
and
C<Net::Z3950::RecordSyntax::TEXT_HTML>

(As always, C<option()> may also be invoked with no ``value''
parameter to return the current value of the option.)

=head2 Scanning

B<### Note to self - write this section!>


=head1 WHAT TO DO WITH YOUR RECORDS

Once you've retrieved a record, what can you do with it?

There are two broad approaches.  One is just to display it to the
user: this can always be done with the C<render()> method, as used in
the sample code above, whatever the record syntax of the record.

The more sophisticated approach is to perform appropriate analysis and
manipulation of the raw record according to the record syntax.  The
raw data is retrieved using the C<rawdata()> method, and the record
syntax can be determined using the universal C<isa()> method:

	$raw = $rec->rawdata();
	if ($rec->isa('Net::Z3950::Record::GRS1')) {
		process_grs1_record($raw);
	elsif ($rec->isa('Net::Z3950::Record::USMARC')) {
		process_marc_record($raw);
	} # etc.

=head2 MARC RECORDS

For further manipulation of MARC records, we recommend the existing
MARC module in Ed Summers's directory at CPAN,
http://cpan.valueclick.com/authors/id/E/ES/ESUMMERS/

=head2 GRS-1 RECORDS

The raw data of GRS-1 records in the C<Net::Z3950> module closely
follows the structure of physcial GRS-1 records - see Appendices REC.5
(B<Generic Record Syntax 1>), TAG (B<TagSet Definitions and Schemas>)
and RET (B<Z39.50 Retrieval>) of the standard more details.

The raw GRS-1 data is intended to be more or less self-describing, but
here is a summary.

=over 4

=item *

The raw data is a reference to an array of elements, each representing
one of the fields of the record.

=item *

Each element is a C<Net::Z3950::APDU::TaggedElement> object.  These
objects support the accessor methods C<tagType()>, C<tagValue()>,
C<tagOccurrence()> and C<content()>; the first three of these return
numeric values, or strings in the less common case of string
tag-values.

=item *

The C<content()> of an element is an object of type
C<Net::Z3950::ElementData>.  Its C<which()> method returns a constant
indicating the type of the content, which may be any of the following:

=over 4

=item *

C<Net::Z3950::ElementData::Numeric>
indicates that the content is a number;
access it via the
C<numeric()>
method.

=item *

C<Net::Z3950::ElementData::String>
indicates that the content is a string of characters;
access it via the
C<string()>
method.

=item *

C<Net::Z3950::ElementData::OID>
indicates that the content is an OID, represented as a string with the
components separated by periods (``C<.>'');
access it via the
C<oid()>
method.

=item *

C<Net::Z3950::ElementData::Subtree>
is
a reference to another C<Net::Z3950::Record::GRS1> object, enabling
arbitrary recursive nesting;
access it via the
C<subtree()>
method.

=back

=back

In the future, we plan to take you away from all this by introducing a
C<Net::Z3950::Data> module which provides a DOM-like interface for
walking hierarchically structured records independently of their
record syntax.  Keep watchin', kids!


=head1 CHANGING SESSION PARAMETERS

As with customising searching or retrieval behaviour, whole-session
behaviour is customised by setting options.  However, this needs to be
done before the session is created, because the Z39.50 protocol
doesn't provide a method for changing (for example) the preferred
message size of an existing connection.

In the C<Net::Z3950> module, this is done by creating a I<manager> - a
controller for one or more connections.  Then the manager's options
can be set; then connections which are opened through the manager use
the specified values for those options.

As a matter of fact, I<every> connection is made through a manager.
If one is not specified in the connection constructor, then the
``default manager'' is used; it's automatically created the first time
it's needed, then re-used for any other connections that need it.

=head2 Make or Find a Manager

A new manager is created as follows:

	$mgr = new Net::Z3950::Manager();

Once the manager exists, a new connection can be made through it by
specifying the manager reference as the first argument to the connection
constructor:

	$conn = new Net::Z3950::Connection($mgr, 'indexdata.dk', 210);

Or equivalently, 

	$conn = $mgr->connect('indexdata.dk', 210);

In order to retrieve the manager through which a connection was made,
whether it was the implicit default manager or not, use the
C<manager()> method:

	$mgr = $conn->manager();

=head2 Set the Parameters

There are two ways to set parameters.  One we have already seen: the
C<option()> method can be used to get and set option values for
managers just as it can for connections and result sets:

	$pms = $mgr->option('preferredMessageSize');
	$mgr->option(preferredMessageSize => $pms*2);

Alternatively, options may be passed to the manager constructor when
the manager is first created:

	$mgr = new Net::Z3950::Manager(
		preferredMessageSize => 100*1024,
		maximumRecordSize => 10*1024*1024,
		preferredRecordSyntax => "GRS-1");

This is I<exactly> equivalent to creating a ``vanilla'' manager with
C<new Net::Z3950::Manager()>, then setting the three options with the
C<option()> method.

B<Message Size Parameters>

The C<preferredMessageSize> and C<maximumRecordSize> parameters can be
used to specify values of the corresponding parameters which are
proposed to the server at initialisation time (although the server is
not bound to honour them.)  See sections 3.2.1.1.4
(B<Preferred-message-size and Exceptional-message-size>) and 3.3
(B<Message/Record Size and Segmentation>) of the Z39.50 standard
itself for details.

Both options default to one megabyte.

B<Implementation Identification>

The C<implementationId>, C<implementationName> and
C<implementationVersion> options can be used to control the
corresponding parameters in initialisation request sent to the server
to identify the client.  The default values are listed below in the
section B<OPTION INHERITANCE>.

B<Authentication>

The C<user>, C<pass> and C<group> options can be specified for a
manager so that they are passed as identification tokens at
initialisation time to any connections opened through that manager.
The three options are interpreted as follows:

=over 4

=item *

If C<user> is not specified, then authentication is omitted (which is
more or less the same as ``anonymous'' authentication).

=item *

If C<user> is specified but not C<pass>, then the value of the
C<user> option is passed as an ``open'' authentication token.

=item *

If both C<user> and C<pass> are specified, then their values are
passed in an ``idPass'' authentication structure, together with the
value of C<group> if is it specified.

=back

By default, all three options are undefined, so no authentication is
used.


B<Character set and language negotiation>

The C<charset> and C<language> options can be used to negotiate the
character set and language to be used for connections opened through
that manager.  If these options are set, they are passed to the server
in a character-negotition otherInfo package attached to the
initialisation request.


=head1 OPTION INHERITANCE

The values of options are inherited from managers to connections,
result sets and finally to records.

This means that when a record is asked for an option value (whether by
an application invoking its C<option()> method, or by code inside the
module that needs to know how to behave), that value is looked for
first in the record's own table of options; then, if it's not
specified there, in the options of the result set from which the
record was retrieved; then if it's not specified there, in those of
the connection across which the result set was found; and finally, if
not specified there either, in the options for the manager through
which the connection was created.

Similarly, option values requested from a result set are looked up (if
not specified in the result set itself) in the connection, then the
manager; and values requested from a connection fall back to its
manager.

This is why it made sense in an earlier example (see the section B<Set
the Parameters>) to specify a value for the C<preferredRecordSyntax>
option when creating a manager: the result of this is that, unless
overridden, it will be the preferred record syntax when any record is
retrieved from any result set retrieved from any connection created
through that manager.  In effect, it establishes a global default.
Alternatively, one might specify different defaults on two different
connections.

In all cases, if the manager doesn't have a value for the requested
option, then a hard-wired default is used.  The defaults are as
follows.  (Please excuse the execrable formatting - that's what
C<pod2html> does, and there's no sensible way around it.)

=over 4

=item C<die_handler>

C<undef>
A function to invoke if C<die()> is called within the main event loop.

=item C<timeout>

C<undef>
The maximum number of seconds a manager will wait when its C<wait()>
method is called.  If the timeout elapses, C<wait()> returns an
undefined value.  B<Can not be set on a per-connection basis.>

=item C<async>

C<0>
(Determines whether a given connection is in asynchronous mode.)

=item C<preferredMessageSize>

C<1024*1024>

=item C<maximumRecordSize>

C<1024*1024>

=item C<user>

C<undef>

=item C<pass>

C<undef>

=item C<group>

C<undef>

=item C<implementationId>

C<'Mike Taylor (id=169)'>

=item C<implementationName>

C<'Net::Z3950.pm (Perl)'>

=item C<implementationVersion>

C<$Net::Z3950::VERSION>

=item C<charset>

C<undef>

=item C<language>

C<undef>

=item C<querytype>

C<'prefix'>

=item C<databaseName>

C<'Default'>

=item C<smallSetUpperBound>

C<0>
(This and the next four options provide flexible control for run-time
details such as what record syntax to use when returning records.  See
sections
3.2.2.1.4 (B<Small-set-element-set-names and
Medium-set-element-set-names>)
and
3.2.2.1.6 (B<Small-set-upper-bound, Large-set-lower-bound, and
Medium-set-present-number>)
of the Z39.50 standard itself for details.)

=item C<largeSetLowerBound>

C<1>

=item C<mediumSetPresentNumber>

C<0>

=item C<smallSetElementSetName>

C<'f'>

=item C<mediumSetElementSetName>

C<'b'>

=item C<preferredRecordSyntax>

C<'GRS-1'>

=item C<responsePosition>

C<1>
(Indicates the one-based position of the start term in the set of
terms returned from a scan.)

=item C<stepSize>

C<0>
(Indicates the number of terms between each of the terms returned from
a scan.)

=item C<numberOfEntries>

C<20>
(Indicates the number of terms to return from a scan.)

=item C<elementSetName>

C<'b'>

=item C<namedResultSets>

C<1> indicating boolean true.  This option tells the client to use a
new result set name for each new result set generated, so that old
C<ResultSet> objects remain valid.  For the benefit of old, broken
servers, this option may be set to 0, indicating that same result-set
name, C<default>, should be used for each search, so that each search
invalidates all existing C<ResultSet>s.

=back

Any other option's value is undefined.


=head1 ASYNCHRONOUS MODE

I don't propose to discuss this at the moment, since I think it's more
important to get the Tutorial out there with the synchronous stuff in
place than to write the asynchronous stuff.  I'll do it soon, honest.
In the mean time, let me be clear: the asynchronous code itself is
done and works (the synchronous interface is merely a thin layer on
top of it) - it's only the I<documentation> that's not yet here.

B<### Note to self - write this section!>


=head1 NOW WHAT?

This tutorial is only an overview of what can be done with the
C<Net::Z3950> module.  If you need more information that it provides,
then you need to read the more technical documentation on the
individual classes that make up the module -
C<Net::Z3950> itself,
C<Net::Z3950::Manager>,
C<Net::Z3950::Connection>,
C<Net::Z3950::ResultSet> and
C<Net::Z3950::Record>.


=head1 AUTHOR

Mike Taylor E<lt>mike@indexdata.comE<gt>

First version Sunday 28th January 2001.

=cut

1;
