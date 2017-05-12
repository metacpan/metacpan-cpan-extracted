/*
 * escape_ansi.c
 * -------------
 * Functions for escaping non-printable characters.
 *
 *
 * Copyright 2008, 2009 Sebastien Aperghis-Tramoni
 *
 * This program is free software; you can redistribute it
 * and/or modify it under the same terms as Perl itself.
 */

/* standard includes */
#include <stdlib.h>

/* custom includes */
#include "escape_chars.h"

/* private macros */
#define NON_PRINTABLE(x)    ((x) <= '\x1F' || (x) == '\x7F')
#define CHAR_INDEX(x)       ( (x) <= '\x1F' ? (int)((x) - '\x00') \
                            : (x) == '\x7F' ? (int)((x) - '\x1F' + 1) \
                            : (int)((x) - '\x1F' + 2) )

/* structures */
struct {
    const char  code;
    const char *name;
} charname[] = {
    { '\x00', "NUL" },  /* "\\0" */
    { '\x01', "SOH" },
    { '\x02', "STX" },
    { '\x03', "ETX" },
    { '\x04', "EOT" },
    { '\x05', "ENQ" },
    { '\x06', "ACK" },
    { '\x07', "BEL" },  /* "\\a" */
    { '\x08', "BS"  },  /* "\\b" */
    { '\x09', "HT"  },  /* "\\t" */
    { '\x0A', "LF"  },  /* "\\n" */
    { '\x0B', "VT"  },  /* "\\v" */
    { '\x0C', "FF"  },  /* "\\f" */
    { '\x0D', "CR"  },  /* "\\r" */
    { '\x0E', "SO"  },
    { '\x0F', "SI"  },
    { '\x10', "DLE" },
    { '\x11', "DC1" },
    { '\x12', "DC2" },
    { '\x13', "DC3" },
    { '\x14', "DC4" },
    { '\x15', "NAK" },
    { '\x16', "SYN" },
    { '\x17', "ETB" },
    { '\x18', "CAN" },
    { '\x19', "EM"  },
    { '\x1A', "SUB" },
    { '\x1B', "ESC" },
    { '\x1C', "FS"  },
    { '\x1D', "GS"  },
    { '\x1E', "RS"  },
    { '\x1F', "US"  },
    { '\x7F', "DEL" },
    {      0, "???" },
};


/*
 * escape_non_printable_chars()
 * --------------------------
/*! Escape non-printable characters
 *
 * This function parse the given null-terminated string and looks for
 * non-printable characters to escape. 
 * 
 * If there are any, a new string is allocated where each non-printable
 * character is replaced with a human-readable representation. For example
 * the character '\x1B' (ESC) is replace with "<ESC>".
 * 
 * If there is no character to escape, the original string is returned.
 * 
 * Typical usage:
 * 
 *     char input[] = "";
 *     char *output;
 *
 *     output = escape_non_printable_chars(input);
 *     ... 
 *     if (output != input)
 *         free(output);
 *
 *
 * @param  input    null-terminated string
 * @return          null-terminated string
 * 
 */
char * escape_non_printable_chars(const char *input) {
    char        *output;
    const char  *i;
    const char  *n;
    char        *o;
    int         len = 0;
    int         num = 0;

    /* first loop to calculate the number of characters to escape */
    for (i=input; *i != '\0'; i++) {
        len++;

        if (NON_PRINTABLE(*i))
            num++;
    }

    /* if there's nothing to escape, just return the input string */
    if (num == 0)
        return (char *) input;

    output = (char *) malloc(len + 4*num);

    /* second loop to actually escape the non-printable characters */
    for (i=input, o=output; *i != '\0'; i++) {
        if (NON_PRINTABLE(*i)) {
            *o++ = '<';

            for (n=charname[CHAR_INDEX(*i)].name; *n != '\0'; n++)
                *o++ = *n;

            *o++ = '>';
        }
        else
            *o++ = *i;
    }

    *o = '\0';

    return output;
}
