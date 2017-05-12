#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h> /* for memmove() mostly */
#include <errno.h> /* errno values */
#include "queue.h"
#include "alloc.h"

/* this typedef lets the standard T_PTROBJ typemap handle the
conversion between perl class and C type and back again */
typedef poe_queue *POE__XS__Queue__Array;

/* This gives us our new method and correct destruction */
#define pq_new(class) pq_create()
#define pq_DESTROY(pq) pq_delete(pq)

MODULE = POE::XS::Queue::Array  PACKAGE = POE::XS::Queue::Array PREFIX = pq_

PROTOTYPES: DISABLE

POE::XS::Queue::Array
pq_new(class)

void
pq_DESTROY(pq)
	POE::XS::Queue::Array pq

int
pq_enqueue(pq, priority, payload)
     POE::XS::Queue::Array pq
     double priority
     SV *payload
     
void
pq_dequeue_next(pq)
	POE::XS::Queue::Array pq
      PREINIT:
	pq_priority_t priority;
	pq_id_t id;
	SV *payload;
      PPCODE:
	if (pq_dequeue_next(pq, &priority, &id, &payload)) {
	  EXTEND(SP, 3);
	  PUSHs(sv_2mortal(newSVnv(priority)));
	  PUSHs(sv_2mortal(newSViv(id)));
	  PUSHs(sv_2mortal(payload));
	}

SV *
pq_get_next_priority(pq)
	POE::XS::Queue::Array pq
      PREINIT:
	pq_priority_t priority;
      CODE:
	if (pq_get_next_priority(pq, &priority)) {
          RETVAL = newSVnv(priority); /* XS will mortalize this for us */
	}
	else {
	  RETVAL = &PL_sv_undef;
	}
      OUTPUT:
	RETVAL

int
pq_get_item_count(pq)
	POE::XS::Queue::Array pq

void
pq_remove_item(pq, id, filter)
	POE::XS::Queue::Array pq
	int id
	SV *filter
      PREINIT:
	pq_entry removed;
      PPCODE:
	if (pq_remove_item(pq, id, filter, &removed)) {
	  EXTEND(SP, 3);
	  PUSHs(sv_2mortal(newSVnv(removed.priority)));
	  PUSHs(sv_2mortal(newSViv(removed.id)));
	  PUSHs(sv_2mortal(removed.payload));
        }

void
pq_remove_items(pq, filter, ...)
	POE::XS::Queue::Array pq
	SV *filter
      PREINIT:
	int max_count;
	pq_entry *removed_entries = NULL;
	int removed_count;
	int i;
      PPCODE:
	if (items > 2)
          max_count = SvIV(ST(2));
        else
          max_count = pq_get_item_count(pq);
	removed_count = pq_remove_items(pq, filter, max_count, 
                                        &removed_entries);
        if (removed_count) {
	  EXTEND(SP, removed_count);
          for (i = 0; i < removed_count; ++i) {
	    pq_entry *entry = removed_entries + i;
	    AV *av = newAV();
	    SV *rv;
	    av_extend(av, 2);
	    av_store(av, 0, newSVnv(entry->priority));
	    av_store(av, 1, newSViv(entry->id));
	    av_store(av, 2, entry->payload);
	    rv = newRV_noinc((SV *)av);
	    PUSHs(sv_2mortal(rv));
          }
	}
	if (removed_entries)
          myfree(removed_entries);

void
pq_adjust_priority(pq, id, filter, delta)
	POE::XS::Queue::Array pq
	int id
	SV *filter
	double delta
      PREINIT:
        pq_priority_t new_priority;
      PPCODE:
        if (pq_adjust_priority(pq, id, filter, delta, &new_priority)) {
	  EXTEND(SP, 1);
	  PUSHs(sv_2mortal(newSVnv(new_priority)));
	}

void
pq_set_priority(pq, id, filter, new_priority)
	POE::XS::Queue::Array pq
	int id
	SV *filter
	double new_priority
      PPCODE:
        if (pq_set_priority(pq, id, filter, new_priority)) {
	  EXTEND(SP, 1);
	  PUSHs(sv_2mortal(newSVnv(new_priority)));
	}

void
pq_peek_items(pq, filter, ...)
	POE::XS::Queue::Array pq
	SV *filter
      PREINIT:
        pq_entry *ret_items;
        int count, i;
	int max_count;
      PPCODE:
        if (items == 3)
          max_count = SvIV(ST(2));
        else
          max_count = pq_get_item_count(pq);
        count = pq_peek_items(pq, filter, max_count, &ret_items);
        if (count) {
          EXTEND(SP, count);
          for (i = 0; i < count; ++i) {
	    pq_entry *entry = ret_items + i;
	    AV *av = newAV();
	    SV *rv;
	    av_extend(av, 2);
	    av_store(av, 0, newSVnv(entry->priority));
	    av_store(av, 1, newSViv(entry->id));
	    av_store(av, 2, newSVsv(entry->payload));
	    rv = newRV_noinc((SV *)av);
	    PUSHs(sv_2mortal(rv));
	  }
          myfree(ret_items);
	}

void
pq_dump(pq)
	POE::XS::Queue::Array pq

void
pq_verify(pq)
	POE::XS::Queue::Array pq

# these are for testing errno is being set correctly for perl when
# set from XS
void
pq__set_errno_xs(value)
	int value
      CODE:
	errno = value;

void
pq__set_errno_queue(value)
	int value
