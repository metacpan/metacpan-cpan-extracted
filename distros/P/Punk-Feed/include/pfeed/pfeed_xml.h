#ifndef PFEED_XML_H
#define PFEED_XML_H

/* Getting application text into a document without breaking it.
 *
 * Two different jobs, and the order between them is the whole point:
 * percent-encoding turns a path into a URL, XML escaping turns any string into
 * character data. A URL is encoded first and escaped second.
 *
 * WHY THE ORDER. A path holding a space is not a URL at all, so escaping alone
 * would produce a well-formed document containing an invalid URL - which
 * readers accept and then cannot follow. Encoding first also means everything
 * reaching the escaper is ASCII, so a slug that is not valid UTF-8 cannot make
 * the document unparseable; the encoder turned it into %XX long before.
 *
 * WHY THERE IS NO CDATA. The tempting shape for an entry's HTML content is
 * <![CDATA[ ... ]]>, and it is wrong: application content containing ']]>'
 * breaks straight out of it, and that sequence turns up on its own in code
 * samples. Everything is escaped instead, which is why Atom content goes out
 * as type="html" carrying escaped markup - a form every reader handles and
 * none can be confused by.
 *
 * Needs nothing but perl.
 */

/* UTF-8 bytes for any input SV, which is the one thing a document declaring
 * encoding="UTF-8" may contain.
 *
 * Perl gives three shapes for the same text and this has to flatten all three:
 *
 *   - a character string with a codepoint above 255 is UTF-8 flagged, and
 *     SvPV already hands back UTF-8 bytes;
 *   - a character string whose codepoints are all below 256 is stored
 *     UNFLAGGED, one byte each - so "Caf\x{e9}" is the single byte E9, and
 *     emitting it raw puts invalid UTF-8 in the document;
 *   - a byte string that is already UTF-8 with the flag off, which is what
 *     File::Raw::JSON and Template::Stencil hand back all over this family.
 *
 * The last two are both "unflagged with a high byte" and cannot be told apart
 * by their flags, so they are told apart by their contents: a byte sequence
 * that is valid UTF-8 is taken as UTF-8, and anything else as latin-1 and
 * upgraded. Valid UTF-8 is not something latin-1 prose falls into by accident.
 *
 * WHAT is_utf8_string ACCEPTS, and why that is still the right question here.
 * It accepts perl's UTF-8, which is a superset of Unicode's: the surrogates
 * and codepoints above U+10FFFF encode without complaint. Those are exactly
 * the ones XML forbids, so this test is not and cannot be the guard against
 * them - pfeed_xml_cat is, on the decoded codepoint, below.
 *
 * Tightening this to a strict test instead would be the wrong repair. The
 * question being asked here is only "are these bytes UTF-8 or latin-1", and a
 * strict test answers "latin-1" for a byte string that really does hold an
 * encoded surrogate - so a document would carry three bytes of mojibake where
 * dropping one unusable character was wanted. Judging encoding here and
 * judging what XML can carry at emit time keeps each answer where its
 * question is.
 *
 * Punk itself does not transcode - it hands the SV to the server as it came -
 * and being stricter here is deliberate. An HTML page with one bad byte
 * renders with one bad character; a feed with one bad byte is not well-formed
 * XML, and a reader rejects ALL of it. Same reasoning as escaping the
 * ampersand.
 *
 * The returned pointer is valid until the next FREETMPS.
 */
static const char *pfeed_u8(pTHX_ SV *in, STRLEN *lp)
{
    STRLEN l;
    const char *p;

    if (!(in && SvOK(in))) { *lp = 0; return ""; }
    p = SvPV_const(in, l);
    if (SvUTF8(in) || is_utf8_string((const U8 *)p, l)) { *lp = l; return p; }
    {
        SV *tmp = sv_2mortal(newSVpvn(p, l));
        sv_utf8_upgrade(tmp);
        p = SvPV_const(tmp, l);
        *lp = l;
        return p;
    }
}

/* One UTF-8 sequence to a codepoint, for deciding whether XML can carry it.
 *
 * PERL'S UTF-8 and not Unicode's, deliberately. The SV reaching here may hold
 * a surrogate or a codepoint above U+10FFFF, because perl permits both in a
 * string and SvPV hands back their encoded bytes. Decoding has to ACCEPT those
 * forms in order to recognise them, since they are precisely the ones XML
 * cannot carry: a decoder that refused them would report "malformed" and a
 * decoder that never ran would emit them.
 *
 * Sequence length comes from the start byte alone, counting its leading ones,
 * with perl's FF form as the one special case. Nothing above four bytes has
 * its value accumulated: every such codepoint is already past U+10FFFF, so the
 * value is not needed, and skipping the arithmetic is also how this avoids
 * overflowing a UV on the thirteen-byte form.
 *
 * *len is the bytes to step over and is ALWAYS at least one, so no caller can
 * fail to make progress. *ok is 0 for a malformed sequence, whose bytes the
 * caller drops: pfeed_u8 above has already made the input UTF-8, so this is
 * the belt to that braces, and emitting a byte we could not read is the one
 * outcome worse than dropping it. */
#define PFEED_CP_TOO_BIG ((UV)0x110000)   /* a value that is never XML Char */

static UV pfeed_cp(const char *s, STRLEN avail, STRLEN *len, int *ok)
{
    const U8 *p = (const U8 *)s;
    U8 c = p[0];
    int n, i;
    UV uv;

    *ok = 1;
    if (c < 0x80) { *len = 1; return (UV)c; }

    /* `big` rather than a sentinel value in uv: a flag cannot be reached by
     * accumulation, and reasoning about whether it could is not worth the
     * line it would save. */
    {
        int big = 0;
        if      (c >= 0xC0 && c <= 0xDF) { n = 2;  uv = (UV)(c & 0x1F); }
        else if (c >= 0xE0 && c <= 0xEF) { n = 3;  uv = (UV)(c & 0x0F); }
        else if (c >= 0xF0 && c <= 0xF7) { n = 4;  uv = (UV)(c & 0x07); }
        else if (c >= 0xF8 && c <= 0xFB) { n = 5;  big = 1; uv = 0; }
        else if (c >= 0xFC && c <= 0xFD) { n = 6;  big = 1; uv = 0; }
        else if (c == 0xFE)              { n = 7;  big = 1; uv = 0; }
        else if (c == 0xFF)              { n = 13; big = 1; uv = 0; }
        else { *len = 1; *ok = 0; return 0; }  /* a continuation byte, alone */

        if ((STRLEN)n > avail) { *len = avail ? avail : 1; *ok = 0; return 0; }
        for (i = 1; i < n; i++) {
            if ((p[i] & 0xC0) != 0x80) { *len = (STRLEN)i; *ok = 0; return 0; }
            if (!big) uv = (uv << 6) | (UV)(p[i] & 0x3F);
        }
        *len = (STRLEN)n;
        return big ? PFEED_CP_TOO_BIG : uv;
    }
}

/* XML 1.0 section 2.2, the Char production, and nothing looser:
 *
 *   Char ::= #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD]
 *                                            | [#x10000-#x10FFFF]
 *
 * So: the C0 controls other than tab, newline and carriage return; the
 * surrogates; U+FFFE and U+FFFF; and everything above U+10FFFF. Note what is
 * NOT excluded - U+007F is a legal Char, and so are the noncharacters outside
 * the BMP. This implements the production rather than a notion of "unsafe
 * text", because the production is what a parser applies. */
static int pfeed_xml_char(UV c)
{
    if (c == 0x09 || c == 0x0A || c == 0x0D) return 1;
    if (c <  0x20)    return 0;
    if (c <= 0xD7FF)  return 1;
    if (c <  0xE000)  return 0;        /* surrogates */
    if (c <= 0xFFFD)  return 1;        /* and so U+FFFE, U+FFFF are out */
    if (c <  0x10000) return 0;
    return c <= 0x10FFFF;
}

/* XML escaping, over every emitted value without exception.
 *
 * One unescaped '&' makes the document not well-formed, and a reader rejects
 * ALL of it rather than the offending entry - so this is a correctness problem
 * before it is a security one. A feed carries prose and titles, where an
 * ampersand is ordinary rather than exotic.
 *
 * Both quote characters are escaped, which is what makes one function safe in
 * an attribute as well as in text and removes the chance of picking the wrong
 * one at a call site.
 *
 * AND WHAT XML CANNOT CARRY IS DROPPED, which is the other half of the same
 * job and was missing until 0.04. Escaping five characters is only enough if
 * every other byte is one a document may hold, and it is not: a feed carries
 * text its operator never wrote - comments, submitted posts, forum threads,
 * uploaded file names - and one C0 control or one surrogate anywhere in any
 * entry makes the whole document fatally ill-formed. Every subscriber then
 * loses every item, not the one entry, and the bytes are cached and re-served
 * for the whole ttl.
 *
 * DROPPED and not escaped, because escaping is not available: &#1; and
 * &#xD800; are as forbidden as the raw character. A character reference may
 * only name a character the Char production already allows, so there is
 * nothing to turn these into. XML 1.1 would take some of them; a feed is 1.0.
 *
 * CODEPOINT-WISE and not byte-wise, because a byte-wise C0 filter closes only
 * the nearer of the two routes in. The other is that the bytes may legitimately
 * encode a surrogate or something past U+10FFFF, which no byte in the sequence
 * looks wrong on its own. */
static void pfeed_xml_cat(pTHX_ SV *out, const char *s, STRLEN l)
{
    STRLEN i = 0, start = 0;

    while (i < l) {
        unsigned char c = (unsigned char)s[i];
        const char *rep = NULL;
        STRLEN n = 1;

        /* Every path below either `continue`s - keeping these bytes in the
         * run being accumulated - or falls through to the flush, where `rep`
         * says whether an entity replaces the n bytes or nothing does. */
        if (c < 0x80) {
            switch (c) {
                case '&':  rep = "&amp;";  break;
                case '<':  rep = "&lt;";   break;
                case '>':  rep = "&gt;";   break;
                case '"':  rep = "&quot;"; break;
                case '\'': rep = "&apos;"; break;
                default:
                    /* ASCII needs no decoding to be judged: tab, newline and
                     * carriage return are Char, the rest of C0 is not, and
                     * everything from 0x20 up is. */
                    if (c >= 0x20 || c == 0x09 || c == 0x0A || c == 0x0D) {
                        i++;
                        continue;
                    }
                    break;                     /* a C0 control: dropped */
            }
        }
        else {
            int ok;
            UV uv = pfeed_cp(s + i, l - i, &n, &ok);
            if (ok && pfeed_xml_char(uv)) { i += n; continue; }
        }

        if (i > start) sv_catpvn(out, s + start, i - start);
        if (rep) sv_catpv(out, rep);
        i += n;
        start = i;
    }
    if (l > start) sv_catpvn(out, s + start, l - start);
}

/* The same for an SV, which is what every call site actually holds. */
static void pfeed_xml_sv(pTHX_ SV *out, SV *in)
{
    STRLEN l;
    const char *p;
    if (!(in && SvOK(in))) return;
    p = pfeed_u8(aTHX_ in, &l);
    pfeed_xml_cat(aTHX_ out, p, l);
}

/* Percent-encoding.
 *
 * In a PATH, unreserved plus '/' is kept and everything else encoded.
 * Over-encoding a sub-delimiter there is legal and costs three bytes, and the
 * server decodes it back to the same path; under-encoding one is a different
 * URL.
 *
 * In a QUERY the same rule would be wrong, and quietly. Encoding '?' and '='
 * folds the query into the path, so `/article?id=5` becomes a request for a
 * file literally named "article?id=5" - a 404 for every subscriber, from a
 * link that looks right in the document. So a query keeps RFC 3986's query
 * production: pchar plus '/' and '?', where pchar is unreserved, the
 * sub-delims "!$&'()*+,;=", ':' and '@'. '#' is kept too, so a fragment
 * survives rather than being swallowed into the query.
 *
 * The '&' a query keeps is then escaped to &amp; by pfeed_xml_cat, which is
 * exactly right: &amp; in XML *is* the character '&'. That is the whole reason
 * these are two passes in this order rather than one.
 *
 * The character classes are spelled out rather than asked of isALNUM, which
 * counts '_' as alphanumeric and has changed spelling across perls. A URL
 * encoder is not the place to inherit either. */
static void pfeed_pct_run(pTHX_ SV *out, const char *s, STRLEN l, int query)
{
    static const char hex[] = "0123456789ABCDEF";
    STRLEN i;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)s[i];
        int keep = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
                || (c >= '0' && c <= '9')
                || c == '-' || c == '.' || c == '_' || c == '~' || c == '/';
        if (!keep && query) {
            switch (c) {
                case '?': case '#': case ':': case '@':
                case '!': case '$': case '&': case '\'':
                case '(': case ')': case '*': case '+':
                case ',': case ';': case '=':
                    keep = 1; break;
                default: break;
            }
        }
        if (keep) sv_catpvn(out, (const char *)&c, 1);
        else {
            char e[3];
            e[0] = '%'; e[1] = hex[c >> 4]; e[2] = hex[c & 0xF];
            sv_catpvn(out, e, 3);
        }
    }
}

/* Path rules, which is what a bare path wants. */
static void pfeed_pct_cat(pTHX_ SV *out, const char *s, STRLEN l)
{
    pfeed_pct_run(aTHX_ out, s, l, 0);
}

/* base + path, encoded then escaped, onto `out`.
 *
 * The path is split at the first '?' so each half is encoded under its own
 * rules. Everything after it - query and fragment alike - is query.
 *
 * The base is not encoded: it is configuration, it has already been checked to
 * be an absolute http or https URL, and percent-encoding it would turn the
 * "://" into something no reader would follow. */
static void pfeed_url_cat(pTHX_ SV *out, SV *base, const char *p, STRLEN pl)
{
    SV *url = sv_2mortal(newSVpvs(""));
    const char *q = (const char *)memchr(p, '?', pl);
    /* appended as bytes rather than with sv_catsv, which would upgrade `url`
     * to character semantics and make the %XX that follow ambiguous */
    if (base && SvOK(base)) {
        STRLEN bl;
        const char *bp = pfeed_u8(aTHX_ base, &bl);
        sv_catpvn(url, bp, bl);
    }
    if (q) {
        STRLEN plen = (STRLEN)(q - p);
        pfeed_pct_run(aTHX_ url, p, plen, 0);
        sv_catpvs(url, "?");
        pfeed_pct_run(aTHX_ url, q + 1, pl - plen - 1, 1);
    }
    else pfeed_pct_run(aTHX_ url, p, pl, 0);
    {
        STRLEN ul;
        const char *up = SvPV_const(url, ul);
        pfeed_xml_cat(aTHX_ out, up, ul);
    }
}

/* The same from an SV path. */
static void pfeed_url_sv(pTHX_ SV *out, SV *base, SV *path)
{
    STRLEN l;
    const char *p;
    if (!(path && SvOK(path))) return;
    /* UTF-8 first, then percent-encoded: /caf<e9> has to reach a reader as
     * %C3%A9 and not %E9, or the link 404s */
    p = pfeed_u8(aTHX_ path, &l);
    pfeed_url_cat(aTHX_ out, base, p, l);
}

#endif /* PFEED_XML_H */
