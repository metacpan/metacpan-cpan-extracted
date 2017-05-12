
/* ********************************************************************	*
 * strlcpy.c	version 0.01	1-12-09					*
 *									*
 *     COPYRIGHT 2008-2009 Michael Robinton <michael@bizsystems.com>	*
 *									*
 * This program is free software; you can redistribute it and/or modify	*
 * it under the terms of either:					*
 *									*
 *  a) the GNU General Public License as published by the Free		*
 *  Software Foundation; either version 2, or (at your option) any	*
 *  later version, or							*
 *									*
 *  b) the "Artistic License" which comes with this distribution.	*
 *									*
 * This program is distributed in the hope that it will be useful,	*
 * but WITHOUT ANY WARRANTY; without even the implied warranty of	*
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either	*
 * the GNU General Public License or the Artistic License for more 	*
 * details.								*
 *									*
 * You should have received a copy of the Artistic License with this	*
 * distribution, in the file named "Artistic".  If not, I'll be glad 	*
 * to provide one.							*
 *									*
 * You should also have received a copy of the GNU General Public 	*
 * License along with this program in the file named "Copying". If not, *
 * write to the 							*
 *									*
 *	Free Software Foundation, Inc.					*
 *	59 Temple Place, Suite 330					*
 *	Boston, MA  02111-1307, USA					*
 *									*
 * or visit their web page on the internet at:				*
 *									*
 *	http://www.gnu.org/copyleft/gpl.html.				*
 * ********************************************************************	*

SYNOPSIS

     size_t
     strlcpy(char *dst, const char *src, size_t size);

DESCRIPTION

     The strlcpy() function copys strings and is designed to be safer, more 
     consistent, and less error prone replacement for strncpy(3). Unlike that
     function, strlcpy() takes the full size of the buffer (not just the length)
     and guarantees to NUL-terminate the result (as long as size is larger than 0.
     Note that you should include a byte for the NUL in size.  Also note that 
     strlcpy() only operates on true `C'' strings.  This means that for strlcpy()
     src must be NUL-terminated.

     The strlcpy() function copies up to size - 1 characters from the 
     NUL-terminated string src to dst, NUL-terminating the result.

RETURN VALUES

     The strlcpy() returns the total length of the string it tried to create, that
     means the length of src. While this may seem somewhat confusing it was done 
     to make truncation detection simple.

 *
 */

#include "localconf.h"
#ifndef HAVE_STRLCPY

size_t
strlcpy (char *d, const char *s, size_t size)
{
    size_t n = 0;
    if ((int)size < 1)
	return 0;
    while (n < size) {
	if ((*(d + n) = *(s + n)) == 0) {
	    n++;
	    break;
        }
        else
            n++;
    }
    if (n < size) {
	*(d+n) = 0;
    }
    else {
	*(d + n -1) = 0;
    }
    return n;
}
#endif
