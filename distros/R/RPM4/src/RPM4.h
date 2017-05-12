/* $Id$ */

#ifndef _HDLIST_H
#define _HDLIST_H

#include "rpmversion.h"
#include "header.h"

/* Hdlistsign.c: imported but modified functions */

int rpmchecksig(rpmts ts, const char * filename, int flags);

/* rpmlib does not export some usefull functions
 * We Import its here 
 * This File should be the last included */

/* From signature.h */

#ifndef H_SIGNATURE

typedef	enum sigType_e {
    RPMSIGTYPE_HEADERSIG= 5
} sigType;

typedef enum pgpVersion_e {
    PGP_NOTDETECTED	= -1,
    PGP_UNKNOWN		= 0,
    PGP_2		= 2,
    PGP_5		= 5
} pgpVersion;

Header rpmNewSignature(void);

rpmRC rpmReadSignature(FD_t fd, Header *sighp,
		sigType sig_type, const char ** msg);

int rpmWriteSignature(FD_t fd, Header h);

int rpmAddSignature(Header sig, const char * file,
		    int32_t sigTag, const char * passPhrase);

#define RPMLOOKUPSIG_QUERY	0	/*!< Lookup type in effect          */
#define RPMLOOKUPSIG_DISABLE	1	/*!< Disable (--sign was not given) */
#define RPMLOOKUPSIG_ENABLE	2	/*!< Re-enable %_signature          */

int rpmLookupSignatureType(int action);

char * rpmGetPassPhrase(const char * prompt,
		const int sigTag);

const char * rpmDetectPGPVersion(pgpVersion * pgpVer);

#endif /* H_SIGNATURE */

#ifndef H_HEADER_INTERNAL

#ifdef HD_HEADER_INTERNAL
/** \ingroup header
 * Description of tag data.
 */
typedef /*@abstract@*/ struct entryInfo_s * entryInfo;
struct entryInfo_s {
    int32_t tag;         /*!< Tag identifier. */
    int32_t type;        /*!< Tag data type. */
    int32_t offset;      /*!< Offset into data segment (ondisk only). */
    int32_t count;       /*!< Number of tag elements. */
};

/** \ingroup header
 * A single tag from a Header.
 */
typedef /*@abstract@*/ struct indexEntry_s * indexEntry;
struct indexEntry_s {
    struct entryInfo_s info;    /*!< Description of tag data. */
/*@owned@*/
    void * data;        /*!< Location of tag data. */
    int length;         /*!< No. bytes of data. */
    int rdlen;          /*!< No. bytes of data in region. */
};

struct headerToken_s {
    /*@unused@*/
    struct HV_s hv;     /*!< Header public methods. */
    /*@only@*/ /*@null@*/
    void * blob;        /*!< Header region blob. */
    /*@owned@*/
    indexEntry index;       /*!< Array of tags. */
    int indexUsed;      /*!< Current size of tag array. */
    int indexAlloced;       /*!< Allocated size of tag array. */
    int flags;
#define HEADERFLAG_SORTED   (1 << 0) /*!< Are header entries sorted? */
#define HEADERFLAG_ALLOCATED    (1 << 1) /*!< Is 1st header region allocated? */
#define HEADERFLAG_LEGACY   (1 << 2) /*!< Header came from legacy source? */
#define HEADERFLAG_DEBUG    (1 << 3) /*!< Debug this header? */
    /*@refs@*/
    int nrefs;          /*!< Reference count. */
};
#endif

#endif /* H_HEADER_INTERNAL */

#ifndef H_LEGACY

void compressFilelist(Header h);
void expandFilelist(Header h);

#endif /* H_LEGACY */

#endif
