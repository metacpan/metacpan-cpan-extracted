#include "ppport.h"
#include "perl.h"

#include "hash_table.h"

typedef struct {
  U32 hash;
  char* key;
  char* accessor_name;
  bool  default_coderef;
  I32 accessor_len;
  I32 len; /* not STRLEN for perl internal UTF hacks and hv_common_keylen
              -- man, these things can take you by surprise */
  SV *default_value;
} autoxs_hashkey;

#ifdef USE_ITHREADS
typedef struct {
  perl_mutex mutex;
  perl_cond cond;
  unsigned int locks;
} cxsa_global_lock;
#endif /* USE_ITHREADS */

/********************
 * prototype section 
 ********************/

I32 get_hashkey_index(pTHX_ const char* key, const I32 len);
I32 _new_hashkey();

void _resize_array(I32** array, U32* len, U32 newlen);
void _resize_array_init(I32** array, U32* len, U32 newlen, I32 init);
I32 _new_internal_arrayindex();
I32 get_internal_array_index(I32 object_ary_idx);

#ifdef USE_ITHREADS
void _init_cxsa_lock(cxsa_global_lock* theLock);
#endif /* USE_ITHREADS */

/*************************
 * initialization section 
 ************************/

U32 CXSAccessor_no_hashkeys = 0;
U32 CXSAccessor_free_hashkey_no = 0;
autoxs_hashkey* CXSAccessor_hashkeys = NULL;
HashTable* CXSAccessor_reverse_hashkeys = NULL;

U32 CXSAccessor_no_arrayindices = 0;
U32 CXSAccessor_free_arrayindices_no = 0;
I32* CXSAccessor_arrayindices = NULL;

U32 CXSAccessor_reverse_arrayindices_length = 0;
I32* CXSAccessor_reverse_arrayindices = NULL;

#ifdef USE_ITHREADS
static cxsa_global_lock CXSAccessor_lock;
#endif /* USE_ITHREADS */

/*************************
 * implementation section 
 *************************/

#ifdef USE_ITHREADS
/* implement locking for thread-safety */

#define CXSA_ACQUIRE_GLOBAL_LOCK(theLock)     \
STMT_START {                                  \
  MUTEX_LOCK(&theLock.mutex);                 \
  while (theLock.locks != 0) {                \
    COND_WAIT(&theLock.cond, &theLock.mutex); \
  }                                           \
  theLock.locks = 1;                          \
  MUTEX_UNLOCK(&theLock.mutex);               \
} STMT_END

#define CXSA_RELEASE_GLOBAL_LOCK(theLock)     \
STMT_START {                                  \
  MUTEX_LOCK(&theLock.mutex);                 \
  theLock.locks = 0;                          \
  COND_SIGNAL(&theLock.cond);                 \
  MUTEX_UNLOCK(&theLock.mutex);               \
} STMT_END

void _init_cxsa_lock(cxsa_global_lock* theLock) {
  cxa_memzero((void*)theLock, sizeof(cxsa_global_lock));
  MUTEX_INIT(&theLock->mutex);
  COND_INIT(&theLock->cond);
  theLock->locks = 0;
}

#else /* no USE_ITHREADS */
#define CXSA_RELEASE_GLOBAL_LOCK(theLock)
#define CXSA_ACQUIRE_GLOBAL_LOCK(theLock)
#endif /* USE_ITHREADS */

/* implement hash containers */

I32 get_hashkey_index(pTHX_ const char* key, const I32 len) {
  I32 index;

  CXSA_ACQUIRE_GLOBAL_LOCK(CXSAccessor_lock);

  /* init */
  if (CXSAccessor_reverse_hashkeys == NULL)
    CXSAccessor_reverse_hashkeys = CXSA_HashTable_new(16, 0.9);

  index = CXSA_HashTable_fetch(CXSAccessor_reverse_hashkeys, key, (STRLEN)len);
  if ( index == -1 ) { /* does not exist */
    index = _new_hashkey();
    /* store the new hash key in the reverse lookup table */
    CXSA_HashTable_store(CXSAccessor_reverse_hashkeys, key, len, index);
  }

  CXSA_RELEASE_GLOBAL_LOCK(CXSAccessor_lock);

  return index;
}

/* this is private, call get_hashkey_index instead */
I32 _new_hashkey() {
  if (CXSAccessor_no_hashkeys == CXSAccessor_free_hashkey_no) {
    U32 extend = 1 + CXSAccessor_no_hashkeys * 2;
    /*printf("extending hashkey storage by %u\n", extend);*/
    CXSAccessor_hashkeys = (autoxs_hashkey*)cxa_realloc(
      (void*)CXSAccessor_hashkeys,
      (CXSAccessor_no_hashkeys + extend) * sizeof(autoxs_hashkey)
    );
    CXSAccessor_no_hashkeys += extend;
  }
  return CXSAccessor_free_hashkey_no++;
}


/* implement array containers */

void _resize_array(I32** array, U32* len, U32 newlen) {
  *array = (I32*)cxa_realloc((void*)(*array), newlen*sizeof(I32));
  *len = newlen;
}

void _resize_array_init(I32** array, U32* len, U32 newlen, I32 init) {
  U32 i;
  *array = (I32*)cxa_realloc((void*)(*array), newlen*sizeof(I32));
  for (i = *len; i < newlen; ++i)
    (*array)[i] = init;
  *len = newlen;
}

/* this is private, call get_internal_array_index instead */
I32 _new_internal_arrayindex() {
  if (CXSAccessor_no_arrayindices == CXSAccessor_free_arrayindices_no) {
    U32 extend = 2 + CXSAccessor_no_arrayindices * 2;
    /*printf("extending array index storage by %u\n", extend);*/
    _resize_array(&CXSAccessor_arrayindices, &CXSAccessor_no_arrayindices, extend);
  }
  return CXSAccessor_free_arrayindices_no++;
}

I32 get_internal_array_index(I32 object_ary_idx) {
  I32 new_index;

  CXSA_ACQUIRE_GLOBAL_LOCK(CXSAccessor_lock);

  if (CXSAccessor_reverse_arrayindices_length <= (U32)object_ary_idx)
    _resize_array_init( &CXSAccessor_reverse_arrayindices,
                        &CXSAccessor_reverse_arrayindices_length,
                        object_ary_idx+1, -1 );

  /* -1 == "undef" */
  if (CXSAccessor_reverse_arrayindices[object_ary_idx] > -1) {
    CXSA_RELEASE_GLOBAL_LOCK(CXSAccessor_lock);
    return CXSAccessor_reverse_arrayindices[object_ary_idx];
  }

  new_index = _new_internal_arrayindex();
  CXSAccessor_reverse_arrayindices[object_ary_idx] = new_index;

  CXSA_RELEASE_GLOBAL_LOCK(CXSAccessor_lock);

  return new_index;
}

#undef CXSA_ACQUIRE_GLOBAL_LOCK
#undef CXSA_RELEASE_GLOBAL_LOCK
