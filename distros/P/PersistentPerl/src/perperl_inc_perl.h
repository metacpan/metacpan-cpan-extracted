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

#ifdef PERPERL_BACKEND
#   define PERL_CORE
#endif

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <patchlevel.h>

/* For sockets */
#ifndef VMS
# ifdef I_SYS_TYPES
#  include <sys/types.h>
# endif
#include <sys/socket.h>
#ifdef MPE
# define PF_INET AF_INET
# define PF_UNIX AF_UNIX
# define SOCK_RAW 3
#endif
#ifdef I_SYS_UN
#include <sys/un.h>
#endif
# ifdef I_NETINET_IN
#  include <netinet/in.h>
# endif
#include <netdb.h>
#ifdef I_ARPA_INET
# include <arpa/inet.h>
#endif
#else
#include "sockadapt.h"
#endif
#ifndef INADDR_LOOPBACK
#define INADDR_LOOPBACK         0x7F000001
#endif /* INADDR_LOOPBACK */

/* Various */
#ifdef I_UNISTD
#include <unistd.h>
#endif

/* For fcntl */
#ifdef I_FCNTL
#include <fcntl.h>
#endif

/* For waitpid */
#ifdef I_SYS_WAIT
#include <sys/wait.h>
#endif

/* For readv/writev.  I_SYSUIO is new in perl 5.6 */
#if defined(I_SYSUIO) || PATCHLEVEL < 6
#include <sys/uio.h>
#endif

/* Found in pp_sys.c... */
   /* fcntl.h might not have been included, even if it exists, because
      the current Configure only sets I_FCNTL if it's needed to pick up
      the *_OK constants.  Make sure it has been included before testing
      the fcntl() locking constants. */
#  if defined(HAS_FCNTL) && !defined(I_FCNTL)
#    include <fcntl.h>
#  endif

/* For mmap */
/* We should use I_SYS_MMAN here, but it doesn't seem to work yet */
#ifndef _WIN32
#include <sys/mman.h>
#endif

/* For kill, sig* functions */
#if !defined(_WIN32) && (!defined(NSIG) || defined(M_UNIX) || defined(M_XENIX))
#include <signal.h>
#endif
