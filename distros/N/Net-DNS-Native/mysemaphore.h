typedef struct
{
	unsigned int count;
	unsigned long waiters_count;
	pthread_mutex_t lock;
	pthread_cond_t count_nonzero;
} my_sem_t;

int my_sem_init(my_sem_t *s, int shared, unsigned int initial_count) {
	int rc;
	rc = pthread_mutex_init(&s->lock, NULL);
	if (rc != 0) return rc;
	
	rc = pthread_cond_init(&s->count_nonzero, NULL);
	if (rc != 0) return rc;
	
	s->count = initial_count;
	s->waiters_count = 0;
	
	return 0;
}

int my_sem_wait(my_sem_t *s) {
	// Acquire mutex to enter critical section.
	pthread_mutex_lock(&s->lock);
	
	// Keep track of the number of waiters so that <sem_post> works correctly.
	s->waiters_count++;
	
	// Wait until the semaphore count is > 0, then atomically release
	// <lock> and wait for <count_nonzero> to be signaled. 
	while (s->count == 0)
		pthread_cond_wait(&s->count_nonzero, &s->lock);
	// <s->lock> is now held.
	
	// Decrement the waiters count.
	s->waiters_count--;
	
	// Decrement the semaphore's count.
	s->count--;
	
	// Release mutex to leave critical section.
	pthread_mutex_unlock(&s->lock);
	
	return 0;
}

int my_sem_post(my_sem_t *s) {
	pthread_mutex_lock(&s->lock);
	
	// Always allow one thread to continue if it is waiting.
	if (s->waiters_count > 0)
		pthread_cond_signal(&s->count_nonzero);
	
	// Increment the semaphore's count.
	s->count++;
	pthread_mutex_unlock(&s->lock);
	
	return 0;
}

int my_sem_destroy(my_sem_t *s) {
	int rc;
	rc = pthread_mutex_destroy(&s->lock);
	if (rc != 0) return rc;
	
	rc = pthread_cond_destroy(&s->count_nonzero);
	if (rc != 0) return rc;
	
	return 0;
}
