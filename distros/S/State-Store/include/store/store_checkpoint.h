#ifndef STORE_CHECKPOINT_H
#define STORE_CHECKPOINT_H

/* Named checkpoints: a HAMT map from name to value. Naming one is one entry
 * onto a value that already exists; it holds that value for as long as the
 * name does, whatever the history limit drops. A name follows HAMT's key
 * rule: the table makes the Latin-1 and the UTF-8 spelling of one string
 * the same name. */

/* A name from Perl: its bytes and whether they are UTF-8. */
static const char *store_name(pTHX_ SV *sv, STRLEN *len, int *utf8, const char *what) {
    const char *p;
    sv = store_read_once(aTHX_ sv);
    if (!SvOK(sv)) croak("%s: a checkpoint's name cannot be undef", what);
    p = SvPV(sv, *len);
    *utf8 = SvUTF8(sv) ? 1 : 0;
    return p;
}

/* The value named, borrowed, or a croak naming the name. */
static SV *store_named(pTHX_ const store *s, SV *name, const char *what) {
    STRLEN len;
    int utf8;
    const char *p = store_name(aTHX_ name, &len, &utf8, what);
    SV *v = s->checkpoints ? (STORE_HAMT->map_fetch)(aTHX_ s->checkpoints, p, len, utf8) : NULL;
    if (!v) croak("%s: no checkpoint named \"%" SVf "\"", what, SVfARG(name));
    return v;
}

static void store_checkpoint(pTHX_ store *s, SV *name, const char *what) {
    STRLEN len;
    int utf8;
    const char *p;

    store_check_mutable(aTHX_ s, what);
    p = store_name(aTHX_ name, &len, &utf8, what);
    if (!s->checkpoints) {
        s->checkpoints = (STORE_HAMT->map_new)(aTHX);
        if (!s->checkpoints) croak("%s: out of memory", what);
    }
    if ((STORE_HAMT->map_store)(aTHX_ s->checkpoints, p, len, utf8, s->value) != HAMT_ABI_OK)
        croak("%s: out of memory", what);
}

static void store_drop_checkpoint(pTHX_ store *s, SV *name, const char *what) {
    STRLEN len;
    int utf8;
    const char *p;

    store_check_mutable(aTHX_ s, what);
    (void)store_named(aTHX_ s, name, what);
    p = store_name(aTHX_ name, &len, &utf8, what);
    if ((STORE_HAMT->map_remove)(aTHX_ s->checkpoints, p, len, utf8) != HAMT_ABI_OK)
        croak("%s: out of memory", what);
}

static int store_name_into_av(pTHX_ void *ud, const char *key, STRLEN klen, int utf8, SV *value) {
    SV *name = newSVpvn(key, klen);
    PERL_UNUSED_ARG(value);
    if (utf8) SvUTF8_on(name);
    av_push((AV *)ud, name);
    return 0;
}

#endif
