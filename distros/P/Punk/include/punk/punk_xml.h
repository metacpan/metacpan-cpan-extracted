#ifndef PUNK_XML_H
#define PUNK_XML_H

/* The XML body path: a request body parsed into a File::Raw::XML::Document,
 * and a Document or Node handed back as a response.
 *
 * Punk maps nothing between XML and Perl data. JSON's model is Perl's, so
 * `return { ok => 1 }` has one obvious encoding; XML's is not, and every
 * convention for elements-versus-attributes, ordering, mixed content and
 * repeated elements is wrong for somebody's schema. What is here is the two
 * ends only: bytes in to a tree, a tree out to bytes. The application walks
 * it or XPaths it.
 *
 * All of it runs over frx_abi.h's SV bridge (version 2), so a document
 * crosses between C and Perl without a method call: `parse` and `doc_to_sv`
 * on the way in, `doc_from_sv`/`node_from_sv` and `write` on the way out.
 *
 * Needs punk_frx() from Punk.xs. */

/* One spelling, used by $c->xml, Punk::Response::finalize and punk_coerce.
 * The charset is explicit because a Node is written without an XML
 * declaration, so a fragment would otherwise leave its encoding to RFC 7303's
 * default; it also matches the text/html and text/plain defaults beside it.
 * Negotiation is unaffected - pa_match compares type and subtype only. */
#define PK_XML_CT "application/xml; charset=utf-8"

/* Could this SV be one of File::Raw::XML's objects at all?
 *
 * punk_frx() requires File::Raw::XML on its first call, and an application
 * that never touches XML must not pay that just because it returned a hash
 * reference. Until the module is loaded there is nothing that could have
 * blessed a Document or a Node, so a missing stash is a definitive no and
 * this stays a null pointer compare for every JSON response ever sent. */
static int punk_xml_possible(pTHX_ SV *sv) {
    if (!SvROK(sv) || !SvOBJECT(SvRV(sv))) return 0;
    return gv_stashpvs("File::Raw::XML::Document", 0) != NULL;
}

/* The apex to serialise and the document it belongs to, or NULL when this is
 * not a Document or a Node. The two _from_sv entries answer NULL rather than
 * croaking for anything that is not theirs, which is what makes them usable
 * as the type test.
 *
 * A Document's apex is its document node, not its root element: that is what
 * carries the top-level comments and processing instructions, and what the
 * writer needs to emit the declaration and the DOCTYPE. */
static const frx_node *punk_xml_apex(pTHX_ SV *sv, frx_doc **dp, int *is_doc) {
    const frx_abi *A;
    frx_doc *d;
    const frx_node *n;

    *dp = NULL;
    *is_doc = 0;
    if (!punk_xml_possible(aTHX_ sv)) return NULL;

    A = punk_frx(aTHX);
    if ((d = A->doc_from_sv(aTHX_ sv)) != NULL) {
        *dp = d;
        *is_doc = 1;
        return A->document(d);
    }
    if ((n = A->node_from_sv(aTHX_ sv, dp)) != NULL && *dp) return n;
    *dp = NULL;
    return NULL;
}

/* Is this a Document or a Node? The question punk_coerce and finalize ask of
 * every reference before handing it to the JSON encoder. */
static int punk_xml_is(pTHX_ SV *sv) {
    frx_doc *d;
    int is_doc;
    return punk_xml_apex(aTHX_ sv, &d, &is_doc) != NULL;
}

/* The markup of a Document or Node as bytes (+1, no character flag - which
 * is what a response body wants), or NULL with a mortal message in *errp.
 *
 * `write` reports a refusal by returning NULL and filling an frx_err; it does
 * not croak. That matters more than it looks: punk_coerce runs from loop
 * callbacks with no G_EVAL around them, so an exception raised here would
 * leave Punk entirely rather than becoming a 500. */
static SV *punk_xml_bytes(pTHX_ SV *sv, SV **errp) {
    const frx_abi *A;
    frx_doc *d = NULL;
    const frx_node *apex;
    frx_write_opts o;
    frx_err err;
    SV *out;
    int is_doc = 0;

    if (errp) *errp = NULL;
    apex = punk_xml_apex(aTHX_ sv, &d, &is_doc);
    if (!apex || !d) {
        if (errp) *errp = sv_2mortal(newSVpvs(
            "Punk: xml: not a File::Raw::XML::Document or ::Node"));
        return NULL;
    }

    A = punk_frx(aTHX);
    A->write_opts_init(&o);
    /* a fragment carries neither, matching what ->to_string does for a node */
    if (!is_doc) { o.declaration = 0; o.doctype = 0; }

    memset(&err, 0, sizeof err);
    /* (A->write), with the member parenthesised: on a PERL_IMPLICIT_SYS perl
     * - Strawberry - iperlsys.h makes `write` a function-like macro, and
     * A->write(...) does not compile. frx_abi.h says so where it declares it. */
    out = (A->write)(aTHX_ apex, d, &o, &err);
    if (!out && errp)
        *errp = sv_2mortal(newSVpvf("Punk: xml: %s",
                    err.what ? err.what : "the document could not be written"));
    return out;
}

/* Bytes to a blessed File::Raw::XML::Document (+1), croaking with the
 * parser's own message on a refusal - which is what $c->req->json does for
 * malformed JSON, and the two bodies should not answer differently.
 *
 * `parse` is the strict entry and frx_abi.h guarantees it can never mean
 * anything else: no document type declaration is accepted wherever it
 * stands, which removes external entities, parameter entities, the external
 * DTD fetch, XXE and the billion laughs as a class rather than as a setting.
 * There is no options argument here and there must never be one - a profile
 * or a resolver reachable from a request is exactly the switch that would
 * give all of that back. */
static SV *punk_xml_parse(pTHX_ SV *bytes) {
    const frx_abi *A = punk_frx(aTHX);
    SV *err = NULL;                  /* mortal, owned by parse; never freed here */
    STRLEN len;
    const char *p = SvPV_const(bytes, len);
    frx_doc *d = A->parse(aTHX_ p, len, NULL, &err);
    if (!d) {
        if (err) croak_sv(err);
        croak("Punk: xml: the request body is not well-formed XML");
    }
    return A->doc_to_sv(aTHX_ d);    /* takes the document; magic frees it */
}

#endif /* PUNK_XML_H */
