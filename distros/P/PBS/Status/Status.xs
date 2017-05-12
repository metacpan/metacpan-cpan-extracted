#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "../ppport.h"

#include <pbs_ifl.h>

#include "../const-c.inc"

MODULE = PBS::Status		PACKAGE = PBS::Status

INCLUDE: ../const-xs.inc

struct batch_status *
new(CLASS)
    char *CLASS
CODE:
    RETVAL = (struct batch_status *)safemalloc(sizeof(struct batch_status));
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

void
DESTROY(self)
    struct batch_status *self
PREINIT:
    struct batch_status *p;
    struct batch_status *q;
PPCODE:
    if (self != NULL) {
        p = self;
        while (p != NULL) {
           q = p;
           p = p->next;
           safefree(q);
        }
    }

char *
get_name(self)
    struct batch_status *self
CODE:
    RETVAL = self->name; 
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

char *
get_text(self)
    struct batch_status *self
CODE:
    RETVAL = self->text; 
    if (RETVAL == NULL) {
        XSRETURN_UNDEF;
    }
OUTPUT:
    RETVAL

SV *
get_attributes(self)
    struct batch_status *self
CODE:
    if (self->attribs == NULL) {
        XSRETURN_UNDEF;
    }
    RETVAL = newSV(0);
    RETVAL = newRV_noinc(RETVAL);
    RETVAL = sv_setref_pv(RETVAL, "PBS::Attr", (void *)self->attribs);
OUTPUT:
    RETVAL

void
push(self, next)
    struct batch_status *self
    struct batch_status *next
PPCODE:
    self->next = next;

SV *
get(self)
    struct batch_status *self
PREINIT:
    HV                  *hvval;
    SV                  *svval;
    AV                  *rtn;
    struct batch_status *p;
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
            if (p->text != NULL) {
                svval = newSVpv(p->text, strlen(p->text));
                if (hv_store(hvval, "text", strlen("text"), svval, 0) == NULL) {
                    croak("Text not stored");
                }
            }
            /* push the attrl list into the hash */
            if (p->attribs != NULL) {
                svval = newSV(0);
                svval = newRV_noinc(svval);
                svval = sv_setref_pv(svval, "PBS::Attr", (void *)p->attribs);
                if (hv_store(hvval, "attributes", strlen("attributes"), svval, 0) == NULL) {
                    croak("Attribs not stored");
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
