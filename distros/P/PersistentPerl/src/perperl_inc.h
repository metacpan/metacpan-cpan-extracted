/*
 * Copyright (C) 2003  Sam Horrocks
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

/*
 * We can get compiled in two different modes - 32-bit inode#'s and
 * and 64-bit inode#'s.  On the sun test box, Apache-2 uses 64-bit, perl
 * uses 32-bit which leads to mis-communication and a corrupt temp file.
 * Best solution seems to be to just store them as 64-bit.
 *
 * If your compiler doesn't support "long long", change these to "dev_t"
 * and "ino_t" which should work if you don't have the above problem.
 */
typedef long long perperl_dev_t;
typedef long long perperl_ino_t;

#ifndef max
#define max(a,b) ((a) > (b) ? (a) : (b))
#endif

#ifndef min
#define min(a,b) ((a) < (b) ? (a) : (b))
#endif

#ifndef MAP_FAILED
#   define MAP_FAILED (-1)
#endif

#ifdef __GNUC__
#define PERPERL_INLINE __inline__
#else
#define PERPERL_INLINE
#endif

#ifdef EWOULDBLOCK
#   define SP_EWOULDBLOCK(e) ((e) == EWOULDBLOCK)
#else
#   define SP_EWOULDBLOCK(e) 0
#endif
#ifdef EAGAIN
#   define SP_EAGAIN(e) ((e) == EAGAIN)
#else
#   define SP_EAGAIN(e) 0
#endif
#define SP_NOTREADY(e) (SP_EAGAIN(e) || SP_EWOULDBLOCK(e))

typedef struct {
    perperl_ino_t	i;
    perperl_dev_t	d;
} PersistentDevIno;

#define PERPERL_PKGNAME	"PersistentPerl"
#define PERPERL_PKG(s)	PERPERL_PKGNAME "::" s

#ifdef PERPERL_EFENCE
#   define PERPERL_REALLOC_MULT 1
#else
#   define PERPERL_REALLOC_MULT 2
#endif

#ifdef _WIN32
typedef DWORD pid_t;
#endif

#include "perperl_util.h"
#include "perperl_sig.h"
#include "perperl_opt.h"
#include "perperl_optdefs.h"
#include "perperl_poll.h"
#include "perperl_slot.h"
#include "perperl_ipc.h"
#include "perperl_group.h"
#include "perperl_backend.h"
#include "perperl_frontend.h"
#include "perperl_file.h"
#include "perperl_script.h"
#include "perperl_circ.h"
#include "perperl_cb.h"
#ifdef PERPERL_BACKEND
#    include "perperl_perl.h"
#endif
