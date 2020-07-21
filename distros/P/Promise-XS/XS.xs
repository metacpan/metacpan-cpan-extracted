#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdbool.h>
#include <unistd.h>

#define MY_CXT_KEY "Promise::XS::_guts" XS_VERSION

#define BASE_CLASS "Promise::XS"

#define PROMISE_CLASS "Promise::XS::Promise"
#define PROMISE_CLASS_TYPE Promise__XS__Promise

#define DEFERRED_CLASS "Promise::XS::Deferred"
#define DEFERRED_CLASS_TYPE Promise__XS__Deferred

#ifdef PL_phase
#define PXS_IS_GLOBAL_DESTRUCTION PL_phase == PERL_PHASE_DESTRUCT
#else
#define PXS_IS_GLOBAL_DESTRUCTION PL_dirty
#endif

#define RESULT_IS_RESOLVED(result) (result->state == XSPR_RESULT_RESOLVED)
#define RESULT_IS_REJECTED(result) (result->state == XSPR_RESULT_REJECTED)

#define UNUSED(x) (void)(x)

typedef struct xspr_callback_s xspr_callback_t;
typedef struct xspr_promise_s xspr_promise_t;
typedef struct xspr_result_s xspr_result_t;
typedef struct xspr_callback_queue_s xspr_callback_queue_t;

typedef enum {
    XSPR_STATE_NONE,
    XSPR_STATE_PENDING,
    XSPR_STATE_FINISHED,
} xspr_promise_state_t;

typedef enum {
    XSPR_RESULT_NONE,
    XSPR_RESULT_RESOLVED,
    XSPR_RESULT_REJECTED,
    XSPR_RESULT_BOTH
} xspr_result_state_t;

typedef enum {
    // from then() or catch()
    XSPR_CALLBACK_PERL,

    // from finally()
    XSPR_CALLBACK_FINALLY,


    // from a promise returned from a then() or catch() callback
    XSPR_CALLBACK_CHAIN,

    // from a promise returned from a finally() callback
    XSPR_CALLBACK_FINALLY_CHAIN
} xspr_callback_type_t;

struct xspr_callback_s {
    xspr_callback_type_t type;

    union {
        struct {
            SV* on_resolve;
            SV* on_reject;
            xspr_promise_t* next;
        } perl;

        struct {
            SV* on_finally;
            xspr_promise_t* next;
        } finally;

        xspr_promise_t* chain;

        struct {
            xspr_result_t* original_result;
            xspr_promise_t* chain_promise;
        } finally_chain;
    };
};

struct xspr_result_s {
    xspr_result_state_t state;
    SV** results;
    int count;
    int refs;
    bool rejection_should_warn;
};

struct xspr_promise_s {
    xspr_promise_state_t state;
    pid_t detect_leak_pid;
    int refs;
    union {
        struct {
            xspr_callback_t** callbacks;
            int callbacks_count;
        } pending;
        struct {
            xspr_result_t *result;
        } finished;
    };
};

struct xspr_callback_queue_s {
    xspr_promise_t* origin;
    xspr_callback_t* callback;
    xspr_callback_queue_t* next;
};

xspr_callback_t* xspr_callback_new_perl(pTHX_ SV* on_resolve, SV* on_reject, xspr_promise_t* next);
xspr_callback_t* xspr_callback_new_chain(pTHX_ xspr_promise_t* chain);
xspr_callback_t* xspr_callback_new_finally_chain(pTHX_ xspr_result_t* original_result, xspr_promise_t* next_promise);
void xspr_callback_process(pTHX_ xspr_callback_t* callback, xspr_promise_t* origin);
void xspr_callback_free(pTHX_ xspr_callback_t* callback);

xspr_promise_t* xspr_promise_new(pTHX);
void xspr_promise_then(pTHX_ xspr_promise_t* promise, xspr_callback_t* callback);
void xspr_promise_finish(pTHX_ xspr_promise_t* promise, xspr_result_t *result);
void xspr_promise_incref(pTHX_ xspr_promise_t* promise);
void xspr_promise_decref(pTHX_ xspr_promise_t* promise);

xspr_result_t* xspr_result_new(pTHX_ xspr_result_state_t state, unsigned count);
xspr_result_t* pxs_result_clone(pTHX_ xspr_result_t* old);
xspr_result_t* xspr_result_from_error(pTHX_ const char *error);
void xspr_result_incref(pTHX_ xspr_result_t* result);
void xspr_result_decref(pTHX_ xspr_result_t* result);

xspr_result_t* xspr_invoke_perl(pTHX_ SV* perl_fn, SV** inputs, unsigned input_count);
xspr_promise_t* xspr_promise_from_sv(pTHX_ SV* input);


typedef struct {
    xspr_callback_queue_t* queue_head;
    xspr_callback_queue_t* queue_tail;
    int in_flush;
    int backend_scheduled;
#ifdef USE_ITHREADS
    tTHX owner;
#endif
    SV* conversion_helper;
    SV* pxs_flush_cr;
    HV* pxs_base_stash;
    HV* pxs_promise_stash;
    HV* pxs_deferred_stash;
    SV* deferral_cr;
    SV* deferral_arg;
} my_cxt_t;

typedef struct {
    xspr_promise_t* promise;
} DEFERRED_CLASS_TYPE;

typedef struct {
    xspr_promise_t* promise;
} PROMISE_CLASS_TYPE;

//----------------------------------------------------------------------

START_MY_CXT

/* Process a single callback */
void xspr_callback_process(pTHX_ xspr_callback_t* callback, xspr_promise_t* origin)
{
    assert(origin->state == XSPR_STATE_FINISHED);

    if (callback->type == XSPR_CALLBACK_CHAIN) {
        xspr_promise_finish(aTHX_ callback->chain, origin->finished.result);

    } else if (callback->type == XSPR_CALLBACK_FINALLY_CHAIN) {
        xspr_promise_finish(aTHX_
            callback->finally_chain.chain_promise,
            RESULT_IS_REJECTED(origin->finished.result) ? origin->finished.result : callback->finally_chain.original_result
        );

    } else if (callback->type == XSPR_CALLBACK_PERL || callback->type == XSPR_CALLBACK_FINALLY) {
        SV* callback_fn;
        xspr_promise_t* next_promise;

        if (callback->type == XSPR_CALLBACK_FINALLY) {
            callback_fn = callback->finally.on_finally;
            next_promise = callback->finally.next;

            /* A finally() “catches” its parent promise, even as it
               rethrows any failure from it. */
            if (callback_fn && SvOK(callback_fn)) {
                origin->finished.result->rejection_should_warn = false;
            }
        } else {
            next_promise = callback->perl.next;

            if (RESULT_IS_RESOLVED(origin->finished.result)) {
                callback_fn = callback->perl.on_resolve;
            } else if (RESULT_IS_REJECTED(origin->finished.result)) {
                callback_fn = callback->perl.on_reject;

                if (callback_fn && SvOK(callback_fn)) {
                    origin->finished.result->rejection_should_warn = false;
                }

            } else {
                callback_fn = NULL; /* Be quiet, bad compiler! */
                assert(0);
            }
        }

        if (callback_fn != NULL) {
            xspr_result_t* callback_result;

            if (callback->type == XSPR_CALLBACK_FINALLY) {
                callback_result = xspr_invoke_perl(aTHX_ callback_fn, NULL, 0);
            }
            else {
                callback_result = xspr_invoke_perl(aTHX_
                    callback_fn,
                    origin->finished.result->results,
                    origin->finished.result->count
                );
            }

            if (next_promise == NULL) {
                if (callback->type == XSPR_CALLBACK_FINALLY && RESULT_IS_RESOLVED(callback_result) && RESULT_IS_REJECTED(origin->finished.result)) {

                    /* This handles the case where finally() is called in
                       void context and the parent promise rejects. In this
                       case we need an unhandled-rejection warning right
                       away since, given the absence of a next_promise,
                       by definition we have an unhandled rejection.
                    */
                    xspr_result_decref(aTHX_ callback_result);
                    callback_result = pxs_result_clone( aTHX_ origin->finished.result );
                }
            }
            else {
                bool finish_promise = true;

                if (callback_result->count > 0 && callback_result->state == XSPR_RESULT_RESOLVED) {
                    xspr_promise_t* promise = xspr_promise_from_sv(aTHX_ callback_result->results[0]);

                    if (promise != NULL) {

                        if (callback_result->count > 1) {
                            warn( BASE_CLASS ": %d extra response(s) returned after promise! Treating promise like normal return.", callback_result->count - 1 );
                        }
                        else if (promise == next_promise) {
                            finish_promise = false;

                            /* This is an extreme corner case the A+ spec made us implement: we need to reject
                            * cases where the promise created from then() is passed back to its own callback */
                            xspr_result_t* chain_error = xspr_result_from_error(aTHX_ "TypeError");
                            xspr_promise_finish(aTHX_ next_promise, chain_error);

                            xspr_result_decref(aTHX_ chain_error);
                        }
                        else {
                            finish_promise = false;

                            /* Fairly normal case: we returned a promise from the callback */
                            xspr_callback_t* chainback;

                            if (callback->type == XSPR_CALLBACK_FINALLY) {
                                chainback = xspr_callback_new_finally_chain(aTHX_ origin->finished.result, next_promise);
                            }
                            else {
                                chainback = xspr_callback_new_chain(aTHX_ next_promise);
                            }

                            xspr_promise_then(aTHX_ promise, chainback);
                        }

                        xspr_promise_decref(aTHX_ promise);
                    }
                }

                if (finish_promise) {
                    xspr_result_t* final_result;
                    bool final_result_needs_decref = false;;

                    if ((callback->type == XSPR_CALLBACK_FINALLY) && RESULT_IS_RESOLVED(callback_result)) {
                        final_result = origin->finished.result;

                        if (RESULT_IS_REJECTED(final_result)) {

                            // If finally()’s callback succeeds, it takes
                            // on the resolution status of the “parent”
                            // promise. If that promise rejected, then,
                            // the finally’s promise also rejects. Notably,
                            // the finally’s promise should STILL trigger
                            // an unhandled-rejection warning, even if the
                            // parent’s rejection is eventually handled.
                            final_result = pxs_result_clone(aTHX_ final_result);
                            final_result_needs_decref = true;
                        }
                    }
                    else {
                        final_result = callback_result;
                    }

                    xspr_promise_finish(aTHX_ next_promise, final_result);

                    if (final_result_needs_decref) {
                        xspr_result_decref(aTHX_ final_result);
                    }
                }
            }

            xspr_result_decref(aTHX_ callback_result);

        } else if (next_promise) {
            /* No callback, so we're just passing the result along. */
            xspr_result_t* result = origin->finished.result;
            xspr_promise_finish(aTHX_ next_promise, result);
        }

    } else {
        assert(0);
    }
}

/* Frees the xspr_callback_t structure */
void xspr_callback_free(pTHX_ xspr_callback_t *callback)
{
    if (callback->type == XSPR_CALLBACK_CHAIN) {
        xspr_promise_decref(aTHX_ callback->chain);

    } else if (callback->type == XSPR_CALLBACK_PERL) {
        SvREFCNT_dec(callback->perl.on_resolve);
        SvREFCNT_dec(callback->perl.on_reject);
        if (callback->perl.next != NULL)
            xspr_promise_decref(aTHX_ callback->perl.next);

    } else if (callback->type == XSPR_CALLBACK_FINALLY) {
        SvREFCNT_dec(callback->finally.on_finally);
        if (callback->finally.next != NULL)
            xspr_promise_decref(aTHX_ callback->finally.next);

    } else if (callback->type == XSPR_CALLBACK_FINALLY_CHAIN) {
        xspr_promise_decref(aTHX_ callback->finally_chain.chain_promise);
        xspr_result_decref(aTHX_ callback->finally_chain.original_result);

    } else {
        assert(0);
    }

    Safefree(callback);
}

/* Process the queue until it's empty */
void xspr_queue_flush(pTHX)
{
    dMY_CXT;

    if (MY_CXT.in_flush) {
        /* XXX: is there a reasonable way to trigger this? */
        warn("Rejecting request to flush promises queue: already processing");
        return;
    }
    MY_CXT.in_flush = 1;

    while (MY_CXT.queue_head != NULL) {
        /* Save some typing... */
        xspr_callback_queue_t *cur = MY_CXT.queue_head;

        /* Process the callback. This could trigger some Perl code, meaning we
         * could end up with additional queue entries after this */
        xspr_callback_process(aTHX_ cur->callback, cur->origin);

        /* Free-ing the callback structure could theoretically trigger DESTROY subs,
         * enqueueing new callbacks, so we can't assume the loop ends here! */
        MY_CXT.queue_head = cur->next;
        if (cur->next == NULL) {
            MY_CXT.queue_tail = NULL;
        }

        /* Destroy the structure */
        xspr_callback_free(aTHX_ cur->callback);
        xspr_promise_decref(aTHX_ cur->origin);
        Safefree(cur);
    }

    MY_CXT.in_flush = 0;
    MY_CXT.backend_scheduled = 0;
}

/* Add a callback invocation into the queue for the given origin promise.
 * Takes ownership of the callback structure */
void xspr_queue_add(pTHX_ xspr_callback_t* callback, xspr_promise_t* origin)
{
    dMY_CXT;

    xspr_callback_queue_t* entry;
    Newxz(entry, 1, xspr_callback_queue_t);
    entry->origin = origin;
    xspr_promise_incref(aTHX_ entry->origin);
    entry->callback = callback;

    if (MY_CXT.queue_head == NULL) {
        assert(MY_CXT.queue_tail == NULL);
        /* Empty queue, so now it's just us */
        MY_CXT.queue_head = entry;
        MY_CXT.queue_tail = entry;

    } else {
        assert(MY_CXT.queue_tail != NULL);
        /* Existing queue, add to the tail */
        MY_CXT.queue_tail->next = entry;
        MY_CXT.queue_tail = entry;
    }
}

void _call_with_1_or_2_args( pTHX_ SV* cb, SV* maybe_arg0, SV* arg1 ) {
    // --- Almost all copy-paste from “perlcall” … blegh!
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);

    if (maybe_arg0) {
        EXTEND(SP, 2);
        PUSHs(maybe_arg0);
    }
    else {
        EXTEND(SP, 1);
    }

    PUSHs( arg1 );
    PUTBACK;

    call_sv(cb, G_VOID);

    FREETMPS;
    LEAVE;

    return;
}

void _call_pv_with_args( pTHX_ const char* subname, SV** args, unsigned argscount )
{
    // --- Almost all copy-paste from “perlcall” … blegh!
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, argscount);

    unsigned i;
    for (i=0; i<argscount; i++) {
        PUSHs(args[i]);
    }

    PUTBACK;

    call_pv(subname, G_VOID);

    FREETMPS;
    LEAVE;

    return;
}

void xspr_queue_maybe_schedule(pTHX)
{
    dMY_CXT;
    if (MY_CXT.queue_head == NULL || MY_CXT.backend_scheduled || MY_CXT.in_flush) {
        return;
    }

    MY_CXT.backend_scheduled = 1;
    /* We trust our backends to be sane, so little guarding against errors here */

    if (!MY_CXT.pxs_flush_cr) {
        HV *stash = gv_stashpv(DEFERRED_CLASS, 0);
        GV* method_gv = gv_fetchmethod_autoload(stash, "___flush", FALSE);
        if (method_gv != NULL && isGV(method_gv) && GvCV(method_gv) != NULL) {
            MY_CXT.pxs_flush_cr = newRV_inc( (SV*)GvCV(method_gv) );
        }
        else {
            assert(0);
        }
    }

    _call_with_1_or_2_args(aTHX_ MY_CXT.deferral_cr, MY_CXT.deferral_arg, MY_CXT.pxs_flush_cr);
}

/* Invoke the user's perl code. We need to be really sure this doesn't return early via croak/next/etc. */
xspr_result_t* xspr_invoke_perl(pTHX_ SV* perl_fn, SV** inputs, unsigned input_count)
{
    dSP;
    unsigned count, i;
    xspr_result_t* result;

    if (!SvROK(perl_fn)) {
        return xspr_result_from_error(aTHX_ "promise callbacks need to be a CODE reference");
    }

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, input_count);
    for (i = 0; i < input_count; i++) {
        PUSHs(inputs[i]);
    }
    PUTBACK;

    /* Clear $_ so that callbacks don't end up talking to each other by accident */
    SAVE_DEFSV;
    DEFSV_set(sv_newmortal());

    count = call_sv(perl_fn, G_EVAL | G_ARRAY);

    SPAGAIN;

    if (SvTRUE(ERRSV)) {
        result = xspr_result_new(aTHX_ XSPR_RESULT_REJECTED, 1);
        result->results[0] = newSVsv(ERRSV);
    } else {
        result = xspr_result_new(aTHX_ XSPR_RESULT_RESOLVED, count);
        for (i = 0; i < count; i++) {
            result->results[count-i-1] = SvREFCNT_inc(POPs);
        }
    }
    PUTBACK;

    FREETMPS;
    LEAVE;

    return result;
}

/* Increments the ref count for xspr_result_t */
void xspr_result_incref(pTHX_ xspr_result_t* result)
{
    result->refs++;
}

/* Decrements the ref count for the xspr_result_t, freeing the structure if needed */
void xspr_result_decref(pTHX_ xspr_result_t* result)
{
    if (--(result->refs) == 0) {
        if (RESULT_IS_REJECTED(result) && result->rejection_should_warn) {
            SV* warn_args[result->count];

            // Dupe the results to warn about:
            Copy(result->results, warn_args, result->count, SV*);

            _call_pv_with_args(aTHX_ "Promise::XS::Promise::_warn_unhandled", warn_args, result->count);
        }

        unsigned i;
        for (i = 0; i < result->count; i++) {
            SvREFCNT_dec(result->results[i]);
        }
        Safefree(result->results);
        Safefree(result);
    }
}

void xspr_immediate_process(pTHX_ xspr_callback_t* callback, xspr_promise_t* promise)
{
    xspr_callback_process(aTHX_ callback, promise);

    /* Destroy the structure */
    xspr_callback_free(aTHX_ callback);
}

/* Transitions a promise from pending to finished, using the given result */
void xspr_promise_finish(pTHX_ xspr_promise_t* promise, xspr_result_t* result)
{
    dMY_CXT;

    assert(promise->state == XSPR_STATE_PENDING);
    xspr_callback_t** pending_callbacks = promise->pending.callbacks;
    int count = promise->pending.callbacks_count;

    promise->state = XSPR_STATE_FINISHED;
    promise->finished.result = result;
    xspr_result_incref(aTHX_ promise->finished.result);

    unsigned i;
    for (i = 0; i < count; i++) {

        // If any of this promise’s callbacks has an on_reject, then
        // the promise’s result is rejection-handled.
        if (pending_callbacks[i]->type == XSPR_CALLBACK_PERL && RESULT_IS_REJECTED(result) && result->rejection_should_warn) {
            SV* on_reject = pending_callbacks[i]->perl.on_reject;
            if (on_reject && SvOK(on_reject)) {
                result->rejection_should_warn = false;
            }
        }

        if (MY_CXT.deferral_cr) {
            xspr_queue_add(aTHX_ pending_callbacks[i], promise);
        }
        else {
            xspr_immediate_process(aTHX_ pending_callbacks[i], promise);
        }
    }

    if (MY_CXT.deferral_cr) {
        xspr_queue_maybe_schedule(aTHX);
    }

    Safefree(pending_callbacks);
}

/* Create a new xspr_result_t object with the given number of item slots */
xspr_result_t* xspr_result_new(pTHX_ xspr_result_state_t state, unsigned count)
{
    xspr_result_t* result;
    Newxz(result, 1, xspr_result_t);
    Newxz(result->results, count, SV*);
    result->rejection_should_warn = true;
    result->state = state;
    result->refs = 1;
    result->count = count;
    return result;
}

xspr_result_t* pxs_result_clone(pTHX_ xspr_result_t* old)
{
    xspr_result_t* new = xspr_result_new(aTHX_ old->state, old->count);

    unsigned i;
    for (i=0; i<old->count; i++) {
        new->results[i] = SvREFCNT_inc( old->results[i] );
    }

    return new;
}

xspr_result_t* xspr_result_from_error(pTHX_ const char *error)
{
    xspr_result_t* result = xspr_result_new(aTHX_ XSPR_RESULT_REJECTED, 1);
    result->results[0] = newSVpv(error, 0);
    return result;
}

/* Increments the ref count for xspr_promise_t */
void xspr_promise_incref(pTHX_ xspr_promise_t* promise)
{
    (promise->refs)++;
}

/* Decrements the ref count for the xspr_promise_t, freeing the structure if needed */
void xspr_promise_decref(pTHX_ xspr_promise_t *promise)
{
    if (--(promise->refs) == 0) {
        if (promise->state == XSPR_STATE_PENDING) {
            /* XXX: is this a bad thing we should warn for? */
            int count = promise->pending.callbacks_count;
            xspr_callback_t **callbacks = promise->pending.callbacks;
            int i;
            for (i = 0; i < count; i++) {
                xspr_callback_free(aTHX_ callbacks[i]);
            }
            Safefree(callbacks);

        } else if (promise->state == XSPR_STATE_FINISHED) {
            xspr_result_decref(aTHX_ promise->finished.result);

        } else {
            assert(0);
        }

        Safefree(promise);
    }
}

/* Creates a new promise. It's that simple. */
xspr_promise_t* xspr_promise_new(pTHX)
{
    xspr_promise_t* promise;
    Newxz(promise, 1, xspr_promise_t);
    promise->refs = 1;
    promise->state = XSPR_STATE_PENDING;
    return promise;
}

xspr_callback_t* xspr_callback_new_perl(pTHX_ SV* on_resolve, SV* on_reject, xspr_promise_t* next)
{
    xspr_callback_t* callback;
    Newxz(callback, 1, xspr_callback_t);
    callback->type = XSPR_CALLBACK_PERL;
    if (SvOK(on_resolve))
        callback->perl.on_resolve = newSVsv(on_resolve);
    if (SvOK(on_reject))
        callback->perl.on_reject = newSVsv(on_reject);
    callback->perl.next = next;
    if (next)
        xspr_promise_incref(aTHX_ callback->perl.next);
    return callback;
}

xspr_callback_t* xspr_callback_new_finally(pTHX_ SV* on_finally, xspr_promise_t* next)
{
    xspr_callback_t* callback;
    Newxz(callback, 1, xspr_callback_t);
    callback->type = XSPR_CALLBACK_FINALLY;
    if (SvOK(on_finally))
        callback->finally.on_finally = newSVsv(on_finally);
    callback->finally.next = next;
    if (next)
        xspr_promise_incref(aTHX_ callback->finally.next);
    return callback;
}

xspr_callback_t* xspr_callback_new_chain(pTHX_ xspr_promise_t* chain)
{
    xspr_callback_t* callback;
    Newxz(callback, 1, xspr_callback_t);
    callback->type = XSPR_CALLBACK_CHAIN;
    callback->chain = chain;
    xspr_promise_incref(aTHX_ chain);
    return callback;
}

xspr_callback_t* xspr_callback_new_finally_chain(pTHX_ xspr_result_t* original_result, xspr_promise_t* next_promise)
{
    xspr_callback_t* callback;
    Newxz(callback, 1, xspr_callback_t);
    callback->type = XSPR_CALLBACK_FINALLY_CHAIN;

    /*
    callback->finally_chain.original_result = original_result;
    xspr_result_incref(aTHX_ original_result);
    */
    callback->finally_chain.original_result = pxs_result_clone(aTHX_ original_result);

    callback->finally_chain.chain_promise = next_promise;
    xspr_promise_incref(aTHX_ next_promise);

    return callback;
}

/* Adds a then to the promise. Takes ownership of the callback */
void xspr_promise_then(pTHX_ xspr_promise_t* promise, xspr_callback_t* callback)
{
    dMY_CXT;

    if (promise->state == XSPR_STATE_PENDING) {
        promise->pending.callbacks_count++;
        Renew(promise->pending.callbacks, promise->pending.callbacks_count, xspr_callback_t*);
        promise->pending.callbacks[promise->pending.callbacks_count-1] = callback;

    } else if (promise->state == XSPR_STATE_FINISHED) {

        if (MY_CXT.deferral_cr) {
            xspr_queue_add(aTHX_ callback, promise);
            xspr_queue_maybe_schedule(aTHX);
        }
        else {
            xspr_immediate_process(aTHX_ callback, promise);
        }
    } else {
        assert(0);
    }
}

/* Returns a promise if the given SV is a thenable. Ownership handed to the caller! */
xspr_promise_t* xspr_promise_from_sv(pTHX_ SV* input)
{
    if (input == NULL || !sv_isobject(input)) {
        return NULL;
    }

    /* If we got one of our own promises: great, not much to do here! */
    if (sv_derived_from(input, PROMISE_CLASS)) {
        IV tmp = SvIV((SV*)SvRV(input));
        PROMISE_CLASS_TYPE* promise = INT2PTR(PROMISE_CLASS_TYPE*, tmp);
        xspr_promise_incref(aTHX_ promise->promise);
        return promise->promise;
    }

    /* Maybe we got another type of promise. Let's convert it */
    GV* method_gv = gv_fetchmethod_autoload(SvSTASH(SvRV(input)), "then", FALSE);
    if (method_gv != NULL && isGV(method_gv) && GvCV(method_gv) != NULL) {
        dMY_CXT;

        xspr_result_t* new_result = xspr_invoke_perl(aTHX_ MY_CXT.conversion_helper, &input, 1);
        if (new_result->state == XSPR_RESULT_RESOLVED &&
            new_result->results != NULL &&
            new_result->count == 1 &&
            SvROK(new_result->results[0]) &&
            sv_derived_from(new_result->results[0], PROMISE_CLASS)) {
            /* This is expected: our conversion function returned us one of our own promises */
            IV tmp = SvIV((SV*)SvRV(new_result->results[0]));
            PROMISE_CLASS_TYPE* new_promise = INT2PTR(PROMISE_CLASS_TYPE*, tmp);

            xspr_promise_t* promise = new_promise->promise;
            xspr_promise_incref(aTHX_ promise);

            xspr_result_decref(aTHX_ new_result);
            return promise;

        } else {
            xspr_promise_t* promise = xspr_promise_new(aTHX);
            xspr_promise_finish(aTHX_ promise, new_result);
            xspr_result_decref(aTHX_ new_result);
            return promise;
        }
    }

    /* We didn't get a promise. */
    return NULL;
}

DEFERRED_CLASS_TYPE* _get_deferred_from_sv(pTHX_ SV *self_sv) {
    SV *referent = SvRV(self_sv);
    return INT2PTR(DEFERRED_CLASS_TYPE*, SvUV(referent));
}

PROMISE_CLASS_TYPE* _get_promise_from_sv(pTHX_ SV *self_sv) {
    SV *referent = SvRV(self_sv);
    return INT2PTR(PROMISE_CLASS_TYPE*, SvUV(referent));
}

SV* _ptr_to_svrv(pTHX_ void* ptr, HV* stash) {
    SV* referent = newSVuv( PTR2UV(ptr) );
    SV* retval = newRV_noinc(referent);
    sv_bless(retval, stash);

    return retval;
}

static inline xspr_promise_t* create_promise(pTHX) {
    dMY_CXT;

    xspr_promise_t* promise = xspr_promise_new(aTHX);

    SV *detect_leak_perl = NULL;

    SV** dml_svgv = hv_fetchs( MY_CXT.pxs_base_stash, "DETECT_MEMORY_LEAKS", 0 );

    if (dml_svgv) {
        detect_leak_perl = GvSV(*dml_svgv);
    }

    promise->detect_leak_pid = detect_leak_perl && SvTRUE(detect_leak_perl) ? getpid() : 0;

    return promise;
}

/* Many promises are just thrown away after the final callback, no need to allocate a next promise for those */
static inline xspr_promise_t* create_next_promise_if_needed(pTHX_ SV* original, SV** stack_ptr) {
    if (GIMME_V != G_VOID) {
        PROMISE_CLASS_TYPE* next_promise;
        Newxz(next_promise, 1, PROMISE_CLASS_TYPE);

        xspr_promise_t* next = create_promise(aTHX);
        next_promise->promise = next;

        *stack_ptr = sv_newmortal();

        // This would be simpler, but let’s facilitate subclassing.
        // sv_setref_pv(*stack_ptr, PROMISE_CLASS, (void*)next_promise);

        sv_setref_pv(*stack_ptr, NULL, (void*)next_promise);
        sv_bless(*stack_ptr, SvSTASH(SvRV(original)));

        return next;
    }

    return NULL;
}

static inline void _warn_on_destroy_if_needed(pTHX_ xspr_promise_t* promise, SV* self_sv) {
    if (promise->detect_leak_pid && PXS_IS_GLOBAL_DESTRUCTION && promise->detect_leak_pid == getpid()) {
        warn( "======================================================================\nXXXXXX - %s survived until global destruction; memory leak likely!\n======================================================================\n", SvPV_nolen(self_sv) );
    }
}

static inline void _warn_weird_reject_if_needed( pTHX_ SV* self_sv, const char* funcname, I32 my_items ) {

    char *pkgname = NULL;

    HV *stash = (self_sv == NULL) ? NULL : SvSTASH( SvRV(self_sv) );

    if (stash != NULL) {
        pkgname = HvNAME(stash);
    }

    if (pkgname == NULL) pkgname = DEFERRED_CLASS;

    if (my_items == 0) {
        warn( "%s: Empty call to %s()", pkgname, funcname );
    }
    else {
        warn( "%s: %s() called with only uninitialized values (%d)", pkgname, funcname, my_items);
    }
}

static inline void _resolve_promise(pTHX_ xspr_promise_t* promise_p, SV** args, I32 argslen) {
    xspr_result_t* result = xspr_result_new(aTHX_ XSPR_RESULT_RESOLVED, argslen);

    unsigned i;
    for (i = 0; i < argslen; i++) {
        result->results[i] = newSVsv(args[i]);
    }

    xspr_promise_finish(aTHX_ promise_p, result);
    xspr_result_decref(aTHX_ result);
}

static inline void _reject_promise(pTHX_ SV* self_sv, xspr_promise_t* promise_p, SV** args, I32 argslen) {
    xspr_result_t* result = xspr_result_new(aTHX_ XSPR_RESULT_REJECTED, argslen);

    bool has_defined = false;

    unsigned i;
    for (i = 0; i < argslen; i++) {
        result->results[i] = newSVsv(args[i]);

        if (!has_defined && SvOK(result->results[i])) {
            has_defined = true;
        }
    }

    if (!has_defined) {
        const char* funcname = (self_sv == NULL) ? "rejected" : "reject";

        _warn_weird_reject_if_needed( aTHX_ self_sv, funcname, argslen );
    }

    xspr_promise_finish(aTHX_ promise_p, result);
    xspr_result_decref(aTHX_ result);
}

SV* _promise_to_sv(pTHX_ xspr_promise_t* promise_p) {
    dMY_CXT;

    PROMISE_CLASS_TYPE* promise_ptr;
    Newxz(promise_ptr, 1, PROMISE_CLASS_TYPE);
    promise_ptr->promise = promise_p;

    return _ptr_to_svrv(aTHX_ promise_ptr, MY_CXT.pxs_promise_stash);
}

//----------------------------------------------------------------------

MODULE = Promise::XS     PACKAGE = Promise::XS

BOOT:
{
    MY_CXT_INIT;
#ifdef USE_ITHREADS
    MY_CXT.owner = aTHX;
#endif
    MY_CXT.queue_head = NULL;
    MY_CXT.queue_tail = NULL;
    MY_CXT.in_flush = 0;
    MY_CXT.backend_scheduled = 0;
    MY_CXT.conversion_helper = NULL;

    MY_CXT.pxs_base_stash = gv_stashpv(BASE_CLASS, FALSE);
    MY_CXT.pxs_promise_stash = gv_stashpv(PROMISE_CLASS, FALSE);
    MY_CXT.pxs_deferred_stash = gv_stashpv(DEFERRED_CLASS, FALSE);

    MY_CXT.deferral_cr = NULL;
    MY_CXT.deferral_arg = NULL;
    MY_CXT.pxs_flush_cr = NULL;
}

# In some old thread-multi perls sv_dup_inc() wasn’t defined.

#if defined(USE_ITHREADS) && defined(sv_dup_inc)

# ithreads would seem to be a very bad idea in Promise-based code,
# but anyway ..

void
CLONE(...)
    PPCODE:

        SV* conversion_helper = NULL;
        SV* pxs_flush_cr = NULL;
        SV* deferral_cr = NULL;
        SV* deferral_arg = NULL;

        {
            dMY_CXT;

            CLONE_PARAMS params = {NULL, 0, MY_CXT.owner};

            if ( MY_CXT.conversion_helper ) {
                conversion_helper = sv_dup_inc( MY_CXT.conversion_helper, &params );
            }

            if ( MY_CXT.pxs_flush_cr ) {
                pxs_flush_cr = sv_dup_inc( MY_CXT.pxs_flush_cr, &params );
            }

            if ( MY_CXT.deferral_cr ) {
                deferral_cr = sv_dup_inc( MY_CXT.deferral_cr, &params );
            }

            if ( MY_CXT.deferral_arg ) {
                deferral_arg = sv_dup_inc( MY_CXT.deferral_arg, &params );
            }
        }

        {
            MY_CXT_CLONE;
            MY_CXT.owner = aTHX;

            // Clone SVs
            MY_CXT.conversion_helper = conversion_helper;
            MY_CXT.pxs_flush_cr = pxs_flush_cr;
            MY_CXT.deferral_cr = deferral_cr;
            MY_CXT.deferral_arg = deferral_arg;

            // Clone HVs
            MY_CXT.pxs_base_stash = gv_stashpv(BASE_CLASS, FALSE);
            MY_CXT.pxs_promise_stash = gv_stashpv(PROMISE_CLASS, FALSE);
            MY_CXT.pxs_deferred_stash = gv_stashpv(DEFERRED_CLASS, FALSE);
        }

        XSRETURN_UNDEF;

#endif /* USE_ITHREADS && defined(sv_dup_inc) */

SV *
resolved(...)
    CODE:
        xspr_promise_t* promise_p = create_promise(aTHX);

        _resolve_promise(aTHX_ promise_p, &(ST(0)), items);

        RETVAL = _promise_to_sv(aTHX_ promise_p);
    OUTPUT:
        RETVAL

SV *
rejected(...)
    CODE:
        xspr_promise_t* promise_p = create_promise(aTHX);

        _reject_promise(aTHX_ NULL, promise_p, &(ST(0)), items);

        RETVAL = _promise_to_sv(aTHX_ promise_p);
    OUTPUT:
        RETVAL

#----------------------------------------------------------------------

MODULE = Promise::XS     PACKAGE = Promise::XS::Deferred

PROTOTYPES: DISABLE

SV *
create()
    CODE:
        dMY_CXT;

        DEFERRED_CLASS_TYPE* deferred_ptr;
        Newxz(deferred_ptr, 1, DEFERRED_CLASS_TYPE);

        xspr_promise_t* promise = create_promise(aTHX);

        deferred_ptr->promise = promise;

        RETVAL = _ptr_to_svrv(aTHX_ deferred_ptr, MY_CXT.pxs_deferred_stash);
    OUTPUT:
        RETVAL

void
___set_deferral_generic(SV* cr, ...)
    CODE:
        dMY_CXT;

        cr = SvRV(cr);

        if (MY_CXT.deferral_cr) {
            SvREFCNT_dec(MY_CXT.deferral_cr);
        }

        MY_CXT.deferral_cr = cr;
        SvREFCNT_inc(MY_CXT.deferral_cr);

        if (items > 1) {
            if (MY_CXT.deferral_arg) {
                SvREFCNT_dec(MY_CXT.deferral_arg);
            }

            MY_CXT.deferral_arg = ST(1);
            SvREFCNT_inc(MY_CXT.deferral_arg);
        }

# We don’t care if there are args or not.
void
___flush(...)
    CODE:
        UNUSED(items);
        xspr_queue_flush(aTHX);

void
___set_conversion_helper(helper)
        SV* helper
    CODE:
        dMY_CXT;
        if (MY_CXT.conversion_helper != NULL)
            croak("Refusing to set a conversion helper twice");
        MY_CXT.conversion_helper = newSVsv(helper);

SV*
promise(SV* self_sv)
    CODE:
        DEFERRED_CLASS_TYPE* self = _get_deferred_from_sv(aTHX_ self_sv);

        xspr_promise_incref(aTHX_ self->promise);

        RETVAL = _promise_to_sv(aTHX_ self->promise);
    OUTPUT:
        RETVAL

SV*
resolve(SV *self_sv, ...)
    CODE:
        DEFERRED_CLASS_TYPE* self = _get_deferred_from_sv(aTHX_ self_sv);

        if (self->promise->state != XSPR_STATE_PENDING) {
            croak("Cannot resolve deferred: not pending");
        }

        _resolve_promise(aTHX_ self->promise, &(ST(1)), items - 1);

        if (GIMME_V == G_VOID) {
            RETVAL = NULL;
        }
        else {
            SvREFCNT_inc(self_sv);
            RETVAL = self_sv;
        }
    OUTPUT:
        RETVAL

SV*
reject(SV *self_sv, ...)
    CODE:
        DEFERRED_CLASS_TYPE* self = _get_deferred_from_sv(aTHX_ self_sv);

        if (self->promise->state != XSPR_STATE_PENDING) {
            croak("Cannot reject deferred: not pending");
        }

        _reject_promise(aTHX_ self_sv, self->promise, &(ST(1)), items - 1);

        if (GIMME_V == G_VOID) {
            RETVAL = NULL;
        }
        else {
            SvREFCNT_inc(self_sv);
            RETVAL = self_sv;
        }
    OUTPUT:
        RETVAL

bool
is_pending(SV *self_sv)
    CODE:
        DEFERRED_CLASS_TYPE* self = _get_deferred_from_sv(aTHX_ self_sv);

        RETVAL = (self->promise->state == XSPR_STATE_PENDING);
    OUTPUT:
        RETVAL

SV*
clear_unhandled_rejection(SV *self_sv)
    CODE:
        DEFERRED_CLASS_TYPE* self = _get_deferred_from_sv(aTHX_ self_sv);

        if (self->promise->state == XSPR_STATE_FINISHED) {
            self->promise->finished.result->rejection_should_warn = false;
        }

        if (GIMME_V == G_VOID) {
            RETVAL = NULL;
        }
        else {
            SvREFCNT_inc(self_sv);
            RETVAL = self_sv;
        }
    OUTPUT:
        RETVAL

void
DESTROY(SV *self_sv)
    CODE:
        DEFERRED_CLASS_TYPE* self = _get_deferred_from_sv(aTHX_ self_sv);

        _warn_on_destroy_if_needed(aTHX_ self->promise, self_sv);

        xspr_promise_decref(aTHX_ self->promise);
        Safefree(self);

# ----------------------------------------------------------------------

MODULE = Promise::XS     PACKAGE = Promise::XS::Promise

PROTOTYPES: DISABLE

void
then(SV* self_sv, SV* on_resolve = NULL, SV* on_reject = NULL)
    PPCODE:
        PROMISE_CLASS_TYPE* self = _get_promise_from_sv(aTHX_ self_sv);

        xspr_promise_t* next;

        if (on_resolve == NULL) on_resolve = &PL_sv_undef;
        if (on_reject == NULL) on_reject = &PL_sv_undef;

        next = create_next_promise_if_needed(aTHX_ self_sv, &ST(0));

        xspr_callback_t* callback = xspr_callback_new_perl(aTHX_ on_resolve, on_reject, next);
        xspr_promise_then(aTHX_ self->promise, callback);

        XSRETURN(next ? 1 : 0);

void
catch(SV* self_sv, SV* on_reject)
    PPCODE:
        PROMISE_CLASS_TYPE* self = _get_promise_from_sv(aTHX_ self_sv);

        xspr_promise_t* next = create_next_promise_if_needed(aTHX_ self_sv, &ST(0));

        xspr_callback_t* callback = xspr_callback_new_perl(aTHX_ &PL_sv_undef, on_reject, next);
        xspr_promise_then(aTHX_ self->promise, callback);

        XSRETURN(next ? 1 : 0);

void
finally(SV* self_sv, SV* on_finally)
    PPCODE:
        PROMISE_CLASS_TYPE* self = _get_promise_from_sv(aTHX_ self_sv);

        xspr_promise_t* next = create_next_promise_if_needed(aTHX_ self_sv, &ST(0));

        xspr_callback_t* callback = xspr_callback_new_finally(aTHX_ on_finally, next);
        xspr_promise_then(aTHX_ self->promise, callback);

        XSRETURN(next ? 1 : 0);

void
DESTROY(SV* self_sv)
    CODE:
        PROMISE_CLASS_TYPE* self = _get_promise_from_sv(aTHX_ self_sv);

        _warn_on_destroy_if_needed(aTHX_ self->promise, self_sv);

        xspr_promise_decref(aTHX_ self->promise);
        Safefree(self);
