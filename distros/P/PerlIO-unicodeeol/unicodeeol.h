#ifndef UNICODEEOL_H
#define UNICODEEOL_H

typedef struct {
    PerlIOBuf       base;
    unsigned char   previous;
} UnicodeEOL;

/* vim: set filetype=perl ts=8 sts=4 et: */

#endif
