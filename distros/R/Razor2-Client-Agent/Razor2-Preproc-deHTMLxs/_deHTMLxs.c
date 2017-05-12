/*
 * $Id: _deHTMLxs.c,v 1.5 2006/02/16 19:16:00 rsoderberg Exp $
 */

#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "deHTMLxs.h"


/* Read-only structure, so it's thread-safe */
typedef struct {
    char *name;
    char chr;
} CM_PREPROC_html_tags_t;

CM_PREPROC_html_tags_t CM_PREPROC_html_tags[] = {
    { "lt"    , '<'       },  { "gt"    , '>'       },  { "amp"   , '&'       },
    { "quot"  , '"'       },  { "nbsp"  , ' '       },  { "iexcl" , (char)161 },
    { "cent"  , (char)162 },  { "pound" , (char)163 },  { "curren", (char)164 },
    { "yen"   , (char)165 },  { "brvbar", (char)166 },  { "sect"  , (char)167 },
    { "uml"   , (char)168 },  { "copy"  , (char)169 },  { "ordf"  , (char)170 },
    { "laquo" , (char)171 },  { "not"   , (char)172 },  { "shy"   , (char)173 },
    { "reg"   , (char)174 },  { "macr"  , (char)175 },  { "deg"   , (char)176 },
    { "plusmn", (char)177 },  { "sup2"  , (char)178 },  { "sup3"  , (char)179 },
    { "acute" , (char)180 },  { "micro" , (char)181 },  { "para"  , (char)182 },
    { "middot", (char)183 },  { "cedil" , (char)184 },  { "sup1"  , (char)185 },
    { "ordm"  , (char)186 },  { "raquo" , (char)187 },  { "frac14", (char)188 },
    { "frac12", (char)189 },  { "frac34", (char)190 },  { "iquest", (char)191 },
    { "Agrave", (char)192 },  { "Aacute", (char)193 },  { "Acirc" , (char)194 },
    { "Atilde", (char)195 },  { "Auml"  , (char)196 },  { "Aring" , (char)197 },
    { "AElig" , (char)198 },  { "Ccedil", (char)199 },  { "Egrave", (char)200 },
    { "Eacute", (char)201 },  { "Ecirc" , (char)202 },  { "Euml"  , (char)203 },
    { "Igrave", (char)204 },  { "Iacute", (char)205 },  { "Icirc" , (char)206 },
    { "Iuml"  , (char)207 },  { "ETH"   , (char)208 },  { "Ntilde", (char)209 },
    { "Ograve", (char)210 },  { "Oacute", (char)211 },  { "Ocirc" , (char)212 },
    { "Otilde", (char)213 },  { "Ouml"  , (char)214 },  { "times" , (char)215 },
    { "Oslash", (char)216 },  { "Ugrave", (char)217 },  { "Uacute", (char)218 },
    { "Ucirc" , (char)219 },  { "Uuml"  , (char)220 },  { "Yacute", (char)221 },
    { "THORN" , (char)222 },  { "szlig" , (char)223 },  { "agrave", (char)224 },
    { "aacute", (char)225 },  { "acirc" , (char)226 },  { "atilde", (char)227 },
    { "auml"  , (char)228 },  { "aring" , (char)229 },  { "aelig" , (char)230 },
    { "ccedil", (char)231 },  { "egrave", (char)232 },  { "eacute", (char)233 },
    { "ecirc" , (char)234 },  { "euml"  , (char)235 },  { "igrave", (char)236 },
    { "iacute", (char)237 },  { "icirc" , (char)238 },  { "iuml"  , (char)239 },
    { "eth"   , (char)240 },  { "ntilde", (char)241 },  { "ograve", (char)242 },
    { "oacute", (char)243 },  { "ocirc" , (char)244 },  { "otilde", (char)245 },
    { "ouml"  , (char)246 },  { "divide", (char)247 },  { "oslash", (char)248 },
    { "ugrave", (char)249 },  { "uacute", (char)250 },  { "ucirc" , (char)251 },
    { "uuml"  , (char)252 },  { "yacute", (char)253 },  { "thorn" , (char)254 },
    { "yuml"  , (char)255 },  { 0, (char)0 }
};


const char *CM_PREPROC_parse_html_tag_tolower(const char *body, char *tagname, unsigned int tagnamelen) {
    unsigned int cch = 0;

    if (*body != '<')
        return NULL;

    body++;

    if ((*body == '!') || (*body == '/'))
        body++;

    while (isspace((unsigned char) *body))
        body++;

    while (isalpha((unsigned char) *body)) {
        if(--tagnamelen == 0)
            break;

        *tagname++ = tolower(*body++);
        cch++;
    }

    *tagname = '\0';

    if (cch == 0)
        return NULL;

    while ((*body != '\0') && (*body != '>'))
        body++;

    if (*body != '>')
        return NULL;

    /* Return pointer to the ending '>' */
    return body;
}

int CM_PREPROC_is_html(const char *body) {
    char tagname[100] = {0};

    const char *ppHtmlSubsetLowerCase[] = {
        "html", "body", "a", "font", "table", "head", "base", "meta", "td", "tr", "style", "img", "object", "br",
        "b", "i", "span", "div", "form", "input", "button", "frame", "iframe", "tbody", "col", "th", "hr",
        "xml", "script", "pre", "param", "applet", "center", "area", "map", "em", "embed", "xmp", "sub", "sup",
        NULL
    };

    if ((body == NULL) || (*body == '\0'))
        return 0;

    /* Loop through all '<' chars and try to parse a recognizable HTML tag */
    for (body = strchr(body, '<'); body != NULL; body = strchr(body + 1, '<')) {
        /* Attempt tp parse the tag */
        const char *pTagEnd = CM_PREPROC_parse_html_tag_tolower(body, tagname, sizeof(tagname));
        const char **ppCurTag;

        if (pTagEnd == NULL)
            continue;

        /* Check our tag array for its existence (everything is lower case) */
        for(ppCurTag = ppHtmlSubsetLowerCase; *ppCurTag != NULL; ppCurTag++) {
            const char *pCurTag = *ppCurTag;
            if((*pCurTag == *tagname) && (strcmp(tagname, pCurTag) == 0))
                return 1;
        }

        body = pTagEnd;
    }

    return 0;
}

static char CM_PREPROC_html_tagxlat(char **ref) {
    char c = 0, *s = *ref;

    unsigned int len = (unsigned int) strlen(s);
    unsigned int offset = ( len > 10 ? 10 : len );

    CM_PREPROC_html_tags_t *tags;
    unsigned int tlen;

    if (!isalpha(*s))
        return '&';

    for (tags = (CM_PREPROC_html_tags_t*)&CM_PREPROC_html_tags; tags->name && !c; tags++) {
        tlen = (unsigned int) strlen(tags->name);

        if (tlen > offset)
            continue;

        if (!strncmp(s, tags->name, tlen)) {
            c = tags->chr;
            s += tlen;
        }
    }

    if (!c)
        c = '&';
    else if (*s == ';')
        s++;

    *ref = s;

    return c;
}


char *CM_PREPROC_html_strip(char *s, char *text) {
    int sgml = 0, tag = 0;
    char c, last = '\0', quote = '\0', *t;

    if ((t = text) == NULL)
        return NULL;

    if (!s || !*s)
        return NULL;

    memset(text, 0, strlen(s)+1);

    while ((c = *s++)) {
        if (c == quote) {

            if (c == '-' && last != '-')
                goto next;
            else
                last = '\0';

            quote = '\0';

        } else if (!quote) {

            switch (c) {

                case '<':
                    tag = 1;
                    if (*s == '!') {
                        sgml = 1;
                        s++;
                    } else if (*s)
                        s++;

                    break;

                case '>':
                    if (tag)
                        sgml = tag = 0;
                    break;

                case '-':
                    if (sgml && last == '-')
                        quote = '-';
                    else
                        goto valid;
                    break;

                case '"':
                case '\'':
                    if (tag)
                        quote = c;
                    else
                        goto valid;
                    break;

                case '&':
                    *t++ = CM_PREPROC_html_tagxlat(&s);
                    break;

                default:
                valid:
                    if (!tag)
                        *t++ = c;
                    break;
            }

        }

        next:
        last = c;
    }

    return text;

}
