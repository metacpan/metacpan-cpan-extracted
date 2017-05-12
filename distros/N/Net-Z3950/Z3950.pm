# $Id: Z3950.pm,v 1.47 2006/05/08 10:50:21 mike Exp $

package Net::Z3950;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
$VERSION = '0.51';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Net::Z3950 macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Net::Z3950 $VERSION;


=head1 NAME

Net::Z3950 - Perl extension for talking to Z39.50 servers.

=head1 WARNING

You should not be using this module unless you need
this precise API for compatibility reasons.  New applications
should use the ZOOM-Perl module (Net::Z3950::ZOOM) instead.

http://search.cpan.org/~mirk/Net-Z3950-ZOOM/

=head1 SYNOPSIS

(This code blocks in reads: see below for sample non-blocking code
which allows multiple servers to be searched in parallel.)

	use Net::Z3950;

	$conn = new Net::Z3950::Connection('server.host.name', 210)
	    or die $!;
	$rs = $conn->search('au=kernighan or su=unix')
	    or die $conn->errmsg();

	my $n = $rs->size();
	print "found $n records:\n";
	foreach $i (1..$n) {
	    $rec = $rs->record($i) or die $rs->errmsg();
	    print $rec->render();
	}

	$conn->close();

=head1 DESCRIPTION

This module provides a Perl interface to the Z39.50 information
retrieval protocol (aka. ISO 23950), a mature and powerful protocol
used in application domains as diverse as bibliographic information,
geo-spatial mapping, museums and other cultural heritage information,
and structured vocabulary navigation.

C<Net::Z3950.pm> is an implementation of the Perl binding for ZOOM, the
Z39.50 Objct Orientation Model.  Bindings for the same abstract API
are, or will be, available in other languages including C, C++, Java
and Tcl.

Two basic approaches are possible to building clients with this
module:

=over 4

=item *

The simple synchronous approach considers blocking reads acceptable, and
therefore allows a straightforward style of imperative programming.
This approach is suitable for clients which only talk to one server at
a time, and is exemplified by the code in the SYNOPSIS section above.

=item *

The more complex asynchronous approach, appropriate for clients which
multiplex simultaneous connections, requires a slightly less familiar
event-driven programming style, as exemplified in the ASYNCHRONOUS
SYNOPSIS section below.

=back

(The simpler synchronous interface functions are implemented as a thin
layer on top of the asynchronous functions.)

=head1 ASYNCHRONOUS SYNOPSIS

(This code does not block in reads, and so is suitable for broadcast
clients which search multiple servers simultaneously: see above for
simpler sample code that blocks in reads.)

I<### To be written>

=cut


# Define the operation-code enumeration.  The values here are chosen
# to be in a distinctive range (i.e. 3950 plus a small integer) so
# that if they are misused in another context, they're easy to spot.
package Net::Z3950::Op;
sub Error    { 3951 }
sub Init     { 3952 }
sub Search   { 3953 }
sub Get      { 3954 }
sub DeleteRS { 3955 }
sub Scan     { 3956 }
package Net::Z3950;


# Define the record-syntax enumeration.  These values must be kept
# synchronised with the values implied by the oid_value enumeration in
# the header file "yaz/oid.h"
package Net::Z3950::RecordSyntax;
sub UNIMARC    { 16 }
sub INTERMARC  { 17 }
sub CCF        { 18 }
sub USMARC     { 19 }
sub UKMARC     { 20 }
sub NORMARC    { 21 }
sub LIBRISMARC { 22 }
sub DANMARC    { 23 }
sub FINMARC    { 24 }
sub MAB        { 25 }
sub CANMARC    { 26 }
sub SBN        { 27 }
sub PICAMARC   { 28 }
sub AUSMARC    { 29 }
sub IBERMARC   { 30 }
sub CATMARC    { 31 }
sub MALMARC    { 32 }
sub EXPLAIN    { 33 }
sub SUTRS      { 34 }
sub OPAC       { 35 }
sub SUMMARY    { 36 }
sub GRS0       { 37 }
sub GRS1       { 38 }
sub EXTENDED   { 39 }
sub TEXT_HTML  { 70 }
sub XML        { 80 }
sub TEXT_XML   { 80 }
sub APPLICATION_XML { 81 }

use vars '%map';
# Maps record-syntax name strings to enumeration members
%map = (UNIMARC => UNIMARC,
	INTERMARC => INTERMARC,
	CCF => CCF,
	USMARC => USMARC,
	UKMARC => UKMARC,
	NORMARC => NORMARC,
	LIBRISMARC => LIBRISMARC,
	DANMARC => DANMARC,
	FINMARC => FINMARC,
	MAB => MAB,
	CANMARC => CANMARC,
	SBN => SBN,
	PICAMARC => PICAMARC,
	AUSMARC => AUSMARC,
	IBERMARC => IBERMARC,
	CATMARC => CATMARC,
	MALMARC => MALMARC,
	EXPLAIN => EXPLAIN,
	SUTRS => SUTRS,
	OPAC => OPAC,
	SUMMARY => SUMMARY,
	GRS0 => GRS0,
	GRS1 => GRS1,
	EXTENDED => EXTENDED,
	TEXT_HTML => TEXT_HTML,
	XML => XML,
	TEXT_XML => TEXT_XML,
	APPLICATION_XML => APPLICATION_XML,
	);
package Net::Z3950;


# Define the reason-for-decodeAPDU()-failure enumeration.  This must
# be kept synchronised with the values #defined in "yazwrap/yazwrap.h"
package Net::Z3950::Reason;
sub EOF        { 23951 }	# read EOF from connection (server gone)
sub Incomplete { 23952 }	# read bytes, but not yet a whole APDU
sub Malformed  { 23953 }	# couldn't decode APDU (malformed)
sub BadAPDU    { 23954 }	# APDU was well-formed but unrecognised
sub Error      { 23955 }	# some other error (consult errno)
package Net::Z3950;


# Define the query-type enumeration.  This must be kept synchronised
# with the values #defined in "yazwrap/yazwrap.h"
package Net::Z3950::QueryType;
sub Prefix  { 39501 }		# Yaz's "@attr"-ish forward-Polish notation
sub CCL     { 39502 }		# Send CCL string to server ``as is''
sub CCL2RPN { 39503 }		# Convert CCL to RPN (type-1) locally
sub CQL     { 39504 }		# Send CQL string to server ``as is''
package Net::Z3950;


# Define the result-set-status enumeration, used by the
# `resultSetStatus' field in the Net::Z3950::APDU::SearchResponse
# class in cases where `searchStatus' is false (indicating failure).
# This must be kept synchronised with the ASN.1 for the structure
# described in section 3.2.2.1.11 of the Z39.50 standard itself.
package Net::Z3950::ResultSetStatus;
sub Subset  { 1 }
sub Interim { 2 }
sub None    { 3 }
package Net::Z3950;


# Define the present-status enumeration, used by the `presentStatus'
# field in the Net::Z3950::APDU::SearchResponse class in cases where
# `searchStatus' is true (indicating success).  This must be kept
# synchronised with the ASN.1 for the structure described in section
# 3.2.2.1.11 of the Z39.50 standard itself.
package Net::Z3950::PresentStatus;
sub Success  { 0 }
sub Partial1 { 1 }
sub Partial2 { 2 }
sub Partial3 { 3 }
sub Partial4 { 4 }
sub Failure  { 5 }
package Net::Z3950;


# Define the scan-status enumeration, used by the `scanStatus'
# field in the Net::Z3950::APDU::ScanResponse class.  This must be
# kept synchronised with the ASN.1 for the structure described in
# section 3.2.8.1.6 of the Z39.50 standard itself.
package Net::Z3950::ScanStatus;
sub Success  { 0 }
sub Partial1 { 1 }
sub Partial2 { 2 }
sub Partial3 { 3 }
sub Partial4 { 4 }
sub Partial5 { 5 }
sub Failure  { 6 }
package Net::Z3950;


# Include modules implementing Net::Z3950 classes
use Net::Z3950::Manager;
use Net::Z3950::Connection;
use Net::Z3950::APDU;
use Net::Z3950::ResultSet;
use Net::Z3950::Record;
use Net::Z3950::ScanSet;


=head1 FUNCTIONS

The C<Net::Z3950> module itself provides very few functions: most of the
functionality is provided by the daughter modules included by C<Net::Z3950>
- C<Net::Z3950::Manager>, C<Net::Z3950::Connection>, I<etc.>

=cut


=head2 errstr()

	$errcode = $conn->errcode();
	$errmsg = Net::Z3950::errstr($errcode);
	print "error $errcode ($errmsg)\n";

Returns an English-language string describing the error indicated by
the Z39.50 BIB-1 diagnostic error code I<$errcode>.

=cut

sub errstr {
    my($errcode) = @_;

    use Carp;
    confess "errstr() called with undefined argument" if !defined $errcode;
    return "not yet available (try again later)" if $errcode == 0;
    return diagbib1_str($errcode);
}


=head2 opstr()

	$str = Net::Z3950::opstr($conn->errop());
	print "error occurred in $str\n";

Returns an English-language string describing the operation indicated
by the argument, which must be one of the C<Net::Z3950::Op::*> constants
described in the documentation for the C<Net::Z3950::Connection> class's
C<op()> method.

=cut

sub opstr {
    my($op) = @_;
    return "error" if $op == Net::Z3950::Op::Error;
    return "init" if $op == Net::Z3950::Op::Init;
    return "search" if $op == Net::Z3950::Op::Search;
    return "get" if $op == Net::Z3950::Op::Get;
    return "deleteRS" if $op == Net::Z3950::Op::DeleteRS;
    return "scan" if $op == Net::Z3950::Op::Scan;
    return "unknown op " . $op;
}


=head1 AUTHOR

Mike Taylor E<lt>mike@indexdata.comE<gt>

First version Tuesday 23rd May 2000.

=head1 SEE ALSO

The ZOOM API for Z39.50, of which this is an implementation, is fully
specified at
http://zoom.z3950.org
where links to other implementations may also be found.

This module is built on Index Data's Yaz (Yet Another Z39.50) toolkit,
which is freely available at
http://indexdata.dk/yaz/

Index Data also provide a variety of other useful Z39.50 software
including the free server/database Zebra, the commercial
server/database Z'mbol, a Tcl interface to Z39.50 called Ir/Tcl, and a
free web-to-Z39.50 gateway called Zap.  See their home page at
http://indexdata.dk/

The best source of information about Z39.50 itself is the official
Mainenance Agency at
http://lcweb.loc.gov/z3950/agency/

=cut

1;
__END__
