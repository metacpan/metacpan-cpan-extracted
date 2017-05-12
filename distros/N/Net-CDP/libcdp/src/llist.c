/*
 * $Id: llist.c,v 1.1 2005/07/20 13:44:13 mchapman Exp $
 */

#include <system.h>

cdp_llist_t *
cdp_llist_new(cdp_dup_fn_t dup_fn, cdp_free_fn_t free_fn) {
	cdp_llist_t *result;

	assert(dup_fn);
	assert(free_fn);

	result = CALLOC(1, cdp_llist_t);
	result->dup_fn = dup_fn;
	result->free_fn = free_fn;
	return result;
}

cdp_llist_t *
cdp_llist_dup(const cdp_llist_t *llist) {
	cdp_llist_t *result;
	cdp_llist_iter_t iter;

	assert(llist);

	result = cdp_llist_new(llist->dup_fn, llist->free_fn);
	for (iter = cdp_llist_iter(llist); iter; iter = cdp_llist_next(iter))
		cdp_llist_append(result, (llist->dup_fn)(cdp_llist_get(iter)));

	return result;
}

void
cdp_llist_append(cdp_llist_t *llist, void *x) {
	cdp_llist_item_t *item;

	assert(llist);

	item = CALLOC(1, cdp_llist_item_t);
	item->x = x;
	if (llist->tail)
		llist->tail->next = item;
	else
		llist->head = item;
	llist->tail = item;
	llist->count++;
}

void
cdp_llist_transfer(cdp_llist_t *llist, cdp_llist_t *src) {
	assert(llist);
	assert(src);
	assert(llist->dup_fn == src->dup_fn);
	assert(llist->free_fn == src->free_fn);

	if (llist->tail)
		llist->tail->next = src->head;
	else
		llist->head = src->head;
	llist->tail = src->tail;
	llist->count += src->count;
	src->head = src->tail = NULL;
	src->count = 0;
}

void
cdp_llist_free(cdp_llist_t *llist) {
	cdp_llist_iter_t iter, next;

	assert(llist);

	for (iter = cdp_llist_iter(llist); iter; iter = next) {
		next = cdp_llist_next(iter);
		(*llist->free_fn)cdp_llist_get(iter);
		FREE((cdp_llist_item_t *)iter);
	}
	FREE(llist);
}
