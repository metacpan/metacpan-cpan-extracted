/*
 * This Program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; version 2 of the License.
 *
 * This Program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this Program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place, Suite 330, Boston, MA 02111-1307 USA.
 *
 * Copyright (C) 2001 Sun Microsystems, Inc. Used by permission.
 * Copyright (C) 2005 Red Hat, Inc.
 * Copyright (C) 2009 Qindel Formacion y Servicios S.L.
 * All rights reserved.
 *
 * This code is derived from 389 Directory Server (aka Fedora
 * Directory Server) "389-ds-base-1.2.1/ldap/servers/slapd/dn.c".
 */

#include "common.h"

static char hex_digit[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
			  'A', 'B', 'C', 'D', 'E', 'F'};

static void
escape_char(char c, char **to) {
    *(*to)++ = '\\';
    *(*to)++ = hex_digit[(c >> 4) & 0xf];
    *(*to)++ = hex_digit[c & 0xf];
}

static int
hex_digit2int(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'A' && c <= 'F') return c - ('A' - 10);
    if (c >= 'a' && c <= 'f') return c - ('a' - 10);
    return -1;
}

static int
unescape_char(const char **from, const char *top) {
    if (*from >= top)
	return -1;
    char c = *(*from)++;
    int hn = hex_digit2int(c);
    if (hn >= 0) {
	if (*from < top) {
	    int ln = hex_digit2int(**from);
	    if (ln >= 0) {
		(*from)++;
		return ((hn << 4) + ln);
	    }
	}
	return hn;
    }
    return c;
}

#define SEPARATOR(c)	((c) == ',' || (c) == ';' || (c) == '+')

#define B4TYPE		0
#define INTYPE		1
#define B4EQUAL		2
#define B4VALUE		3
#define INVALUE		4
#define INQUOTEDVALUE	5
#define INVALUEHEX      6

SV *
dn_normalize(SV *ssv) {
    STRLEN slen, space_ix;
    const char *s = SvPVutf8(ssv, slen);
    const char *stop = s + slen;
    char *dstart = NULL, *d = NULL, *dtop = NULL;
    SV *dsv = sv_2mortal(newSV(sv_len(ssv) + 4 * (UTF8_MAXBYTES_CASE)));
    int state = B4TYPE;
    
    SvPOK_on(dsv);

    while (s < stop) {
	int c = (unsigned char)(*s++);
	int is_space = isSPACE(c);

	if (dtop - d < UTF8_MAXBYTES_CASE + 4) {
	    STRLEN dlen = d - dstart;
	    if (dlen)
		SvCUR_set(dsv, dlen);
	    dstart = sv_grow(dsv, dlen + (stop - s) + 4 * (UTF8_MAXBYTES_CASE + 4));
	    dtop = dstart + SvLEN(dsv);
	    d = dstart + SvCUR(dsv);
	}
	
	switch ( state ) {
	case B4TYPE:
	    if (is_space)
		break;
	    state = INTYPE; /* fall through */

	case INTYPE:
	    if (is_space)
		state = B4EQUAL;
	    else {
		if ( c == '=' )
		    state = B4VALUE;

		else if (!isALNUM(c) && c != '-')
		    croak("invalid character '%c' for dn description", c);
	    
		*d++ = c;
	    }
	    break;

	case B4EQUAL:
	    if (!is_space) {
		if ( c == '=' ) {
		    state = B4VALUE;
		    *d++ = c;
		}
		else
		    croak ("invalid character '%c' for dn description", *s);
	    }
	    break;

	case B4VALUE:
	    if (is_space)
		break;
	    if (c == '#') {
		state = INVALUEHEX;
		break;
	    }
	    state = INVALUE; /* fall through */
	    space_ix = d - dstart;

	case INVALUE:
	    if (c == '"')
		state = INQUOTEDVALUE;
	    else {
		if (SEPARATOR(c)) {
		    d = dstart + space_ix;
		    *d++ = c;
		    state = B4TYPE;		
		    break;
		}
		if (c == '\\')
		    c = unescape_char(&s, stop);

		if (c >= 0) {
		    if ((c < 0x80) && (isALNUM(c) || (c == '-')))
			*d++ = c;
		    else
			escape_char(c, &d);
		}
		if (!is_space)
		    space_ix = d - dstart;
	    }
	    break;

	case INQUOTEDVALUE:
	    if (c == '"') {
		state = INVALUE;
		space_ix = d - dstart;
	    }
	    else {
		if (c == '\\')
		    c = unescape_char(&s, stop);
		if (c >= 0) {
		    if ((c < 0x80) && (isALNUM(c) || (c == '-')))
			*d++ = c;
		    else
			escape_char(c, &d);
		}
	    }
	    break;	    

	case INVALUEHEX:
	{
	    if (SEPARATOR(c)) {
		*d++ = c;
		state = B4TYPE;
	    }
	    else if (!is_space) {
		int hn = hex_digit2int(c);
		if (hn >= 0) {
		    int ln = (s < stop ? hex_digit2int(*s) : -1);
		    c = (ln >= 0 ? ((hn << 4) + ln) : hn);
		    
		    if ((c < 0x80) && (isALNUM(c) || (c == '-')))
			*d++ = c;
		    else
			escape_char(c, &d);
		}
		else
		    croak("invalid character '%c' inside hexadecimal string", c);
	    }
	    break;
	}   
	default:
	    croak ("internal error: bad state %d", state);
	}
    }
    SvCUR_set(dsv, d - dstart);
    SvREFCNT_inc(dsv);
    return dsv;
}
