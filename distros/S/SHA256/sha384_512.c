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

#include <stdio.h>
#include "sha512.h"
#include "endian.h"

/* truncate to 32 bits -- should be a null op on 32-bit machines */
#define TRUNC32(x)	((Uint32)((x) & 0xffffffffLL))

/* 64-bit rotate to the RIGHT */
#define ROT64(x,n)	(((x >> n) | (x << (64 - n))))

#define CH(x, y, z) (((x) & (y))^(~(x) & (z)))
#define MAJ(x, y, z)(((x) & (y))^((x) & (z))^((y) & (z)))

/* upper-case sigma functions in SHA spec */
#define USIG0(x) (ROT64(x, 28)^ROT64(x, 34)^ROT64(x, 39))
#define USIG1(x) (ROT64(x, 14)^ROT64(x, 18)^ROT64(x, 41))

/* lower-case sigma functions in SHA spec */
#define LSIG0(x) (ROT64(x, 1)^ROT64(x, 8)^(x >> 7))
#define LSIG1(x) (ROT64(x, 19)^ROT64(x, 61)^(x >> 6))

/* Constants */
static Uint64 K[80] = {
  0x428a2f98d728ae22LL, 0x7137449123ef65cdLL,
  0xb5c0fbcfec4d3b2fLL, 0xe9b5dba58189dbbcLL,
  0x3956c25bf348b538LL, 0x59f111f1b605d019LL,
  0x923f82a4af194f9bLL, 0xab1c5ed5da6d8118LL,
  0xd807aa98a3030242LL, 0x12835b0145706fbeLL,
  0x243185be4ee4b28cLL, 0x550c7dc3d5ffb4e2LL,
  0x72be5d74f27b896fLL, 0x80deb1fe3b1696b1LL,
  0x9bdc06a725c71235LL, 0xc19bf174cf692694LL,
  0xe49b69c19ef14ad2LL, 0xefbe4786384f25e3LL,
  0x0fc19dc68b8cd5b5LL, 0x240ca1cc77ac9c65LL,
  0x2de92c6f592b0275LL, 0x4a7484aa6ea6e483LL,
  0x5cb0a9dcbd41fbd4LL, 0x76f988da831153b5LL,
  0x983e5152ee66dfabLL, 0xa831c66d2db43210LL,
  0xb00327c898fb213fLL, 0xbf597fc7beef0ee4LL,
  0xc6e00bf33da88fc2LL, 0xd5a79147930aa725LL,
  0x06ca6351e003826fLL, 0x142929670a0e6e70LL,
  0x27b70a8546d22ffcLL, 0x2e1b21385c26c926LL,
  0x4d2c6dfc5ac42aedLL, 0x53380d139d95b3dfLL,
  0x650a73548baf63deLL, 0x766a0abb3c77b2a8LL,
  0x81c2c92e47edaee6LL, 0x92722c851482353bLL,
  0xa2bfe8a14cf10364LL, 0xa81a664bbc423001LL,
  0xc24b8b70d0f89791LL, 0xc76c51a30654be30LL,
  0xd192e819d6ef5218LL, 0xd69906245565a910LL,
  0xf40e35855771202aLL, 0x106aa07032bbd1b8LL,
  0x19a4c116b8d2d0c8LL, 0x1e376c085141ab53LL,
  0x2748774cdf8eeb99LL, 0x34b0bcb5e19b48a8LL,
  0x391c0cb3c5c95a63LL, 0x4ed8aa4ae3418acbLL,
  0x5b9cca4f7763e373LL, 0x682e6ff3d6b2b8a3LL,
  0x748f82ee5defb2fcLL, 0x78a5636f43172f60LL,
  0x84c87814a1f0ab72LL, 0x8cc702081a6439ecLL,
  0x90befffa23631e28LL, 0xa4506cebde82bde9LL,
  0xbef9a3f7b2c67915LL, 0xc67178f2e372532bLL,
  0xca273eceea26619cLL, 0xd186b8c721c0c207LL,
  0xeada7dd6cde0eb1eLL, 0xf57d4f7fee6ed178LL,
  0x06f067aa72176fbaLL, 0x0a637dc5a2c898a6LL,
  0x113f9804bef90daeLL, 0x1b710b35131c471bLL,
  0x28db77f523047d84LL, 0x32caab7b40c72493LL,
  0x3c9ebe0a15c9bebcLL, 0x431d67c49c100d4cLL,
  0x4cc5d4becb3e42b6LL, 0x597f299cfc657e2aLL,
  0x5fcb6fab3ad6faecLL, 0x6c44198c4a475817LL
};

static void sha_transform(SHA_INFO512 *sha_info)
{
  int i, j;
  Uint8 *dp;
  Uint64 T, T1, T2, A, B, C, D, E, F, G, H, W[80];

  dp = sha_info->data;

#undef SWAP_DONE

#if BYTEORDER == 1234 || BYTEORDER == 12345678
#define SWAP_DONE
  for (i = 0; i < 16; ++i) {
    T = *((Uint64 *) dp);
    dp += 8;
    W[i] = 
      ((T << 56) & 0xff00000000000000LL) |
      ((T << 40) & 0x00ff000000000000LL) |
      ((T << 24) & 0x0000ff0000000000LL) |
      ((T <<  8) & 0x000000ff00000000LL) |
      ((T >>  8) & 0x00000000ff000000LL) |
      ((T >> 24) & 0x0000000000ff0000LL) |
      ((T >> 40) & 0x000000000000ff00LL) |
      ((T >> 56) & 0x00000000000000ffLL);
  }

#endif

#if BYTEORDER == 4321 || BYTEORDER == 87654321
#define SWAP_DONE
  for (i = 0; i < 16; ++i) {
    T = *((Uint64 *) dp);
    dp += 8;
    W[i] = (T);
  }
#endif

#ifndef SWAP_DONE
#error Unknown byte order -- you need to add code here
#endif /* SWAP_DONE */


  A = sha_info->digest[0];
  B = sha_info->digest[1];
  C = sha_info->digest[2];
  D = sha_info->digest[3];
  E = sha_info->digest[4];
  F = sha_info->digest[5];
  G = sha_info->digest[6];
  H = sha_info->digest[7];

  for (i=16; i<80; i++)
    W[i] = (LSIG1(W[i-2]) + W[i-7] + LSIG0(W[i-15]) + W[i-16]);

  for (j=0; j<80; j++) {
    T1 = (H + USIG1(E) + CH(E, F, G) + K[j] + W[j]);
    T2 = (USIG0(A) + MAJ(A, B, C));
    H = G;
    G = F;
    F = E;
    E = (D + T1);
    D = C;
    C = B;
    B = A;
    A = (T1 + T2);
  }

  sha_info->digest[0] += A;
  sha_info->digest[1] += B;
  sha_info->digest[2] += C;
  sha_info->digest[3] += D;
  sha_info->digest[4] += E;
  sha_info->digest[5] += F;
  sha_info->digest[6] += G;
  sha_info->digest[7] += H;
}

void sha_init512(SHA_INFO512 *sha_info)
{
  sha_info->digest[0] = 0x6a09e667f3bcc908LL;
  sha_info->digest[1] = 0xbb67ae8584caa73bLL;
  sha_info->digest[2] = 0x3c6ef372fe94f82bLL;
  sha_info->digest[3] = 0xa54ff53a5f1d36f1LL;
  sha_info->digest[4] = 0x510e527fade682d1LL;
  sha_info->digest[5] = 0x9b05688c2b3e6c1fLL;
  sha_info->digest[6] = 0x1f83d9abfb41bd6bLL;
  sha_info->digest[7] = 0x5be0cd19137e2179LL;
  sha_info->count_lo = 0L;
  sha_info->count_hi = 0L;
  sha_info->local = 0;
  memset((Uint8 *)sha_info->data, 0, SHA512_BLOCKSIZE);
}

void sha_init384(SHA_INFO512 *sha_info)
{
  sha_info->digest[0] = 0xcbbb9d5dc1059ed8LL;
  sha_info->digest[1] = 0x629a292a367cd507LL;
  sha_info->digest[2] = 0x9159015a3070dd17LL;
  sha_info->digest[3] = 0x152fecd8f70e5939LL;
  sha_info->digest[4] = 0x67332667ffc00b31LL;
  sha_info->digest[5] = 0x8eb44a8768581511LL;
  sha_info->digest[6] = 0xdb0c2e0d64f98fa7LL;
  sha_info->digest[7] = 0x47b5481dbefa4fa4LL;
  sha_info->count_lo = 0L;
  sha_info->count_hi = 0L;
  sha_info->local = 0;
  memset((Uint8 *)sha_info->data, 0, SHA512_BLOCKSIZE);
}

void sha_update512(SHA_INFO512 *sha_info, Uint8 *buffer, int count)
{
  int i;
  Uint64 clo;

  clo = sha_info->count_lo + (count << 3);
  if (clo < sha_info->count_lo) {
    sha_info->count_hi++;
  }
  sha_info->count_lo = clo;
  if (sha_info->local) {
    i = SHA512_BLOCKSIZE - sha_info->local;
    if (i > count) {
      i = count;
    }
    memcpy(((Uint8 *) sha_info->data) + sha_info->local, buffer, i);
    count -= i;
    buffer += i;
    sha_info->local += i;
    if (sha_info->local == SHA512_BLOCKSIZE) {
      sha_transform(sha_info);
    } else {
      return;
    }
  }
  while (count >= SHA512_BLOCKSIZE) {
    memcpy(sha_info->data, buffer, SHA512_BLOCKSIZE);
    buffer += SHA512_BLOCKSIZE;
    count -= SHA512_BLOCKSIZE;
    sha_transform(sha_info);
  }
  memcpy(sha_info->data, buffer, count);
  sha_info->local = count;
}

void sha_final512(SHA_INFO512 *sha_info)
{
  int count, i;
  Uint64 lo_bit_count, hi_bit_count;

  lo_bit_count = sha_info->count_lo;
  hi_bit_count = sha_info->count_hi;
  count = (int) ((lo_bit_count >> 3) & 0x7f);
  ((Uint8 *) sha_info->data)[count++] = 0x80;
  if (count > SHA512_BLOCKSIZE - 16) {
    memset(((Uint8 *) sha_info->data) + count, 0, SHA512_BLOCKSIZE - count);
    sha_transform(sha_info);
    memset((Uint8 *) sha_info->data, 0, SHA512_BLOCKSIZE - 16);
  } else {
    memset(((Uint8 *) sha_info->data) + count, 0, SHA512_BLOCKSIZE - count - 16);
  }
  sha_info->data[112] = (hi_bit_count >> 56) & 0xff;
  sha_info->data[113] = (hi_bit_count >> 48) & 0xff;
  sha_info->data[114] = (hi_bit_count >> 40) & 0xff;
  sha_info->data[115] = (hi_bit_count >> 32) & 0xff;
  sha_info->data[116] = (hi_bit_count >> 24) & 0xff;
  sha_info->data[117] = (hi_bit_count >> 16) & 0xff;
  sha_info->data[118] = (hi_bit_count >>  8) & 0xff;
  sha_info->data[119] = (hi_bit_count >>  0) & 0xff;
  sha_info->data[120] = (lo_bit_count >> 56) & 0xff;
  sha_info->data[121] = (lo_bit_count >> 48) & 0xff;
  sha_info->data[122] = (lo_bit_count >> 40) & 0xff;
  sha_info->data[123] = (lo_bit_count >> 32) & 0xff;
  sha_info->data[124] = (lo_bit_count >> 24) & 0xff;
  sha_info->data[125] = (lo_bit_count >> 16) & 0xff;
  sha_info->data[126] = (lo_bit_count >>  8) & 0xff;
  sha_info->data[127] = (lo_bit_count >>  0) & 0xff;
  sha_transform(sha_info);
}

void sha_unpackdigest384(Uint8 digest[48], SHA_INFO512 *sha_info)
{
  digest[ 0] = (unsigned char) ((sha_info->digest[0] >> 56) & 0xff);
  digest[ 1] = (unsigned char) ((sha_info->digest[0] >> 48) & 0xff);
  digest[ 2] = (unsigned char) ((sha_info->digest[0] >> 40) & 0xff);
  digest[ 3] = (unsigned char) ((sha_info->digest[0] >> 32) & 0xff);
  digest[ 4] = (unsigned char) ((sha_info->digest[0] >> 24) & 0xff);
  digest[ 5] = (unsigned char) ((sha_info->digest[0] >> 16) & 0xff);
  digest[ 6] = (unsigned char) ((sha_info->digest[0] >>  8) & 0xff);
  digest[ 7] = (unsigned char) ((sha_info->digest[0]      ) & 0xff);
  digest[ 8] = (unsigned char) ((sha_info->digest[1] >> 56) & 0xff);
  digest[ 9] = (unsigned char) ((sha_info->digest[1] >> 48) & 0xff);
  digest[10] = (unsigned char) ((sha_info->digest[1] >> 40) & 0xff);
  digest[11] = (unsigned char) ((sha_info->digest[1] >> 32) & 0xff);
  digest[12] = (unsigned char) ((sha_info->digest[1] >> 24) & 0xff);
  digest[13] = (unsigned char) ((sha_info->digest[1] >> 16) & 0xff);
  digest[14] = (unsigned char) ((sha_info->digest[1] >>  8) & 0xff);
  digest[15] = (unsigned char) ((sha_info->digest[1]      ) & 0xff);
  digest[16] = (unsigned char) ((sha_info->digest[2] >> 56) & 0xff);
  digest[17] = (unsigned char) ((sha_info->digest[2] >> 48) & 0xff);
  digest[18] = (unsigned char) ((sha_info->digest[2] >> 40) & 0xff);
  digest[19] = (unsigned char) ((sha_info->digest[2] >> 32) & 0xff);
  digest[20] = (unsigned char) ((sha_info->digest[2] >> 24) & 0xff);
  digest[21] = (unsigned char) ((sha_info->digest[2] >> 16) & 0xff);
  digest[22] = (unsigned char) ((sha_info->digest[2] >>  8) & 0xff);
  digest[23] = (unsigned char) ((sha_info->digest[2]      ) & 0xff);
  digest[24] = (unsigned char) ((sha_info->digest[3] >> 56) & 0xff);
  digest[25] = (unsigned char) ((sha_info->digest[3] >> 48) & 0xff);
  digest[26] = (unsigned char) ((sha_info->digest[3] >> 40) & 0xff);
  digest[27] = (unsigned char) ((sha_info->digest[3] >> 32) & 0xff);
  digest[28] = (unsigned char) ((sha_info->digest[3] >> 24) & 0xff);
  digest[29] = (unsigned char) ((sha_info->digest[3] >> 16) & 0xff);
  digest[30] = (unsigned char) ((sha_info->digest[3] >>  8) & 0xff);
  digest[31] = (unsigned char) ((sha_info->digest[3]      ) & 0xff);
  digest[32] = (unsigned char) ((sha_info->digest[4] >> 56) & 0xff);
  digest[33] = (unsigned char) ((sha_info->digest[4] >> 48) & 0xff);
  digest[34] = (unsigned char) ((sha_info->digest[4] >> 40) & 0xff);
  digest[35] = (unsigned char) ((sha_info->digest[4] >> 32) & 0xff);
  digest[36] = (unsigned char) ((sha_info->digest[4] >> 24) & 0xff);
  digest[37] = (unsigned char) ((sha_info->digest[4] >> 16) & 0xff);
  digest[38] = (unsigned char) ((sha_info->digest[4] >>  8) & 0xff);
  digest[39] = (unsigned char) ((sha_info->digest[4]      ) & 0xff);
  digest[40] = (unsigned char) ((sha_info->digest[5] >> 56) & 0xff);
  digest[41] = (unsigned char) ((sha_info->digest[5] >> 48) & 0xff);
  digest[42] = (unsigned char) ((sha_info->digest[5] >> 40) & 0xff);
  digest[43] = (unsigned char) ((sha_info->digest[5] >> 32) & 0xff);
  digest[44] = (unsigned char) ((sha_info->digest[5] >> 24) & 0xff);
  digest[45] = (unsigned char) ((sha_info->digest[5] >> 16) & 0xff);
  digest[46] = (unsigned char) ((sha_info->digest[5] >>  8) & 0xff);
  digest[47] = (unsigned char) ((sha_info->digest[5]      ) & 0xff);
}

void sha_unpackdigest512(Uint8 digest[64], SHA_INFO512 *sha_info)
{
  digest[ 0] = (unsigned char) ((sha_info->digest[0] >> 56) & 0xff);
  digest[ 1] = (unsigned char) ((sha_info->digest[0] >> 48) & 0xff);
  digest[ 2] = (unsigned char) ((sha_info->digest[0] >> 40) & 0xff);
  digest[ 3] = (unsigned char) ((sha_info->digest[0] >> 32) & 0xff);
  digest[ 4] = (unsigned char) ((sha_info->digest[0] >> 24) & 0xff);
  digest[ 5] = (unsigned char) ((sha_info->digest[0] >> 16) & 0xff);
  digest[ 6] = (unsigned char) ((sha_info->digest[0] >>  8) & 0xff);
  digest[ 7] = (unsigned char) ((sha_info->digest[0]      ) & 0xff);
  digest[ 8] = (unsigned char) ((sha_info->digest[1] >> 56) & 0xff);
  digest[ 9] = (unsigned char) ((sha_info->digest[1] >> 48) & 0xff);
  digest[10] = (unsigned char) ((sha_info->digest[1] >> 40) & 0xff);
  digest[11] = (unsigned char) ((sha_info->digest[1] >> 32) & 0xff);
  digest[12] = (unsigned char) ((sha_info->digest[1] >> 24) & 0xff);
  digest[13] = (unsigned char) ((sha_info->digest[1] >> 16) & 0xff);
  digest[14] = (unsigned char) ((sha_info->digest[1] >>  8) & 0xff);
  digest[15] = (unsigned char) ((sha_info->digest[1]      ) & 0xff);
  digest[16] = (unsigned char) ((sha_info->digest[2] >> 56) & 0xff);
  digest[17] = (unsigned char) ((sha_info->digest[2] >> 48) & 0xff);
  digest[18] = (unsigned char) ((sha_info->digest[2] >> 40) & 0xff);
  digest[19] = (unsigned char) ((sha_info->digest[2] >> 32) & 0xff);
  digest[20] = (unsigned char) ((sha_info->digest[2] >> 24) & 0xff);
  digest[21] = (unsigned char) ((sha_info->digest[2] >> 16) & 0xff);
  digest[22] = (unsigned char) ((sha_info->digest[2] >>  8) & 0xff);
  digest[23] = (unsigned char) ((sha_info->digest[2]      ) & 0xff);
  digest[24] = (unsigned char) ((sha_info->digest[3] >> 56) & 0xff);
  digest[25] = (unsigned char) ((sha_info->digest[3] >> 48) & 0xff);
  digest[26] = (unsigned char) ((sha_info->digest[3] >> 40) & 0xff);
  digest[27] = (unsigned char) ((sha_info->digest[3] >> 32) & 0xff);
  digest[28] = (unsigned char) ((sha_info->digest[3] >> 24) & 0xff);
  digest[29] = (unsigned char) ((sha_info->digest[3] >> 16) & 0xff);
  digest[30] = (unsigned char) ((sha_info->digest[3] >>  8) & 0xff);
  digest[31] = (unsigned char) ((sha_info->digest[3]      ) & 0xff);
  digest[32] = (unsigned char) ((sha_info->digest[4] >> 56) & 0xff);
  digest[33] = (unsigned char) ((sha_info->digest[4] >> 48) & 0xff);
  digest[34] = (unsigned char) ((sha_info->digest[4] >> 40) & 0xff);
  digest[35] = (unsigned char) ((sha_info->digest[4] >> 32) & 0xff);
  digest[36] = (unsigned char) ((sha_info->digest[4] >> 24) & 0xff);
  digest[37] = (unsigned char) ((sha_info->digest[4] >> 16) & 0xff);
  digest[38] = (unsigned char) ((sha_info->digest[4] >>  8) & 0xff);
  digest[39] = (unsigned char) ((sha_info->digest[4]      ) & 0xff);
  digest[40] = (unsigned char) ((sha_info->digest[5] >> 56) & 0xff);
  digest[41] = (unsigned char) ((sha_info->digest[5] >> 48) & 0xff);
  digest[42] = (unsigned char) ((sha_info->digest[5] >> 40) & 0xff);
  digest[43] = (unsigned char) ((sha_info->digest[5] >> 32) & 0xff);
  digest[44] = (unsigned char) ((sha_info->digest[5] >> 24) & 0xff);
  digest[45] = (unsigned char) ((sha_info->digest[5] >> 16) & 0xff);
  digest[46] = (unsigned char) ((sha_info->digest[5] >>  8) & 0xff);
  digest[47] = (unsigned char) ((sha_info->digest[5]      ) & 0xff);
  digest[48] = (unsigned char) ((sha_info->digest[6] >> 56) & 0xff);
  digest[49] = (unsigned char) ((sha_info->digest[6] >> 48) & 0xff);
  digest[50] = (unsigned char) ((sha_info->digest[6] >> 40) & 0xff);
  digest[51] = (unsigned char) ((sha_info->digest[6] >> 32) & 0xff);
  digest[52] = (unsigned char) ((sha_info->digest[6] >> 24) & 0xff);
  digest[53] = (unsigned char) ((sha_info->digest[6] >> 16) & 0xff);
  digest[54] = (unsigned char) ((sha_info->digest[6] >>  8) & 0xff);
  digest[55] = (unsigned char) ((sha_info->digest[6]      ) & 0xff);
  digest[56] = (unsigned char) ((sha_info->digest[7] >> 56) & 0xff);
  digest[57] = (unsigned char) ((sha_info->digest[7] >> 48) & 0xff);
  digest[58] = (unsigned char) ((sha_info->digest[7] >> 40) & 0xff);
  digest[59] = (unsigned char) ((sha_info->digest[7] >> 32) & 0xff);
  digest[60] = (unsigned char) ((sha_info->digest[7] >> 24) & 0xff);
  digest[61] = (unsigned char) ((sha_info->digest[7] >> 16) & 0xff);
  digest[62] = (unsigned char) ((sha_info->digest[7] >>  8) & 0xff);
  digest[63] = (unsigned char) ((sha_info->digest[7]      ) & 0xff);
}
