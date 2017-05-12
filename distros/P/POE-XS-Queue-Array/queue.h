#ifndef XSQUEUE_H
#define XSQUEUE_H

typedef unsigned pq_id_t;
typedef double pq_priority_t;

/* an entry in the queue */
typedef struct {
  pq_priority_t priority;
  pq_id_t id;
  SV *payload;
} pq_entry;

typedef struct poe_queue_tag poe_queue;

extern poe_queue *pq_create(void);
extern void
pq_delete(poe_queue *pq);
extern int
pq_enqueue(poe_queue *pq, pq_priority_t priority, SV *payload);
extern int
pq_get_item_count(poe_queue *pq);
extern int
pq_dequeue_next(poe_queue *pq, pq_priority_t *priority, pq_id_t *id, SV **payload);
extern int
pq_get_next_priority(poe_queue *pq, pq_priority_t *priority);
extern int
pq_remove_item(poe_queue *pq, pq_id_t id, SV *filter, pq_entry *removed);
extern int
pq_remove_items(poe_queue *pq, SV *filter, int max_count, pq_entry **entries);
extern int
pq_set_priority(poe_queue *pq, pq_id_t id, SV *filter, pq_priority_t new_priority);
extern int
pq_adjust_priority(poe_queue *pq, pq_id_t id, SV *filter, double delta, pq_priority_t *priority);
extern int
pq_peek_items(poe_queue *pq, SV *filter, int max_count, pq_entry **items);
extern void pq_dump(poe_queue *pq);
extern void pq_verify(poe_queue *pq);

extern void
pq__set_errno_queue(int value);

#endif
