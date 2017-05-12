
/* ********************************************************************	*
 * localconf.h	version 0.01	1-23-09					*
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

#ifdef WORDS_BIGENDIAN
#define host_is_BIG_ENDIAN 1
#else
#define host_is_LITTLE_ENDIAN 1
#endif

#include "defaults.h"

#if SIZEOF_U_INT8_T == 0
#undef SIZEOF_U_INT8_T
#define SIZEOF_U_INT8_T SIZEOF_UINT8_T
typedef uint8_t u_int8_t;
#endif 

#if SIZEOF_U_INT16_T == 0
#undef SIZEOF_U_INT16_T
#define SIZEOF_U_INT16_T SIZEOF_UINT16_T
typedef uint16_t u_int16_t;
#endif

#if SIZEOF_U_INT32_T == 0
#undef SIZEOF_U_INT32_T
#define SIZEOF_U_INT32_T SIZEOF_UINT32_T
typedef uint32_t u_int32_t;
#endif

#if SIZEOF_U_INT64_T == 0
#undef SIZEOF_U_INT64_T
#define SIZEOF_U_INT64_T SIZEOF_UINT64_T
typedef uint64_t u_int64_t;
#endif

#ifdef HAVE_LINUX_NETLINK_H
#define HAVE_NETLINK_H
#include <linux/netlink.h>
#endif
#ifdef HAVE_LINUX_RTNETLINK_H
#define HAVE_RTNETLINK_H
#include <linux/rtnetlink.h>
#endif

#include "localperl.h"

/*
 *      defined if the C program should include <pthread.h>
 *      LOCAL_PERL_WANTS_PTHREAD_H
 *
 *      defined if perl was compiled to use threads
 *      LOCAL_PERL_USE_THREADS
 *
 *      defined if perl was compiled to use interpreter threads
 *      LOCAL_PERL_USE_I_THREADS
 *
 *      defined if perl was compiled to use 5005 threads
 *      LOCAL_PERL_USE_5005_THREADS
 */
   
#if defined (HAVE_PTHREAD_H) && defined (LOCAL_PERL_WANTS_PTHREAD_H)
#define LOCAL_USE_P_THREADS
#include <pthread.h>
/* only want one flavor of threads */
# ifdef HAVE_THREAD_H
# undef HAVE_THREAD_H
# endif
#endif 

#if defined (HAVE_THREAD_H) && defined (LOCAL_PERL_USE_THREADS)
#include <sched.h>
#include <thread.h>
#define LOCAL_USE_THREADS
#endif

#include "netsymbolC.inc"

#include "ni_fixups.h"
#include "ni_funct.h"
