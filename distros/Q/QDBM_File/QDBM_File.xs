#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* for 5.6.1 */
/* #define NEED_sv_2pvbyte */
#define NEED_sv_2pv_flags
#include "ppport.h"

#include "depot.h"
#include "curia.h"
#include "cabin.h"
#include "villa.h"
#include "vista_xs.h"
#include "odeum.h"

/*
   The DBM_setFilter & DBM_ckFilter macros are only used by
   the *DB*_File modules
   Imported from XSUB.h for older XS
*/

#ifndef DBM_setFilter
#define DBM_setFilter(db_type, code)                \
    STMT_START {                                    \
        if (db_type)                                \
            RETVAL = sv_mortalcopy(db_type);        \
        ST(0) = RETVAL;                             \
        if ( db_type && (code == &PL_sv_undef) ) {  \
            SvREFCNT_dec(db_type);                  \
            db_type = NULL;                         \
        }                                           \
        else if (code) {                            \
            if (db_type) {                          \
                sv_setsv(db_type, code);            \
            }                                       \
            else {                                  \
                db_type = newSVsv(code);            \
            }                                       \
        }                                           \
    } STMT_END
#endif

#ifndef DBM_ckFilter
#define DBM_ckFilter(arg, type, name)                       \
    STMT_START {                                            \
        if (db->type) {                                     \
            if (db->filtering) {                            \
                croak("recursion detected in %s", name);    \
            }                                               \
            ENTER;                                          \
            SAVETMPS;                                       \
            SAVEINT(db->filtering);                         \
            db->filtering = TRUE;                           \
            SAVESPTR(DEFSV);                                \
            if (name[7] == 's') {                           \
                arg = newSVsv(arg);                         \
            }                                               \
            DEFSV = arg;                                    \
            SvTEMP_off(arg);                                \
            PUSHMARK(SP);                                   \
            PUTBACK;                                        \
            (void)call_sv(db->type, G_DISCARD);             \
            SPAGAIN;                                        \
            PUTBACK;                                        \
            FREETMPS;                                       \
            LEAVE;                                          \
            if (name[7] == 's') {                           \
                arg = sv_2mortal(arg);                      \
            }                                               \
        }                                                   \
    } STMT_END
#endif

typedef struct {
    void* dbp;
    SV* comparer; /* subroutine reference */
    SV* filter_fetch_key;
    SV* filter_store_key;
    SV* filter_fetch_value;
    SV* filter_store_value;
    int filtering;
} QDBM_File_type;

typedef QDBM_File_type* QDBM_File;
typedef SV* datum_key;
typedef SV* datum_value;

#define dpptr(db)  ( (DEPOT*)db->dbp )
#define crptr(db)  ( (CURIA*)db->dbp )
#define vlptr(db)  ( (VILLA*)db->dbp )
#define vstptr(db) ( (VISTA*)db->dbp )

/* define static data for btree comparer */
#define MY_CXT_KEY "QDBM_File::_guts" XS_VERSION

typedef struct {
    SV* comparer;
} my_cxt_t;

START_MY_CXT

#define DEF_QDBM_STORE(FUNCNAME, PUTFUNC, DBPTR) \
static int FUNCNAME(QDBM_File db, datum_key key, datum_value value, int dmode); \
static int FUNCNAME(QDBM_File db, datum_key key, datum_value value, int dmode) { \
    STRLEN ksize; \
    STRLEN vsize; \
    const char* kbyte; \
    const char* vbyte; \
    kbyte = SvPV_const(key, ksize); \
    vbyte = SvPV_const(value, vsize); \
    return PUTFUNC( DBPTR(db), kbyte, (int)ksize, vbyte, (int)vsize, dmode ); \
}

DEF_QDBM_STORE(store_dp, dpput, dpptr)
DEF_QDBM_STORE(store_cr, crput, crptr)
DEF_QDBM_STORE(store_crlob, crputlob, crptr)
DEF_QDBM_STORE(store_vl, vlput, vlptr)
DEF_QDBM_STORE(store_vst, vstput, vstptr)

#undef DEF_QDBM_STORE_FUNC

static int btree_compare(const char* key_a, int ksize_a, const char* key_b, int ksize_b);
static int btree_compare(const char* key_a, int ksize_a, const char* key_b, int ksize_b) {

    int count;
    int retval;

    dSP;
    dMY_CXT;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs( sv_2mortal( newSVpvn(key_a, (STRLEN)ksize_a) ) );
    XPUSHs( sv_2mortal( newSVpvn(key_b, (STRLEN)ksize_b) ) );

    PUTBACK;

    count = call_sv(MY_CXT.comparer, G_SCALAR);

    SPAGAIN;

    if (1 != count) {
        croak("qdbm compare error: subroutine returned %d values, expected 1\n", count);
    }

    retval = POPi;

    PUTBACK;
    FREETMPS;
    LEAVE;

    return retval;
}

MODULE = QDBM_File    PACKAGE = QDBM_File

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.comparer = &PL_sv_undef;
}

INCLUDE: dbm_filter.xsh

QDBM_File
TIEHASH(char* dbtype, char* filename, int flags = O_CREAT|O_RDWR, int mode = 0644, int buckets = -1)
ALIAS:
    new = 1
PREINIT:
    DEPOT* dbp;
    int o_flags;
CODE:
    RETVAL = NULL;
    o_flags = ( (flags & O_WRONLY) || (flags & O_RDWR) ) ? DP_OWRITER : DP_OREADER;
    if (flags & O_CREAT) o_flags |= DP_OCREAT;
    if (flags & O_TRUNC) o_flags |= DP_OTRUNC;

    dbp = dpopen(filename, o_flags, buckets);

    if (NULL != dbp) {
        Newxz(RETVAL, 1, QDBM_File_type);
        RETVAL->dbp = (void*)dbp;
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
DESTROY(QDBM_File db)
CODE:
    if (db) {
        if ( dpclose( dpptr(db) ) ) {
            if (db->comparer)           SvREFCNT_dec(db->comparer);
            if (db->filter_fetch_key)   SvREFCNT_dec(db->filter_fetch_key);
            if (db->filter_store_key)   SvREFCNT_dec(db->filter_store_key);
            if (db->filter_fetch_value) SvREFCNT_dec(db->filter_fetch_value);
            if (db->filter_store_value) SvREFCNT_dec(db->filter_store_value);
            Safefree(db);
        }
        else {
            croak( "qdbm close error: %s\n", dperrmsg(dpecode) );
        }
    }

datum_value
FETCH(QDBM_File db, datum_key key, int start = 0, int offset = -1)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    char* value;
CODE:
    kbyte = SvPV_const(key, ksize);
    value = dpget( dpptr(db), kbyte, (int)ksize, start, offset, &vsize );
    if (NULL != value) {
        RETVAL = newSVpvn(value, (STRLEN)vsize);
        cbfree(value);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
STORE(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_dp(db, key, value, DP_DOVER);
OUTPUT:
    RETVAL

bool
store_keep(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_dp(db, key, value, DP_DKEEP);
OUTPUT:
    RETVAL

bool
store_cat(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_dp(db, key, value, DP_DCAT);
OUTPUT:
    RETVAL

bool
DELETE(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
CODE:
    kbyte = SvPV_const(key, ksize);
    RETVAL = dpout( dpptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
EXISTS(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
CODE:
    kbyte = SvPV_const(key, ksize);
    vsize = dpvsiz( dpptr(db), kbyte, (int)ksize );
    RETVAL = (-1 != vsize);
OUTPUT:
    RETVAL

datum_key
FIRSTKEY(QDBM_File db)
PREINIT:
    int ksize;
    char* key;
CODE:
    if ( dpiterinit( dpptr(db) ) ) {
        key = dpiternext( dpptr(db), &ksize );
        if (NULL != key) {
            RETVAL = newSVpvn(key, (STRLEN)ksize);
            cbfree(key);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

datum_key
NEXTKEY(QDBM_File db, datum_key prev_key)
PREINIT:
    int ksize;
    char* key;
CODE:
    key = dpiternext( dpptr(db), &ksize );
    if (NULL != key) {
        RETVAL = newSVpvn(key, (STRLEN)ksize);
        cbfree(key);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
set_align(QDBM_File db, int align)
CODE:
    RETVAL = dpsetalign( dpptr(db), align );
OUTPUT:
    RETVAL

bool
set_fbp_size(QDBM_File db, int size)
CODE:
    RETVAL = dpsetfbpsiz( dpptr(db), size );
OUTPUT:
    RETVAL

bool
sync(QDBM_File db)
CODE:
    RETVAL = dpsync( dpptr(db) );
OUTPUT:
    RETVAL

bool
optimize(QDBM_File db, int buckets = -1)
CODE:
    RETVAL = dpoptimize( dpptr(db), buckets );
OUTPUT:
    RETVAL

int
get_record_size(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
CODE:
    kbyte = SvPV_const(key, ksize);
    RETVAL = dpvsiz( dpptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
init_iterator(QDBM_File db)
CODE:
    RETVAL = dpiterinit( dpptr(db) );
OUTPUT:
    RETVAL

SV*
get_name(QDBM_File db)
PREINIT:
    char* name;
CODE:
    name = dpname( dpptr(db) );
    if (NULL != name) {
        RETVAL = newSVpv(name, 0);
        cbfree(name);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

int
get_size(QDBM_File db)
CODE:
    RETVAL = dpfsiz( dpptr(db) );
OUTPUT:
    RETVAL

int
count_buckets(QDBM_File db)
CODE:
    RETVAL = dpbnum( dpptr(db) );
OUTPUT:
    RETVAL

int
count_used_buckets(QDBM_File db)
CODE:
    RETVAL = dpbusenum( dpptr(db) );
OUTPUT:
    RETVAL

int
count_records(QDBM_File db)
ALIAS:
    SCALAR = 1
CODE:
    RETVAL = dprnum( dpptr(db) );
OUTPUT:
    RETVAL

bool
is_writable(QDBM_File db)
CODE:
    RETVAL = dpwritable( dpptr(db) );
OUTPUT:
    RETVAL

bool
is_fatal_error(QDBM_File db)
CODE:
    RETVAL = dpfatalerror( dpptr(db) );
OUTPUT:
    RETVAL

const char*
get_error(SV* package)
CODE:
    RETVAL = dperrmsg(dpecode);
OUTPUT:
    RETVAL

time_t
get_mtime(QDBM_File db)
CODE:
    RETVAL = dpmtime( dpptr(db) );
OUTPUT:
    RETVAL

bool
repair(SV* package, char* filename)
CODE:
    if ( sv_isobject(package) ) {
        warn("qdbm repair warning: called via instance method\n");
    }
    RETVAL = dprepair(filename);
OUTPUT:
    RETVAL

bool
export_db(QDBM_File db, char* filename)
CODE:
    RETVAL = dpexportdb( dpptr(db), filename );
OUTPUT:
    RETVAL

bool
import_db(QDBM_File db, char* filename)
CODE:
    RETVAL = dpimportdb( dpptr(db), filename );
OUTPUT:
    RETVAL

MODULE = QDBM_File    PACKAGE = QDBM_File::Multiple

INCLUDE: dbm_filter.xsh

QDBM_File
TIEHASH(char* dbtype, char* filename, int flags = O_CREAT|O_RDWR, int mode = 0644, int buckets = -1, int directories = -1)
ALIAS:
    new = 1
PREINIT:
    CURIA* dbp;
    int o_flags;
CODE:
    RETVAL = NULL;
    o_flags = ( (flags & O_WRONLY) || (flags & O_RDWR) ) ? CR_OWRITER : CR_OREADER;
    if (flags & O_CREAT) o_flags |= CR_OCREAT;
    if (flags & O_TRUNC) o_flags |= CR_OTRUNC;
    dbp = cropen(filename, o_flags, buckets, directories);
    if (NULL != dbp) {
        Newxz(RETVAL, 1, QDBM_File_type);
        RETVAL->dbp = (void*)dbp;
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
DESTROY(QDBM_File db)
CODE:
    if (db) {
        if ( crclose( crptr(db) ) ) {
            if (db->comparer)           SvREFCNT_dec(db->comparer);
            if (db->filter_fetch_key)   SvREFCNT_dec(db->filter_fetch_key);
            if (db->filter_store_key)   SvREFCNT_dec(db->filter_store_key);
            if (db->filter_fetch_value) SvREFCNT_dec(db->filter_fetch_value);
            if (db->filter_store_value) SvREFCNT_dec(db->filter_store_value);
            Safefree(db);
        }
        else {
            croak( "qdbm close error: %s\n", dperrmsg(dpecode) );
        }
    }

datum_value
FETCH(QDBM_File db, datum_key key, int start = 0, int offset = -1)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    char* value;
CODE:
    kbyte = SvPV_const(key, ksize);
    value = crget( crptr(db), kbyte, (int)ksize, start, offset, &vsize );
    if (NULL != value) {
        RETVAL = newSVpvn(value, (STRLEN)vsize);
        cbfree(value);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
STORE(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_cr(db, key, value, CR_DOVER);
OUTPUT:
    RETVAL

bool
store_keep(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_cr(db, key, value, CR_DKEEP);
OUTPUT:
    RETVAL

bool
store_cat(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_cr(db, key, value, CR_DCAT);
OUTPUT:
    RETVAL

bool
DELETE(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
CODE:
    kbyte = SvPV_const(key, ksize);
    RETVAL = crout( crptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
EXISTS(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
CODE:
    kbyte = SvPV_const(key, ksize);
    vsize = crvsiz( crptr(db), kbyte, (int)ksize );
    RETVAL = (-1 != vsize);
OUTPUT:
    RETVAL

datum_key
FIRSTKEY(QDBM_File db)
PREINIT:
    int ksize;
    char* key;
CODE:
    if ( criterinit( crptr(db) ) ) {
        key = criternext( crptr(db), &ksize );
        if (NULL != key) {
            RETVAL = newSVpvn(key, (STRLEN)ksize);
            cbfree(key);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

datum_key
NEXTKEY(QDBM_File db, datum_key prev_key)
PREINIT:
    int ksize;
    char* key;
CODE:
    key = criternext( crptr(db), &ksize );
    if (NULL != key) {
        RETVAL = newSVpvn(key, (STRLEN)ksize);
        cbfree(key);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
set_align(QDBM_File db, int align)
CODE:
    RETVAL = crsetalign( crptr(db), align );
OUTPUT:
    RETVAL

bool
set_fbp_size(QDBM_File db, int size)
CODE:
    RETVAL = crsetfbpsiz( crptr(db), size);
OUTPUT:
    RETVAL

bool
sync(QDBM_File db)
CODE:
    RETVAL = crsync( crptr(db) );
OUTPUT:
    RETVAL

bool
optimize(QDBM_File db, int buckets = -1)
CODE:
    RETVAL = croptimize( crptr(db), buckets );
OUTPUT:
    RETVAL

int
get_record_size(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
CODE:
    kbyte = SvPV_const(key, ksize);
    RETVAL = crvsiz( crptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
init_iterator(QDBM_File db)
CODE:
    RETVAL = criterinit( crptr(db) );
OUTPUT:
    RETVAL

SV*
get_name(QDBM_File db)
PREINIT:
    char* name;
CODE:
    name = crname( crptr(db) );
    if (NULL != name) {
        RETVAL = newSVpv(name, 0);
        cbfree(name);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

int
get_size(QDBM_File db)
CODE:
    RETVAL = crfsiz( crptr(db) );
OUTPUT:
    RETVAL

int
count_buckets(QDBM_File db)
CODE:
    RETVAL = crbnum( crptr(db) );
OUTPUT:
    RETVAL

int
count_used_buckets(QDBM_File db)
CODE:
    RETVAL = crbusenum( crptr(db) );
OUTPUT:
    RETVAL

int
count_records(QDBM_File db)
ALIAS:
    SCALAR = 1
CODE:
    RETVAL = crrnum( crptr(db) );
OUTPUT:
    RETVAL

bool
is_writable(QDBM_File db)
CODE:
    RETVAL = crwritable( crptr(db) );
OUTPUT:
    RETVAL

bool
is_fatal_error(QDBM_File db)
CODE:
    RETVAL = crfatalerror( crptr(db) );
OUTPUT:
    RETVAL

const char*
get_error(SV* package)
CODE:
    RETVAL = dperrmsg(dpecode);
OUTPUT:
    RETVAL

time_t
get_mtime(QDBM_File db)
CODE:
    RETVAL = crmtime( crptr(db) );
OUTPUT:
    RETVAL

bool
repair(SV* package, char* filename)
CODE:
    if ( sv_isobject(package) ) {
        warn("qdbm repair warning: called via instance method\n");
    }
    RETVAL = crrepair(filename);
OUTPUT:
    RETVAL

bool
export_db(QDBM_File db, char* filename)
CODE:
    RETVAL = crexportdb( crptr(db), filename );
OUTPUT:
    RETVAL

bool
import_db(QDBM_File db, char* filename)
CODE:
    RETVAL = crimportdb( crptr(db), filename );
OUTPUT:
    RETVAL

datum_value
fetch_lob(QDBM_File db, datum_key key, int start = 0, int offset = -1)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    char* value;
CODE:
    kbyte = SvPV_const(key, ksize);
    value = crgetlob( crptr(db), kbyte, (int)ksize, start, offset, &vsize );
    if (NULL != value) {
        RETVAL = newSVpvn(value, (STRLEN)vsize);
        cbfree(value);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
store_lob(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_crlob(db, key, value, CR_DOVER);
OUTPUT:
    RETVAL

bool
store_keep_lob(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_crlob(db, key, value, CR_DKEEP);
OUTPUT:
    RETVAL

bool
store_cat_lob(QDBM_File db, datum_key key, datum_value value)
CODE:
    RETVAL = store_crlob(db, key, value, CR_DCAT);
OUTPUT:
    RETVAL

bool
delete_lob(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
CODE:
    kbyte = SvPV_const(key, ksize);
    RETVAL = croutlob( crptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
exists_lob(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
CODE:
    kbyte = SvPV_const(key, ksize);
    vsize = crvsizlob( crptr(db), kbyte, (int)ksize );
    RETVAL = (-1 != vsize);
OUTPUT:
    RETVAL

int
count_lob_records(QDBM_File db)
CODE:
    RETVAL = crrnumlob( crptr(db) );
OUTPUT:
    RETVAL

MODULE = QDBM_File    PACKAGE = QDBM_File::BTree

INCLUDE: dbm_filter.xsh

QDBM_File
TIEHASH(char* dbtype, char* filename, int flags = O_CREAT|O_RDWR, int mode = 0644, SV* comparer = &PL_sv_undef)
ALIAS:
    new = 1
PREINIT:
    VILLA* dbp;
    int o_flags;
    VLCFUNC cmpptr;
CODE:
    RETVAL = NULL;
    cmpptr = SvOK(comparer) ? btree_compare : VL_CMPLEX;
    o_flags = ( (flags & O_WRONLY) || (flags & O_RDWR) ) ? VL_OWRITER : VL_OREADER;
    if (flags & O_CREAT) o_flags |= VL_OCREAT;
    if (flags & O_TRUNC) o_flags |= VL_OTRUNC;

    dbp = vlopen(filename, o_flags, cmpptr);

    if (NULL != dbp) {
        Newxz(RETVAL, 1, QDBM_File_type);
        RETVAL->dbp = (void*)dbp;
        RETVAL->comparer = newSVsv(comparer);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
DESTROY(QDBM_File db)
CODE:
    if (db) {
        if ( vlclose( vlptr(db) ) ) {
            if (db->comparer)           SvREFCNT_dec(db->comparer);
            if (db->filter_fetch_key)   SvREFCNT_dec(db->filter_fetch_key);
            if (db->filter_store_key)   SvREFCNT_dec(db->filter_store_key);
            if (db->filter_fetch_value) SvREFCNT_dec(db->filter_fetch_value);
            if (db->filter_store_value) SvREFCNT_dec(db->filter_store_value);
            Safefree(db);
        }
        else {
            croak( "qdbm close error: %s\n", dperrmsg(dpecode) );
        }
    }

datum_value
FETCH(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    char* value;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    value = vlget( vlptr(db), kbyte, (int)ksize, &vsize );

    if (NULL != value) {
        RETVAL = newSVpvn(value, (STRLEN)vsize);
        cbfree(value);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
STORE(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vl(db, key, value, VL_DOVER);
OUTPUT:
    RETVAL

bool
store_keep(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vl(db, key, value, VL_DKEEP);
OUTPUT:
    RETVAL

bool
store_cat(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vl(db, key, value, VL_DCAT);
OUTPUT:
    RETVAL

bool
store_dup(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vl(db, key, value, VL_DDUP);
OUTPUT:
    RETVAL

bool
store_dupr(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vl(db, key, value, VL_DDUPR);
OUTPUT:
    RETVAL

bool
DELETE(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vlout( vlptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
EXISTS(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    vsize = vlvsiz( vlptr(db), kbyte, (int)ksize );
    RETVAL = (-1 != vsize);
OUTPUT:
    RETVAL

datum_key
FIRSTKEY(QDBM_File db)
PREINIT:
    int ksize;
    char* key;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    if ( vlcurfirst( vlptr(db) ) ) {
        key = vlcurkey( vlptr(db), &ksize );
        if (NULL != key) {
            RETVAL = newSVpvn(key, (STRLEN)ksize);
            cbfree(key);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

datum_key
NEXTKEY(QDBM_File db, datum_key prev_key)
PREINIT:
    int ksize;
    char* key;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    if ( vlcurnext( vlptr(db) ) ) {
        key = vlcurkey( vlptr(db), &ksize );
        if (NULL != key) {
            RETVAL = newSVpvn(key, (STRLEN)ksize);
            cbfree(key);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

int
get_record_size(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vlvsiz( vlptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

int
count_match_records(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vlvnum( vlptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
delete_list(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vloutlist( vlptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

void
fetch_list(QDBM_File db, datum_key key)
PREINIT:
    int i;
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    const char* value;
    CBLIST* list;
    SV* value_sv;
    dMY_CXT;
PPCODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    list = vlgetlist( vlptr(db), kbyte, (int)ksize );

    if (NULL != list) {
        for (i = 0; i < cblistnum(list); i++) {
            value = cblistval(list, i, &vsize);
            value_sv = newSVpvn(value, (STRLEN)vsize);
            DBM_ckFilter(value_sv, filter_fetch_value, "filter_fetch_value");
            XPUSHs( sv_2mortal(value_sv) );
        }
        cblistclose(list);
    }
    else {
        XSRETURN_EMPTY;
    }

bool
store_list(QDBM_File db, datum_key key, ...)
PREINIT:
    int i;
    STRLEN ksize;
    const char* kbyte;
    STRLEN vsize;
    const char* vbyte;
    CBLIST* list;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    list = cblistopen();
    for (i = 2; i < items; i++) {
        DBM_ckFilter( ST(i), filter_store_value, "filter_store_value" );
        SvGETMAGIC( ST(i) );
        sv_utf8_downgrade( ST(i), 0 );
        vbyte = SvPV_const( ST(i), vsize );
        cblistpush(list, vbyte, (int)vsize);
    }
    kbyte = SvPV_const(key, ksize);
    RETVAL = vlputlist( vlptr(db), kbyte, (int)ksize, list );
OUTPUT:
    RETVAL
CLEANUP:
    cblistclose(list);

bool
init_iterator(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlcurfirst( vlptr(db) );
OUTPUT:
    RETVAL

bool
move_first(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlcurfirst( vlptr(db) );
OUTPUT:
    RETVAL

bool
move_last(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlcurlast( vlptr(db) );
OUTPUT:
    RETVAL

bool
move_next(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlcurnext( vlptr(db) );
OUTPUT:
    RETVAL

bool
move_prev(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlcurprev( vlptr(db) );
OUTPUT:
    RETVAL

bool
move_forward(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vlcurjump( vlptr(db), kbyte, (int)ksize, VL_JFORWARD );
OUTPUT:
    RETVAL

bool
move_backword(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vlcurjump( vlptr(db), kbyte, (int)ksize, VL_JBACKWARD );
OUTPUT:
    RETVAL

datum_key
get_current_key(QDBM_File db)
PREINIT:
    int ksize;
    char* key;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    key = vlcurkey( vlptr(db), &ksize );
    if (NULL != key) {
        RETVAL = newSVpvn(key, (STRLEN)ksize);
        cbfree(key);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

datum_key
get_current_value(QDBM_File db)
PREINIT:
    int vsize;
    char* value;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    value = vlcurval( vlptr(db), &vsize );
    if (NULL != value) {
        RETVAL = newSVpvn(value, (STRLEN)vsize);
        cbfree(value);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
store_current(QDBM_File db, datum_value value)
PREINIT:
    STRLEN vsize;
    const char* vbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    vbyte = SvPV_const(value, vsize);
    RETVAL = vlcurput(
        vlptr(db),
        vbyte,
        (int)vsize,
        VL_CPCURRENT
    );
OUTPUT:
    RETVAL

bool
store_after(QDBM_File db, datum_value value)
PREINIT:
    STRLEN vsize;
    const char* vbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    vbyte = SvPV_const(value, vsize);
    RETVAL = vlcurput(
        vlptr(db),
        vbyte,
        (int)vsize,
        VL_CPAFTER
    );
OUTPUT:
    RETVAL

bool
store_before(QDBM_File db, datum_value value)
PREINIT:
    STRLEN vsize;
    const char* vbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    vbyte = SvPV_const(value, vsize);
    RETVAL = vlcurput(
        vlptr(db),
        vbyte,
        (int)vsize,
        VL_CPBEFORE
    );
OUTPUT:
    RETVAL

bool
delete_current(QDBM_File db, datum_key key)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlcurout( vlptr(db) );
OUTPUT:
    RETVAL

void
set_tuning(QDBM_File db, int max_leaf_record, int max_non_leaf_index, int max_cache_leaf, int max_cache_non_leaf)
CODE:
    vlsettuning( vlptr(db), max_leaf_record, max_non_leaf_index, max_cache_leaf, max_cache_non_leaf );

bool
set_fbp_size(QDBM_File db, int size)
CODE:
    RETVAL = vlsetfbpsiz( vlptr(db), size );
OUTPUT:
    RETVAL

bool
sync(QDBM_File db)
CODE:
    RETVAL = vlsync( vlptr(db) );
OUTPUT:
    RETVAL

bool
optimize(QDBM_File db)
CODE:
    RETVAL = vloptimize( vlptr(db) );
OUTPUT:
    RETVAL

SV*
get_name(QDBM_File db)
PREINIT:
    char* name;
CODE:
    name = vlname( vlptr(db) );
    if (NULL != name) {
        RETVAL = newSVpv(name, 0);
        cbfree(name);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

int
get_size(QDBM_File db)
CODE:
    RETVAL = vlfsiz( vlptr(db) );
OUTPUT:
    RETVAL

int
count_leafs(QDBM_File db)
CODE:
    RETVAL = vllnum( vlptr(db) );
OUTPUT:
    RETVAL

int
count_non_leafs(QDBM_File db)
CODE:
    RETVAL = vlnnum( vlptr(db) );
OUTPUT:
    RETVAL

int
count_records(QDBM_File db)
ALIAS:
    SCALAR = 1
CODE:
    RETVAL = vlrnum( vlptr(db) );
OUTPUT:
    RETVAL

bool
is_writable(QDBM_File db)
CODE:
    RETVAL = vlwritable( vlptr(db) );
OUTPUT:
    RETVAL

bool
is_fatal_error(QDBM_File db)
CODE:
    RETVAL = vlfatalerror( vlptr(db) );
OUTPUT:
    RETVAL

const char*
get_error(SV* package)
CODE:
    RETVAL = dperrmsg(dpecode);
OUTPUT:
    RETVAL

time_t
get_mtime(QDBM_File db)
CODE:
    RETVAL = vlmtime( vlptr(db) );
OUTPUT:
    RETVAL

bool
begin_transaction(QDBM_File db)
CODE:
    RETVAL = vltranbegin( vlptr(db) );
OUTPUT:
    RETVAL

bool
commit(QDBM_File db)
CODE:
    RETVAL = vltrancommit( vlptr(db) );
OUTPUT:
    RETVAL

bool
rollback(QDBM_File db)
CODE:
    RETVAL = vltranabort( vlptr(db) );
OUTPUT:
    RETVAL

bool
repair(SV* package, char* filename, SV* comparer = &PL_sv_undef)
PREINIT:
    VLCFUNC cmpptr;
    dMY_CXT;
CODE:
    cmpptr = SvOK(comparer) ? btree_compare : VL_CMPLEX;
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = comparer;
    if ( sv_isobject(package) ) {
        warn("qdbm repair warning: called via instance method\n");
    }
    RETVAL = vlrepair(filename, cmpptr);
OUTPUT:
    RETVAL

bool
export_db(QDBM_File db, char* filename)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlexportdb( vlptr(db), filename );
OUTPUT:
    RETVAL

bool
import_db(QDBM_File db, char* filename)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vlimportdb( vlptr(db), filename );
OUTPUT:
    RETVAL

MODULE = QDBM_File    PACKAGE = QDBM_File::BTree::Multiple

INCLUDE: dbm_filter.xsh

QDBM_File
TIEHASH(char* dbtype, char* filename, int flags = O_CREAT|O_RDWR, int mode = 0644, SV* comparer = &PL_sv_undef)
ALIAS:
    new = 1
PREINIT:
    VISTA* dbp;
    int o_flags;
    VSTCFUNC cmpptr;
CODE:
    RETVAL = NULL;
    cmpptr = SvOK(comparer) ? btree_compare : VST_CMPLEX;
    o_flags = ( (flags & O_WRONLY) || (flags & O_RDWR) ) ? VST_OWRITER : VST_OREADER;
    if (flags & O_CREAT) o_flags |= VST_OCREAT;
    if (flags & O_TRUNC) o_flags |= VST_OTRUNC;

    dbp = vstopen(filename, o_flags, cmpptr);

    if (NULL != dbp) {
        Newxz(RETVAL, 1, QDBM_File_type);
        RETVAL->dbp = (void*)dbp;
        RETVAL->comparer = newSVsv(comparer);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
DESTROY(QDBM_File db)
CODE:
    if (db) {
        if ( vstclose( vstptr(db) ) ) {
            if (db->comparer)           SvREFCNT_dec(db->comparer);
            if (db->filter_fetch_key)   SvREFCNT_dec(db->filter_fetch_key);
            if (db->filter_store_key)   SvREFCNT_dec(db->filter_store_key);
            if (db->filter_fetch_value) SvREFCNT_dec(db->filter_fetch_value);
            if (db->filter_store_value) SvREFCNT_dec(db->filter_store_value);
            Safefree(db);
        }
        else {
            croak( "qdbm close error: %s\n", dperrmsg(dpecode) );
        }
    }

datum_value
FETCH(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    char* value;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    value = vstget( vstptr(db), kbyte, (int)ksize, &vsize );

    if (NULL != value) {
        RETVAL = newSVpvn(value, (STRLEN)vsize);
        cbfree(value);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
STORE(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vst(db, key, value, VST_DOVER);
OUTPUT:
    RETVAL

bool
store_keep(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vst(db, key, value, VST_DKEEP);
OUTPUT:
    RETVAL

bool
store_cat(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vst(db, key, value, VST_DCAT);
OUTPUT:
    RETVAL

bool
store_dup(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vst(db, key, value, VST_DDUP);
OUTPUT:
    RETVAL

bool
store_dupr(QDBM_File db, datum_key key, datum_value value)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = store_vst(db, key, value, VST_DDUPR);
OUTPUT:
    RETVAL

bool
DELETE(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vstout( vstptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
EXISTS(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    vsize = vstvsiz( vstptr(db), kbyte, (int)ksize );
    RETVAL = (-1 != vsize);
OUTPUT:
    RETVAL

datum_key
FIRSTKEY(QDBM_File db)
PREINIT:
    int ksize;
    char* key;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    if ( vstcurfirst( vstptr(db) ) ) {
        key = vstcurkey( vstptr(db), &ksize );
        if (NULL != key) {
            RETVAL = newSVpvn(key, (STRLEN)ksize);
            cbfree(key);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

datum_key
NEXTKEY(QDBM_File db, datum_key prev_key)
PREINIT:
    int ksize;
    char* key;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    if ( vstcurnext( vstptr(db) ) ) {
        key = vstcurkey( vstptr(db), &ksize );
        if (NULL != key) {
            RETVAL = newSVpvn(key, (STRLEN)ksize);
            cbfree(key);
        }
        else {
            XSRETURN_UNDEF;
        }
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

int
get_record_size(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vstvsiz( vstptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

int
count_match_records(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vstvnum( vstptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

bool
delete_list(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vstoutlist( vstptr(db), kbyte, (int)ksize );
OUTPUT:
    RETVAL

void
fetch_list(QDBM_File db, datum_key key)
PREINIT:
    int i;
    STRLEN ksize;
    const char* kbyte;
    int vsize;
    const char* value;
    CBLIST* list;
    SV* value_sv;
    dMY_CXT;
PPCODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    list = vstgetlist( vstptr(db), kbyte, (int)ksize );

    if (NULL != list) {
        for (i = 0; i < cblistnum(list); i++) {
            value = cblistval(list, i, &vsize);
            value_sv = newSVpvn(value, (STRLEN)vsize);
            DBM_ckFilter(value_sv, filter_fetch_value, "filter_fetch_value");
            XPUSHs( sv_2mortal(value_sv) );
        }
        cblistclose(list);
    }
    else {
        XSRETURN_EMPTY;
    }

bool
store_list(QDBM_File db, datum_key key, ...)
PREINIT:
    int i;
    STRLEN ksize;
    const char* kbyte;
    STRLEN vsize;
    const char* vbyte;
    CBLIST* list;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    list = cblistopen();
    for (i = 2; i < items; i++) {
        DBM_ckFilter( ST(i), filter_store_value, "filter_store_value" );
        SvGETMAGIC( ST(i) );
        sv_utf8_downgrade( ST(i), 0 );
        vbyte = SvPV_const( ST(i), vsize );
        cblistpush(list, vbyte, (int)vsize);
    }
    kbyte = SvPV_const(key, ksize);
    RETVAL = vstputlist( vstptr(db), kbyte, (int)ksize, list );
OUTPUT:
    RETVAL
CLEANUP:
    cblistclose(list);

bool
init_iterator(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstcurfirst( vstptr(db) );
OUTPUT:
    RETVAL

bool
move_first(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstcurfirst( vstptr(db) );
OUTPUT:
    RETVAL

bool
move_last(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstcurlast( vstptr(db) );
OUTPUT:
    RETVAL

bool
move_next(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstcurnext( vstptr(db) );
OUTPUT:
    RETVAL

bool
move_prev(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstcurprev( vstptr(db) );
OUTPUT:
    RETVAL

bool
move_forward(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vstcurjump( vstptr(db), kbyte, (int)ksize, VST_JFORWARD );
OUTPUT:
    RETVAL

bool
move_backword(QDBM_File db, datum_key key)
PREINIT:
    STRLEN ksize;
    const char* kbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    kbyte = SvPV_const(key, ksize);
    RETVAL = vstcurjump( vstptr(db), kbyte, (int)ksize, VST_JBACKWARD );
OUTPUT:
    RETVAL

datum_key
get_current_key(QDBM_File db)
PREINIT:
    int ksize;
    char* key;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    key = vstcurkey( vstptr(db), &ksize );
    if (NULL != key) {
        RETVAL = newSVpvn(key, (STRLEN)ksize);
        cbfree(key);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

datum_key
get_current_value(QDBM_File db)
PREINIT:
    int vsize;
    char* value;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    value = vstcurval( vstptr(db), &vsize );
    if (NULL != value) {
        RETVAL = newSVpvn(value, (STRLEN)vsize);
        cbfree(value);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
store_current(QDBM_File db, datum_value value)
PREINIT:
    STRLEN vsize;
    const char* vbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    vbyte = SvPV_const(value, vsize);
    RETVAL = vstcurput(
        vstptr(db),
        vbyte,
        (int)vsize,
        VL_CPCURRENT
    );
OUTPUT:
    RETVAL

bool
store_after(QDBM_File db, datum_value value)
PREINIT:
    STRLEN vsize;
    const char* vbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    vbyte = SvPV_const(value, vsize);
    RETVAL = vstcurput(
        vstptr(db),
        vbyte,
        (int)vsize,
        VL_CPAFTER
    );
OUTPUT:
    RETVAL

bool
store_before(QDBM_File db, datum_value value)
PREINIT:
    STRLEN vsize;
    const char* vbyte;
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    vbyte = SvPV_const(value, vsize);
    RETVAL = vstcurput(
        vstptr(db),
        vbyte,
        (int)vsize,
        VL_CPBEFORE
    );
OUTPUT:
    RETVAL

bool
delete_current(QDBM_File db)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstcurout( vstptr(db) );
OUTPUT:
    RETVAL

void
set_tuning(QDBM_File db, int max_leaf_record, int max_non_leaf_index, int max_cache_leaf, int max_cache_non_leaf)
CODE:
    vstsettuning( vstptr(db), max_leaf_record, max_non_leaf_index, max_cache_leaf, max_cache_non_leaf );

bool
set_fbp_size(QDBM_File db, int size)
CODE:
    RETVAL = vstsetfbpsiz( vstptr(db), size );
OUTPUT:
    RETVAL

bool
sync(QDBM_File db)
CODE:
    RETVAL = vstsync( vstptr(db) );
OUTPUT:
    RETVAL

bool
optimize(QDBM_File db)
CODE:
    RETVAL = vstoptimize( vstptr(db) );
OUTPUT:
    RETVAL

SV*
get_name(QDBM_File db)
PREINIT:
    char* name;
CODE:
    name = vstname( vstptr(db) );
    if (NULL != name) {
        RETVAL = newSVpv(name, 0);
        cbfree(name);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

int
get_size(QDBM_File db)
CODE:
    RETVAL = vstfsiz( vstptr(db) );
OUTPUT:
    RETVAL

int
count_leafs(QDBM_File db)
CODE:
    RETVAL = vstlnum( vstptr(db) );
OUTPUT:
    RETVAL

int
count_non_leafs(QDBM_File db)
CODE:
    RETVAL = vstnnum( vstptr(db) );
OUTPUT:
    RETVAL

int
count_records(QDBM_File db)
ALIAS:
    SCALAR = 1
CODE:
    RETVAL = vstrnum( vstptr(db) );
OUTPUT:
    RETVAL

bool
is_writable(QDBM_File db)
CODE:
    RETVAL = vstwritable( vstptr(db) );
OUTPUT:
    RETVAL

const char*
get_error(SV* package)
CODE:
    RETVAL = dperrmsg(dpecode);
OUTPUT:
    RETVAL

bool
is_fatal_error(QDBM_File db)
CODE:
    RETVAL = vstfatalerror( vstptr(db) );
OUTPUT:
    RETVAL

time_t
get_mtime(QDBM_File db)
CODE:
    RETVAL = vstmtime( vstptr(db) );
OUTPUT:
    RETVAL

bool
begin_transaction(QDBM_File db)
CODE:
    RETVAL = vsttranbegin( vstptr(db) );
OUTPUT:
    RETVAL

bool
commit(QDBM_File db)
CODE:
    RETVAL = vsttrancommit( vstptr(db) );
OUTPUT:
    RETVAL

bool
rollback(QDBM_File db)
CODE:
    RETVAL = vsttranabort( vstptr(db) );
OUTPUT:
    RETVAL

bool
repair(SV* package, char* filename, SV* comparer = &PL_sv_undef)
PREINIT:
    VSTCFUNC cmpptr;
    dMY_CXT;
CODE:
    cmpptr = SvOK(comparer) ? btree_compare : VST_CMPLEX;
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = comparer;
    if ( sv_isobject(package) ) {
        warn("qdbm repair warning: called via instance method\n");
    }
    RETVAL = vstrepair(filename, cmpptr);
OUTPUT:
    RETVAL

bool
export_db(QDBM_File db, char* filename)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstexportdb( vstptr(db), filename );
OUTPUT:
    RETVAL

bool
import_db(QDBM_File db, char* filename)
PREINIT:
    dMY_CXT;
CODE:
    SAVESPTR(MY_CXT.comparer);
    MY_CXT.comparer = db->comparer;
    RETVAL = vstimportdb( vstptr(db), filename );
OUTPUT:
    RETVAL

MODULE = QDBM_File    PACKAGE = QDBM_File::InvertedIndex

ODEUM*
new(char* dbtype, char* filename, int flags = O_CREAT|O_RDWR)
PREINIT:
    int o_flags;
CODE:
    o_flags = ( (flags & O_WRONLY) || (flags & O_RDWR) ) ? OD_OWRITER : OD_OREADER;
    if (flags & O_CREAT) o_flags |= OD_OCREAT;
    if (flags & O_TRUNC) o_flags |= OD_OTRUNC;

    RETVAL = odopen(filename, o_flags);
    if (NULL == RETVAL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
DESTROY(ODEUM* db)
CODE:
    if (db) {
        if ( !odclose(db) ) {
            croak( "qdbm close error: %s\n", dperrmsg(dpecode) );
        }
    }

bool
store_document(ODEUM* db, ODDOC* doc, int max_words = -1, bool over = (bool)TRUE)
CODE:
    RETVAL = odput(db, doc, max_words, over);
OUTPUT:
    RETVAL

bool
delete_document_by_uri(ODEUM* db, const char* uri)
CODE:
    RETVAL = odout(db, uri);
OUTPUT:
    RETVAL

bool
delete_document_by_id(ODEUM* db, int id)
CODE:
    RETVAL = odoutbyid(db, id);
OUTPUT:
    RETVAL

ODDOC*
get_document_by_uri(ODEUM* db, const char* uri)
CODE:
    RETVAL = odget(db, uri);
    if (NULL == RETVAL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

ODDOC*
get_document_by_id(ODEUM* db, int id)
CODE:
    RETVAL = odgetbyid(db, id);
    if (NULL == RETVAL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

int
get_document_id(ODEUM* db, const char* uri)
CODE:
    RETVAL = odgetidbyuri(db, uri);
OUTPUT:
    RETVAL

bool
exists_document_by_uri(ODEUM* db, const char* uri)
CODE:
    RETVAL = ( -1 != odgetidbyuri(db, uri) );
OUTPUT:
    RETVAL

bool
exists_document_by_id(ODEUM* db, int id)
CODE:
    RETVAL = odcheck(db, id);
OUTPUT:
    RETVAL

void
search_document(ODEUM* db, const char* word, int max = -1)
PREINIT:
    int i;
    int length;
    ODPAIR* pair;
PPCODE:
    pair = odsearch(db, word, max, &length);
    if (NULL != pair) {
        for (i = 0; i < length; i++) {
            mXPUSHi(pair[i].id);
        }
        cbfree(pair);
    }
    else {
        XSRETURN_EMPTY;
    }

int
search_document_count(ODEUM* db, const char* word)
CODE:
    RETVAL = odsearchdnum(db, word);
OUTPUT:
    RETVAL

bool
init_iterator(ODEUM* db)
CODE:
    RETVAL = oditerinit(db);
OUTPUT:
    RETVAL

ODDOC*
get_next_document(ODEUM* db)
CODE:
    RETVAL = oditernext(db);
    if (NULL == RETVAL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

bool
sync(ODEUM* db)
CODE:
    RETVAL = odsync(db);
OUTPUT:
    RETVAL

bool
optimize(ODEUM* db)
CODE:
    RETVAL = odoptimize(db);
OUTPUT:
    RETVAL

SV*
get_name(ODEUM* db)
PREINIT:
    char* name;
CODE:
    name = odname(db);
    if (NULL != name) {
        RETVAL = newSVpv(name, 0);
        cbfree(name);
    }
    else {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

double
get_size(ODEUM* db)
CODE:
    RETVAL = odfsiz(db);
OUTPUT:
    RETVAL

int
count_buckets(ODEUM* db)
CODE:
    RETVAL = odbnum(db);
OUTPUT:
    RETVAL

int
count_used_buckets(ODEUM* db)
CODE:
    RETVAL = odbusenum(db);
OUTPUT:
    RETVAL

int
count_documents(ODEUM* db)
CODE:
    RETVAL = oddnum(db);
OUTPUT:
    RETVAL

int
count_words(ODEUM* db)
CODE:
    RETVAL = odwnum(db);
OUTPUT:
    RETVAL

bool
is_writable(ODEUM* db)
CODE:
    RETVAL = odwritable(db);
OUTPUT:
    RETVAL

bool
is_fatal_error(ODEUM* db)
CODE:
    RETVAL = odfatalerror(db);
OUTPUT:
    RETVAL

const char*
get_error(SV* package)
CODE:
    RETVAL = dperrmsg(dpecode);
OUTPUT:
    RETVAL

time_t
get_mtime(ODEUM* db)
CODE:
    RETVAL = odmtime(db);
OUTPUT:
    RETVAL

bool
merge(SV* package, const char* name, ...)
PREINIT:
    int i;
    STRLEN elemsize;
    const char* elembyte;
    CBLIST* elemnames;
CODE:
    if ( sv_isobject(package) ) {
        warn("qdbm merge warning: called via instance method\n");
    }
    else {
        elemnames = cblistopen();
        for (i = 2; i < items; i++) {
            SvGETMAGIC( ST(i) );
            sv_utf8_downgrade( ST(i), 0 );
            elembyte = SvPV_const( ST(i), elemsize );
            cblistpush(elemnames, elembyte, (int)elemsize);
        }
        RETVAL = odmerge(name, elemnames);
    }
OUTPUT:
    RETVAL

void
_get_scores(ODEUM* db, ODDOC* doc, int max)
PREINIT:
    const char* key;
    const char* value;
    int ksize;
    int vsize;
    CBMAP* scores;
PPCODE:
    scores = oddocscores(doc, max, db);
    if ( 0 == cbmaprnum(scores) ) {
        cbmapclose(scores);
        XSRETURN_EMPTY;
    }
    else {
        cbmapiterinit(scores);
        while ( NULL != ( key = cbmapiternext(scores, &ksize) ) ) {
            value = cbmapiterval(key, &vsize);
            XPUSHs( sv_2mortal( newSVpvn(key, (STRLEN)ksize) ) );
            XPUSHs( sv_2mortal( newSVpvn(value, (STRLEN)vsize) ) );
        }
        cbmapclose(scores);
    }

void
set_tuning(SV* package, int index_buckets, int inverted_index_division_num, int dirty_buffer_buckets, int dirty_buffer_size)
CODE:
    if ( sv_isobject(package) ) {
        warn("qdbm set_tuning warning: called via instance method\n");
    }
    else {
        odsettuning(
            index_buckets,
            inverted_index_division_num,
            dirty_buffer_buckets,
            dirty_buffer_size
        );
    }

void
set_char_class(ODEUM* db, const char* space, const char* delimiter, const char* glue)
CODE:
    odsetcharclass(db, space, delimiter, glue);

void
analyze_text(SV* self, const char* text)
PREINIT:
    ODEUM* db;
    int i;
    const char* value;
    int vsize;
    CBLIST* appearance_words;
PPCODE:
    if ( sv_isobject(self) && sv_derived_from(self, "QDBM_File::InvertedIndex") ) {
        db = (ODEUM*)SvIV( (SV*)SvRV(self) );
        appearance_words = cblistopen();
        odanalyzetext(db, text, appearance_words, NULL);
    }
    else {
        appearance_words = odbreaktext(text);
    }
    if ( 0 == cblistnum(appearance_words) ) {
        cblistclose(appearance_words);
        XSRETURN_EMPTY;
    }
    else {
        for (i = 0; i < cblistnum(appearance_words); i++) {
            value = cblistval(appearance_words, i, &vsize);
            XPUSHs( sv_2mortal( newSVpvn(value, (STRLEN)vsize) ) );
        }
        cblistclose(appearance_words);
    }

char*
normalize_word(SV* package, const char* asis)
PREINIT:
    char* normalized_word;
CODE:
    if ( sv_isobject(package) ) {
        warn("qdbm normalize_word warning: called via instance method\n");
    }
    else {
        normalized_word = odnormalizeword(asis);
        RETVAL = normalized_word;
    }
OUTPUT:
    RETVAL
CLEANUP:
    cbfree(normalized_word);

void
query(ODEUM *db, const char* query)
PREINIT:
    int i;
    int length;
    int vsize;
    const char* value;
    ODPAIR* pair;
    SV* errsv;
    CBLIST* errors;
PPCODE:
    errors = cblistopen();
    pair = odquery(db, query, &length, errors);
    if (NULL == pair) {
        errsv = newSVpvn("", (STRLEN)0);
        SAVEMORTALIZESV(errsv);
        for (i = 0; i < cblistnum(errors); i++) {
            value = cblistval(errors, i, &vsize);
            sv_catpv(errsv, "qdbm query warning: ");
            sv_catpv(errsv, value);
            sv_catpv(errsv, "\n");
        }
        cblistclose(errors);
        warn( SvPV_nolen(errsv) );
        XSRETURN_EMPTY;
    }
    else {
        for (i = 0; i < length; i++) {
            mXPUSHi(pair[i].id);
        }
        cblistclose(errors);
        cbfree(pair);
    }

MODULE = QDBM_File    PACKAGE = QDBM_File::InvertedIndex::Document

ODDOC*
new(char* package, char* uri)
CODE:
    RETVAL = oddocopen(uri);
OUTPUT:
    RETVAL

void
set_attribute(ODDOC* doc, const char* name, const char* value)
CODE:
    oddocaddattr(doc, name, value);

const char*
get_attribute(ODDOC* doc, const char* name)
CODE:
    RETVAL = oddocgetattr(doc, name);
    if (NULL == RETVAL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
add_word(ODDOC* doc, const char* normal, const char* asis)
CODE:
    oddocaddword(doc, normal, asis);

int
get_id(ODDOC* doc)
CODE:
    RETVAL = oddocid(doc);
OUTPUT:
    RETVAL

const char*
get_uri(ODDOC* doc)
CODE:
    RETVAL = oddocuri(doc);
OUTPUT:
    RETVAL

void
get_normalized_words(ODDOC* doc)
PREINIT:
    int i;
    const char* value;
    int vsize;
    const CBLIST* words;
PPCODE:
    words = oddocnwords(doc);
    if ( 0 < cblistnum(words) ) {
        for (i = 0; i < cblistnum(words); i++) {
            value = cblistval(words, i, &vsize);
            XPUSHs( sv_2mortal( newSVpvn(value, (STRLEN)vsize) ) );
        }
    }
    else {
        XSRETURN_EMPTY;
    }

void
get_appearance_words(ODDOC* doc)
PREINIT:
    int i;
    const char* value;
    int vsize;
    const CBLIST* words;
PPCODE:
    words = oddocawords(doc);
    if ( 0 < cblistnum(words) ) {
        for (i = 0; i < cblistnum(words); i++) {
            value = cblistval(words, i, &vsize);
            XPUSHs( sv_2mortal( newSVpvn(value, (STRLEN)vsize) ) );
        }
    }
    else {
        XSRETURN_EMPTY;
    }

void
_get_scores(ODDOC* doc, int max, ODEUM* db = NULL)
PREINIT:
    const char* key;
    const char* value;
    int ksize;
    int vsize;
    CBMAP* scores;
PPCODE:
    scores = oddocscores(doc, max, db);
    if ( 0 == cbmaprnum(scores) ) {
        cbmapclose(scores);
        XSRETURN_EMPTY;
    }
    else {
        cbmapiterinit(scores);
        while ( NULL != ( key = cbmapiternext(scores, &ksize) ) ) {
            value = cbmapiterval(key, &vsize);
            XPUSHs( sv_2mortal( newSVpvn(key, (STRLEN)ksize) ) );
            XPUSHs( sv_2mortal( newSVpvn(value, (STRLEN)vsize) ) );
        }
        cbmapclose(scores);
    }

void
DESTROY(ODDOC* doc)
CODE:
    if (doc) {
        oddocclose(doc);
    }
