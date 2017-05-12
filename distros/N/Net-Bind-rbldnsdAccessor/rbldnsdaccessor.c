/*	rbldnsdaccessor.c	version 1.00

 Copyright 2006, Michael Robinton, michael@bizsystems.com
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or 
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of 
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */


#include "rbldnsdaccessor.h"

/*	add heap tracking for memory usage so that all memory can be released
 *	by calling "rblf_mtfree". "istream.c" memory is ignored as it appears
 *	to take care of itself dynamically
 */

#define MT_EXTEND 1024 * sizeof(void *)	/*	size of each subsequent memory tracking extension	*/
static void ** mtrack = NULL;
static unsigned long mtend = 0;

void
rblf_mtrack(void * mem)
{
  unsigned long i;
  void * newmt;
  
  if (mtrack == NULL) {
    mtrack = calloc(MT_EXTEND,sizeof(char *));
    if (!mtrack)
      oom();
    mtend = MT_EXTEND;
  }

FIND_EMPTY_SLOT:
  for (i=0;i<mtend;i++) {
    if (!mtrack[i]) {
      mtrack[i] = mem;
      return;
    }
  }
/*	no more room in array, extend	*/
  newmt = realloc(mtrack,mtend + (MT_EXTEND));
  if (!newmt)
    oom();
  bzero(newmt + (MT_EXTEND),MT_EXTEND);
  mtrack = newmt;
  mtend += MT_EXTEND;
  goto FIND_EMPTY_SLOT;
}

void
rblf_mtrack_forget(void * mem)
{
  unsigned long i;
  
  for (i=0;i<mtend;i++) {
    if (mtrack[i] == mem) {
      mtrack[i] = NULL;
      return;
    }
  }
}

void
rblf_mtfree(void * mem)
{
  if (!mtrack || !mem)
    return;
    
  rblf_mtrack_forget(mem);
  free(mem);
}

void
rblf_mtfree_all(void)
{
  unsigned long i;
  
  if (!mtrack)
    return;
    
  for (i=0;i<mtend;i++) {
    if (!mtrack[i])
      free(mtrack[i]);
  }
  free(mtrack);
  mtrack = NULL;
  mtend = 0;
}

#ifdef RBLFBASE_H		/* this is Perl code only	*/

#else				/* this is BIND code only	*/

static dns_sdbimplementation_t * rbldnsd = NULL;

isc_result_t
rblf_lookup(const char * zone, const char *name, void * dbdata, dns_sdblookup_t * lookup)
{
  UNUSED(dbdata);
  UNUSED(zone);
  return (rblf_isc_lookup(name,lookup,dns_sdb_putrdata));
}

dns_sdbmethods_t
rblf_methods = {
  rblf_lookup,
  NULL,		/*	authority	*/
  NULL,		/*	allnodes	*/
  rblf_create_zone,
  NULL		/*	destroy		*/
};

/*	wrapper around dns_sdb_register()	*/
isc_result_t
rbldnsd_init(void)
{
  extern isc_mem_t * ns_g_mctx;

  /*  unsigned flags = DNS_SDBFLAG_THREADSAFE;    */
  unsigned int flags = 0;
    
  return (dns_sdb_register("rbldnsd", &rblf_methods, NULL, flags, ns_g_mctx, &rbldnsd));
}

/*	wrapper around dns_sdb_unregister()	*/
void
rbldnsd_clear(void)
{
  if (rbldnsd == NULL)
    return;

  rblf_drop();
  dns_sdb_unregister(&rbldnsd);
}

#endif
