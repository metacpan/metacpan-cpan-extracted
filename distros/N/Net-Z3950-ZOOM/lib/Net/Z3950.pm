use strict;
use warnings;
use Net::Z3950::ZOOM;

our $VERSION = '0.99';	# Supersedes "proper" Net::Z3950 v0.51


# Member naming convention is the same as in ../ZOOM.pm

# ----------------------------------------------------------------------------
# Enumerations are copied from the old Net::Z3950 module.
# It's not entirely clear yet which of these we actually need, so for
# now I am commenting them all out, and faulting in the ones we need.
# ----------------------------------------------------------------------------

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


## Define the record-syntax enumeration.  These values must be kept
## synchronised with the values implied by the oid_value enumeration in
## the header file "yaz/oid.h"
#package Net::Z3950::RecordSyntax;
#sub UNIMARC    { 16 }
#sub INTERMARC  { 17 }
#sub CCF        { 18 }
#sub USMARC     { 19 }
#sub UKMARC     { 20 }
#sub NORMARC    { 21 }
#sub LIBRISMARC { 22 }
#sub DANMARC    { 23 }
#sub FINMARC    { 24 }
#sub MAB        { 25 }
#sub CANMARC    { 26 }
#sub SBN        { 27 }
#sub PICAMARC   { 28 }
#sub AUSMARC    { 29 }
#sub IBERMARC   { 30 }
#sub CATMARC    { 31 }
#sub MALMARC    { 32 }
#sub EXPLAIN    { 33 }
#sub SUTRS      { 34 }
#sub OPAC       { 35 }
#sub SUMMARY    { 36 }
#sub GRS0       { 37 }
#sub GRS1       { 38 }
#sub EXTENDED   { 39 }
#sub TEXT_HTML  { 70 }
#sub XML        { 80 }
#sub TEXT_XML   { 80 }
#sub APPLICATION_XML { 81 }
#
#use vars '%map';
## Maps record-syntax name strings to enumeration members
#%map = (UNIMARC => UNIMARC,
#	INTERMARC => INTERMARC,
#	CCF => CCF,
#	USMARC => USMARC,
#	UKMARC => UKMARC,
#	NORMARC => NORMARC,
#	LIBRISMARC => LIBRISMARC,
#	DANMARC => DANMARC,
#	FINMARC => FINMARC,
#	MAB => MAB,
#	CANMARC => CANMARC,
#	SBN => SBN,
#	PICAMARC => PICAMARC,
#	AUSMARC => AUSMARC,
#	IBERMARC => IBERMARC,
#	CATMARC => CATMARC,
#	MALMARC => MALMARC,
#	EXPLAIN => EXPLAIN,
#	SUTRS => SUTRS,
#	OPAC => OPAC,
#	SUMMARY => SUMMARY,
#	GRS0 => GRS0,
#	GRS1 => GRS1,
#	EXTENDED => EXTENDED,
#	TEXT_HTML => TEXT_HTML,
#	XML => XML,
#	TEXT_XML => TEXT_XML,
#	APPLICATION_XML => APPLICATION_XML,
#	);
#package Net::Z3950;
#
#
## Define the reason-for-decodeAPDU()-failure enumeration.  This must
## be kept synchronised with the values #defined in "yazwrap/yazwrap.h"
#package Net::Z3950::Reason;
#sub EOF        { 23951 }	# read EOF from connection (server gone)
#sub Incomplete { 23952 }	# read bytes, but not yet a whole APDU
#sub Malformed  { 23953 }	# couldn't decode APDU (malformed)
#sub BadAPDU    { 23954 }	# APDU was well-formed but unrecognised
#sub Error      { 23955 }	# some other error (consult errno)
#package Net::Z3950;
#
#
## Define the query-type enumeration.  This must be kept synchronised
## with the values #defined in "yazwrap/yazwrap.h"
#package Net::Z3950::QueryType;
#sub Prefix  { 39501 }		# Yaz's "@attr"-ish forward-Polish notation
#sub CCL     { 39502 }		# Send CCL string to server ``as is''
#sub CCL2RPN { 39503 }		# Convert CCL to RPN (type-1) locally
#sub CQL     { 39504 }		# Send CQL string to server ``as is''
#package Net::Z3950;
#
#
## Define the result-set-status enumeration, used by the
## `resultSetStatus' field in the Net::Z3950::APDU::SearchResponse
## class in cases where `searchStatus' is false (indicating failure).
## This must be kept synchronised with the ASN.1 for the structure
## described in section 3.2.2.1.11 of the Z39.50 standard itself.
#package Net::Z3950::ResultSetStatus;
#sub Subset  { 1 }
#sub Interim { 2 }
#sub None    { 3 }
#package Net::Z3950;
#
#
## Define the present-status enumeration, used by the `presentStatus'
## field in the Net::Z3950::APDU::SearchResponse class in cases where
## `searchStatus' is true (indicating success).  This must be kept
## synchronised with the ASN.1 for the structure described in section
## 3.2.2.1.11 of the Z39.50 standard itself.
#package Net::Z3950::PresentStatus;
#sub Success  { 0 }
#sub Partial1 { 1 }
#sub Partial2 { 2 }
#sub Partial3 { 3 }
#sub Partial4 { 4 }
#sub Failure  { 5 }
#package Net::Z3950;
#
#
## Define the scan-status enumeration, used by the `scanStatus'
## field in the Net::Z3950::APDU::ScanResponse class.  This must be
## kept synchronised with the ASN.1 for the structure described in
## section 3.2.8.1.6 of the Z39.50 standard itself.
#package Net::Z3950::ScanStatus;
#sub Success  { 0 }
#sub Partial1 { 1 }
#sub Partial2 { 2 }
#sub Partial3 { 3 }
#sub Partial4 { 4 }
#sub Partial5 { 5 }
#sub Failure  { 6 }
#package Net::Z3950;

# ----------------------------------------------------------------------------

package Net::Z3950;

sub errstr {
    my($errcode) = @_;
    # This is not 100% compatible, because it will translate
    # ZOOM-level errors as well as BIB-1 diagnostic codes.
    return Net::Z3950::ZOOM::diag_str($errcode)
}

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


# ----------------------------------------------------------------------------

package Net::Z3950::Manager;
sub new { Net::Z3950::Connection->new() }


# ----------------------------------------------------------------------------

package Net::Z3950::Connection;

sub new {
    die "The Net::Z3950::ZOOM distribution does not yet support the Net::Z3950 'Classic' API.  A subsequent version will do so; until then, please continue using Net::Z3950 itself if you need its API."
}


1;
