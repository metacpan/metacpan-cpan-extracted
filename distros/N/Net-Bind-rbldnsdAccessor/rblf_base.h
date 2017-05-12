/*	rblf_base.h
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

#ifndef RBLFBASE_H
#define RBLFBASE_H 1

#include <string.h>
#include <arpa/nameser.h>

#include "rbldnsdaccessor.h"

/*	check for file reload needed this often	*/
#define RBLF_RELOAD_CHECK_INTERVAL 60

/*	the ISC definition of UNUSED		*/
#define B_UNUSED(x) (void)(x)

/*	the rbldnsd definition of UNUSED	*/
#define R_UNUSED __attribute__((unused))

#define RBLF_DLEN PACKETSZ * 2	/*	enough for 2 x expansion	*/

/*	types missing from <arpa/namser.h>	*/
#ifndef T_DS
#define T_DS 43
#endif
#ifndef T_TKEY
#define T_TKEY 249
#endif
#ifndef T_TSIG
#define T_TSIG 250
#endif

struct rblf_info {
  unsigned int type;
  u_int32_t ttl;
  unsigned int rdl;
  unsigned char rdata[RBLF_DLEN];
};

/*	from rbldnsd/dns.h	*/
#define dns_dnlc(c) ((c) >= 'A' && (c) <= 'Z' ? (c) - 'A' + 'a' : (c))

/*	from rbldnsdf and friends	*/
int rblf_safemcpy(unsigned char * dst, unsigned char * src, size_t size, unsigned char * dstlim);
int rblf_strncpy(char * dst, char * src, size_t max);
int rblf_case(struct rblf_info * ri, unsigned char **ptrptr, unsigned char * bom, unsigned char * eom);

#endif
