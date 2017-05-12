
#ifndef __STAFINCLUDES_H__
#define __STAFINCLUDES_H__

#include "STAFError.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned int STAFHandle_t;

/* Mutex */
typedef struct STAFMutexSemImplementation *STAFMutexSem_t;

STAFRC_t STAFMutexSemConstruct(STAFMutexSem_t *pMutex, 
                               const char *name, unsigned int *osRC);
STAFRC_t STAFMutexSemRequest(STAFMutexSem_t mutex, unsigned int timeout,
                             unsigned int *osRC);
STAFRC_t STAFMutexSemRelease(STAFMutexSem_t mutex, unsigned int *osRC);
STAFRC_t STAFMutexSemDestruct(STAFMutexSem_t *pMutex, unsigned int *osRC);

/* Event */

#define STAF_EVENT_SEM_INDEFINITE_WAIT (unsigned int)-1
typedef struct STAFEventSemImplementation *STAFEventSem_t;
typedef enum   STAFEventSemState_e {
    kSTAFEventSemReset  = 0, 
    kSTAFEventSemPosted = 1
} STAFEventSemState_t;
STAFRC_t STAFEventSemConstruct(STAFEventSem_t *pEvent, 
                               const char *name, unsigned int *osRC);
STAFRC_t STAFEventSemPost(STAFEventSem_t pEvent, unsigned int *osRC);
STAFRC_t STAFEventSemReset(STAFEventSem_t pEvent, unsigned int *osRC);
STAFRC_t STAFEventSemWait(STAFEventSem_t pEvent, unsigned int timeout,
                          unsigned int *osRC);
STAFRC_t STAFEventSemDestruct(STAFEventSem_t *pEvent, unsigned int *osRC);


/* String */

typedef struct STAFStringImplementation *STAFString_t;
typedef const struct STAFStringImplementation *STAFStringConst_t;
typedef enum STAFStringCaseSensitive_e {
    kSTAFStringCaseInsensitive = 0,
    kSTAFStringCaseSensitive = 1
} STAFStringCaseSensitive_t;

STAFRC_t STAFStringConstruct(STAFString_t *pString,
                             const char *buffer,
                             unsigned int len,
                             unsigned int *osRC);
STAFRC_t STAFStringConstructCopy(STAFString_t *pString,
                                 STAFStringConst_t aString,
                                 unsigned int *osRC);
STAFRC_t STAFStringToUpperCase(STAFString_t aString,
                               unsigned int *osRC);
STAFRC_t STAFStringReplace(STAFString_t aString,
                           STAFStringConst_t oldString,
                           STAFStringConst_t newString,
                           unsigned int *osRC);
STAFRC_t STAFStringToCurrentCodePage(STAFStringConst_t aString,
                                     char **to,
                                     unsigned int *len,
                                     unsigned int *osRC);
STAFRC_t STAFStringConcatenate(STAFString_t aString,
                               STAFStringConst_t aSource,
                               unsigned int *osRC);
STAFRC_t STAFStringToUInt(STAFStringConst_t aString,
                          unsigned int *value, unsigned int base,
                          unsigned int *osRC);
STAFRC_t STAFStringLength(STAFStringConst_t aString,
                          unsigned int *len,
                          unsigned int corb,
                          unsigned int *osRC);
STAFRC_t STAFStringDestruct(STAFString_t *pString,
                            unsigned int *osRC);
STAFRC_t STAFStringFreeBuffer(const char *buffer,
                              unsigned int *osRC);
STAFRC_t STAFStringIsEqualTo(STAFStringConst_t aFirst,
                             STAFStringConst_t aSecond,
                             STAFStringCaseSensitive_t sensitive,
                             unsigned int *comparison,
                             unsigned int *osRC);


#ifdef __cplusplus
}
#endif
#endif
