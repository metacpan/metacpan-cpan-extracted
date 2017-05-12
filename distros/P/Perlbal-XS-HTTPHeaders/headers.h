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

#ifndef __HEADERS_H
#define __HEADERS_H

extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

/* some general purpose defines we use */
#define H_REQUEST 1
#define H_RESPONSE 2

/* setup method constants */
#define M_GET 1
#define M_POST 2
#define M_OPTIONS 3
#define M_PUT 4
#define M_DELETE 5
#define M_HEAD 6

/* some structs we use for storing header information */
struct Header {
    int keylen;     /* 14 */
    char *key;      /* Content-length */
    SV *sv_value;   /* 5 */
    Header *prev, *next;
};

/* the main headers class */
class HTTPHeaders {

    private:
        int versionNumber, statusCode, headersType, method;
        SV *sv_uri, *sv_firstLine, *sv_methodString;

        Header *hdrs, *hdrtail;

        Header *findHeader(char *which, int len = 0);
        void freeHeader(Header *hdr);

    public:
        /* constructor and destructor */
        HTTPHeaders();
        ~HTTPHeaders();
        int parseHeaders(SV *headers);

        /* reconstructor */
        SV *getReconstructed();

        /* get and set header values */
        SV *getHeader(char *which);
        void setHeader(char *which, char *value);

        /* extra getters that we use to speed stuff up */
        int getMethod();
        SV *getMethodString();
        int getStatusCode();
        void setStatusCode(int code);
        void setVersionNumber(int version);
        int getVersionNumber();
        bool isRequest();
        bool isResponse();
        void setCodeText(int code, char *codetext);
        SV *getURI();
        SV *setURI(char *uri);
        SV *getHeadersList();
        
};

#endif
