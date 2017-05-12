#ifndef _QSTRUCT_UTILS_H
#define _QSTRUCT_UTILS_H

#include <inttypes.h>
#include <stdint.h>


#define QSTRUCT_U16(x) ((uint16_t)(x))
#define QSTRUCT_U32(x) ((uint32_t)(x))
#define QSTRUCT_U64(x) ((uint64_t)(x))
#define QSTRUCT_U16P(x) ((uint16_t *)(x))
#define QSTRUCT_U32P(x) ((uint32_t *)(x))
#define QSTRUCT_U64P(x) ((uint64_t *)(x))
#define QSTRUCT_UC(x,n) (((unsigned char *)(x))[n])

#ifdef QSTRUCT_LITTLE_ENDIAN_NON_PORTABLE
#  define QSTRUCT_LOAD_8BYTE_LE(s, d) (*(QSTRUCT_U64P(d)) = *(QSTRUCT_U64P(s)))
#  define QSTRUCT_LOAD_4BYTE_LE(s, d) (*(QSTRUCT_U32P(d)) = *(QSTRUCT_U32P(s)))
#  define QSTRUCT_LOAD_2BYTE_LE(s, d) (*(QSTRUCT_U16P(d)) = *(QSTRUCT_U16P(s)))

#  define QSTRUCT_STORE_8BYTE_LE(s, d) (*(QSTRUCT_U64P(d)) = *(QSTRUCT_U64P(s)))
#  define QSTRUCT_STORE_4BYTE_LE(s, d) (*(QSTRUCT_U32P(d)) = *(QSTRUCT_U32P(s)))
#  define QSTRUCT_STORE_2BYTE_LE(s, d) (*(QSTRUCT_U16P(d)) = *(QSTRUCT_U16P(s)))
#else
#  define QSTRUCT_LOAD_8BYTE_LE(s, d) (*QSTRUCT_U64P(d) = (QSTRUCT_U64(QSTRUCT_UC(s,0)) << 0)  | \
                                                          (QSTRUCT_U64(QSTRUCT_UC(s,1)) << 8)  | \
                                                          (QSTRUCT_U64(QSTRUCT_UC(s,2)) << 16) | \
                                                          (QSTRUCT_U64(QSTRUCT_UC(s,3)) << 24) | \
                                                          (QSTRUCT_U64(QSTRUCT_UC(s,4)) << 32) | \
                                                          (QSTRUCT_U64(QSTRUCT_UC(s,5)) << 40) | \
                                                          (QSTRUCT_U64(QSTRUCT_UC(s,6)) << 48) | \
                                                          (QSTRUCT_U64(QSTRUCT_UC(s,7)) << 56))

#  define QSTRUCT_LOAD_4BYTE_LE(s, d) (*QSTRUCT_U32P(d) = (QSTRUCT_U32(QSTRUCT_UC(s,0)) << 0)  | \
                                                          (QSTRUCT_U32(QSTRUCT_UC(s,1)) << 8)  | \
                                                          (QSTRUCT_U32(QSTRUCT_UC(s,2)) << 16) | \
                                                          (QSTRUCT_U32(QSTRUCT_UC(s,3)) << 24))

#  define QSTRUCT_LOAD_2BYTE_LE(s, d) (*QSTRUCT_U16P(d) = (QSTRUCT_U16(QSTRUCT_UC(s,0)) << 0)  | \
                                                          (QSTRUCT_U16(QSTRUCT_UC(s,1)) << 8))

#  define QSTRUCT_STORE_8BYTE_LE(s, d) (QSTRUCT_UC(d,0) = (*QSTRUCT_U64P(s) >> 0) & 0xFF, \
                                        QSTRUCT_UC(d,1) = (*QSTRUCT_U64P(s) >> 8) & 0xFF, \
                                        QSTRUCT_UC(d,2) = (*QSTRUCT_U64P(s) >> 16) & 0xFF, \
                                        QSTRUCT_UC(d,3) = (*QSTRUCT_U64P(s) >> 24) & 0xFF, \
                                        QSTRUCT_UC(d,4) = (*QSTRUCT_U64P(s) >> 32) & 0xFF, \
                                        QSTRUCT_UC(d,5) = (*QSTRUCT_U64P(s) >> 40) & 0xFF, \
                                        QSTRUCT_UC(d,6) = (*QSTRUCT_U64P(s) >> 48) & 0xFF, \
                                        QSTRUCT_UC(d,7) = (*QSTRUCT_U64P(s) >> 56) & 0xFF)

#  define QSTRUCT_STORE_4BYTE_LE(s, d) (QSTRUCT_UC(d,0) = (*QSTRUCT_U32P(s) >> 0) & 0xFF, \
                                        QSTRUCT_UC(d,1) = (*QSTRUCT_U32P(s) >> 8) & 0xFF, \
                                        QSTRUCT_UC(d,2) = (*QSTRUCT_U32P(s) >> 16) & 0xFF, \
                                        QSTRUCT_UC(d,3) = (*QSTRUCT_U32P(s) >> 24) & 0xFF)

#  define QSTRUCT_STORE_2BYTE_LE(s, d) (QSTRUCT_UC(d,0) = (*QSTRUCT_U16P(s) >> 0) & 0xFF, \
                                        QSTRUCT_UC(d,1) = (*QSTRUCT_U16P(s) >> 8) & 0xFF)
#endif


#define QSTRUCT_ALIGN_UP(p, a) (((p) + (a) - 1) & ~((a) - 1))


#define QSTRUCT_BODY_SIZE_TO_ALIGNMENT(s) ((s) <= 1 ? 1 : \
                                           (s) <= 2 ? 2 : \
                                           (s) <= 4 ? 4 : \
                                           8 \
                                          )


#ifndef QSTRUCT_INLINE
#  define QSTRUCT_INLINE inline
#endif


#endif
