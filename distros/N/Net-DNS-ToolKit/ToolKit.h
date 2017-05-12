/* ToolKit.h
 *
 * Copyright 2003 - 2005, Michael Robinton <michael@bizsystems.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifndef NS_GET16
#define NS_GET16	GETSHORT
#endif

#ifndef NS_PUT16
#define NS_PUT16	PUTSHORT
#endif

#ifndef NS_GET32
#define NS_GET32	GETLONG
#endif

#ifndef NS_PUT32
#define NS_PUT32	PUTLONG
#endif

#ifndef NS_INT32SZ
#define NS_INT32SZ	INT32SZ
#endif

#ifndef NS_INT16SZ
#define NS_INT16SZ	INT16SZ
#endif

#ifndef NS_INADDRSZ
#define NS_INADDRSZ	INADDRSZ
#endif

#ifndef NS_HFIXEDSZ
#define NS_HFIXEDSZ	HFIXEDSZ
#endif

#ifndef NS_IN6ADDRSZ
#define NS_IN6ADDRSZ	16
#endif

#ifndef MAXDNAME
#  ifndef NS_MAXDNAME
#  define NS_MAXDNAME 1025
#  endif
#define MAXDNAME NS_MAXDNAME
#endif
