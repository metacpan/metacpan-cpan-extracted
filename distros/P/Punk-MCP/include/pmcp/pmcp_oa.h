/* pmcp_oa.h - tools from an Open::API mount, called by re-entering the app.
 *
 * Needs: pmcp_decl.h, pmcp_call.h, pmcp_state.h.
 *
 * `openapi` names mounts: a mount object as `api` returns it, '*' for every
 * mount, or a string matching a mount's spec or its prefix. Each operation
 * becomes a tool, unless `ops` leaves it out or its `x-mcp` is false. The spec
 * stays the source of truth, as it is for Maat, and the rules are Maat's
 * (Maat/include/mt_mcp_tools.h):
 *
 *   name         the operationId lowercased, anything else made _, 64 at most,
 *                _N on a collision. A collision with a DSL tool croaks
 *   description  the summary, then the description, clipped to 1024
 *   annotations  from the method alone: GET and HEAD read-only, PUT and DELETE
 *                idempotent, DELETE destructive, and open world
 *   inputSchema  Open::API's operation_schema: the parameters flat, the body
 *                under `body`, with $defs
 *   x-mcp        { name, title, description, annotations } overrides those.
 *                No guard: the mount's own guards run on the inner request.
 *
 * A call is a request the application answers: a synthetic env built in C as
 * Maat's mt_mcp_call builds one, handed to the innermost app (a middleware
 * added last at on_compile captures it). So the mount's security checker,
 * its validation and its guards all run, and the answer comes back through
 * 05's triplet branch. The env carries the caller's Authorization to this
 * application's own mount and nowhere else, and is marked pmcp.inner and
 * pmcp.tool so an observer or a rate limit can tell the inner request apart.
 */

#ifndef PMCP_OA_H
#define PMCP_OA_H

#define PMCP_OA_NAME_MAX 64
#define PMCP_OA_DESC_MAX 1024

static const char *const PMCP_XMCP_KEYS[] = {
    "name", "title", "description", "annotations", NULL
};

/* ---- the input handle ------------------------------------------------------------ */

static SV *PMCP_INPUT = NULL;   /* sub { open my $fh, '<', \$_[0]; $fh } */

/* An in-memory read handle over `bytes`, for psgi.input: Punk reads a body
 * through PerlIO, so it has to be a real handle. +1 */
static SV *pmcp_input_handle(pTHX_ SV *bytes)
{
    SV *fh, *copy;
    if (!PMCP_INPUT) {
        PMCP_INPUT = eval_pv("sub { my $b = $_[0]; open my $fh, '<', \\$b "
                             "or die \"cannot open a body handle: $!\"; $fh }", TRUE);
        SvREFCNT_inc_simple_void_NN(PMCP_INPUT);
    }
    copy = sv_2mortal(newSVsv(bytes));
    fh = pmcp_call_sv(aTHX_ PMCP_INPUT, &copy, 1, G_SCALAR, NULL);
    return fh;
}

/* ---- percent encoding ------------------------------------------------------------- */

/* Everything outside RFC 3986's unreserved set is escaped: the same routine
 * serves a path segment and a query value, and over-escaping is always safe
 * where under-escaping smuggles a delimiter. A JSON boolean goes out as
 * true or false, not as SCALAR(0x...). */
static void pmcp_pct_cat(pTHX_ SV *out, SV *v)
{
    static const char hex[] = "0123456789ABCDEF";
    STRLEN l, i;
    const char *p;
    if (!v || !SvOK(v)) return;
    if (SvROK(v) && SvTYPE(SvRV(v)) < SVt_PVAV) {
        sv_catpv(out, SvTRUE(SvRV(v)) ? "true" : "false");
        return;
    }
    if (SvROK(v)) return;
    p = SvPVutf8(v, l);
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
            || c == '-' || c == '.' || c == '_' || c == '~')
            sv_catpvn(out, (const char *)&c, 1);
        else {
            char b[3];
            b[0] = '%'; b[1] = hex[c >> 4]; b[2] = hex[c & 15];
            sv_catpvn(out, b, 3);
        }
    }
}

/* ---- finding the mounts --------------------------------------------------------------- */

/* Does `want` (an `openapi` entry) name `mount`? */
static int pmcp_oa_names(pTHX_ SV *want, SV *mount)
{
    SV *spec, *prefix;
    if (SvROK(want)) return SvRV(want) == SvRV(mount);
    if (strEQ(SvPV_nolen(want), "*")) return 1;
    spec = pmcp_hget(aTHX_ (HV *)SvRV(mount), "spec");
    if (spec && !SvROK(spec) && sv_eq(spec, want)) return 1;
    prefix = sv_2mortal(pmcp_call_method(aTHX_ mount, "prefix", NULL, 0, G_SCALAR, NULL));
    return prefix && SvOK(prefix) && SvCUR(prefix) && sv_eq(prefix, want);
}

/* ---- deriving the tools ------------------------------------------------------------------ */

/* The tool name for an operationId, made unique against `used`. Mortal. */
static SV *pmcp_oa_name(pTHX_ SV *raw, HV *used)
{
    SV *base = sv_2mortal(newSVpvs("")), *name;
    STRLEN l, i;
    const char *p = SvPV_const(raw, l);
    int n = 1;
    for (i = 0; i < l && SvCUR(base) < PMCP_OA_NAME_MAX; i++) {
        char c = p[i];
        if (c >= 'A' && c <= 'Z') c = (char)(c - 'A' + 'a');
        if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '-'))
            c = '_';
        sv_catpvn(base, &c, 1);
    }
    if (!SvCUR(base)) sv_catpvs(base, "op");
    name = sv_2mortal(newSVsv(base));
    while (hv_exists_ent(used, name, 0)) {
        char suffix[16];
        int sl = my_snprintf(suffix, sizeof suffix, "_%d", ++n);
        name = sv_2mortal(newSVsv(base));
        if (SvCUR(name) > (STRLEN)(PMCP_OA_NAME_MAX - sl))
            SvCUR_set(name, PMCP_OA_NAME_MAX - sl);
        sv_catpvn(name, suffix, sl);
    }
    (void)hv_store_ent(used, name, newSViv(1), 0);
    return name;
}

static SV *pmcp_clip(pTHX_ SV *t)
{
    if (!t || !SvOK(t) || !SvCUR(t)) return NULL;
    if (SvCUR(t) <= PMCP_OA_DESC_MAX) return sv_2mortal(newSVsv(t));
    {
        SV *c = sv_2mortal(newSVpvn(SvPVX(t), PMCP_OA_DESC_MAX - 4));
        sv_catpvs(c, " ...");
        return c;
    }
}

/* argument name -> {in, name}, from $api->operation($id). Header, path and
 * query, as Maat does. A cookie argument would have to be folded into the
 * Cookie header, and no spec in front of this has used one: left out rather
 * than guessed. +1 HV */
static HV *pmcp_oa_where(pTHX_ SV *api, SV *op_id)
{
    static const char *const locs[] = { "path", "query", "header", NULL };
    HV *w = newHV();
    SV *info = pmcp_call_method(aTHX_ api, "operation", &op_id, 1, G_SCALAR, NULL);
    HV *params;
    int li;
    sv_2mortal(info);
    if (!pmcp_is_hash(info) || !pmcp_is_hash(pmcp_hget(aTHX_ (HV *)SvRV(info), "params")))
        return w;
    params = (HV *)SvRV(pmcp_hget(aTHX_ (HV *)SvRV(info), "params"));
    for (li = 0; locs[li]; li++) {
        SV *list = pmcp_hget(aTHX_ params, locs[li]);
        SSize_t i, n;
        if (!pmcp_is_array(list)) continue;
        n = av_len((AV *)SvRV(list)) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch((AV *)SvRV(list), i, 0);
            SV *nm;
            HV *rec;
            if (!(e && pmcp_is_hash(*e))) continue;
            nm = pmcp_hget(aTHX_ (HV *)SvRV(*e), "name");
            if (!nm) continue;
            rec = newHV();
            (void)hv_stores(rec, "in", newSVpv(locs[li], 0));
            (void)hv_stores(rec, "name", newSVsv(nm));
            (void)hv_store_ent(w, nm, newRV_noinc((SV *)rec), 0);
        }
    }
    return w;
}

/* The tool spec 05's freeze understands, built from the operation. Mortal HV,
 * or NULL when x-mcp says to leave the operation out. */
static HV *pmcp_oa_spec(pTHX_ SV *api, HV *op, SV *opname)
{
    SV *op_id = pmcp_hget(aTHX_ op, "operationId");
    SV *method = pmcp_hget(aTHX_ op, "method");
    SV *path = pmcp_hget(aTHX_ op, "path");
    HV *spec = (HV *)sv_2mortal((SV *)newHV());
    HV *x = NULL;
    SV *doc, *schema, *v;

    {   /* x-mcp, from the raw spec */
        SV *raw = sv_2mortal(pmcp_call_method(aTHX_ api, "spec", NULL, 0, G_SCALAR, NULL));
        SV *paths = pmcp_is_hash(raw) ? pmcp_hget(aTHX_ (HV *)SvRV(raw), "paths") : NULL;
        SV *item = (paths && pmcp_is_hash(paths)) ? pmcp_hget(aTHX_ (HV *)SvRV(paths), SvPV_nolen(path)) : NULL;
        SV *rop = (item && pmcp_is_hash(item)) ? pmcp_hget(aTHX_ (HV *)SvRV(item), SvPV_nolen(method)) : NULL;
        SV *xv = (rop && pmcp_is_hash(rop)) ? pmcp_hget(aTHX_ (HV *)SvRV(rop), "x-mcp") : NULL;
        if (xv && !SvROK(xv) && !SvTRUE(xv)) return NULL;
        if (xv && SvROK(xv) && SvTYPE(SvRV(xv)) < SVt_PVAV && !SvTRUE(SvRV(xv))) return NULL;
        if (xv && pmcp_is_hash(xv)) {
            SV *what = sv_2mortal(newSVpvf("x-mcp key on operation '%" SVf "'", SVfARG(op_id)));
            x = (HV *)SvRV(xv);
            pmcp_check_keys(aTHX_ SvPV_nolen(what), x, PMCP_XMCP_KEYS);
        }
    }

    doc = sv_2mortal(pmcp_call_method(aTHX_ api, "operation_doc", &op_id, 1, G_SCALAR, NULL));
    if ((v = x ? pmcp_hget(aTHX_ x, "title") : NULL)) (void)hv_stores(spec, "title", newSVsv(v));
    if ((v = x ? pmcp_hget(aTHX_ x, "description") : NULL)) {
        (void)hv_stores(spec, "description", newSVsv(pmcp_clip(aTHX_ v)));
    }
    else if (pmcp_is_hash(doc)) {
        SV *s = pmcp_hget(aTHX_ (HV *)SvRV(doc), "summary");
        SV *d = pmcp_hget(aTHX_ (HV *)SvRV(doc), "description");
        SV *joined = sv_2mortal(newSVpvs(""));
        if (s) sv_catsv(joined, s);
        if (d && SvCUR(d)) {
            if (SvCUR(joined)) sv_catpvs(joined, "\n\n");
            sv_catsv(joined, d);
        }
        if (SvCUR(joined)) (void)hv_stores(spec, "description", newSVsv(pmcp_clip(aTHX_ joined)));
    }
    if ((v = x ? pmcp_hget(aTHX_ x, "annotations") : NULL)) {
        (void)hv_stores(spec, "annotations", newSVsv(v));
    }
    else {
        HV *a = newHV();
        const char *m = SvPV_nolen(method);
        int read = foldEQ(m, "get", 3) || foldEQ(m, "head", 4);
        int del = strlen(m) == 6 && foldEQ(m, "delete", 6);
        int put = strlen(m) == 3 && foldEQ(m, "put", 3);
        (void)hv_stores(a, "readOnlyHint", newSViv(read));
        (void)hv_stores(a, "destructiveHint", newSViv(del));
        (void)hv_stores(a, "idempotentHint", newSViv(read || put || del));
        (void)hv_stores(a, "openWorldHint", newSViv(1));
        (void)hv_stores(spec, "annotations", newRV_noinc((SV *)a));
    }
    schema = pmcp_call_method(aTHX_ api, "operation_schema", &op_id, 1, G_SCALAR, NULL);
    (void)hv_stores(spec, "input", schema ? schema : newRV_noinc((SV *)newHV()));
    PERL_UNUSED_ARG(opname);
    return spec;
}

/* Every operation of every named mount, appended to the tool table. Runs in
 * the innermost middleware, once the mounts have compiled. */
static void pmcp_oa_derive(pTHX_ SV *app, pmcp_server *ps)
{
    SV *names = pmcp_hget(aTHX_ ps->opts, "openapi");
    SV *allow = pmcp_hget(aTHX_ ps->opts, "ops");
    SV *mounts = pmcp_hget(aTHX_ (HV *)SvRV(app), "api_mounts");
    AV *wanted = (AV *)SvRV(names);
    HV *used = (HV *)sv_2mortal((SV *)newHV());
    HV *allowed = NULL, *seen_ops = (HV *)sv_2mortal((SV *)newHV());
    pmcp_tools *ts = (pmcp_tools *)ps->srv.tools;
    AV *ms = pmcp_is_array(mounts) ? (AV *)SvRV(mounts) : NULL;
    SSize_t wi, mi, nm = ms ? av_len(ms) + 1 : 0;
    IV i, added = 0;

    if (!ts) {
        Newxz(ts, 1, pmcp_tools);
        Newxz(ts->t, 1, pmcp_tool);
        {
            SV *v = pmcp_hget(aTHX_ ps->opts, "page_size");
            ts->page_size = v ? SvIV(v) : 50;
        }
        ps->srv.tools = ts;
    }
    for (i = 0; i < ts->n; i++) (void)hv_store_ent(used, ts->t[i].name, newSViv(2), 0);
    if (allow) {
        SSize_t k, n = av_len((AV *)SvRV(allow)) + 1;
        allowed = (HV *)sv_2mortal((SV *)newHV());
        for (k = 0; k < n; k++)
            (void)hv_store_ent(allowed, *av_fetch((AV *)SvRV(allow), k, 0), newSViv(0), 0);
    }

    for (wi = 0; wi <= av_len(wanted); wi++) {
        SV *want = *av_fetch(wanted, wi, 0);
        int matched = 0;
        for (mi = 0; mi < nm; mi++) {
            SV *mount = *av_fetch(ms, mi, 0);
            SV *api, *opsv, *prefix;
            SSize_t oi, no;
            if (!pmcp_oa_names(aTHX_ want, mount)) continue;
            matched = 1;
            api = sv_2mortal(pmcp_call_method(aTHX_ mount, "api", NULL, 0, G_SCALAR, NULL));
            prefix = sv_2mortal(pmcp_call_method(aTHX_ mount, "prefix", NULL, 0, G_SCALAR, NULL));
            opsv = sv_2mortal(pmcp_call_method(aTHX_ api, "operations", NULL, 0, G_SCALAR, NULL));
            if (!pmcp_is_array(opsv)) continue;
            no = av_len((AV *)SvRV(opsv)) + 1;
            for (oi = 0; oi < no; oi++) {
                HV *op = (HV *)SvRV(*av_fetch((AV *)SvRV(opsv), oi, 0));
                SV *op_id = pmcp_hget(aTHX_ op, "operationId");
                HV *spec, *x = NULL;
                SV *name, *xname = NULL, *full;
                pmcp_tool *t;
                int ver;
                if (!op_id || hv_exists_ent(seen_ops, op_id, 0)) continue;
                if (allowed) {
                    HE *ae = hv_fetch_ent(allowed, op_id, 0, 0);
                    if (!ae) continue;
                    sv_setiv(HeVAL(ae), 1);
                }
                spec = pmcp_oa_spec(aTHX_ api, op, op_id);
                if (!spec) continue;
                (void)hv_store_ent(seen_ops, op_id, newSViv(1), 0);
                {   /* x-mcp's name, checked as a DSL name is */
                    SV *raw = sv_2mortal(pmcp_call_method(aTHX_ api, "spec", NULL, 0, G_SCALAR, NULL));
                    SV *paths = pmcp_hget(aTHX_ (HV *)SvRV(raw), "paths");
                    SV *item = pmcp_hget(aTHX_ (HV *)SvRV(paths), SvPV_nolen(pmcp_hget(aTHX_ op, "path")));
                    SV *rop = item ? pmcp_hget(aTHX_ (HV *)SvRV(item), SvPV_nolen(pmcp_hget(aTHX_ op, "method"))) : NULL;
                    SV *xv = (rop && pmcp_is_hash(rop)) ? pmcp_hget(aTHX_ (HV *)SvRV(rop), "x-mcp") : NULL;
                    if (xv && pmcp_is_hash(xv)) x = (HV *)SvRV(xv);
                    xname = x ? pmcp_hget(aTHX_ x, "name") : NULL;
                }
                if (xname) {
                    STRLEN xl;
                    const char *xp = SvPV_const(xname, xl);
                    if (!pmcp_tool_name_ok(xp, xl))
                        croak("%s: x-mcp name '%" SVf "' on operation '%" SVf "' is not 1 to 128 "
                              "of A-Z a-z 0-9 _ . -", PMCP_WHO, SVfARG(xname), SVfARG(op_id));
                    if (hv_exists_ent(used, xname, 0))
                        croak("%s: x-mcp name '%" SVf "' on operation '%" SVf "' is already a "
                              "tool", PMCP_WHO, SVfARG(xname), SVfARG(op_id));
                    (void)hv_store_ent(used, xname, newSViv(1), 0);
                    name = xname;
                }
                else {
                    /* the name before any _N: a DSL tool by that name is a
                     * clash to fix, not one to number round */
                    HV *probe = (HV *)sv_2mortal((SV *)newHV());
                    SV *base = pmcp_oa_name(aTHX_ op_id, probe);
                    HE *he = hv_fetch_ent(used, base, 0, 0);
                    if (he && SvIV(HeVAL(he)) == 2)
                        croak("%s: operation '%" SVf "' becomes the tool '%" SVf "', which the "
                              "mcp keyword already declares. Rename one, or give the operation "
                              "x-mcp: { name: ... }", PMCP_WHO, SVfARG(op_id), SVfARG(base));
                    name = pmcp_oa_name(aTHX_ op_id, used);
                }

                Renew(ts->t, ts->n + 1, pmcp_tool);
                t = &ts->t[ts->n++];
                Zero(t, 1, pmcp_tool);
                t->name = newSVsv(name);
                t->input = pmcp_compile_schema(aTHX_ name, pmcp_hget(aTHX_ spec, "input"), "input");
                t->timeout = 0;
                t->oa_method = newSVsv(pmcp_hget(aTHX_ op, "method"));
                {
                    char *u = SvPV_force_nolen(t->oa_method);
                    STRLEN k;
                    for (k = 0; u[k]; k++) u[k] = toUPPER(u[k]);
                }
                full = newSVsv(prefix && SvOK(prefix) ? prefix : &PL_sv_no);
                sv_catsv(full, pmcp_hget(aTHX_ op, "path"));
                t->oa_path = full;
                t->oa_where = pmcp_oa_where(aTHX_ api, op_id);
                {
                    SV *annotations = pmcp_tool_annotations(aTHX_ name,
                                        pmcp_hget(aTHX_ spec, "annotations"));
                    if (annotations) sv_2mortal(annotations);
                    for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++)
                        t->entry[ver] = pmcp_tool_entry(aTHX_ name, spec, annotations,
                                                        (enum pmcp_ver)ver);
                }
                added++;
            }
        }
        if (!matched)
            croak("%s: openapi '%" SVf "' names no api mount (a mount object, '*', its "
                  "spec or its prefix)", PMCP_WHO, SVfARG(want));
    }
    if (allowed) {
        HE *he;
        hv_iterinit(allowed);
        while ((he = hv_iternext(allowed)))
            if (!SvIV(HeVAL(he)))
                croak("%s: ops names '%" SVf "', which no named mount has", PMCP_WHO,
                      SVfARG(hv_iterkeysv(he)));
    }

    if (ts->n > 1) qsort(ts->t, (size_t)ts->n, sizeof(pmcp_tool), pmcp_tool_cmp);
    {
        int ver;
        for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++) {
            if (ts->list[ver]) Safefree(ts->list[ver]);
            Newxz(ts->list[ver], ts->n > 0 ? ts->n : 1, SV *);
            for (i = 0; i < ts->n; i++) ts->list[ver][i] = ts->t[i].entry[ver];
        }
    }
    PERL_UNUSED_VAR(added);
}

/* ---- the innermost middleware ----------------------------------------------------------- */

/* Added last at on_compile, so it wraps the raw app: it keeps that app for the
 * calls, derives the tools, and returns the app unchanged. cap = [app, server] */
XS_INTERNAL(pmcp_capture_cb)
{
    dXSARGS;
    SV *app = pmcp_cap(aTHX_ cv, 0);
    pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_cap(aTHX_ cv, 1));
    SV *inner = items > 0 ? ST(0) : &PL_sv_undef;
    if (ps) {
        if (ps->srv.psgi) SvREFCNT_dec(ps->srv.psgi);
        ps->srv.psgi = newSVsv(inner);
        pmcp_oa_derive(aTHX_ app, ps);
        if (pmcp_hget(aTHX_ ps->opts, "oauth"))
            warn("%s: openapi tools carry the caller's token to the mount, whose own "
                 "checker decides: it must accept tokens issued for this MCP endpoint\n",
                 PMCP_WHO);
    }
    ST(0) = inner;
    XSRETURN(1);
}

/* ---- the call ------------------------------------------------------------------------------ */

/* Run an OpenAPI tool: the synthetic env, the inner app, the answer. Returns
 * the value the app answered with (mortal), or NULL with *why (+1). */
static SV *pmcp_oa_call(pTHX_ SV *psgi, pmcp_tool *t, SV *c, HV *args, SV **why)
{
    SV *envsv = sv_2mortal(pmcp_call_method(aTHX_ c, "env", NULL, 0, G_SCALAR, NULL));
    HV *env = (HV *)SvRV(envsv), *nenv = newHV();
    SV *path = newSVpvs(""), *query = newSVpvs(""), *body = NULL, *nrv, *res, *err = NULL;
    STRLEN tl, i;
    const char *tp = SvPV_const(t->oa_path, tl);
    int nq = 0;

    *why = NULL;
    for (i = 0; i < tl; i++) {
        if (tp[i] == '{') {
            STRLEN j = i + 1;
            while (j < tl && tp[j] != '}') j++;
            if (j < tl) {
                SV **a = hv_fetch(args, tp + i + 1, (I32)(j - i - 1), 0);
                if (a && *a) pmcp_pct_cat(aTHX_ path, *a);
                i = j;
                continue;
            }
        }
        sv_catpvn(path, tp + i, 1);
    }
    {
        HE *he;
        hv_iterinit(args);
        while ((he = hv_iternext(args))) {
            SV *k = hv_iterkeysv(he), *v = HeVAL(he);
            HE *we;
            HV *w;
            const char *in;
            SV *nm;
            if (strEQ(SvPV_nolen(k), "body")) { body = v; continue; }
            we = hv_fetch_ent(t->oa_where, k, 0, 0);
            if (!we || !pmcp_is_hash(HeVAL(we))) continue;
            w = (HV *)SvRV(HeVAL(we));
            in = SvPV_nolen(pmcp_hget(aTHX_ w, "in"));
            nm = pmcp_hget(aTHX_ w, "name");
            if (strEQ(in, "query")) {
                if (pmcp_is_array(v)) {
                    SSize_t x, n = av_len((AV *)SvRV(v)) + 1;
                    for (x = 0; x < n; x++) {
                        SV **el = av_fetch((AV *)SvRV(v), x, 0);
                        if (nq++) sv_catpvs(query, "&");
                        pmcp_pct_cat(aTHX_ query, nm);
                        sv_catpvs(query, "=");
                        if (el) pmcp_pct_cat(aTHX_ query, *el);
                    }
                }
                else {
                    if (nq++) sv_catpvs(query, "&");
                    pmcp_pct_cat(aTHX_ query, nm);
                    sv_catpvs(query, "=");
                    pmcp_pct_cat(aTHX_ query, v);
                }
            }
            else if (strEQ(in, "header")) {
                SV *hk = newSVpvs("HTTP_");
                STRLEN x, nl;
                const char *np = SvPV_const(nm, nl);
                for (x = 0; x < nl; x++) {
                    char ch = np[x];
                    ch = ch == '-' ? '_' : toUPPER(ch);
                    sv_catpvn(hk, &ch, 1);
                }
                (void)hv_store_ent(nenv, hk, SvROK(v) ? newSVpv(SvTRUE(SvRV(v)) ? "true" : "false", 0)
                                                      : newSVsv(v), 0);
                SvREFCNT_dec(hk);
            }
        }
    }
    {
        static const char *const carry[] = {
            "HTTP_HOST", "HTTP_AUTHORIZATION", "REMOTE_ADDR", "REMOTE_PORT",
            "SERVER_NAME", "SERVER_PORT", "SERVER_PROTOCOL", "psgi.url_scheme",
            "psgi.errors", "psgi.version", "psgi.multithread", "psgi.multiprocess",
            "psgi.run_once", "psgi.nonblocking", "psgix.logger", NULL
        };
        int k;
        for (k = 0; carry[k]; k++) {
            SV **s = hv_fetch(env, carry[k], (I32)strlen(carry[k]), 0);
            if (s && *s) (void)hv_store(nenv, carry[k], (I32)strlen(carry[k]), newSVsv(*s), 0);
        }
    }
    (void)hv_stores(nenv, "REQUEST_METHOD", newSVsv(t->oa_method));
    (void)hv_stores(nenv, "PATH_INFO", path);
    (void)hv_stores(nenv, "QUERY_STRING", query);
    (void)hv_stores(nenv, "SCRIPT_NAME", newSVpvs(""));
    (void)hv_stores(nenv, "pmcp.inner", newSViv(1));
    (void)hv_stores(nenv, "pmcp.tool", newSVsv(t->name));
    if (body) {
        SV *bytes = pmcp_json_trapped(aTHX_ body, &err);
        if (!bytes) {
            SvREFCNT_dec((SV *)nenv);
            *why = newSVpvs("the body argument is not JSON");
            SvREFCNT_dec(err);
            return NULL;
        }
        sv_2mortal(bytes);
        (void)hv_stores(nenv, "CONTENT_TYPE", newSVpvs("application/json"));
        (void)hv_stores(nenv, "CONTENT_LENGTH", newSViv((IV)SvCUR(bytes)));
        (void)hv_stores(nenv, "psgi.input", pmcp_input_handle(aTHX_ bytes));
    }
    else {
        (void)hv_stores(nenv, "CONTENT_LENGTH", newSViv(0));
        (void)hv_stores(nenv, "psgi.input", pmcp_input_handle(aTHX_ sv_2mortal(newSVpvs(""))));
    }
    nrv = sv_2mortal(newRV_noinc((SV *)nenv));
    res = pmcp_call_sv(aTHX_ psgi, &nrv, 1, G_SCALAR, &err);
    if (!res) {
        *why = pmcp_die_text(aTHX_ err);
        SvREFCNT_dec(err);
        return NULL;
    }
    sv_2mortal(res);
    return pmcp_settle(aTHX_ c, res, t->timeout, why);
}

#endif /* PMCP_OA_H */
