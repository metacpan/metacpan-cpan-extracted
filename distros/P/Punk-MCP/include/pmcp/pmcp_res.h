/* pmcp_res.h - resources: declarations, the two lists, and resources/read.
 *
 * Needs: pmcp_uri.h, pmcp_call.h.
 *
 * A declared URI with a {var} is a template and is listed by
 * resources/templates/list. Without one it is a resource and is listed by
 * resources/list. A read tries the exact URIs first, then the templates in
 * declaration order, and the template's variables reach the action as params.
 *
 * A resource has no isError. A read that fails is a JSON-RPC error: -32002
 * when there is nothing at the URI (or the caller may not see it), -32603 when
 * the action failed.
 */

#ifndef PMCP_RES_H
#define PMCP_RES_H

#define PMCP_NOT_FOUND (-32002)

typedef struct {
    SV       *uri;                   /* the URI or the template, owned */
    pmcp_tpl *tpl;                   /* NULL for an exact URI */
    SV       *target;
    AV       *guards;
    NV        timeout;
    SV       *mime;                  /* or NULL */
    SV       *entry[PMCP_V_LATEST + 1];
} pmcp_resource;

typedef struct {
    pmcp_resource *r;                /* exact URIs sorted, then templates */
    IV  n, n_exact;
    IV  page_size;
    int any_guard;
    SV **list[PMCP_V_LATEST + 1];    /* exact entries, borrowed */
    SV **tlist[PMCP_V_LATEST + 1];   /* template entries, borrowed */
} pmcp_resources;

static const char *const PMCP_RES_KEYS[] = {
    "name", "title", "description", "mime", "size", "annotations", "guard",
    "icons", "timeout", NULL
};

static void pmcp_res_croak(pTHX_ SV *uri, const char *what)
{
    croak("%s: mcp resource '%" SVf "' %s", PMCP_WHO, SVfARG(uri), what);
}

/* audience, priority, lastModified. +1 HV ref, or NULL. */
static SV *pmcp_res_annotations(pTHX_ SV *uri, SV *a)
{
    static const char *const keys[] = { "audience", "priority", "lastModified", NULL };
    HV *in, *out;
    SV *v;
    if (!a) return NULL;
    if (!pmcp_is_hash(a)) pmcp_res_croak(aTHX_ uri, "annotations must be a hash");
    in = (HV *)SvRV(a);
    pmcp_check_keys(aTHX_ "resource annotation", in, keys);
    out = (HV *)sv_2mortal((SV *)newHV());
    if ((v = pmcp_hget(aTHX_ in, "audience"))) {
        AV *src, *dst;
        SSize_t i, n;
        if (!pmcp_is_array(v))
            pmcp_res_croak(aTHX_ uri, "annotation audience must be a list of user and assistant");
        src = (AV *)SvRV(v);
        dst = newAV();
        (void)hv_stores(out, "audience", newRV_noinc((SV *)dst));
        n = av_len(src) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            const char *s = (e && pmcp_is_text(*e)) ? SvPV_nolen(*e) : "";
            if (!(strEQ(s, "user") || strEQ(s, "assistant")))
                pmcp_res_croak(aTHX_ uri, "annotation audience must be a list of user and assistant");
            av_push(dst, newSVpv(s, 0));
        }
    }
    if ((v = pmcp_hget(aTHX_ in, "priority"))) {
        if (SvROK(v) || !looks_like_number(v) || SvNV(v) < 0 || SvNV(v) > 1)
            pmcp_res_croak(aTHX_ uri, "annotation priority must be a number from 0 to 1");
        (void)hv_stores(out, "priority", newSVnv(SvNV(v)));
    }
    if ((v = pmcp_hget(aTHX_ in, "lastModified"))) {
        STRLEN l;
        const char *p = pmcp_is_text(v) ? SvPV_const(v, l) : NULL;
        /* an ISO 8601 date-time: the date and a T are enough to tell */
        if (!p || l < 11 || p[4] != '-' || p[7] != '-' || p[10] != 'T')
            pmcp_res_croak(aTHX_ uri, "annotation lastModified must be an ISO 8601 date-time");
        (void)hv_stores(out, "lastModified", newSVsv(v));
    }
    return newRV_inc((SV *)out);
}

static SV *pmcp_res_entry(pTHX_ pmcp_resource *r, HV *spec, SV *annotations,
                          enum pmcp_ver v)
{
    HV *e = newHV();
    SV *x, *bytes, *err = NULL;
    (void)hv_store(e, r->tpl ? "uriTemplate" : "uri", r->tpl ? 11 : 3,
                   newSVsv(r->uri), 0);
    x = pmcp_hget(aTHX_ spec, "name");
    (void)hv_stores(e, "name", x ? pmcp_str(aTHX_ x) : newSVsv(r->uri));
    if ((x = pmcp_hget(aTHX_ spec, "description")))
        (void)hv_stores(e, "description", pmcp_str(aTHX_ x));
    if (r->mime) (void)hv_stores(e, "mimeType", newSVsv(r->mime));
    if (annotations) (void)hv_stores(e, "annotations", newSVsv(annotations));
    if (!r->tpl && (x = pmcp_hget(aTHX_ spec, "size")))
        (void)hv_stores(e, "size", newSViv(SvIV(x)));
    if (v >= PMCP_V_2025_06_18 && (x = pmcp_hget(aTHX_ spec, "title")))
        (void)hv_stores(e, "title", pmcp_str(aTHX_ x));
    if (v >= PMCP_V_2025_11_25 && (x = pmcp_hget(aTHX_ spec, "icons")))
        (void)hv_stores(e, "icons", newSVsv(x));
    bytes = pmcp_json_trapped(aTHX_ sv_2mortal(newRV_noinc((SV *)e)), &err);
    if (!bytes) {
        sv_2mortal(err);
        croak("%s: mcp resource '%" SVf "' cannot be listed: %" SVf, PMCP_WHO,
              SVfARG(r->uri), SVfARG(err));
    }
    return bytes;
}

static void pmcp_resources_free(pTHX_ pmcp_resources *rs)
{
    IV i;
    int v;
    if (!rs) return;
    for (i = 0; i < rs->n; i++) {
        pmcp_resource *r = &rs->r[i];
        if (r->uri) SvREFCNT_dec(r->uri);
        if (r->tpl) pmcp_tpl_free(r->tpl);
        if (r->target) SvREFCNT_dec(r->target);
        if (r->guards) SvREFCNT_dec((SV *)r->guards);
        if (r->mime) SvREFCNT_dec(r->mime);
        for (v = 0; v <= PMCP_V_LATEST; v++) if (r->entry[v]) SvREFCNT_dec(r->entry[v]);
    }
    for (v = 0; v <= PMCP_V_LATEST; v++) {
        if (rs->list[v]) Safefree(rs->list[v]);
        if (rs->tlist[v]) Safefree(rs->tlist[v]);
    }
    Safefree(rs->r);
    Safefree(rs);
}

static int pmcp_res_cmp(const void *a, const void *b)
{
    dTHX;
    return sv_cmp(((const pmcp_resource *)a)->uri, ((const pmcp_resource *)b)->uri);
}

static pmcp_resources *pmcp_resources_freeze(pTHX_ SV *app, AV *decls, HV *opts)
{
    pmcp_resources *rs;
    SSize_t i, n = av_len(decls) + 1;
    IV k, nt = 0;
    pmcp_resource *tmp;
    SV *v;
    NV dflt_timeout = (v = pmcp_hget(aTHX_ opts, "timeout")) ? SvNV(v) : 0;
    int pass;

    Newxz(rs, 1, pmcp_resources);
    Newxz(rs->r, n > 0 ? n : 1, pmcp_resource);
    Newxz(tmp, n > 0 ? n : 1, pmcp_resource);
    rs->page_size = (v = pmcp_hget(aTHX_ opts, "page_size")) ? SvIV(v) : 50;

    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        SV *uri = *av_fetch(d, PMCP_D_KEY, 0);
        HV *spec = (HV *)SvRV(*av_fetch(d, PMCP_D_SPEC, 0));
        pmcp_resource *r;
        SV *annotations;
        STRLEN ul;
        const char *up;
        int ver;

        if (!strEQ(SvPV_nolen(*av_fetch(d, PMCP_D_KIND, 0)), "resource")) continue;
        {
            SV *what = sv_2mortal(newSVpvf("mcp resource '%" SVf "' key", SVfARG(uri)));
            pmcp_check_keys(aTHX_ SvPV_nolen(what), spec, PMCP_RES_KEYS);
        }
        up = SvPV_const(uri, ul);
        if (!memchr(up, ':', ul))
            pmcp_res_croak(aTHX_ uri, "is not a URI: it has no scheme");
        {
            static const char *const text[] = { "name", "title", "description", "mime", NULL };
            int ti;
            for (ti = 0; text[ti]; ti++)
                if ((v = pmcp_hget(aTHX_ spec, text[ti])) && !pmcp_is_text(v)) {
                    SV *m = sv_2mortal(newSVpvf("%s must be a string", text[ti]));
                    pmcp_res_croak(aTHX_ uri, SvPV_nolen(m));
                }
        }
        if ((v = pmcp_hget(aTHX_ spec, "size"))
            && (SvROK(v) || !looks_like_number(v) || SvNV(v) < 0 || SvNV(v) != (NV)SvIV(v)))
            pmcp_res_croak(aTHX_ uri, "size must be a whole number of bytes");
        if ((v = pmcp_hget(aTHX_ spec, "icons"))) pmcp_check_icons(aTHX_ v);
        if ((v = pmcp_hget(aTHX_ spec, "timeout"))
            && (SvROK(v) || !looks_like_number(v) || !(SvNV(v) > 0)))
            pmcp_res_croak(aTHX_ uri, "timeout must be a number of seconds above 0");

        r = &tmp[nt++];
        r->uri = newSVsv(uri);
        if (pmcp_is_template(up, ul)) {
            r->tpl = pmcp_tpl_parse(aTHX_ uri);
            if (pmcp_hget(aTHX_ spec, "size"))
                pmcp_res_croak(aTHX_ uri, "is a template, and a template has no size");
        }
        r->target = newSVsv(*av_fetch(d, PMCP_D_TARGET, 0));
        r->guards = pmcp_resolve_guards(aTHX_ app, "resource", uri,
                        hv_exists(spec, "guard", 5) ? *hv_fetchs(spec, "guard", 0) : NULL);
        if (r->guards) rs->any_guard = 1;
        r->timeout = (v = pmcp_hget(aTHX_ spec, "timeout")) ? SvNV(v) : dflt_timeout;
        if ((v = pmcp_hget(aTHX_ spec, "mime"))) r->mime = newSVsv(v);
        annotations = pmcp_res_annotations(aTHX_ uri, pmcp_hget(aTHX_ spec, "annotations"));
        if (annotations) sv_2mortal(annotations);
        for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++)
            r->entry[ver] = pmcp_res_entry(aTHX_ r, spec, annotations, (enum pmcp_ver)ver);
    }

    /* exact URIs first, sorted for the list and the search; then templates in
     * declaration order, which is the order a read tries them */
    for (pass = 0; pass < 2; pass++)
        for (k = 0; k < nt; k++)
            if ((pass == 0) == (tmp[k].tpl == NULL)) rs->r[rs->n++] = tmp[k];
    Safefree(tmp);
    for (k = 0; k < rs->n; k++) if (!rs->r[k].tpl) rs->n_exact++;
    if (rs->n_exact > 1)
        qsort(rs->r, (size_t)rs->n_exact, sizeof(pmcp_resource), pmcp_res_cmp);

    /* two templates one URI could match is a read whose answer depends on
     * declaration order, which nobody reading the code would guess */
    {
        IV a, b;
        for (a = rs->n_exact; a < rs->n; a++)
            for (b = a + 1; b < rs->n; b++)
                if (pmcp_tpl_overlap(rs->r[a].tpl, rs->r[b].tpl))
                    croak("%s: mcp resource '%" SVf "' and '%" SVf "' can match "
                          "the same URI", PMCP_WHO, SVfARG(rs->r[a].uri),
                          SVfARG(rs->r[b].uri));
    }

    {
        int ver;
        for (ver = PMCP_V_2025_03_26; ver <= PMCP_V_LATEST; ver++) {
            Newxz(rs->list[ver], rs->n_exact > 0 ? rs->n_exact : 1, SV *);
            Newxz(rs->tlist[ver], rs->n - rs->n_exact > 0 ? rs->n - rs->n_exact : 1, SV *);
            for (k = 0; k < rs->n; k++) {
                if (k < rs->n_exact) rs->list[ver][k] = rs->r[k].entry[ver];
                else rs->tlist[ver][k - rs->n_exact] = rs->r[k].entry[ver];
            }
        }
    }
    return rs;
}

/* ---- the lists ---------------------------------------------------------------- */

typedef struct { pmcp_resources *rs; IV offset; SV *c; } pmcp_res_list_ctx;

static int pmcp_res_visible(pTHX_ void *vctx, IV i)
{
    pmcp_res_list_ctx *x = (pmcp_res_list_ctx *)vctx;
    pmcp_resource *r = &x->rs->r[x->offset + i];
    SV *why;
    if (!r->guards) return 1;
    if (!x->c) return 0;
    why = pmcp_run_guards(aTHX_ r->guards, x->c);
    if (!why) return 1;
    SvREFCNT_dec(why);
    return 0;
}

static SV *pmcp_res_list_common(pTHX_ const pmcp_srv *s, pmcp_req *r,
                                HV *params, int templates)
{
    pmcp_resources *rs = (pmcp_resources *)s->resources;
    enum pmcp_ver v = r->version ? r->version : PMCP_V_2025_03_26;
    SV **cur = params ? hv_fetchs(params, "cursor", 0) : NULL;
    IV count, start = 0;
    pmcp_res_list_ctx x;

    if (!rs) return pmcp_fail(r, PMCP_METHOD, "method not found");
    count = templates ? rs->n - rs->n_exact : rs->n_exact;
    if (cur && SvOK(*cur)) {
        start = pmcp_cursor_read(aTHX_ *cur, count);
        if (start < 0) return pmcp_fail(r, PMCP_PARAMS, "invalid cursor");
    }
    x.rs = rs;
    x.offset = templates ? rs->n_exact : 0;
    x.c = r->c;
    r->raw = pmcp_page_bytes(aTHX_ templates ? "resourceTemplates" : "resources",
                             templates ? rs->tlist[v] : rs->list[v], count, start,
                             rs->page_size, rs->any_guard ? pmcp_res_visible : NULL, &x);
    return NULL;
}

static SV *pmcp_resources_list(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    return pmcp_res_list_common(aTHX_ s, r, params, 0);
}

static SV *pmcp_resources_templates(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    return pmcp_res_list_common(aTHX_ s, r, params, 1);
}

/* ---- resources/read --------------------------------------------------------------- */

/* Is this media type text? Any text/ type, and the structured text types. */
static int pmcp_mime_textual(pTHX_ SV *mime)
{
    STRLEN l;
    const char *p;
    if (!mime) return -1;                      /* undeclared: look at the bytes */
    p = SvPV_nolen(mime);
    l = strlen(p);
    if (l >= 5 && memEQ(p, "text/", 5)) return 1;
    return instr(p, "json") || instr(p, "xml") || instr(p, "yaml")
        || instr(p, "javascript") || instr(p, "ecmascript");
}

/* One contents entry for a string. +1 HV ref. */
static SV *pmcp_res_content(pTHX_ SV *uri, SV *mime, SV *val)
{
    HV *e = newHV();
    int textual = pmcp_mime_textual(aTHX_ mime);
    STRLEN l;
    const char *p;
    (void)hv_stores(e, "uri", newSVsv(uri));
    if (mime) (void)hv_stores(e, "mimeType", newSVsv(mime));
    if (SvUTF8(val)) {
        if (textual != 0) { (void)hv_stores(e, "text", newSVsv(val)); goto done; }
        p = SvPVutf8(val, l);
    }
    else p = SvPV(val, l);
    if (textual == 1 || (textual == -1 && is_utf8_string((U8 *)p, l))) {
        /* bytes that are UTF-8 go out as the characters they spell */
        SV *t = newSVpvn(p, l);
        if (is_utf8_string((U8 *)p, l)) SvUTF8_on(t);
        (void)hv_stores(e, "text", t);
    }
    else (void)hv_stores(e, "blob", pmcp_b64(aTHX_ (const unsigned char *)p, l));
done:
    return newRV_noinc((SV *)e);
}

/* The exact resource, or the first template that matches (with *caps +1). */
static pmcp_resource *pmcp_res_find(pTHX_ pmcp_resources *rs, SV *uri, HV **caps)
{
    IV lo = 0, hi = rs->n_exact, k;
    *caps = NULL;
    while (lo < hi) {
        IV mid = lo + (hi - lo) / 2;
        int c = sv_cmp(uri, rs->r[mid].uri);
        if (c == 0) return &rs->r[mid];
        if (c < 0) hi = mid; else lo = mid + 1;
    }
    for (k = rs->n_exact; k < rs->n; k++)
        if ((*caps = pmcp_tpl_match(aTHX_ rs->r[k].tpl, uri))) return &rs->r[k];
    return NULL;
}

static SV *pmcp_res_not_found(pTHX_ pmcp_req *r, SV *uri)
{
    r->edata = newRV_noinc((SV *)newHV());
    (void)hv_stores((HV *)SvRV(r->edata), "uri", newSVsv(uri));
    return pmcp_fail(r, PMCP_NOT_FOUND, "Resource not found");
}

static SV *pmcp_res_failed(pTHX_ pmcp_req *r, SV *why, IV status)
{
    r->edata = newRV_noinc((SV *)newHV());
    if (why) (void)hv_stores((HV *)SvRV(r->edata), "reason", why);
    if (status) (void)hv_stores((HV *)SvRV(r->edata), "status", newSViv(status));
    return pmcp_fail(r, PMCP_INTERNAL, "the resource could not be read");
}

static SV *pmcp_resources_read(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    pmcp_resources *rs = (pmcp_resources *)s->resources;
    enum pmcp_ver v = r->version ? r->version : PMCP_V_2025_03_26;
    SV **uv = params ? hv_fetchs(params, "uri", 0) : NULL;
    SV *uri, *args, *call, *child, *why = NULL, *val, *mime, *out, *err = NULL;
    HV *caps;
    pmcp_resource *res;
    AV *contents;

    if (!rs) return pmcp_fail(r, PMCP_METHOD, "method not found");
    if (!(uv && pmcp_is_str(*uv))) return pmcp_fail(r, PMCP_PARAMS, "a uri is required");
    uri = *uv;
    res = pmcp_res_find(aTHX_ rs, uri, &caps);
    if (!res) return pmcp_res_not_found(aTHX_ r, uri);
    if (!r->c) return pmcp_fail(r, PMCP_INTERNAL, "no request to read the resource in");

    args = sv_2mortal(newRV_noinc((SV *)(caps ? caps : newHV())));
    call = sv_2mortal(pmcp_call_object(aTHX_ "resources/read", uri, args, v, params));
    pmcp_call_attach(aTHX_ r, call);
    child = sv_2mortal(pmcp_child_context(aTHX_ r->c, "resource", uri, args, call));

    /* a resource the caller may not see is one that is not there */
    if ((why = pmcp_run_guards(aTHX_ res->guards, child))) {
        SvREFCNT_dec(why);
        return pmcp_res_not_found(aTHX_ r, uri);
    }

    val = pmcp_run_action(aTHX_ res->target, child, res->timeout, &why);
    if (!val) return pmcp_res_failed(aTHX_ r, why, 0);
    mime = res->mime;

    if (!SvOK(val)) return pmcp_res_not_found(aTHX_ r, uri);
    if (pmcp_is_hash(val) && hv_exists((HV *)SvRV(val), "contents", 8)) {
        out = newSVsv(val);
        goto answer;
    }
    contents = newAV();
    out = newRV_noinc((SV *)newHV());
    (void)hv_stores((HV *)SvRV(out), "contents", newRV_noinc((SV *)contents));
    if (pmcp_is_triplet(aTHX_ val)) {
        AV *tr = (AV *)SvRV(val);
        IV status = SvIV(*av_fetch(tr, 0, 0));
        int is_json;
        SV *body = pmcp_triplet_body(aTHX_ tr, &is_json);
        SvREFCNT_dec(out);
        if (status == 404) return pmcp_res_not_found(aTHX_ r, uri);
        if (status >= 400) return pmcp_res_failed(aTHX_ r, NULL, status);
        if (!body) return pmcp_res_failed(aTHX_ r, newSVpvs("a streamed body"), status);
        if (!mime && is_json) mime = sv_2mortal(newSVpvs("application/json"));
        contents = newAV();
        out = newRV_noinc((SV *)newHV());
        (void)hv_stores((HV *)SvRV(out), "contents", newRV_noinc((SV *)contents));
        av_push(contents, pmcp_res_content(aTHX_ uri, mime, body));
    }
    else if (!SvROK(val) || SvAMAGIC(val)) {
        av_push(contents, pmcp_res_content(aTHX_ uri, mime, val));
    }
    else if (pmcp_is_hash(val) || pmcp_is_array(val)) {
        SV *json = pmcp_json_trapped(aTHX_ val, &err);
        if (!json) {
            SvREFCNT_dec(out);
            SvREFCNT_dec(err);
            return pmcp_fail(r, PMCP_INTERNAL, "the resource is not JSON");
        }
        sv_2mortal(json);
        av_push(contents, pmcp_res_content(aTHX_ uri,
            mime ? mime : sv_2mortal(newSVpvs("application/json")), json));
    }
    else {
        SvREFCNT_dec(out);
        return pmcp_res_failed(aTHX_ r,
            newSVpvf("the action returned a %s reference", sv_reftype(SvRV(val), 0)), 0);
    }

answer:
    {
        SV *bytes = pmcp_json_trapped(aTHX_ out, &err);
        SvREFCNT_dec(out);
        if (!bytes) {
            SvREFCNT_dec(err);
            return pmcp_fail(r, PMCP_INTERNAL, "the resource is not JSON");
        }
        r->raw = bytes;
    }
    return NULL;
}

#endif /* PMCP_RES_H */
