/* $Id: /mirror/Senna-Perl/lib/Senna.xs 6103 2007-03-16T16:45:50.914799Z daisuke  $
 *
 * Copyright (c) 2005-2007 Daisuke Maki <dmaki@cpan.org>
 * All rights reserved.
 */

/* TODO
 *
 * - Add more tests
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#include "ppport.h"

#include <senna/senna.h>

/* This is defined in senna's sym.h, so don't forget to change accordingly */
#ifndef SEN_SYM_MAX_KEY_LENGTH 
#define SEN_SYM_MAX_KEY_LENGTH 0xffff
#endif

/* This is defined in senna's snip.h. */
#ifndef MAX_SNIP_RESULT_COUNT
#define MAX_SNIP_RESULT_COUNT 8U
#endif

/* XXX - 
 * I can never get this straight.
 * Senna's key_size element, even if you set it to 0 at creation time,
 * returns the actual length of the key.
 */
#define SEN_INT_KEY sizeof(int)
#define SEN_VARCHAR_KEY 0
#define SEN_MAX_KEY_SIZE 8192
#define SEN_MAX_PATH_SIZE 1024

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

#define XS_STRUCT2OBJ(sv, class, obj) \
    sv = newSViv(PTR2IV(obj));  \
    sv = newRV_noinc(sv); \
    sv_bless(sv, gv_stashpv(class, 1)); \
    SvREADONLY_on(sv);

typedef struct sen_perl_snip {
    sen_snip *snip; /* the snip object */
    char     **open_tags;
    size_t    open_tags_size;
    char     **close_tags;
    size_t    close_tags_size;
} sen_perl_snip;

SV *
sen_rc2obj(sen_rc rc)
{
    SV *sv;

    if (GIMME_V == G_VOID) {
        sv = &PL_sv_undef;
    } else {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("Senna::RC", 9)));
        XPUSHs(sv_2mortal(newSViv(rc)));
        PUTBACK;
        if (call_method("Senna::RC::new", G_SCALAR) <= 0) {
            croak ("Senna::RC::new did not return object ");
        }
        SPAGAIN;
        sv = POPs;

        if (! sv_isobject(sv) || ! sv_isa(sv, "Senna::RC")) {
            croak ("Senna::RC::new did not return a proper object");
        }
        sv = newSVsv(sv);

        FREETMPS;
        LEAVE;
    }

    return sv;
}

void
senna_bootstrap()
{
    HV *stash;
    sen_rc rc;

    rc = sen_init();
    if (rc != sen_success)
        croak("Failed to call sen_init(). sen_init() returned %d", rc);

    stash = gv_stashpv("Senna::Constants", 1);

    /* miscellany */
    newCONSTSUB(stash, "LIBSENNA_VERSION", newSVpvf("%d.%d.%d", SENNA_MAJOR_VERSION, SENNA_MINOR_VERSION, SENNA_MICRO_VERSION));

    /* key_size */
    newCONSTSUB(stash, "SEN_VARCHAR_KEY", newSViv(SEN_VARCHAR_KEY));
    newCONSTSUB(stash, "SEN_INT_KEY", newSViv(SEN_INT_KEY));

    /* sen_index_create flags */
    newCONSTSUB(stash, "SEN_INDEX_NORMALIZE", newSViv(SEN_INDEX_NORMALIZE));
    newCONSTSUB(stash, "SEN_INDEX_SPLIT_ALPHA", newSViv(SEN_INDEX_SPLIT_ALPHA));
    newCONSTSUB(stash, "SEN_INDEX_SPLIT_DIGIT", newSViv(SEN_INDEX_SPLIT_DIGIT));
    newCONSTSUB(stash, "SEN_INDEX_SPLIT_SYMBOL", newSViv(SEN_INDEX_SPLIT_SYMBOL));
    newCONSTSUB(stash, "SEN_INDEX_MORPH_ANALYSE", newSViv(SEN_INDEX_MORPH_ANALYSE));
    newCONSTSUB(stash, "SEN_INDEX_NGRAM", newSViv(SEN_INDEX_NGRAM));
    newCONSTSUB(stash, "SEN_INDEX_DELIMITED", newSViv(SEN_INDEX_DELIMITED));
    newCONSTSUB(stash, "SEN_INDEX_ENABLE_SUFFIX_SEARCH", newSViv(SEN_INDEX_ENABLE_SUFFIX_SEARCH));
    newCONSTSUB(stash, "SEN_INDEX_DISABLE_SUFFIX_SEARCH", newSViv(SEN_INDEX_DISABLE_SUFFIX_SEARCH));
    newCONSTSUB(stash, "SEN_INDEX_WITH_VACUUM", newSViv(SEN_INDEX_WITH_VACUUM));

    /* sen_query */
    newCONSTSUB(stash, "SEN_QUERY_AND", newSVpvf("%c", SEN_QUERY_AND));
    newCONSTSUB(stash, "SEN_QUERY_BUT", newSVpvf("%c", SEN_QUERY_BUT));
    newCONSTSUB(stash, "SEN_QUERY_ADJ_INC", newSVpvf("%c", SEN_QUERY_ADJ_INC));
    newCONSTSUB(stash, "SEN_QUERY_ADJ_DEC", newSVpvf("%c", SEN_QUERY_ADJ_DEC));
    newCONSTSUB(stash, "SEN_QUERY_ADJ_NEG", newSVpvf("%c", SEN_QUERY_ADJ_NEG));
    newCONSTSUB(stash, "SEN_QUERY_PREFIX", newSVpvf("%c", SEN_QUERY_PREFIX));
    newCONSTSUB(stash, "SEN_QUERY_PARENL", newSVpvf("%c", SEN_QUERY_PARENL));
    newCONSTSUB(stash, "SEN_QUERY_PARENR", newSVpvf("%c", SEN_QUERY_PARENR));
    newCONSTSUB(stash, "SEN_QUERY_QUOTEL", newSVpvf("%c", SEN_QUERY_QUOTEL));
    newCONSTSUB(stash, "SEN_QUERY_QUOTER", newSVpvf("%c", SEN_QUERY_QUOTER));

    /* sen_rc */
    newCONSTSUB(stash, "SEN_RC_SUCCESS", newSViv(sen_success));
    newCONSTSUB(stash, "SEN_RC_MEMORY_EXHAUSTED", newSViv(sen_memory_exhausted));
    newCONSTSUB(stash, "SEN_RC_INVALID_FORMAT", newSViv(sen_invalid_format));
    newCONSTSUB(stash, "SEN_RC_FILE_ERR", newSViv(sen_file_operation_error));
    newCONSTSUB(stash, "SEN_RC_INVALID_ARG", newSViv(sen_invalid_argument));
    newCONSTSUB(stash, "SEN_RC_OTHER", newSViv(sen_other_error));

    /* sen_encoding */
    newCONSTSUB(stash, "SEN_ENC_DEFAULT", newSViv(sen_enc_default));
    newCONSTSUB(stash, "SEN_ENC_NONE", newSViv(sen_enc_none));
    newCONSTSUB(stash, "SEN_ENC_EUCJP", newSViv(sen_enc_euc_jp));
    newCONSTSUB(stash, "SEN_ENC_UTF8", newSViv(sen_enc_utf8));
    newCONSTSUB(stash, "SEN_ENC_SJIS", newSViv(sen_enc_sjis)); 

    /* sen_rec_unit */
    newCONSTSUB(stash, "SEN_REC_DOCUMENT", newSViv(sen_rec_document));
    newCONSTSUB(stash, "SEN_REC_SECTION", newSViv(sen_rec_section));
    newCONSTSUB(stash, "SEN_REC_POSITION", newSViv(sen_rec_position));
    newCONSTSUB(stash, "SEN_REC_USERDEF", newSViv(sen_rec_userdef));
    newCONSTSUB(stash, "SEN_REC_NONE", newSViv(sen_rec_none));

    /* sen_sel_operator */
    newCONSTSUB(stash, "SEN_SELOP_OR", newSViv(sen_sel_or));
    newCONSTSUB(stash, "SEN_SELOP_AND", newSViv(sen_sel_and));
    newCONSTSUB(stash, "SEN_SELOP_BUT", newSViv(sen_sel_but));
    newCONSTSUB(stash, "SEN_SELOP_ADJUST", newSViv(sen_sel_adjust));

    /* sen_sel_mode */
    newCONSTSUB(stash, "SEN_SELMODE_EXACT", newSViv(sen_sel_exact));
    newCONSTSUB(stash, "SEN_SELMODE_PARTIAL", newSViv(sen_sel_partial));
    newCONSTSUB(stash, "SEN_SELMODE_UNSPLIT", newSViv(sen_sel_unsplit));
    newCONSTSUB(stash, "SEN_SELMODE_NEAR", newSViv(sen_sel_near));
    newCONSTSUB(stash, "SEN_SELMODE_SIMILAR", newSViv(sen_sel_similar));
    newCONSTSUB(stash, "SEN_SELMODE_TERM_EXTRACT", newSViv(sen_sel_term_extract));

    /* sen_sort_mode */
    newCONSTSUB(stash, "SEN_SORT_DESC", newSViv(sen_sort_descending));
    newCONSTSUB(stash, "SEN_SORT_ASC", newSViv(sen_sort_ascending));

    /* sen_log_level */
    newCONSTSUB(stash, "SEN_LOG_NONE", newSViv(sen_log_none));
    newCONSTSUB(stash, "SEN_LOG_EMERG", newSViv(sen_log_emerg));
    newCONSTSUB(stash, "SEN_LOG_ALERT", newSViv(sen_log_alert));
    newCONSTSUB(stash, "SEN_LOG_CRIT", newSViv(sen_log_crit));
    newCONSTSUB(stash, "SEN_LOG_ERROR", newSViv(sen_log_error));
    newCONSTSUB(stash, "SEN_LOG_WARNING", newSViv(sen_log_warning));
    newCONSTSUB(stash, "SEN_LOG_NOTICE", newSViv(sen_log_notice));
    newCONSTSUB(stash, "SEN_LOG_INFO", newSViv(sen_log_info));
    newCONSTSUB(stash, "SEN_LOG_DEBUG", newSViv(sen_log_debug));
    newCONSTSUB(stash, "SEN_LOG_DUMP", newSViv(sen_log_dump));
}

static void
sv2senna_key(sen_index *index, SV *key, void **ret_key)
{
    long *int_key;
    long  int_tmp;
    char *char_key;
    STRLEN len;
    int key_size;

    sen_index_info(index, &key_size, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

    if (key_size == SEN_INT_KEY) {
        if (! SvIOK(key)) {
            croak("index is created with integer keys, but was passed a non-integer key");
        }

        int_tmp  = SvIV(key);
        *ret_key = &int_tmp;
    } else {
        char_key = SvPV(key, len);
        if (len >= SEN_MAX_KEY_SIZE) {
            croak("key length must be less than SENNA_MAX_KEY_SIZE bytes");
        }
        *ret_key = (void *) char_key;
    }
}

static int
sen_sort_optarg_cb(sen_records *r1, const sen_recordh *a,
    sen_records *r2, const sen_recordh *b, void *args)
{
    dSP;
    int key_size;
    void **compar_args = (void *) args;
    int i, section, pos, score, n_subrecs;
    SV *sr1_obj;
    SV *sr2_obj;
    AV *cb_args;
    SV *sv_a;
    SV *sv_b;
    SV *sv_key;
    SV *sv;
    SV **svr;

    cb_args = (AV *) compar_args[1];

    sen_sym_info(r1->keys, &key_size, NULL, NULL, NULL, NULL);
    if (key_size == SEN_VARCHAR_KEY) {
        char key[SEN_MAX_KEY_SIZE];
        sen_record_info(r1, a, key, SEN_MAX_KEY_SIZE, NULL, 
            &section, &pos, &score, &n_subrecs);

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("Senna::Record", 13)));
        XPUSHs(sv_2mortal(newSVpv("key", 3)));
        XPUSHs(sv_2mortal(newSVpv(key, 0)));
        XPUSHs(sv_2mortal(newSVpv("score", 5)));
        XPUSHs(sv_2mortal(newSViv(score)));
        XPUSHs(sv_2mortal(newSVpv("pos", 3)));
        XPUSHs(sv_2mortal(newSViv(pos)));
        XPUSHs(sv_2mortal(newSVpv("section", 7)));
        XPUSHs(sv_2mortal(newSViv(section)));
        XPUSHs(sv_2mortal(newSVpv("n_subrecs", 8)));
        XPUSHs(sv_2mortal(newSViv(n_subrecs)));

        PUTBACK;
        if (! call_method("Senna::Record::new", G_SCALAR) <= 0) {
            croak ("Senna::Record::new did not return object");
        }
        SPAGAIN;
        sv_a = POPs;
        FREETMPS;
        LEAVE;

        if (! sv_isobject(sv) || ! sv_isa(sv, "Senna::Record")) {
            croak ("Senna::Record::new did not return a proper object");
        }

        
        sen_record_info(r2, b, key, SEN_MAX_KEY_SIZE, NULL, 
            &section, &pos, &score, &n_subrecs);

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("Senna::Record", 13)));
        XPUSHs(sv_2mortal(newSVpv("key", 3)));
        XPUSHs(sv_2mortal(newSVpv(key, 0)));
        XPUSHs(sv_2mortal(newSVpv("score", 5)));
        XPUSHs(sv_2mortal(newSViv(score)));
        XPUSHs(sv_2mortal(newSVpv("pos", 3)));
        XPUSHs(sv_2mortal(newSViv(pos)));
        XPUSHs(sv_2mortal(newSVpv("section", 7)));
        XPUSHs(sv_2mortal(newSViv(section)));
        XPUSHs(sv_2mortal(newSVpv("n_subrecs", 8)));
        XPUSHs(sv_2mortal(newSViv(n_subrecs)));

        PUTBACK;
        if (! call_method("Senna::Record::new", G_SCALAR) <= 0) {
            croak ("Senna::Record::new did not return object");
        }
        SPAGAIN;
        sv_b = POPs;
        FREETMPS;
        LEAVE;

        if (! sv_isobject(sv) || ! sv_isa(sv, "Senna::Record")) {
            croak ("Senna::Record::new did not return a proper object");
        }
    } else {
        long key;
        sen_record_info(r1, a, (void *) &key, SEN_INT_KEY, NULL, 
            &section, &pos, &score, &n_subrecs);
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("Senna::Record", 13)));
        XPUSHs(sv_2mortal(newSVpv("key", 3)));
        XPUSHs(sv_2mortal(newSViv(key)));
        XPUSHs(sv_2mortal(newSVpv("score", 5)));
        XPUSHs(sv_2mortal(newSViv(score)));
        XPUSHs(sv_2mortal(newSVpv("pos", 3)));
        XPUSHs(sv_2mortal(newSViv(pos)));
        XPUSHs(sv_2mortal(newSVpv("section", 7)));
        XPUSHs(sv_2mortal(newSViv(section)));
        XPUSHs(sv_2mortal(newSVpv("n_subrecs", 8)));
        XPUSHs(sv_2mortal(newSViv(n_subrecs)));

        PUTBACK;
        if (! call_method("Senna::Record::new", G_SCALAR) <= 0) {
            croak ("Senna::Record::new did not return object");
        }
        SPAGAIN;
        sv_a = POPs;
        FREETMPS;
        LEAVE;

        if (! sv_isobject(sv) || ! sv_isa(sv, "Senna::Record")) {
            croak ("Senna::Record::new did not return a proper object");
        }

        sen_record_info(r2, b, (void *) &key, SEN_INT_KEY, NULL, 
            &section, &pos, &score, &n_subrecs);
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("Senna::Record", 13)));
        XPUSHs(sv_2mortal(newSVpv("key", 3)));
        XPUSHs(sv_2mortal(newSViv(key)));
        XPUSHs(sv_2mortal(newSVpv("score", 5)));
        XPUSHs(sv_2mortal(newSViv(score)));
        XPUSHs(sv_2mortal(newSVpv("pos", 3)));
        XPUSHs(sv_2mortal(newSViv(pos)));
        XPUSHs(sv_2mortal(newSVpv("section", 7)));
        XPUSHs(sv_2mortal(newSViv(section)));
        XPUSHs(sv_2mortal(newSVpv("n_subrecs", 8)));
        XPUSHs(sv_2mortal(newSViv(n_subrecs)));

        PUTBACK;
        if (! call_method("Senna::Record::new", G_SCALAR) <= 0) {
            croak ("Senna::Record::new did not return object");
        }
        SPAGAIN;
        sv_b = POPs;
        FREETMPS;
        LEAVE;

        if (! sv_isobject(sv) || ! sv_isa(sv, "Senna::Record")) {
            croak ("Senna::Record::new did not return a proper object");
        }

    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    sr1_obj = XS_STRUCT2OBJ(sv, "Senna::Results", r1);
    sr2_obj = XS_STRUCT2OBJ(sv, "Senna::Results", r2);
    XPUSHs(sr1_obj);
    XPUSHs(sv_a);
    XPUSHs(sr2_obj);
    XPUSHs(sv_b);
    for(i = 0; i <= av_len(cb_args); i++) {
        svr = av_fetch(cb_args, i, 0);
        if (svr == NULL)
            XPUSHs(&PL_sv_undef);
        else 
            XPUSHs(sv_2mortal(newSVsv(*svr)));
    }

    PUTBACK;
    if (! call_sv((SV *) compar_args[0], G_EVAL|G_SCALAR) <= 0) {
        return 0;
    }

    SPAGAIN;
    sv = POPs;
    FREETMPS;
    LEAVE;

    return SvTRUE(sv) ? 1 : 0;
}

static int
sen_select_optarg_cb(sen_records *r, const void *key, int pid, void *args)
{
    SV *sr_obj;
    SV *cb_pid;
    SV *cb_key;
    AV *cb_args;
    SV *sv;
    SV **svr;
    int key_size;
    int i;
    void **func_args = (void **) args;

    dSP;

    sr_obj = XS_STRUCT2OBJ(sv, "Senna::Results", r);
    cb_pid = newSViv(pid);
    cb_args = (AV *) func_args[1];

    sen_records_rewind(r);
    sen_record_info(r, sen_records_curr_rec(r), NULL, 0, &key_size,
        NULL, NULL, NULL, NULL);
    if (key_size == SEN_INT_KEY) {
        cb_key = newSViv(*((long *) key));
    } else {
        cb_key = newSVpv((char *) key, 0);
    }

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(sr_obj);
    XPUSHs(cb_key);
    XPUSHs(cb_pid);
    for(i = 0; i <= av_len(cb_args); i++) {
        svr = av_fetch(cb_args, i, 0);
        if (svr == NULL)
            XPUSHs(&PL_sv_undef);
        else 
            XPUSHs(sv_2mortal(newSVsv(*svr)));
    }

    PUTBACK;
    if (! call_sv((SV *) func_args[0], G_EVAL|G_SCALAR) <= 0) {
        return 0;
    }

    SPAGAIN;
    sv = POPs;
    FREETMPS;
    LEAVE;

    return SvTRUE(sv) ? 1 : 0;
}

MODULE = Senna   PACKAGE = Senna

BOOT:
    senna_bootstrap();

MODULE = Senna   PACKAGE = Senna::Index   PREFIX=SIndex_

SV *
SIndex_xs_create(class, path, key_size = SEN_VARCHAR_KEY, flags = 0, initial_n_segments = 0, encoding = sen_enc_default)
        char *class;
        char *path;
        int  key_size;
        int  flags;
        int  initial_n_segments;
        sen_encoding encoding;
    PREINIT:
        sen_index *index;
        SV *sv;
    CODE:
        index = sen_index_create(path, key_size, flags, initial_n_segments, encoding);
        if (index == NULL)
            croak ("Failed to create senna index");

        XS_STRUCT2OBJ(sv, class, index);
        RETVAL = sv;
    OUTPUT:
        RETVAL
    
SV *
SIndex_xs_open(class, path)
        char *class;
        char *path;
    PREINIT:
        sen_index *index;
        int key_size;
        SV *sv;
    CODE:
        index = sen_index_open(path);
        if (index == NULL)
            croak ("Failed to open senna index");

        /* Make sure that index does not have some unsupported key_size
         */
        sen_index_info(index, &key_size, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        if (key_size != SEN_VARCHAR_KEY && key_size != SEN_INT_KEY)
            croak("Senna::Index does not support key_size other than 0 or 4");

        XS_STRUCT2OBJ(sv, class, index);
        SvREADONLY_on(sv);

        RETVAL = sv;
    OUTPUT:
        RETVAL

void
SIndex_info(self)
        SV *self;
    PREINIT:
        sen_index *index;
        int key_size;
        int flags;
        int initial_n_segments;
        sen_encoding encoding;
        unsigned int nrecords_keys;
        unsigned int file_size_keys;
        unsigned int nrecords_lexicon;
        unsigned int file_size_lexicon;
        unsigned int inv_seg_size;
        unsigned int inv_chunk_size;
        sen_rc rc;
    PPCODE:
        index = XS_STATE(sen_index *, self);
        rc = sen_index_info(index,
            &key_size, &flags, &initial_n_segments, &encoding,
            &nrecords_keys, &file_size_keys, &nrecords_lexicon,
            &file_size_lexicon, &inv_seg_size, &inv_chunk_size
        );

        if (rc != sen_success)
            croak("Failed to call sen_index_info: %d", rc);

        EXTEND(SP, 10);
        mPUSHi(key_size);
        mPUSHi(flags);
        mPUSHi(initial_n_segments);
        mPUSHi(encoding);
        mPUSHi(nrecords_keys);
        mPUSHi(file_size_keys);
        mPUSHi(nrecords_lexicon);
        mPUSHi(file_size_lexicon);
        mPUSHi(inv_seg_size);
        mPUSHi(inv_chunk_size);

SV *
SIndex_path(self)
        SV *self;
    PREINIT:
        sen_index *index;
        char path[SEN_MAX_PATH_SIZE];
    CODE:
        index = XS_STATE(sen_index *, self);
        sen_index_path(index, path, SEN_MAX_PATH_SIZE);
        RETVAL = newSVpv(path, 0);
    OUTPUT:
        RETVAL

SV *
SIndex_close(obj)
        SV *obj;
    PREINIT:
        sen_index *index;
    CODE:
        index = XS_STATE(sen_index *, obj);
        RETVAL = sen_rc2obj(sen_index_close(index));
    OUTPUT:
        RETVAL

SV *
SIndex_remove(self)
        SV *self;
    PREINIT:
        sen_index *index;
        char path[SEN_MAX_PATH_SIZE];
    CODE:
        index = XS_STATE(sen_index *, self);
        if (! sen_index_path(index, path, SEN_MAX_PATH_SIZE))
            croak("sen_index_path did not return a proper path");
        RETVAL = sen_rc2obj(sen_index_remove(path));
    OUTPUT:
        RETVAL

SV *
SIndex_xs_rename(self, new)
        SV *self;
        char *new;
    PREINIT:
        sen_index *index;
        char path[SEN_MAX_PATH_SIZE];
    CODE:
        index = XS_STATE(sen_index *, self);
        if (! sen_index_path(index, path, SEN_MAX_PATH_SIZE))
            croak("sen_index_path did not return a proper path");
        RETVAL = sen_rc2obj(sen_index_rename(path, new));
    OUTPUT:
        RETVAL

void
SIndex_xs_select(self, query_sv, records, op_sv, optarg_sv)
        SV *self;
        SV *query_sv;
        SV *records;
        SV *op_sv;
        SV *optarg_sv;
    PREINIT:
        SV *sv;
        STRLEN query_len = 0;
        sen_index   *index;
        sen_rc       rc;
        sen_records *r;
        sen_select_optarg *optarg = NULL;
        sen_sel_operator op = SvOK(op_sv) ? SvIV(op_sv) : 0;
        char *query = NULL;
        int need_optarg_free = 0;
        int need_records_free = 0;
    PPCODE:
        index = XS_STATE(sen_index *, self);

        if ( SvOK(query_sv) ) {
            query = SvPV(query_sv, query_len);
        }

        if (! SvOK(records)) {
            r = sen_records_open(sen_rec_document, sen_rec_none, 0);
            need_records_free = 1;
        } else {
            r = XS_STATE(sen_records *, records);
        }

        if (SvOK(optarg_sv)) {
            optarg = XS_STATE(sen_select_optarg *, optarg_sv);
            if (optarg != NULL) {
                Newz(1234, optarg, 1, sen_select_optarg);
                optarg->mode = sen_sel_exact;
                need_optarg_free = 1;
            }
        }

        rc = sen_index_select(
            index,
            query,
#if (SENNA_MAJOR_VERSION >= 1)
            query_len,
#endif
            r,
            op,
            optarg
        );

        if (need_optarg_free) {
            Safefree(optarg);
        }

        if (rc != sen_success) {
            Safefree(r);
            croak ("Failed to execute sen_index_select: rc = %d", rc);
        }

        if (GIMME_V == G_VOID) {
            if (need_records_free) sen_records_close(r);
            /* no op */;
        } else if (GIMME_V == G_SCALAR) {
            XS_STRUCT2OBJ(sv, "Senna::Records", r);
            XPUSHs(sv);
        } else {
            char keybuf[SEN_MAX_KEY_SIZE];
            int  score;
            int  hits;

            hits = sen_records_nhits(r);
            if (hits <= 0)
                return;

            EXTEND(SP, hits);
            while (sen_records_next(r, &keybuf, SEN_MAX_KEY_SIZE, &score)) {
                /* Construct Senna::Record object */
                dSP;

                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSVpv("Senna::Record", 13)));
                XPUSHs(sv_2mortal(newSVpv("key", 3)));

                SPAGAIN;
                sv = POPs;
                if (! SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVHV ) {
                    croak ("Senna::Record::new did not return a proper object");
                }
                sv = newSVsv(sv);
            
                PUTBACK;
                FREETMPS;
                LEAVE;

                XPUSHs(sv);
            }
            if (need_records_free) sen_records_close(r);
        }

SV *
SIndex_xs_upd(self, key, old_sv, new_sv)
        SV *self;
        SV *key;
        SV *old_sv;
        SV *new_sv;
    PREINIT:
        sen_index *index;
        int        key_size;
        void      *void_key;
        char      *old = NULL;
        char      *new = NULL;
        STRLEN old_len, new_len;
    CODE:
        index = XS_STATE(sen_index *, self);
        sv2senna_key(index, key, &void_key);

        if ( SvOK(old_sv) ) {
            old = SvPV(old_sv, old_len);
        }

        if ( SvOK(new_sv) ) {
            new = SvPV(new_sv, new_len);
        }

        RETVAL = sen_rc2obj(sen_index_upd(
            index,
            void_key,
            old,
#if (SENNA_MAJOR_VERSION >= 1)
            old_len,
#endif
            new,
#if (SENNA_MAJOR_VERSION >= 1)
            new_len
#endif
        ));

    OUTPUT:
        RETVAL
 
SV *
SIndex_xs_update(self, key, section, old, new)
        SV *self;
        SV *key;
        unsigned int section;
        SV *old;
        SV *new;
    PREINIT:
        sen_index *index;
        int        key_size;
        void      *void_key;
        sen_values *old_values;
        sen_values *new_values;
    CODE:
        if (section < 1)
            croak("section must be >= 1");

        index = XS_STATE(sen_index *, self);
        old_values = SvOK(old) ? XS_STATE(sen_values *, old) : NULL;
        new_values = SvOK(new) ? XS_STATE(sen_values *, new) : NULL;

        sv2senna_key(index, key, &void_key);
        RETVAL = sen_rc2obj(sen_index_update(index, key, section, old_values, new_values));
    OUTPUT:
        RETVAL

SV *
SIndex_xs_query_exec(self, query, op = sen_sel_or)
        SV *self;
        SV *query;
        sen_sel_operator op;
    PREINIT:
        sen_index *i;
        sen_query *q;
        sen_records *r;
        sen_rc rc;
        SV *sv;
    CODE:
        i = XS_STATE(sen_index *, self);
        q = XS_STATE(sen_query *, query);

        Newz(1234, r, 1, sen_records);

        rc = sen_query_exec(i, q, r, op);
        if (rc != sen_success)
            croak("sen_query_exec failed: rc = %d", rc);

        XS_STRUCT2OBJ(sv, "Senna::Records", r);
        RETVAL = sv;
    OUTPUT:
        RETVAL

MODULE = Senna      PACKAGE = Senna::Records   PREFIX=SRecords_

SV *
SRecords_xs_open(class, record_unit, subrec_unit, max_n_subrecs)
        char *class;
        sen_rec_unit record_unit;
        sen_rec_unit subrec_unit;
        unsigned int max_n_subrecs;
    PREINIT:
        sen_records *r;
        SV *sv;
    CODE:
        r = sen_records_open(record_unit, subrec_unit, max_n_subrecs);
        if (r == NULL)
            croak("Failed to open sen_records");

        XS_STRUCT2OBJ(sv, class, r);
        RETVAL = sv;
    OUTPUT:
        RETVAL

void
SRecords_xs_next(self)
        SV *self;
    PREINIT:
        sen_records *r;
        sen_rc rc;
    PPCODE:
        r = XS_STATE(sen_records *, self);

        if (GIMME_V == G_SCALAR) {
            /* If we're being called in scalar context, then just return if
             * we have a next record or not
             */
            rc = sen_records_next(r, NULL, 0, NULL);
            XPUSHs(rc == 0 ? &PL_sv_no : &PL_sv_yes);
        } else {
            /* Otherwise, grab the next entry along with other metadata */
            SV *key_sv;
            int score = 0;
            int key_size = 0;
            int section = 0;
            int pos = 0;
            int n_subrecs = 0;

            sen_sym_info(r->keys, &key_size, NULL, NULL, NULL, NULL);

            if (key_size == SEN_INT_KEY) {
                long key;

                rc = sen_records_next(r, &key, 0, &score);
                sen_record_info(r, sen_records_curr_rec(r),
                    NULL, 0, NULL,
                    &section, &pos, NULL, &n_subrecs);
                key_sv = newSViv(key);
            } else {
                char key[SEN_MAX_KEY_SIZE];

                rc = sen_records_next(r, &key, SEN_MAX_KEY_SIZE, &score);
                sen_record_info(r, sen_records_curr_rec(r),
                    NULL, 0, NULL,
                    &section, &pos, NULL, &n_subrecs);
                key_sv = newSVpv(key, 0);
            }

            if (rc != 0) {
                XPUSHs(key_sv);
                XPUSHs(sv_2mortal(newSViv(score)));
                XPUSHs(sv_2mortal(newSViv(section)));
                XPUSHs(sv_2mortal(newSViv(pos)));
                XPUSHs(sv_2mortal(newSViv(n_subrecs)));
            }
        }

SV *
SRecords_rewind(self)
        SV *self;
    PREINIT:
        sen_records *r;
    CODE:
        r = XS_STATE(sen_records *, self);
        RETVAL = sen_rc2obj(sen_records_rewind(r));
    OUTPUT:
        RETVAL

int
SRecords_nhits(self)
        SV *self;
    PREINIT:
        sen_records *r;
    CODE:
        r = XS_STATE(sen_records *, self);
        RETVAL = sen_records_nhits(r);
    OUTPUT:
        RETVAL

int
SRecords_curr_score(self)
        SV *self;
    PREINIT:
        sen_records *r;
    CODE:
        r = XS_STATE(sen_records *, self);
        RETVAL = sen_records_curr_score(r);
    OUTPUT:
        RETVAL

int
SRecords_find(self, key)
        SV *self;
        SV *key;
    PREINIT:
        sen_records *r;
        int key_size;
        STRLEN len;
    CODE:
        r = XS_STATE(sen_records *, self);

        sen_records_rewind(r);
        sen_record_info(r, sen_records_curr_rec(r), NULL, 0, &key_size,
            NULL, NULL, NULL, NULL);
        if (key_size == SEN_INT_KEY) {
            RETVAL = sen_records_find(r, (void *) SvIV(key));
        } else {
            RETVAL = sen_records_find(r, (void *) SvPV(key, len));
        }
        sen_records_rewind(r);
    OUTPUT:
        RETVAL

SV *
SRecords_curr_key(self)
        SV *self;
    PREINIT:
        int key_size;
        sen_records *r;
    CODE:
        r = XS_STATE(sen_records *, self);

        /* if we've already reached the end, don't even bother */
        if( ! r->curr_rec)
            XSRETURN_UNDEF;
        
        sen_record_info(r, sen_records_curr_rec(r), NULL, 0, &key_size,
            NULL, NULL, NULL, NULL);

        if (key_size == SEN_INT_KEY) {
            long int_key;
            if (! sen_records_curr_key(r, &int_key, 1))
                XSRETURN_UNDEF;

            RETVAL = newSViv(int_key);
        } else {
            char char_key[SEN_MAX_KEY_SIZE];

            if (! sen_records_curr_key(r, &char_key, SEN_MAX_KEY_SIZE) )
                XSRETURN_UNDEF;
            RETVAL = newSVpv(char_key, 0);
        }
    OUTPUT:
        RETVAL

SV *
SRecords_close(self)
        SV *self;
    PREINIT:
        sen_records *r;
    CODE:
        r = XS_STATE(sen_records *, self);
        RETVAL = sen_rc2obj(sen_records_close(r));
    OUTPUT:
        RETVAL

SV *
SRecords_union(self, other)
        SV *self;
        SV *other;
    PREINIT:
        sen_records *r;
        SV *sv;
    CODE:
        r = sen_records_union(XS_STATE(sen_records *, self),
                XS_STATE(sen_records *, other));
        XS_STRUCT2OBJ(sv, "Senna::Records", r);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SRecords_subtract(self, other)
        SV *self;
        SV *other;
    PREINIT:
        sen_records *r;
        SV *sv;
    CODE:
        r = sen_records_subtract(XS_STATE(sen_records *, self),
                XS_STATE(sen_records *, other));
        XS_STRUCT2OBJ(sv, "Senna::Records", r);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SRecords_intersect(self, other)
        SV *self;
        SV *other;
    PREINIT:
        sen_records *r;
        SV *sv;
    CODE:
        r = sen_records_intersect(XS_STATE(sen_records *, self),
                XS_STATE(sen_records *, other));
        XS_STRUCT2OBJ(sv, "Senna::Records", r);
        RETVAL = sv;
    OUTPUT:
        RETVAL

int
SRecords_difference(self, other)
        SV *self;
        SV *other;
    PREINIT:
        SV *sv;
    CODE:
        RETVAL = sen_records_difference(
                XS_STATE(sen_records *, self),
                XS_STATE(sen_records *, other));
    OUTPUT:
        RETVAL

SV *
SRecords_xs_sort(self, limit, optarg)
        SV *self;
        int limit;
        SV *optarg;
    PREINIT:
        sen_records *r;
        sen_sort_optarg *o;
    CODE:
        r = XS_STATE(sen_records *, self);
        o = XS_STATE(sen_sort_optarg *, optarg);
        RETVAL = sen_rc2obj(sen_records_sort(r, limit, o));
    OUTPUT:
        RETVAL

MODULE = Senna      PACKAGE = Senna::Query    PREFIX=SQuery_

SV *
SQuery_xs_open(class, str, default_op, max_exprs, encoding)
        char *class;
        char *str;
        sen_sel_operator default_op;
        int max_exprs;
        sen_encoding encoding;
    PREINIT:
        SV *sv;
        sen_query *q;
    CODE:
        q = sen_query_open(
            str, 
#if (SENNA_MAJOR_VERSION >= 1)
            strlen(str),
#endif
            default_op,
            max_exprs,
            encoding
        );
        if (q == NULL)
            croak("Failed to open query");

        XS_STRUCT2OBJ(sv, class, q);
        RETVAL = sv;
    OUTPUT:
        RETVAL

char *
SQuery_rest(self)
        SV *self;
    PREINIT:
        sen_query *q;
#if (SENNA_MAJOR_VERSION >= 1)
        char *rest;
        unsigned int len;
#endif
    CODE:
        q = XS_STATE(sen_query *, self);
#if (SENNA_MAJOR_VERSION >= 1)
        len = sen_query_rest(q, (const char**) &rest);
        RETVAL = rest;
#else
        RETVAL = (char *) sen_query_rest(q);
#endif
    OUTPUT:
        RETVAL

SV *
SQuery_close(self)
        SV *self;
    PREINIT:
        sen_query *q;
    CODE:
        q = XS_STATE(sen_query *, self);
        RETVAL = sen_rc2obj(sen_query_close(q));
    OUTPUT:
        RETVAL

MODULE = Senna      PACKAGE = Senna::Symbol    PREFIX=SSymbol_

SV *
SSymbol_xs_create(class, path, key_size, flags, encoding)
        char *class;
        char *path;
        unsigned int key_size;
        unsigned int flags;
        sen_encoding encoding;
    PREINIT:
        SV *sv;
        sen_sym *sym;
    CODE:
        sym = sen_sym_create(path, key_size, flags, encoding);
        if (sym == NULL)
            croak("Failed to create sym");
        XS_STRUCT2OBJ(sv, class, sym);

        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SSymbol_xs_open(class, path)
        char *class;
        char *path;
    PREINIT:
        SV *sv;
        sen_sym *sym;
    CODE:
        sym = sen_sym_open(path);
        if(sym == NULL)
            croak("Failed to open sen_sym");
        XS_STRUCT2OBJ(sv, class, sym);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SSymbol_close(self)
        SV *self;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_rc2obj(sen_sym_close(sym));
    OUTPUT:
        RETVAL

sen_id
SSymbol_xs_get(self, key)
        SV *self;
        char *key;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_sym_get(sym, key);
    OUTPUT:
        RETVAL

sen_id
SSymbol_xs_at(self, key)
        SV *self;
        char *key;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_sym_at(sym, key);
    OUTPUT:
        RETVAL

SV *
SSymbol_xs_del(self, key)
        SV *self;
        char *key;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_rc2obj(sen_sym_del(sym, key));
    OUTPUT:
        RETVAL

unsigned int
SSymbol_size(self)
        SV *self;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_sym_size(sym);
    OUTPUT:
        RETVAL

char *
SSymbol_xs_key(self, id)
        SV *self;
        sen_id id;
    PREINIT:
        sen_sym *sym;
        char keybuf[SEN_SYM_MAX_KEY_LENGTH];
        sen_rc rc;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        rc = sen_sym_key(sym, id, keybuf, SEN_SYM_MAX_KEY_LENGTH);
        if (rc != sen_success)
            croak("Failed to call sen_sym_key: %d", rc);

        RETVAL = keybuf;
    OUTPUT:
        RETVAL

sen_id
SSymbol_xs_common_prefix_search(self, key)
        SV *self;
        char *key;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_sym_common_prefix_search(sym, key);
    OUTPUT:
        RETVAL

SV *
SSymbol_xs_prefix_search(self, key);
        SV *self;
        char *key;
    PREINIT:
        sen_sym *sym;
        SV *sv;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        XS_STRUCT2OBJ(sv, "Senna::Set", sen_sym_prefix_search(sym, key));
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SSymbol_xs_suffix_search(self, key);
        SV *self;
        char *key;
    PREINIT:
        sen_sym *sym;
        SV *sv;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        XS_STRUCT2OBJ(sv, "Senna::Set", sen_sym_suffix_search(sym, key));
        RETVAL = sv;
    OUTPUT:
        RETVAL

int
SSymbol_xs_pocket_get(self, id)
        SV *self;
        sen_id id;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_sym_pocket_get(sym, id);
    OUTPUT:
        RETVAL

SV *
SSymbol_xs_pocket_set(self, id, value)
        SV *self;
        sen_id id;
        unsigned int value;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_rc2obj(sen_sym_pocket_set(sym, id, value));
    OUTPUT:
        RETVAL

sen_id
SSymbol_xs_next(self, id)
        SV *self;
        sen_id id;
    PREINIT:
        sen_sym *sym;
    CODE:
        sym = XS_STATE(sen_sym *, self);
        RETVAL = sen_sym_next(sym, id);
    OUTPUT:
        RETVAL

MODULE = Senna      PACKAGE = Senna::Set   PREFIX=SSet_

SV *
SSet_xs_open(class, key_size = SEN_VARCHAR_KEY, value_size = 0, n_entries = 0)
        char *class;
        unsigned int key_size;
        unsigned int value_size;
        unsigned int n_entries;
    PREINIT:
        SV *sv;
        sen_set *set;
    CODE:
        set = sen_set_open(key_size, value_size, n_entries);
        XS_STRUCT2OBJ(sv, class, set);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SSet_close(self)
        SV *self;
    PREINIT:
        sen_set *set;
    CODE:
        set = XS_STATE(sen_set *, self);
        RETVAL = sen_rc2obj(sen_set_close(set));
    OUTPUT:
        RETVAL

void
SSet_info(self)
        SV *self;
    PREINIT:
        sen_rc rc;
        sen_set *set;
        unsigned int key_size;
        unsigned int value_size;
        unsigned int n_entries;
    PPCODE:
        set = XS_STATE(sen_set *, self);
        rc = sen_set_info(set, &key_size, &value_size, &n_entries);
        if (rc != sen_success)
            croak ("Failed to call sen_set_info: %d", rc);

        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(key_size)));
        PUSHs(sv_2mortal(newSViv(value_size)));
        PUSHs(sv_2mortal(newSViv(n_entries)));

MODULE = Senna      PACKAGE = Senna::Snippet   PREFIX=SSnip_

SV *
SSnip_xs_open(class, encoding, flags, width, max_results, default_open_tag_sv, default_close_tag_sv, mapping_sv)
        char*        class;
        sen_encoding encoding;
        int          flags;
        size_t       width;
        unsigned int max_results;
        SV*          default_open_tag_sv;
        SV*          default_close_tag_sv;
        SV*          mapping_sv;
    PREINIT:
        int mapping;
        sen_snip *snip;
        sen_perl_snip *perl_snip;
        char *default_open_tag = NULL;
        char *default_close_tag = NULL;
        STRLEN default_open_tag_len = 0;
        STRLEN default_close_tag_len = 0;
        SV *sv;
    CODE:
        if (max_results > MAX_SNIP_RESULT_COUNT) 
            croak("Senna::Snippet::new(): max_results exceeds MAX_SNIP_RESULT_COUNT (%d)", MAX_SNIP_RESULT_COUNT);

        if (SvPOK(default_open_tag_sv) && sv_len(default_open_tag_sv))
            default_open_tag = SvPV(default_open_tag_sv, default_open_tag_len);

        if (SvPOK(default_close_tag_sv) && sv_len(default_close_tag_sv))
            default_close_tag = SvPV(default_close_tag_sv, default_close_tag_len);

        mapping = SvTRUE(mapping_sv) ? -1 : 0;

        Newz(1234, perl_snip, 1, sen_perl_snip);

        if (default_open_tag == NULL)
            croak("Senna::Snippet::new(): default_open_tag must be specified");

        if (default_close_tag == NULL)
            croak("Senna::Snippet::new(): default_close_tag must be specified");


        perl_snip->open_tags_size = 1;
        Newz(1234, perl_snip->open_tags, 1, char *);
        Newz(1234, perl_snip->open_tags[perl_snip->open_tags_size - 1], default_open_tag_len + 1, char);
        Copy(default_open_tag, perl_snip->open_tags[perl_snip->open_tags_size - 1], default_open_tag_len, char);
        default_open_tag = perl_snip->open_tags[perl_snip->open_tags_size - 1];

        perl_snip->close_tags_size = 1;
        Newz(1234, perl_snip->close_tags, 1, char *);
        Newz(1234, (perl_snip->close_tags[perl_snip->close_tags_size - 1]), default_close_tag_len + 1, char);
        Copy(default_close_tag, perl_snip->close_tags[0], default_close_tag_len, char);
        default_close_tag = perl_snip->close_tags[perl_snip->close_tags_size - 1];

        /* mapping is written as a struct, but the docs say that you should
         * specify NULL or -1
         */
        snip = sen_snip_open(
            encoding,
            flags,
            width,
            max_results,
            default_open_tag,
#if (SENNA_MAJOR_VERSION >= 1)
            default_open_tag_len,
#endif
            default_close_tag,
#if (SENNA_MAJOR_VERSION >= 1)
            default_close_tag_len,
#endif
            (sen_snip_mapping *) mapping
        );
        if (snip == NULL)
            croak("Failed to create snip");

        perl_snip->snip = snip;

        XS_STRUCT2OBJ(sv, class, perl_snip);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SSnip_xs_add_cond(self, keyword, opentag_sv, closetag_sv)
        SV *self;
        char *keyword;
        SV *opentag_sv;
        SV *closetag_sv;
    PREINIT:
        char *opentag = NULL;
        char *closetag = NULL;
        sen_perl_snip *snip;
        STRLEN opentag_len = 0;
        STRLEN closetag_len = 0;
    CODE:
        snip = XS_STATE(sen_perl_snip *, self);

        if (SvPOK(opentag_sv) && sv_len(opentag_sv) > 0) {
            opentag = SvPV(opentag_sv, opentag_len);
            snip->open_tags_size++;
            Renew(snip->open_tags, snip->open_tags_size, char *);
            Newz(1234, snip->open_tags[snip->open_tags_size - 1], opentag_len + 1, char);
            Copy(opentag, snip->open_tags[snip->open_tags_size - 1], opentag_len, char);
            opentag = snip->open_tags[snip->open_tags_size - 1];
        }
            
        if (SvPOK(closetag_sv) && sv_len(closetag_sv) > 0) {
            closetag = SvPV(closetag_sv, closetag_len);
            snip->close_tags_size++;
            Renew(snip->close_tags, snip->close_tags_size, char *);
            Newz(1234, snip->close_tags[snip->close_tags_size - 1], closetag_len + 1, char);
            Copy(closetag, snip->close_tags[snip->close_tags_size - 1], closetag_len, char);
            closetag = snip->close_tags[snip->close_tags_size - 1];
        }
            
        RETVAL = sen_rc2obj(
            sen_snip_add_cond(
                snip->snip,
                keyword,
#if (SENNA_MAJOR_VERSION >= 1)
                strlen(keyword),
#endif
                opentag,
#if (SENNA_MAJOR_VERSION >= 1)
                opentag_len,
#endif
                closetag
#if (SENNA_MAJOR_VERSION >= 1)
                ,
                closetag_len
#endif
            )
        );
    OUTPUT:
        RETVAL

void
SSnip_xs_exec(self, string)
        SV *self;
        char *string;
    PREINIT:
        sen_perl_snip    *snip;
        unsigned int nresults;
        char        *result;
#if (SENNA_MAJOR_VERSION >= 1)
        unsigned int max_tagged_len;
#else
        size_t       max_tagged_len;
#endif
        int          i;
        sen_rc rc;
    PPCODE:
        snip = XS_STATE(sen_perl_snip *, self);
        sen_snip_exec(
            snip->snip,
            string,
#if (SENNA_MAJOR_VERSION >= 1)
            strlen(string),
#endif
            &nresults,
            &max_tagged_len
        );

        EXTEND(SP, nresults);
        Newz(1234, result, max_tagged_len, char);
        for(i = 0; i < nresults; i++) {
            rc = sen_snip_get_result(
                snip->snip,
                i,
                result
#if (SENNA_MAJOR_VERSION >= 1)
                ,
                &max_tagged_len
#endif
            );
            if (rc != sen_success) 
                croak("Call to sen_snip_get_result returned %d", rc);
            PUSHs(sv_2mortal(newSVpv(result, 0)));
        }
        Safefree(result);

void
DESTROY(self)
        SV *self;
    PREINIT:
        sen_perl_snip *snip;
        int i;
    PPCODE:
        snip = XS_STATE(sen_perl_snip *, self);
        sen_snip_close(snip->snip);

        for(i = 0; i < snip->open_tags_size; i++) {
            Safefree(snip->open_tags[i]);
        }
        Safefree(snip->open_tags);

        for(i = 0; i < snip->close_tags_size; i++) {
            Safefree(snip->close_tags[i]);
        }
        Safefree(snip->close_tags);

        


MODULE = Senna      PACKAGE = Senna::OptArg::Sort  PREFIX=SOSort_

SV *
SOSort_xs_new(class, mode, compar = NULL, compar_arg = NULL)
        char *class;
        sen_sort_mode mode;
        CV *compar;
        AV *compar_arg;
    PREINIT:
        sen_sort_optarg *optarg;
        SV *sv;
    CODE:
        Newz(1234, optarg, 1, sen_sort_optarg);
        optarg->mode = mode;

        if (SvOK(compar)) {
            optarg->compar = &sen_sort_optarg_cb;
        
            /* The callback arguments are always the CV of the callback,
             * the AV of the argument list, and key_size of the index.
             */
            Newz(1234, optarg->compar_arg, 2, void *);
            ((void **)optarg->compar_arg)[0] = compar;
            if (SvOK(compar_arg) && SvTYPE(compar_arg) == SVt_PVCV)
                ((void **)optarg->compar_arg)[1] = SvREFCNT_inc(compar_arg);
        }

        XS_STRUCT2OBJ(sv, class, optarg);
        RETVAL = sv;
    OUTPUT:
        RETVAL

sen_sort_mode
SOSort_mode(self)
        SV *self;
    PREINIT:
        sen_sort_optarg *optarg;
    CODE:
        optarg = XS_STATE(sen_sort_optarg *, self);
        RETVAL = optarg->mode;
    OUTPUT:
        RETVAL

CV *
SOSort_compar(self)
        SV *self;
    PREINIT:
        sen_sort_optarg *optarg;
        void **args;
    CODE:
        optarg = XS_STATE(sen_sort_optarg *, self);
        /* The CV is always placed in the first element of ->compar_arg */
        args = (void **) optarg->compar_arg;
        if (args[0] == NULL)
            XSRETURN_UNDEF;

        RETVAL = (CV *) args[0];
    OUTPUT:
        RETVAL

void
SOSort_compar_arg(self)
        SV *self;
    PREINIT:
        sen_sort_optarg *optarg;
        void **args;
    PPCODE:
        optarg = XS_STATE(sen_sort_optarg *, self);
        /* The CV is always placed in the second element of ->func_arg */
        args = (void **) optarg->compar_arg;
        if (GIMME_V == G_SCALAR) {
            AV *av;
            if (args[1] == NULL)
                return;

            av = (AV *) args[1];
            EXTEND(SP, 1);
            PUSHs(newRV_noinc((SV *) av));
        } else {
            AV *av;
            int i;
            int len;
            SV **svr;

            av = (AV *) args[1];
            len = av_len(av) + 1;
            if (len <= 0)
                return;

            EXTEND(SP, len);
            for (i = 0; i < len; i++) {
                svr = av_fetch(av, i - 1, 0);
                if (*svr != NULL && SvOK(*svr)) {
                    PUSHs(*svr);
                }
            }
        }

void
SOSort_DESTROY(self)
        SV *self;
    PREINIT:
        sen_sort_optarg *optarg;
    CODE:
        optarg = XS_STATE(sen_sort_optarg *, self);
        if (optarg->compar_arg != NULL) {
            void **args = (void **) optarg->compar_arg;

            if (args[0] != NULL)
                SvREFCNT_dec((CV *) args[0]);

            if (args[1] != NULL)
                SvREFCNT_dec((AV *) args[1]);

            Safefree(args);
        }

        Safefree(optarg);

MODULE = Senna      PACKAGE = Senna::OptArg::Select  PREFIX=SOSelect_

SV *
SOSelect_xs_new(class, mode, similarity_threshold, max_interval, weight_vector, func = NULL, func_args = NULL)
        char *class;
        sen_sel_mode mode;
        int          similarity_threshold;
        int          max_interval;
        AV          *weight_vector;
        CV          *func;
        AV          *func_args;
    PREINIT:
        sen_select_optarg *optarg;
        SV             **svr;
        int i;
        SV *sv;
    CODE:
        Newz(1234, optarg, 1, sen_select_optarg);
        optarg->mode = mode;
        optarg->similarity_threshold = similarity_threshold;
        optarg->vector_size = av_len(weight_vector) + 1;
        optarg->max_interval = max_interval;

        if (optarg->vector_size > 0) {
            Newz(1234, optarg->weight_vector, optarg->vector_size, int);
            for(i = 0; i < optarg->vector_size; i++) {
                svr = av_fetch(weight_vector, i, 0);
                if (svr != NULL && SvIOK(*svr)) {
                    optarg->weight_vector[i] = SvIV(*svr);
                }
            }
        }

        if (SvOK(func)) {
            int key_size;
            void **args;

            optarg->func = &sen_select_optarg_cb;

            /* The callback arguments are always the CV of the callback,
             * the AV of the argument list, and key_size of the index.
             */
            Newz(1234, args, 2, void *);
            args[0] = (void *) func;
            if (SvOK(func_args))
                args[1] = (void *) func_args;
            optarg->func_arg = (void *) args;
        }

        XS_STRUCT2OBJ(sv, class, optarg);
        RETVAL = sv;

    OUTPUT:
        RETVAL

sen_sel_mode
SOSelect_mode(self)
        SV *self;
    PREINIT:
        sen_select_optarg *optarg;
    CODE:
        optarg = XS_STATE(sen_select_optarg *, self);
        RETVAL = optarg->mode;
    OUTPUT:
        RETVAL

int
SOSelect_similarity_threshold(self)
        SV *self;
    PREINIT:
        sen_select_optarg *optarg;
    CODE:
        optarg = XS_STATE(sen_select_optarg *, self);
        RETVAL = optarg->similarity_threshold;
    OUTPUT:
        RETVAL

int
SOSelect_max_interval(self)
        SV *self;
    PREINIT:
        sen_select_optarg *optarg;
    CODE:
        optarg = XS_STATE(sen_select_optarg *, self);
        RETVAL = optarg->max_interval;
    OUTPUT:
        RETVAL

void
SOSelect_weight_vector(self)
        SV *self;
    PREINIT:
        sen_select_optarg *optarg;
    PPCODE:
        optarg = XS_STATE(sen_select_optarg *, self);
        if (optarg->vector_size <= 0)
            return;

        if (GIMME_V == G_SCALAR) {
            AV *av = newAV();
            int i;

            EXTEND(SP, 1);
            av_extend(av, optarg->vector_size - 1);
            for (i = 0; i < optarg->vector_size; i++) {
                av_push(av, newSViv(optarg->weight_vector[i]));
            }
            PUSHs(newRV_inc((SV *) av));
        } else {
            int i;

            EXTEND(SP, optarg->vector_size);
            for (i = 0; i < optarg->vector_size; i++) {
                PUSHs(newSViv(optarg->weight_vector[i]));
            }
        }

CV *
SOSelect_func(self)
        SV *self;
    PREINIT:
        sen_select_optarg *optarg;
        void **args;
    CODE:
        optarg = XS_STATE(sen_select_optarg *, self);
        /* The CV is always placed in the first element of ->func_arg */
        args = (void **) optarg->func_arg;
        if (args[0] == NULL)
            XSRETURN_UNDEF;

        RETVAL = (CV *) args[0];
    OUTPUT:
        RETVAL

void
SOSelect_func_arg(self)
        SV *self;
    PREINIT:
        sen_select_optarg *optarg;
        void **args;
    PPCODE:
        optarg = XS_STATE(sen_select_optarg *, self);
        /* The CV is always placed in the second element of ->func_arg */
        args = (void **) optarg->func_arg;
        if (GIMME_V == G_SCALAR) {
            AV *av;
            if (args[1] == NULL)
                return;

            av = (AV *) args[1];
            EXTEND(SP, 1);
            PUSHs(newRV_noinc((SV *) av));
        } else {
            AV *av;
            int i;
            int len;
            SV **svr;

            av = (AV *) args[1];
            len = av_len(av) + 1;
            if (len <= 0)
                return;

            EXTEND(SP, len);
            for (i = 0; i < len; i++) {
                svr = av_fetch(av, i - 1, 0);
                if (*svr != NULL && SvOK(*svr)) {
                    PUSHs(*svr);
                }
            }
        }

SV *
SOSelect_DESTROY(self)
        SV *self;
    PREINIT:
        sen_select_optarg *optarg;
    CODE:
        optarg = XS_STATE(sen_select_optarg *, self);
        if (optarg->weight_vector != NULL)
            Safefree(optarg->weight_vector);

        if (optarg->func_arg != NULL) {
            void **args = (void **) optarg->func_arg;
            if (args[0] != NULL)
                SvREFCNT_dec((CV *) args[0]);

            if (args[1] != NULL)
                SvREFCNT_dec((AV *) args[1]);

            Safefree(optarg->func_arg);
        }

        Safefree(optarg);

MODULE = Senna    PACKAGE = Senna::Values    PREFIX=SValues_

SV *
SValues_open(class)
        char *class;
    PREINIT:
        sen_values *values;
        SV *sv;
    CODE:
        values = sen_values_open();
        XS_STRUCT2OBJ(sv, class, values);
        RETVAL = sv;
    OUTPUT:
        RETVAL

SV *
SValues_close(self)
        SV *self;
    PREINIT:
        sen_values *values;
    CODE:
        values = XS_STATE(sen_values *, self);
        RETVAL = sen_rc2obj(sen_values_close(values));
    OUTPUT:
        RETVAL

SV *
SValues_xs_add(self, str, weight)
        SV *self;
        char *str;
        unsigned int weight;
    PREINIT:
        sen_values *values;
    CODE:
        values = XS_STATE(sen_values *, self);
        RETVAL = sen_rc2obj(
            sen_values_add(
                values,
                str,
#if (SENNA_MAJOR_VERSION >= 1)
                strlen(str),
#endif
                weight
            )
        );
    OUTPUT:
        RETVAL

