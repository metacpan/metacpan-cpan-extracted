
/* ********************************************************************	*
 * ni_malloc.c	version 0.01 2-11-09					*
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
 * ********************************************************************	*/

#include "config.h"

int __ni_malloc_c_silence_warning;

#if HAVE_MALLOC == 0 || HAVE_REALLOC == 0

/* if this OS has buggy memory allocation, fix it	*/

#warning FUNCTIONS calloc, malloc, realloc, free re-defined because of buggy C lib

#include <sys/types.h>
#include <stdlib.h>

void *
ni_rpl_malloc (size_t n)
{
    if (n == 0)
	n = 1;
    return malloc(n);
}

void *
ni_rpl_calloc (size_t mbsz, size_t n)
{
    if (n == 0)
	n = 1;
    return calloc(mbsz,n);
}

void *
ni_rpl_realloc (void * ptr, size_t n)
{
    if (ptr == NULL)
	return malloc(n);
    return realloc(ptr,n);
}

void
ni_rpl_free  (void * ptr)
{
    if (ptr != NULL)
	free(ptr);
}

#endif
