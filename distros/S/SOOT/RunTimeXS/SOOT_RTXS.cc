
#include "SOOT_RTXS.h"

U32 SOOT_RTXS_no_hashkeys = 0;
U32 SOOT_RTXS_free_hashkey_no = 0;
soot_rtxs_hashkey* SOOT_RTXS_hashkeys = NULL;
HashTable* SOOT_RTXS_reverse_hashkeys = NULL;

U32 SOOT_RTXS_no_arrayindices = 0;
U32 SOOT_RTXS_free_arrayindices_no = 0;
I32* SOOT_RTXS_arrayindices = NULL;

U32 SOOT_RTXS_reverse_arrayindices_length = 0;
I32* SOOT_RTXS_reverse_arrayindices = NULL;

#ifdef USE_ITHREADS
soot_rtxs_global_lock SOOT_RTXS_lock;
#endif /* USE_ITHREADS */


#ifdef USE_ITHREADS
/* implement locking for thread-safety */

#define SOOT_RTXS_ACQUIRE_GLOBAL_LOCK(theLock) \
STMT_START {                                   \
  MUTEX_LOCK(&theLock.mutex);                  \
  while (theLock.locks != 0) {                 \
    COND_WAIT(&theLock.cond, &theLock.mutex);  \
  }                                            \
  theLock.locks = 1;                           \
  MUTEX_UNLOCK(&theLock.mutex);                \
} STMT_END

#define SOOT_RTXS_RELEASE_GLOBAL_LOCK(theLock) \
STMT_START {                                   \
  MUTEX_LOCK(&theLock.mutex);                  \
  theLock.locks = 0;                           \
  COND_SIGNAL(&theLock.cond);                  \
  MUTEX_UNLOCK(&theLock.mutex);                \
} STMT_END

void _init_soot_rtxs_lock(soot_rtxs_global_lock* theLock) {
  Zero(theLock, 1, soot_rtxs_global_lock);
  MUTEX_INIT(&theLock->mutex);
  COND_INIT(&theLock->cond);
  theLock->locks = 0;
}

#else /* no USE_ITHREADS */
#define SOOT_RTXS_RELEASE_GLOBAL_LOCK(theLock)
#define SOOT_RTXS_ACQUIRE_GLOBAL_LOCK(theLock)
#endif /* USE_ITHREADS */

/* implement hash containers */

I32 get_hashkey_index(pTHX_ const char* key, const I32 len) {
  I32 index;

  SOOT_RTXS_ACQUIRE_GLOBAL_LOCK(SOOT_RTXS_lock);

  /* init */
  if (SOOT_RTXS_reverse_hashkeys == NULL)
    SOOT_RTXS_reverse_hashkeys = SOOT_RTXS_HashTable_new(16, 0.9);

  index = SOOT_RTXS_HashTable_fetch(SOOT_RTXS_reverse_hashkeys, key, (STRLEN)len);
  if ( index == -1 ) { /* does not exist */
    index = _new_hashkey();
    /* store the new hash key in the reverse lookup table */
    SOOT_RTXS_HashTable_store(SOOT_RTXS_reverse_hashkeys, key, len, index);
  }

  SOOT_RTXS_RELEASE_GLOBAL_LOCK(SOOT_RTXS_lock);

  return index;
}

/* this is private, call get_hashkey_index instead */
I32 _new_hashkey() {
  if (SOOT_RTXS_no_hashkeys == SOOT_RTXS_free_hashkey_no) {
    U32 extend = 1 + SOOT_RTXS_no_hashkeys * 2;
    /*printf("extending hashkey storage by %u\n", extend);*/
    soot_rtxs_hashkey* tmphashkeys;
    Newx(tmphashkeys, SOOT_RTXS_no_hashkeys + extend, soot_rtxs_hashkey);
    Copy(SOOT_RTXS_hashkeys, tmphashkeys, SOOT_RTXS_no_hashkeys, soot_rtxs_hashkey);
    Safefree(SOOT_RTXS_hashkeys);
    SOOT_RTXS_hashkeys = tmphashkeys;
    SOOT_RTXS_no_hashkeys += extend;
  }
  return SOOT_RTXS_free_hashkey_no++;
}


/* implement array containers */

void _resize_array(I32** array, U32* len, U32 newlen) {
  I32* tmparraymap;
  Newx(tmparraymap, newlen * sizeof(I32), I32);
  Copy(*array, tmparraymap, *len, I32);
  Safefree(*array);
  *array = tmparraymap;
  *len = newlen;
}

void _resize_array_init(I32** array, U32* len, U32 newlen, I32 init) {
  U32 i;
  I32* tmparraymap;
  Newx(tmparraymap, newlen * sizeof(I32), I32);
  Copy(*array, tmparraymap, *len, I32);
  Safefree(*array);
  *array = tmparraymap;
  for (i = *len; i < newlen; ++i)
    (*array)[i] = init;
  *len = newlen;
}

/* this is private, call get_internal_array_index instead */
I32 _new_internal_arrayindex() {
  if (SOOT_RTXS_no_arrayindices == SOOT_RTXS_free_arrayindices_no) {
    U32 extend = 2 + SOOT_RTXS_no_arrayindices * 2;
    /*printf("extending array index storage by %u\n", extend);*/
    _resize_array(&SOOT_RTXS_arrayindices, &SOOT_RTXS_no_arrayindices, extend);
  }
  return SOOT_RTXS_free_arrayindices_no++;
}

I32 get_internal_array_index(I32 object_ary_idx) {
  I32 new_index;

  SOOT_RTXS_ACQUIRE_GLOBAL_LOCK(SOOT_RTXS_lock);

  if (SOOT_RTXS_reverse_arrayindices_length <= (U32)object_ary_idx)
    _resize_array_init( &SOOT_RTXS_reverse_arrayindices,
                        &SOOT_RTXS_reverse_arrayindices_length,
                        object_ary_idx+1, -1 );

  /* -1 == "undef" */
  if (SOOT_RTXS_reverse_arrayindices[object_ary_idx] > -1) {
    SOOT_RTXS_RELEASE_GLOBAL_LOCK(SOOT_RTXS_lock);
    return SOOT_RTXS_reverse_arrayindices[object_ary_idx];
  }

  new_index = _new_internal_arrayindex();
  SOOT_RTXS_reverse_arrayindices[object_ary_idx] = new_index;

  SOOT_RTXS_RELEASE_GLOBAL_LOCK(SOOT_RTXS_lock);

  return new_index;
}

#undef SOOT_RTXS_ACQUIRE_GLOBAL_LOCK
#undef SOOT_RTXS_RELEASE_GLOBAL_LOCK

