#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newCONSTSUB
#define NEED_newRV_noinc
#include "ppport.h"

#include <depot.h>
#include <cabin.h>
#include <odeum.h>


#define XS_STRUCT2OBJ(sv, class, obj) \
    sv = newSViv(PTR2IV(obj));  \
    sv = newRV_noinc(sv); \
    sv_bless(sv, gv_stashpv(class, 1)); \
    SvREADONLY_on(sv);

#define XS_STATE(type, x) \
    INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

typedef struct _perl_odeum {
    int active;
    ODEUM *odeum;
} perl_odeum;

typedef struct _perl_odeum_result {
    int num;
    int idx;
    ODPAIR *pairs;
    ODEUM *odeum;
} perl_odeum_result;

MODULE = Search::Odeum		PACKAGE = Search::Odeum		PREFIX = Odeum_

SV *
Odeum_xs_new(class, name, omode)
    char *class;
    char *name;
    int omode;
PREINIT:
    perl_odeum *podeum;
    ODEUM *odeum;
    SV *sv;
CODE:
    odeum = odopen(name, omode);
    if(odeum == NULL)
        croak("Failed to open odeum db");
    Newz(1, podeum, 1, perl_odeum);
    podeum->active = 1;
    podeum->odeum = odeum;
    XS_STRUCT2OBJ(sv, class, podeum);
    RETVAL = sv;
OUTPUT: 
    RETVAL

int 
Odeum_put(obj, docobj, wmax = -1, over = 1)
    SV *obj;
    SV *docobj;
    int wmax;
    int over;
PREINIT:
    ODDOC *doc;
    ODEUM *odeum;
CODE:
    doc = XS_STATE(ODDOC *, docobj);
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odput(odeum, doc, wmax, over);
OUTPUT:
    RETVAL

int 
Odeum_out(obj, uri)
    SV *obj;
    const char *uri;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odout(odeum, uri);
OUTPUT:
    RETVAL

int 
Odeum_outbyid(obj, id)
    SV *obj;
    int id;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odoutbyid(odeum, id);
OUTPUT:
    RETVAL

SV *
Odeum_get(obj, uri)
    SV *obj;
    const char *uri;
PREINIT:
    ODEUM *odeum;
    ODDOC *doc;
    SV *sv;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    doc = odget(odeum, uri);
    XS_STRUCT2OBJ(sv, "Search::Odeum::Document", doc);
    RETVAL = sv;
OUTPUT:
    RETVAL

SV *
Odeum_getbyid(obj, id)
    SV *obj;
    int id;
PREINIT:
    ODEUM *odeum;
    ODDOC *doc;
    SV *sv;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    doc = odgetbyid(odeum, id);
    XS_STRUCT2OBJ(sv, "Search::Odeum::Document", doc);
    RETVAL = sv;
OUTPUT:
    RETVAL

int
Odeum_getidbyuri(obj, uri)
    SV *obj;
    const char *uri;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odgetidbyuri(odeum, uri);
OUTPUT:
    RETVAL

int 
Odeum_check(obj, id)
    SV *obj;
    int id;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odcheck(odeum, id);
OUTPUT:
    RETVAL

SV *
Odeum_search(obj, word, max = -1)
    SV *obj;
    const char *word;
    int max;
PREINIT:
    ODEUM *odeum;
    ODPAIR *pairs;
    SV *sv;
    int num;
    perl_odeum_result *res;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    if((pairs = odsearch(odeum, word, max, &num)) != NULL){
        Newz(1, res, 1, perl_odeum_result);
        res->pairs = pairs;
        res->odeum = odeum;
        res->num = num;
        res->idx = 0;
        XS_STRUCT2OBJ(sv, "Search::Odeum::Result", res);
        RETVAL = sv;
    }
    else 
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

int
Odeum_searchdnum(obj, word)
    SV *obj;
    const char *word;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odsearchdnum(odeum, word);
OUTPUT:
    RETVAL

SV *
Odeum_query(obj, q)
    SV *obj;
    const char *q;
PREINIT:
    ODEUM *odeum;
    ODPAIR *pairs;
    SV *sv;
    int num;
    perl_odeum_result *res;
    CBLIST *errors;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    if((pairs = odquery(odeum, q, &num, NULL)) != NULL){
        Newz(1, res, 1, perl_odeum_result);
        res->pairs = pairs;
        res->odeum = odeum;
        res->num = num;
        res->idx = 0;
        XS_STRUCT2OBJ(sv, "Search::Odeum::Result", res);
        RETVAL = sv;
    }
    else 
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

int
Odeum_sync(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odsync(odeum);
OUTPUT:
    RETVAL

int
Odeum_optimize(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odoptimize(odeum);
OUTPUT:
    RETVAL

SV *
Odeum_name(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
    char *name;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    name = odname(odeum);
    RETVAL = newSVpv(name, 0);
    free(name);
OUTPUT:
    RETVAL

double
Odeum_fsiz(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
    double fsize;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    fsize = odfsiz(odeum);
    RETVAL = fsize;
OUTPUT:
    RETVAL

int 
Odeum_bnum(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odbnum(odeum);
OUTPUT:
    RETVAL

int 
Odeum_busenum(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odbusenum(odeum);
OUTPUT:
    RETVAL

int 
Odeum_dnum(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = oddnum(odeum);
OUTPUT:
    RETVAL

int 
Odeum_wnum(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odwnum(odeum);
OUTPUT:
    RETVAL

int 
Odeum_writable(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odwritable(odeum);
OUTPUT:
    RETVAL

int 
Odeum_fatalerror(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odfatalerror(odeum);
OUTPUT:
    RETVAL

int 
Odeum_inode(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odinode(odeum);
OUTPUT:
    RETVAL

time_t
Odeum_mtime(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
CODE:
    odeum = (XS_STATE(perl_odeum *, obj))->odeum;
    RETVAL = odmtime(odeum);
OUTPUT:
    RETVAL

void
Odeum_close(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
    perl_odeum *podeum;
CODE:
    podeum = XS_STATE(perl_odeum *, obj);
    odeum = podeum->odeum;
    odclose(odeum);
    podeum->active = 0;

void
Odeum_DESTROY(obj)
    SV *obj;
PREINIT:
    ODEUM *odeum;
    perl_odeum *podeum;
CODE:
    podeum = XS_STATE(perl_odeum *, obj);
    if(podeum->active) {
        odeum = podeum->odeum;
        odclose(odeum); 
        podeum->active = 0; 
    }
    Safefree(podeum);



MODULE = Search::Odeum		PACKAGE = Search::Odeum::Document		PREFIX = OdeumDoc_

SV *
OdeumDoc_xs_new(class, uri)
    char *class;
    char *uri;
PREINIT:
    ODDOC *doc;
    SV *sv;
CODE:
    doc = oddocopen(uri);
    XS_STRUCT2OBJ(sv, class, doc);
    RETVAL = sv;
OUTPUT:
    RETVAL

void
OdeumDoc_addattr(obj, name, value)
    SV *obj;
    const char *name;
    const char *value;
PREINIT:
    ODDOC *doc;
CODE:
    doc = XS_STATE(ODDOC *, obj);
    oddocaddattr(doc, name, value);

SV *
OdeumDoc_getattr(obj, name)
    SV *obj;
    const char *name;
PREINIT:
    ODDOC *doc;
    const char *value;
CODE:
    doc = XS_STATE(ODDOC *, obj);
    value = oddocgetattr(doc, name);
    RETVAL = newSVpv(value, 0);
OUTPUT:
    RETVAL

void
OdeumDoc_addword(obj, normal, asis)
    SV *obj;
    const char *normal;
    const char *asis;
PREINIT:
    ODDOC *doc;
CODE:
    doc = XS_STATE(ODDOC *, obj);
    oddocaddword(doc, normal, asis);

int
OdeumDoc_id(obj)
    SV *obj;
PREINIT:
    ODDOC *doc;
CODE:
    doc = XS_STATE(ODDOC *, obj);
    RETVAL = oddocid(doc);
OUTPUT:
    RETVAL

SV *
OdeumDoc_uri(obj)
    SV *obj;
PREINIT:
    ODDOC *doc;
    const char *uri;
    SV *sv;
CODE:
    doc = XS_STATE(ODDOC *, obj);
    uri = oddocuri(doc);
    RETVAL = newSVpv(uri, 0);
OUTPUT:
    RETVAL

void
OdeumDoc_DESTROY(obj)
    SV *obj;
PREINIT:
    ODDOC *doc;
CODE:
    doc = XS_STATE(ODDOC *, obj);
    oddocclose(doc);


MODULE = Search::Odeum		PACKAGE = Search::Odeum::Result		PREFIX = OdeumRes_

int 
OdeumRes_num(obj)
    SV *obj;
PREINIT:
    perl_odeum_result *res;
CODE:
    res = XS_STATE(perl_odeum_result *, obj);
    RETVAL = res->num;
OUTPUT:
    RETVAL

void
OdeumRes_init(obj)
    SV *obj;
PREINIT:
    perl_odeum_result *res;
CODE:
    res = XS_STATE(perl_odeum_result *, obj);
    res->idx = 0;

SV *
OdeumRes_next(obj)
    SV *obj;
PREINIT:
    perl_odeum_result *res;
    int id;
    ODDOC *doc;
    SV *sv;
CODE:
    res = XS_STATE(perl_odeum_result *, obj);
  get_doc:
    if(res->idx >= res->num)
        XSRETURN_UNDEF;
    else {
        id = res->pairs[res->idx].id;
        doc = odgetbyid(res->odeum, id);
        res->idx = res->idx + 1;
        if(doc == NULL)
            goto get_doc; 
        XS_STRUCT2OBJ(sv, "Search::Odeum::Document", doc);
        RETVAL = sv;
    }
OUTPUT:
    RETVAL

SV *
OdeumRes_and_op(obj, other);
    SV *obj;
    SV *other;
PREINIT:
    perl_odeum_result *res1;
    perl_odeum_result *res2;
    perl_odeum_result *res;
    ODPAIR *pairs ;
    SV *sv;
    int num;
CODE:
    res1 = XS_STATE(perl_odeum_result *, obj);
    res2 = XS_STATE(perl_odeum_result *, other);
    if(pairs = odpairsand(res1->pairs, res1->num, res2->pairs, res2->num, &num)) {
        Newz(1, res, 1, perl_odeum_result);
        res->pairs = pairs;
        res->odeum = res1->odeum;
        res->num = num;
        res->idx = 0;
        XS_STRUCT2OBJ(sv, "Search::Odeum::Result", res);
        RETVAL = sv;
    }
    else
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

SV *
OdeumRes_or_op(obj, other);
    SV *obj;
    SV *other;
PREINIT:
    perl_odeum_result *res1;
    perl_odeum_result *res2;
    perl_odeum_result *res;
    ODPAIR *pairs ;
    SV *sv;
    int num;
CODE:
    res1 = XS_STATE(perl_odeum_result *, obj);
    res2 = XS_STATE(perl_odeum_result *, other);
    if(pairs = odpairsor(res1->pairs, res1->num, res2->pairs, res2->num, &num)) {
        Newz(1, res, 1, perl_odeum_result);
        res->pairs = pairs;
        res->odeum = res1->odeum;
        res->num = num;
        res->idx = 0;
        XS_STRUCT2OBJ(sv, "Search::Odeum::Result", res);
        RETVAL = sv;
    }
    else
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL

SV *
OdeumRes_notand_op(obj, other);
    SV *obj;
    SV *other;
PREINIT:
    perl_odeum_result *res1;
    perl_odeum_result *res2;
    perl_odeum_result *res;
    ODPAIR *pairs ;
    SV *sv;
    int num;
CODE:
    res1 = XS_STATE(perl_odeum_result *, obj);
    res2 = XS_STATE(perl_odeum_result *, other);
    if(pairs = odpairsnotand(res1->pairs, res1->num, res2->pairs, res2->num, &num)) {
        Newz(1, res, 1, perl_odeum_result);
        res->pairs = pairs;
        res->odeum = res1->odeum;
        res->num = num;
        res->idx = 0;
        XS_STRUCT2OBJ(sv, "Search::Odeum::Result", res);
        RETVAL = sv;
    }
    else
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL
        

void
OdeumRes_DESTROY(obj)
    SV *obj;
PREINIT:
    perl_odeum_result *res;
CODE:
    res = XS_STATE(perl_odeum_result *, obj);
    free(res->pairs);
    Safefree(res);







