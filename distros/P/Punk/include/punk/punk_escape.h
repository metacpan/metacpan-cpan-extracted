#ifndef PUNK_ESCAPE_H
#define PUNK_ESCAPE_H

/* Escape text for HTML: an element's content or an attribute's value, quoted
 * either way. Appends to `out`, copying runs that need nothing in one go.
 *
 * The five characters are the whole job: & < > " ' are the only ones that can
 * end a text node, an attribute value or a tag. Bytes are copied as they are,
 * so UTF-8 passes through untouched (no byte of a multi-byte character is
 * ASCII). The csrf field, the static listing and the markdown mount all write
 * markup with this; $c->escape_html is the same function for Perl. XML is a
 * different escape (the sitemap's &apos;) and has its own. */
static void punk_html_escape(pTHX_ SV *out, const char *s, STRLEN len) {
    STRLEN i, run = 0;
    for (i = 0; i < len; i++) {
        const char *rep;
        switch (s[i]) {
            case '&':  rep = "&amp;";  break;
            case '<':  rep = "&lt;";   break;
            case '>':  rep = "&gt;";   break;
            case '"':  rep = "&quot;"; break;
            case '\'': rep = "&#39;";  break;
            default:   run++;          continue;
        }
        if (run) { sv_catpvn(out, s + i - run, run); run = 0; }
        sv_catpv(out, rep);
    }
    if (run) sv_catpvn(out, s + len - run, run);
}

#endif
