#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define _LARGEFILE_SOURCE
#define _FILE_OFFSET_BITS 64
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#ifdef __cplusplus
}
#endif

MODULE = Sys::PageCache     PACKAGE = Sys::PageCache

BOOT:
{
    HV *stash = gv_stashpv ("Sys::PageCache", 0);
    newCONSTSUB (stash, "POSIX_FADV_NORMAL"    , newSViv (POSIX_FADV_NORMAL));
    newCONSTSUB (stash, "POSIX_FADV_SEQUENTIAL", newSViv (POSIX_FADV_SEQUENTIAL));
    newCONSTSUB (stash, "POSIX_FADV_RANDOM"    , newSViv (POSIX_FADV_RANDOM));
    newCONSTSUB (stash, "POSIX_FADV_NOREUSE"   , newSViv (POSIX_FADV_NOREUSE));
    newCONSTSUB (stash, "POSIX_FADV_WILLNEED"  , newSViv (POSIX_FADV_WILLNEED));
    newCONSTSUB (stash, "POSIX_FADV_DONTNEED"  , newSViv (POSIX_FADV_DONTNEED));
}

int
page_size()
  CODE:
    RETVAL = sysconf(_SC_PAGESIZE);
  OUTPUT:
    RETVAL

HV*
_fincore(fd, offset, length)
    int fd;
    size_t offset;
    size_t length;
  CODE:
    void *pa = (char *)0;
    unsigned char *vec = (unsigned char *)0;
    size_t page_size = sysconf(_SC_PAGESIZE);
    size_t page_index;
    size_t cached = 0;

    RETVAL = (HV *)sv_2mortal((SV *)newHV());

    pa = mmap((void *)0, length, PROT_NONE, MAP_SHARED, fd, offset);
    if (pa == MAP_FAILED) {
        croak("mmap: %s", strerror(errno));
    }

    vec = calloc(1, (length + page_size - 1) / page_size);
    if (vec == NULL) {
        munmap(pa, length);
        croak("calloc: %s", strerror(errno));
    }

    if (mincore(pa, length, vec) != 0) {
        free(vec);
        munmap(pa, length);
        croak("mincore: %s", strerror(errno));
    }

    for (page_index = 0; page_index <= length / page_size; page_index++) {
        if (vec[page_index] & 1) {
            cached++;
        }
    }

    free(vec);
    munmap(pa, length);

    hv_store(RETVAL, "page_size",     9, newSViv(page_size), 0);
    hv_store(RETVAL, "cached_pages", 12, newSViv(cached), 0);
    hv_store(RETVAL, "cached_size",  11, newSViv((unsigned long long)cached * page_size), 0);
  OUTPUT:
    RETVAL

int
_fadvise(fd, offset, length, advice)
    int fd;
    size_t offset;
    size_t length;
    int advice
  CODE:
    int r;
#if linux
    r = fdatasync(fd);
#else
    r = fsync(fd);
#endif
    if (r != 0) {
        croak("fdatasync: %s", strerror(errno));
    }
    r = posix_fadvise(fd, offset, length, advice);
    if (r != 0) {
        croak("posix_fadvise: %s", strerror(errno));
    }

    RETVAL = r;
  OUTPUT:
    RETVAL
