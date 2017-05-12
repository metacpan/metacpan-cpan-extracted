// While this file is currently available for inclusion outside of
// the main ObjStore distribution, you should not assume that this
// state of affairs will continue.  Please roll your own.
//
// Thanks.

#ifndef _preamble_H_
#define _preamble_H_

#define MIN_PERL_DEFINE 1

extern "C" {

#ifndef __GNUG__
/* This directive is used by gcc to do extra argument checking.  It
has no affect on correctness; it is just a debugging tool.
Re-defining it to nothing avoids warnings from the solaris sunpro
compiler.  If you see warnings on your system, figure out how to force
your compiler to shut-up, and send me a patch. :-) */
#undef __attribute__
#define __attribute__(_arg_)
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

#if !defined(dTHR)
#define dTHR extern int errno
#endif

#undef assert
#ifdef OSP_DEBUG

#define assert(what)                                              \
        if (!(what)) {                                                  \
            croak("Assertion failed: file \"%s\", line %d",             \
                __FILE__, __LINE__);                                    \
        }

#define DEBUG_refcnt(a)   if (osp_thr::fetch()->debug & 0x1)  a
#define DEBUG_assign(a)   if (osp_thr::fetch()->debug & 0x2)  a
// 0x4: see txn.h
#define DEBUG_array(a)    if (osp_thr::fetch()->debug & 0x8)  a
#define DEBUG_hash(a)     if (osp_thr::fetch()->debug & 0x10) a
#define DEBUG_set(a)      if (osp_thr::fetch()->debug & 0x20) a
#define DEBUG_cursor(a)   if (osp_thr::fetch()->debug & 0x40) a
#define DEBUG_bless(a)    if (osp_thr::fetch()->debug & 0x80) a
#define DEBUG_root(a)     if (osp_thr::fetch()->debug & 0x100) a
#define DEBUG_splash(a)   if (osp_thr::fetch()->debug & 0x200) a
#define DEBUG_txn(a)      if (osp_thr::fetch()->debug & 0x400) a
#define DEBUG_ref(a)	  if (osp_thr::fetch()->debug & 0x800) a
#define DEBUG_wrap(a)	  if (osp_thr::fetch()->debug & 0x1000) a
#define DEBUG_thread(a)	  if (osp_thr::fetch()->debug & 0x2000) a
#define DEBUG_index(a)	  if (osp_thr::fetch()->debug & 0x4000) a
#define DEBUG_norefs(a)	  if (osp_thr::fetch()->debug & 0x8000) a
#define DEBUG_decode(a)	  if (osp_thr::fetch()->debug & 0x10000) a
//#define DEBUG_schema(a)	  if (osp_thr::fetch()->debug & 0x20000) a
#define DEBUG_pathexam(a) if (osp_thr::fetch()->debug & 0x40000) a
#define DEBUG_compare(a)  if (osp_thr::fetch()->debug & 0x80000) a
#define DEBUG_dynacast(a) if (osp_thr::fetch()->debug & 0x100000) a
#else
#define assert(what)
#define DEBUG_refcnt(a)
#define DEBUG_assign(a)
#define DEBUG_array(a) 
#define DEBUG_hash(a)
#define DEBUG_set(a)
#define DEBUG_cursor(a)
#define DEBUG_bless(a)
#define DEBUG_root(a)
#define DEBUG_splash(a)
#define DEBUG_txn(a)
#define DEBUG_ref(a)
#define DEBUG_wrap(a)
#define DEBUG_thread(a)
#define DEBUG_index(a)
#define DEBUG_norefs(a)
#define DEBUG_decode(a)
//#define DEBUG_schema(a)
#define DEBUG_pathexam(a)
#define DEBUG_compare(a)
#define DEBUG_dynacast(a)
#endif

#endif
