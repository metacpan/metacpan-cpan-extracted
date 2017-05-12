/*Queue implementation*/
typedef struct queue_element queue_element;

struct queue_element {
	void *val;
	struct queue_element *next;
};

typedef struct {
	queue_element *first;
	queue_element *last;
	int size;
} queue;

typedef struct {
	queue_element *prev;
	queue_element *cur;
} queue_iterator;

queue_iterator* queue_iterator_new(queue *q) {
	queue_iterator *it = malloc(sizeof(queue_iterator));
	it->prev = NULL;
	it->cur = q->first;
	
	return it;
}

void queue_iterator_next(queue_iterator *it) {
	it->prev = it->cur;
	if (it->cur != NULL) {
		it->cur = it->cur->next;
	}
}

char queue_iterator_end(queue_iterator *it) {
	return it->cur == NULL;
}

void queue_iterator_destroy(queue_iterator *it) {
	free(it);
}

queue* queue_new() {
	queue *q = malloc(sizeof(queue));
	q->first = q->last = NULL;
	q->size = 0;
	
	return q;
}

void queue_push(queue *q, void *val) {
	queue_element *q_e = malloc(sizeof(queue_element));
	q_e->val = val;
	q_e->next = NULL;
	
	if (q->first == NULL) {
		q->first = q->last = q_e;
	}
	else {
		q->last = q->last->next = q_e;
	}
	
	q->size++;
}

void* queue_shift(queue *q) {
	if (q->first == NULL) {
		return NULL;
	}
	
	queue_element *q_e = q->first;
	void *val = q_e->val;
	q->first = q_e->next;
	free(q_e);
	
	q->size--;
	return val;
}

void* queue_at(queue *q, queue_iterator *it) {
	if (it->cur == NULL)
		return NULL;
	
	return it->cur->val;
}

void queue_del(queue *q, queue_iterator *it) {
	if (it->cur == NULL)
		return;
	
	if (it->prev != NULL) {
		it->prev->next = it->cur->next;
	}
	else {
		q->first = it->cur->next;
	}
	
	if (q->last == it->cur)
		q->last = it->prev;
	
	queue_element *cur = it->cur;
	it->cur = it->cur->next;
	free(cur);
	
	q->size--;
}

void queue_clear(queue *q) {
	queue_element *q_e, *old;
	for (q_e = q->first; q_e != NULL; old = q_e, q_e = q_e->next, free(old));
	q->first = q->last = NULL;
	q->size = 0;
}

int queue_size(queue *q) {
	return q->size;
}

void queue_destroy(queue *q) {
	queue_element *q_e, *old;
	for (q_e = q->first; q_e != NULL; old = q_e, q_e = q_e->next, free(old));
	free(q);
}
