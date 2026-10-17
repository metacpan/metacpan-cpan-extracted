MODULE = Punk        PACKAGE = Punk::Future

PROTOTYPES: DISABLE

# Punk::Future, in C (punk_future.h). A Future.pm-compatible async result that
# runs on the Hyperman loop when live and blocks otherwise. lib/Punk/Future.pm
# is documentation. (Core stage: create / settle / state / callbacks / get.)

SV *
new(class)
        SV *class
    CODE:
        RETVAL = pf_bless(aTHX_ pf_new(aTHX), pf_class_of(aTHX_ class));
    OUTPUT:
        RETVAL

# done(@values) / fail(@failure): settle a pending future. Chains.
SV *
done(self, ...)
        SV *self
    ALIAS:
        fail       = 1
        AWAIT_DONE = 2
        AWAIT_FAIL = 3
    CODE:
    {
        punk_future *pf = pf_of(aTHX_ self);
        AV *vals = newAV();
        int i;
        for (i = 1; i < items; i++) av_push(vals, newSVsv(ST(i)));
        /* the low bit of ix is the outcome, so the AWAIT_ spellings pair off
         * with the ones they alias */
        pf_settle(aTHX_ pf, self, (ix & 1) ? PF_FAILED : PF_DONE, vals);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

IV
is_ready(self)
        SV *self
    ALIAS:
        is_done            = 1
        is_failed          = 2
        is_cancelled       = 3
        AWAIT_IS_READY     = 4
        AWAIT_IS_CANCELLED = 5
    CODE:
    {
        int st = pf_of(aTHX_ self)->state;
        /* a switch, not a ternary chain: the chain's last arm was a
         * fallthrough that would quietly answer for any ix added later */
        switch (ix) {
            case 1:          RETVAL = (st == PF_DONE);      break;
            case 2:          RETVAL = (st == PF_FAILED);    break;
            case 3: case 5:  RETVAL = (st == PF_CANCELLED); break;
            default:         RETVAL = (st != PF_PENDING);   break;  /* 0, 4 */
        }
    }
    OUTPUT:
        RETVAL

IV
state(self)
        SV *self
    CODE:
        RETVAL = pf_of(aTHX_ self)->state;
    OUTPUT:
        RETVAL

# on_ready($cb) fires $cb->($future) on settle; on_done/on_fail fire
# $cb->(@values) for the matching outcome. Fire at once if already settled.
SV *
on_ready(self, thing)
        SV *self
        SV *thing
    ALIAS:
        on_done        = 1
        on_fail        = 2
        on_cancel      = 3
        AWAIT_ON_READY = 4
    CODE:
    {
        /* ix stops being the reaction kind here. It was PFR_* by coincidence
         * of declaration order, which is not something an alias list should
         * have to know: an alias landing on the wrong number would register a
         * reaction that never fires, and a never-fired reaction is a hang with
         * nothing to report. */
        static const int kind[] = {
            PFR_ON_READY,   /* 0 on_ready       */
            PFR_ON_DONE,    /* 1 on_done        */
            PFR_ON_FAIL,    /* 2 on_fail        */
            PFR_ON_CANCEL,  /* 3 on_cancel      */
            PFR_ON_READY    /* 4 AWAIT_ON_READY */
        };
        pf_react(aTHX_ pf_of(aTHX_ self), self, kind[ix], thing);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# The protocol's two cancel registrations. They are a separate body from
# on_cancel rather than two more aliases because they must return NOTHING:
# these are called by Future::AsyncAwait on the future it is about to hand
# back, and replacing the invocant on the argument stack with a fresh copy of
# it - which is what returning `$self` does here - corrupts that future.
# The protocol defines no return value for either, so there is none.
void
AWAIT_ON_CANCEL(self, thing)
        SV *self
        SV *thing
    ALIAS:
        AWAIT_CHAIN_CANCEL = 1
    CODE:
        PERL_UNUSED_VAR(ix);
        pf_react(aTHX_ pf_of(aTHX_ self), self, PFR_ON_CANCEL, thing);

# get / result: block until ready, then return the values (or die the failure).
# AWAIT_WAIT is the same thing - it is what a toplevel await resolves to.
# AWAIT_GET is defined only on a future that is already ready, so it reads
# where the others wait; the two croaks stay distinguishable on purpose.
void
get(self)
        SV *self
    ALIAS:
        result     = 1
        AWAIT_WAIT = 2
        AWAIT_GET  = 3
    PPCODE:
    {
        punk_future *pf = pf_of(aTHX_ self);
        SSize_t i, n;
        if (ix == 3) {
            if (pf->state == PF_PENDING)
                croak("Punk::Future: AWAIT_GET on a future that is not ready");
        }
        else if (pf->state == PF_PENDING) pf_await(aTHX_ self);  /* pump/sleep */
        /* pf_await ran the loop, and anything on it may have grown the value
         * stack; a grown stack is reallocated, so the SP captured on entry
         * points into freed memory. Re-derive it before pushing. */
        SP = PL_stack_base + ax - 1;
        if (pf->state == PF_CANCELLED)
            croak("Punk::Future: get on a cancelled future");
        if (pf->state == PF_FAILED) {
            SV **f = pf->vals ? av_fetch(pf->vals, 0, 0) : NULL;
            croak_sv(f && *f ? *f : sv_2mortal(newSVpvs("Punk::Future failed")));
        }
        n = pf->vals ? av_len(pf->vals) + 1 : 0;
        /* Scalar context hands back the FIRST value, as Future.pm does. An
         * XSUB otherwise returns whatever was pushed last, which made a
         * multi-value future yield its tail - and punk_coerce and
         * _finish_future both call this in scalar context. */
        if (GIMME_V != G_ARRAY) {
            SV **f = n ? av_fetch(pf->vals, 0, 0) : NULL;
            XPUSHs(f && *f ? sv_2mortal(newSVsv(*f)) : &PL_sv_undef);
        }
        else {
            EXTEND(SP, n);
            for (i = 0; i < n; i++)
                PUSHs(sv_2mortal(newSVsv(*av_fetch(pf->vals, i, 0))));
        }
    }

# the first failure value of a failed future, else undef
SV *
failure(self)
        SV *self
    CODE:
    {
        punk_future *pf = pf_of(aTHX_ self);
        SV **f = (pf->state == PF_FAILED && pf->vals)
                 ? av_fetch(pf->vals, 0, 0) : NULL;
        RETVAL = (f && *f) ? newSVsv(*f) : newSV(0);
    }
    OUTPUT:
        RETVAL

# then($on_done, $on_fail?): a new future the callback's result settles.
# The else/catch($on_fail) pair takes the failure branch only, and
# followed_by($cb) calls $cb->($self) on any outcome. A callback that
# returns a future is adopted.
#
# Keep 'else' off the start of a comment line here: xsubpp matches
# /^#[ \t]*(if|ifn?def|elif|else|endif)\b/ before it decides a '#' line is a
# comment, so '# else/catch(...)' parsed as a bare #else and failed the build
# with "'else' with no matching 'if'".
SV *
then(self, on_done, on_fail = &PL_sv_undef)
        SV *self
        SV *on_done
        SV *on_fail
    CODE:
        RETVAL = pf_make_chain(aTHX_ self, on_done, on_fail, 0);
    OUTPUT:
        RETVAL

# named _pf_else because an XSUB literally named `else` makes xsubpp emit a
# bare C `else`; the public names are the aliases.
SV *
_pf_else(self, on_fail)
        SV *self
        SV *on_fail
    ALIAS:
        else = 1
        catch = 2
    CODE:
        PERL_UNUSED_VAR(ix);
        RETVAL = pf_make_chain(aTHX_ self, &PL_sv_undef, on_fail, 0);
    OUTPUT:
        RETVAL

SV *
followed_by(self, cb)
        SV *self
        SV *cb
    CODE:
        RETVAL = pf_make_chain(aTHX_ self, cb, &PL_sv_undef, 1);
    OUTPUT:
        RETVAL

# A new pending future of the same class, carrying the source's loop. This is
# how an async sub gets the future it returns - see pf_clone for why the loop
# travels with it.
SV *
AWAIT_CLONE(self)
        SV *self
    CODE:
        RETVAL = pf_clone(aTHX_ self);
    OUTPUT:
        RETVAL

# done_future(@v) / fail_future(@v): an already-settled future.
SV *
done_future(class, ...)
        SV *class
    ALIAS:
        fail_future    = 1
        AWAIT_NEW_DONE = 2
        AWAIT_NEW_FAIL = 3
    CODE:
    {
        punk_future *pf = pf_new(aTHX);
        AV *vals = newAV();
        int i;
        RETVAL = pf_bless(aTHX_ pf, pf_class_of(aTHX_ class));
        for (i = 1; i < items; i++) av_push(vals, newSVsv(ST(i)));
        /* The protocol never calls AWAIT_NEW_FAIL with no message, but a
         * failure with no failure value is not a failure. Only the AWAIT_
         * spelling gets the default; fail_future's own behaviour is left
         * exactly as it was. */
        if (ix == 3 && items < 2) av_push(vals, newSVpvs("Failed\n"));
        pf_settle(aTHX_ pf, RETVAL, (ix & 1) ? PF_FAILED : PF_DONE, vals);
    }
    OUTPUT:
        RETVAL

# needs_all/needs_any/wait_all/wait_any(@futures), and all/any aliases.
SV *
needs_all(class, ...)
        SV *class
    ALIAS:
        needs_any = 1
        wait_all  = 2
        wait_any  = 3
        all       = 4
        any       = 5
    CODE:
    {
        int mode = (ix == 4) ? PFC_NEEDS_ALL
                 : (ix == 5) ? PFC_NEEDS_ANY : (int)ix;
        int n = items - 1, i;
        SV **inputs, *G;
        G = pf_bless(aTHX_ pf_new(aTHX), pf_class_of(aTHX_ class));
        Newx(inputs, n > 0 ? n : 1, SV *);
        for (i = 0; i < n; i++) inputs[i] = ST(i + 1);
        pf_combine(aTHX_ G, mode, inputs, n);
        Safefree(inputs);
        RETVAL = G;
    }
    OUTPUT:
        RETVAL

# timer($secs): a future that settles after $secs (a loop timer, or a sleep
# off-loop). defer($cb): run $cb on the next tick; the future settles with its
# result. await: block until ready (pumping the loop), returning the future.
SV *
timer(class, secs)
        SV *class
        NV  secs
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pf_make_timer(aTHX_ (double)secs);
    OUTPUT:
        RETVAL

SV *
defer(class, cb)
        SV *class
        SV *cb
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pf_make_defer(aTHX_ cb);
    OUTPUT:
        RETVAL

SV *
await(self)
        SV *self
    CODE:
        pf_await(aTHX_ self);
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

# cancel: settle a pending future cancelled (its on_ready callbacks and any
# then-chain fire, the chain propagating the cancellation onward). Chains.
SV *
cancel(self)
        SV *self
    CODE:
    {
        punk_future *pf = pf_of(aTHX_ self);
        if (pf->state == PF_PENDING) pf_settle(aTHX_ pf, self, PF_CANCELLED, NULL);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        pf_free(aTHX_ pf_of(aTHX_ self));

MODULE = Punk        PACKAGE = Punk::Context

# Per-request conveniences: $c->promise (a new pending future), $c->timer($s) /
# $c->after($s) (a future settling after $s), and $c->await($f) (block for $f's
# result). They ignore $c - they exist where handler code already has it.
SV *
promise(self)
        SV *self
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = pf_bless(aTHX_ pf_new(aTHX), "Punk::Future");
    OUTPUT:
        RETVAL

SV *
timer(self, secs)
        SV *self
        NV  secs
    ALIAS:
        after = 1
    CODE:
        PERL_UNUSED_VAR(self); PERL_UNUSED_VAR(ix);
        RETVAL = pf_make_timer(aTHX_ (double)secs);
    OUTPUT:
        RETVAL

void
await(self, f)
        SV *self
        SV *f
    PPCODE:
    {
        punk_future *pf;
        SSize_t i, n;
        PERL_UNUSED_VAR(self);
        pf = pf_of(aTHX_ f);
        if (pf->state == PF_PENDING) pf_await(aTHX_ f);
        SP = PL_stack_base + ax - 1;      /* the loop ran: see get above */
        if (pf->state == PF_CANCELLED) croak("Punk::Future: await on a cancelled future");
        if (pf->state == PF_FAILED) {
            SV **fl = pf->vals ? av_fetch(pf->vals, 0, 0) : NULL;
            croak_sv(fl && *fl ? *fl : sv_2mortal(newSVpvs("Punk::Future failed")));
        }
        n = pf->vals ? av_len(pf->vals) + 1 : 0;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSVsv(*av_fetch(pf->vals, i, 0))));
    }
