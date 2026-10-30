/* pmcp_decl.h - tool declarations, checked and frozen at to_app.
 *
 * Needs: pmcp_reg.h, pmcp_proto.h.
 * Gives: pmcp_tools (the frozen table), pmcp_tools_freeze, pmcp_tools_free,
 * pmcp_tool_find, pmcp_json_trapped.
 *
 * A tool's list entry is encoded once per protocol version at boot, because
 * the fields differ by version: title and outputSchema arrived in 2025-06-18,
 * icons in 2025-11-25. tools/list then only concatenates bytes.
 */

#ifndef PMCP_DECL_H
#define PMCP_DECL_H

#define PMCP_TOOL_NAME_MAX 128

typedef struct {
    SV *name;                          /* owned */
    SV *target;                        /* code ref, owned */
    SV *input;                         /* JSON::Schema::Fast::Compiled, owned */
    SV *output;                        /* the same, or NULL */
    AV *guards;                        /* resolved code refs, or NULL for none */
    NV  timeout;                       /* seconds, 0 for none */
    int stream;
    SV *entry[PMCP_V_LATEST + 1];      /* encoded tools/list entry, by version */
    /* an OpenAPI tool (12): no target, a request to re-enter the app with */
    SV *oa_method;                     /* GET, POST, ... */
    SV *oa_path;                       /* the mount prefix and the path template */
    HV *oa_where;                      /* argument -> {in, name} */
} pmcp_tool;

typedef struct {
    pmcp_tool *t;                      /* sorted by name */
    IV  n;
    IV  page_size;
    int any_guard;                     /* the list is filtered per caller */
    SV **list[PMCP_V_LATEST + 1];      /* t[i].entry[v] in name order, borrowed */
} pmcp_tools;

/* ---- encoding a value someone else built ---------------------------------- */

static SV *PMCP_ENCODE = NULL;   /* \&File::Raw::JSON::file_json_encode */

/* Canonical JSON of a value an application handed back. Through the XSUB
 * under G_EVAL, because the value can hold anything (a code ref, a glob) and
 * the encoder croaks on what it cannot encode. Returns +1, or NULL with *err
 * set (+1). */
static SV *pmcp_json_trapped(pTHX_ SV *value, SV **err)
{
    SV *argv[3];
    SV *out;
    if (!PMCP_ENCODE) {
        CV *cv = get_cv("File::Raw::JSON::file_json_encode", 0);
        if (!cv) croak(PMCP_DIST ": File::Raw::JSON has no file_json_encode");
        PMCP_ENCODE = newRV_inc((SV *)cv);
    }
    argv[0] = value;
    argv[1] = sv_2mortal(newSVpvs("canonical"));
    argv[2] = sv_2mortal(newSViv(1));
    out = pmcp_call_sv(aTHX_ PMCP_ENCODE, argv, 3, G_SCALAR, err);
    if (out && !SvOK(out)) {
        SvREFCNT_dec(out);
        if (err) *err = newSVpvs("the encoder returned nothing");
        return NULL;
    }
    return out;
}

/* ---- checking a declaration ---------------------------------------------- */

static const char *const PMCP_TOOL_KEYS[] = {
    "title", "description", "input", "output", "annotations", "stream",
    "guard", "icons", "timeout", NULL
};

static const char *const PMCP_ANNOTATION_KEYS[] = {
    "title", "readOnlyHint", "destructiveHint", "idempotentHint",
    "openWorldHint", NULL
};

static void pmcp_tool_croak(pTHX_ SV *name, const char *what)
{
    croak("%s: mcp tool '%" SVf "' %s", PMCP_WHO, SVfARG(name), what);
}

static int pmcp_tool_name_ok(const char *p, STRLEN l)
{
    STRLEN i;
    if (l < 1 || l > PMCP_TOOL_NAME_MAX) return 0;
    for (i = 0; i < l; i++) {
        char c = p[i];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
              || (c >= '0' && c <= '9') || c == '_' || c == '.' || c == '-'))
            return 0;
    }
    return 1;
}

/* An object schema: a hash whose `type` is "object". */
static void pmcp_check_object_schema(pTHX_ SV *name, SV *schema, const char *k)
{
    SV *t;
    if (!pmcp_is_hash(schema)) {
        croak("%s: mcp tool '%" SVf "' %s must be a JSON Schema hash",
              PMCP_WHO, SVfARG(name), k);
    }
    t = pmcp_hget(aTHX_ (HV *)SvRV(schema), "type");
    if (!(t && !SvROK(t) && strEQ(SvPV_nolen(t), "object")))
        croak("%s: mcp tool '%" SVf "' %s must have type 'object'", PMCP_WHO,
              SVfARG(name), k);
}

/* Compile a schema with JSON::Schema::Fast's own constructor, under G_EVAL so
 * a bad one croaks naming the tool. resolver => undef: a tool's schema is part
 * of the application, and booting must not fetch a remote $ref. +1. */
static SV *pmcp_compile_schema(pTHX_ SV *name, SV *schema, const char *k)
{
    SV *argv[3], *err = NULL, *c;
    argv[0] = schema;
    argv[1] = sv_2mortal(newSVpvs("resolver"));
    argv[2] = &PL_sv_undef;
    c = pmcp_call_method(aTHX_ sv_2mortal(newSVpvs("JSON::Schema::Fast")),
                         "compile", argv, 3, G_SCALAR, &err);
    if (!c) {
        SV *why = sv_2mortal(err);
        croak("%s: mcp tool '%" SVf "' %s does not compile: %" SVf, PMCP_WHO,
              SVfARG(name), k, SVfARG(why));
    }
    return c;
}

/* A guard spec: one guard, or a list, or 'none'. Each becomes a code ref
 * through Punk's resolver. Returns NULL for 'none' or no guard, +1 AV else. */
static AV *pmcp_resolve_guards(pTHX_ SV *app, const char *kind, SV *name,
                               SV *spec)
{
    AV *out;
    SV **items;
    SSize_t i, n;
    SV *one[1];

    if (!spec) return NULL;
    if (!SvROK(spec) && SvOK(spec) && strEQ(SvPV_nolen(spec), "none"))
        return NULL;
    pmcp_check_guards(aTHX_ "guard", spec);
    if (pmcp_is_array(spec)) {
        items = AvARRAY((AV *)SvRV(spec));
        n = av_len((AV *)SvRV(spec)) + 1;
    }
    else {
        one[0] = spec;
        items = one;
        n = 1;
    }
    out = newAV();
    sv_2mortal((SV *)out);
    for (i = 0; i < n; i++) {
        SV *g = items[i];
        if (pmcp_is_code(g)) av_push(out, newSVsv(g));
        else {
            SV *argv[2], *err = NULL, *code;
            argv[0] = g;
            argv[1] = sv_2mortal(newSVpvf("the guard of mcp %s '%" SVf "'",
                                          kind, SVfARG(name)));
            code = pmcp_call_method(aTHX_ app, "_resolve_target", argv, 2,
                                    G_SCALAR, &err);
            if (!code) pmcp_croak_sv(aTHX_ sv_2mortal(err));
            av_push(out, code);
        }
    }
    return (AV *)SvREFCNT_inc_simple_NN((SV *)out);
}

/* The annotations, with the hints as JSON booleans. +1 HV ref, or NULL. */
static SV *pmcp_tool_annotations(pTHX_ SV *name, SV *a)
{
    HV *in, *out;
    HE *he;
    if (!a) return NULL;
    if (!pmcp_is_hash(a)) pmcp_tool_croak(aTHX_ name, "annotations must be a hash");
    in = (HV *)SvRV(a);
    pmcp_check_keys(aTHX_ "tool annotation", in, PMCP_ANNOTATION_KEYS);
    out = newHV();
    hv_iterinit(in);
    while ((he = hv_iternext(in))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        SV *v = HeVAL(he);
        if (kl == 5 && memEQ(k, "title", 5)) {
            if (!pmcp_is_text(v)) {
                SvREFCNT_dec((SV *)out);
                pmcp_tool_croak(aTHX_ name, "annotation title must be a string");
            }
            (void)hv_store(out, k, (I32)kl, pmcp_str(aTHX_ v), 0);
        }
        else (void)hv_store(out, k, (I32)kl, pmcp_bool(aTHX_ SvTRUE(v)), 0);
    }
    return newRV_noinc((SV *)out);
}

/* One tool's list entry for version v. +1 bytes. */
static SV *pmcp_tool_entry(pTHX_ SV *name, HV *spec, SV *annotations,
                           enum pmcp_ver v)
{
    HV *e = newHV();
    SV *rv, *bytes, *err = NULL, *x;

    (void)hv_stores(e, "name", newSVsv(name));
    if ((x = pmcp_hget(aTHX_ spec, "description")))
        (void)hv_stores(e, "description", pmcp_str(aTHX_ x));
    x = pmcp_hget(aTHX_ spec, "input");
    (void)hv_stores(e, "inputSchema",
                    x ? newSVsv(x) : newRV_noinc((SV *)newHV()));
    if (!x) {
        SV **slot = hv_fetchs(e, "inputSchema", 0);
        (void)hv_stores((HV *)SvRV(*slot), "type", newSVpvs("object"));
    }
    if (annotations) (void)hv_stores(e, "annotations", newSVsv(annotations));
    if (v >= PMCP_V_2025_06_18) {
        if ((x = pmcp_hget(aTHX_ spec, "title")))
            (void)hv_stores(e, "title", pmcp_str(aTHX_ x));
        if ((x = pmcp_hget(aTHX_ spec, "output")))
            (void)hv_stores(e, "outputSchema", newSVsv(x));
    }
    if (v >= PMCP_V_2025_11_25 && (x = pmcp_hget(aTHX_ spec, "icons")))
        (void)hv_stores(e, "icons", newSVsv(x));

    rv = sv_2mortal(newRV_noinc((SV *)e));
    bytes = pmcp_json_trapped(aTHX_ rv, &err);
    if (!bytes) {
        SV *why = sv_2mortal(err);
        croak("%s: mcp tool '%" SVf "' cannot be listed, its description is "
              "not JSON: %" SVf, PMCP_WHO, SVfARG(name), SVfARG(why));
    }
    return bytes;
}

/* ---- freezing --------------------------------------------------------------- */

static void pmcp_tools_free(pTHX_ pmcp_tools *ts)
{
    IV i;
    int v;
    if (!ts) return;
    for (i = 0; i < ts->n; i++) {
        pmcp_tool *t = &ts->t[i];
        if (t->name) SvREFCNT_dec(t->name);
        if (t->target) SvREFCNT_dec(t->target);
        if (t->input) SvREFCNT_dec(t->input);
        if (t->output) SvREFCNT_dec(t->output);
        if (t->guards) SvREFCNT_dec((SV *)t->guards);
        if (t->oa_method) SvREFCNT_dec(t->oa_method);
        if (t->oa_path) SvREFCNT_dec(t->oa_path);
        if (t->oa_where) SvREFCNT_dec((SV *)t->oa_where);
        for (v = 0; v <= PMCP_V_LATEST; v++)
            if (t->entry[v]) SvREFCNT_dec(t->entry[v]);
    }
    for (v = 0; v <= PMCP_V_LATEST; v++)
        if (ts->list[v]) Safefree(ts->list[v]);
    Safefree(ts->t);
    Safefree(ts);
}

static int pmcp_tool_cmp(const void *a, const void *b)
{
    dTHX;
    return sv_cmp(((const pmcp_tool *)a)->name, ((const pmcp_tool *)b)->name);
}

/* Check every tool declaration and freeze the table. `decls` holds the
 * resolved [kind, key, spec, target] records. */
static pmcp_tools *pmcp_tools_freeze(pTHX_ SV *app, AV *decls, HV *opts)
{
    pmcp_tools *ts;
    SSize_t i, n = av_len(decls) + 1;
    SV *v;
    NV dflt_timeout = (v = pmcp_hget(aTHX_ opts, "timeout")) ? SvNV(v) : 0;

    Newxz(ts, 1, pmcp_tools);
    Newxz(ts->t, n > 0 ? n : 1, pmcp_tool);
    ts->page_size = (v = pmcp_hget(aTHX_ opts, "page_size")) ? SvIV(v) : 50;

    /* A croak part way leaks what was built so far. It is a boot croak: the
     * application does not start, so there is nothing to leak into. */
    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        SV *kind = *av_fetch(d, PMCP_D_KIND, 0);
        SV *name = *av_fetch(d, PMCP_D_KEY, 0);
        HV *spec = (HV *)SvRV(*av_fetch(d, PMCP_D_SPEC, 0));
        pmcp_tool *t;
        STRLEN nl;
        const char *np;
        SV *annotations;
        int ver;

        if (!strEQ(SvPV_nolen(kind), "tool")) continue;
        np = SvPV_const(name, nl);
        if (!pmcp_tool_name_ok(np, nl))
            croak("%s: mcp tool '%" SVf "' has a name that is not 1 to %d of "
                  "A-Z a-z 0-9 _ . -", PMCP_WHO, SVfARG(name), PMCP_TOOL_NAME_MAX);
        {
            SV *what = sv_2mortal(newSVpvf("mcp tool '%" SVf "' key", SVfARG(name)));
            pmcp_check_keys(aTHX_ SvPV_nolen(what), spec, PMCP_TOOL_KEYS);
        }
        if ((v = pmcp_hget(aTHX_ spec, "title")) && !pmcp_is_text(v))
            pmcp_tool_croak(aTHX_ name, "title must be a string");
        if ((v = pmcp_hget(aTHX_ spec, "description")) && !pmcp_is_text(v))
            pmcp_tool_croak(aTHX_ name, "description must be a string");
        if ((v = pmcp_hget(aTHX_ spec, "input")))
            pmcp_check_object_schema(aTHX_ name, v, "input");
        if ((v = pmcp_hget(aTHX_ spec, "output")))
            pmcp_check_object_schema(aTHX_ name, v, "output");
        if ((v = pmcp_hget(aTHX_ spec, "icons"))) pmcp_check_icons(aTHX_ v);
        if ((v = pmcp_hget(aTHX_ spec, "timeout"))
            && (SvROK(v) || !looks_like_number(v) || !(SvNV(v) > 0)))
            pmcp_tool_croak(aTHX_ name, "timeout must be a number of seconds above 0");

        t = &ts->t[ts->n];
        t->name = newSVsv(name);
        ts->n++;
        t->target = newSVsv(*av_fetch(d, PMCP_D_TARGET, 0));
        v = pmcp_hget(aTHX_ spec, "input");
        {
            SV *dflt = NULL;
            if (!v) {
                HV *h = newHV();
                (void)hv_stores(h, "type", newSVpvs("object"));
                dflt = sv_2mortal(newRV_noinc((SV *)h));
            }
            t->input = pmcp_compile_schema(aTHX_ name, v ? v : dflt, "input");
        }
        if ((v = pmcp_hget(aTHX_ spec, "output")))
            t->output = pmcp_compile_schema(aTHX_ name, v, "output");
        t->guards = pmcp_resolve_guards(aTHX_ app, "tool", name,
                                        hv_exists(spec, "guard", 5)
                                        ? *hv_fetchs(spec, "guard", 0) : NULL);
        if (t->guards) ts->any_guard = 1;
        t->timeout = (v = pmcp_hget(aTHX_ spec, "timeout")) ? SvNV(v) : dflt_timeout;
        t->stream = (v = pmcp_hget(aTHX_ spec, "stream")) && SvTRUE(v);

        annotations = pmcp_tool_annotations(aTHX_ name,
                                            pmcp_hget(aTHX_ spec, "annotations"));
        if (annotations) sv_2mortal(annotations);
        for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++)
            t->entry[ver] = pmcp_tool_entry(aTHX_ name, spec, annotations,
                                            (enum pmcp_ver)ver);
    }
    if (ts->n > 1) qsort(ts->t, (size_t)ts->n, sizeof(pmcp_tool), pmcp_tool_cmp);
    {
        int ver;
        for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++) {
            Newxz(ts->list[ver], ts->n > 0 ? ts->n : 1, SV *);
            for (i = 0; i < ts->n; i++) ts->list[ver][i] = ts->t[i].entry[ver];
        }
    }
    return ts;
}

/* By name, or NULL. The table is sorted, so a binary search. */
static pmcp_tool *pmcp_tool_find(pTHX_ pmcp_tools *ts, SV *name)
{
    IV lo = 0, hi = ts ? ts->n : 0;
    while (lo < hi) {
        IV mid = lo + (hi - lo) / 2;
        int c = sv_cmp(name, ts->t[mid].name);
        if (c == 0) return &ts->t[mid];
        if (c < 0) hi = mid; else lo = mid + 1;
    }
    return NULL;
}

#endif /* PMCP_DECL_H */
