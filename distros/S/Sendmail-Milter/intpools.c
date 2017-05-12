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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <pthread.h>

#include "intpools.h"

/*
**  INIT_INTERPRETERS -- initialize the interpreter pool
**
**	Parameters:
**		ipool -- interpreter pool
**		max_interp -- the maximum limit on interpreters allowed.
**		max_requests -- the maximum limit on requests perinterpreter.
**
**	Returns:
**		none.
**
**	Side Effects:
**		Sets up the global variables for the interpreter pool.
*/

void
init_interpreters(ipool, max_interp, max_requests)
	intpool_t *ipool;
	int max_interp;
	int max_requests;
{
	int error;

	memset(ipool, 0, sizeof(intpool_t));

	/* Initialize the mutex */
	if ((error = pthread_mutex_init(&(ipool->ip_mutex), NULL)) != 0)
		croak("intpool pthread_mutex_init failed: %d", error);

	/* Initialize the condition variable */
	if ((error = pthread_cond_init(&(ipool->ip_cond), NULL)) != 0)
		croak("intpool pthread_cond_init() failed: %d", error);

	/* Lock interpreter table */
	if ((error = pthread_mutex_lock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_lock() failed: %d", error);

	/* Critical section */

	/* Initialize the max number of interpreters */
	ipool->ip_max = max_interp;
	ipool->ip_retire = max_requests;

	/* Initialize the free table */
	ipool->ip_freequeue = (AV*) newAV();

	/* Set the number of busy interpreters to zero. */
	ipool->ip_busycount = 0;

	/* This is the global interpreter that thread wrappers will clone .*/
	ipool->ip_parent = PERL_GET_CONTEXT;

	/* End critical section */

	/* Unlock interpreter table */
	if ((error = pthread_mutex_unlock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_unlock() failed: %d", error);
}


/*
**  ALLOC_INTERPRETER_CACHE -- Allocate memory for interpreter cache.
**
**	Parameters:
**		interp -- Interpreter to allocate cache for.
**		size -- Size of cache to allocate.
**
**	Returns:
**		none.
**
**	Warning:
**		This routine is not thread-safe.
*/

void
alloc_interpreter_cache(interp_t *interp, size_t size)
{
	if ((interp->cache = malloc(size)) == NULL)
		croak("failed to allocate memory for interpreter cache.");
}

/*
**  FREE_INTERPRETER_CACHE -- Free memory used by interpreter cache.
**
**	Parameters:
**		interp -- Interpreter to free cache for.
**
**	Returns:
**		none.
**
**	Warning:
**		This routine is not thread-safe.
*/

void
free_interpreter_cache(interp_t *interp)
{
	free(interp->cache);
	interp->cache = NULL;
}


/*
**  CREATE_INTERPRETER -- create an interpreter from the parent.
**
**	Parameters:
**		ipool -- interpreter pool
**
**	Returns:
**		An interpreter context cloned off the parent.
**
**	Warning:
**		This routine is not thread-safe.
*/

interp_t *
create_interpreter(ipool)
	intpool_t *ipool;
{
	interp_t *new_interp;

	/* Clone the reference interpreter and use that. */
	new_interp = (interp_t *) malloc(sizeof(interp_t));

	new_interp->perl = perl_clone(ipool->ip_parent, FALSE);
	new_interp->requests = 1;
	new_interp->cache = NULL;

	{
		/* Hack from modperl until Perl 5.6.1 */
		dTHXa(new_interp->perl);
		if (PL_scopestack_ix == 0)
		{
			/* ENTER could expand. A lot. */
			ENTER;
		}
	}

	/* Restore the parent interpreter after a perl_clone() */
	PERL_SET_CONTEXT(ipool->ip_parent);

	return new_interp;
}


/*
**  CLEANUP_INTERPRETER -- destroy an interpreter
**
**	Parameters:
**		ipool -- interpreter pool
**		del_interp - the interp_t to destroy.
**
**	Returns:
**		none.
**
**	Warning:
**		This routine is not thread-safe.
*/

void
cleanup_interpreter(ipool, del_interp)
	intpool_t *ipool;
	interp_t *del_interp;
{
	perl_destruct(del_interp->perl);
	perl_free(del_interp->perl);

	free_interpreter_cache(del_interp);

	free(del_interp);
}


/*
**  LOCK_INTERPRETER -- lock and retrieve a perl interpreter
**
**	Parameters:
**		ipool -- interpreter pool
**
**	Returns:
**		An interpreter context out of the interpreter pool.
**
**	Side Effects:
**		The caller has exclusive rights to the interpreter
**		until the caller unlocks the interpreter.
**
**	Warning:
**		This routine will block until a free interpreter
**		is available.
**
**		(A timeout might be implemented in the future)
*/

interp_t *
lock_interpreter(ipool)
	intpool_t *ipool;
{
	int error;
	SV *sv_value;
	interp_t *new_interp;

	/* Lock interpreter table */
	if ((error = pthread_mutex_lock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_lock() failed: %d", error);

	/* Critical section */

	/*
	**  Predicate: Any available interpreters? (Free or createable)
	**
	**  ASSERT: ipool->ip_busycount always contains the number of
	**          interpreters that are locked in the system.
	*/

	while ( !((ipool->ip_max == 0) ||
		  (ipool->ip_busycount < ipool->ip_max)) )
	{
		/* No. */

		/* P(): Lock on the condition variable. */
		if ((error = pthread_cond_wait( &(ipool->ip_cond),
						&(ipool->ip_mutex) )) != 0)
		{
			croak("cond_wait failed waiting for interpreter: %d",
				error);
		}

		/* When we wake up again, we might get a new interpreter. */
	}

	/* Restore the parent interpreter context */
	PERL_SET_CONTEXT(ipool->ip_parent);

	/* Any free interpreters on the queue? */
	if (av_len(ipool->ip_freequeue) != -1)
	{
		/* Reuse an old interpreter */
		sv_value = av_shift(ipool->ip_freequeue);

		new_interp = (interp_t *) SvIV(sv_value);

		/* Decrement the reference count. */
		(void) SvREFCNT_dec(sv_value);

		/* Increase the number of requests. */
		new_interp->requests++;

		/* Increment the number of busy interpreters */
		ipool->ip_busycount++;
	}
	else /* No, there aren't, but we can still create one. */
	{
		new_interp = create_interpreter(ipool);

		/* Increment the number of busy interpreters */
		ipool->ip_busycount++;
	}

	/* End critical section */

	/* Restore the parent interpreter context. */
	PERL_SET_CONTEXT(ipool->ip_parent);

	/* Unlock interpreter table */
	if ((error = pthread_mutex_unlock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_unlock() failed: %d", error);

	return new_interp;
}


/*
**  UNLOCK_INTERPRETER -- unlock a perl interpreter
**
**	Parameters:
**		ipool -- interpreter pool
**		busy_interp -- the interpreter context to unlock.
**
**	Returns:
**		none.
**
**	Side Effects:
**		The interpreter is placed back in the interpreter pool
**		and the caller should immediately discard its pointer
**		to the interpreter.
*/

void
unlock_interpreter(ipool, busy_interp)
	intpool_t *ipool;
	interp_t *busy_interp;
{
	int error;

	/* Lock interpreter table */
	if ((error = pthread_mutex_lock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_lock() failed: %d", error);

	/* Critical section */

	/* Restore the parent interpreter context. */
	PERL_SET_CONTEXT(ipool->ip_parent);

	/* ASSERT(ipool->ip_busycount > 0)
	if (ipool->ip_busycount <= 0)
		croak("internal error: busy_count reached zero unexpectedly.");

	/* Decrement the number of busy interpreters */	
	ipool->ip_busycount--;

	if ((ipool->ip_retire != 0) &&
	    (busy_interp->requests > ipool->ip_retire))
	{
		/* Interpreter is too old, recycle it. */
		cleanup_interpreter(ipool, busy_interp);

		busy_interp = create_interpreter(ipool);
	}

	/* Stick busy_interp in the free table */
	(void) av_push(ipool->ip_freequeue, newSViv((IV) busy_interp));

	/* V(): Signal a thread that a new interpreter is available. */
	if ((error = pthread_cond_signal(&(ipool->ip_cond))) != 0)
	{
		croak("cond_signal failed to signal a free interpreter: %d",
			error);
	}

	/* Restore the parent interpreter context. */
	PERL_SET_CONTEXT(ipool->ip_parent);

	/* End critical section */

	/* Unlock interpreter table */
	if ((error = pthread_mutex_unlock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_unlock() failed: %d", error);
}


/*
**  CLEANUP_INTERPRETERS -- clean up the interpreter pool
**
**	Parameters:
**		ipool -- interpreter pool
**
**	Returns:
**		none.
**
**	Side Effects:
**		Shuts down and cleans up the interpreter pool.
**
**	Warning:
**		All interpreters should be unlocked before
**		calling this routine.
*/

void
cleanup_interpreters(ipool)
	intpool_t *ipool;
{
	int error;
	SV *sv_value;
	interp_t *del_interp;

	/* Lock interpreter table */
	if ((error = pthread_mutex_lock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_lock() failed: %d", error);

	/* Critical section */

	/* Restore the original interpreter context. */
	PERL_SET_CONTEXT(ipool->ip_parent);

	/* At some point, we really should V() all of the waiting threads. */
	while (av_len(ipool->ip_freequeue) != -1)
	{
		/* Reuse an old interpreter */
		sv_value = av_shift(ipool->ip_freequeue);

		del_interp = (interp_t *) SvIV(sv_value);

		/* Decrement the reference count. */
		(void) SvREFCNT_dec(sv_value);

		cleanup_interpreter(ipool, del_interp);
	}

	av_undef(ipool->ip_freequeue);
	ipool->ip_freequeue = NULL;

	/* Restore the original interpreter context. */
	PERL_SET_CONTEXT(ipool->ip_parent);

	/* End critical section */

	/* Unlock interpreter table */
	if ((error = pthread_mutex_unlock(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_unlock() failed: %d", error);

	/* Destroy the condition variable */
	if ((error = pthread_cond_destroy(&(ipool->ip_cond))) != 0)
		croak("intpool pthread_cond_destroy() failed: %d", error);

	/* Destroy the intpool mutex */
	if ((error = pthread_mutex_destroy(&(ipool->ip_mutex))) != 0)
		croak("intpool pthread_mutex_destroy() failed: %d", error);
}


/* ---+ Interpreter pools test code. -------------------------------------- */

typedef void *(*test_callback_ptr)(void *);

static intpool_t T_pool;

#define GLOBAL_TEST	"Sendmail::Milter::Callbacks::_test_callback"

void
test_run_callback(pTHX_ SV *callback)
{
	int error;

        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);

	XPUSHs(sv_2mortal(newSViv((IV) aTHX)));

        PUTBACK;

	printf("test_wrapper: Analysing callback...\n");

	if (SvROK(callback) && (SvTYPE(SvRV(callback)) == SVt_PVCV))
	{
		printf("test_wrapper: It's a code reference to: 0x%08x\n",
			SvRV(callback));
	}

	if (SvPOK(callback))
	{
		int len;
		printf("test_wrapper: pointer to string... string is '%s'\n",
			SvPV(callback, len));
	}

	printf("test_wrapper: Calling callback 0x%08x from aTHX 0x%08x.\n",
		callback, aTHX);

	call_sv(callback, G_DISCARD);

        SPAGAIN;
        PUTBACK;
        FREETMPS;
        LEAVE;
}

void *
test_callback_wrapper(void *arg)
{
        interp_t *interp;
	SV *callback;

        if ((interp = lock_interpreter(&T_pool)) == NULL)
                croak("test_wrapper: could not lock a new perl interpreter.");

	PERL_SET_CONTEXT(interp->perl);

	callback = get_sv(GLOBAL_TEST, FALSE);

	test_run_callback(aTHX_ callback);

        unlock_interpreter(&T_pool, interp);

        return NULL;
}

int
test_intpools(pTHX_ int max_interp, int max_requests, int i_max, int j_max,
	      SV* callback)
{
	int i;
	int j;
	pthread_t thread_id;
	SV *global_callback;

	printf("test_wrapper: Original interpreter cloned: 0x%08x\n", aTHX);

	init_interpreters(&T_pool, max_interp, max_requests);

	global_callback = get_sv(GLOBAL_TEST, TRUE);

	sv_setsv(global_callback, callback);

	for (i = 0; i < i_max; i++)
	{
		for (j = 0; j < j_max; j++)
			pthread_create(&thread_id, NULL,
				(test_callback_ptr) test_callback_wrapper,
					(void *)NULL);

		pthread_join(thread_id, NULL);
	}

	cleanup_interpreters(&T_pool);

	return 1;
}
