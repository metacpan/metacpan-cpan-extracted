#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

#include <string.h>
#include "pvip.h"
#include "const.h"


#define XS_STATE(type, x)     (INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x)))

#define XS_STRUCT2OBJ(sv, class, obj, is_root) \
    sv = newSViv(PTR2IV(obj));  \
    sv = newRV_noinc(sv); \
    sv_magic(sv, sv_2mortal(newSViv(is_root)), PERL_MAGIC_ext, NULL, 0); \
    sv_bless(sv, gv_stashpv(class, 1)); \
    SvREADONLY_on(sv);

MODULE = Perl6::PVIP    PACKAGE = Perl6::PVIP

PROTOTYPES: DISABLE

BOOT:
    setup_pvip_const();

void
_parse_string(code)
    SV *code;
PREINIT:
    size_t len;
    const char *buf;
    PVIPNode *node;
    SV *sv;
    SV *errpv;
PPCODE:
    buf = SvPV(code, len);
    PVIPString* err;
    node = PVIP_parse_string(buf, len, 0, &err);
    if (node) {
        XS_STRUCT2OBJ(sv, "Perl6::PVIP::Node", node, 1);
        XPUSHs(sv);
    } else {
        XPUSHs(&PL_sv_undef);
        errpv = newSVpv(err->buf, err->len);
        XPUSHs(errpv);
        PVIP_string_destroy(err);
    }

MODULE = Perl6::PVIP    PACKAGE = Perl6::PVIP::Node

int
type(self)
    SV *self;
CODE:
    PVIPNode *node = XS_STATE(PVIPNode*, self);
    RETVAL = node->type;
OUTPUT:
    RETVAL

int
line_number(self)
    SV *self;
CODE:
    PVIPNode *node = XS_STATE(PVIPNode*, self);
    RETVAL = node->line_number;
OUTPUT:
    RETVAL

SV*
as_sexp(self)
    SV *self;
PREINIT:
    SV *ret;
CODE:
    PVIPNode *node = XS_STATE(PVIPNode*, self);
    PVIPString * buf = PVIP_string_new();
    PVIP_node_as_sexp(node, buf);
    ret = newSVpv(buf->buf, buf->len);
    PVIP_string_destroy(buf);
    RETVAL = ret;
OUTPUT:
    RETVAL

int
category(self)
    SV *self;
CODE:
    PVIPNode *node = XS_STATE(PVIPNode*, self);
    RETVAL = PVIP_node_category(node->type);
OUTPUT:
    RETVAL

const char*
name(self)
    SV *self;
CODE:
    PVIPNode *node = XS_STATE(PVIPNode*, self);
    RETVAL = PVIP_node_name(node->type);
OUTPUT:
    RETVAL

SV*
value(self)
    SV *self;
PREINIT:
    int i;
    AV *av;
CODE:
    PVIPNode *node = XS_STATE(PVIPNode*, self);
    PVIP_category_t cat = PVIP_node_category(node->type);
    switch (cat) {
    case PVIP_CATEGORY_STRING:
        RETVAL = newSVpvn(node->pv->buf, node->pv->len);
        break;
    case PVIP_CATEGORY_INT:
        RETVAL = newSViv(node->iv);
        break;
    case PVIP_CATEGORY_NUMBER:
        RETVAL = newSVnv(node->nv);
        break;
    case PVIP_CATEGORY_CHILDREN:
        av=newAV();
        for (i=0;i<node->children.size; i++) {
            SV *sv;
            XS_STRUCT2OBJ(sv, "Perl6::PVIP::Node", node->children.nodes[i], 0);
            av_push(av, sv);
        }
        RETVAL = newRV_noinc((SV*)av);
        break;
    default:
        abort();
    }
OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self;
PREINIT:
    MAGIC *mg;
CODE:
    PVIPNode *node = XS_STATE(PVIPNode*, self);
    mg = mg_find(SvRV(self), PERL_MAGIC_ext);
    if (mg && SvIV(mg->mg_obj)==1) {
        /* release if it's root node. */
        PVIP_node_destroy(node);
    }

