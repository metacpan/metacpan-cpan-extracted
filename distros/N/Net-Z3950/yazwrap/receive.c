/* $Header: /home/cvsroot/NetZ3950/yazwrap/receive.c,v 1.20 2006/05/08 10:54:22 mike Exp $ */

/*
 * yazwrap/receive.c -- wrapper functions for Yaz's client API.
 *
 * This file provides a single function, decodeAPDU(), which pulls an
 * APDU off the network, decodes it (using YAZ) and converts it from
 * Yaz's C structures into broadly equivalent Perl functions.
 */

#include <assert.h>
#include <yaz/proto.h>
#include <yaz/oid.h>
#include "ywpriv.h"


static SV *translateAPDU(Z_APDU *apdu, int *reasonp);
static SV *translateInitResponse(Z_InitResponse *res, int *reasonp);
static SV *translateSearchResponse(Z_SearchResponse *res, int *reasonp);
static SV *translateScanResponse(Z_ScanResponse *res, int *reasonp);
static SV *translatePresentResponse(Z_PresentResponse *res, int *reasonp);
static SV *translateDeleteRSResponse(Z_DeleteResultSetResponse *res,
				     int *reasonp);
static SV *translateClose(Z_Close *res, int *reasonp);
static SV *translateRecords(Z_Records *x);
static SV *translateNamePlusRecordList(Z_NamePlusRecordList *x);
static SV *translateNamePlusRecord(Z_NamePlusRecord *x);
static SV *translateListEntries(Z_ListEntries *x, int *isErrorp);
static SV *translateEntry(Z_Entry *x);
static SV *translateTermInfo(Z_TermInfo *x);
static SV *translateTerm(Z_Term *x);
static SV *translateExternal(Z_External *x);
static SV *translateSUTRS(Z_SUTRS *x);
static SV *translateGenericRecord(Z_GenericRecord *x);
static SV *translateTaggedElement(Z_TaggedElement *x);
static SV *translateStringOrNumeric(Z_StringOrNumeric *x);
static SV *translateElementData(Z_ElementData *x);
static SV *translateOPACRecord(Z_OPACRecord *x);
static SV *translateHoldingsRecord(Z_HoldingsRecord *x);
static SV *translateHoldingsAndCirc(Z_HoldingsAndCircData *x);
static SV *translateVolume(Z_Volume *x);
static SV *translateCircRecord(Z_CircRecord *x);
static SV *translateOctetAligned(Odr_oct *x, Odr_oid *direct_reference);
static SV *translateFragmentSyntax(Z_FragmentSyntax *x);
static SV *translateDiagRecs(Z_DiagRecs *x);
static SV *translateDiagRec(Z_DiagRec *x);
static SV *translateDefaultDiagFormat(Z_DefaultDiagFormat *x);
static SV *translateOID(Odr_oid *x);
static SV *translateOtherInformation(Z_OtherInformation *x);
static SV *translateOtherInformationUnit(Z_OtherInformationUnit *x);
static SV *translateSearchInfoReport(Z_SearchInfoReport *x);
static SV *translateSearchInfoReport_s(Z_SearchInfoReport_s *x);
static SV *translateQueryExpression(Z_QueryExpression *x);
static SV *translateQueryExpressionTerm(Z_QueryExpressionTerm *x);
static SV *newObject(char *class, SV *referent);
static void setNumber(HV *hv, char *name, IV val);
static void setString(HV *hv, char *name, char *val);
static void setBuffer(HV *hv, char *name, char *valdata, int vallen);
static void setMember(HV *hv, char *name, SV *val);


/*
 * This interface hides from the caller the possibility that the
 * socket has become ready not because there's data to be read, but
 * because the connect() has finished.  In this case, we just return a
 * null pointer with *reasonp==REASON_INCOMPLETE, which the caller
 * will treat in the right way (try again later.)
 *
 *  ###	The "perlguts" manual strongly implies that returning a null
 *	pointer here and elsewhere is not good enough, and I need
 *	instead to return PL_sv_undef.  In fact, null seems to work
 *	just fine.
 */
SV *decodeAPDU(COMSTACK cs, int *reasonp)
{
    static char *buf = 0;	/* apparently, static is OK */
    static int size = 0;	/* apparently, static is OK */
    int nbytes;
    static ODR odr = 0;
    Z_APDU *apdu;

    switch (cs_look(cs)) {
    case CS_CONNECT:
	/* In fact, this never happens and I don't understand how the
	 * connection is successfully forged.  We also don't get here 
	 * if the connection _isn't_ forged: instead, the socket
	 * select()s as ready to write, and writing down it fails with
	 * ECONNREFUSED or whatever the error is. */
	if (cs_rcvconnect(cs) < 0) {
	    *reasonp = REASON_ERROR;
	} else {
	    *reasonp = REASON_INCOMPLETE;
	}
	return 0;
    case CS_DATA:
	break;
    default:
	fatal("surprising cs_look() result");
    }

    nbytes = cs_get(cs, &buf, &size);
    switch (nbytes) {
    case -1:
	*reasonp = cs_errno(cs);
	return 0;
    case 0:
	*reasonp = REASON_EOF;
	return 0;
    case 1:
	*reasonp = REASON_INCOMPLETE;
	return 0;
    default:
	/* We got enough bytes for a whole PDU */
	break;
    }

    if (odr)
	odr_reset(odr);
    else {
	if ((odr = odr_createmem(ODR_DECODE)) == 0) {
	    /* Perusal of the Yaz source shows that this is impossible:
	     * odr_createmem() only fails if the initial xmalloc() fails,
	     * but xmalloc() is #defined to xmalloc_f(), which goes fatal
	     * if the underlying xmalloc_d() call fails.
	     */
	    fatal("impossible odr_createmem() failure");
	}
    }

    odr_setbuf(odr, buf, nbytes, 0);
    if (!z_APDU(odr, &apdu, 0, 0)) {
	/* Oops.  Malformed APDU (can't be short, otherwise, we'd not
	 * have got a >1 response from cs_get()).  There's nothing we
	 * can do about it.
	 */
	*reasonp = REASON_MALFORMED;
	return 0;
    }

    /* ### we should find a way to request another call if cs_more() */
    return translateAPDU(apdu, reasonp);
}


/*
 * This has to return a Perl data-structure representing the decoded
 * APDU.  What's the best way to do this?  We have several options:
 *
 *  1.	We can hack a new backend onto Yaz's existing ASN.1 compiler
 *	(written in Tcl!) so that it mechanically generates the
 *	functions necessary to convert Yaz's C data structures into
 *	Perl.
 *
 *  2.	We can do it by hand, which will be more work but will yield a
 *	better final product.  This also has the benefit of a lower
 *	startup cost (I don't have to grok the Tcl code) and a simpler
 *	distribution.
 *
 *  3.	We can do (or have the ASN.1 compiler do) a mechanical job,
 *	translating into low-level Perl data structures like arrays
 *	and hashes, and have the Perl layer above this translate the
 *	"raw" structures into something more palatable.
 *
 * For now, I guess we'll go with option 2, just so we can demonstrate
 * a successful Init negotiation.  In the longer term, we'll probably
 * need to run with 1 or 3, because there's a LOT of dull code to
 * write!
 *
 *  ###	Do I need to check for the Perl "guts" functions returning
 *	null values?  The manual doesn't seem to be clear on this.
 */
static SV *translateAPDU(Z_APDU *apdu, int *reasonp)
{
    switch (apdu->which) {
    case Z_APDU_initResponse:
	return translateInitResponse(apdu->u.initResponse, reasonp);
    case Z_APDU_searchResponse:
	return translateSearchResponse(apdu->u.searchResponse, reasonp);
    case Z_APDU_scanResponse:
	return translateScanResponse(apdu->u.scanResponse, reasonp);
    case Z_APDU_presentResponse:
	return translatePresentResponse(apdu->u.presentResponse, reasonp);
    case Z_APDU_deleteResultSetResponse:
	return translateDeleteRSResponse(apdu->u.deleteResultSetResponse,
					 reasonp);
    case Z_APDU_close:
	return translateClose(apdu->u.close, reasonp);
    default:
	break;
    }

    *reasonp = REASON_BADAPDU;
    return 0;
}


static SV *translateInitResponse(Z_InitResponse *res, int *reasonp)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::InitResponse", (SV*) (hv = newHV()));

    if (res->referenceId) {
	setBuffer(hv, "referenceId",
		  (char*) res->referenceId->buf, res->referenceId->len);
    }
    /* protocolVersion not translated (complex data type) */
    /* options not translated (complex data type) */
    setNumber(hv, "preferredMessageSize", (IV) *res->preferredMessageSize);
    setNumber(hv, "maximumRecordSize", (IV) *res->maximumRecordSize);
    setNumber(hv, "result", (IV) *res->result);
    if (res->implementationId)
	setString(hv, "implementationId", res->implementationId);
    if (res->implementationName)
	setString(hv, "implementationName", res->implementationName);
    if (res->implementationVersion)
	setString(hv, "implementationVersion", res->implementationVersion);
    /* userInformationField (OPT) not translated (complex data type) */
    /* otherInfo (OPT) not translated (complex data type) */

    return sv;
}


static SV *translateSearchResponse(Z_SearchResponse *res, int *reasonp)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::SearchResponse", (SV*) (hv = newHV()));
    if (res->referenceId)
	setBuffer(hv, "referenceId",
		  (char*) res->referenceId->buf, res->referenceId->len);

    setNumber(hv, "resultCount", (IV) *res->resultCount);
    setNumber(hv, "numberOfRecordsReturned",
	      (IV) *res->numberOfRecordsReturned);
    setNumber(hv, "nextResultSetPosition", (IV) *res->nextResultSetPosition);
    setNumber(hv, "searchStatus", (IV) *res->searchStatus);
    if (res->resultSetStatus)
	setNumber(hv, "resultSetStatus", (IV) *res->resultSetStatus);
    if (res->presentStatus)
	setNumber(hv, "presentStatus", (IV) *res->presentStatus);
    if (res->records)
	setMember(hv, "records", translateRecords(res->records));
    if (res->additionalSearchInfo)
    setMember(hv, "additionalSearchInfo", translateOtherInformation(res->additionalSearchInfo));

    /* otherInfo (OPT) not translated (complex data type) */

    return sv;
}

static SV *translateScanResponse(Z_ScanResponse *res, int *reasonp) {
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::ScanResponse", (SV*) (hv = newHV()));
    if (res->referenceId) {
	setBuffer(hv, "referenceId", (char*) res->referenceId->buf,
	res->referenceId->len);
    }

    if (res->stepSize)
	setNumber(hv, "stepSize", (IV) *res->stepSize);
    setNumber(hv, "scanStatus", (IV) *res->scanStatus);
    setNumber(hv, "numberOfEntriesReturned",
	      (IV) *res->numberOfEntriesReturned);
    if (res->positionOfTerm)
	setNumber(hv, "positionOfTerm", (IV) *res->positionOfTerm);
    if (res->entries) {
	int isError = 0;
	SV *tmp = translateListEntries(res->entries, &isError);
	setMember(hv, isError ? "diag" : "entries", tmp);
    }

    /* attributeSet (OPT) not translated (complex data type) */
    /* otherInfo (OPT) not translated (complex data type) */

    return sv;
}

static SV *translateDeleteRSResponse(Z_DeleteResultSetResponse *res,
				     int *reasonp)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::DeleteRSResponse", (SV*) (hv = newHV()));

    if (res->referenceId) {
	setBuffer(hv, "referenceId",
		  (char*) res->referenceId->buf, res->referenceId->len);
    }

    setNumber(hv, "deleteOperationStatus", (IV) *res->deleteOperationStatus);

    /* ### We needn't bother with _any_ of this, really */
    /* Z_ListStatuses *deleteListStatuses; (OPT) */
    /* int *numberNotDeleted; (OPT) */
    /* Z_ListStatuses *bulkStatuses; (OPT) */
    /* Z_InternationalString *deleteMessage; (OPT) */
    /* Z_OtherInformation *otherInfo; (OPT) */

    return sv;
}

static SV *translateClose(Z_Close *res, int *reasonp)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::Close", (SV*) (hv = newHV()));

    if (res->referenceId)
	setBuffer(hv, "referenceId",
		  (char*) res->referenceId->buf, res->referenceId->len);

    setNumber(hv, "closeReason", (IV) *res->closeReason);

    if (res->diagnosticInformation)
	setString(hv, "diagnosticInformation", (char*) res->referenceId);

    /* resourceReportFormat (OPT) not translated */
    /* resourceReport       (OPT) not translated */
    /* otherInfo	    (OPT) not translated */
    return sv;
}


static SV *translatePresentResponse(Z_PresentResponse *res, int *reasonp)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::PresentResponse", (SV*) (hv = newHV()));

    if (res->referenceId)
	setBuffer(hv, "referenceId",
		  (char*) res->referenceId->buf, res->referenceId->len);
    setNumber(hv, "numberOfRecordsReturned",
	      (IV) *res->numberOfRecordsReturned);
    setNumber(hv, "nextResultSetPosition", (IV) *res->nextResultSetPosition);
    setNumber(hv, "presentStatus", (IV) *res->presentStatus);
    if (res->records)
	setMember(hv, "records", translateRecords(res->records));

    /* otherInfo (OPT) not translated (complex data type) */

    return sv;
}


static SV *translateRecords(Z_Records *x)
{
    switch (x->which) {
    case Z_Records_DBOSD:
	return translateNamePlusRecordList(x->u.databaseOrSurDiagnostics);
    case Z_Records_NSD:
	return translateDefaultDiagFormat(x->u.nonSurrogateDiagnostic);
    case Z_Records_multipleNSD:
	return translateDiagRecs(x->u.multipleNonSurDiagnostics);
    default:
	break;
    }
    fatal("illegal `which' in Z_Records");
    return 0;			/* NOTREACHED; inhibit gcc -Wall warning */
}


static SV *translateNamePlusRecordList(Z_NamePlusRecordList *x)
{
    /* Represented as a reference to a blessed array of elements */
    SV *sv;
    AV *av;
    int i;

    sv = newObject("Net::Z3950::APDU::NamePlusRecordList", (SV*) (av = newAV()));
    for (i = 0; i < x->num_records; i++)
	av_push(av, translateNamePlusRecord(x->records[i]));

    return sv;
}


static SV *translateNamePlusRecord(Z_NamePlusRecord *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::NamePlusRecord", (SV*) (hv = newHV()));
    if (x->databaseName)
	setString(hv, "databaseName", x->databaseName);
    setNumber(hv, "which", x->which);

    switch (x->which) {
    case Z_NamePlusRecord_databaseRecord:
	setMember(hv, "databaseRecord",
		  translateExternal(x->u.databaseRecord));
	break;
    case Z_NamePlusRecord_surrogateDiagnostic:
	setMember(hv, "surrogateDiagnostic",
		  translateDiagRec(x->u.surrogateDiagnostic));
	break;
    case Z_NamePlusRecord_startingFragment:
	setMember(hv, "startingFragment",
		  translateFragmentSyntax(x->u.startingFragment));
	break;
    case Z_NamePlusRecord_intermediateFragment:
	setMember(hv, "intermediateFragment",
		  translateFragmentSyntax(x->u.intermediateFragment));
	break;
    case Z_NamePlusRecord_finalFragment:
	setMember(hv, "finalFragment",
		  translateFragmentSyntax(x->u.finalFragment));
	break;
    default:
	fatal("illegal `which' in Z_NamePlusRecord");
    }

    return sv;
}


static SV *translateListEntries(Z_ListEntries *x, int *isErrorp) {
    /*
     * This might return either a ListEntries object or a
     * DefaultDiagFormat object, depending on which of x->entries and
     * x->nonsurrogateDiagnostics is set.  The ASN.1 says that both of
     * these are optional but at least one must be included; but the
     * Z39.50-1995 prose says that entries must _always_ be provided
     * (presumably including when there are zero of them) and the
     * diagnostics are optional.  So we take the pragmatic approach
     * that if there are diagnostics we return them, otherwise the
     * entries.  We further simplify by returning only the first
     * diagnostic if there are several.
     *
     *	### This fails badly with the following scan:
     *		ruslan.ru:210/spstu
     *		@attr 1=21 fruit
     *	The response contains a set of entries _and_ multiple NSDs.
     *	This is because ruslan is a union catalogue of several
     *	database, some of which support scan on subject and some of
     *	which don't.  The former supply terms, and the latter each
     *	supply a diagnostic.  We need to change the structure we
     *	return.
     *
     * The entries object is represented as a reference to a blessed
     * array of elements
     */
    SV *sv;
    AV *av;
    int i;

    if (x->nonsurrogateDiagnostics) {
	/* If there's more than one diagnostic, we just use the first */
	*isErrorp = 1;
	return translateDiagRec(x->nonsurrogateDiagnostics[0]);
    }

    /* No diagnostics, so return the actual entries */
    sv = newObject("Net::Z3950::APDU::ListEntries", (SV*) (av = newAV()));
    for (i=0; i < x->num_entries; i++) {
	av_push(av, translateEntry(x->entries[i]));
    }

    return sv;
}


static SV *translateEntry(Z_Entry *x) {
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::Entry", (SV*) (hv = newHV()));
    switch (x->which) {
    case Z_Entry_termInfo:
	setMember(hv, "termInfo", translateTermInfo(x->u.termInfo));
	break;
    case Z_Entry_surrogateDiagnostic:
	setMember(hv, "surrogateDiagnostic",
	    translateDiagRec(x->u.surrogateDiagnostic));
	break;
    default:
	fatal("illegal `which' in Z_Entry");
    }

    return sv;
}


static SV *translateTermInfo(Z_TermInfo *x) {
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::TermInfo", (SV*) (hv = newHV()));
    setMember(hv, "term", translateTerm(x->term));

    if (x->globalOccurrences)
	setNumber(hv, "globalOccurrences", (IV) *x->globalOccurrences);

    /* ### Lots of elements not translated here:
     * displayTerm     [0] IMPLICIT InternationalString
     * suggestedAttributes AttributeList OPTIONAL,
     * alternativeTerm [4] IMPLICIT SEQUENCE OF AttributesPlusTerm OPTIONAL,
     * byAttributes    [3] IMPLICIT OccurrenceByAttributes OPTIONAL,
     * otherTermInfo       OtherInformation OPTIONAL}
     */

    return sv;
}


static SV *translateTerm(Z_Term *x) {
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::Term", (SV*) (hv = newHV()));

    switch (x->which) {
    case Z_Term_general:
	setBuffer(hv, "general", (char*) x->u.general->buf, x->u.general->len);
	break;
    case Z_Term_numeric:
	/* ### this won't do at all */
	break;
    case Z_Term_characterString:
	break;
    case Z_Term_oid:
	break;
    case Z_Term_dateTime:
	break;
    case Z_Term_external:
	break;
    case Z_Term_integerAndUnit:
	break;
    case Z_Term_null:
	break;
    default:
	fatal("illegal `which' in Z_Term");
    }

    return sv;
}


/*
 * Section 3.4 (EXTERNAL Data) of chapter 3 (The ASN Module) of the
 * Yaz Manual has this to say:
 *	For ASN.1 structured data, you need only consult the which
 *	field to determine the type of data.  You can the access the
 *	data directly through the union.
 * In other words, the Z_External structure's direct_reference,
 * indirect_reference and descriptor fields are only there to help the
 * data get across the network; and once it's done that (and arrived
 * here), we can simply use the `which' discriminator to choose a
 * branch of the union to encode.
 *
 *  ###	Exception: if I understand this correctly, then we need to
 *	have translateOctetAligned() consult x->direct_reference so it
 *	knows which specific *MARC class to bless the data into.
 */
static SV *translateExternal(Z_External *x)
{
    switch (x->which) {
    case Z_External_sutrs:
	return translateSUTRS(x->u.sutrs);
    case Z_External_grs1:
	return translateGenericRecord(x->u.grs1);
    case Z_External_OPAC:
	return translateOPACRecord(x->u.opac);
    case Z_External_octet:
	/* This is used for any opaque data-block (i.e. just a hunk of
	 * octets) -- in particular, for records in any of the *MARC
	 * syntaxes and for XML and HTML records.
	 */
	return translateOctetAligned(x->u.octet_aligned, x->direct_reference);
    case Z_External_searchResult1:
	return translateSearchInfoReport(x->u.searchResult1);
    default:
	break;
    }
    fatal("illegal/unsupported `which' (%d) in Z_External", x->which);
    return 0;			/* NOTREACHED; inhibit gcc -Wall warning */
}


static SV *translateSUTRS(Z_SUTRS *x)
{
    /* Represent as a blessed scalar -- unusual but clearly appropriate.
     * The usual scheme of things in this source file is to make objects of
     * class Net::Z3950::APDU::*, but in this case and some other below, we go
     * straight to the higher-level representation of a Net::Z3950::Record::*
     * object, knowing that this is a subclass of its Net::Z3950::APDU::*
     * analogue, but with additional, record-syntax-specific,
     * functionality.
     */
    return newObject("Net::Z3950::Record::SUTRS",
		     newSVpvn((char*) x->buf, x->len));
}


static SV *translateGenericRecord(Z_GenericRecord *x)
{
    /* Represented as a reference to a blessed array of elements */
    SV *sv;
    AV *av;
    int i;

    /* See comment on class-name in translateSUTRS() above.  We use
     * ...::GRS1 rather than ...::GenericRecord because that's what the
     * application-level calling code will expect.
     */
    sv = newObject("Net::Z3950::Record::GRS1", (SV*) (av = newAV()));
    for (i = 0; i < x->num_elements; i++)
	av_push(av, translateTaggedElement(x->elements[i]));

    return sv;
}


static SV *translateTaggedElement(Z_TaggedElement *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::TaggedElement", (SV*) (hv = newHV()));
    if (x->tagType)
	setNumber(hv, "tagType", *x->tagType);
    setMember(hv, "tagValue", translateStringOrNumeric(x->tagValue));
    if (x->tagOccurrence)
	setNumber(hv, "tagOccurrence", *x->tagOccurrence);
    setMember(hv, "content", translateElementData(x->content));
    /* Z_ElementMetaData *metaData; // OPT */
    /* Z_Variant *appliedVariant; // OPT */

    return sv;
}


static SV *translateStringOrNumeric(Z_StringOrNumeric *x)
{
    switch (x->which) {
    case Z_StringOrNumeric_string:
	return newSVpv(x->u.string, 0);
    case Z_StringOrNumeric_numeric:
	return newSViv(*x->u.numeric);
    default:
	break;
    }
    fatal("illegal `which' in Z_ElementData");
    return 0;			/* NOTREACHED; inhibit gcc -Wall warning */
}


/*
 * It's tempting to treat this data by simply returning an appropriate
 * Perl data structure, not bothering with an explicit discriminator --
 * as translateStringOrNumeric() does for its data -- but that would
 * mean (for example) that we couldn't tell the difference between
 * elementNotThere, elementEmpty and noDataRequested.  This would
 * be A Bad Thing, since it's not this code's job to fix bugs in the
 * standard :-)  Instead, we return an object with an explicit `which'
 * element, as translateNamePlusRecord() does.
 */
static SV *translateElementData(Z_ElementData *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::ElementData", (SV*) (hv = newHV()));
    setNumber(hv, "which", x->which);

    switch (x->which) {
    case Z_ElementData_numeric:
	setMember(hv, "numeric", newSViv(*x->u.numeric));
	break;
    case Z_ElementData_string:
	setMember(hv, "string", newSVpv(x->u.string, 0));
	break;
    case Z_ElementData_oid:
	setMember(hv, "oid", translateOID(x->u.oid));
	break;
    case Z_ElementData_subtree:
	setMember(hv, "subtree", translateGenericRecord(x->u.subtree));
	break;
    default:
	fatal("illegal/unsupported `which' (%d) in Z_ElementData", x->which);
    }

    return sv;
}


static SV *translateOPACRecord(Z_OPACRecord *x)
{
    SV *sv, *sv2;
    HV *hv;
    AV *av;
    int i;

    sv = newObject("Net::Z3950::Record::OPAC", (SV*) (hv = newHV()));
    setMember(hv, "bibliographicRecord",
	      translateExternal(x->bibliographicRecord));
    setNumber(hv, "num_holdingsData", x->num_holdingsData);

    sv2 = newObject("Net::Z3950::APDU::HoldingsData", (SV*) (av = newAV()));
    for (i = 0; i < x->num_holdingsData; i++)
	av_push(av, translateHoldingsRecord(x->holdingsData[i]));
    setMember(hv, "holdingsData", sv2);

    return sv;
}


static SV *translateHoldingsRecord(Z_HoldingsRecord *x)
{
    switch (x->which) {
    case Z_HoldingsRecord_marcHoldingsRecord:
	return translateExternal(x->u.marcHoldingsRecord);
    case Z_HoldingsRecord_holdingsAndCirc:
	return translateHoldingsAndCirc(x->u.holdingsAndCirc);
    default:
	break;
    }
    fatal("illegal `which' in Z_HoldingsRecord");
    return 0;			/* NOTREACHED; inhibit gcc -Wall warning */
}


static SV *translateHoldingsAndCirc(Z_HoldingsAndCircData *x)
{
    SV *sv, *sv2;
    HV *hv;
    AV *av;
    int i;

    sv = newObject("Net::Z3950::APDU::HoldingsAndCirc", (SV*) (hv = newHV()));
    if (x->typeOfRecord)
	setString(hv, "typeOfRecord", x->typeOfRecord);
    if (x->encodingLevel)
	setString(hv, "encodingLevel", x->encodingLevel);
    if (x->format)
	setString(hv, "format", x->format);
    if (x->receiptAcqStatus)
	setString(hv, "receiptAcqStatus", x->receiptAcqStatus);
    if (x->generalRetention)
	setString(hv, "generalRetention", x->generalRetention);
    if (x->completeness)
	setString(hv, "completeness", x->completeness);
    if (x->dateOfReport)
	setString(hv, "dateOfReport", x->dateOfReport);
    if (x->nucCode)
	setString(hv, "nucCode", x->nucCode);
    if (x->localLocation)
	setString(hv, "localLocation", x->localLocation);
    if (x->shelvingLocation)
	setString(hv, "shelvingLocation", x->shelvingLocation);
    if (x->callNumber)
	setString(hv, "callNumber", x->callNumber);
    if (x->shelvingData)
	setString(hv, "shelvingData", x->shelvingData);
    if (x->copyNumber)
	setString(hv, "copyNumber", x->copyNumber);
    if (x->publicNote)
	setString(hv, "publicNote", x->publicNote);
    if (x->reproductionNote)
	setString(hv, "reproductionNote", x->reproductionNote);
    if (x->termsUseRepro)
	setString(hv, "termsUseRepro", x->termsUseRepro);
    if (x->enumAndChron)
	setString(hv, "enumAndChron", x->enumAndChron);

    sv2 = newObject("Net::Z3950::APDU::Volumes", (SV*) (av = newAV()));
    for (i = 0; i < x->num_volumes; i++)
	av_push(av, translateVolume(x->volumes[i]));
    setMember(hv, "volumes", sv2);

    sv2 = newObject("Net::Z3950::APDU::CirculationData", (SV*) (av = newAV()));
    for (i = 0; i < x->num_circulationData; i++)
	av_push(av, translateCircRecord(x->circulationData[i]));
    setMember(hv, "circulationData", sv2);

    return sv;
}


static SV *translateVolume(Z_Volume *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::Volume", (SV*) (hv = newHV()));
    if (x->enumeration)
	setString(hv, "enumeration", x->enumeration);
    if (x->chronology)
	setString(hv, "chronology", x->chronology);
    if (x->enumAndChron)
	setString(hv, "enumAndChron", x->enumAndChron);

    return sv;
}


static SV *translateCircRecord(Z_CircRecord *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::CircRecord", (SV*) (hv = newHV()));
    setNumber(hv, "availableNow", *x->availableNow);
    /* Note the typo in the next line.  It goes right back to the
       ASN.1 in the printed Z39.50-1995 standard, so the honest thing
       here seems to be to propagate it into the Perl interface. */
    if (x->availablityDate)
	setString(hv, "availablityDate", x->availablityDate);
    if (x->availableThru)
	setString(hv, "availableThru", x->availableThru);
    if (x->restrictions)
	setString(hv, "restrictions", x->restrictions);
    if (x->itemId)
	setString(hv, "itemId", x->itemId);
    setNumber(hv, "renewable", *x->renewable);
    setNumber(hv, "onHold", *x->onHold);
    if (x->enumAndChron)
	setString(hv, "enumAndChron", x->enumAndChron);
    if (x->midspine)
	setString(hv, "midspine", x->midspine);
    if (x->temporaryLocation)
	setString(hv, "temporaryLocation", x->temporaryLocation);

    return sv;
}


/*
 * We use a blessed scalar string to represent the (non-ASN.1-encoded)
 * record; the only difficult part is knowing what class to bless it into.
 * We do that by looking up its record syntax in a hardwired table that
 * maps it to a class-name string.
 *
 * We assume that the record, not processed here, will subsequently be
 * picked apart by some pre-existing module, most likely the
 * MARC::Record module for *MARC records; I'd be interested to know
 * what people use for XML and HTML records.
 */
static SV *translateOctetAligned(Odr_oct *x, Odr_oid *direct_reference)
{
    struct {
	oid_value val;
	char *name;
    } rs[] = {
	{ VAL_USMARC,		"Net::Z3950::Record::USMARC" },
	{ VAL_UKMARC,		"Net::Z3950::Record::UKMARC" },
	{ VAL_NORMARC,		"Net::Z3950::Record::NORMARC" },
	{ VAL_LIBRISMARC,	"Net::Z3950::Record::LIBRISMARC" },
	{ VAL_DANMARC,		"Net::Z3950::Record::DANMARC" },
	{ VAL_UNIMARC,		"Net::Z3950::Record::UNIMARC" },
	{ VAL_UNIMARC,		"Net::Z3950::Record::UNIMARC" },
	{ VAL_HTML,		"Net::Z3950::Record::HTML" },
	{ VAL_TEXT_XML,		"Net::Z3950::Record::XML" },
	{ VAL_APPLICATION_XML,	"Net::Z3950::Record::XML" },
	{ VAL_MAB,              "Net::Z3950::Record::MAB" },
	{ VAL_NOP }		/* end marker */
	/* ### etc. */
    };

    int i;
    for (i = 0; rs[i].val != VAL_NOP; i++) {
	static struct oident ent = { PROTO_Z3950, CLASS_RECSYN };
	int *oid;
	ent.value = rs[i].val;
	oid = oid_getoidbyent(&ent);
	if (!oid_oidcmp(oid, direct_reference))
	    break;
    }

    if (rs[i].val == VAL_NOP)
	fatal("can't translate record of unknown RS");

    return newObject(rs[i].name, newSVpvn((char*) x->buf, x->len));
}


static SV *translateFragmentSyntax(Z_FragmentSyntax *x)
{
    return 0;			/* ### not yet implemented */
}


static SV *translateDiagRecs(Z_DiagRecs *x)
{
    /* Represented as a reference to a blessed array of elements */
    SV *sv;
    AV *av;
    int i;

    sv = newObject("Net::Z3950::APDU::DiagRecs", (SV*) (av = newAV()));
    for (i = 0; i < x->num_diagRecs; i++)
	av_push(av, translateDiagRec(x->diagRecs[i]));

    return sv;
}


static SV *translateDiagRec(Z_DiagRec *x)
{
    switch (x->which) {
    case Z_DiagRec_defaultFormat:
	return translateDefaultDiagFormat(x->u.defaultFormat);
    case Z_DiagRec_externallyDefined:
	return translateExternal(x->u.externallyDefined);
    default:
	break;
    }
    fatal("illegal `which' in Z_DiagRec");
    return 0;			/* NOTREACHED; inhibit gcc -Wall warning */
}


static SV *translateDefaultDiagFormat(Z_DefaultDiagFormat *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::DefaultDiagFormat", (SV*) (hv = newHV()));
    setMember(hv, "diagnosticSetId", translateOID(x->diagnosticSetId));
    setNumber(hv, "condition", *x->condition);
    /* ### we don't care what value of `which' pertains -- in either
     * case, what we have is frankly a char*, so we let type punning
     * take care of it.
     */
    setString(hv, "addinfo", x->u.v2Addinfo);
    return sv;
}


static SV *translateOID(Odr_oid *x)
{
    /* Yaz represents an OID by an int array terminated by a negative
     * value, typically -1; we represent it as a reference to a
     * blessed scalar string of "."-separated elements.
     */
    char buf[1000];
    int i;

    *buf = '\0';
    for (i = 0; x[i] >= 0; i++) {
	sprintf(buf + strlen(buf), "%d", (int) x[i]);
	if (x[i+1] >= 0)
	    strcat(buf, ".");
    }

    /*
     * ### We'd like to return a blessed scalar (string) here, but of
     *	course you can't do that in Perl: only references can be
     *	blessed, so we'd have to return a _reference_ to a string, and
     *	bless _that_.  Better to do without the blessing, I think.
     */
    if (1) {
	return newSVpv(buf, 0);
    } else {
	return newObject("Net::Z3950::APDU::OID", newSVpv(buf, 0));
    }
}


static SV *translateOtherInformation(Z_OtherInformation *x)
{
    SV *sv;
    AV *av;
    int i;

    sv = newObject("Net::Z3950::APDU::OtherInformation", (SV*) (av = newAV()));
    for (i=0; i < x->num_elements; i++) {
        av_push(av, translateOtherInformationUnit(x->list[i]));
    }

    return sv;
}


static SV *translateOtherInformationUnit(Z_OtherInformationUnit *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::OtherInformationUnit",
		   (SV*) (hv = newHV()));

    /* ### category not translated */
    setNumber(hv, "which", x->which);
    switch (x->which) {
    case Z_OtherInfo_characterInfo:
	break;
    case Z_OtherInfo_binaryInfo:
	break;
    case Z_OtherInfo_externallyDefinedInfo:
	setMember(hv, "externallyDefinedInfo",
		  translateExternal(x->information.externallyDefinedInfo));
	return sv;
    case Z_OtherInfo_oid:
	break;
    default:
	break;
    }

    fatal("illegal/unsupported `which' (%d) in Z_OtherInformationUnit",
	  x->which);
    return 0;			/* NOTREACHED; inhibit gcc -Wall warning */    
}


static SV *translateSearchInfoReport(Z_SearchInfoReport *x)
{
    SV *sv;
    AV *av;
    int i;

    sv = newObject("Net::Z3950::APDU::SearchInfoReport", (SV*) (av = newAV()));
    for (i=0; i < x->num; i++) {
        av_push(av, translateSearchInfoReport_s(x->elements[i]));
    }

    return sv;
}


static SV *translateSearchInfoReport_s(Z_SearchInfoReport_s *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::SearchInfoReport_s",
		   (SV*) (hv = newHV()));
    setNumber(hv, "fullQuery", (IV) *x->fullQuery);
    if (x->subqueryExpression)
        setMember(hv, "subqueryExpression",
		  translateQueryExpression(x->subqueryExpression));
    if (x->subqueryCount)
        setNumber(hv, "subqueryCount", (IV) *x->subqueryCount);
    /* ### many, many elements omitted here */

    return sv;
}


static SV *translateQueryExpression(Z_QueryExpression *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::QueryExpression", (SV*) (hv = newHV()));
    setNumber(hv, "which", x->which);

    switch (x->which) {
    case Z_QueryExpression_term:
	setMember(hv, "term", translateQueryExpressionTerm(x->u.term));
	return sv;
    case Z_QueryExpression_query:
	break;
    default:
	break;
    }

    fatal("illegal/unsupported `which' (%d) in Z_QueryExpression", x->which);
    return 0;			/* NOTREACHED; inhibit gcc -Wall warning */    
}


static SV *translateQueryExpressionTerm(Z_QueryExpressionTerm *x)
{
    SV *sv;
    HV *hv;

    sv = newObject("Net::Z3950::APDU::QueryExpressionTerm",
		   (SV*) (hv = newHV()));
    setMember(hv, "queryTerm", translateTerm(x->queryTerm));

    return sv;
}


/*
 * Creates a new Perl object of type `class'; the newly-created scalar
 * that is a reference to the blessed thingy `referent' is returned.
 */
static SV *newObject(char *class, SV *referent)
{
    HV *stash;
    SV *sv;

    sv = newRV_noinc((SV*) referent);
    stash = gv_stashpv(class, 0);
    if (stash == 0)
	fatal("attempt to create object of undefined class '%s'", class);
    sv_bless(sv, stash);
    return sv;
}


static void setNumber(HV *hv, char *name, IV val)
{
    SV *sv = newSViv(val);
    setMember(hv, name, sv);
}


static void setString(HV *hv, char *name, char *val)
{
    setBuffer(hv, name, val, 0);
}


static void setBuffer(HV *hv, char *name, char *valdata, int vallen)
{
    SV *sv = newSVpv(valdata, vallen);
    setMember(hv, name, sv);
}


static void setMember(HV *hv, char *name, SV *val)
{
    /* We don't increment `val's reference count -- I think this is
     * right because it's created with a refcount of 1, and in fact
     * the reference via this hash is the only reference to it in
     * general.
     */
    if (!hv_store(hv, name, (U32) strlen(name), val, (U32) 0))
	fatal("couldn't store member in hash");
}
