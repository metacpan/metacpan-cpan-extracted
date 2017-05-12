
#ifndef _SOOT_RTXS_h_
#define _SOOT_RTXS_h_

#include "SOOT_RTXS_hash_table.h"

typedef struct {
  I32 offset;
  U32 maxIndex;
} soot_rtxs_hashkey;

#ifdef USE_ITHREADS
typedef struct {
  perl_mutex mutex;
  perl_cond cond;
  unsigned int locks;
} soot_rtxs_global_lock;
#endif /* USE_ITHREADS */

I32 get_hashkey_index(pTHX_ const char* key, const I32 len);
I32 _new_hashkey();

void _resize_array(I32** array, U32* len, U32 newlen);
void _resize_array_init(I32** array, U32* len, U32 newlen, I32 init);
I32 _new_internal_arrayindex();
I32 get_internal_array_index(I32 object_ary_idx);

#ifdef USE_ITHREADS
void _init_soot_rtxs_lock(soot_rtxs_global_lock* theLock);
#endif /* USE_ITHREADS */

/*************************
 * declare external vars 
 ************************/

extern U32 SOOT_RTXS_no_hashkeys;
extern U32 SOOT_RTXS_free_hashkey_no;
extern soot_rtxs_hashkey* SOOT_RTXS_hashkeys;
extern HashTable* SOOT_RTXS_reverse_hashkeys;

extern U32 SOOT_RTXS_no_arrayindices;
extern U32 SOOT_RTXS_free_arrayindices_no;
extern I32* SOOT_RTXS_arrayindices;

extern U32 SOOT_RTXS_reverse_arrayindices_length;
extern I32* SOOT_RTXS_reverse_arrayindices;

#ifdef USE_ITHREADS
extern soot_rtxs_global_lock SOOT_RTXS_lock;
#endif /* USE_ITHREADS */

#endif

