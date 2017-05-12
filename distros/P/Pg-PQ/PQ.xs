#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef _
#undef _
#endif

#include <libpq-fe.h>

/* static SV * */
/* wrap_hv(void *ptr, char *klass) { */
/*     HV *hv = newHV(); */
/*     SV *sv = newRV_noinc((SV*)hv); */
/*     sv_bless(sv, gv_stashpv(klass, TRUE)); */
/*     hv_stores(hv, "ptr", newSViv(PTR2IV(ptr))); */
/*     return sv; */
/* } */

/* static void * */
/* unwrap_hv(SV *sv) { */
/*     if (SvOK(sv) && SvROK(sv)) { */
/*         HV *hv = SvRV(sv); */
/*         if (SvTYPE((SV*)hv) == SVt_HVPV) { */
/*             SV **psv = hv_fetchs(hv, "ptr", 0); */
/*             if (psv && SvOK(*psv)) */
/*                 return INT2PTR(SvIV(*psv)); */
/*         } */
/*     } */
/*     Perl_croak(aTHX_ "Invalid wrapper"); */
/* } */

static SV *
my_newSVpv_utf8(pTHX_ const char *str) {
    return (str ? newSVpvn_utf8(str, strlen(str), 1) : &PL_sv_undef); 
}

static SV *
make_constant(char *name, STRLEN l, U32 value, char *tag) {
    SV *sv = newSV(0);
    SvUPGRADE(sv, SVt_PVIV);
    sv_setpvn(sv, name, l);
    SvIOK_on(sv);
    SvIsUV_on(sv);
    SvUV_set(sv, value);
    SvREADONLY_on(sv);
    newCONSTSUB(gv_stashpv("Pg::PQ", 1), name, sv);
    if (tag) {
        HV *hv = get_hv("Pg::PQ::EXPORT_TAGS", TRUE);
        SV **svp = hv_fetch(hv, tag, strlen(tag), 1);
        if (!svp || !*svp)
            Perl_croak(aTHX_ "internal error populating EXPORT_TAGS");
        if (!SvOK(*svp) || !SvROK(*svp) || (SvTYPE(SvRV(*svp)) != SVt_PVAV))
            sv_setsv(*svp, sv_2mortal(newRV_noinc((SV*)newAV())));
        av_push((AV*)SvRV(*svp), my_newSVpv_utf8(aTHX_ name));
    }
    return sv;
}

static void
sv_chomp(SV *sv) {
    while (SvOK(sv) && SvPOK(sv) && SvCUR(sv) && SvPVX(sv)[SvCUR(sv) - 1] == '\n')
        SvCUR_set(sv, SvCUR(sv) - 1);
}


#include "enums.h"


MODULE = Pg::PQ		PACKAGE = Pg::PQ		PREFIX=PQ

PROTOTYPES: DISABLE

BOOT:
    init_constants();

char *
PQlibVersion()
CODE:
#if (0 && (PQMAJOR >= 9))
    RETVAL = PQlibVersion(); /* this returns an integer, use the
                              * value obtained from pg_config at
                              * compilation instead */
#else
    RETVAL = PQVERSION;
#endif
OUTPUT:
    RETVAL

MODULE = Pg::PQ		PACKAGE = Pg::PQ::Conn          PREFIX=PQ

void
PQdefaults(...)
PREINIT:
    PQconninfoOption *opts;
    int n = 0;
PPCODE:
    opts = PQconndefaults();
    if (opts) {
        for (; opts[n].keyword; n++) {
            HV *hv = newHV();
            XPUSHs(newRV_noinc((SV*)hv));
            hv_stores(hv, "keyword" , newSVpv(opts[n].keyword , 0));
            hv_stores(hv, "envvar"  , newSVpv(opts[n].envvar  , 0));
            hv_stores(hv, "compiled", newSVpv(opts[n].compiled, 0));
            hv_stores(hv, "value"   , newSVpv(opts[n].val     , 0));
            hv_stores(hv, "label"   , newSVpv(opts[n].label   , 0));
            hv_stores(hv, "dispchar", newSVpv(opts[n].dispchar, 0));
            hv_stores(hv, "dispsize", newSViv(opts[n].dispsize));
        }
        PQconninfoFree(opts);
    }
    XSRETURN(n);

PGconn *PQconnectdb(const char *conninfo);

PGconn *PQconnectStart(char *conninfo)

PostgresPollingStatusType PQconnectPoll(PGconn *conn)

char *PQdb(PGconn *conn)

char *PQuser(PGconn *conn)

char *PQpass(PGconn *conn)

char *PQhost(PGconn *conn)

char *PQport(PGconn *conn)

char *PQoptions( PGconn *conn)

ConnStatusType PQstatus(PGconn *conn)

PGTransactionStatusType PQtransactionStatus(PGconn *conn)

const char *PQparameterStatus(PGconn *conn, char *paramName)

int PQprotocolVersion(PGconn *conn)

int PQserverVersion(PGconn *conn)

char *PQerrorMessage(PGconn *conn)
CLEANUP:
    sv_chomp(ST(0));

int PQsocket(PGconn *conn)

int PQbackendPID(PGconn *conn)

int PQconnectionNeedsPassword(PGconn *conn)

int PQconnectionUsedPassword(PGconn *conn)

# SSL *PQgetssl(PGconn *conn)

void PQfinish(PGconn *conn)
POSTCALL:
    sv_setsv(SvRV(ST(0)), &PL_sv_undef);

void PQreset(PGconn *conn);

int PQresetStart(PGconn *conn);

PostgresPollingStatusType PQresetPoll(PGconn *conn);

const char *PQclientEncoding(PGconn *conn)
CODE:
    RETVAL = pg_encoding_to_char(PQclientEncoding(conn));
OUTPUT:
    RETVAL

PGVerbosity PQsetErrorVerbosity(PGconn *conn, PGVerbosity verbosity);

void PQtrace(PGconn *conn, FILE *stream);

void PQuntrace(PGconn *conn);

# PGresult *PQexec(PGconn *conn, const char *command);

# PGresult *PQexecParams(PGconn *conn, const char *command, int nParams, const Oid *paramTypes, const char * const *paramValues, const int *paramLengths, const int *paramFormats, int resultFormat);

PGresult *PQexec(PGconn *conn, const char *command, ...)
ALIAS:
    execQuery = 0
CODE:
    if (items <= 2) {
        RETVAL = PQexec(conn, command);
    }
    else {
        int n = items - 2, i;
        char **values;
        Newx(values, n, char *);
        for (i = 0; i < n; i++) values[i] = SvPVutf8_nolen(ST(i + 2));
        RETVAL = PQexecParams(conn, command, n, NULL, (const char **)values, NULL, NULL, 0);
        Safefree(values);
    }
OUTPUT:
    RETVAL


# PGresult *PQprepare(PGconn *conn, const char *stmtName, const char *query, int nParams, const Oid *paramTypes);

PGresult *PQprepare(PGconn *conn, const char *stmtName, const char *query)
C_ARGS: conn, stmtName, query, 0, NULL

PGresult *PQdescribePrepared(PGconn *conn, const char *stmtName);

# PGresult *PQexecPrepared(PGconn *conn, const char *stmtName, int nParams, const char * const *paramValues, const int *paramLengths, const int *paramFormats, int resultFormat);

PGresult *PQexecPrepared(PGconn *conn, const char *stmtName, ...)
ALIAS:
    execQueryPrepared = 0
PREINIT:
    int n = items - 2, i;
    char **values;
CODE:
    Newx(values, n, char *);
    for (i = 0; i < n; i++) values[i] = SvPVutf8_nolen(ST(i + 2));
    RETVAL = PQexecPrepared(conn, stmtName, n, (const char **)values, NULL, NULL, 0);
    Safefree(values);
OUTPUT:
    RETVAL

# PGcancel *PQgetCancel(PGconn *conn);
# ALIAS:
#    makeCancel = 0

void PQnotifies(PGconn *conn)
PREINIT:
    PGnotify *notice;
PPCODE:
    notice = PQnotifies(conn);
    if (notice) {
        int pid = notice->be_pid;
        SV *name = sv_2mortal(my_newSVpv_utf8(aTHX_ notice->relname));
        SV *extra = sv_2mortal(my_newSVpv_utf8(aTHX_ notice->extra));
        PQfreemem(notice);
        EXTEND(sp, 3);
        PUSHs(name);
        if (GIMME_V == G_ARRAY) {
            PUSHs(sv_2mortal(newSViv(pid)));
            PUSHs(extra);
            XSRETURN(3);
        }
        else
            XSRETURN(1);
    }
    else
        XSRETURN(0);

PGresult *PQmakeEmptyPGresult(PGconn *conn, ExecStatusType status);
ALIAS:
    PQmakeEmptyResult = 0

SV *PQescapeString(PGconn *conn, SV *from)
PREINIT:
    STRLEN len;
    char *pv;
    int error;
CODE:
    pv = SvPVutf8(from, len);
    RETVAL = newSV(len * 2 + 1);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, PQescapeStringConn(conn, SvPVX(RETVAL), pv, len, &error));
    if (error) {
        SvREFCNT_dec(RETVAL);
        RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

#if PQMAJOR >= 9

char *PQescapeLiteral(PGconn *conn, const char *str, size_t length(str))
CLEANUP:
    if (RETVAL) PQfreemem(RETVAL);

char *PQescapeIdentifier(PGconn *conn, const char *str, size_t length(str))
CLEANUP:
    if (RETVAL) PQfreemem(RETVAL);

#endif

# unsigned char *PQescapeByteaConn(PGconn *conn, unsigned char *from, size_t from_length, size_t *to_length);

# int PQsendQuery(PGconn *conn, const char *command);

# int PQsendQueryParams(PGconn *conn, const char *command, int nParams, const Oid *paramTypes, const char * const *paramValues, const int *paramLengths, const int *paramFormats, int resultFormat);

int PQsendQuery(PGconn *conn, const char *command, ...)
CODE:
    if (items <= 2) {
        RETVAL = PQsendQuery(conn, command);
    }
    else {
        int n = items - 2, i;
        char **values;
        Newx(values, n, char *);
        for (i = 0; i < n; i++) {
            SV *sv = ST(i + 2);
            values[i] = (SvOK(sv) ? SvPVutf8_nolen(sv) : NULL);
        }
        RETVAL = PQsendQueryParams(conn, command, n, NULL, (const char **)values, NULL, NULL, 0);
        Safefree(values);
    }
OUTPUT:
    RETVAL


# int PQsendPrepare(PGconn *conn, const char *stmtName, const char *query, int nParams, const Oid *paramTypes);

int PQsendPrepare(PGconn *conn, const char *stmtName, const char *query)
C_ARGS: conn, stmtName, query, 0, NULL

# int PQsendQueryPrepared(PGconn *conn, char *stmtName, int nParams, const char * const *paramValues, const int *paramLengths, const int *paramFormats, int resultFormat);

int PQsendQueryPrepared(PGconn *conn, const char *stmtName, ...)
PREINIT:
    int n = items - 2, i;
    char **values;
CODE:
    Newx(values, n, char *);
    for (i = 0; i < n; i++) values[i] = SvPVutf8_nolen(ST(i + 2));
    RETVAL = PQsendQueryPrepared(conn, stmtName, n, (const char **)values, NULL, NULL, 0);
    Safefree(values);
OUTPUT:
    RETVAL

PGresult *PQgetResult(PGconn *conn);
ALIAS:
    result = 0

int PQconsumeInput(PGconn *conn);

int PQisBusy(PGconn *conn)
ALIAS:
    busy = 0

int PQsetnonblocking(PGconn *conn, int arg)

int PQisnonblocking(PGconn *conn);

int nonBlocking(PGconn *conn, SV *nb = &PL_sv_undef)
CODE:
    if (SvOK(nb))
        PQsetnonblocking(conn, SvIV(nb));
    RETVAL = PQisnonblocking(conn);
OUTPUT:
    RETVAL

int PQflush(PGconn *conn);

# PGresult *PQfn(PGconn *conn, int fnid, int *result_buf, int *result_len, int result_is_int, const PQArgBlock *args, int nargs);


MODULE = Pg::PQ		PACKAGE = Pg::PQ::Result          PREFIX=PQ

ExecStatusType PQresultStatus(PGresult *res)
ALIAS:
    status = 0

char *PQresStatus(ExecStatusType status)

char *statusMessage(PGresult *res)
CODE:
    RETVAL = PQresStatus(PQresultStatus(res));
OUTPUT:
    RETVAL

char *PQresultErrorMessage(PGresult *res)
ALIAS:
    errorMessage = 0
CLEANUP:
    sv_chomp(ST(0));

char *PQresultErrorField(PGresult *res, char field);
ALIAS:
    _errorField = 0
CLEANUP:
    sv_chomp(ST(0));

void PQclear(PGresult *res)
POSTCALL:
    sv_setsv(ST(0), &PL_sv_undef);

int PQntuples(PGresult *res)
ALIAS:
    nTuples = 0
    nRows   = 1

int PQnfields(PGresult *res)
ALIAS:
    nFields  = 0
    nColumns = 1

char *PQfname(PGresult *res, int column_number)
ALIAS:
    columnName = 0

void
PQfnames(PGresult *res)
ALIAS:
    columnNames = 0
PREINIT:
    int cols;
PPCODE:
    cols = PQnfields(res);
    if (cols) {
        int j;
        if (GIMME_V != G_ARRAY) cols = 1;
        EXTEND(sp, cols);
        for (j = 0; j < cols; j++) {
            char *pv = PQfname(res, j);
            SV *sv = newSVpvn_utf8(pv, strlen(pv), 1);
            mPUSHs(sv);            
        }
    }
    XSRETURN(cols);


int PQfnumber(PGresult *res, const char *column_name)
ALIAS:
    columnNumber = 0

Oid PQftable(PGresult *res, int column_number)
ALIAS:
    columnTable = 0

SV *PQftablecol(PGresult *res, int column_number);
ALIAS:
    columnTableColumn = 0
PREINIT:
    int col;
CODE:
    col = PQftablecol(res, column_number);
    RETVAL = (col ? newSViv(col) : &PL_sv_undef);
OUTPUT:
    RETVAL

int PQfformat(PGresult *res, int column_number);

Oid PQftype(PGresult *res, int column_number);

int PQfmod(PGresult *res, int column_number);

int PQfsize(PGresult *res, int column_number);
ALIAS:
    fSize = 0

int PQbinaryTuples(PGresult *res);

int PQgetisnull(PGresult *res, int row_number, int column_number);
ALIAS:
    null = 0

# TODO: handle data in binary format
SV *PQgetvalue(PGresult *res, int row_number, int column_number);
ALIAS:
    value = 0
PREINIT:
    char *pv;
CODE:
    if (PQgetisnull(res, row_number, column_number))
        RETVAL = &PL_sv_undef;
    else {
        pv = PQgetvalue(res, row_number, column_number);
        if (pv)
            RETVAL = newSVpvn_utf8(pv, PQgetlength(res, row_number, column_number), 1);
        else
            RETVAL = &PL_sv_undef;
    }
OUTPUT:
    RETVAL

void
PQgettuple(PGresult *res, UV i = 0)
ALIAS:
    row = 0
PREINIT:
    int rows, cols, j;
PPCODE:
    rows = PQntuples(res);
    cols = PQnfields(res);
    if ((i > rows) || !cols)
        XSRETURN(0);
    else {
        if (GIMME_V != G_ARRAY) cols = 1;
        EXTEND(SP, cols);
        for (j = 0; j < cols; j++) {
            if (!PQgetisnull(res, i, j)) {
                char *pv = PQgetvalue(res, i, j);
                if (pv) {
                    PUSHs(newSVpvn_utf8(pv, PQgetlength(res, i, j), 1));
                    continue;
                }
            }
            PUSHs(&PL_sv_undef);
        }
        XSRETURN(cols);
    }

void
PQgettuple_as_hash(PGresult *res, ...)
ALIAS:
    rowAsHash = 0
PREINIT:
    int i, rows, cols;
PPCODE:
    i = (items > 1 ? SvIV(ST(1)) : 0);
    rows = PQntuples(res);
    cols = PQnfields(res);
    if ((i > rows) || !cols)
        XSRETURN(0);
    else {
        int j;
        HV *hv = newHV();
        SV *rv = newRV_noinc((SV*)hv);
        SV *tmp = NULL;
        for (j = 0; j < cols; j++) {
            SV *key;
            SV *val = ( PQgetisnull(res, i, j) 
                        ? newSV(0)
                        : newSVpvn_utf8(PQgetvalue(res, i, j), PQgetlength(res, i, j), 1));
            if ((items > j + 2) && SvOK(ST(j + 2))) {
                key = ST(j + 2);
            }
            else {
                if (!tmp) tmp = sv_newmortal();
                key = tmp;
                sv_setpv(key, PQfname(res, j));
                SvUTF8_on(key);
            }
            /*fprintf(stderr, "*>> hv_store_ent(0x%p, %s, %s)\n", hv, SvPV_nolen(key), SvPV_nolen(val));*/
            hv_store_ent(hv, key, val, 0);
        }
        mPUSHs(rv);
        XSRETURN(1);
    }

void
PQgetcolumn(PGresult *res, int j = 0)
ALIAS:
    column = 0
PREINIT:
    int rows, cols, i;
PPCODE:
    rows = PQntuples(res);
    cols = PQnfields(res);
    if ((j > cols) || !rows)
        XSRETURN(0);
    else {
        if (GIMME_V != G_ARRAY) rows = 1;
        EXTEND(SP, rows);
        for (i = 0; i < rows; i++) {
            if (!PQgetisnull(res, i, j)) {
                char *pv = PQgetvalue(res, i, j);
                if (pv) {
                    PUSHs(newSVpvn_utf8(pv, PQgetlength(res, i, j), 1));
                    continue;
                }
            }
            PUSHs(&PL_sv_undef);
        }
        XSRETURN(rows);
    }

void
PQgettuples(PGresult *res)
ALIAS:
    rows = 0
PREINIT:
    int rows, cols, i, j;
PPCODE:
    rows = PQntuples(res);
    cols = PQnfields(res);
    if (GIMME_V != G_ARRAY) {
        mPUSHi(rows);
        XSRETURN(1);
    }
    else {
        EXTEND(SP, rows);
        for (i = 0; i < rows; i++) {
            AV *av = newAV();
            mPUSHs(newRV_noinc((SV*)av));
            if (cols) av_extend(av, cols - 1);
            for (j = 0; j < cols; j++) {
                SV *val = ( PQgetisnull(res, i, j)
                            ? &PL_sv_undef
                            : newSVpvn_utf8(PQgetvalue(res, i, j), PQgetlength(res, i, j), 1) );
                av_store(av, j, val);
            }
        }
        XSRETURN(rows);
    }

void
PQgettuples_as_hashes(PGresult *res)
ALIAS:
    rowsAsHashes = 0
PREINIT:
    int rows, cols, i, j;
PPCODE:
    rows = PQntuples(res);
    cols = PQnfields(res);
    if (GIMME_V != G_ARRAY) {
        mPUSHi(cols);
        XSRETURN(1);
    }
    else {
        SV **names;
        Newx(names, cols, SV *);
        EXTEND(SP, rows);
        for (j = 0; j < cols; j++) {
            if (items - 1 > j) {
                names[j] = ST(j - 1);
            }
            else {
                names[j] = sv_2mortal(newSVpv(PQfname(res, j), 0));
                SvUTF8_on(names[j]);
            }
        }
        for (i = 0; i < rows; i++) {
            HV *hv = newHV();
            for (j = 0; j < cols; j++) {
                SV *val = ( PQgetisnull(res, i, j)
                            ? newSV(0)
                            : newSVpvn_utf8(PQgetvalue(res, i, j), PQgetlength(res, i, j), 1) );
                hv_store_ent(hv, names[j], val, 0);
            }
            mPUSHs(newRV_noinc((SV*)hv));
        }
        Safefree(names);
        XSRETURN(rows);
    }


void
PQgetcolumns(PGresult *res)
ALIAS:
    columns = 0
PREINIT:
    int rows, cols, i, j;
PPCODE:
    rows = PQntuples(res);
    cols = PQnfields(res);
    if (GIMME_V != G_ARRAY) {
        mPUSHi(cols);
        XSRETURN(1);
    }
    else {
        EXTEND(SP, rows);
        for (j = 0; j < cols; j++) {
            AV *av = newAV();
            mPUSHs(newRV_noinc((SV*)av));
            if (rows) av_extend(av, rows - 1);
            for (i = 0; i < rows; i++) {
                if (!PQgetisnull(res, i, j)) {
                    char *pv = PQgetvalue(res, i, j);
                    if (pv) {
                        av_store(av, i, newSVpvn_utf8(pv, PQgetlength(res, i, j), 1));
                        continue;
                    }
                }
                av_store(av, i, &PL_sv_undef);
            }
        }
        XSRETURN(cols);
    }


int PQgetlength(PGresult *res, int row_number, int column_number);
ALIAS:
    valueLength = 0

int PQnparams(PGresult *res)
ALIAS:
    nParams = 0

Oid PQparamtype(PGresult *res, int param_number)
ALIAS:
    paramType = 0


# void PQprint(FILE *fout, PGresult *res, PQprintOpt *po);

char *PQcmdStatus(PGresult *res)

SV *PQcmdTuples(PGresult *res)
ALIAS:
    cmdRows = 0
PREINIT:
    char *pv;
CODE:
    pv = PQcmdTuples(res);
    if (!pv || !pv[0])
        RETVAL = &PL_sv_undef;
    else
        RETVAL = my_newSVpv_utf8(aTHX_ pv);
OUTPUT:
    RETVAL

Oid PQoidValue(PGresult *res)

MODULE = Pg::PQ		PACKAGE = Pg::PQ::Cancel          PREFIX=PQ

void PQfreeCancel(PGcancel *cancel);
POSTCALL:
    sv_setsv(SvRV(ST(0)), &PL_sv_undef);

SV *
PQcancel(PGcancel *cancel)
PREINIT:
    int r;
    char buf[256];
CODE:
    r = PQcancel(cancel, buf, 256);
    if (r)
        RETVAL = &PL_sv_undef;
    else {
        RETVAL = my_newSVpv_utf8(aTHX_ buf);
        SvUPGRADE(RETVAL, SVt_PVIV);
        SvIOK_on(RETVAL);
        SvIV_set(RETVAL, 1);
    }
OUTPUT:
    RETVAL
            
