/*
 * Various C-specific decls/includes/etc. for the RPM linkage
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef H_RPM_XS_HDR
#define H_RPM_XS_HDR

#ifdef Stat
#  undef Stat
#endif
#ifdef Mkdir
#  undef Mkdir
#endif
#ifdef Fstat
#  undef Fstat
#endif
#ifdef Fflush
#  undef Fflush
#endif
#ifdef Fopen
#  undef Fopen
#endif

/* Borrowed from DB_File.xs */
#ifndef pTHX
#    define pTHX
#    define pTHX_
#    define aTHX
#    define aTHX_
#    define dTHX dTHR
#endif

#ifndef newSVpvn
#    define newSVpvn(a,b)       newSVpv(a,b)
#endif
#ifndef newSVpvn_share
#    define newSVpvn_share(s,len,hash)	newSVpvn(s,len)
#endif
#ifndef SvPV_nolen
#    define SvPV_nolen(s)	SvPV(s, PL_na)
#endif

#include <rpmcli.h>
#include <rpmlib.h>
#include <rpmdb.h>

/* Various flags. For now, one nybble for header and one for package. */
#define RPM_HEADER_MASK        0x0f
#define RPM_HEADER_READONLY    0x01
#define RPM_HEADER_FROM_REF    0x02

#define RPM_PACKAGE_MASK       0x0f00
#define RPM_PACKAGE_READONLY   0x0100
#define RPM_PACKAGE_NOREAD     0x0200


/*
 *    Perl complement: RPM::Database
 */

/*
  This is the underlying struct that implements the interface to the RPM
  database.
*/

typedef struct {
    rpmdb dbp;
    rpmdbMatchIterator iterator;
} RPM_Database;

typedef RPM_Database * RPM__Database;


/*
 *    Perl complement: RPM::Header
 */

/*
  This is the underlying struct that implements the interface to the RPM
  headers.
*/

typedef struct {
    Header hdr;
    /* These three tags will probably cover at least 80% of data requests */
    const char* name;
    const char* version;
    const char* release;
    /* These are set by rpmReadPackageHeader when applicable */
    int isSource;   /* If this header is for a source RPM (SRPM) */
    /* Keep a per-header iterator for things like FIRSTKEY and NEXTKEY */
    HeaderIterator iterator;
    /* Since we close the files after reading, store the filename here in case
       we have to re-open it later */
    char* source_name;
} RPM_Header;

typedef RPM_Header * RPM__Header;


/*
  These represent the various interfaces that are allowed for use outside
  their native modules.
*/
/* RPM.xs: */
extern void *rpm_hvref2ptr(pTHX_ SV *, const char *);
extern SV *rpm_ptr2hvref(pTHX_ void *, const char *);

typedef int RPM_Tag;
extern int rpmtag_pv2iv(pTHX_ const char *name);
extern const char *rpmtag_iv2pv(pTHX_ int tag);
extern SV *rpmtag_iv2sv(pTHX_ int tag);
extern int rpmtag_sv2iv(pTHX_ SV *sv);

/* RPM/Error.xs: */
extern SV* rpm_errSV;

/* RPM/Header.xs: */
extern const char* sv2key(pTHX_ SV *);
extern RPM__Header rpmhdr_TIEHASH_header(pTHX_ const Header);
extern RPM__Header rpmhdr_TIEHASH_new(pTHX);
extern RPM__Header rpmhdr_TIEHASH_FD(pTHX_ const FD_t);
extern RPM__Header rpmhdr_TIEHASH_fd(pTHX_ const int);
extern RPM__Header rpmhdr_TIEHASH_file(pTHX_ const char *);
extern SV* rpmhdr_FETCH(pTHX_ RPM__Header, RPM_Tag);
void rpmhdr_DESTROY(pTHX_ RPM__Header hdr);
void rpmhdr_CLEAR(pTHX_ RPM__Header hdr);
extern int rpmhdr_STORE(pTHX_ RPM__Header, RPM_Tag, SV *);
extern int rpmhdr_DELETE(pTHX_ RPM__Header, RPM_Tag);
extern bool rpmhdr_EXISTS(pTHX_ RPM__Header, RPM_Tag);
extern int rpmhdr_FIRSTKEY(pTHX_ RPM__Header hdr,
                            RPM_Tag *tagp, SV **valuep);
extern int rpmhdr_NEXTKEY(pTHX_ RPM__Header hdr, RPM_Tag prev_tag,
                            RPM_Tag *tagp, SV **valuep);
extern unsigned int rpmhdr_size(pTHX_ RPM__Header);
extern int rpmhdr_tagtype(pTHX_ RPM__Header, RPM_Tag);
extern int rpmhdr_write(pTHX_ RPM__Header, SV *, int);
extern int rpmhdr_cmpver(pTHX_ RPM__Header, RPM__Header);

/* RPM/Database.xs: */
extern RPM__Database rpmdb_TIEHASH(pTHX_ char *, SV *);
extern RPM__Header rpmdb_FETCH(pTHX_ RPM__Database dbstruct, const char *name);
extern bool rpmdb_EXISTS(pTHX_ RPM__Database dbstruct, const char *name);
extern int rpmdb_FIRSTKEY(pTHX_ RPM__Database db,
                            const char **namep, RPM__Header *hdrp);
extern int rpmdb_NEXTKEY(pTHX_ RPM__Database db, const char *prev_name,
                            const char **namep, RPM__Header *hdrp);

#endif /* H_RPM_XS_HDR */
