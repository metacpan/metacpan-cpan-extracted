#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "queue.h"
#include "alloc.h"

/*#define DEBUG(x) x*/
#define DEBUG(x)
/*#define DEBUG_ERR(x) x*/
#define DEBUG_ERR(x)

/*#define KEEP_STATS 1*/

#if KEEP_STATS
#define STATS(x) x
#else
#define STATS(x)
#endif

#define PQ_START_SIZE 10
#define AT_START 0
#define AT_END 1

#define STUPID_IDS 0

#define LARGE_QUEUE_SIZE 50

/*
We store the queue in a similar way to the way perl deals with arrays,
we keep a block of memory, but the first element may or may not be in use,
depending on the pattern of usage.

There's 3 value controlling usage of the array:

  - alloc - the number of elements allocated in total
  - start - the first element in use in the array
  - end - one past the end of the last element in the array

This has the properties that:

  start == 0 - no space at the front
  end == alloc - no space at the end
  end - start - number of elements in the queue

We use a perl hash (HV *) to store the mapping from ids to priorities.

*/
struct poe_queue_tag {
  /* the first entry in use */
  int start;

  /* 1 past the last entry in use, hence end - start is the number of 
     entries in the queue */
  int end;

  /* the total number of entries allocated */
  int alloc;

  /* used to generate item ids */
  pq_id_t queue_seq;

  /* used to track in use item ids */
  HV *ids;

  /* the actual entries */
  pq_entry *entries;

#if KEEP_STATS
  int total_finds;
  int binary_finds;
#endif
};

/*
poe_create - create a new queue object.

No parameters.  returns the new queue object.

*/
poe_queue *
pq_create(void) {
  poe_queue *pq = mymalloc(sizeof(poe_queue));
  
  if (pq == NULL)
    croak("Out of memory");
  pq->start = 0;
  pq->end = 0;
  pq->alloc = PQ_START_SIZE;
  pq->queue_seq = 0;
  pq->ids = newHV();
  pq->entries = mymalloc(sizeof(pq_entry) * PQ_START_SIZE);
  memset(pq->entries, 0, sizeof(pq_entry) * PQ_START_SIZE);
  if (pq->entries == NULL)
    croak("Out of memory");

#if KEEP_STATS
  pq->total_finds = pq->binary_finds = 0;
#endif

  DEBUG( fprintf(stderr, "pq_create() => %p\n", pq) );

  return pq;
}

/*
pq_delete - release the queue object.

This also releases one reference from each SV in the queue.

*/
void
pq_delete(poe_queue *pq) {
  int i;

  DEBUG( fprintf(stderr, "pq_delete(%p)\n", pq) );
  if (pq->end > pq->start) {
    for (i = pq->start; i < pq->end; ++i) {
      SvREFCNT_dec(pq->entries[i].payload);
    }
  }
  SvREFCNT_dec((SV *)pq->ids);
  pq->ids = NULL;
  if (pq->entries)
    myfree(pq->entries);
  pq->entries = NULL;
  myfree(pq);
}

/*
pq_new_id - generate a new item id.

Internal use only.

This, the following 3 functions and pq_create, pq_delete, should be
all that needs to be modified if we change hash implementations.

*/
static
pq_id_t
pq_new_id(poe_queue *pq, pq_priority_t priority) {
#if STUPID_IDS
  int seq;
  int i;
  int found;
  
  do {
    seq = ++pq->queue_seq;
    found = 0;
    for (i = pq->start; i < pq->end; ++i) {
      if (pq->entries[i].id == seq) {
	found = 1;
	break;
      }
    }
  } while (found);

  return seq;
#else
  pq_id_t seq = ++pq->queue_seq;;

  while (hv_exists(pq->ids, (char *)&seq, sizeof(seq))) {
    seq = ++pq->queue_seq;
  }
  hv_store(pq->ids, (char *)&seq, sizeof(seq), newSVnv(priority), 0);
#endif

  return seq;
}

/*
pq_release_id - releases an id for future use.
*/
static
void
pq_release_id(poe_queue *pq, pq_id_t id) {
#if STUPID_IDS
#else
  hv_delete(pq->ids, (char *)&id, sizeof(id), 0);
#endif
}

/*
pq_item_priority - get the priority of an item given it's id
*/
static
int
pq_item_priority(poe_queue *pq, pq_id_t id, pq_priority_t *priority) {
#if STUPID_IDS
  int i;

  for (i = pq->start; i < pq->end; ++i) {
    if (pq->entries[i].id == id) {
      *priority = pq->entries[i].priority;
      return 1;
    }
  }

  return 0;
#else
  SV **entry = hv_fetch(pq->ids, (char *)&id, sizeof(id), 0);

  if (!entry || !*entry)
    return 0;

  *priority = SvNV(*entry);

  return 1;
#endif
}

/*
pq_set_id_priority - set the priority of an item in the id hash
*/
static
void
pq_set_id_priority(poe_queue *pq, pq_id_t id, pq_priority_t new_priority) {
#if STUPID_IDS
  /* nothing to do, caller set it in the array */
#else
  SV **entry = hv_fetch(pq->ids, (char *)&id, sizeof(id), 0);

  if (!entry && !*entry)
    croak("pq_set_priority: id not found");

  sv_setnv(*entry, new_priority);
#endif
}

/*
pq_move_items - moves items around.

This encapsulates the old calls to memmove(), providing a single place
to add error checking.
*/
static void
pq_move_items(poe_queue *pq, int target, int src, int count) {

  DEBUG_ERR(
  {
    int die = 0;
    if (src < pq->start) {
      fprintf(stderr, "src %d less than start %d\n", src, pq->start);
      ++die;
    }
    if (src + count > pq->end) {
      fprintf(stderr, "src %d + count %d beyond end %d\n", src, count, pq->end);
      ++die;
    }
    if (target < 0) {
      fprintf(stderr, "target %d < 0\n", target);
      ++die;
    }
    if (target + count > pq->alloc) {
      fprintf(stderr, "target %d + count %d > alloc %d\n", target, count, pq->alloc);
      ++die;
    }
    if (die) *(char *)0 = '\0';
  }
  )
  memmove(pq->entries + target, pq->entries + src, count * sizeof(pq_entry));
}

/*
pq_realloc - make space at the front of back of the queue.

This adjusts the queue to allow insertion of a single item at the
front or the back of the queue.

If the queue has 33% or more space available we simple adjust the
position of the in-use items within the array.  We try not to push the
items right up against the opposite end of the array, since we might
need to insert items there too.

If the queue has less than 33% space available we allocate another 50%
space.  We then only move the queue elements if we need space at the
front, since the reallocation has just opened up a huge space at the
back.  Since we're reallocating exponentially larger sizes we should
have a constant time cost on reallocation per queue item stored (but
other costs are going to be higher.)

*/
static
void
pq_realloc(poe_queue *pq, int at_end) {
  int count = pq->end - pq->start;

  DEBUG( fprintf(stderr, "pq_realloc((%d, %d, %d), %d)\n", pq->start, pq->end, pq->alloc, at_end) );
  if (count * 3 / 2 < pq->alloc) {
    /* 33 % or more space available, use some of it */
    int new_start;

    if (at_end) {
      new_start = (pq->alloc - count) / 3;
    }
    else {
      new_start = (pq->alloc - count) * 2 / 3;
    }
    DEBUG( fprintf(stderr, "  moving start to %d\n", new_start) );
    pq_move_items(pq, new_start, pq->start, count);
    pq->start = new_start;
    pq->end = new_start + count;
  }
  else {
    int new_alloc = pq->alloc * 3 / 2;
    pq->entries = myrealloc(pq->entries, sizeof(pq_entry) * new_alloc);
    pq->alloc = new_alloc;

    if (!pq->entries)
      croak("Out of memory");

    DEBUG( fprintf(stderr, "  - expanding to %d entries\n", new_alloc) );

    if (!at_end) {
      int new_start = (new_alloc - count) * 2 / 3;
      DEBUG( fprintf(stderr, "  moving start to %d\n", new_start) );
      pq_move_items(pq, new_start, pq->start, count);
      pq->start = new_start;
      pq->end = new_start + count;
    }
  }
  DEBUG( fprintf(stderr, "  final: %d %d %d\n", pq->start, pq->end, pq->alloc) );
}

/*
pq_insertion_point - figure out where to insert an item with the given
priority

Internal.
*/
static
int
pq_insertion_point(poe_queue *pq, pq_priority_t priority) {
  if (pq->end - pq->start < LARGE_QUEUE_SIZE) {
    int i = pq->end;
    while (i > pq->start &&
           priority < pq->entries[i-1].priority) {
      --i;
    }
    return i;
  }
  else {
    int lower = pq->start;
    int upper = pq->end - 1;
    while (1) {
      int midpoint = (lower + upper) >> 1;

      if (upper < lower)
        return lower;
      
      if (priority < pq->entries[midpoint].priority) {
        upper = midpoint - 1;
        continue;
      }
      if (priority > pq->entries[midpoint].priority) {
        lower = midpoint + 1;
        continue;
      }
      while (midpoint < pq->end &&
             priority == pq->entries[midpoint].priority) {
        ++midpoint;
      }
      return midpoint;
    }
  }
}

int
pq_enqueue(poe_queue *pq, pq_priority_t priority, SV *payload) {
  int fill_at;
  pq_id_t id = pq_new_id(pq, priority);

  DEBUG( fprintf(stderr, "pq_enqueue(%f, %p)\n", priority, payload) );
  if (pq->start == pq->end) {
    DEBUG( fprintf(stderr, "  - on empty queue\n") );
    /* allow room at front and back for new entries */
    pq->start = pq->alloc / 3;
    pq->end = pq->start + 1;
    fill_at = pq->start;
  }
  else if (priority >= pq->entries[pq->end-1].priority) {
    DEBUG( fprintf(stderr, "  - at the end\n") );
    if (pq->end == pq->alloc)
      /* past the end - need to realloc or make some space */
      pq_realloc(pq, AT_END);
    
    fill_at = pq->end;
    ++pq->end;
  }
  else if (priority < pq->entries[pq->start].priority) {
    DEBUG( fprintf(stderr, "  - at the front\n") );
    if (pq->start == 0)
      /* no space at the front, make some */
      pq_realloc(pq, AT_START);

    --pq->start;
    fill_at = pq->start;
  }
  else {
    int i;
    DEBUG( fprintf(stderr, "  - in the middle\n") );
    i = pq_insertion_point(pq, priority);
    
    /* if we're near the end we want to push entries up, otherwise down */
    if (i - pq->start > (pq->end - pq->start) / 2) {
      DEBUG( fprintf(stderr, "    - closer to the back (%d -> [ %d %d ])\n",
                     i, pq->start, pq->end) );
      /* make sure we have space, this might end up copying twice, 
	 but too bad for now */
      if (pq->end == pq->alloc) {
        int old_start = pq->start;
	pq_realloc(pq, AT_END);
        i += pq->start - old_start;
      }
      
      pq_move_items(pq, i+1, i, pq->end - i);
      ++pq->end;
      fill_at = i;
    }
    else {
      DEBUG( fprintf(stderr, "    - closer to the front (%d -> [ %d %d ])\n",
                     i, pq->start, pq->end) );
      if (pq->start == 0) {
	pq_realloc(pq, AT_START);
	i += pq->start;
      }
      pq_move_items(pq, pq->start-1, pq->start, i - pq->start);
      --pq->start;
      fill_at = i-1;
    }
  }
  pq->entries[fill_at].priority = priority;
  pq->entries[fill_at].id = id;
  pq->entries[fill_at].payload = newSVsv(payload);

  return id;
}

/*
  Note: it's up to the caller to release the SV.  The XS code does this 
  by making it mortal.
*/
int
pq_dequeue_next(poe_queue *pq, pq_priority_t *priority, pq_id_t *id, SV **payload) {
  pq_entry *entry;
  /* the caller needs to release the payload (somehow) */
  if (pq->start == pq->end)
    return 0;

  entry = pq->entries + pq->start++;
  *priority = entry->priority;
  *id = entry->id;
  *payload = entry->payload;
  pq_release_id(pq, entry->id);

  return 1;
}

int
pq_get_next_priority(poe_queue *pq, pq_priority_t *priority) {
  if (pq->start == pq->end)
    return 0;

  *priority = pq->entries[pq->start].priority;
  return 1;
}

int
pq_get_item_count(poe_queue *pq) {
  return pq->end - pq->start;
}

/*
pq_test_filter - the XS magic involved in passing the payload to a
filter function.
*/
static
int
pq_test_filter(pq_entry *entry, SV *filter) {
  /* man perlcall for the magic here */
  dSP;
  int count;
  SV *result_sv;
  int result;

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVsv(entry->payload)));
  PUTBACK;

  count = call_sv(filter, G_SCALAR);

  SPAGAIN;

  if (count != 1) 
    croak("got other than 1 value in scalar context");

  result_sv = POPs;
  result = SvTRUE(result_sv);

  PUTBACK;
  FREETMPS;
  LEAVE;

  return result;
}

/*
pq_find_item - search for an item we know is there.

Internal.
*/
static
int
pq_find_item(poe_queue *pq, pq_id_t id, pq_priority_t priority) {
  int i;

  STATS(++pq->total_finds);
  if (pq->end - pq->start < LARGE_QUEUE_SIZE) {
    for (i = pq->start; i < pq->end; ++i) {
      if (pq->entries[i].id == id)
        return i;
    }
    DEBUG(fprintf(stderr, "pq_find_item %d => %f\n", id, priority) );
    croak("Internal inconsistency: event should have been found");
  }

  /* try a binary search */
  /* simply translated from the perl */
  STATS(++pq->binary_finds);
  {
    int lower = pq->start;
    int upper = pq->end - 1;
    int linear_point;
    while (1) {
      int midpoint = (upper + lower) >> 1;
      if (upper < lower) {
        croak("Internal inconsistency, priorities out of order");
      }
      if (priority < pq->entries[midpoint].priority) {
        upper = midpoint - 1;
        continue;
      }
      if (priority > pq->entries[midpoint].priority) {
        lower = midpoint + 1;
        continue;
      }
      linear_point = midpoint;
      while (linear_point >= pq->start &&
             priority == pq->entries[linear_point].priority) {
        if (pq->entries[linear_point].id == id)
          return linear_point;
        --linear_point;
      }
      linear_point = midpoint;
      while ( (++linear_point < pq->end) &&
              priority == pq->entries[linear_point].priority) {
        if (pq->entries[linear_point].id == id)
          return linear_point;
      }

      croak("internal inconsistency: event should have been found");
    }
  }
}

int
pq_remove_item(poe_queue *pq, pq_id_t id, SV *filter, pq_entry *removed) {
  pq_priority_t priority;
  int index;

  if (!pq_item_priority(pq, id, &priority)) {
    errno = ESRCH;
    return 0;
  }

  index = pq_find_item(pq, id, priority);

  if (!pq_test_filter(pq->entries + index, filter)) {
    errno = EPERM;
    return 0;
  }

  *removed = pq->entries[index];
  pq_release_id(pq, id);
  if (index == pq->start) {
    ++pq->start;
  }
  else if (index == pq->end - 1) {
    --pq->end;
  }
  else {
    pq_move_items(pq, index, index+1, pq->end - index - 1);
    --pq->end;
  }
  DEBUG( fprintf(stderr, "removed (%d, %p (%d))\n", id, removed->payload,
		 SvREFCNT(removed->payload)) );

  return 1;
}

int
pq_remove_items(poe_queue *pq, SV *filter, int max_count, pq_entry **entries) {
  int in_index, out_index;
  int remove_count = 0;
  
  *entries = NULL;
  if (pq->start == pq->end)
    return 0;

  *entries = mymalloc(sizeof(pq_entry) * (pq->end - pq->start));
  if (!*entries)
    croak("Out of memory");
  
  in_index = out_index = pq->start;
  while (in_index < pq->end && remove_count < max_count) {
    if (pq_test_filter(pq->entries + in_index, filter)) {
      pq_release_id(pq, pq->entries[in_index].id);
      (*entries)[remove_count++] = pq->entries[in_index++];
    }
    else {
      pq->entries[out_index++] = pq->entries[in_index++];
    }
  }
  while (in_index < pq->end) {
    pq->entries[out_index++] = pq->entries[in_index++];
  }
  pq->end = out_index;
  
  return remove_count;
}

/*
We need to keep the following 2 functions in sync (or combine the
common code.)
*/
int
pq_set_priority(poe_queue *pq, pq_id_t id, SV *filter, pq_priority_t new_priority) {
  pq_priority_t old_priority;
  int index, insert_at;

  if (!pq_item_priority(pq, id, &old_priority)) {
    errno = ESRCH;
    return 0;
  }

  index = pq_find_item(pq, id, old_priority);

  if (!pq_test_filter(pq->entries + index, filter)) {
    errno = EPERM;
    return 0;
  }

  DEBUG( fprintf(stderr, " - index %d  oldp %f newp %f\n", index, old_priority, new_priority) );

  if (pq->end - pq->start == 1) {
    DEBUG( fprintf(stderr, "   -- one item\n") );
    /* only the one item anyway */
    pq->entries[pq->start].priority = new_priority;
  }
  else {
    insert_at = pq_insertion_point(pq, new_priority);
    DEBUG( fprintf(stderr, "   - new index %d\n", insert_at) );
    /* the item is still in the queue, so either side of it means it
       won't move */
    if (insert_at == index || insert_at == index+1) {
      DEBUG( fprintf(stderr, "   -- change in place\n") );
      pq->entries[index].priority = new_priority;
    }
    else {
      pq_entry saved = pq->entries[index];
      saved.priority = new_priority;

      if (insert_at < index) {
        DEBUG( fprintf(stderr, "  - insert_at < index\n") );
	pq_move_items(pq, insert_at + 1, insert_at, index - insert_at);
        pq->entries[insert_at] = saved;
      }
      else {
        DEBUG( fprintf(stderr, "  - insert_at > index\n") );
	--insert_at;
	pq_move_items(pq, index, index + 1, insert_at - index);
        pq->entries[insert_at] = saved;
      }
    }
  }

  pq_set_id_priority(pq, id, new_priority);

  return 1;  
}

int
pq_adjust_priority(poe_queue *pq, pq_id_t id, SV *filter, double delta, pq_priority_t *priority) {
  pq_priority_t old_priority, new_priority;
  int index, insert_at;

  DEBUG( fprintf(stderr, "pq_adjust_priority(..., %d, %p, %f, ...)\n", id, filter, delta) );

  if (!pq_item_priority(pq, id, &old_priority)) {
    errno = ESRCH;
    return 0;
  }

  index = pq_find_item(pq, id, old_priority);

  if (!pq_test_filter(pq->entries + index, filter)) {
    errno = EPERM;
    return 0;
  }

  new_priority = old_priority + delta;

  DEBUG( fprintf(stderr, " - index %d  oldp %f newp %f\n", index, old_priority, new_priority) );

  if (pq->end - pq->start == 1) {
    DEBUG( fprintf(stderr, "   -- one item\n") );
    /* only the one item anyway */
    pq->entries[pq->start].priority = new_priority;
  }
  else {
    insert_at = pq_insertion_point(pq, new_priority);
    DEBUG( fprintf(stderr, "   - new index %d\n", insert_at) );
    /* the item is still in the queue, so either side of it means it
       won't move */
    if (insert_at == index || insert_at == index+1) {
      DEBUG( fprintf(stderr, "   -- change in place\n") );
      pq->entries[index].priority = new_priority;
    }
    else {
      pq_entry saved = pq->entries[index];
      saved.priority = new_priority;

      if (insert_at < index) {
        DEBUG( fprintf(stderr, "  - insert_at < index\n") );
	pq_move_items(pq, insert_at + 1, insert_at, index - insert_at);
        pq->entries[insert_at] = saved;
      }
      else {
        DEBUG( fprintf(stderr, "  - insert_at > index\n") );
	--insert_at;
	pq_move_items(pq, index, index + 1, insert_at - index);
        pq->entries[insert_at] = saved;
      }
    }
  }

  pq_set_id_priority(pq, id, new_priority);
  *priority = new_priority;

  return 1;  
}

int
pq_peek_items(poe_queue *pq, SV *filter, int max_count, pq_entry **items) {
  int count = 0;
  int i;

  *items = NULL;
  if (pq->end == pq->start)
    return 0;

  *items = mymalloc(sizeof(pq_entry) * (pq->end - pq->start));
  for (i = pq->start; i < pq->end; ++i) {
    if (pq_test_filter(pq->entries + i, filter)) {
      (*items)[count++] = pq->entries[i];
    }
  }
  if (!count) {
    myfree(*items);
    *items = NULL;
  }

  return count;
}

/*
pq_dump - dump the internals of the queue structure.
*/
void
pq_dump(poe_queue *pq) {
  int i;
  HE *he;

  fprintf(stderr, "poe_queue\n");
  fprintf(stderr, "  start: %d\n", pq->start);
  fprintf(stderr, "    end: %d\n", pq->end);
  fprintf(stderr, "  alloc: %d\n", pq->alloc);
  fprintf(stderr, "    seq: %d\n", pq->queue_seq);
  fprintf(stderr, "  **Queue Entries:\n"
         "      index:   id  priority    SV\n");
  for (i = pq->start; i < pq->end; ++i) {
    pq_entry *entry = pq->entries + i;
    fprintf(stderr, "      %5d: %5d %8f  %p (%u)\n", i, entry->id, entry->priority,
	   entry->payload, (unsigned)SvREFCNT(entry->payload));
  }
  fprintf(stderr, "  **Hash entries:\n");
  hv_iterinit(pq->ids);
  while ((he = hv_iternext(pq->ids)) != NULL) {
    STRLEN len;
    fprintf(stderr, "   %d => %f\n", *(pq_id_t *)HePV(he, len), SvNV(hv_iterval(pq->ids, he)));
  }
}

/*
pq_verify - basic verification of the structure of the queue

For now check for duplicate ids in sequence.
*/
void
pq_verify(poe_queue *pq) {
  int i;
  int lastid;
  int found_err = 0;

  if (pq->start != pq->end) {
    lastid = pq->entries[pq->start].id;
    i = pq->start + 1;
    while (i < pq->end) {
      if (pq->entries[i].id == lastid) {
        fprintf(stderr, "Duplicate id %d at %d\n", lastid, i);
        ++found_err;
      }
      ++i;
    }
  }
  if (found_err) {
    pq_dump(pq);
    exit(1);
  }
}

/*
pq__set_errno_queue - set errno

This just sets errno for testing purposes.
*/
void
pq__set_errno_queue(int value) {
  errno = value;
}

