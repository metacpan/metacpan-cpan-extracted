/* sha - An implementation of the NIST SHA 256/384/512 Message Digest algorithm
 * Copyright (C) 2001 Rafael R. Sevilla <sevillar@team.ph.inter.net>
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef _SHA_H

#define _SHA_H

#include "types.h"

#define SHA_BLOCKSIZE 64
#define SHA512_BLOCKSIZE 128
#define SHA256_DIGESTSIZE 32
#define SHA512_DIGESTSIZE 64
#define SHA384_DIGESTSIZE 48

/* for SHA256 only */
typedef struct {
  Uint32 digest[8];
  Uint32 count_lo, count_hi;
  Uint8 data[SHA_BLOCKSIZE];
  int local;
} SHA_INFO;

extern void sha_init(SHA_INFO *sha_info);
extern void sha_update(SHA_INFO *sha_info, Uint8 *buffer, int count);
extern void sha_final(SHA_INFO *sha_info);
extern void sha_unpackdigest(Uint8 digest[32], SHA_INFO *sha_info);
extern void sha_print(SHA_INFO *sha_info);

#endif
