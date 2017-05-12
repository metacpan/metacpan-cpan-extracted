# $Header: /home/cvsroot/NetZ3950/Z3950/APDU.pm,v 1.13 2005/04/19 21:36:35 mike Exp $

package Net::Z3950::APDU;
use strict;
use vars qw($AUTOLOAD @FIELDS);


=head1 NAME

Net::Z3950::APDU - Read-only objects representing decoded Z39.50 APDUs

=head1 SYNOPSIS

I<You probably shouldn't be reading this!>

	package Net::Z3950::APDU::SomeSpecificSortOfAPDU;
	use Net::Z3950::APDU;
	@ISA = qw(Net::Z3950::APDU);
	@FIELDS = qw(names of APDU fields);

=head1 DESCRIPTION

This class provides a trivial base for the various read-only APDUs
implemented as a part of the Net::Z3950 module.  Its role is simply to
supply named methods providing read-only access to the same-named
fields.  The set of fields is specified by the derived class's
package-global C<@FIELDS> array.

I<You don't need to understand or use this class in order to use the
Net::Z3950 module.  It's purely an implementation detail.  In fact, I
probably should never even have written this documentation.  Forget I
said anything.  Go and read the next section.>

=cut

sub AUTOLOAD {
    my $this = shift();

    my $class = ref $this;
    my $fieldname;
    ($fieldname = $AUTOLOAD) =~ s/.*:://;
    die "class $class -- field `$fieldname' not defined"
	if !grep { $_ eq $fieldname } $class->_fields();

    return $this->{$fieldname};
}

sub DESTROY {
    # Do nothing.  This is only here because on some installations --
    # I don't really have a handle on what the condition is --
    # APDU-derived objects try to call DESTROY when they're thrown
    # away, and that was getting translated into a call to AUTOLOAD,
    # which was complaining "field `DESTROY' not defined".  Now that
    # we have an explicit no-opping DESTROY, that shouldn't happen.
    #
    # The only discussion I have found anywhere of DESTROY/AUTOLOAD
    # interaction is this thread on comp.lang.perl.moderated:
    #	http://groups.google.com/groups?hl=en&frame=right&th=1bc05ce0aff89451&seekm=86r9qpmvbv.fsf%40lion.plab.ku.dk#link1
}


=head1 SUBCLASSES

The following classes are all trivial derivations of C<Net::Z3950::APDU>,
and represent specific types of APDU.  Each such class is
characterised by the set of data-access methods it supplies: these are
listed below.

Each method takes no arguments, and returns the information implied by
its name.  See the relevant sections of the Z39.50 Standard for
information on the interpretation of this information - for example,
section 3.2.1 (Initialization Facility) describes the elements of the
C<Net::Z3950::APDU::InitResponse> class.

I<Actually, you don't need to understand or use any of these classes
either: they're used internally in the implementation, so this
documentation is provided as a service to those who will further
develop this module in the future.>

=cut


=head2 Net::Z3950::APDU::InitResponse

	referenceId()
	preferredMessageSize()
	maximumRecordSize()
	result()
	implementationId()
	implementationName()
	implementationVersion()

=cut

package Net::Z3950::APDU::InitResponse;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(referenceId preferredMessageSize maximumRecordSize result
	     implementationId implementationName
	     implementationVersion);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::SearchResponse

	referenceId()
	resultCount()
	numberOfRecordsReturned()
	nextResultSetPosition()
	searchStatus()
	resultSetStatus()
	presentStatus()
	records()
	additionalSearchInfo()

=cut

package Net::Z3950::APDU::SearchResponse;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(referenceId resultCount numberOfRecordsReturned
	     nextResultSetPosition searchStatus resultSetStatus
	     presentStatus records additionalSearchInfo);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::ScanResponse

	referenceId()
	stepSize()
	scanStatus()
	numberOfEntriesReturned()
	positionOfTerm()
	entries()
	diag()

The C<diag()> method should be consulted when C<scanStatus()> returns
6, indicating failure; otherwise, C<entries()> may be consulted.

=cut

package Net::Z3950::APDU::ScanResponse;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(referenceId stepSize scanStatus
             numberOfEntriesReturned positionOfTerm
             entries diag);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::PresentResponse

	referenceId()
	numberOfRecordsReturned()
	nextResultSetPosition()
	presentStatus()
	records()

=cut

package Net::Z3950::APDU::PresentResponse;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(referenceId numberOfRecordsReturned nextResultSetPosition
	     presentStatus records);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::DeleteRSResponse

	referenceId()
	deleteOperationStatus()

(We don't bother to decode the rest of this APDU at the moment, since
I bet everyone calls C<Net::Z3950::ResultSet::delete()> in void
context.  If anyone wants more information out of it, we can wire it
through.)

=cut

package Net::Z3950::APDU::DeleteRSResponse;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(referenceId deleteOperationStatus);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::Close

	referenceId()
	closeReason()
	diagnosticInformation()

In addition, this class provides a method of no arguments,
C<as_text()>, which returns a human-readable string describing the
reason for the close.

=cut

package Net::Z3950::Close;
sub Finished		{ 0 }
sub Shutdown		{ 1 }
sub SystemProblem	{ 2 }
sub CostLimit		{ 3 }
sub Resources		{ 4 }
sub SecurityViolation	{ 5 }
sub ProtocolError	{ 6 }
sub LackOfActivity	{ 7 }
sub PeerAbort		{ 8 }
sub Unspecified		{ 9 }

package Net::Z3950::APDU::Close;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(closeReason diagnosticInformation referenceId);
sub _fields { @FIELDS };

# render the info as a printable string

sub as_text {
    my $this = shift;
    my $text = (
	    qw( Finished Shutdown SystemProblem CostLimit
	    Resources SecurityViolation ProtocolError
	    LackOfActivity PeerAbort Unspecified )
	)[$this->{closeReason}] || '**Unknown**';
    $text .= " ($this->{diagnosticInformation})"
    				if defined $this->{diagnosticInformation};
    $text .= " refid[$this->{referenceId}]"
    				if defined $this->{referenceId};

    $text;
}


=head2 Net::Z3950::APDU::NamePlusRecordList

No methods - just treat as a reference to an array of
C<Net::Z3950::APDU::NamePlusRecord>

=cut

package Net::Z3950::APDU::NamePlusRecordList;


=head2 Net::Z3950::APDU::NamePlusRecord

	databaseName()
	which()
	databaseRecord()
	surrogateDiagnostic()
	startingFragment()
	intermediateFragment()
	finalFragment()

Only one of the last five methods will return anything - you can find
out which one by inspecting the return value of the C<which()> method,
which always takes one of the following values:

=over 4

=item *

Net::Z3950::NamePlusRecord::DatabaseRecord

=item *

Net::Z3950::NamePlusRecord::SurrogateDiagnostic

=item *

Net::Z3950::NamePlusRecord::StartingFragment

=item *

Net::Z3950::NamePlusRecord::IntermediateFragment

=item *

Net::Z3950::NamePlusRecord::FinalFragment

=back

When C<which()> is C<Net::Z3950::NamePlusRecord::DatabaseRecord>, the
object returned from the C<databaseRecord()> method will be a decoded
Z39.50 EXTERNAL.  Its type may be any of the following (and may be
tested using C<$rec-E<gt>isa('Net::Z3950::Record::Whatever')> if necessary.)

=over 4

=item *

Net::Z3950::Record::SUTRS

=item *

Net::Z3950::Record::GRS1

=item *

Net::Z3950::Record::USMARC and
similarly, Net::Z3950::Record::UKMARC, Net::Z3950::Record::NORMARC, I<etc>.

=item *

Net::Z3950::Record::XML

=item *

Net::Z3950::Record::HTML

=item *

Net::Z3950::Record::OPAC

I<### others, not yet supported>

=back

=cut

package Net::Z3950::APDU::NamePlusRecord;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);

@FIELDS = qw(databaseName which databaseRecord surrogateDiagnostic
	     startingFragment intermediateFragment finalFragment);
sub _fields { @FIELDS };

# Define the NamePlusRecord class's "which" enumeration, which
# indicates which of the possible branches contains data (i.e. it's
# the discriminator for a union.)  This must be kept synchronised with
# the values defined in the header file <yaz/z-core.h>
package Net::Z3950::NamePlusRecord;
sub DatabaseRecord       { 1 }
sub SurrogateDiagnostic  { 2 }
sub StartingFragment     { 3 }
sub IntermediateFragment { 4 }
sub FinalFragment        { 5 }
package Net::Z3950;


=head2 Net::Z3950::APDU::SUTRS, Net::Z3950::APDU::USMARC, Net::Z3950::APDU::UKMARC, Net::Z3950::APDU::NORMARC, Net::Z3950::APDU::LIBRISMARC, Net::Z3950::APDU::DANMARC, Net::Z3950::APDU::UNIMARC, Net::Z3950::APDU::MAB

No methods - just treat as an opaque chunk of data.

=cut

package Net::Z3950::APDU::SUTRS;
package Net::Z3950::APDU::USMARC;
package Net::Z3950::APDU::UKMARC;
package Net::Z3950::APDU::NORMARC;
package Net::Z3950::APDU::LIBRISMARC;
package Net::Z3950::APDU::DANMARC;
package Net::Z3950::APDU::UNIMARC;
package Net::Z3950::APDU::MAB;


=head2 Net::Z3950::APDU::TaggedElement;

	tagType()
	tagValue()
	tagOccurrence()
	content()

=cut

package Net::Z3950::APDU::TaggedElement;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(tagType tagValue tagOccurrence content);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::ElementData

	which()
	numeric()
	string()
	oid()
	subtree()

Only one of the last four methods will return anything - you can find
out which one by inspecting the return value of the C<which()> method,
which always takes one of the following values:

=over 4

=item *

Net::Z3950::ElementData::Numeric

=item *

Net::Z3950::ElementData::String

=item *

Net::Z3950::ElementData::OID

=item *

Net::Z3950::ElementData::Subtree

=item *

I<### others, not yet supported>

=back

=cut

package Net::Z3950::APDU::ElementData;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);

@FIELDS = qw(which numeric string oid subtree);
sub _fields { @FIELDS };

# Define the ElementData class's "which" enumeration, which indicates
# which of the possible branches contains data (i.e. it's the
# discriminator for a union.)  This must be kept synchronised with the
# values defined in the header file <yaz/z-grs.h> -- NOT <yaz/prt-grs.h>
package Net::Z3950::ElementData;
sub Numeric { 1 }
sub String  { 5 }
sub OID { 7 }
sub Subtree { 13 }
package Net::Z3950;


=head2 Net::Z3950::APDU::HoldingsData

No methods - just treat as a reference to an array of objects, where
each object is either an MARC holdings record (of type
C<Net::Z3950::Record::USMARC> or similar) or a
C<Net::Z3950::APDU::HoldingsAndCirc>

=cut

package Net::Z3950::APDU::HoldingsData;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::APDU);


=head2 Net::Z3950::APDU::HoldingsAndCirc

	typeOfRecord()
	encodingLevel()
	format()
	receiptAcqStatus()
	generalRetention()
	completeness()
	dateOfReport()
	nucCode()
	localLocation()
	shelvingLocation()
	callNumber()
	shelvingData()
	copyNumber()
	publicNote()
	reproductionNote()
	termsUseRepro()
	enumAndChron()
	volumes()
	circulationData()

All but the last two of these have string values, although not
necessarily human-readable strings.  C<volumes()> returns a
C<Net::Z3950::APDU::Volumes> object (note the plural in the
type-name), and C<circulationData()> a
C<Net::Z3950::APDU::CirculationData>.

=cut

package Net::Z3950::APDU::HoldingsAndCirc;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(typeOfRecord encodingLevel format receiptAcqStatus
	     generalRetention completeness dateOfReport nucCode
	     localLocation shelvingLocation callNumber shelvingData
	     copyNumber publicNote reproductionNote termsUseRepro
	     enumAndChron volumes circulationData);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::Volumes

No methods - just treat as a reference to an array of
C<Net::Z3950::APDU::Volume>
objects.

=cut

package Net::Z3950::APDU::Volumes;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::APDU);


=head2 Net::Z3950::APDU::HoldingsAndCirc

	enumeration()
	chronology()
	enumAndChron()

=cut

package Net::Z3950::APDU::Volume;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(enumeration chronology enumAndChron);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::CirculationData

No methods - just treat as a reference to an array of
C<Net::Z3950::APDU::CircRecord>
objects.

=cut

package Net::Z3950::APDU::CirculationData;
use vars qw(@ISA);
@ISA = qw(Net::Z3950::APDU);



=head2 Net::Z3950::APDU::HoldingsAndCirc

	availableNow()
	availablityDate()
	availableThru()
	restrictions()
	itemId()
	renewable()
	onHold()
	enumAndChron()
	midspine()
	temporaryLocation()

=cut

package Net::Z3950::APDU::CircRecord;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(availableNow availablityDate availableThru restrictions
	     itemId renewable onHold enumAndChron midspine
	     temporaryLocation);
sub _fields { @FIELDS };

=head2 Net::Z3950::APDU::DiagRecs

No methods - just treat as a reference to an array of object
references.  The objects will typically be of class
C<Net::Z3950::APDU::DefaultDiagFormat>, but careful callers will check
this, since any kind of EXTERNAL may be provided instead.

=cut

package Net::Z3950::APDU::DiagRecs;


=head2 Net::Z3950::APDU::DefaultDiagFormat;

	diagnosticSetId()
	condition()
	addinfo()

=cut

package Net::Z3950::APDU::DefaultDiagFormat;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(diagnosticSetId condition addinfo);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::OID

B<No longer exists.>
Previously this class had no methods - calling code just treated it
as a reference to an array of integers.  However, since the only thing
anyone (including C<Net::Z3950::Record::GRS1::render()>)
ever did with it was smush it up into a string with

	join('.', @$oidRef)

we now just return the dot-separated OID string
I<not blessed into any class>
(because scalars can't be blessed - only I<references> to scalars,
and we don't want the extra useless level of indirection).

=cut

package Net::Z3950::APDU::OID;


=head2 Net::Z3950::APDU::ListEntries

No methods - just treat as a reference to an array of
C<Net::Z3950::APDU::Entry>

=cut

package Net::Z3950::APDU::ListEntries;


=head2 Net::Z3950::APDU::Entry

	termInfo()
	surrogateDiagnostic()

Usually, C<termInfo()> returns a scanned term.  When it returns an
undefined value, consult <surrogateDiagnostic()> to find out why.

=cut

package Net::Z3950::APDU::Entry;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(termInfo surrogateDiagnostic);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::TermInfo

	term()
	globalOccurrences()

I<### Lots more to come here, including displayTerm>

=cut

package Net::Z3950::APDU::TermInfo;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(term globalOccurrences);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::Term

	general()
	numeric()
	characterString()
	oid()
	dateTime()
	external()
	integerAndUnit()
	null()

At present only ``general'' terms are supported.  The value of such a
term may be obtained by calling <general()>.  Terms of other types can
not be obtained.

=cut

package Net::Z3950::APDU::Term;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);
@FIELDS = qw(general numeric characterString oid
             dateTime external integerAndUnit null);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::OtherInformation

No methods - just treat as a reference to an array of
C<Net::Z3950::APDU::OtherInformationUnit>

=cut

package Net::Z3950::APDU::OtherInformation;

=head2 Net::Z3950::APDU::OtherInformationUnit

    which()
    characterInfo()
    binaryInfo()
    externallyDefinedInfo
    oid()

At present only ``externallyDefinedInfo'' units are supported.

=cut

package Net::Z3950::APDU::OtherInformationUnit;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);

@FIELDS = qw(which characterInfo binaryInfo externallyDefinedInfo oid);
sub _fields { @FIELDS };

# Define the OtherInformationUnit class's "which" enumeration, which
# indicates which of the possible branches contains data (i.e. it's
# the discriminator for a union.)
package Net::Z3950::OtherInformationUnit;
sub CharacterInfo { 1 }
sub BinaryInfo  { 2 }
sub ExternallyDefinedInfo { 3 }
sub Oid { 4 }
package Net::Z3950;


=head2 Net::Z3950::APDU::SearchInfoReport

No methods - just treat as a reference to an array of
C<Net::Z3950::APDU::SearchInfoReport_s>

=cut

package Net::Z3950::APDU::SearchInfoReport;


=head2 Net::Z3950::APDU::SearchInfoReport_s

    fullQuery()
    subqueryExpression()
    subqueryCount()

=cut

package Net::Z3950::APDU::SearchInfoReport_s;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);

@FIELDS = qw(fullQuery subqueryExpression subqueryCount);
sub _fields { @FIELDS };


=head2 Net::Z3950::APDU::QueryExpression

    which()
    term()
    query()

At present only ``term'' query expressions are supported.

=cut

package Net::Z3950::APDU::QueryExpression;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);

@FIELDS = qw(which term query);
sub _fields { @FIELDS };

# Define the QueryExpression class's "which" enumeration, which
# indicates which of the possible branches contains data (i.e. it's
# the discriminator for a union.)
package Net::Z3950::QueryExpression;
sub Term { 1 }
sub Query { 2 }
package Net::Z3950;


=head2 Net::Z3950::APDU::QueryExpressionTerm

    queryTerm()

=cut

package Net::Z3950::APDU::QueryExpressionTerm;
use vars qw(@ISA @FIELDS);
@ISA = qw(Net::Z3950::APDU);

@FIELDS = qw(queryTerm);
sub _fields { @FIELDS };


=head1 AUTHOR

Mike Taylor E<lt>mike@indexdata.comE<gt>

First version Saturday 27th May 2000.

=cut


1;
