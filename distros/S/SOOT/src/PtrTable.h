/*
 * This is a customised version of the pointer table implementation in Perl's sv.c.
 * Just like Perl, is released under the GPL or the Artistic License.
 * First customized by chocolateboy 2009-02-25,
 * 2010-02-22 for SOOT by Steffen Mueller
 */

#ifndef __PtrTable_h_
#define __PtrTable_h_
#include "ROOTIncludes.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#undef do_open
#undef do_close
#ifdef __cplusplus
}
#endif

#include <set>

namespace SOOT {

  typedef struct PtrAnnotation {
    unsigned int fNReferences;
    std::set<SV*> fPerlObjects;
    bool fDoNotDestroy;
  } PtrAnnotation;

  void ClearAnnotation(pTHX_ PtrAnnotation* pa);

  typedef void (*PtrTableEntryValueDtor)(pTHX_ PtrAnnotation*);

  typedef struct PtrTableEntry {
      struct PtrTableEntry* next;
      const TObject* key;
      PtrAnnotation* value;
  } PtrTableEntry;

  class PtrTable {
  public:
    /** New PtrTable with a given number of pre-allocated slots
     *  and a grow threshold with reasonable default.
     *  The PtrTable keeps its associated Perl interpreter around (pTHX)
     *  and requires a function pointer for the entry destruction.
     */
    PtrTable(pTHX_ UV size, PtrTableEntryValueDtor dtor, NV threshold = 0.9);
    ~PtrTable();
    
    /// Stores an element in the PtrTable, returning the previous value if any
    PtrAnnotation* Store(const TObject* key, PtrAnnotation* value);
    /// Fetches an element from the PtrTable
    PtrAnnotation* Fetch(const TObject* key);
    /// Fetches an element from the PtrTable and creates it if it didn't exist
    PtrAnnotation* FetchOrCreate(const TObject* key);
    /// Deletes an element from the PtrTable
    bool Delete(TObject* key);
    /// Clear PtrTable
    void Clear();

    /// Print information about the table (for debugging only)
    void PrintStats();
  private:
    /// Searches an element in the PtrTable and returns its ENTRY
    PtrTableEntry* Find(const TObject* key);
    /// Double the size of the array
    void Grow();

    struct PtrTableEntry **fArray;
    UV fSize;
    UV fItems;
    NV fThreshold;
#ifdef USE_ITHREADS
    tTHX fPerl;
#endif /* USE_ITHREADS */
    PtrTableEntryValueDtor fDtor;

#if PTRSIZE == 8
    /*
     * This is one of Thomas Wang's hash functions for 64-bit integers from:
     * http://www.concentric.net/~Ttwang/tech/inthash.htm
     */
    static inline U32 hash(PTRV u) {
        u = (~u) + (u << 18);
        u = u ^ (u >> 31);
        u = u * 21;
        u = u ^ (u >> 11);
        u = u + (u << 6);
        u = u ^ (u >> 22);
        return (U32)u;
    }
#else
    /*
     * This is one of Bob Jenkins' hash functions for 32-bit integers
     * from: http://burtleburtle.net/bob/hash/integer.html
     */
    static inline U32 hash(PTRV u) {
        u = (u + 0x7ed55d16) + (u << 12);
        u = (u ^ 0xc761c23c) ^ (u >> 19);
        u = (u + 0x165667b1) + (u << 5);
        u = (u + 0xd3a2646c) ^ (u << 9);
        u = (u + 0xfd7046c5) + (u << 3);
        u = (u ^ 0xb55a4f09) ^ (u >> 16);
        return u;
    }
#endif
  };

} // end namespace SOOT::PtrTable

#endif

