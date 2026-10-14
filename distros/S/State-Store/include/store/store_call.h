#ifndef STORE_CALL_H
#define STORE_CALL_H

/* G_LIST is perl 5.36's name for what older perls call G_ARRAY. */
#ifndef G_LIST
#  define G_LIST G_ARRAY
#endif

/* A caller's scalar read once - its magic run once - into a mortal copy
 * the rest can read as often as it likes. Not sv_mortalcopy: that takes
 * the string buffer of a temporary it copies, leaving the temporary empty,
 * and a temporary is what a sub's return value is. NOSTEAL copies it. */
static SV *store_read_once(pTHX_ SV *sv) {
    SV *c = sv_newmortal();
    sv_setsv_flags(c, sv, SV_GMAGIC | SV_NOSTEAL);
    return c;
}

/* Every sub the store calls - a swap's, a watcher, the validator, a
 * transaction's - is called through here.
 *
 * On a stack of its own, as perl's sort calls its comparison. Without that,
 * `last` or `next` inside the sub finds the caller's loop on the context
 * stack and jumps to it straight through this library's C, which never
 * gets control back: a transaction would stay open for ever. On a stack of
 * its own there is no loop to find, so it is an error like any other, and
 * the store deals with it as it deals with a die.
 *
 * Under G_EVAL, with $@ localised, so that a call that works leaves the
 * caller's $@ as it was. A die comes back as a copy of the error, mortal,
 * for the caller to throw again once it has put things right.
 *
 * `gimme` is G_VOID, G_SCALAR or G_LIST. A scalar result is put in *one;
 * list results are pushed onto `many`. Either is a temporary that lives as
 * long as the caller's temps frame. */
static SV *store_call(pTHX_ SV *code, SV **args, I32 nargs, I32 gimme,
                      SV **one, AV *many) {
    dSP;
    SV *err = NULL;
    I32 n, i;

    if (one) *one = &PL_sv_undef;
    ENTER;
    save_scalar(PL_errgv);
    PUSHSTACKi(PERLSI_UNKNOWN);
    {
        PUSHMARK(SP);
        EXTEND(SP, nargs);
        for (i = 0; i < nargs; i++) PUSHs(args[i]);
        PUTBACK;
        n = call_sv(code, gimme | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            err = sv_2mortal(newSVsv(ERRSV));
        }
        else if (gimme == G_SCALAR && one) {
            if (n > 0) *one = *SP;
        }
        else if (gimme == G_LIST && many) {
            for (i = n; i > 0; i--) av_push(many, SvREFCNT_inc_simple_NN(*(SP - i + 1)));
        }
        SP -= n;
        PUTBACK;
    }
    POPSTACK;
    LEAVE;
    return err;
}

/* Throw `err` again. */
static void store_rethrow(pTHX_ SV *err) {
    sv_setsv(ERRSV, err);
    croak(NULL);
}

#endif
