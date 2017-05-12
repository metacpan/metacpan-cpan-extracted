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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "headers.h"

#include "const-c.inc"

MODULE = Perlbal::XS::HTTPHeaders		PACKAGE = Perlbal::XS::HTTPHeaders		

INCLUDE: const-xs.inc

HTTPHeaders *
HTTPHeaders::new( headers, junk = 0 )
    SV *headers
    int junk
    CODE:
        RETVAL = new HTTPHeaders();
        if (!RETVAL) XSRETURN_UNDEF;
        if (!RETVAL->parseHeaders( headers )) {
            delete RETVAL;
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

void
HTTPHeaders::DESTROY()

SV *
HTTPHeaders::getReconstructed()

SV *
HTTPHeaders::getHeader( which )
    char *which

void
HTTPHeaders::setHeader( which, value )
    char *which
    char *value

int
HTTPHeaders::getMethod()

int
HTTPHeaders::getStatusCode()

int
HTTPHeaders::getVersionNumber()

void
HTTPHeaders::setVersionNumber( version )
    int version

bool
HTTPHeaders::isRequest()

bool
HTTPHeaders::isResponse()

void
HTTPHeaders::setStatusCode( code )
    int code

void
HTTPHeaders::setCodeText( code, codetext )
    int code
    char *codetext

SV *
HTTPHeaders::getURI()

SV *
HTTPHeaders::setURI( uri )
    char *uri

################################################################################
## setup functions that call through to our native functions; this is the
## interface definition that Perlbal expects to use when we're a replacement
## for the standard library

SV *
HTTPHeaders::header( which, value = NULL )
    char *which
    char *value
    PROTOTYPE: $;$
    CODE:
        // THIS is first argument, so we expect 2 or 3
        if (items > 2) {
            THIS->setHeader( which, value );
            if (GIMME_V != G_VOID && value) {
                RETVAL = THIS->getHeader( which );
            } else {
                XSRETURN_UNDEF;
            }
        } else
            RETVAL = THIS->getHeader( which );
    OUTPUT:
        RETVAL

SV *
HTTPHeaders::to_string()
    CODE:
        RETVAL = THIS->getReconstructed();
    OUTPUT:
        RETVAL

SV *
HTTPHeaders::to_string_ref()
    CODE:
        SV *temp = THIS->getReconstructed();
        RETVAL = newRV_noinc(temp);
    OUTPUT:
        RETVAL

SV *
HTTPHeaders::request_method()
    CODE:
        switch ( THIS->getMethod() ) {
            case M_GET:
                RETVAL = newSVpvn("GET", 3);
                break;
            case M_HEAD:
                RETVAL = newSVpvn("HEAD", 4);
                break;
            case M_POST:
                RETVAL = newSVpvn("POST", 4);
                break;
            case M_OPTIONS:
                RETVAL = newSVpvn("OPTIONS", 7);
                break;
            case M_PUT:
                RETVAL = newSVpvn("PUT", 3);
                break;
            case M_DELETE:
                RETVAL = newSVpvn("DELETE", 6);
                break;
            default:
                RETVAL = THIS->getMethodString();
        }
    OUTPUT:
        RETVAL

SV *
HTTPHeaders::request_uri()
    CODE:
        RETVAL = THIS->getURI();
    OUTPUT:
        RETVAL

SV *
HTTPHeaders::headers_list()
    CODE:
        RETVAL = THIS->getHeadersList();
    OUTPUT:
        RETVAL

SV *
HTTPHeaders::set_request_uri( uri = NULL )
    char *uri
    CODE:
        RETVAL = THIS->setURI(uri);
    OUTPUT:
        RETVAL

int
HTTPHeaders::response_code()
    CODE:
        RETVAL = THIS->getStatusCode();
    OUTPUT:
        RETVAL

int
HTTPHeaders::version_number( value = 0 )
    int value
    CODE:
        // do a set if we have 2 parameters
        if (items == 2) {
            THIS->setVersionNumber( value );
            RETVAL = value;
        } else
            RETVAL = THIS->getVersionNumber();
    OUTPUT:
        RETVAL
