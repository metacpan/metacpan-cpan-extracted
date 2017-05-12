#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <fcntl.h>
#include "RPM.h"

/*
  rpmdb_TIEHASH

  This is the implementation of the tied-hash class constructor. The XS
  wrapper will verify that the value of class is correct, then massage the
  arguments as needed. The return value is expected to be either NULL or a
  valid RPM__Database value (which the XS wrapper will fix up).
*/
RPM__Database rpmdb_TIEHASH(pTHX_ char* class, SV* opts)
{
    char*  root  = (char *)NULL;
    int    mode  = O_RDONLY;
    mode_t perms = 0;
    HV*    opt_hash;
    SV**   svp;
    RPM_Database* retvalp; /* For "private" */

    if (opts)
    {
        if (SvROK(opts) && (SvTYPE(opts) == SVt_PVHV))
        {
            /* This is a hash reference. We are concerned only with
               the key "root". "mode" and "perms" don't apply, as we are
               going to open the database as read-only. */
            opt_hash = (HV*)SvRV(opts);

            svp = hv_fetch(opt_hash, "root", 4, FALSE);
            if (svp && SvPOK(*svp))
                root = SvPV_nolen(*svp);
        }
        else if (SvPOK(opts))
        {
            /* They passed a scalar, assumed to be the "root" */
            root = SvPV_nolen(opts);
        }
        else
        {
            rpmError(RPMERR_BADARG, "Wrong type for argument 2 to TIEHASH");
            return (Null(RPM__Database));
        }
    }

    /* With that all processed, attempt to open the actual RPM DB */
    /* The retvalp is used for the C-level rpmlib information on databases */
    Newz(0, retvalp, 1, RPM_Database);
    if (rpmdbOpen(root, &retvalp->dbp, mode, perms) != 0)
    {
        Safefree(retvalp);
        /* rpm lib will have set the error already */
        return (Null(RPM__Database));
    }

    return retvalp;
}

RPM__Header rpmdb_FETCH(pTHX_ RPM__Database dbstruct, const char *name)
{
    Header h, hi;
    rpmdbMatchIterator mi;
    RPM__Header hdr = Null(RPM__Header);

    h = Null(Header);
    mi = rpmdbInitIterator(dbstruct->dbp, RPMTAG_NAME, name, 0);
    while ((hi = rpmdbNextIterator(mi)) != Null(Header))
    {
        /* There might be more than one match. Find the newest one. */
        if (h == Null(Header) || rpmVersionCompare(hi, h) == 1)
        {
            headerFree(h);
            h = headerLink(hi);
        }
    }
    rpmdbFreeIterator(mi);
    if (h)
        hdr = rpmhdr_TIEHASH_header(aTHX_ h);
    return hdr;
}

bool rpmdb_EXISTS(pTHX_ RPM__Database dbstruct, const char *name)
{
    RPM__Header hdr = rpmdb_FETCH(aTHX_ dbstruct, name);
    if (hdr) {
        rpmhdr_DESTROY(aTHX_ hdr);
        return TRUE;
    }
    return FALSE;
}

int rpmdb_FIRSTKEY(pTHX_ RPM__Database db, const char **namep, RPM__Header *hdrp)
{
    if (db->iterator)
        rpmdbFreeIterator(db->iterator);
    db->iterator = rpmdbInitIterator(db->dbp, RPMDBI_PACKAGES, NULL, 0);
    if (! db->iterator) {
        warn("%s: rpmdbInitIterator() failed", "RPM::Database::FIRSTKEY");
        return 0;
    }
    return rpmdb_NEXTKEY(aTHX_ db, Nullch, namep, hdrp);
}

int rpmdb_NEXTKEY(pTHX_ RPM__Database db, const char *prev_name,
                  const char **namep, RPM__Header *hdrp)
{
    Header h;
    (void) prev_name;
    if (! db->iterator) {
        warn("%s called before FIRSTKEY", "RPM::Database::NEXTKEY");
        return 0;
    }
    if (! (h = rpmdbNextIterator(db->iterator))) {
        /* That was last package.  Game over. */
        rpmdbFreeIterator(db->iterator);
        db->iterator = Null(rpmdbMatchIterator);
        return 0;
    }
    h = headerLink(h);
    *hdrp = rpmhdr_TIEHASH_header(aTHX_ h);
    *namep = (*hdrp)->name;
    return 1;
}

void rpmdb_DESTROY(pTHX_ RPM__Database db)
{
    if (db->iterator)
        rpmdbFreeIterator(db->iterator);
    rpmdbClose(db->dbp);
    Safefree(db);
}

MODULE = RPM::Database  PACKAGE = RPM::Database         PREFIX = rpmdb_


RPM::Database
rpmdb_TIEHASH(class, opts=NULL)
    char* class;
    SV* opts;
    PROTOTYPE: $;$
    CODE:
    RETVAL = rpmdb_TIEHASH(aTHX_ class, opts);
    OUTPUT:
    RETVAL

RPM::Header
rpmdb_FETCH(self, name)
    RPM::Database self;
    const char *name;
    PROTOTYPE: $$
    CODE:
    RETVAL = rpmdb_FETCH(aTHX_ self, name);
    OUTPUT:
    RETVAL

int
rpmdb_STORE(self=NULL, key=NULL, value=NULL)
    SV* self;
    SV* key;
    SV* value;
    PROTOTYPE: $$$
    CODE:
    {
        rpmError(RPMERR_NOCREATEDB, "STORE: operation not permitted");
        RETVAL = 0;
    }
    OUTPUT:
        RETVAL

SV*
rpmdb_DELETE(self=NULL, key=NULL)
    SV* self;
    SV* key;
    PROTOTYPE: $$
    CODE:
    {
        rpmError(RPMERR_NOCREATEDB, "DELETE: operation not permitted");
        RETVAL = Nullsv;
    }
    OUTPUT:
    RETVAL

int
rpmdb_CLEAR(self=NULL)
    SV* self;
    PROTOTYPE: $
    CODE:
    {
        rpmError(RPMERR_NOCREATEDB, "CLEAR: operation not permitted");
        RETVAL = 0;
    }
    OUTPUT:
    RETVAL

bool
rpmdb_EXISTS(self, name)
    RPM::Database self;
    const char *name;
    PROTOTYPE: $$
    CODE:
    RETVAL = rpmdb_EXISTS(aTHX_ self, name);
    OUTPUT:
    RETVAL

void
rpmdb_FIRSTKEY(self)
    RPM::Database self;
    PROTOTYPE: $
    PPCODE:
    {
        const char *name;
        RPM__Header hdr;

        if (rpmdb_FIRSTKEY(aTHX_ self, &name, &hdr))
        {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(rpm_ptr2hvref(aTHX_ hdr, "RPM::Header")));
            PUSHs(sv_2mortal(newSVpv(name, 0)));
        }

    }

void
rpmdb_NEXTKEY(self, prev_name=NULL)
    RPM::Database self;
    const char *prev_name;
    PROTOTYPE: $;$
    PPCODE:
    {
        const char *name;
        RPM__Header hdr;

        if (rpmdb_NEXTKEY(aTHX_ self, prev_name, &name, &hdr))
        {
            EXTEND(SP, 2);
            PUSHs(sv_2mortal(rpm_ptr2hvref(aTHX_ hdr, "RPM::Header")));
            PUSHs(sv_2mortal(newSVpv(name, 0)));
        }

    }

void
rpmdb_DESTROY(self)
    RPM::Database self;
    PROTOTYPE: $
    CODE:
    rpmdb_DESTROY(aTHX_ self);

bool
rpmdb_init(class, root=NULL, perms=O_RDWR)
    SV* class;
    const char* root;
    int perms;
    PROTOTYPE: $;$$
    CODE:
    if (SvPOK(class) && strEQ(SvPV_nolen(class), "RPM::Database"))
        RETVAL = !rpmdbInit(root, perms);
    else {
        rpmError(RPMERR_BADARG, "%s must be called as a static method",
                                "RPM::Database::init");
        RETVAL = FALSE;
    }
    OUTPUT:
    RETVAL

bool
rpmdb_rebuild(class, root=NULL)
    SV* class;
    const char* root;
    PROTOTYPE: $;$
    CODE:
    if (SvPOK(class) && strEQ(SvPV_nolen(class), "RPM::Database"))
#if RPM_VERSION >= 0x040100
        RETVAL = !rpmdbRebuild(root, NULL, NULL);
#else
        RETVAL = !rpmdbRebuild(root);
#endif
    else {
        rpmError(RPMERR_BADARG, "%s must be called as a static method",
                                "RPM::Database::rebuild");
        RETVAL = FALSE;
    }
    OUTPUT:
    RETVAL

void
rpmdb_find_by_file(self, string)
    RPM::Database self;
    SV *string;
    PROTOTYPE: $$
    ALIAS:
        find_by_group = RPMTAG_GROUP
        find_what_provides = RPMTAG_PROVIDENAME
        find_what_requires = RPMTAG_REQUIRENAME
        find_what_conflicts = RPMTAG_CONFLICTNAME
        find_by_package = RPMTAG_NAME
    PPCODE:
    /* This is a front-end to all the rpmdbFindBy*() set, including FindByPackage
       which differs from FETCH above in that if there is actually more than one
       match, all will be returned.  */
    {
        const char *str = Nullch;
        RPM_Header *hdr;

        if (ix == 0)
            ix = RPMTAG_BASENAMES;

        hdr = rpm_hvref2ptr(aTHX_ string, "RPM::Header");
        if (hdr)
            str = hdr->name;
        else
            str = SvPV_nolen(string);

        if (! (str && *str)) {
            rpmError(RPMERR_BADARG, "%s: arg 2 must be either a string"
                     " or valid RPM::Header object", GvNAME(CvGV(cv)));
        /*  Perl_warn(aTHX_ "%s", SvPV_nolen(rpm_errSV)); */
        }
        else {
            rpmdbMatchIterator mi = rpmdbInitIterator(self->dbp, ix, str, 0);
            if (mi) {
                Header h;
                int n = rpmdbGetIteratorCount(mi);
                EXTEND(SP, n);
                while ((h = rpmdbNextIterator(mi)) != Null(Header)) {
                    h = headerLink(h);
                    hdr = rpmhdr_TIEHASH_header(aTHX_ h);
                    PUSHs(sv_2mortal(rpm_ptr2hvref(aTHX_ hdr, "RPM::Header")));
                }
                rpmdbFreeIterator(mi);
            }
        }
    }
