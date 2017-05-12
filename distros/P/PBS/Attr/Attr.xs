#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../ppport.h"

#include <pbs_ifl.h>

#include "../const-c.inc"

MODULE = PBS::Attr		PACKAGE = PBS::Attr		

INCLUDE: ../const-xs.inc

struct attrl *
new(CLASS)
    char *CLASS
CODE:
    RETVAL = (struct attrl *)safemalloc(sizeof(struct attrl));
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

char *
get_name(self)
    struct attrl *self
CODE:
    RETVAL = self->name; 
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
set_name(self, name)
    struct attrl *self
    char         *name
PPCODE:
    self->name = strdup(name);

char *
get_resource(self)
    struct attrl *self
CODE:
    RETVAL = self->resource; 
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
set_resource(self, resource)
    struct attrl *self
    char         *resource
PPCODE:
    self->resource = strdup(resource);

char *
get_value(self)
    struct attrl *self
CODE:
    RETVAL = self->value; 
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
set_value(self, value)
    struct attrl *self
    char         *value
PPCODE:
    self->value = strdup(value);

void
push(self, next)
    struct attrl *self
    struct attrl *next
PPCODE:
    self->next = next;

void
set_current(self, values)
    struct attrl *self
    HV           *values
PREINIT:
    SV           **ssv;
PPCODE:
    ssv = hv_fetch(values, "name", strlen("name"), 0);
    if (ssv != NULL) {
        self->name = SvPV_nolen(*ssv);
    }
    
    ssv = hv_fetch(values, "resource", strlen("resource"), 0);
    if (ssv != NULL) {
        self->resource = SvPV_nolen(*ssv);
    }

    ssv = hv_fetch(values, "value", strlen("value"), 0);
    if (ssv != NULL) {
        self->value = SvPV_nolen(*ssv);
    }
    
SV *
get(self)
    struct attrl *self
PREINIT:
    HV           *hvval;
    SV           *svval;
    AV           *rtn;
    struct attrl *p;
CODE:
    if (self == NULL) {
        XSRETURN_UNDEF;
    } else {
        rtn = newAV();
        p = self;
        while (p != NULL) {
            # make p into a perl hash
            hvval = newHV();
            if (p->name != NULL) {
                svval = newSVpv(p->name, strlen(p->name));
                if (hv_store(hvval, "name", strlen("name"), svval, 0) == NULL) {
                    croak("Name not stored");
                }
            }
            if (p->resource != NULL) {
                svval = newSVpv(p->resource, strlen(p->resource));
                if (hv_store(hvval, "resource", strlen("resource"), svval, 0) == NULL) {
                    croak("Resource not stored");
                }
            }
            if (p->value != NULL) {
                svval = newSVpv(p->value, strlen(p->value));
                if (hv_store(hvval, "value", strlen("value"), svval, 0) == NULL) {
                    croak("Value not stored");
                }
            }
            av_push(rtn, newRV_noinc((SV *)hvval));
            p = p->next;
        }
        RETVAL = newRV_inc((SV *)rtn);
    }
OUTPUT:
    RETVAL 
CLEANUP:
    SvREFCNT_dec(rtn);

void
DESTROY(self)
    struct attrl *self
PREINIT:
    struct attrl *p;
    struct attrl *q;
PPCODE:
    if (self != NULL) {
        p = self;
        while (p != NULL) {
            q = p;
            p = p->next;
            safefree(q);
        }
    }

