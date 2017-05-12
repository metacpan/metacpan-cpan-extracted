/*
 * Copyright (c) 2000 Charles Ying. All rights reserved.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as perl itself.
 *
 * Please note that this code falls under a different license than the
 * other code found in Sendmail::Milter.
 *
 */

#ifndef __INTPOOLS_H_
#define __INTPOOLS_H_

struct interp_t
{
	PerlInterpreter *perl;
	void *cache;
	int requests;
};

typedef struct interp_t interp_t;

struct intpool_t
{
	pthread_mutex_t		ip_mutex;
	pthread_cond_t		ip_cond;

	PerlInterpreter		*ip_parent;

	int ip_max;
	int ip_retire;

	int ip_busycount;

	AV*			ip_freequeue;
};

typedef struct intpool_t intpool_t;


extern void init_interpreters(intpool_t *, int, int);
extern void cleanup_interpreters(intpool_t *);

extern interp_t *lock_interpreter(intpool_t *);
extern void unlock_interpreter(intpool_t *, interp_t *);

extern interp_t *create_interpreter(intpool_t *);
extern void cleanup_interpreter(intpool_t *, interp_t *);

extern void alloc_interpreter_cache(interp_t *interp, size_t size);
extern void free_interpreter_cache(interp_t *interp);

extern int test_intpools(pTHX_ int, int, int, int, SV*);

#endif /* __INTPOOLS_H_ */

