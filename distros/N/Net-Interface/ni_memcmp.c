
/* ********************************************************************	*
 * memcmp.c	version 0.01	1-12-09					*
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

	int
	memcmp(const void *s1, const void *s2, size_t n);

DESCRIPTION
	The  memcmp()  function  compares  the  first  n  bytes of the memory 
	areas s1 and s2.  It returns an integer less than, equal to, or greater 
	than zero if s1 is found, respectively, to be less than, to match, or 
	be greater than s2.

RETURN VALUE
	The  memcmp() function returns an integer less than, equal to, or greater 
	than zero if the first n bytes of s1 is found, respectively, to be less 
	than, to match, or be greater  than the first n bytes of s2.

 *
 */

#include "localconf.h"
#ifndef HAVE_MEMCMP

int
memcmp (const void *s1, const void *s2, size_t n)
{
    register unsigned char * a = (unsigned char *)s1, * b = (unsigned char *)s2;
    int rv;
    
    while (n != 0) {

	if ((rv = *a - *b) != 0)
	    return rv;
	a++;
	b++;
	n--;
    }
    return 0;
}

#endif
