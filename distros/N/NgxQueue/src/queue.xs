#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "ngx-queue.h"

typedef struct p5_ngx_queue_s p5_ngx_queue_t;
typedef p5_ngx_queue_t* NgxQueue;

struct p5_ngx_queue_s {
    ngx_queue_t queue;
    SV* data;
};

/* from List::Util */
#if PERL_VERSION < 13 || (PERL_VERSION == 13 && PERL_SUBVERSION < 9)
#  define PERL_HAS_BAD_MULTICALL_REFCOUNT
#endif

MODULE = NgxQueue PACKAGE = NgxQueue

PROTOTYPES: DISABLE

NgxQueue
new(char* class_name, SV* data = NULL)
CODE:
{
    PERL_UNUSED_VAR(class_name);
    Newx(RETVAL, 1, p5_ngx_queue_t);
    ngx_queue_init(&RETVAL->queue);

    if (data) {
        RETVAL->data = newRV_inc(data);
    }
    else {
        RETVAL->data = NULL;
    }
}
OUTPUT:
    RETVAL

void
DESTROY(NgxQueue self)
CODE:
{
    int cnt;

    if (self->data) {
        cnt = SvREFCNT(self->data);
        SvREFCNT_dec(self->data);
        if (cnt <= 1) {
            self->data = NULL;
            Safefree(self);
        }
    }
}

void
data(NgxQueue self)
CODE:
{
    if (self->data) {
        ST(0) = SvRV(self->data);
        XSRETURN(1);
    }
    else {
        XSRETURN(0);
    }
}

int
empty(NgxQueue h)
CODE:
{
    RETVAL = ngx_queue_empty(&h->queue);
}
OUTPUT:
    RETVAL

void
insert_head(NgxQueue h, NgxQueue x)
ALIAS:
    insert_after = 1
CODE:
{
    PERL_UNUSED_VAR(ix);
    ngx_queue_insert_head(&h->queue, &x->queue);
    PERL_UNUSED_VAR(SvREFCNT_inc(x->data));
}

void
insert_tail(NgxQueue h, NgxQueue x)
CODE:
{
    ngx_queue_insert_tail(&h->queue, &x->queue);
    PERL_UNUSED_VAR(SvREFCNT_inc(x->data));
}

NgxQueue
head(NgxQueue h)
CODE:
{
    ngx_queue_t* q = ngx_queue_head(&h->queue);
    RETVAL = ngx_queue_data(q, p5_ngx_queue_t, queue);
    PERL_UNUSED_VAR(SvREFCNT_inc(RETVAL->data));
}
OUTPUT:
    RETVAL

NgxQueue
last(NgxQueue h)
CODE:
{
    ngx_queue_t* q = ngx_queue_last(&h->queue);
    RETVAL = ngx_queue_data(q, p5_ngx_queue_t, queue);
    PERL_UNUSED_VAR(SvREFCNT_inc(RETVAL->data));
}
OUTPUT:
    RETVAL

NgxQueue
next(NgxQueue h)
CODE:
{
    ngx_queue_t* q = ngx_queue_next(&h->queue);
    RETVAL = ngx_queue_data(q, p5_ngx_queue_t, queue);
    PERL_UNUSED_VAR(SvREFCNT_inc(RETVAL->data));
}
OUTPUT:
    RETVAL

NgxQueue
prev(NgxQueue h)
CODE:
{
    ngx_queue_t* q = ngx_queue_prev(&h->queue);
    RETVAL = ngx_queue_data(q, p5_ngx_queue_t, queue);
    PERL_UNUSED_VAR(SvREFCNT_inc(RETVAL->data));
}
OUTPUT:
    RETVAL

void
remove(NgxQueue x)
CODE:
{
    ngx_queue_remove(&x->queue);
    SvREFCNT_dec(x->data);
}

void
split(NgxQueue h, NgxQueue q, NgxQueue n)
CODE:
{
    ngx_queue_split(&h->queue, &q->queue, &n->queue);
}

void
add(NgxQueue self, NgxQueue n)
CODE:
{
    ngx_queue_add(&self->queue, &n->queue);
}

void
foreach(NgxQueue h, SV* cb)
CODE:
{
    ngx_queue_t* q;
    CV* cv;
    HV* stash;
    GV* gv;

    cv = sv_2cv(cb, &stash, &gv, 0);

    if (cv == Nullcv) {
        croak("Not a subroutine reference");
    }

    SAVESPTR(GvSV(PL_defgv));

    dMULTICALL;
    I32 gimme = G_SCALAR;
    PUSH_MULTICALL(cv);

    ngx_queue_foreach(q, &h->queue) {
        NgxQueue queue = ngx_queue_data(q, p5_ngx_queue_t, queue);
        sv_setref_pv(GvSV(PL_defgv), "NgxQueue", (void*)queue);
        if (queue->data) {
            PERL_UNUSED_VAR(SvREFCNT_inc(queue->data));
        }
        MULTICALL;
    }
#ifdef PERL_HAS_BAD_MULTICALL_REFCOUNT
	if (CvDEPTH(multicall_cv) > 1)
	    SvREFCNT_inc_simple_void_NN(multicall_cv);
#endif
    POP_MULTICALL;
}

