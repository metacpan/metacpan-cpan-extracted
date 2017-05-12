
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#include "ppport.h" 

#include "perlvtab.h"

SQLITE_EXTENSION_INIT1

#ifdef MULTIPLICITY
#  define my_dTHX(a) pTHXx = ((PerlInterpreter*)((a) ? (a) : PERL_GET_THX))
#else
#  define my_dTHX(a) dNOOP
#endif

#ifdef __APPLE__
extern char **environ;
#endif

typedef struct _perl_vtab {
    sqlite3_vtab base;
    SV *sv;
    sqlite3 *db;
#ifdef MULTIPLICITY
    PerlInterpreter *perl;
#endif
} perl_vtab;

typedef struct _perl_vtab_cursor {
    sqlite3_vtab_cursor base;
    SV *sv;
} perl_vtab_cursor;


#define VTM_CREATE 0
#define VTM_CONNECT 1
#define VTM_DROP 2
#define VTM_DISCONNECT 3
#define VTM_BEGIN_TRANSACTION 4
#define VTM_SYNC_TRANSACTION 5
#define VTM_COMMIT_TRANSACTION 6
#define VTM_ROLLBACK_TRANSACTION 7

EXTERN_C void xs_init (pTHX);

EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);

EXTERN_C void
xs_init(pTHX)
{
	char *file = __FILE__;
	dXSUB_SYS;

	/* DynaLoader is a special case */
	newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}


static char *vtm_name[] = { "CREATE", 
                            "CONNECT",
                            "DROP",
                            "DISCONNECT",                            
                            "BEGIN_TRANSACTION",
                            "SYNC_TRANSACTION",
                            "COMMIT_TRANSACTION",
                            "ROLLBACK_TRANSACTION",
                            NULL, };

static int
perlCreateOrConnect(sqlite3 *db,
                    void *pAux,
                    int argc, const char *const *argv,
                    sqlite3_vtab **ppVTab,
		    char **pzErr,
                    int method) {
    my_dTHX(pAux);
    dSP;
    I32 ax;
    int i;
    int count;
    SV *tmp;
    perl_vtab *vtab = NULL;
    SV *vtabsv;
    int rc = SQLITE_OK;

    if (argc < 4) {
        Perl_warn(aTHX_ "Can't create virtual table, Perl driver name is missing");
        return SQLITE_ERROR;
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv(VTAB_MODULE_LOADER, 0)));
    XPUSHs(sv_2mortal(newSVpv(vtm_name[method], 0)));

    for (i = 0; i<argc; i++) {
        tmp = sv_2mortal(newSVpv(argv[i], 0));
        SvUTF8_on(tmp);
        XPUSHs(tmp);
    }

    PUTBACK;
    count = call_method("_CREATE_OR_CONNECT", G_SCALAR|G_EVAL);
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;
    vtabsv = ST(0);
    if (!count || SvTRUE(ERRSV) || !SvOK(vtabsv)) {
        Perl_warn(aTHX_  "%s::%s method failed: %s\n",
		  VTAB_MODULE_LOADER,
                  vtm_name[method],
                  SvTRUE(ERRSV) ? SvPV_nolen(ERRSV) : "method returned undef");
        rc = SQLITE_ERROR;
        goto cleanup;
    }

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    PUTBACK;
    count = call_method("DECLARE_SQL", G_SCALAR|G_EVAL);
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;
    tmp = ST(0);    
    if (!count || SvTRUE(ERRSV) || !SvOK(tmp)) {
        Perl_warn(aTHX_  "%s::DECLARE_SQL method failed: %s",
                  sv_reftype(SvRV(vtabsv), 1),
                  SvTRUE(ERRSV) ? SvPV_nolen(ERRSV) : "method returned undef");
        rc = SQLITE_ERROR;
	if (SvTRUE(ERRSV))
	    *pzErr = sqlite3_mprintf("%s", SvPV_nolen(ERRSV));
        goto cleanup;
    }

    rc = sqlite3_declare_vtab(db, SvPVutf8_nolen(tmp));
    if (rc != SQLITE_OK)
        goto cleanup;

    Newxz(vtab, 1, perl_vtab);
    vtab->sv = SvREFCNT_inc(vtabsv);
    vtab->db = db;
#ifdef MULTIPLICITY
    vtab->perl = my_perl;
#endif

cleanup:
    *ppVTab = (sqlite3_vtab *) vtab;

    FREETMPS;
    LEAVE;
    
    return rc;
}

static int
perlCreate(sqlite3 *db,
           void *pAux,
           int argc, const char *const *argv,
           sqlite3_vtab **ppVTab,
	   char **pzErr) {
    return perlCreateOrConnect(db, pAux, argc, argv, ppVTab, pzErr, VTM_CREATE);
}

static int
perlConnect(sqlite3 *db,
           void *pAux,
           int argc, const char *const *argv,
           sqlite3_vtab **ppVTab,
	   char **pzErr) {
    return perlCreateOrConnect(db, pAux, argc, argv, ppVTab, pzErr, VTM_CONNECT);
}

static int
perlSimpleVtabMethod(sqlite3_vtab *vtab, int method) {
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = ((perl_vtab*)vtab)->sv;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    PUTBACK;
    count = call_method(vtm_name[method], G_VOID|G_EVAL);
    SPAGAIN;
    SP -= count;
    PUTBACK;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::%s method failed: %s",
                  sv_reftype(SvRV(vtabsv), 1),
                  vtm_name[method],
                  SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
        goto cleanup;
    }

cleanup:
    FREETMPS;
    LEAVE;

    return rc;
}

static int
perlDropOrDisconnect(sqlite3_vtab *vtab, int method) {
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = ((perl_vtab*)vtab)->sv;
    int count;
    int rc = SQLITE_OK;

    assert(method < VTM__TOP);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    PUTBACK;
    count = call_method(vtm_name[method], G_VOID|G_EVAL);
    SPAGAIN;
    SP -= count;
    PUTBACK;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::%s method failed: %s",
                  sv_reftype(SvRV(vtabsv), 1),
                  vtm_name[method],
                  SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
        goto cleanup;
    }

    SvREFCNT_dec(vtabsv);
    Safefree(vtab);
    
cleanup:
    FREETMPS;
    LEAVE;

    return rc;
}

static int
perlBegin(sqlite3_vtab *vtab) {
    return perlSimpleVtabMethod(vtab, VTM_BEGIN_TRANSACTION);
}

static int
perlSync(sqlite3_vtab *vtab) {
    return perlSimpleVtabMethod(vtab, VTM_SYNC_TRANSACTION);
}

static int
perlCommit(sqlite3_vtab *vtab) {
    return perlSimpleVtabMethod(vtab, VTM_COMMIT_TRANSACTION);
}

static int
perlRollback(sqlite3_vtab *vtab) {
    return perlSimpleVtabMethod(vtab, VTM_ROLLBACK_TRANSACTION);
}

static int
perlDestroy(sqlite3_vtab *vtab) {
    return perlDropOrDisconnect(vtab, VTM_DROP);
}

static int
perlDisconnect(sqlite3_vtab *vtab) {
    return perlDropOrDisconnect(vtab, VTM_DISCONNECT);
}

static int
perlOpen(sqlite3_vtab *vtab, sqlite3_vtab_cursor **ppCursor) {
    my_dTHX(((perl_vtab *)vtab)->perl);
    dSP;
    I32 ax;
    perl_vtab_cursor *cursor = NULL;
    SV *vtabsv = ((perl_vtab*)vtab)->sv;
    SV *cursv;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    PUTBACK;
    count = call_method("OPEN", G_SCALAR|G_EVAL);
    SPAGAIN;

    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;
    cursv = ST(0);

    if (!count || !SvOK(cursv)) {
        Perl_warn(aTHX_ "%s::OPEN method failed: %s",
                  sv_reftype(SvRV(vtabsv), 1),
                  SvTRUE(ERRSV) ? SvPV_nolen(ERRSV) : "method returned undef");
        rc = SQLITE_ERROR;
        goto cleanup;
    }

    Newxz(cursor, 1, perl_vtab_cursor);
    cursor->sv = SvREFCNT_inc(cursv);
    SvREFCNT_inc(vtabsv);

cleanup:
    *ppCursor = (sqlite3_vtab_cursor *) cursor;

    FREETMPS;
    LEAVE;

    return rc;
}

static int
perlClose(sqlite3_vtab_cursor *cur) {
    SV *cursv = ((perl_vtab_cursor *)cur)->sv;
    perl_vtab *vtab = (perl_vtab *)(cur->pVtab);
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = vtab->sv;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    XPUSHs(cursv);

    PUTBACK;
    count = call_method("CLOSE", G_VOID|G_EVAL);
    SPAGAIN;

    SP -= count;
    PUTBACK;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::CLOSE method failed: %s", sv_reftype(SvRV(vtabsv), 1), SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
        goto cleanup;
    }
    
    SvREFCNT_dec(cursv);
    SvREFCNT_dec(vtabsv);
    Safefree(cur);

cleanup:
    FREETMPS;
    LEAVE;

    return rc;
}

static char *
op2str(unsigned char op) {
    switch (op) {
    case SQLITE_INDEX_CONSTRAINT_EQ:
        return "eq";
    case SQLITE_INDEX_CONSTRAINT_GT:
        return "gt";
    case SQLITE_INDEX_CONSTRAINT_LE:
        return "le";
    case SQLITE_INDEX_CONSTRAINT_LT:
        return "lt";
    case SQLITE_INDEX_CONSTRAINT_GE:
        return "ge";
    case SQLITE_INDEX_CONSTRAINT_MATCH:
        return "match";
    default:
        return "unknown";
    }
}

int perlBestIndex(sqlite3_vtab *vtab, sqlite3_index_info *ixinfo) {
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    I32 ax;
    SV *vtabsv = ((perl_vtab*)vtab)->sv;
    AV *av;
    AV *ctrain;
    int count;
    int i;
    STRLEN len;
    char *str;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);

    ctrain = newAV();
    XPUSHs(sv_2mortal(newRV_noinc((SV*)ctrain)));

    for (i = 0; i < ixinfo->nConstraint; i++) {
        HV *hv = newHV();
        av_push(ctrain, newRV_noinc((SV*)hv));
        hv_store(hv, "column",  6, newSViv(ixinfo->aConstraint[i].iColumn), 0);
        hv_store(hv, "operator", 8, newSVpv(op2str(ixinfo->aConstraint[i].op), 0), 0);
        hv_store(hv, "usable", 6, (ixinfo->aConstraint[i].usable ? &PL_sv_yes : &PL_sv_no), 0);
    }

    av = newAV();
    XPUSHs(sv_2mortal(newRV_noinc((SV*)av)));

    for (i = 0; i < ixinfo->nOrderBy; i++) {
        HV *hv = newHV();
        av_push(av, newRV_noinc((SV*)hv));
        hv_store(hv, "column",  6, newSViv(ixinfo->aOrderBy[i].iColumn), 0);
        hv_store(hv, "direction", 9, newSViv(ixinfo->aOrderBy[i].desc ? -1 : 1), 0);
    }
    
    PUTBACK;
    count = call_method("BEST_INDEX", G_ARRAY|G_EVAL);
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::BEST_INDEX method failed: %s\n", sv_reftype(SvRV(vtabsv), 1), SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
        goto cleanup;
    }

    if (count != 4) {
        Perl_warn(aTHX_ "%s::BEST_INDEX method returned wrong number of values (%d, %d expected)", sv_reftype(SvRV(vtabsv), 1), count, 4);
        rc = SQLITE_ERROR;
        goto cleanup;
    }

    ixinfo->idxNum = SvIV(ST(0));
    str = SvPVutf8(ST(1), len);
    ixinfo->idxStr = sqlite3_malloc(len+1);
    memcpy(ixinfo->idxStr, str, len);
    ixinfo->idxStr[len] = 0;
    ixinfo->needToFreeIdxStr = 1;

    ixinfo->orderByConsumed = SvTRUE(ST(2));
    ixinfo->estimatedCost = SvNV(ST(3));

    for (i = 0; i < ixinfo->nConstraint; i++) {
        SV **rv = av_fetch(ctrain, i, FALSE);
        if (rv && SvROK(*rv) && SvTYPE(SvRV(*rv)) == SVt_PVHV) {
            HV *hv = (HV*)SvRV(*rv);
            SV **val;
            val = hv_fetch(hv, "arg_index", 9, FALSE);
            ixinfo->aConstraintUsage[i].argvIndex = (val && SvOK(*val)) ? SvIV(*val) + 1 : 0;
            val = hv_fetch(hv, "omit", 4, FALSE);
            ixinfo->aConstraintUsage[i].omit = (val && SvTRUE(*val)) ? 1 : 0;
            /* Perl_warn(aTHX_ "omit: %d\n", ixinfo->aConstraintUsage[i].omit); */
        }
        else {
            Perl_warn(aTHX_ "%s::BEST_INDEX method has corrupted constraint data structure",
                      sv_reftype(SvRV(vtabsv), 1));
            rc = SQLITE_ERROR;
            goto cleanup;
        }
    }

cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}

static int
perlEof(sqlite3_vtab_cursor* cur) {
    I32 ax;
    SV *cursv = ((perl_vtab_cursor *)cur)->sv;
    perl_vtab *vtab = (perl_vtab *)(cur->pVtab);
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = vtab->sv;
    SV *rcsv;
    int count;
    int rc = 0;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    XPUSHs(cursv);

    PUTBACK;
    count = call_method("EOF", G_SCALAR|G_EVAL);
    SPAGAIN;

    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    rcsv = ST(0);
    PUTBACK;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::EOF method failed: %s", sv_reftype(SvRV(vtabsv), 1), SvPV_nolen(ERRSV));
        rc = 1;
        goto cleanup;
    }

    rc = SvTRUE(rcsv);

cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}

static int
perlNext(sqlite3_vtab_cursor* cur) {
    SV *cursv = ((perl_vtab_cursor *)cur)->sv;
    perl_vtab *vtab = (perl_vtab *)(cur->pVtab);
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = vtab->sv;
    SV *rcsv;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    XPUSHs(cursv);
    PUTBACK;
    count = call_method("NEXT", G_SCALAR|G_EVAL);
    SPAGAIN;
    SP -= count;
    PUTBACK;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::NEXT method failed: %s", sv_reftype(SvRV(vtabsv), 1), SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
    }

cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}

static int
perlColumn(sqlite3_vtab_cursor *cur, sqlite3_context *ctx, int n) {
    I32 ax;
    SV *cursv = ((perl_vtab_cursor *)cur)->sv;
    perl_vtab *vtab = (perl_vtab *)(cur->pVtab);
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = vtab->sv;
    SV *sv;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(vtabsv);
    XPUSHs(cursv);
    XPUSHs(sv_2mortal(newSViv(n)));
    PUTBACK;
    count = call_method("COLUMN", G_SCALAR|G_EVAL);
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;
    sv = ST(0);

    if (SvTRUE(ERRSV)) {
        STRLEN len;
        char *str;
        SV *err = sv_2mortal(newSVpvf("%s::COLUMN method failed: %s", sv_reftype(SvRV(vtabsv), 1), SvPV_nolen(ERRSV)));
        str = SvPVutf8(err, len);
        sqlite3_result_error(ctx, str, len);
        rc = SQLITE_ERROR;
        goto cleanup;
    }

    if (!SvOK(sv)) {
        /* Perl_warn(aTHX_ "undef found"); */
        sqlite3_result_null(ctx);
    }
    else if (SvIOK(sv)) {
        /* Perl_warn(aTHX_ "int found"); */
        sqlite3_result_int(ctx, SvIV(sv));
    }
    else if (SvNOK(sv)) {
        /* Perl_warn(aTHX_ "number found"); */
        sqlite3_result_double(ctx, SvNV(sv));
    }
    else {
        STRLEN len;
        char *str = SvPVutf8(sv, len);
        /* Perl_warn(aTHX_ "string found"); */
        sqlite3_result_text(ctx, str, len, SQLITE_TRANSIENT);
    }


cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}

static SV *
newSVsqlite3_value(pTHX_ sqlite3_value *v) {
    SV *sv;
    int type = sqlite3_value_type(v);
    switch(type) {
    case SQLITE_NULL:
        return &PL_sv_undef;

    case SQLITE_INTEGER:
        return newSViv(sqlite3_value_int(v));

    case SQLITE_FLOAT:
        return newSVnv(sqlite3_value_double(v));

    case SQLITE_TEXT:
        sv = newSVpvn(sqlite3_value_text(v),
                      sqlite3_value_bytes(v));
        SvUTF8_on(sv);
        return sv;

    case SQLITE_BLOB:
        return newSVpvn((char *)sqlite3_value_text(v),
                        sqlite3_value_bytes(v));
    }
    Perl_warn(aTHX_ "unsupported SQLite type %d found", type);
    return &PL_sv_undef;
}

static int
perlFilter(sqlite3_vtab_cursor *cur,
           int idxNum, const char *idxStr,
           int argc, sqlite3_value **argv) {
    
    SV *cursv = ((perl_vtab_cursor *)cur)->sv;
    perl_vtab *vtab = (perl_vtab *)(cur->pVtab);
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = vtab->sv;
    SV *tmp;
    int i;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(vtabsv);
    XPUSHs(cursv);
    XPUSHs(sv_2mortal(newSViv(idxNum)));
    tmp = sv_2mortal(newSVpv(idxStr, 0));
    SvUTF8_on(tmp);
    XPUSHs(tmp);
    for (i = 0; i < argc; i++)
        XPUSHs(sv_2mortal(newSVsqlite3_value(aTHX_ argv[i])));
    PUTBACK;
    count = call_method("FILTER", G_VOID|G_EVAL);
    SPAGAIN;
    SP -= count;
    PUTBACK;

    if (SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::FILTER method failed: %s", sv_reftype(SvRV(vtabsv), 1), SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
    }

cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}

static int
perlRowid(sqlite3_vtab_cursor *cur, sqlite_int64 *rowid) {
    SV *cursv = ((perl_vtab_cursor *)cur)->sv;
    perl_vtab *vtab = (perl_vtab *)(cur->pVtab);
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    SV *vtabsv = vtab->sv;
    SV *rowidsv;
    I32 ax;
    int i;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(vtabsv);
    XPUSHs(cursv);

    PUTBACK;
    count = call_method("ROWID", G_SCALAR|G_EVAL);
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;
    rowidsv = ST(0);
    if (!count || SvTRUE(ERRSV) || !SvOK(rowidsv)) {
        Perl_warn(aTHX_ "%s::ROWID method failed: %s",
                  sv_reftype(SvRV(vtabsv), 1),
                  SvTRUE(ERRSV) ? SvPV_nolen(ERRSV) : "method returned undef");
        rc = SQLITE_ERROR;
        goto cleanup;
    }

    if (SvUOK(rowidsv))
        *rowid = SvUV(rowidsv);
    else if (SvIOK(rowidsv))
        *rowid = SvIV(rowidsv);
    else
        *rowid = SvNV(rowidsv);

cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}


static int
perlUpdate(sqlite3_vtab *vtab, int argc, sqlite3_value **argv, sqlite_int64 *rowid) {
    my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    I32 ax;
    SV *vtabsv = ((perl_vtab*)vtab)->sv;
    SV *rowidsv;
    int i;
    int count;
    int rc = SQLITE_OK;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(vtabsv);
    for (i = 0; i < argc; i++)
        XPUSHs(sv_2mortal(newSVsqlite3_value(aTHX_ argv[i])));
    PUTBACK;
    count = call_method("UPDATE", G_SCALAR|G_EVAL);
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;

    if (!count || SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::UPDATE method failed: %s\n",
                  sv_reftype(SvRV(vtabsv), 1),
                  SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
        goto cleanup;
    }    
    rowidsv = ST(0);
    if (!SvOK(rowidsv))
        *rowid = 0;
    else if (SvUOK(rowidsv))
        *rowid = SvUV(rowidsv);
    else if (SvIOK(rowidsv))
        *rowid = SvIV(rowidsv);
    else
        *rowid = SvNV(rowidsv);

cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}

static int
perlRename(sqlite3_vtab *vtab, const char *name) {
     my_dTHX(((perl_vtab*)vtab)->perl);
    dSP;
    I32 ax;
    SV *vtabsv = ((perl_vtab*)vtab)->sv;
    int count;
    int rc = SQLITE_OK;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(vtabsv);
    XPUSHs(sv_2mortal(newSVpv(name, 0)));
    PUTBACK;
    count = call_method("RENAME", G_SCALAR|G_EVAL);
    SPAGAIN;
    SP -= count;
    ax = (SP - PL_stack_base) + 1;
    PUTBACK;

    if (!count || SvTRUE(ERRSV)) {
        Perl_warn(aTHX_ "%s::RENAME method failed: %s\n",
                  sv_reftype(SvRV(vtabsv), 1),
                  SvPV_nolen(ERRSV));
        rc = SQLITE_ERROR;
        goto cleanup;
    }    
    rc = (SvTRUE(ST(0)) ? SQLITE_OK : SQLITE_ERROR);

cleanup:
    FREETMPS;
    LEAVE;
    return rc;
}


sqlite3_module vtab_perl_module = {
    1,
    perlCreate,
    perlConnect,
    perlBestIndex,
    perlDisconnect,
    perlDestroy,
    perlOpen,
    perlClose,
    perlFilter,
    perlNext,
    perlEof,
    perlColumn,
    perlRowid,
    perlUpdate,
    perlBegin,
    perlSync,
    perlCommit,
    perlRollback,
    NULL, /* perlFindFunction - not implemented yet! */
    perlRename,
};

static char *argv[] = { "perlvtab",
			"-e",
			"$SQLite::VirtualTable::EMBEDED=1;"
			"require SQLite::VirtualTable",
			NULL };

int sqlite3_extension_init(sqlite3 *db, char **pzErrMsg, 
                           const sqlite3_api_routines *pApi) {

    PerlInterpreter *my_perl = perl_alloc();
    int ac = 3;
    char **av = argv;
    char **env = environ;
    PERL_SYS_INIT3(&ac, &av, &env);
    perl_construct(my_perl);
    perl_parse(my_perl, xs_init, ac, av, env);
    perl_run(my_perl);

    SQLITE_EXTENSION_INIT2(pApi)

    sqlite3_create_module(db, "perl", &vtab_perl_module, my_perl);
    return SQLITE_OK;
}

int dbd_sqlite_init_vtab_extension(sqlite3 *db, char **pzErrMsg, 
				   const sqlite3_api_routines *pApi) {
    SQLITE_EXTENSION_INIT2(pApi)

    sqlite3_create_module(db, "perl", &vtab_perl_module, NULL);
    return SQLITE_OK;
}
