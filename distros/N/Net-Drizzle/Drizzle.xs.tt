/*
    vim: ft=xs
*/
#include "net_drizzle.h"
#include "const.h"

inline
SV *_bless(const char *class, void *obj) {
    SV * ret = newSViv(0);
    XS_STRUCT2OBJ(ret, class, obj);
    return ret;
}

SV* _create_drizzle() {
    net_drizzle * self;
    Newxz(self, 1, net_drizzle);
    Newxz(self->drizzle, 1, drizzle_st);
    if (drizzle_create(self->drizzle) == NULL) {
        Perl_croak(aTHX_ "drizzle_create:NULL\n"); /* should not reache here */
    }
    self->queries = newAV();
    SV * ret = _bless("Net::Drizzle", self);
    LOG("CREATE drizzle 0x%X\n", (unsigned int)ret);
    return ret;
}

SV * _create_result(SV* con_sv, SV *query_sv, drizzle_result_st* result_raw) {
    net_result * result;
    Newxz(result, 1, net_result);
    if (con_sv) {
        result->drizzle = SvREFCNT_inc_simple(XS_STATE(net_con*, con_sv)->drizzle);
    } else if (query_sv) {
        result->drizzle   = SvREFCNT_inc_simple(XS_STATE(net_query*, query_sv)->drizzle);
    } else {
        Perl_croak(aTHX_ "should not reach here");
    }

    if (con_sv) {
        result->con     = SvREFCNT_inc_simple(con_sv);
    } else {
        result->con     = NULL;
    }
    if (query_sv) {
        result->query     = SvREFCNT_inc_simple(query_sv);
    } else {
        result->query   = NULL;
    }

    result->result  = result_raw;
    return _bless("Net::Drizzle::Result", result);
}

net_col * _create_col(SV* result_sv, drizzle_column_st* col_raw) {
    net_result * result_result = XS_STATE(net_result*, result_sv);
    net_col *col;
    Newxz(col, 1, net_col);
    col->drizzle = SvREFCNT_inc_simple(result_result->drizzle);
    col->con     = SvREFCNT_inc_simple(result_result->con);
    col->result  = SvREFCNT_inc_simple(result_sv);
    col->col     = col_raw;
    return col;
}

SV * _create_con(SV* drizzle_sv, drizzle_con_st *con_raw) {
    net_con *con;
    Newxz(con, 1, net_con);
    LOG("CREATE connection drizzle=0x%X, drizzle_refcnt=%d\n", (unsigned int)drizzle_sv, (int)SvREFCNT(drizzle_sv));
    con->drizzle = SvREFCNT_inc_simple(drizzle_sv);
    con->con     = con_raw;
    return _bless("Net::Drizzle::Connection", con);
}

SV * _create_query(SV* drizzle_sv, SV *con_sv, drizzle_query_st *query_raw) {
    LOG("CREATE query 0x%X, drizzle_refcnt=%d\n", (unsigned int)drizzle_sv, (int)SvREFCNT(drizzle_sv));

    net_query *query;
    Newxz(query, 1, net_query);
    query->drizzle = SvREFCNT_inc(drizzle_sv);
    if (con_sv != NULL) {
        query->con     = SvREFCNT_inc(con_sv);
    } else {
        query->con     = NULL;
    }
    query->query     = query_raw;
    return _bless("Net::Drizzle::Query", query);
}

SV* row2arrayref(drizzle_row_t row, uint16_t cnt) {
    AV * res = newAV();
    int i;
    for (i=0; i<cnt; i++) {
        SV *s = newSVpv(row[i], strlen(row[i]));
        av_push(res, SvREFCNT_inc(s));
    }
    return newRV_noinc((SV*)res);
}

/* prototype for sub xs modules */
XS(boot_Net__Drizzle__Connection);
XS(boot_Net__Drizzle__Result);
XS(boot_Net__Drizzle__Column);
XS(boot_Net__Drizzle__Query);

#define call_sub_xs(name) \
        PUSHMARK(mark); boot_Net__Drizzle__##name(aTHX_ cv)

MODULE = Net::Drizzle  PACKAGE = Net::Drizzle

PROTOTYPES: DISABLE

BOOT:
    /* call other *.xs modules */
    call_sub_xs(Connection);
    call_sub_xs(Result);
    call_sub_xs(Column);
    call_sub_xs(Query);
    setup_constants();

SV*
Net::Drizzle::new()
CODE:
    PERL_UNUSED_VAR(CLASS);
    RETVAL = _create_drizzle();
OUTPUT:
    RETVAL

SV*
con_create(SV *self)
CODE:
    drizzle_st * drizzle = GET_DRIZZLE(self);
    drizzle_con_st *con_raw;
    if ((con_raw = drizzle_con_create(drizzle, NULL)) == NULL) {
        Perl_croak(aTHX_ "drizzle_con_create:NULL\n");
    }
    RETVAL = _create_con(self, con_raw);
OUTPUT:
    RETVAL

SV*
con_add_tcp(SV* self, const char *host, U16 port, const char * user, const char * password, const char *db, drizzle_con_options_t opt)
CODE:
    drizzle_st * drizzle = GET_DRIZZLE(self);
    drizzle_con_st *con_raw = drizzle_con_add_tcp(
                                         drizzle,
                                         NULL, /* auto allocate */
                                         host, port, user, password, db,
                                         opt);
    RETVAL = _create_con(self, con_raw);
OUTPUT:
    RETVAL

void
DESTROY(SV* _self)
CODE:
    LOG("DESTROY drizzle 0x%X, drizzle->refcnt=%d\n", (unsigned int)_self, (int)SvREFCNT(_self));
    drizzle_st *drizzle = GET_DRIZZLE(_self);
    drizzle_free(drizzle);
    av_undef(GET_DRIZZLE_QUERIES(_self));
    Safefree(drizzle);

void
query_run_all(SV *self)
CODE:
    drizzle_st *drizzle = GET_DRIZZLE(self);
    drizzle_return_t ret = drizzle_query_run_all(drizzle);
    if (ret != DRIZZLE_RETURN_OK) {
        Perl_croak(aTHX_ "drizzle_query_run_all:%s\n", drizzle_error(drizzle));
    }

SV *
escape(SV *class, SV* str)
CODE:
    PERL_UNUSED_VAR(class);
    STRLEN str_len;
    const char * str_c = SvPV(str, str_len);
    char * buf;
    Newxz(buf, str_len*2+1, char);
    uint64_t dst_len = drizzle_escape_string(buf, str_c, str_len);
    SV * res = newSVpvn(buf, dst_len);
    Safefree(buf);
    RETVAL = res;
OUTPUT:
    RETVAL

SV *
hex_string(SV *class, SV* str)
CODE:
    PERL_UNUSED_VAR(class);
    STRLEN str_len;
    const char * str_c = SvPV(str, str_len);
    char * buf;
    Newxz(buf, str_len*2+1, char);
    uint64_t dst_len = drizzle_hex_string(buf, str_c, str_len);
    SV * res = newSVpvn(buf, dst_len);
    Safefree(buf);
    RETVAL = res;
OUTPUT:
    RETVAL

const char *
drizzle_version(SV *class)
CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = drizzle_version();
OUTPUT:
    RETVAL

SV*
add_options(SV* self, int opt)
CODE:
    drizzle_st * drizzle = GET_DRIZZLE(self);
    drizzle_add_options(drizzle, opt);
    RETVAL = SvREFCNT_inc(self);
OUTPUT:
    RETVAL

void
con_wait(SV* self)
CODE:
    drizzle_st * drizzle = GET_DRIZZLE(self);
    drizzle_return_t ret = drizzle_con_wait(drizzle);
    if (ret != DRIZZLE_RETURN_OK) {
        // Perl_croak(aTHX_ "drizzle_con_wait:%s\n", drizzle_error(drizzle));
    }

void
con_ready(SV* self)
PPCODE:
    drizzle_st * drizzle = GET_DRIZZLE(self);
    drizzle_con_st * con_raw = drizzle_con_ready(drizzle);
    if (con_raw) {
        ST(0) = _create_con(self, con_raw);
        XSRETURN(1);
    } else {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

const char*
error(SV* self)
CODE:
    drizzle_st* drizzle = GET_DRIZZLE(self);
    RETVAL=drizzle_error(drizzle);
OUTPUT:
    RETVAL

int
error_code(SV* self)
CODE:
    drizzle_st* drizzle = GET_DRIZZLE(self);
    RETVAL=drizzle_error_code(drizzle);
OUTPUT:
    RETVAL

void
query_run(SV* self)
PPCODE:
    dTARGET;
    drizzle_st *drizzle = GET_DRIZZLE(self);
    drizzle_return_t ret = 0;
    drizzle_query_st * query = drizzle_query_run(drizzle, &ret);
    if (query) {
        SV * q = _create_query(self, NULL, query);
        XPUSHi(ret);
        mXPUSHs(q);
        XSRETURN(2);
    } else {
        XPUSHi(ret);
        XPUSHs(&PL_sv_undef);
        XSRETURN(2);
    }

