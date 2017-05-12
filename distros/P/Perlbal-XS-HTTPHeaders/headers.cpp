/******************************************************************************
 * Perlbal XS HTTPHeaders class                                               *
 * Written by Mark Smith (junior@sixapart.com)                                *
 *                                                                            *
 * This program is free software; you can redistribute it and/or modify it    *
 * under the same terms as Perl itself.                                       *
 *                                                                            *
 * Copyright 2004 Danga Interactive, Inc.                                     *
 * Copyright 2005 Six Apart, Ltd.                                             *
 ******************************************************************************/

#include "headers.h"

#include "stdio.h"
#include "stdlib.h"
#include "string.h"

using namespace std;

/******************************************************************************
 * HELPER FUNCTIONS ***********************************************************
 ******************************************************************************/
int skip_spaces(char **ptr) {
    // should be safe, as string terminates with \0, so we won't hit that
    // as long as we're looking to match spaces only
    int i = 0;
    while (**ptr == ' ') {
        i++;
        (*ptr)++;
    }
    return i;
}

int skip_to_space(char **ptr) {
    // safe as we stop incrementing if we hit a \n or a \0
    int i = 0;
    while (**ptr != ' ' && **ptr != '\0') {
        // only increase length if this isn't an \r... we only want to count real stuff
        i++;
        (*ptr)++;
    }
    return i;
}

// FIXME: the following two functions can be optimized so as not to do the \r check in
// the main loop; just look for \r in the while and increment *ptr by two if we have an
// \r\n after the while loop... I'm too lazy to do it now
int skip_to_eol(char **ptr) {
    // safe as we stop incrementing if we hit a \n or a \0
    int i = 0;
    while (**ptr != '\n' && **ptr != '\0') {
        // only increase length if this isn't an \r... we only want to count real stuff
        if (**ptr != '\r')
            i++;
        (*ptr)++;
    }
    if (**ptr == '\n')
        (*ptr)++;
    return i;
}

int skip_to_colon(char **ptr) {
    // safe as we stop incrementing if we hit a colon, \n, or \0
    int i = 0;
    while (**ptr != ':') {
        if (**ptr == '\r' || **ptr == '\n' || **ptr == '\0')
            return 0; // invalid line? make them bomb
        i++;
        (*ptr)++;
    }
    if (**ptr == ':')
        (*ptr)++;
    return i;
}

int parseVersionNumber(char *ptr, char **newptr) {
    int i = 0, j = 0;

    // find width of first number
    while (isdigit(ptr[i])) i++;
    if (i == 0 || i > 4 || ptr[i] != '.') return 0;

    // find width of second number
    while (isdigit(ptr[i+j+1])) j++;
    if (j == 0 || j > 4) return 0;

    // update newptr with data
    *newptr = (ptr + i + j + 1);

    // now extract into ret
    int ret = atoi(ptr) * 1000 + atoi(ptr+i+1);
    return ret;
}


/******************************************************************************
 * HTTPHEADERS CLASS **********************************************************
 ******************************************************************************/

HTTPHeaders::HTTPHeaders() {
    /* initialize our internal data */
    versionNumber = 0;
    statusCode = 0;
    headersType = 0;
    method = 0;
    sv_uri = NULL;
    sv_firstLine = NULL;
    sv_methodString = NULL;
    hdrs = NULL;
    hdrtail = NULL;
}

HTTPHeaders::~HTTPHeaders() {
    if (sv_uri) {
        SvREFCNT_dec(sv_uri);
    }
    if (sv_firstLine) {
        SvREFCNT_dec(sv_firstLine);
    }
    if (sv_methodString) {
        SvREFCNT_dec(sv_methodString);
    }

    /* free header structs we're using */
    Header *next = NULL;
    while (hdrs) {
        next = hdrs->next;
        freeHeader(hdrs);
        hdrs = next;
    }
}

void HTTPHeaders::freeHeader(Header *hdr) {
    // now free this header
    Safefree(hdr->key);
    SvREFCNT_dec(hdr->sv_value);
    Safefree(hdr);
}


int HTTPHeaders::parseHeaders(SV *headers) {
    // make sure headers is a reference
    if (!SvROK(headers))
        return 0;
    
    // setup variables we're going to use
    int state = 0; // 0 = parsing first line, 1 = parsing headers
    int len = 0;
    char *initial = SvPV_nolen(SvRV(headers)); // point to the beginning of headers
    char *pptr, *ptr = initial;
    Header *lasthdr = NULL;

    // loop while we haven't hit the end
    while (*ptr != '\0') {
        // state 0 is when we haven't gotten anything and we're reading in
        // the first line for processing
        if (state == 0) {
            if (!strncmp(ptr, "HTTP/", 5)) {
                headersType = H_RESPONSE;
                // FIXME: this probably isn't safe if the headers are really short
                // because we're just randomly referencing into headers
                versionNumber = parseVersionNumber(ptr + 5, &ptr);
                if (versionNumber <= 0)
                    return 0;

                // now we want to get the code, which should be next after some spaces
                skip_spaces(&ptr);

                // get the code
                statusCode = strtol(ptr, &ptr, 10);

                // now skip to the end of line
                skip_to_eol(&ptr);

                // now copy our first line.  we do this weird thing with \r and \n in order
                // to remove any trailing \r\ns from our first line.
                len = ptr - initial;
                while (initial[len - 1] == '\r' || initial[len - 1] == '\n')
                    len--;
                sv_firstLine = newSVpvn(initial, len);
                if (!sv_firstLine)
                    return 0;

                // now continue on to doing actual header parsing
                state = 1;
                continue;
            }

            // must be a request
            headersType = H_REQUEST;
            if (!strncmp(ptr, "GET ", 4)) {
                ptr += 4;
                method = M_GET;
            } else if (!strncmp(ptr, "POST ", 5)) {
                ptr += 5;
                method = M_POST;
            } else if (!strncmp(ptr, "HEAD ", 5)) {
                ptr += 5;
                method = M_HEAD;
            } else if (!strncmp(ptr, "OPTIONS ", 8)) {
                ptr += 8;
                method = M_OPTIONS;
            } else if (!strncmp(ptr, "PUT ", 4)) {
                ptr += 4;
                method = M_PUT;
            } else if (!strncmp(ptr, "DELETE ", 7)) {
                ptr += 7;
                method = M_DELETE;
            } else {
                pptr = ptr;
                len = skip_to_space(&ptr);
                if (len) {
                    sv_methodString = newSVpvn(pptr, len);
                    if (!sv_methodString)
                        return 0;
                } else {
                    // nothing, error
                    return 0;
                }

                skip_spaces(&ptr);
            }

            // now we need to read in the URI
            pptr = ptr;
            len = skip_to_space(&ptr);
            if (len) {
                // now get the URI
                sv_uri = newSVpvn(pptr, len);
                if (!sv_uri)
                    return 0;
            }

            // now we need to determine the version
            skip_spaces(&ptr);
            if (!strncmp(ptr, "HTTP/", 5)) {
                // FIXME: this probably isn't safe if the headers are really short
                // because we're just randomly referencing into headers
                versionNumber = parseVersionNumber(ptr + 5, &ptr);
                if (versionNumber <= 0)
                    return 0;
                skip_to_eol(&ptr);

                // now copy our first line.  we do this weird thing with \r and \n in order
                // to remove any trailing \r\ns from our first line.
                len = ptr - initial;
                while (initial[len - 1] == '\r' || initial[len - 1] == '\n')
                    len--;
                sv_firstLine = newSVpvn(initial, len);
                if (!sv_firstLine)
                    return 0;
            } else {
                return 0;
            }

            // cool, start parsing the headers now
            state = 1;
        } else if (state == 1) {
            // if it starts with space or tab then go ahead and append to previous header
            if (*ptr == ' ' || *ptr == '\t') {
                // we have to have lasthdr, or something drastically bad happened
                if (!lasthdr)
                    return 0;

                // get the whole line, the whole thing is just being appended
                pptr = ptr;
                len = skip_to_eol(&ptr);

                // len should never be 0 in this case, but in case it is...
                if (!len)
                    return 0;

                // append this data to the end
                sv_catpv(lasthdr->sv_value, "\r\n");
                sv_catpvn(lasthdr->sv_value, pptr, len);
                continue;
            }

            // normal case; we're going to get something.  first see if we're up against a blank line
            // or the end of string marker, and if so, we're done (but successfully!)
            if (*ptr == '\r' || *ptr == '\n' || *ptr == '\0')
                return 1;

            // now let's find a colon if we can
            pptr = ptr;
            len = skip_to_colon(&ptr);

            // if skip_to_colon returns 0, it hit the end with no colon, so this isn't a valid request
            if (!len)
                return 0;

            // jump 'ptr' to the beginning of this line's data
            skip_spaces(&ptr);

            // now see if we have another copy of this header already
            Header *hdr = findHeader(pptr, len);
            if (hdr) {
                // basically, responses can have Set-Cookie headers... if we're in a response
                // and handling a Set-Cookie header, we just want to append it to our header
                // list like normal.  in requests, or in non-Set-Cookie headers, we want to
                // append to our previous header
                if (isRequest() || strncasecmp(hdr->key, "Set-Cookie", len)) {
                    // find out how long this line is
                    pptr = ptr;
                    len = skip_to_eol(&ptr);
                    
                    // simply append ", " and our data
                    sv_catpvn(hdr->sv_value, ", ", 2);
                    sv_catpvn(hdr->sv_value, pptr, len);
                    continue;
                }
            }

            // now create a new header to store this line's data
            New(0, hdr, 1, Header);
            if (!hdr)
                return 0;
            Poison(hdr, 1, Header);

            // set it up
            hdr->keylen = len;
            hdr->prev = NULL;
            hdr->next = NULL;
            hdr->key = NULL;
            hdr->sv_value = NULL;
            hdrtail = hdr;

            // copy in the header name... note we don't have to insert a null
            // at the end of hdr->key because we use Newz which zeros the allocated space
            Newz(0, hdr->key, len + 1, char);
            if (!hdr->key)
                return 0;
            Copy(pptr, hdr->key, len, char);

            // and jump to the end of the line, fail if we got nothing
            pptr = ptr;
            len = skip_to_eol(&ptr);

            // copy this as our value
            hdr->sv_value = newSVpvn(pptr, len);
            if (!hdr->sv_value)
                return 0;

            // now insert this into our list
            if (lasthdr) {
                hdr->prev = lasthdr;
                lasthdr->next = hdr;
                lasthdr = hdr;
            } else {
                hdrs = hdr;
                lasthdr = hdr;
            }

        }
    }

    // if we get here we're done, so return state
    return state;
}

SV *HTTPHeaders::getReconstructed() {
    // reconstitute the header we got... pretty much just firstLine + all the headers
    SV *res = newSVpvn("", 0);
    if (!res) return &PL_sv_undef;
    SvGROW(res, 768);

    // print in the first line
    if (!sv_firstLine) {
        SvREFCNT_dec(res);
        return &PL_sv_undef;
    }
    sv_catsv(res, sv_firstLine);
    sv_catpv(res, "\r\n");

    // now over each header
    for (Header *cur = hdrs; cur; cur = cur->next) {
        if (!cur->key) {
            SvREFCNT_dec(res);
            return &PL_sv_undef;
        }
        sv_catpv(res, cur->key);
        sv_catpv(res, ": ");

        if (!cur->sv_value) {
            SvREFCNT_dec(res);
            return &PL_sv_undef;
        }
        sv_catsv(res, cur->sv_value);
        sv_catpv(res, "\r\n");
    }

    // tack on final \r\n
    sv_catpv(res, "\r\n");

    // return our scalar
    return res;
}

Header *HTTPHeaders::findHeader(char *which, int len) {
    // make sure we got something
    if (!which) return NULL;
    int wlen = len ? len : strlen(which);
    if (!wlen) return NULL;

    // now iterate and find the header
    for (Header *cur = hdrs; cur; cur = cur->next) {
        // very fast shortcut; check lengths which will rule out most of the
        // headers that we have in our list, as most don't share a length
        if (wlen != cur->keylen)
            continue;

        // do a bytewise comparison...
        if (!strncasecmp(cur->key, which, wlen))
            return cur;
    }

    // failure
    return NULL;
}

SV *HTTPHeaders::getHeader(char *which) {
    Header *hdr = findHeader(which);
    if (!hdr)
        return &PL_sv_undef;

    // return a reference to our sv after incrementing its refcount
    SvREFCNT_inc(hdr->sv_value);
    return hdr->sv_value;
}

void HTTPHeaders::setHeader(char *which, char *value) {
    Header *hdr = findHeader(which);

    // now get the length of value
    int vlen = value ? strlen(value) : 0;

    // behavior changes depending on whether we're setting or unsetting
    if (vlen) {
        // if we have no header in the lineup, we need to create one and stick it on the end
        if (!hdr) {
            // nope, create a new one
            New(0, hdr, 1, Header);
            if (!hdr)
                return; // FIXME: way to report error here? :/
            Poison(hdr, 1, Header);

            // initialize this header
            hdr->key = NULL;
            hdr->keylen = 0;
            hdr->prev = NULL;
            hdr->next = NULL;
            hdr->sv_value = NULL;

            // link this in (hdrtail becomes our prev, us its next, we the new tail)
            // don't you love dealing with everything manually?
            if (hdrtail) {
                hdrtail->next = hdr;
                hdr->prev = hdrtail;
            }
            if (!hdrs)
                hdrs = hdr;
            hdrtail = hdr;
        }

        // free up header value, as we're giving it a new one
        if (hdr->sv_value) {
            SvREFCNT_dec(hdr->sv_value);
        }

        // now copy the new value
        hdr->sv_value = newSVpvn(value, vlen);
        if (!hdr->sv_value)
            return; // FIXME: as above, error?

        // free up old key if we had one
        if (hdr->key) {
            Safefree(hdr->key);
        }

        // copy in the header name
        int wlen = strlen(which);
        Newz(0, hdr->key, wlen + 1, char);
        Copy(which, hdr->key, wlen, char);
        hdr->keylen = wlen;

    } else {
        // return if we don't have a header (unset what doesn't exist? sure thing!)
        if (!hdr)
            return;

        // no value, so they're removing it
        if (hdr->prev) {
            // previous implies we're a link in the chain, so point our previous
            // header to point at the next one past us (drop us from the link)
            hdr->prev->next = hdr->next;
        } else {
            // no previous, so this was the head header
            hdrs = hdr->next;
        }

        // and now update our next to point to our previous...
        if (hdr->next) {
            // we have someone after us, point them up at the top
            hdr->next->prev = hdr->prev;
        } else {
            // nothing past us, so we were the last header, so point hdrtail at
            // the one before us now
            hdrtail = hdr->prev;
        }

        freeHeader(hdr);
    }
}

int HTTPHeaders::getMethod() {
    return method;
}

SV *HTTPHeaders::getMethodString() {
    if (sv_methodString) {
        SvREFCNT_inc(sv_methodString);
        return sv_methodString;
    } else
        return &PL_sv_undef;
}

int HTTPHeaders::getStatusCode() {
    return statusCode;
}

int HTTPHeaders::getVersionNumber() {
    return versionNumber;
}

bool HTTPHeaders::isRequest() {
    return headersType == H_REQUEST;
}

bool HTTPHeaders::isResponse() {
    return headersType == H_RESPONSE;
}

SV *HTTPHeaders::getURI() {
    if (sv_uri) {
        SvREFCNT_inc(sv_uri);
        return sv_uri;
    } else
        return &PL_sv_undef;
}

SV *HTTPHeaders::getHeadersList() {
    if (hdrs) {
        AV *header_names = (AV*) sv_2mortal((SV*)newAV());
        for (Header *cur = hdrs; cur; cur = cur->next) {
            av_push(header_names, newSVpv(cur->key, cur->keylen));
        }
        return newRV((SV*)header_names);
    } else
        return &PL_sv_undef;
}

SV *HTTPHeaders::setURI(char *uri) {
    int urilen = uri ? strlen(uri) : 0;
    SV *temp_uri = newSVpvn(uri, urilen);

    if (!temp_uri)
        return &PL_sv_undef;

    // Select which method we're using and turn it into a string
    const char *methodstr;

    switch(method) {
        case M_GET:
            methodstr = "GET";
            break;
        case M_POST:
            methodstr = "POST";
            break;
        case M_OPTIONS:
            methodstr = "OPTIONS";
            break;
        case M_PUT:
            methodstr = "PUT";
            break;
        case M_DELETE:
            methodstr = "DELETE";
            break;
        case M_HEAD:
            methodstr = "HEAD";
            break;
        default:
            if (sv_methodString) {
                methodstr = SvPV_nolen(sv_methodString);
                break;
            } else
                return &PL_sv_undef;
    }

    // Reconstruct the first line
    SV *temp_firstLine;
    if (versionNumber)
        temp_firstLine = newSVpvf("%s %s HTTP/%d.%d",
                                  methodstr, uri, int(versionNumber / 1000), versionNumber % 1000);
    else
        temp_firstLine = newSVpvf("%s %s",
                                  methodstr, uri);

    // Overwrite the SVs we were preparing
    if (sv_uri)
        SvREFCNT_dec(sv_uri);

    sv_uri = temp_uri;

    if (sv_firstLine)
        SvREFCNT_dec(sv_firstLine);

    sv_firstLine = temp_firstLine;

    // Increment refcount and put sv_uri on the return stack to indicate success.
    SvREFCNT_inc(sv_uri);
    return sv_uri;
}

void HTTPHeaders::setStatusCode(int code) {
    statusCode = code;
}

void HTTPHeaders::setCodeText(int code, char *codetext) {
    // only if response
    if (isRequest())
        return;

    // nothing if they're the same
    if (statusCode == code)
        return;

    // verify we have a line (already got headers)
    if (!sv_firstLine)
        return;

    // set and rebuild sv_firstLine
    statusCode = code;
    SV *temp = newSVpvf("HTTP/%d.%d %d %s",
                        int(versionNumber / 1000), versionNumber % 1000, code, codetext);

    // save our new line, get rid of old one
    SvREFCNT_dec(sv_firstLine);
    sv_firstLine = temp;
}

void HTTPHeaders::setVersionNumber(int version) {
    // if we don't have a first line, die
    if (!sv_firstLine)
        return;
    
    // generate new sv with new HTTP/ etc
    SV *temp = newSVpvf("HTTP/%d.%d", int(version / 1000), version % 1000);
    char *initial = SvPV_nolen(sv_firstLine);
    char *ptr = initial;

    // variable codepaths
    if (isResponse()) {
        // responses are easy... find first space, and concat from that point on
        // onto the end of temp
        skip_to_space(&ptr);
        sv_catpv(temp, ptr);
    } else {
        // requests are more difficult, we have to find the last space...
        skip_to_space(&ptr);
        skip_spaces(&ptr);
        skip_to_space(&ptr);
        skip_spaces(&ptr);

        // now create in temp2 what we need
        SV *temp2 = newSVpvn(initial, ptr - initial);
        sv_catsv(temp2, temp);
        SvREFCNT_dec(temp);
        temp = temp2;
    }

    // free up our first line, it's now temp
    SvREFCNT_dec(sv_firstLine);
    sv_firstLine = temp;

    // store for people to get at
    versionNumber = version;
}
