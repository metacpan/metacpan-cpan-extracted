/* pmcp_prompt.h - prompts: declarations, prompts/list, prompts/get.
 *
 * Needs: pmcp_call.h.
 *
 * A prompt is an action that returns messages. Its declared arguments are the
 * names a client may fill, and the required ones are checked before the action
 * runs. Arguments are strings, as the protocol has them, and reach the action
 * as params.
 */

#ifndef PMCP_PROMPT_H
#define PMCP_PROMPT_H

typedef struct {
    SV *name;
    SV *target;
    AV *guards;
    NV  timeout;
    AV *required;                    /* names of the required arguments */
    SV *description;                 /* or NULL */
    SV *entry[PMCP_V_LATEST + 1];
} pmcp_prompt;

typedef struct {
    pmcp_prompt *p;                  /* sorted by name */
    IV  n;
    IV  page_size;
    int any_guard;
    SV **list[PMCP_V_LATEST + 1];
} pmcp_prompts;

static const char *const PMCP_PROMPT_KEYS[] = {
    "title", "description", "arguments", "guard", "icons", "timeout", NULL
};

static void pmcp_prompt_croak(pTHX_ SV *name, const char *what)
{
    croak("%s: mcp prompt '%" SVf "' %s", PMCP_WHO, SVfARG(name), what);
}

/* The arguments as listed: [{name, description?, required}]. +1 AV ref, and
 * the required names into `req`. */
static SV *pmcp_prompt_args(pTHX_ SV *name, SV *a, AV *req)
{
    static const char *const keys[] = { "name", "description", "required", NULL };
    AV *src, *out;
    SSize_t i, n;
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    if (!a) return newRV_noinc((SV *)newAV());
    if (!pmcp_is_array(a))
        pmcp_prompt_croak(aTHX_ name, "arguments must be a list of {name, description, required}");
    src = (AV *)SvRV(a);
    out = (AV *)sv_2mortal((SV *)newAV());
    n = av_len(src) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(src, i, 0);
        HV *h, *o;
        SV *an, *x;
        if (!(e && pmcp_is_hash(*e)))
            pmcp_prompt_croak(aTHX_ name, "arguments must be a list of {name, description, required}");
        h = (HV *)SvRV(*e);
        {
            SV *what = sv_2mortal(newSVpvf("mcp prompt '%" SVf "' argument key", SVfARG(name)));
            pmcp_check_keys(aTHX_ SvPV_nolen(what), h, keys);
        }
        an = pmcp_hget(aTHX_ h, "name");
        if (!pmcp_is_text(an)) pmcp_prompt_croak(aTHX_ name, "has an argument with no name");
        if (hv_exists_ent(seen, an, 0)) {
            SV *m = sv_2mortal(newSVpvf("names the argument '%" SVf "' twice", SVfARG(an)));
            pmcp_prompt_croak(aTHX_ name, SvPV_nolen(m));
        }
        (void)hv_store_ent(seen, an, newSViv(1), 0);
        o = newHV();
        av_push(out, newRV_noinc((SV *)o));
        (void)hv_stores(o, "name", pmcp_str(aTHX_ an));
        if ((x = pmcp_hget(aTHX_ h, "description"))) {
            if (!pmcp_is_text(x)) pmcp_prompt_croak(aTHX_ name, "has an argument description that is not a string");
            (void)hv_stores(o, "description", pmcp_str(aTHX_ x));
        }
        x = pmcp_hget(aTHX_ h, "required");
        (void)hv_stores(o, "required", pmcp_bool(aTHX_ x && SvTRUE(x)));
        if (x && SvTRUE(x)) av_push(req, newSVsv(an));
    }
    return newRV_inc((SV *)out);
}

static SV *pmcp_prompt_entry(pTHX_ SV *name, HV *spec, SV *args, enum pmcp_ver v)
{
    HV *e = newHV();
    SV *x, *bytes, *err = NULL;
    (void)hv_stores(e, "name", newSVsv(name));
    if ((x = pmcp_hget(aTHX_ spec, "description")))
        (void)hv_stores(e, "description", pmcp_str(aTHX_ x));
    (void)hv_stores(e, "arguments", newSVsv(args));
    if (v >= PMCP_V_2025_06_18 && (x = pmcp_hget(aTHX_ spec, "title")))
        (void)hv_stores(e, "title", pmcp_str(aTHX_ x));
    if (v >= PMCP_V_2025_11_25 && (x = pmcp_hget(aTHX_ spec, "icons")))
        (void)hv_stores(e, "icons", newSVsv(x));
    bytes = pmcp_json_trapped(aTHX_ sv_2mortal(newRV_noinc((SV *)e)), &err);
    if (!bytes) {
        sv_2mortal(err);
        croak("%s: mcp prompt '%" SVf "' cannot be listed: %" SVf, PMCP_WHO,
              SVfARG(name), SVfARG(err));
    }
    return bytes;
}

static void pmcp_prompts_free(pTHX_ pmcp_prompts *ps)
{
    IV i;
    int v;
    if (!ps) return;
    for (i = 0; i < ps->n; i++) {
        pmcp_prompt *p = &ps->p[i];
        if (p->name) SvREFCNT_dec(p->name);
        if (p->target) SvREFCNT_dec(p->target);
        if (p->guards) SvREFCNT_dec((SV *)p->guards);
        if (p->required) SvREFCNT_dec((SV *)p->required);
        if (p->description) SvREFCNT_dec(p->description);
        for (v = 0; v <= PMCP_V_LATEST; v++) if (p->entry[v]) SvREFCNT_dec(p->entry[v]);
    }
    for (v = 0; v <= PMCP_V_LATEST; v++) if (ps->list[v]) Safefree(ps->list[v]);
    Safefree(ps->p);
    Safefree(ps);
}

static int pmcp_prompt_cmp(const void *a, const void *b)
{
    dTHX;
    return sv_cmp(((const pmcp_prompt *)a)->name, ((const pmcp_prompt *)b)->name);
}

static pmcp_prompts *pmcp_prompts_freeze(pTHX_ SV *app, AV *decls, HV *opts)
{
    pmcp_prompts *ps;
    SSize_t i, n = av_len(decls) + 1;
    SV *v;
    NV dflt_timeout = (v = pmcp_hget(aTHX_ opts, "timeout")) ? SvNV(v) : 0;

    Newxz(ps, 1, pmcp_prompts);
    Newxz(ps->p, n > 0 ? n : 1, pmcp_prompt);
    ps->page_size = (v = pmcp_hget(aTHX_ opts, "page_size")) ? SvIV(v) : 50;

    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        SV *name = *av_fetch(d, PMCP_D_KEY, 0);
        HV *spec = (HV *)SvRV(*av_fetch(d, PMCP_D_SPEC, 0));
        pmcp_prompt *p;
        SV *args;
        int ver;

        if (!strEQ(SvPV_nolen(*av_fetch(d, PMCP_D_KIND, 0)), "prompt")) continue;
        {
            SV *what = sv_2mortal(newSVpvf("mcp prompt '%" SVf "' key", SVfARG(name)));
            pmcp_check_keys(aTHX_ SvPV_nolen(what), spec, PMCP_PROMPT_KEYS);
        }
        if ((v = pmcp_hget(aTHX_ spec, "title")) && !pmcp_is_text(v))
            pmcp_prompt_croak(aTHX_ name, "title must be a string");
        if ((v = pmcp_hget(aTHX_ spec, "description")) && !pmcp_is_text(v))
            pmcp_prompt_croak(aTHX_ name, "description must be a string");
        if ((v = pmcp_hget(aTHX_ spec, "icons"))) pmcp_check_icons(aTHX_ v);
        if ((v = pmcp_hget(aTHX_ spec, "timeout"))
            && (SvROK(v) || !looks_like_number(v) || !(SvNV(v) > 0)))
            pmcp_prompt_croak(aTHX_ name, "timeout must be a number of seconds above 0");

        p = &ps->p[ps->n++];
        p->name = newSVsv(name);
        p->required = newAV();
        args = sv_2mortal(pmcp_prompt_args(aTHX_ name, pmcp_hget(aTHX_ spec, "arguments"),
                                           p->required));
        p->target = newSVsv(*av_fetch(d, PMCP_D_TARGET, 0));
        p->guards = pmcp_resolve_guards(aTHX_ app, "prompt", name,
                        hv_exists(spec, "guard", 5) ? *hv_fetchs(spec, "guard", 0) : NULL);
        if (p->guards) ps->any_guard = 1;
        p->timeout = (v = pmcp_hget(aTHX_ spec, "timeout")) ? SvNV(v) : dflt_timeout;
        if ((v = pmcp_hget(aTHX_ spec, "description"))) p->description = newSVsv(v);
        for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++)
            p->entry[ver] = pmcp_prompt_entry(aTHX_ name, spec, args, (enum pmcp_ver)ver);
    }
    if (ps->n > 1) qsort(ps->p, (size_t)ps->n, sizeof(pmcp_prompt), pmcp_prompt_cmp);
    {
        int ver;
        IV k;
        for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++) {
            Newxz(ps->list[ver], ps->n > 0 ? ps->n : 1, SV *);
            for (k = 0; k < ps->n; k++) ps->list[ver][k] = ps->p[k].entry[ver];
        }
    }
    return ps;
}

/* ---- prompts/list ------------------------------------------------------------- */

typedef struct { pmcp_prompts *ps; SV *c; } pmcp_prompt_list_ctx;

static int pmcp_prompt_visible(pTHX_ void *vctx, IV i)
{
    pmcp_prompt_list_ctx *x = (pmcp_prompt_list_ctx *)vctx;
    SV *why;
    if (!x->ps->p[i].guards) return 1;
    if (!x->c) return 0;
    why = pmcp_run_guards(aTHX_ x->ps->p[i].guards, x->c);
    if (!why) return 1;
    SvREFCNT_dec(why);
    return 0;
}

static SV *pmcp_prompts_list(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    pmcp_prompts *ps = (pmcp_prompts *)s->prompts;
    enum pmcp_ver v = r->version ? r->version : PMCP_V_2025_03_26;
    SV **cur = params ? hv_fetchs(params, "cursor", 0) : NULL;
    IV start = 0;
    pmcp_prompt_list_ctx x;

    if (!ps) return pmcp_fail(r, PMCP_METHOD, "method not found");
    if (cur && SvOK(*cur)) {
        start = pmcp_cursor_read(aTHX_ *cur, ps->n);
        if (start < 0) return pmcp_fail(r, PMCP_PARAMS, "invalid cursor");
    }
    x.ps = ps;
    x.c = r->c;
    r->raw = pmcp_page_bytes(aTHX_ "prompts", ps->list[v], ps->n, start,
                             ps->page_size, ps->any_guard ? pmcp_prompt_visible : NULL, &x);
    return NULL;
}

/* ---- prompts/get ----------------------------------------------------------------- */

static pmcp_prompt *pmcp_prompt_find(pTHX_ pmcp_prompts *ps, SV *name)
{
    IV lo = 0, hi = ps->n;
    while (lo < hi) {
        IV mid = lo + (hi - lo) / 2;
        int c = sv_cmp(name, ps->p[mid].name);
        if (c == 0) return &ps->p[mid];
        if (c < 0) hi = mid; else lo = mid + 1;
    }
    return NULL;
}

/* One message: {role, content}, content a string or a content block. Returns
 * +1, or NULL with *bad set to what was wrong. */
static SV *pmcp_prompt_message(pTHX_ SV *m, const char **bad)
{
    HV *h, *out;
    SV *role, *content;
    const char *rp;
    if (!pmcp_is_hash(m)) { *bad = "a prompt message is not a {role, content} hash"; return NULL; }
    h = (HV *)SvRV(m);
    role = pmcp_hget(aTHX_ h, "role");
    rp = (role && !SvROK(role)) ? SvPV_nolen(role) : "";
    if (!(strEQ(rp, "user") || strEQ(rp, "assistant"))) {
        *bad = "a prompt message has a role that is not user or assistant";
        return NULL;
    }
    content = pmcp_hget(aTHX_ h, "content");
    out = newHV();
    (void)hv_stores(out, "role", newSVpv(rp, 0));
    if (content && pmcp_is_hash(content))
        (void)hv_stores(out, "content", newSVsv(content));
    else if (content && (!SvROK(content) || SvAMAGIC(content))) {
        HV *b = newHV();
        (void)hv_stores(b, "type", newSVpvs("text"));
        (void)hv_stores(b, "text", pmcp_str(aTHX_ content));
        (void)hv_stores(out, "content", newRV_noinc((SV *)b));
    }
    else {
        SvREFCNT_dec((SV *)out);
        *bad = "a prompt message has no content";
        return NULL;
    }
    return newRV_noinc((SV *)out);
}

static SV *pmcp_prompts_get(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    pmcp_prompts *ps = (pmcp_prompts *)s->prompts;
    enum pmcp_ver v = r->version ? r->version : PMCP_V_2025_03_26;
    SV **nv = params ? hv_fetchs(params, "name", 0) : NULL;
    SV **av = params ? hv_fetchs(params, "arguments", 0) : NULL;
    SV *args, *call, *child, *why = NULL, *val, *desc = NULL, *out, *bytes, *err = NULL;
    AV *msgs = NULL, *list;
    pmcp_prompt *p;
    SSize_t i, n;

    if (!ps) return pmcp_fail(r, PMCP_METHOD, "method not found");
    if (!(nv && pmcp_is_str(*nv)))
        return pmcp_fail(r, PMCP_PARAMS, "a prompt name is required");
    p = pmcp_prompt_find(aTHX_ ps, *nv);
    if (!p) return pmcp_fail(r, PMCP_PARAMS, "unknown prompt");
    if (av && SvOK(*av) && !pmcp_is_hash(*av))
        return pmcp_fail(r, PMCP_PARAMS, "arguments must be an object");
    if (!r->c) return pmcp_fail(r, PMCP_INTERNAL, "no request to get the prompt in");

    args = (av && SvOK(*av)) ? *av : sv_2mortal(newRV_noinc((SV *)newHV()));
    call = sv_2mortal(pmcp_call_object(aTHX_ "prompts/get", p->name, args, v, params));
    pmcp_call_attach(aTHX_ r, call);
    child = sv_2mortal(pmcp_child_context(aTHX_ r->c, "prompt", p->name, args, call));

    /* a prompt the caller may not see is one that does not exist */
    if ((why = pmcp_run_guards(aTHX_ p->guards, child))) {
        SvREFCNT_dec(why);
        return pmcp_fail(r, PMCP_PARAMS, "unknown prompt");
    }

    {
        HE *he;
        HV *ah = (HV *)SvRV(args);
        hv_iterinit(ah);
        while ((he = hv_iternext(ah))) {
            SV *val2 = HeVAL(he);
            if (SvROK(val2) || !SvOK(val2)) {
                STRLEN kl;
                const char *k = HePV(he, kl);
                r->edata = newRV_noinc((SV *)newHV());
                (void)hv_stores((HV *)SvRV(r->edata), "argument", newSVpvn(k, kl));
                return pmcp_fail(r, PMCP_PARAMS, "prompt arguments must be strings");
            }
        }
        n = av_len(p->required) + 1;
        for (i = 0; i < n; i++) {
            SV *rn = *av_fetch(p->required, i, 0);
            if (!hv_exists_ent(ah, rn, 0)) {
                r->edata = newRV_noinc((SV *)newHV());
                (void)hv_stores((HV *)SvRV(r->edata), "argument", newSVsv(rn));
                return pmcp_fail(r, PMCP_PARAMS, "a required argument is missing");
            }
        }
    }

    val = pmcp_run_action(aTHX_ p->target, child, p->timeout, &why);
    if (!val) {
        r->edata = newRV_noinc((SV *)newHV());
        (void)hv_stores((HV *)SvRV(r->edata), "reason", why);
        return pmcp_fail(r, PMCP_INTERNAL, "the prompt failed");
    }

    if (pmcp_is_triplet(aTHX_ val)) {
        AV *tr = (AV *)SvRV(val);
        IV status = SvIV(*av_fetch(tr, 0, 0));
        int is_json;
        SV *body = pmcp_triplet_body(aTHX_ tr, &is_json);
        if (status >= 400 || !body) {
            r->edata = newRV_noinc((SV *)newHV());
            (void)hv_stores((HV *)SvRV(r->edata), "status", newSViv(status));
            return pmcp_fail(r, PMCP_INTERNAL, "the prompt failed");
        }
        val = body;
    }

    list = (AV *)sv_2mortal((SV *)newAV());
    if (!SvOK(val)) return pmcp_fail(r, PMCP_INTERNAL, "the prompt returned nothing");
    if (!SvROK(val) || SvAMAGIC(val)) {
        HV *m = newHV();
        (void)hv_stores(m, "role", newSVpvs("user"));
        (void)hv_stores(m, "content", newSVsv(val));
        av_push(list, newRV_noinc((SV *)m));
    }
    else if (pmcp_is_hash(val) && pmcp_is_array(pmcp_hget(aTHX_ (HV *)SvRV(val), "messages"))) {
        msgs = (AV *)SvRV(pmcp_hget(aTHX_ (HV *)SvRV(val), "messages"));
        desc = pmcp_hget(aTHX_ (HV *)SvRV(val), "description");
    }
    else if (pmcp_is_array(val)) msgs = (AV *)SvRV(val);
    else if (pmcp_is_hash(val)) av_push(list, newSVsv(val));
    else return pmcp_fail(r, PMCP_INTERNAL, "the prompt returned something that is not messages");
    if (msgs) {
        n = av_len(msgs) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(msgs, i, 0);
            av_push(list, newSVsv(e ? *e : &PL_sv_undef));
        }
    }

    {
        AV *clean = newAV();
        n = av_len(list) + 1;
        for (i = 0; i < n; i++) {
            const char *bad = NULL;
            SV *m = pmcp_prompt_message(aTHX_ *av_fetch(list, i, 0), &bad);
            if (!m) {
                SvREFCNT_dec((SV *)clean);
                return pmcp_fail(r, PMCP_INTERNAL, bad);
            }
            av_push(clean, m);
        }
        out = newRV_noinc((SV *)newHV());
        if (desc) (void)hv_stores((HV *)SvRV(out), "description", pmcp_str(aTHX_ desc));
        else if (p->description)
            (void)hv_stores((HV *)SvRV(out), "description", newSVsv(p->description));
        (void)hv_stores((HV *)SvRV(out), "messages", newRV_noinc((SV *)clean));
    }
    bytes = pmcp_json_trapped(aTHX_ out, &err);
    SvREFCNT_dec(out);
    if (!bytes) {
        SvREFCNT_dec(err);
        return pmcp_fail(r, PMCP_INTERNAL, "the prompt is not JSON");
    }
    r->raw = bytes;
    return NULL;
}

#endif /* PMCP_PROMPT_H */
