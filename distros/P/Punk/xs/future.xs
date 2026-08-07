MODULE = Punk        PACKAGE = Punk::Future

PROTOTYPES: DISABLE

# Punk::Future, in C (punk_future.h). A Future.pm-compatible async result that
# runs on the Hyperman loop when live and blocks otherwise. lib/Punk/Future.pm
# is documentation. (Core stage: create / settle / state / callbacks / get.)

SV *
new(class)
        SV *class
    CODE:
        RETVAL = pf_bless(aTHX_ pf_new(aTHX), SvPV_nolen(class));
    OUTPUT:
        RETVAL

# done(@values) / fail(@failure): settle a pending future. Chains.
SV *
done(self, ...)
        SV *self
    ALIAS:
        fail = 1
    CODE:
    {
        punk_future *pf = pf_of(aTHX_ self);
        AV *vals = newAV();
        int i;
        for (i = 1; i < items; i++) av_push(vals, newSVsv(ST(i)));
        pf_settle(aTHX_ pf, self, ix ? PF_FAILED : PF_DONE, vals);
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

IV
is_ready(self)
        SV *self
    ALIAS:
        is_done      = 1
        is_failed    = 2
        is_cancelled = 3
    CODE:
    {
        int st = pf_of(aTHX_ self)->state;
        RETVAL = ix == 0 ? (st != PF_PENDING)
               : ix == 1 ? (st == PF_DONE)
               : ix == 2 ? (st == PF_FAILED)
               :           (st == PF_CANCELLED);
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
on_ready(self, cb)
        SV *self
        SV *cb
    ALIAS:
        on_done = 1
        on_fail = 2
    CODE:
        pf_react(aTHX_ pf_of(aTHX_ self), self, (int)ix, cb);
        RETVAL = newSVsv(self);
    OUTPUT:
        RETVAL

# get / result: block until ready, then return the values (or die the failure).
void
get(self)
        SV *self
    PPCODE:
    {
        punk_future *pf = pf_of(aTHX_ self);
        SSize_t i, n;
        if (pf->state == PF_PENDING) pf_await(aTHX_ self);   /* pump / sleep */
        if (pf->state == PF_CANCELLED)
            croak("Punk::Future: get on a cancelled future");
        if (pf->state == PF_FAILED) {
            SV **f = pf->vals ? av_fetch(pf->vals, 0, 0) : NULL;
            croak_sv(f && *f ? *f : sv_2mortal(newSVpvs("Punk::Future failed")));
        }
        n = pf->vals ? av_len(pf->vals) + 1 : 0;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSVsv(*av_fetch(pf->vals, i, 0))));
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
        RETVAL = (f && *f) ? newSVsv(*f) : &PL_sv_undef;
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

# done_future(@v) / fail_future(@v): an already-settled future.
SV *
done_future(class, ...)
        SV *class
    ALIAS:
        fail_future = 1
    CODE:
    {
        punk_future *pf = pf_new(aTHX);
        AV *vals = newAV();
        int i;
        RETVAL = pf_bless(aTHX_ pf, SvPV_nolen(class));
        for (i = 1; i < items; i++) av_push(vals, newSVsv(ST(i)));
        pf_settle(aTHX_ pf, RETVAL, ix ? PF_FAILED : PF_DONE, vals);
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
        G = pf_bless(aTHX_ pf_new(aTHX), SvPV_nolen(class));
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
        if (pf->state == PF_CANCELLED) croak("Punk::Future: await on a cancelled future");
        if (pf->state == PF_FAILED) {
            SV **fl = pf->vals ? av_fetch(pf->vals, 0, 0) : NULL;
            croak_sv(fl && *fl ? *fl : sv_2mortal(newSVpvs("Punk::Future failed")));
        }
        n = pf->vals ? av_len(pf->vals) + 1 : 0;
        EXTEND(SP, n);
        for (i = 0; i < n; i++) PUSHs(sv_2mortal(newSVsv(*av_fetch(pf->vals, i, 0))));
    }
