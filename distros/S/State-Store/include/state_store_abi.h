#ifndef STATE_STORE_ABI_H
#define STATE_STORE_ABI_H

/* Public C ABI for State::Store: everything a store does from Perl, callable
 * from another extension's C.
 *
 * It is resolved at RUNTIME through State::Store::_abi_ptr - a versioned
 * table of function pointers - so there is no link-time coupling: each dist
 * builds and upgrades by itself. A consumer reaches this header through
 * ExtUtils::Depends, or vendors a copy pinned at STATE_STORE_ABI_VERSION,
 * and checks abi_version once when it loads.
 *
 * The table only ever grows at the end. STATE_STORE_ABI_VERSION bumps on
 * any append, and a consumer requires abi_version >= the version it was
 * written against, treating a later table as a superset it uses a prefix
 * of. NOT ==: an equality check turns every release of this dist into a
 * breaking change for every consumer.
 *
 * ---- THIS HEADER NEEDS PERL -------------------------------------------
 *
 * Every entry takes pTHX_, and a store is a Perl object. Include perl's
 * headers first.
 *
 * ---- resolving the table ----------------------------------------------
 *
 * At BOOT, once, never per call:
 *
 *     static const state_store_abi *STORE = NULL;
 *
 *     BOOT:
 *     {
 *         SV *err;
 *         SV *sv = eval_pv("require State::Store; State::Store::_abi_ptr()", 0);
 *         err = get_sv("@", 0);
 *         if (sv && SvOK(sv) && (!err || !SvTRUE(err))) {
 *             const state_store_abi *t = INT2PTR(const state_store_abi *, SvUV(sv));
 *             if (t && t->abi_version >= STATE_STORE_ABI_VERSION) STORE = t;
 *         }
 *     }
 *
 * The VALUE eval_pv returns, not the top of the stack. A NULL table means
 * State::Store is absent or too old.
 *
 * Calls are written (STORE->set)(aTHX_ st, value). The parentheses keep a
 * member's name from ever being read as a function-like macro, which is how
 * XSUB.h redefines a number of ordinary names on a perl built with
 * PERL_IMPLICIT_SYS.
 *
 * ---- WHAT A STORE IS HERE ---------------------------------------------
 *
 * A store is the same object Perl sees: a reference to a State::Store, or to
 * an object of a subclass. Every entry takes it as `SV *st`. `store_new`
 * makes one with a reference count of one, which the caller owns; one that
 * came from Perl is borrowed for as long as Perl holds it. A store made here
 * can be handed to Perl, and one from Perl can be used here, freely.
 *
 * ---- values -----------------------------------------------------------
 *
 * A value is COPIED when it is stored, and the copy is read-only. A value
 * that comes back - from `current`, or handed to a callback - is the stored
 * scalar itself, BORROWED: valid until the store lets go of it, which may
 * be the next change. To keep it, SvREFCNT_inc it; to change it, copy it.
 *
 * Two values are the same value as HAMT's value_equal has it: the same
 * scalar, two references to one thing, two non-references that are the same
 * string, or two undefs. Storing the value already held is no change.
 *
 * ---- results and failure ----------------------------------------------
 *
 * An entry that returns int returns STATE_STORE_OK, a positive answer its
 * comment describes, or one of the negative codes below.
 *
 * An entry that changes the value - set, swap, undo, redo, restore,
 * txn_commit - tells the watchers once the change is complete, as the Perl
 * methods do. A Perl watcher, or a Perl validator, that dies makes the entry
 * die, exactly as the Perl method would: after the change for a watcher,
 * with nothing changed for a validator. C watchers and validators given to
 * this table MUST NOT croak.
 *
 * Running out of memory croaks, as perl's own allocator does; the store is
 * left as it was. */

#define STATE_STORE_ABI_VERSION 1

#define STATE_STORE_OK          0
#define STATE_STORE_NOMEM     (-1)  /* reserved; this version croaks instead */
#define STATE_STORE_NOTSTORE  (-2)  /* `st` is not a store */
#define STATE_STORE_BUSY      (-3)  /* not allowed now: inside the validator,
                                       or, for undo, redo, restore,
                                       clear_history and set_history_limit,
                                       inside a transaction */
#define STATE_STORE_REFUSED   (-4)  /* the validator said no */
#define STATE_STORE_NOTFOUND  (-5)  /* no checkpoint by that name */
#define STATE_STORE_ORDER     (-6)  /* not the innermost open transaction */
#define STATE_STORE_STOPPED   (-7)  /* a callback asked for nothing to change */

#ifndef STATE_STORE_TXN_FWD
#define STATE_STORE_TXN_FWD
typedef struct state_store_txn state_store_txn;     /* an open transaction */
#endif

/* ---- callbacks ---------------------------------------------------------- */

/* A swap: the value to store in place of `current`, which is copied; or
 * NULL to change nothing. May return `current` itself. MUST NOT croak. */
typedef SV *(*state_store_swap_fn)(pTHX_ void *ud, SV *current);

/* A watcher: called after every change, with the value before, the value
 * after, and the store. MUST NOT croak. */
typedef void (*state_store_watch_fn)(pTHX_ void *ud, SV *was, SV *now, SV *st);

/* A validator: 1 to let `proposed` replace `held`, 0 to refuse. MUST NOT
 * croak, and must not change the store. */
typedef int (*state_store_validate_fn)(pTHX_ void *ud, SV *proposed, SV *held, SV *st);

/* One checkpoint. Return 0 to carry on, anything else to stop. */
typedef int (*state_store_name_fn)(pTHX_ void *ud, const char *name, STRLEN len,
                                   int utf8, SV *value);

typedef struct state_store_abi {
    int abi_version;

    /* ================================================================ *
     *  the store
     * ================================================================ */

    /* A new State::Store holding a copy of `initial` (NULL is undef), with
     * every step kept, no watcher and no validator: a reference with a
     * count of one, which the caller owns. */
    SV  *(*store_new)(pTHX_ SV *initial);
    /* 1 when `sv` is a store this interpreter can use, 0 when not. */
    int  (*is_store)(pTHX_ SV *sv);

    /* ================================================================ *
     *  the value
     * ================================================================ */

    /* The current value, borrowed; NULL when `st` is not a store. */
    SV  *(*current)(pTHX_ SV *st);
    /* Replaces the value. 1 when it changed, 0 when `value` was the value
     * held, or a negative code. Asks the validator. */
    int  (*set)(pTHX_ SV *st, SV *value);
    /* Replaces the value with what `fn` makes of it. As `set`, and
     * STATE_STORE_STOPPED when `fn` returned NULL. */
    int  (*swap)(pTHX_ SV *st, state_store_swap_fn fn, void *ud);

    /* ================================================================ *
     *  history
     * ================================================================ */

    /* Up to `n` steps back, or forward; `*taken`, when not NULL, gets how
     * many were taken. */
    int    (*undo)(pTHX_ SV *st, size_t n, size_t *taken);
    int    (*redo)(pTHX_ SV *st, size_t n, size_t *taken);
    /* How many steps can be undone, or redone. 0 for something not a store. */
    size_t (*undo_count)(pTHX_ SV *st);
    size_t (*redo_count)(pTHX_ SV *st);
    /* Forgets every step both ways; the value stays. */
    int    (*clear_history)(pTHX_ SV *st);
    /* 1 with the limit in `*limit` when there is one, 0 when every step is
     * kept, or a negative code. */
    int    (*history_limit)(pTHX_ SV *st, size_t *limit);
    /* A limit of `limit` steps when `limited`, none when not. Cuts the past
     * to it at once. */
    int    (*set_history_limit)(pTHX_ SV *st, int limited, size_t limit);

    /* ================================================================ *
     *  watchers and the validator
     * ================================================================ */

    /* Adds a watcher, after every one already there. Its id for unwatch,
     * which is never 0; 0 when `st` is not a store. */
    UV     (*watch)(pTHX_ SV *st, state_store_watch_fn fn, void *ud);
    /* Removes a watcher added here or from Perl. 1 if there was one. */
    int    (*unwatch)(pTHX_ SV *st, UV id);
    /* How many watchers, from Perl and from here. */
    size_t (*watchers)(pTHX_ SV *st);
    /* Makes `fn` the store's validator, in place of any, from Perl or from
     * here; NULL removes it. Does not check the value held. */
    int    (*set_validator)(pTHX_ SV *st, state_store_validate_fn fn, void *ud);

    /* ================================================================ *
     *  transactions
     * ================================================================ */

    /* Opens a transaction: NULL, with *status set when it is not NULL, if
     * one cannot be opened now. Every transaction opened must be committed
     * or aborted, innermost first; until it is, it holds the store. */
    state_store_txn *(*txn_begin)(pTHX_ SV *st, int *status);
    /* Closes one, keeping what was done in it: for the outermost, one step
     * and one change told to the watchers. The handle is dead afterwards,
     * whatever the result, except for STATE_STORE_ORDER, when nothing was
     * done and it is still open. */
    int  (*txn_commit)(pTHX_ state_store_txn *t);
    /* Closes one, putting the store back as it was when it was opened.
     * The handle is dead afterwards, except for STATE_STORE_ORDER. */
    int  (*txn_abort)(pTHX_ state_store_txn *t);
    /* 1 while a transaction is open on the store, 0 when not. */
    int  (*in_txn)(pTHX_ SV *st);

    /* ================================================================ *
     *  checkpoints
     * ================================================================ */

    /* Names the current value. A name is bytes and a flag saying they are
     * UTF-8; two names are one exactly when a Perl hash would say so. */
    int    (*checkpoint)(pTHX_ SV *st, const char *name, STRLEN len, int utf8);
    /* Makes the value named current, as a change: 1 when it changed, 0
     * when it was the value held, or a negative code. Does not ask the
     * validator. */
    int    (*restore)(pTHX_ SV *st, const char *name, STRLEN len, int utf8);
    /* 1 when there is a checkpoint by that name, 0 when not. */
    int    (*has_checkpoint)(pTHX_ SV *st, const char *name, STRLEN len, int utf8);
    /* The value a checkpoint names, borrowed, or NULL. */
    SV    *(*checkpoint_value)(pTHX_ SV *st, const char *name, STRLEN len, int utf8);
    int    (*drop_checkpoint)(pTHX_ SV *st, const char *name, STRLEN len, int utf8);
    size_t (*checkpoint_count)(pTHX_ SV *st);
    /* Calls `fn` for every checkpoint, in no particular order.
     * STATE_STORE_OK, or STATE_STORE_STOPPED when `fn` stopped it. */
    int    (*checkpoint_walk)(pTHX_ SV *st, state_store_name_fn fn, void *ud);
} state_store_abi;

#endif
