/*
 * escape_ansi.xs
 * --------------
 * Functions for escaping non-printable characters.
 *
 *
 * Copyright 2008, 2009 Sebastien Aperghis-Tramoni
 *
 * This program is free software; you can redistribute it
 * and/or modify it under the same terms as Perl itself.
 */

/* Perl includes */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* escape_ansi */
#include "escape_chars.h"


MODULE = PerlIO::via::escape_ansi    PACKAGE = PerlIO::via::escape_ansi

PROTOTYPES: ENABLE

char *
escape_non_printable_chars(input)
    const char *input
