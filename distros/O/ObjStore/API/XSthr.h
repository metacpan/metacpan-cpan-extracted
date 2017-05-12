/*
  Thread Specific Data for Perl Extensions
  ----------------------------------------

  1] Your constructor must return the type (mypackage_thr*).  This
  block will be added to each thread's thread specific array at a
  unique index.  It will be blessed into the given class.

    dXSTHRINIT(mypackage, constr(), "MyPackage::ThreadInfo")


  2] Add XSTHRBOOT to your BOOT section so it can allocate a
  thread specific slot.

  BOOT:
    XSTHRBOOT(mypackage);


  3] To fetch your thread info, use something like this (or make a macro):

  {
    mypackage_thr *mythrinfo;
    XSTHRINFO(mypackage, mythrinfo);
    ...
  }


  4] If you need to do something special upon thread exit (like freeing
  memory), then add a method "MyPackage::ThreadInfo::DESTROY".

  OTOH, when compiled with non-threaded perl the DESTORY method is
  not guarenteed to be called.


  Joshua Pritikin 19980418


TODO:

Graham Barr <gbarr@ti.com> wrote:
I am not sure I like the idea of having to type the package name every
time I need to use one of these macros. As these are intended for use
in an XS file and there are PACKAGE statements in th .xs file, could
xsubpp define a macro (say __XS__PACKAGE__ or something) which could
then be used in these macros ??
 */

#ifndef USE_THREADS
/* Easy, just store a static global pointer to the only instance. */

#  define dXSTHRINIT(PREFIX, constructor, blessto)					\
static PREFIX##_thr *PREFIX##_single = 0;					\
static void *PREFIX##_newthr()							\
{ PREFIX##_single = (PREFIX##_thr*) constructor; return PREFIX##_single; }

#  define XSTHRBOOT(PREFIX) STMT_START {} STMT_END

#  define XSTHRINFO(PREFIX, var) \
var = ((PREFIX##_thr *)(PREFIX##_single ? PREFIX##_single : PREFIX##_newthr()))

#else /*USE_THREADS*/

#  define dXSTHRINIT(PREFIX, constructor, blessto)			\
static int PREFIX##_key = -1;					\
static PREFIX##_thr *PREFIX##_newthr()				\
{								\
  SV *isv;							\
  PREFIX##_thr *info;						\
  dTHR;								\
  assert(PREFIX##_key != -1);					\
  isv = *av_fetch(thr->specific, PREFIX##_key, 1);		\
  info = constructor;						\
  sv_setref_pv(isv, blessto, (void*) info);			\
  SvREFCNT_inc(isv);						\
  return info;							\
}

#  define XSTHRBOOT(PREFIX)					\
  STMT_START {							\
    PUTBACK;							\
    perl_require_pv("Thread/Specific.pm");			\
    if (SvTRUE(ERRSV)) croak(SvPV(ERRSV,na));			\
    SPAGAIN;							\
    PUSHMARK(SP);						\
    XPUSHs(sv_2mortal(newSVpv("Thread::Specific", 16)));	\
    PUTBACK;							\
    items = perl_call_method("key_create", G_SCALAR);		\
    assert(items==1);						\
    SPAGAIN;							\
    PREFIX##_key = POPi;					\
    PUTBACK;							\
  } STMT_END

#  define XSTHRINFO(PREFIX, var)					\
STMT_START {							\
  dTHR;								\
  SV **_info = av_fetch(thr->specific, PREFIX##_key, 0);	\
  if (!_info || !SvOK(*_info)) var = PREFIX##_newthr();		\
  else var = (PREFIX##_thr *)SvIV((SV*)SvRV(*_info));		\
} STMT_END

#endif
