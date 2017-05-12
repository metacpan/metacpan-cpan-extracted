/* $Header: /home/cvsroot/NetZ3950/yazwrap/send.c,v 1.12 2006/05/08 10:54:14 mike Exp $ */

/*
 * yazwrap/send.c -- wrapper functions for Yaz's client API.
 *
 * This file provides functions which (we hope) will be easier to
 * invoke via XS than the raw Yaz API.  We do this by providing fewer
 * functions at a higher level; and, where appropriate, using more
 * primitive C data types.
 */

#include <unistd.h>
#include <yaz/proto.h>
#include <yaz/pquery.h>		/* prefix query compiler */
#include <yaz/ccl.h>		/* CCL query compiler */
#include <yaz/yaz-ccl.h>	/* CCL-to-RPN query converter */
#include <yaz/otherinfo.h>
#include <yaz/charneg.h>
#include "ywpriv.h"


Z_ReferenceId *make_ref_id(Z_ReferenceId *buf, databuf refId);
static Odr_oid *record_syntax(ODR odr, int preferredRecordSyntax);
static databuf encode_apdu(ODR odr, Z_APDU *apdu, char **errmsgp);
static int prepare_odr(ODR *odrp, char **errmsgp);
static databuf nodata(char *msg);


/*
 * Errors are indicated by returning a databuf with a null data member,
 * with *errmsgp pointed at an error message whose memory is managed by
 * this module.
 */
databuf makeInitRequest(databuf referenceId,
			int preferredMessageSize,
			int maximumRecordSize,
			mnchar *user,
			mnchar *password,
			mnchar *groupid,
			mnchar *implementationId,
			mnchar *implementationName,
			mnchar *implementationVersion,
			mnchar *charset,
			mnchar *language,
			char **errmsgp)
{
    static ODR odr = 0;
    Z_APDU *apdu;
    Z_InitRequest *req;
    Z_ReferenceId zr;
    Z_IdAuthentication auth;
    Z_IdPass id;

    if (!prepare_odr(&odr, errmsgp))
	return nodata((char*) 0);
    apdu = zget_APDU(odr, Z_APDU_initRequest);
    req = apdu->u.initRequest;

    req->referenceId = make_ref_id(&zr, referenceId);
    /*
     * ### We should consider allowing the caller to influence which
     * of the following options are set.  The ones marked with the
     * Mystic Rune Of The Triple Hash are actually not supported in
     * Net::Z3950.pm as I write.
     */
    ODR_MASK_SET(req->options, Z_Options_search);
    ODR_MASK_SET(req->options, Z_Options_present);
    ODR_MASK_SET(req->options, Z_Options_namedResultSets);
    ODR_MASK_SET(req->options, Z_Options_triggerResourceCtrl); /* ### */
    ODR_MASK_SET(req->options, Z_Options_scan);
    ODR_MASK_SET(req->options, Z_Options_sort);	/* ### */
    ODR_MASK_SET(req->options, Z_Options_extendedServices); /* ### */
    ODR_MASK_SET(req->options, Z_Options_delSet); /* ### */

    ODR_MASK_SET(req->protocolVersion, Z_ProtocolVersion_1);
    ODR_MASK_SET(req->protocolVersion, Z_ProtocolVersion_2);
    ODR_MASK_SET(req->protocolVersion, Z_ProtocolVersion_3);

    *req->preferredMessageSize = preferredMessageSize;
    *req->maximumRecordSize = maximumRecordSize;

    /*
     * We interpret the `user', `password' and `group' arguments as
     * follows: if `user' is not specified, then authentication is
     * omitted (which is more or less the same as "anonymous"
     * authentication); if `user' is specified but not `password',
     * then it's treated as an "open" authentication token; if both
     * `user' and `password' are specified, then they are used in
     * "idPass" authentication, together with `group' if specified.
     */
    if (user != 0) {
	req->idAuthentication = &auth;
	if (password == 0) {
	    auth.which = Z_IdAuthentication_open;
	    auth.u.open = user;
	} else {
	    auth.which = Z_IdAuthentication_idPass;
	    auth.u.idPass = &id;
	    id.userId = user;
	    id.groupId = groupid;
	    id.password = password;
	}
    }

    if (charset || language) {
        Z_OtherInformation **p;
        Z_OtherInformationUnit *p0;

        yaz_oi_APDU(apdu, &p);
         
        if ((p0=yaz_oi_update(p, odr, NULL, 0, 0))) {
            ODR_MASK_SET(req->options, Z_Options_negotiationModel);
             
            p0->which = Z_OtherInfo_externallyDefinedInfo;
            p0->information.externallyDefinedInfo =
                yaz_set_proposal_charneg(
                    odr,
                    (const char**)&charset,
                    charset ? 1 : 0,
                    (const char**)&language, language ? 1 : 0, 1);
        }
    }
     

    if (implementationId != 0)
	req->implementationId = implementationId;
    if (implementationName != 0)
	req->implementationName = implementationName;
    if (implementationVersion != 0)
	req->implementationVersion = implementationVersion;

    return encode_apdu(odr, apdu, errmsgp);
}


/*
 * I feel really uncomfortable about that fact that if this function
 * fails, the caller has no way to know why -- it could be an illegal
 * record syntax, an unsupported query type, a bad search command or
 * failure to encode the APDU.  Oh well.
 */
databuf makeSearchRequest(databuf referenceId,
			  int smallSetUpperBound,
			  int largeSetLowerBound,
			  int mediumSetPresentNumber,
			  char *resultSetName,
			  char *databaseName,
			  char *smallSetElementSetName,
			  char *mediumSetElementSetName,
			  int preferredRecordSyntax,
			  int queryType,
			  char *query,
			  char **errmsgp)
{
    static ODR odr = 0;
    Z_APDU *apdu;
    Z_SearchRequest *req;
    Z_ReferenceId zr;
    Z_ElementSetNames smallES, mediumES;
    oident attrset;
    int oidbuf[20];		/* more than enough */
    Z_Query zquery;
    Odr_oct ccl_query;
    struct ccl_rpn_node *rpn;
    int error, pos;
    static CCL_bibset bibset;
    Z_External *ext;

    if (!prepare_odr(&odr, errmsgp))
	return nodata((char*) 0);
    apdu = zget_APDU(odr, Z_APDU_searchRequest);
    req = apdu->u.searchRequest;

    req->referenceId = make_ref_id(&zr, referenceId);
    *req->smallSetUpperBound = smallSetUpperBound;
    *req->largeSetLowerBound = largeSetLowerBound;
    *req->mediumSetPresentNumber = mediumSetPresentNumber;
    *req->replaceIndicator = 1;
    if (strcmp (resultSetName, "0") != 0)
	req->resultSetName = resultSetName;
    req->num_databaseNames = 1;
    req->databaseNames = &databaseName;

    /* Translate a single element-set names into a Z_ElementSetNames */
    req->smallSetElementSetNames = &smallES;
    smallES.which = Z_ElementSetNames_generic;
    smallES.u.generic = smallSetElementSetName;

    req->mediumSetElementSetNames = &mediumES;
    mediumES.which = Z_ElementSetNames_generic;
    mediumES.u.generic = mediumSetElementSetName;

    /* Convert from our enumeration to the corresponding OID */
    if ((req->preferredRecordSyntax =
	 record_syntax(odr, preferredRecordSyntax)) == 0)
	return nodata(*errmsgp = "can't convert record syntax");

    /* Convert from our querytype/query pair to a Z_Query */
    req->query = &zquery;

    switch (queryType) {
    case QUERYTYPE_PREFIX:
	/* ### Is type-1 always right?  What about type-101 when under v2? */
        zquery.which = Z_Query_type_1;
        if ((zquery.u.type_1 = p_query_rpn (odr, PROTO_Z3950, query)) == 0)
	    return nodata(*errmsgp = "can't compile PQN query");
        break;

    case QUERYTYPE_CCL:
        zquery.which = Z_Query_type_2;
        zquery.u.type_2 = &ccl_query;
        ccl_query.buf = (unsigned char*) query;
        ccl_query.len = strlen(query);
        break;

    case QUERYTYPE_CCL2RPN:
        zquery.which = Z_Query_type_1;
	if (bibset == 0) {
	    FILE *fp;
	    bibset = ccl_qual_mk();
	    if ((fp = fopen("ccl.qual", "r")) != 0) {
		ccl_qual_file(bibset, fp);
		fclose(fp);
	    } else if (errno != ENOENT) {
		return nodata(*errmsgp = "can't read CCL qualifier file");
	    }
	}
        if ((rpn = ccl_find_str(bibset, query, &error, &pos)) == 0)
	    return nodata(*errmsgp = (char*) ccl_err_msg(error));
        if ((zquery.u.type_1 = ccl_rpn_query(odr, rpn)) == 0)
	    return nodata(*errmsgp = "can't encode Type-1 query");
        attrset.proto = PROTO_Z3950;
        attrset.oclass = CLASS_ATTSET;
        attrset.value = VAL_BIB1; /* ### should be configurable! */
        zquery.u.type_1->attributeSetId = oid_ent_to_oid(&attrset, oidbuf);
        ccl_rpn_delete (rpn);
        break;

    case QUERYTYPE_CQL:
        zquery.which = Z_Query_type_104;
        ext = (Z_External*) odr_malloc(odr, sizeof(*ext));
        ext->direct_reference = odr_getoidbystr(odr, "1.2.840.10003.16.2");
        ext->indirect_reference = 0;
        ext->descriptor = 0;
        ext->which = Z_External_CQL;
        ext->u.cql = odr_strdup(odr, query);
        zquery.u.type_104 = ext;
        break;

    default:
	return nodata(*errmsgp = "unknown queryType");
    }

    return encode_apdu(odr, apdu, errmsgp);
}


/* Inspired by the scan implementation from client.c
 * in the source package of the YAZ C toolkit available
 * at http://www.indexdata.dk/yaz/
 */
databuf makeScanRequest(databuf referenceId,
                        char *databaseName,
                        int stepSize,
                        int numberOfTermsRequested,
                        int preferredPositionInResponse,
                        int queryType,
                        char *query,
			char **errmsgp)                    
{
    static ODR odr = 0;
    Z_APDU *apdu;
    Z_ScanRequest *req;
    Z_ReferenceId zr;
    static CCL_bibset bibset;
    int oid[OID_SIZE];

    if (!prepare_odr(&odr, errmsgp))
        return nodata((char*) 0);

    apdu = zget_APDU(odr, Z_APDU_scanRequest);
    req = apdu->u.scanRequest;

    req->referenceId = make_ref_id(&zr, referenceId);
    req->num_databaseNames = 1;
    req->databaseNames = &databaseName;
    req->stepSize = &stepSize;
    req->numberOfTermsRequested = &numberOfTermsRequested;
    req->preferredPositionInResponse = &preferredPositionInResponse;

    /* ### should this share code with makeSearchRequest()? */
    if (queryType == QUERYTYPE_CCL2RPN) {
        oident bib1;
        int error, pos;
        struct ccl_rpn_node *rpn;

        rpn = ccl_find_str (bibset,  query, &error, &pos);
        if (bibset == 0) {
            FILE *fp;
            bibset = ccl_qual_mk();
            if ((fp = fopen("ccl.qual", "r")) != 0) {
                ccl_qual_file(bibset, fp);
                fclose(fp);
            } else if (errno != ENOENT) {
                return nodata (*errmsgp = "can't read CCL qualifier file");
            }
        }
        rpn = ccl_find_str (bibset,  query, &error, &pos);
        if (error) {
            return nodata (*errmsgp = (char *) ccl_err_msg(error));
        }
        bib1.proto = PROTO_Z3950;
        bib1.oclass = CLASS_ATTSET;
        bib1.value = VAL_BIB1;
        req->attributeSet = oid_ent_to_oid (&bib1, oid);

        if (!(req->termListAndStartPoint = ccl_scan_query (odr, rpn))) {
           return  nodata (*errmsgp = "can't convert CCL to Scan term");
        }
        ccl_rpn_delete (rpn);

    } else {  /* QUERYTYPE_PREFIX */
        YAZ_PQF_Parser pqf_parser = yaz_pqf_create ();

        if (!(req->termListAndStartPoint =
            yaz_pqf_scan(pqf_parser, odr, &req->attributeSet, query)))
        {
            size_t off;
            (void) yaz_pqf_error (pqf_parser,(const char **) errmsgp, &off);
            yaz_pqf_destroy (pqf_parser);
            return nodata(*errmsgp);
        }
        yaz_pqf_destroy (pqf_parser);
    }

    return encode_apdu(odr, apdu, errmsgp);
}


databuf makePresentRequest(databuf referenceId,
			   char *resultSetId,
			   int resultSetStartPoint,
			   int numberOfRecordsRequested,
			   char *elementSetName,
			   int preferredRecordSyntax,
			   char **errmsgp)
{
    static ODR odr = 0;
    Z_APDU *apdu;
    Z_PresentRequest *req;
    Z_ReferenceId zr;
    Z_RecordComposition rcomp;
    Z_ElementSetNames esname;

    if (!prepare_odr(&odr, errmsgp))
	return nodata((char*) 0);
    apdu = zget_APDU(odr, Z_APDU_presentRequest);
    req = apdu->u.presentRequest;

    req->referenceId = make_ref_id(&zr, referenceId);
    if (strcmp (resultSetId, "0") != 0)
	req->resultSetId = resultSetId;
    *req->resultSetStartPoint = resultSetStartPoint;
    *req->numberOfRecordsRequested = numberOfRecordsRequested;
    req->num_ranges = 0;	/* ### would be nice to support this */
    req->recordComposition = &rcomp;
    rcomp.which = Z_RecordComp_simple;	/* ### espec suppport would be nice */
    rcomp.u.simple = &esname;
    esname.which = Z_ElementSetNames_generic;
    esname.u.generic = elementSetName;
    if ((req->preferredRecordSyntax =
	 record_syntax(odr, preferredRecordSyntax)) == 0)
	return nodata(*errmsgp = "can't convert record syntax");

    return encode_apdu(odr, apdu, errmsgp);
}


databuf makeDeleteRSRequest(databuf referenceId,
			    char *resultSetId,
			    char **errmsgp)
{
    static ODR odr = 0;
    Z_APDU *apdu;
    Z_DeleteResultSetRequest *req;
    Z_ReferenceId zr;
    Z_ResultSetId *rsList[1];
    int x;

    if (!prepare_odr(&odr, errmsgp))
	return nodata((char*) 0);
    apdu = zget_APDU(odr, Z_APDU_deleteResultSetRequest);
    req = apdu->u.deleteResultSetRequest;

    req->referenceId = make_ref_id(&zr, referenceId);
    req->deleteFunction = &x;
    x = Z_DeleteResultSetRequest_list;
    req->num_resultSetList = 1;
    req->resultSetList = &rsList[0];
    rsList[0] = resultSetId;

    return encode_apdu(odr, apdu, errmsgp);
}


/*
 * If refId is non-null, copy it into the provided buffer, and return
 * a pointer to it; otherwise, return a null pointer.  Either way, the
 * result is suitable to by plugged into an APDU structure.
 */
Z_ReferenceId *make_ref_id(Z_ReferenceId *buf, databuf refId)
{
    if (refId.data == 0)
	return 0;

    buf->buf = (unsigned char*) refId.data;
    buf->len = (int) refId.len;
    return buf;
}


static Odr_oid *record_syntax(ODR odr, int preferredRecordSyntax)
{
    oident prefsyn;
    int oidbuf[20];		/* more than enough */
    int *oid;

    prefsyn.proto = PROTO_Z3950;
    prefsyn.oclass = CLASS_RECSYN;
    prefsyn.value = (oid_value) preferredRecordSyntax;
    if ((oid = oid_ent_to_oid(&prefsyn, oidbuf)) == 0)
	return 0;

    return odr_oiddup(odr, oid);
}


/*
 * Memory management strategy: every APDU we're asked to allocate
 * obliterates the previous one by overwriting our static ODR buffer,
 * so the caller _must_ ensure that it copies or otherwise consumes
 * the return value before the next call is made.  (This strategy
 * would normally stink, but it's actually not error-prone in this
 * context, since we know that the Perl XS code is about to copy the
 * data onto its stack.)
 */
static databuf encode_apdu(ODR odr, Z_APDU *apdu, char **errmsgp)
{
    databuf res;
    int len;
    res.len = 0;		/* Not needed, but prevents compiler warning */
    res.data = 0;

    if (!z_APDU(odr, &apdu, 0, (char*) 0)) {
	*errmsgp = odr_errmsg(odr_geterror(odr));
	return res;
    }

    res.data = odr_getbuf(odr, &len, (int*) 0);
    res.len = len;
    return res;
}


static int prepare_odr(ODR *odrp, char **errmsgp)
{
    if (*odrp != 0) {
	odr_reset(*odrp);
    } else if ((*odrp = odr_createmem(ODR_ENCODE)) == 0) {
	*errmsgp = "can't create ODR stream";
	return 0;
    }

    return 1;
}


/*
 * Return a databuf with a null pointer (used as an error indicator)
 * (In passing, we also report to stderr what the problem was.)
 */
static databuf nodata(char *msg)
{
    databuf buf;

#ifndef NDEBUG
    if (msg != 0) {
	fprintf(stderr, "DEBUG nodata(): %s\n", msg);
    }
#endif
    buf.len = 0;		/* Not needed, but prevents compiler warning */
    buf.data = 0;
    return buf;
}


/*
 * Simple wrapper for cs_write() when that comes along.  Also calls
 * cs_look() to detect the completion of a connection when that comes
 * along.
 */
int yaz_write(COMSTACK cs, databuf buf)
{
    if (cs_look(cs) == CS_CONNECT) {
	if (cs_rcvconnect(cs) < 0) {
	    return -1;
	}
    }

    return write(cs_fileno(cs), buf.data, buf.len);
}
