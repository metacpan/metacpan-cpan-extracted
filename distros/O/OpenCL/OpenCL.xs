#include <stddef.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ecb.h"//D

#define X_STACKSIZE sizeof (void *) * 512 * 1024 // 2-4mb should be enough, really
#include "xthread.h"
#include "schmorp.h"

#ifdef I_DLFCN
  #include <dlfcn.h>
#endif

// how stupid is that, the 1.2 header files define CL_VERSION_1_1,
// but then fail to define the api functions unless you ALSO define
// this. This breaks 100% of the opencl 1.1 apps, for what reason?
// after all, the functions are deprecated, not removed.
// in addition, you cannot test for this in any future-proof way.
// each time a new opencl version comes out, you need to make a new
// release.
#define CL_USE_DEPRECATED_OPENCL_1_2_APIS /* just guessing, you stupid idiots */

#ifndef PREFER_1_1
  #define PREFER_1_1 1
#endif

#if PREFER_1_1
  #define CL_USE_DEPRECATED_OPENCL_1_1_APIS
#endif

#ifdef __APPLE__
  #define CLHDR(name) <OpenCL/name>
#else
  #define CLHDR(name) <CL/name>
#endif

#include CLHDR(opencl.h)

#if 0
#ifndef CL_VERSION_1_2
  #include CLHDR(cl_d3d9.h)
#endif
#endif

#if _WIN32
  #include CLHDR(cl_d3d10.h)
  #if CL_VERSION_1_2
    #include CLHDR<cl_d3d11.h>
  #endif
  #include CLHDR<cl_dx9_media_sharing.h.h>
#endif

#ifndef CL_VERSION_1_2
  #undef PREFER_1_1
  #define PREFER_1_1 1
#endif

// make sure all constants we might use are actually defined
#include "default.h"

typedef cl_platform_id   OpenCL__Platform;
typedef cl_device_id     OpenCL__Device;
typedef cl_device_id     OpenCL__SubDevice;
typedef cl_context       OpenCL__Context;
typedef cl_command_queue OpenCL__Queue;
typedef cl_mem           OpenCL__Memory;
typedef cl_mem           OpenCL__Buffer;
typedef cl_mem           OpenCL__BufferObj;
typedef cl_mem           OpenCL__Image;
typedef cl_mem           OpenCL__Memory_ornull;
typedef cl_mem           OpenCL__Buffer_ornull;
typedef cl_mem           OpenCL__Image_ornull;
typedef cl_sampler       OpenCL__Sampler;
typedef cl_program       OpenCL__Program;
typedef cl_kernel        OpenCL__Kernel;
typedef cl_event         OpenCL__Event;
typedef cl_event         OpenCL__UserEvent;

typedef struct mapped *  OpenCL__Mapped;

static HV
   *stash_platform,
   *stash_device,
   *stash_subdevice,
   *stash_context,
   *stash_queue,
   *stash_program,
   *stash_kernel,
   *stash_sampler,
   *stash_event,
   *stash_userevent,
   *stash_memory,
   *stash_buffer,
   *stash_bufferobj,
   *stash_image,
   *stash_image1d,
   *stash_image1darray,
   *stash_image1dbuffer,
   *stash_image2d,
   *stash_image2darray,
   *stash_image3d,
   *stash_mapped,
   *stash_mappedbuffer,
   *stash_mappedimage;

/*****************************************************************************/

// name must include a leading underscore
// all of this horrors would be unneceesary if somebody wrote a proper OpenGL module
// for perl. doh.
static void *
glsym (const char *name)
{
  void *fun = 0;

  #if defined I_DLFCN && defined RTLD_DEFAULT
              fun = dlsym (RTLD_DEFAULT, name + 1);
    if (!fun) fun = dlsym (RTLD_DEFAULT, name);

    if (!fun)
      {
        static void *libgl;
        static const char *glso[] = {
          "libGL.so.1",
          "libGL.so.3",
          "libGL.so.4.0",
          "libGL.so",
          "/usr/lib/libGL.so",
          "/usr/X11R6/lib/libGL.1.dylib"
        };
        int i;

        for (i = 0; !libgl && i < sizeof (glso) / sizeof (glso [0]); ++i)
          {
            libgl = dlopen (glso [i], RTLD_LAZY);
            if (libgl)
              break;
          }

        if (libgl)
          {
                      fun = dlsym (libgl, name + 1);
            if (!fun) fun = dlsym (libgl, name);
          }
      }
  #endif

  return fun;
}

/*****************************************************************************/

/* up to two temporary buffers */
static void * ecb_noinline
tmpbuf (size_t size)
{
  enum { buffers = 4 };
  static int idx;
  static void *buf [buffers];
  static size_t len [buffers];

  idx = (idx + 1) % buffers;

  if (len [idx] < size)
    {
      free (buf [idx]);
      len [idx] = ((size + 31) & ~4095) + 4096 - 32;
      buf [idx] = malloc (len [idx]);
    }

  return buf [idx];
}

static const char * ecb_noinline
cv_get_name (CV *cv)
{
  static char fullname [256];

  GV *gv = CvGV (cv); // gv better be nonzero

  HV *stash = GvSTASH (gv);
  const char *hvname = HvNAME_get (stash); // stash also better be nonzero
  const char *gvname = GvNAME (gv);

  snprintf (fullname, sizeof (fullname), "%s::%s", hvname, gvname);
  return fullname;
}

/*****************************************************************************/

typedef struct
{
  IV iv;
  const char *name;
  #define const_iv(name) { (IV)CL_ ## name, # name },
} ivstr;

typedef struct
{
  NV nv;
  const char *name;
  #define const_nv(name) { (NV)CL_ ## name, # name },
} nvstr;

static const char *
iv2str (IV value, const ivstr *base, int count, const char *fallback)
{
  int i;
  static char strbuf [32];

  for (i = count; i--; )
    if (base [i].iv == value)
      return base [i].name;

  snprintf (strbuf, sizeof (strbuf), fallback, (int)value);

  return strbuf;
}

static const char *
enum2str (cl_uint value)
{
  static const ivstr enumstr[] = {
    #include "enumstr.h"
  };

  return iv2str (value, enumstr, sizeof (enumstr) / sizeof (enumstr [0]), "ENUM(0x%04x)");
}

static const char *
err2str (cl_int err)
{
  static const ivstr errstr[] = {
    #include "errstr.h"
  };

  return iv2str (err, errstr, sizeof (errstr) / sizeof (errstr [0]), "ERROR(%d)");
}

/*****************************************************************************/

static cl_int res;

#define FAIL(name) \
  croak ("cl" # name ": %s", err2str (res));

#define NEED_SUCCESS(name,args) \
  do { \
    res = cl ## name args; \
    \
    if (res) \
      FAIL (name); \
  } while (0)

#define NEED_SUCCESS_ARG(retdecl, name, args) \
  retdecl = cl ## name args; \
  if (res) \
    FAIL (name);

/*****************************************************************************/

static SV *
new_clobj (HV *stash, IV id)
{
  return sv_2mortal (sv_bless (newRV_noinc (newSViv (id)), stash));
}

#define PUSH_CLOBJ(stash,id)  PUSHs  (new_clobj ((stash), (IV)(id)))
#define XPUSH_CLOBJ(stash,id) XPUSHs (new_clobj ((stash), (IV)(id)))

/* cl objects are either \$iv, or [$iv, ...] */
/* they can be upgraded at runtime to the array form */
static void * ecb_noinline
SvCLOBJ (CV *cv, const char *svname, SV *sv, const char *pkg)
{
  // sv_derived_from is quite slow :(
  if (SvROK (sv) && sv_derived_from (sv, pkg))
    return (void *)SvIV (SvRV (sv));

  croak ("%s: %s is not of type %s", cv_get_name (cv), svname, pkg);
}

// the "no-inherit" version of the above
static void * ecb_noinline
SvCLOBJ_ni (CV *cv, const char *svname, SV *sv, HV *stash)
{
  if (SvROK (sv) && SvSTASH (SvRV (sv)) == stash)
    return (void *)SvIV (SvRV (sv));

  croak ("%s: %s is not of type %s", cv_get_name (cv), svname, HvNAME (stash));
}

/*****************************************************************************/

static cl_context_properties * ecb_noinline
SvCONTEXTPROPERTIES (CV *cv, const char *svname, SV *sv, cl_context_properties *extra, int extracount)
{
  if (!sv || !SvOK (sv))
    if (extra)
      sv = sv_2mortal (newRV_noinc ((SV *)newAV ())); // slow, but rarely used hopefully
    else
      return 0;

  if (SvROK (sv) && SvTYPE (SvRV (sv)) == SVt_PVAV)
    {
      AV *av = (AV *)SvRV (sv);
      int i, len = av_len (av) + 1;
      cl_context_properties *p = tmpbuf (sizeof (cl_context_properties) * (len + extracount + 1));
      cl_context_properties *l = p;

      if (len & 1)
        croak ("%s: %s is not a property list (must contain an even number of elements)", cv_get_name (cv), svname);

      while (extracount--)
        *l++ = *extra++;

      for (i = 0; i < len; i += 2)
        {
          cl_context_properties t = SvIV (*av_fetch (av, i    , 0));
          SV *p_sv                =       *av_fetch (av, i + 1, 0);
          cl_context_properties v = SvIV (p_sv); // code below can override

          switch (t)
            {
              case CL_CONTEXT_PLATFORM:
                if (SvROK (p_sv))
                  v = (cl_context_properties)SvCLOBJ (cv, svname, p_sv, "OpenCL::Platform");
                break;

              case CL_GLX_DISPLAY_KHR:
                if (!SvOK (p_sv))
                  {
                    void *func = glsym ("_glXGetCurrentDisplay");
                    if (func)
                      v = (cl_context_properties)((void *(*)(void))func)();
                  }
                break;

              case CL_GL_CONTEXT_KHR:
                if (!SvOK (p_sv))
                  {
                    void *func = glsym ("_glXGetCurrentContext");
                    if (func)
                      v = (cl_context_properties)((void *(*)(void))func)();
                  }
                break;

              default:
                /* unknown property, treat as int */
                break;
            }

          *l++ = t;
          *l++ = v;
        }

      *l = 0;

      return p;
    }

   croak ("%s: %s is not a property list (either undef or [type => value, ...])", cv_get_name (cv), svname);
}

// parse an array of CLOBJ into a void ** array in C - works only for CLOBJs whose representation
// is a pointer (and only on well-behaved systems).
static void * ecb_noinline
object_list (CV *cv, int or_undef, const char *argname, SV *arg, const char *klass, cl_uint *rcount)
{
  if (!SvROK (arg) || SvTYPE (SvRV (arg)) != SVt_PVAV)
    croak ("%s: '%s' parameter must be %sa reference to an array of %s objects",
           cv_get_name (cv), argname, or_undef ? "undef or " : "", klass);

  AV *av = (AV *)SvRV (arg);
  void **list = 0;
  cl_uint count = av_len (av) + 1;

  if (count)
    {
      list = tmpbuf (sizeof (*list) * count);
      int i;
      for (i = 0; i < count; ++i)
        list [i] = SvCLOBJ (cv, argname, *av_fetch (av, i, 1), klass);
    }

  if (!count && !or_undef)
    croak ("%s: '%s' must contain at least one %s object",
           cv_get_name (cv), argname, klass);

  *rcount = count;
  return (void *)list;
}

/*****************************************************************************/
/* callback stuff */

/* default context callback, log to stderr */
static void CL_CALLBACK
context_default_notify (const char *msg, const void *info, size_t cb, void *data)
{
  fprintf (stderr, "OpenCL Context Notify: %s\n", msg);
}

typedef struct
{
  int free_cb;
  void (*push)(void *data1, void *data2, void *data3);
} eq_vtbl;

typedef struct eq_item
{
  struct eq_item *next;
  eq_vtbl *vtbl;
  SV *cb;
  void *data1, *data2, *data3;
} eq_item;

static void (*eq_signal_func)(void *signal_arg, int value);
static void *eq_signal_arg;
static xmutex_t eq_lock = X_MUTEX_INIT;
static eq_item *eq_head, *eq_tail;

static void ecb_noinline
eq_enq (eq_vtbl *vtbl, SV *cb, void *data1, void *data2, void *data3)
{
  eq_item *item = malloc (sizeof (eq_item));

  item->next  = 0;
  item->vtbl  = vtbl;
  item->cb    = cb;
  item->data1 = data1;
  item->data2 = data2;
  item->data3 = data3;

  X_LOCK (eq_lock);

  *(eq_head ? &eq_tail->next : &eq_head) = item;
  eq_tail = item;

  X_UNLOCK (eq_lock);

  eq_signal_func (eq_signal_arg, 0);
}

static eq_item *
eq_dec (void)
{
  eq_item *res;

  X_LOCK (eq_lock);

  res = eq_head;
  if (res)
    eq_head = res->next;

  X_UNLOCK (eq_lock);

  return res;
}

static void
eq_poll (void)
{
  eq_item *item;

  while ((item = eq_dec ()))
    {
      ENTER;
      SAVETMPS;

      dSP;
      PUSHMARK (SP);
      EXTEND (SP, 2);

      if (item->vtbl->free_cb)
        sv_2mortal (item->cb);

      PUTBACK;
      item->vtbl->push (item->data1, item->data2, item->data3);

      SV *cb = item->cb;
      free (item);

      call_sv (cb, G_DISCARD | G_VOID);

      FREETMPS;
      LEAVE;
    }
}

static void
eq_poll_interrupt (pTHX_ void *c_arg, int value)
{
  eq_poll ();
}

/*****************************************************************************/
/* context notify */

static void ecb_noinline
eq_context_push (void *data1, void *data2, void *data3)
{
  dSP;
  PUSHs (sv_2mortal (newSVpv  (data1, 0)));
  PUSHs (sv_2mortal (newSVpvn (data2, (STRLEN)data3)));
  PUTBACK;

  free (data1);
  free (data2);
}

static eq_vtbl eq_context_vtbl = { 0, eq_context_push };

static void CL_CALLBACK
eq_context_notify (const char *msg, const void *pvt, size_t cb, void *user_data)
{
  void *pvt_copy = malloc (cb);
  memcpy (pvt_copy, pvt, cb);
  eq_enq (&eq_context_vtbl, user_data, strdup (msg), pvt_copy, (void *)cb);
}

#define CONTEXT_NOTIFY_CALLBACK \
  void (CL_CALLBACK *pfn_notify)(const char *, const void *, size_t, void *) = context_default_notify; \
  void *user_data = 0; \
  \
  if (SvOK (notify)) \
    { \
      pfn_notify = eq_context_notify; \
      user_data = s_get_cv (notify); \
    }

static SV * ecb_noinline
new_clobj_context (cl_context ctx, void *user_data)
{
  SV *sv = new_clobj (stash_context, (IV)ctx);

  if (user_data)
    sv_magicext (SvRV (sv), user_data, PERL_MAGIC_ext, 0, 0, 0);

  return sv;
}

#define XPUSH_CLOBJ_CONTEXT XPUSHs (new_clobj_context (ctx, user_data));

/*****************************************************************************/
/* build/compile/link notify */

static void
eq_program_push (void *data1, void *data2, void *data3)
{
  dSP;
  PUSH_CLOBJ (stash_program, data1);
  PUTBACK;
}

static eq_vtbl eq_program_vtbl = { 1, eq_program_push };

static void CL_CALLBACK
eq_program_notify (cl_program program, void *user_data)
{
  clRetainProgram (program);

  eq_enq (&eq_program_vtbl, user_data, (void *)program, 0, 0);
}

typedef void (CL_CALLBACK *program_callback)(cl_program program, void *user_data);

static program_callback ecb_noinline
make_program_callback (SV *notify, void **ruser_data)
{
  if (SvOK (notify))
    {
      *ruser_data = SvREFCNT_inc (s_get_cv (notify));
      return eq_program_notify;
    }
  else
    {
      *ruser_data = 0;
      return 0;
    }
}

struct build_args
{
  cl_program program;
  char *options;
  void *user_data;
  cl_uint num_devices;
};

X_THREAD_PROC (build_program_thread)
{
  struct build_args *arg = thr_arg;

  clBuildProgram (arg->program, arg->num_devices, arg->num_devices ? (void *)(arg + 1) : 0, arg->options, 0, 0);
  
  if (arg->user_data)
    eq_program_notify (arg->program, arg->user_data);
  else
    clReleaseProgram (arg->program);

  free (arg->options);
  free (arg);

  return 0;
}

static void
build_program_async (cl_program program, cl_uint num_devices, const cl_device_id *device_list, const char *options, void *user_data)
{
  struct build_args *arg = malloc (sizeof (struct build_args) + sizeof (*device_list) * num_devices);

  arg->program     = program;
  arg->options     = strdup (options);
  arg->user_data   = user_data;
  arg->num_devices = num_devices;
  memcpy (arg + 1, device_list, sizeof (*device_list) * num_devices);

  xthread_t id;
  thread_create (&id, build_program_thread, arg);
}

/*****************************************************************************/
/* mem object destructor notify */

static void ecb_noinline
eq_destructor_push (void *data1, void *data2, void *data3)
{
}

static eq_vtbl eq_destructor_vtbl = { 0, eq_destructor_push };

static void CL_CALLBACK
eq_destructor_notify (cl_mem memobj, void *user_data)
{
  eq_enq (&eq_destructor_vtbl, (SV *)user_data, (void *)memobj, 0, 0);
}

/*****************************************************************************/
/* event objects */

static void
eq_event_push (void *data1, void *data2, void *data3)
{
  dSP;
  PUSH_CLOBJ (stash_event, data1);
  PUSHs (sv_2mortal (newSViv ((IV)data2)));
  PUTBACK;
}

static eq_vtbl eq_event_vtbl = { 1, eq_event_push };

static void CL_CALLBACK
eq_event_notify (cl_event event, cl_int event_command_exec_status, void *user_data)
{
  clRetainEvent (event);
  eq_enq (&eq_event_vtbl, user_data, (void *)event, (void *)(IV)event_command_exec_status, 0);
}

/*****************************************************************************/
/* utilities for XS code */

static size_t
img_row_pitch (cl_mem img)
{
  size_t res;
  clGetImageInfo (img, CL_IMAGE_ROW_PITCH, sizeof (res), &res, 0);
  return res;
}

static cl_event * ecb_noinline
event_list (CV *cv, SV **items, cl_uint *rcount, cl_event extra)
{
  cl_uint count = *rcount;

  if (count > 0x7fffffffU) // yeah, it's a hack - the caller might have underflowed
    *rcount = count = 0;

  if (!count && !extra)
    return 0;

  cl_event *list = tmpbuf (sizeof (cl_event) * (count + 1));
  int i = 0;

  while (count--)
    if (SvOK (items [count]))
      list [i++] = SvCLOBJ (cv, "wait_events", items [count], "OpenCL::Event");

  if (extra)
    list [i++] = extra;

  *rcount = i;

  return i ? list : 0;
}

#define EVENT_LIST(skip) \
  cl_uint event_list_count = items - (skip); \
  cl_event *event_list_ptr = event_list (cv, &ST (skip), &event_list_count, 0)

#define INFO(class) \
{ \
	size_t size; \
	NEED_SUCCESS (Get ## class ## Info, (self, name, 0, 0, &size)); \
        SV *sv = sv_2mortal (newSV (size)); \
        SvUPGRADE (sv, SVt_PV); \
        SvPOK_only (sv); \
        SvCUR_set (sv, size); \
	NEED_SUCCESS (Get ## class ## Info, (self, name, size, SvPVX (sv), 0)); \
        XPUSHs (sv); \
}

/*****************************************************************************/
/* mapped_xxx */

static OpenCL__Mapped
SvMAPPED (SV *sv)
{
  // no typechecking atm., keep your fingers crossed
  return (OpenCL__Mapped)SvMAGIC (SvRV (sv))->mg_ptr;
}

struct mapped
{
  cl_command_queue queue;
  cl_mem memobj;
  void *ptr;
  size_t cb;
  cl_event event;
  size_t row_pitch;
  size_t slice_pitch;

  size_t element_size;
  size_t width, height, depth;
};

static SV *
mapped_new (
  HV *stash, cl_command_queue queue, cl_mem memobj, cl_map_flags flags,
  void *ptr, size_t cb, cl_event ev,
  size_t row_pitch, size_t slice_pitch, size_t element_size,
  size_t width, size_t height, size_t depth
)
{
  SV *data = newSV (0);
  SvUPGRADE (data, SVt_PVMG);

  OpenCL__Mapped mapped;
  New (0, mapped, 1, struct mapped);

  clRetainCommandQueue (queue);

  mapped->queue         = queue;
  mapped->memobj        = memobj;
  mapped->ptr           = ptr;
  mapped->cb            = cb;
  mapped->event         = ev;
  mapped->row_pitch     = row_pitch;
  mapped->slice_pitch   = slice_pitch;

  mapped->element_size  = element_size;
  mapped->width         = width;
  mapped->height        = height;
  mapped->depth         = depth;

  sv_magicext (data, 0, PERL_MAGIC_ext, 0, (char *)mapped, 0);

  if (SvLEN (data))
    Safefree (data);

  SvPVX (data) = (char *)ptr;
  SvCUR_set (data, cb);
  SvLEN_set (data, 0);
  SvPOK_only (data);

  SV *obj = sv_2mortal (sv_bless (newRV_noinc (data), stash));

  if (!(flags & CL_MAP_WRITE))
    SvREADONLY_on (data);

  return obj;
}

static void
mapped_detach (SV *sv, OpenCL__Mapped mapped)
{
  SV *data = SvRV (sv);

  // the next check checks both before AND after detach, where SvPVX should STILL be 0
  if (SvPVX (data) != (char *)mapped->ptr)
    warn ("FATAL: OpenCL memory mapped scalar changed location, detected");
  else
    {
      SvREADONLY_off (data);
      SvCUR_set (data, 0);
      SvPVX (data) = 0;
      SvOK_off (data);
    }

  mapped->ptr = 0;
}

static void
mapped_unmap (CV *cv, SV *self, OpenCL__Mapped mapped, cl_command_queue queue, SV **wait_list, cl_uint event_list_count)
{
  cl_event *event_list_ptr = event_list (cv, wait_list, &event_list_count, mapped->event);
  cl_event ev;

  NEED_SUCCESS (EnqueueUnmapMemObject, (queue, mapped->memobj, mapped->ptr, event_list_count, event_list_ptr, &ev));

  clReleaseEvent (mapped->event);
  mapped->event = ev;

  mapped_detach (self, mapped);
}

static size_t
mapped_element_size (OpenCL__Mapped self)
{
  if (!self->element_size)
    clGetImageInfo (self->memobj, CL_IMAGE_ELEMENT_SIZE, sizeof (self->element_size), &self->element_size, 0);

  return self->element_size;
}

/*****************************************************************************/

MODULE = OpenCL		PACKAGE = OpenCL

PROTOTYPES: ENABLE

void
poll ()
	CODE:
        eq_poll ();

void
_eq_initialise (IV func, IV arg)
	CODE:
        eq_signal_func = (void (*)(void *, int))func;
        eq_signal_arg  = (void*)arg;

BOOT:
{
  HV *stash = gv_stashpv ("OpenCL", 1);

  static const ivstr *civ, const_iv[] = {
    { sizeof (cl_char  ), "SIZEOF_CHAR"   },
    { sizeof (cl_uchar ), "SIZEOF_UCHAR"  },
    { sizeof (cl_short ), "SIZEOF_SHORT"  },
    { sizeof (cl_ushort), "SIZEOF_USHORT" },
    { sizeof (cl_int   ), "SIZEOF_INT"    },
    { sizeof (cl_uint  ), "SIZEOF_UINT"   },
    { sizeof (cl_long  ), "SIZEOF_LONG"   },
    { sizeof (cl_ulong ), "SIZEOF_ULONG"  },
    { sizeof (cl_half  ), "SIZEOF_HALF"   },
    { sizeof (cl_float ), "SIZEOF_FLOAT"  },
    { sizeof (cl_double), "SIZEOF_DOUBLE" },
    { PREFER_1_1        , "PREFER_1_1"    },
#include "constiv.h"
  };

  for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
    newCONSTSUB (stash, (char *)civ[-1].name, newSViv (civ[-1].iv));

  static const nvstr *cnv, const_nv[] = {
#include "constnv.h"
  };

  for (cnv = const_nv + sizeof (const_nv) / sizeof (const_nv [0]); cnv > const_nv; cnv--)
    newCONSTSUB (stash, (char *)cnv[-1].name, newSVnv (cnv[-1].nv));

  newCONSTSUB (stash, "NAN", newSVnv (CL_NAN)); // CL_NAN might be a function call

  stash_platform	= gv_stashpv ("OpenCL::Platform",	GV_ADD);
  stash_device		= gv_stashpv ("OpenCL::Device",		GV_ADD);
  stash_subdevice	= gv_stashpv ("OpenCL::SubDevice",	GV_ADD);
  stash_context		= gv_stashpv ("OpenCL::Context",	GV_ADD);
  stash_queue		= gv_stashpv ("OpenCL::Queue",		GV_ADD);
  stash_program		= gv_stashpv ("OpenCL::Program",	GV_ADD);
  stash_kernel		= gv_stashpv ("OpenCL::Kernel",		GV_ADD);
  stash_sampler		= gv_stashpv ("OpenCL::Sampler",	GV_ADD);
  stash_event		= gv_stashpv ("OpenCL::Event",		GV_ADD);
  stash_userevent	= gv_stashpv ("OpenCL::UserEvent",	GV_ADD);
  stash_memory		= gv_stashpv ("OpenCL::Memory",		GV_ADD);
  stash_buffer		= gv_stashpv ("OpenCL::Buffer",		GV_ADD);
  stash_bufferobj	= gv_stashpv ("OpenCL::BufferObj",	GV_ADD);
  stash_image		= gv_stashpv ("OpenCL::Image",		GV_ADD);
  stash_image1d		= gv_stashpv ("OpenCL::Image1D",	GV_ADD);
  stash_image1darray	= gv_stashpv ("OpenCL::Image1DArray",	GV_ADD);
  stash_image1dbuffer	= gv_stashpv ("OpenCL::Image1DBuffer",	GV_ADD);
  stash_image2d		= gv_stashpv ("OpenCL::Image2D",	GV_ADD);
  stash_image2darray	= gv_stashpv ("OpenCL::Image2DArray",	GV_ADD);
  stash_image3d		= gv_stashpv ("OpenCL::Image3D",	GV_ADD);
  stash_mapped		= gv_stashpv ("OpenCL::Mapped",		GV_ADD);
  stash_mappedbuffer	= gv_stashpv ("OpenCL::MappedBuffer",	GV_ADD);
  stash_mappedimage	= gv_stashpv ("OpenCL::MappedImage",	GV_ADD);

  sv_setiv (perl_get_sv ("OpenCL::POLL_FUNC", TRUE), (IV)eq_poll_interrupt);
}

cl_int
errno ()
	CODE:
        RETVAL = res;
	OUTPUT:
        RETVAL

const char *
err2str (cl_int err = res)

const char *
enum2str (cl_uint value)

void
platforms ()
	PPCODE:
	cl_platform_id *list;
        cl_uint count;
        int i;

	NEED_SUCCESS (GetPlatformIDs, (0, 0, &count));
        list = tmpbuf (sizeof (*list) * count);
	NEED_SUCCESS (GetPlatformIDs, (count, list, 0));

        EXTEND (SP, count);
        for (i = 0; i < count; ++i)
          PUSH_CLOBJ (stash_platform, list [i]);

void
context_from_type (cl_context_properties *properties = 0, cl_device_type type = CL_DEVICE_TYPE_DEFAULT, SV *notify = &PL_sv_undef)
	PPCODE:
        CONTEXT_NOTIFY_CALLBACK;
        NEED_SUCCESS_ARG (cl_context ctx, CreateContextFromType, (properties, type, pfn_notify, user_data, &res));
        XPUSH_CLOBJ_CONTEXT;

void
context (cl_context_properties *properties, SV *devices, SV *notify = &PL_sv_undef)
	PPCODE:
        cl_uint       device_count;
        cl_device_id *device_list = object_list (cv, 0, "devices", devices, "OpenCL::Device", &device_count);

        CONTEXT_NOTIFY_CALLBACK;
	NEED_SUCCESS_ARG (cl_context ctx, CreateContext, (properties, device_count, device_list, pfn_notify, user_data, &res));
        XPUSH_CLOBJ_CONTEXT;

void
wait_for_events (...)
	CODE:
        EVENT_LIST (0);
        NEED_SUCCESS (WaitForEvents, (event_list_count, event_list_ptr));

PROTOTYPES: DISABLE

MODULE = OpenCL		PACKAGE = OpenCL::Platform

void
info (OpenCL::Platform self, cl_platform_info name)
	PPCODE:
        INFO (Platform)

void
unload_compiler (OpenCL::Platform self)
	CODE:
#if CL_VERSION_1_2
        clUnloadPlatformCompiler (self);
#endif

#BEGIN:platform

void
profile (OpenCL::Platform self)
 ALIAS:
 profile = CL_PLATFORM_PROFILE
 version = CL_PLATFORM_VERSION
 name = CL_PLATFORM_NAME
 vendor = CL_PLATFORM_VENDOR
 extensions = CL_PLATFORM_EXTENSIONS
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetPlatformInfo, (self, ix,    0,     0, &size));
 char *value = tmpbuf (size);
 NEED_SUCCESS (GetPlatformInfo, (self, ix, size, value,     0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVpv (value, 0)));

#END:platform

void
devices (OpenCL::Platform self, cl_device_type type = CL_DEVICE_TYPE_ALL)
	PPCODE:
	cl_device_id *list;
        cl_uint count;
        int i;

	NEED_SUCCESS (GetDeviceIDs, (self, type, 0, 0, &count));
        list = tmpbuf (sizeof (*list) * count);
	NEED_SUCCESS (GetDeviceIDs, (self, type, count, list, 0));

        EXTEND (SP, count);
        for (i = 0; i < count; ++i)
          PUSH_CLOBJ (stash_device, list [i]);

void
context (OpenCL::Platform self, SV *properties, SV *devices, SV *notify = &PL_sv_undef)
	PPCODE:
	cl_context_properties extra[] = { CL_CONTEXT_PLATFORM, (cl_context_properties)self };
        cl_context_properties *props = SvCONTEXTPROPERTIES (cv, "properties", properties, extra, 2);

        cl_uint       device_count;
        cl_device_id *device_list = object_list (cv, 0, "devices", devices, "OpenCL::Device", &device_count);

        CONTEXT_NOTIFY_CALLBACK;
	NEED_SUCCESS_ARG (cl_context ctx, CreateContext, (props, device_count, device_list, pfn_notify, user_data, &res));
        XPUSH_CLOBJ_CONTEXT;

void
context_from_type (OpenCL::Platform self, SV *properties = 0, cl_device_type type = CL_DEVICE_TYPE_DEFAULT, SV *notify = &PL_sv_undef)
	PPCODE:
	cl_context_properties extra[] = { CL_CONTEXT_PLATFORM, (cl_context_properties)self };
        cl_context_properties *props = SvCONTEXTPROPERTIES (cv, "properties", properties, extra, 2);

        CONTEXT_NOTIFY_CALLBACK;
        NEED_SUCCESS_ARG (cl_context ctx, CreateContextFromType, (props, type, pfn_notify, user_data, &res));
        XPUSH_CLOBJ_CONTEXT;

MODULE = OpenCL		PACKAGE = OpenCL::Device

void
info (OpenCL::Device self, cl_device_info name)
	PPCODE:
        INFO (Device)

#if CL_VERSION_1_2

void
sub_devices (OpenCL::Device self, SV *properties)
	PPCODE:
        if (!SvROK (properties) || SvTYPE (SvRV (properties)) != SVt_PVAV)
          croak ("OpenCL::Device::sub_devices: properties must be specified as reference to an array of property-value pairs");

        properties = SvRV (properties);

        cl_uint count = av_len ((AV *)properties) + 1;
        cl_device_partition_property *props = tmpbuf (sizeof (*props) * count + 1);

        int i;
        for (i = 0; i < count; ++i)
          props [i] = (cl_device_partition_property)SvIV (*av_fetch ((AV *)properties, i, 0));

        props [count] = 0;

        cl_uint num_devices;
	NEED_SUCCESS (CreateSubDevices, (self, props, 0, 0, &num_devices));
        cl_device_id *list = tmpbuf (sizeof (*list) * num_devices);
	NEED_SUCCESS (CreateSubDevices, (self, props, num_devices, list, 0));

        EXTEND (SP, num_devices);
        for (i = 0; i < count; ++i)
          PUSH_CLOBJ (stash_subdevice, list [i]);

#endif

#BEGIN:device

void
type (OpenCL::Device self)
 ALIAS:
 type = CL_DEVICE_TYPE
 address_bits = CL_DEVICE_ADDRESS_BITS
 max_mem_alloc_size = CL_DEVICE_MAX_MEM_ALLOC_SIZE
 single_fp_config = CL_DEVICE_SINGLE_FP_CONFIG
 global_mem_cache_size = CL_DEVICE_GLOBAL_MEM_CACHE_SIZE
 global_mem_size = CL_DEVICE_GLOBAL_MEM_SIZE
 max_constant_buffer_size = CL_DEVICE_MAX_CONSTANT_BUFFER_SIZE
 local_mem_size = CL_DEVICE_LOCAL_MEM_SIZE
 execution_capabilities = CL_DEVICE_EXECUTION_CAPABILITIES
 properties = CL_DEVICE_QUEUE_PROPERTIES
 double_fp_config = CL_DEVICE_DOUBLE_FP_CONFIG
 half_fp_config = CL_DEVICE_HALF_FP_CONFIG
 PPCODE:
 cl_ulong value [1];
 NEED_SUCCESS (GetDeviceInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
vendor_id (OpenCL::Device self)
 ALIAS:
 vendor_id = CL_DEVICE_VENDOR_ID
 max_compute_units = CL_DEVICE_MAX_COMPUTE_UNITS
 max_work_item_dimensions = CL_DEVICE_MAX_WORK_ITEM_DIMENSIONS
 preferred_vector_width_char = CL_DEVICE_PREFERRED_VECTOR_WIDTH_CHAR
 preferred_vector_width_short = CL_DEVICE_PREFERRED_VECTOR_WIDTH_SHORT
 preferred_vector_width_int = CL_DEVICE_PREFERRED_VECTOR_WIDTH_INT
 preferred_vector_width_long = CL_DEVICE_PREFERRED_VECTOR_WIDTH_LONG
 preferred_vector_width_float = CL_DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT
 preferred_vector_width_double = CL_DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE
 max_clock_frequency = CL_DEVICE_MAX_CLOCK_FREQUENCY
 max_read_image_args = CL_DEVICE_MAX_READ_IMAGE_ARGS
 max_write_image_args = CL_DEVICE_MAX_WRITE_IMAGE_ARGS
 image_support = CL_DEVICE_IMAGE_SUPPORT
 max_samplers = CL_DEVICE_MAX_SAMPLERS
 mem_base_addr_align = CL_DEVICE_MEM_BASE_ADDR_ALIGN
 min_data_type_align_size = CL_DEVICE_MIN_DATA_TYPE_ALIGN_SIZE
 global_mem_cache_type = CL_DEVICE_GLOBAL_MEM_CACHE_TYPE
 global_mem_cacheline_size = CL_DEVICE_GLOBAL_MEM_CACHELINE_SIZE
 max_constant_args = CL_DEVICE_MAX_CONSTANT_ARGS
 local_mem_type = CL_DEVICE_LOCAL_MEM_TYPE
 preferred_vector_width_half = CL_DEVICE_PREFERRED_VECTOR_WIDTH_HALF
 native_vector_width_char = CL_DEVICE_NATIVE_VECTOR_WIDTH_CHAR
 native_vector_width_short = CL_DEVICE_NATIVE_VECTOR_WIDTH_SHORT
 native_vector_width_int = CL_DEVICE_NATIVE_VECTOR_WIDTH_INT
 native_vector_width_long = CL_DEVICE_NATIVE_VECTOR_WIDTH_LONG
 native_vector_width_float = CL_DEVICE_NATIVE_VECTOR_WIDTH_FLOAT
 native_vector_width_double = CL_DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE
 native_vector_width_half = CL_DEVICE_NATIVE_VECTOR_WIDTH_HALF
 reference_count_ext = CL_DEVICE_REFERENCE_COUNT_EXT
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetDeviceInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
max_work_group_size (OpenCL::Device self)
 ALIAS:
 max_work_group_size = CL_DEVICE_MAX_WORK_GROUP_SIZE
 image2d_max_width = CL_DEVICE_IMAGE2D_MAX_WIDTH
 image2d_max_height = CL_DEVICE_IMAGE2D_MAX_HEIGHT
 image3d_max_width = CL_DEVICE_IMAGE3D_MAX_WIDTH
 image3d_max_height = CL_DEVICE_IMAGE3D_MAX_HEIGHT
 image3d_max_depth = CL_DEVICE_IMAGE3D_MAX_DEPTH
 max_parameter_size = CL_DEVICE_MAX_PARAMETER_SIZE
 profiling_timer_resolution = CL_DEVICE_PROFILING_TIMER_RESOLUTION
 PPCODE:
 size_t value [1];
 NEED_SUCCESS (GetDeviceInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
max_work_item_sizes (OpenCL::Device self)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetDeviceInfo, (self, CL_DEVICE_MAX_WORK_ITEM_SIZES,    0,     0, &size));
 size_t *value = tmpbuf (size);
 NEED_SUCCESS (GetDeviceInfo, (self, CL_DEVICE_MAX_WORK_ITEM_SIZES, size, value,     0));
 int i, n = size / sizeof (*value);
 EXTEND (SP, n);
 for (i = 0; i < n; ++i)
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
error_correction_support (OpenCL::Device self)
 ALIAS:
 error_correction_support = CL_DEVICE_ERROR_CORRECTION_SUPPORT
 endian_little = CL_DEVICE_ENDIAN_LITTLE
 available = CL_DEVICE_AVAILABLE
 compiler_available = CL_DEVICE_COMPILER_AVAILABLE
 host_unified_memory = CL_DEVICE_HOST_UNIFIED_MEMORY
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetDeviceInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (value [i] ? &PL_sv_yes : &PL_sv_no));

void
platform (OpenCL::Device self)
 PPCODE:
 cl_platform_id value [1];
 NEED_SUCCESS (GetDeviceInfo, (self, CL_DEVICE_PLATFORM, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSH_CLOBJ (stash_platform, value [i]);

void
name (OpenCL::Device self)
 ALIAS:
 name = CL_DEVICE_NAME
 vendor = CL_DEVICE_VENDOR
 driver_version = CL_DRIVER_VERSION
 profile = CL_DEVICE_PROFILE
 version = CL_DEVICE_VERSION
 extensions = CL_DEVICE_EXTENSIONS
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetDeviceInfo, (self, ix,    0,     0, &size));
 char *value = tmpbuf (size);
 NEED_SUCCESS (GetDeviceInfo, (self, ix, size, value,     0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVpv (value, 0)));

void
parent_device_ext (OpenCL::Device self)
 PPCODE:
 cl_device_id value [1];
 NEED_SUCCESS (GetDeviceInfo, (self, CL_DEVICE_PARENT_DEVICE_EXT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSH_CLOBJ (stash_device, value [i]);

void
partition_types_ext (OpenCL::Device self)
 ALIAS:
 partition_types_ext = CL_DEVICE_PARTITION_TYPES_EXT
 affinity_domains_ext = CL_DEVICE_AFFINITY_DOMAINS_EXT
 partition_style_ext = CL_DEVICE_PARTITION_STYLE_EXT
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetDeviceInfo, (self, ix,    0,     0, &size));
 cl_device_partition_property_ext *value = tmpbuf (size);
 NEED_SUCCESS (GetDeviceInfo, (self, ix, size, value,     0));
 int i, n = size / sizeof (*value);
 EXTEND (SP, n);
 for (i = 0; i < n; ++i)
 PUSHs (sv_2mortal (newSVuv (value [i])));

#END:device

MODULE = OpenCL		PACKAGE = OpenCL::SubDevice

#if CL_VERSION_1_2

void
DESTROY (OpenCL::SubDevice self)
	CODE:
        clReleaseDevice (self);

#endif

MODULE = OpenCL		PACKAGE = OpenCL::Context

void
DESTROY (OpenCL::Context self)
	CODE:
        clReleaseContext (self);

void
info (OpenCL::Context self, cl_context_info name)
	PPCODE:
        INFO (Context)

void
queue (OpenCL::Context self, OpenCL::Device device, cl_command_queue_properties properties = 0)
	PPCODE:
	NEED_SUCCESS_ARG (cl_command_queue queue, CreateCommandQueue, (self, device, properties, &res));
        XPUSH_CLOBJ (stash_queue, queue);

void
user_event (OpenCL::Context self)
	PPCODE:
	NEED_SUCCESS_ARG (cl_event ev, CreateUserEvent, (self, &res));
        XPUSH_CLOBJ (stash_userevent, ev);

void
buffer (OpenCL::Context self, cl_mem_flags flags, size_t len)
	PPCODE:
        if (flags & (CL_MEM_USE_HOST_PTR | CL_MEM_COPY_HOST_PTR))
          croak ("OpenCL::Context::buffer: cannot use/copy host ptr when no data is given, use $context->buffer_sv instead?");
        
        NEED_SUCCESS_ARG (cl_mem mem, CreateBuffer, (self, flags, len, 0, &res));
        XPUSH_CLOBJ (stash_bufferobj, mem);

void
buffer_sv (OpenCL::Context self, cl_mem_flags flags, SV *data)
	PPCODE:
	STRLEN len;
        char *ptr = SvOK (data) ? SvPVbyte (data, len) : 0;
        if (!(flags & (CL_MEM_USE_HOST_PTR | CL_MEM_COPY_HOST_PTR)))
          croak ("OpenCL::Context::buffer_sv: you have to specify use or copy host ptr when buffer data is given, use $context->buffer instead?");
        NEED_SUCCESS_ARG (cl_mem mem, CreateBuffer, (self, flags, len, ptr, &res));
        XPUSH_CLOBJ (stash_bufferobj, mem);

#if CL_VERSION_1_2

void
image (OpenCL::Context self, cl_mem_flags flags, cl_channel_order channel_order, cl_channel_type channel_type, cl_mem_object_type type, size_t width, size_t height, size_t depth = 0, size_t array_size = 0, size_t row_pitch = 0, size_t slice_pitch = 0, cl_uint num_mip_level = 0, cl_uint num_samples = 0, SV *data = &PL_sv_undef)
	PPCODE:
	STRLEN len;
        char *ptr = SvOK (data) ? SvPVbyte (data, len) : 0;
        const cl_image_format format = { channel_order, channel_type };
        const cl_image_desc desc = {
          type,
          width, height, depth,
          array_size, row_pitch, slice_pitch,
          num_mip_level, num_samples,
	  type == CL_MEM_OBJECT_IMAGE1D_BUFFER ? (cl_mem)SvCLOBJ (cv, "data", data, "OpenCL::Buffer") : 0
        };
	NEED_SUCCESS_ARG (cl_mem mem, CreateImage, (self, flags, &format, &desc, ptr, &res));
        HV *stash = stash_image;
        switch (type)
          {
            case CL_MEM_OBJECT_IMAGE1D_BUFFER:	stash = stash_image1dbuffer; break;
            case CL_MEM_OBJECT_IMAGE1D:		stash = stash_image1d;       break;
            case CL_MEM_OBJECT_IMAGE1D_ARRAY:	stash = stash_image2darray;  break;
            case CL_MEM_OBJECT_IMAGE2D:		stash = stash_image2d;       break;
            case CL_MEM_OBJECT_IMAGE2D_ARRAY:	stash = stash_image2darray;  break;
            case CL_MEM_OBJECT_IMAGE3D:		stash = stash_image3d;       break;
          }
        XPUSH_CLOBJ (stash, mem);

#endif

void
image2d (OpenCL::Context self, cl_mem_flags flags, cl_channel_order channel_order, cl_channel_type channel_type, size_t width, size_t height, size_t row_pitch = 0, SV *data = &PL_sv_undef)
	PPCODE:
	STRLEN len;
        char *ptr = SvOK (data) ? SvPVbyte (data, len) : 0;
        const cl_image_format format = { channel_order, channel_type };
#if PREFER_1_1
	NEED_SUCCESS_ARG (cl_mem mem, CreateImage2D, (self, flags, &format, width, height, row_pitch, ptr, &res));
#else
        const cl_image_desc desc = { CL_MEM_OBJECT_IMAGE2D, width, height, 0, 0, row_pitch, 0, 0, 0, 0 };
	NEED_SUCCESS_ARG (cl_mem mem, CreateImage, (self, flags, &format, &desc, ptr, &res));
#endif
        XPUSH_CLOBJ (stash_image2d, mem);

void
image3d (OpenCL::Context self, cl_mem_flags flags, cl_channel_order channel_order, cl_channel_type channel_type, size_t width, size_t height, size_t depth, size_t row_pitch = 0, size_t slice_pitch = 0, SV *data = &PL_sv_undef)
	PPCODE:
	STRLEN len;
        char *ptr = SvOK (data) ? SvPVbyte (data, len) : 0;
        const cl_image_format format = { channel_order, channel_type };
#if PREFER_1_1
	NEED_SUCCESS_ARG (cl_mem mem, CreateImage3D, (self, flags, &format, width, height, depth, row_pitch, slice_pitch, ptr, &res));
#else
        const cl_image_desc desc = { CL_MEM_OBJECT_IMAGE3D, width, height, depth, 0, row_pitch, slice_pitch, 0, 0, 0 };
	NEED_SUCCESS_ARG (cl_mem mem, CreateImage, (self, flags, &format, &desc, ptr, &res));
#endif
        XPUSH_CLOBJ (stash_image3d, mem);

#if cl_apple_gl_sharing || cl_khr_gl_sharing

void
gl_buffer (OpenCL::Context self, cl_mem_flags flags, cl_GLuint bufobj)
	PPCODE:
        NEED_SUCCESS_ARG (cl_mem mem, CreateFromGLBuffer, (self, flags, bufobj, &res));
        XPUSH_CLOBJ (stash_bufferobj, mem);

void
gl_renderbuffer (OpenCL::Context self, cl_mem_flags flags, cl_GLuint renderbuffer)
	PPCODE:
	NEED_SUCCESS_ARG (cl_mem mem, CreateFromGLRenderbuffer, (self, flags, renderbuffer, &res));
        XPUSH_CLOBJ (stash_image2d, mem);

#if CL_VERSION_1_2

void
gl_texture (OpenCL::Context self, cl_mem_flags flags, cl_GLenum target, cl_GLint miplevel, cl_GLuint texture)
	ALIAS:
	PPCODE:
	NEED_SUCCESS_ARG (cl_mem mem, CreateFromGLTexture, (self, flags, target, miplevel, texture, &res));
        cl_gl_object_type type;
	NEED_SUCCESS (GetGLObjectInfo, (mem, &type, 0)); // TODO: use target instead?
        HV *stash = stash_memory;
        switch (type)
          {
            case CL_GL_OBJECT_TEXTURE_BUFFER:	stash = stash_image1dbuffer; break;
            case CL_GL_OBJECT_TEXTURE1D:	stash = stash_image1d;       break;
            case CL_GL_OBJECT_TEXTURE1D_ARRAY:	stash = stash_image2darray;  break;
            case CL_GL_OBJECT_TEXTURE2D:	stash = stash_image2d;       break;
            case CL_GL_OBJECT_TEXTURE2D_ARRAY:	stash = stash_image2darray;  break;
            case CL_GL_OBJECT_TEXTURE3D:	stash = stash_image3d;       break;
          }
        XPUSH_CLOBJ (stash, mem);

#endif

void
gl_texture2d (OpenCL::Context self, cl_mem_flags flags, cl_GLenum target, cl_GLint miplevel, cl_GLuint texture)
	PPCODE:
#if PREFER_1_1
	NEED_SUCCESS_ARG (cl_mem mem, CreateFromGLTexture2D, (self, flags, target, miplevel, texture, &res));
#else
	NEED_SUCCESS_ARG (cl_mem mem, CreateFromGLTexture  , (self, flags, target, miplevel, texture, &res));
#endif
        XPUSH_CLOBJ (stash_image2d, mem);

void
gl_texture3d (OpenCL::Context self, cl_mem_flags flags, cl_GLenum target, cl_GLint miplevel, cl_GLuint texture)
	PPCODE:
#if PREFER_1_1
	NEED_SUCCESS_ARG (cl_mem mem, CreateFromGLTexture3D, (self, flags, target, miplevel, texture, &res));
#else
	NEED_SUCCESS_ARG (cl_mem mem, CreateFromGLTexture  , (self, flags, target, miplevel, texture, &res));
#endif
        XPUSH_CLOBJ (stash_image3d, mem);

#endif

void
supported_image_formats (OpenCL::Context self, cl_mem_flags flags, cl_mem_object_type image_type)
	PPCODE:
{
	cl_uint count;
        cl_image_format *list;
        int i;
 
	NEED_SUCCESS (GetSupportedImageFormats, (self, flags, image_type, 0, 0, &count));
        Newx (list, count, cl_image_format);
	NEED_SUCCESS (GetSupportedImageFormats, (self, flags, image_type, count, list, 0));

        EXTEND (SP, count);
        for (i = 0; i < count; ++i)
          {
            AV *av = newAV ();
            av_store (av, 1, newSVuv (list [i].image_channel_data_type));
            av_store (av, 0, newSVuv (list [i].image_channel_order));
            PUSHs (sv_2mortal (newRV_noinc ((SV *)av)));
          }
}

void
sampler (OpenCL::Context self, cl_bool normalized_coords, cl_addressing_mode addressing_mode, cl_filter_mode filter_mode)
	PPCODE:
	NEED_SUCCESS_ARG (cl_sampler sampler, CreateSampler, (self, normalized_coords, addressing_mode, filter_mode, &res));
        XPUSH_CLOBJ (stash_sampler, sampler);

void
program_with_source (OpenCL::Context self, SV *program)
	PPCODE:
	STRLEN len;
        size_t len2;
        const char *ptr = SvPVbyte (program, len);
        
        len2 = len;
	NEED_SUCCESS_ARG (cl_program prog, CreateProgramWithSource, (self, 1, &ptr, &len2, &res));
        XPUSH_CLOBJ (stash_program, prog);

void
program_with_binary (OpenCL::Context self, SV *devices, SV *binaries)
	PPCODE:
        cl_uint       device_count;
        cl_device_id *device_list = object_list (cv, 0, "devices", devices, "OpenCL::Device", &device_count);

        if (!SvROK (binaries) || SvTYPE (SvRV (binaries)) != SVt_PVAV)
          croak ("OpenCL::Context::program_with_binary: binaries must be specified as reference to an array of strings");

        binaries = SvRV (binaries);

        if (device_count != av_len ((AV *)binaries) + 1)
          croak ("OpenCL::Context::program_with_binary: differing numbers of devices and binaries are not allowed");

        size_t               *length_list = tmpbuf (sizeof (*length_list) * device_count);
        const unsigned char **binary_list = tmpbuf (sizeof (*binary_list) * device_count);
        cl_int               *status_list = tmpbuf (sizeof (*status_list) * device_count);

        int i;
        for (i = 0; i < device_count; ++i)
          {
	    STRLEN len;
            binary_list [i] = (const unsigned char *)SvPVbyte (*av_fetch ((AV *)binaries, i, 0), len);
            length_list [i] = len;
          }

	NEED_SUCCESS_ARG (cl_program prog, CreateProgramWithBinary, (self, device_count, device_list,
                                                                     length_list, binary_list,
                                                                     GIMME_V == G_ARRAY ? status_list : 0, &res));

        EXTEND (SP, 2);
        PUSH_CLOBJ (stash_program, prog);

        if (GIMME_V == G_ARRAY)
          {
            AV *av = newAV ();
            PUSHs (sv_2mortal (newRV_noinc ((SV *)av)));

            for (i = device_count; i--; )
              av_store (av, i, newSViv (status_list [i]));
          }

#if CL_VERSION_1_2

void
program_with_built_in_kernels (OpenCL::Context self, SV *devices, SV *kernel_names)
	PPCODE:
        cl_uint       device_count;
        cl_device_id *device_list = object_list (cv, 0, "devices", devices, "OpenCL::Device", &device_count);

	NEED_SUCCESS_ARG (cl_program prog, CreateProgramWithBuiltInKernels, (self, device_count, device_list, SvPVbyte_nolen (kernel_names), &res));

        XPUSH_CLOBJ (stash_program, prog);

void
link_program (OpenCL::Context self, SV *devices, SV *options, SV *programs, SV *notify = &PL_sv_undef)
	CODE:
        cl_uint       device_count = 0;
        cl_device_id *device_list  = 0;

        if (SvOK (devices))
          device_list = object_list (cv, 1, "devices", devices, "OpenCL::Device", &device_count);

        cl_uint      program_count;
        cl_program  *program_list = object_list (cv, 0, "programs", programs, "OpenCL::Program", &program_count);

        void *user_data;
        program_callback pfn_notify = make_program_callback (notify, &user_data);

        NEED_SUCCESS_ARG (cl_program prog, LinkProgram, (self, device_count, device_list, SvPVbyte_nolen (options),
                                                         program_count, program_list, pfn_notify, user_data, &res));

        XPUSH_CLOBJ (stash_program, prog);

#endif

#BEGIN:context

void
reference_count (OpenCL::Context self)
 ALIAS:
 reference_count = CL_CONTEXT_REFERENCE_COUNT
 num_devices = CL_CONTEXT_NUM_DEVICES
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetContextInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
devices (OpenCL::Context self)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetContextInfo, (self, CL_CONTEXT_DEVICES,    0,     0, &size));
 cl_device_id *value = tmpbuf (size);
 NEED_SUCCESS (GetContextInfo, (self, CL_CONTEXT_DEVICES, size, value,     0));
 int i, n = size / sizeof (*value);
 EXTEND (SP, n);
 for (i = 0; i < n; ++i)
 PUSH_CLOBJ (stash_device, value [i]);

void
properties (OpenCL::Context self)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetContextInfo, (self, CL_CONTEXT_PROPERTIES,    0,     0, &size));
 cl_context_properties *value = tmpbuf (size);
 NEED_SUCCESS (GetContextInfo, (self, CL_CONTEXT_PROPERTIES, size, value,     0));
 int i, n = size / sizeof (*value);
 EXTEND (SP, n);
 for (i = 0; i < n; ++i)
 PUSHs (sv_2mortal (newSVuv ((UV)value [i])));

#END:context

MODULE = OpenCL		PACKAGE = OpenCL::Queue

void
DESTROY (OpenCL::Queue self)
	CODE:
        clReleaseCommandQueue (self);

void
read_buffer (OpenCL::Queue self, OpenCL::Buffer mem, cl_bool blocking, size_t offset, size_t len, SV *data, ...)
	ALIAS:
	enqueue_read_buffer = 0
	PPCODE:
        EVENT_LIST (6);

        SvUPGRADE (data, SVt_PV);
        SvGROW (data, len);
        SvPOK_only (data);
        SvCUR_set (data, len);

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueReadBuffer, (self, mem, blocking, offset, len, SvPVX (data), event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
write_buffer (OpenCL::Queue self, OpenCL::Buffer mem, cl_bool blocking, size_t offset, SV *data, ...)
	ALIAS:
	enqueue_write_buffer = 0
	PPCODE:
        EVENT_LIST (5);

	STRLEN len;
        char *ptr = SvPVbyte (data, len);

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueWriteBuffer, (self, mem, blocking, offset, len, ptr, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

#if CL_VERSION_1_2

void
fill_buffer (OpenCL::Queue self, OpenCL::Buffer mem, SV *data, size_t offset, size_t size, ...)
	ALIAS:
	enqueue_fill_buffer = 0
	PPCODE:
        EVENT_LIST (5);

	STRLEN len;
        char *ptr = SvPVbyte (data, len);

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueFillBuffer, (self, mem, ptr, len, offset, size, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
fill_image (OpenCL::Queue self, OpenCL::Image img, NV r, NV g, NV b, NV a, size_t x, size_t y, size_t z, size_t width, size_t height, size_t depth, ...)
	ALIAS:
	enqueue_fill_image = 0
	PPCODE:
        EVENT_LIST (12);

        const size_t origin [3] = { x, y, z };
        const size_t region [3] = { width, height, depth };

        const cl_float c_f [4] = { r, g, b, a };
        const cl_uint  c_u [4] = { r, g, b, a };
        const cl_int   c_s [4] = { r, g, b, a };
        const void *c_fus [3] = { &c_f, &c_u, &c_s };
        static const char fus [] = { 0, 0, 0, 0, 0, 0, 0, 2, 2, 2, 1, 1, 1, 0, 0 };
	cl_image_format format;
        NEED_SUCCESS (GetImageInfo, (img, CL_IMAGE_FORMAT, sizeof (format), &format, 0));
        assert (sizeof (fus) == CL_FLOAT + 1 - CL_SNORM_INT8);
        if (format.image_channel_data_type < CL_SNORM_INT8 || CL_FLOAT < format.image_channel_data_type)
          croak ("enqueue_fill_image: image has unsupported channel type, only opencl 1.2 channel types supported.");

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueFillImage, (self, img, c_fus [fus [format.image_channel_data_type - CL_SNORM_INT8]],
                                         origin, region, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

#endif

void
copy_buffer (OpenCL::Queue self, OpenCL::Buffer src, OpenCL::Buffer dst, size_t src_offset, size_t dst_offset, size_t len, ...)
	ALIAS:
	enqueue_copy_buffer = 0
	PPCODE:
        EVENT_LIST (6);

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueCopyBuffer, (self, src, dst, src_offset, dst_offset, len, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
read_buffer_rect (OpenCL::Queue self, OpenCL::Memory buf, cl_bool blocking, size_t buf_x, size_t buf_y, size_t buf_z, size_t host_x, size_t host_y, size_t host_z, size_t width, size_t height, size_t depth, size_t buf_row_pitch, size_t buf_slice_pitch, size_t host_row_pitch, size_t host_slice_pitch, SV *data, ...)
	ALIAS:
	enqueue_read_buffer_rect = 0
	PPCODE:
        EVENT_LIST (17);

        const size_t buf_origin [3] = { buf_x , buf_y , buf_z  };
        const size_t host_origin[3] = { host_x, host_y, host_z };
        const size_t region[3] = { width, height, depth };

        if (!buf_row_pitch)
          buf_row_pitch = region [0];

        if (!buf_slice_pitch)
          buf_slice_pitch = region [1] * buf_row_pitch;

        if (!host_row_pitch)
          host_row_pitch = region [0];

        if (!host_slice_pitch)
          host_slice_pitch = region [1] * host_row_pitch;

        size_t len = host_row_pitch * host_slice_pitch * region [2];

        SvUPGRADE (data, SVt_PV);
        SvGROW (data, len);
        SvPOK_only (data);
        SvCUR_set (data, len);

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueReadBufferRect, (self, buf, blocking, buf_origin, host_origin, region, buf_row_pitch, buf_slice_pitch, host_row_pitch, host_slice_pitch, SvPVX (data), event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
write_buffer_rect (OpenCL::Queue self, OpenCL::Memory buf, cl_bool blocking, size_t buf_x, size_t buf_y, size_t buf_z, size_t host_x, size_t host_y, size_t host_z, size_t width, size_t height, size_t depth, size_t buf_row_pitch, size_t buf_slice_pitch, size_t host_row_pitch, size_t host_slice_pitch, SV *data, ...)
	ALIAS:
	enqueue_write_buffer_rect = 0
	PPCODE:
        EVENT_LIST (17);

        const size_t buf_origin [3] = { buf_x , buf_y , buf_z  };
        const size_t host_origin[3] = { host_x, host_y, host_z };
        const size_t region[3] = { width, height, depth };
	STRLEN len;
        char *ptr = SvPVbyte (data, len);

        if (!buf_row_pitch)
          buf_row_pitch = region [0];

        if (!buf_slice_pitch)
          buf_slice_pitch = region [1] * buf_row_pitch;

        if (!host_row_pitch)
          host_row_pitch = region [0];

        if (!host_slice_pitch)
          host_slice_pitch = region [1] * host_row_pitch;

        size_t min_len = host_row_pitch * host_slice_pitch * region [2];

        if (len < min_len)
          croak ("clEnqueueWriteImage: data string is shorter than what would be transferred");

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueWriteBufferRect, (self, buf, blocking, buf_origin, host_origin, region, buf_row_pitch, buf_slice_pitch, host_row_pitch, host_slice_pitch, ptr, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
copy_buffer_rect (OpenCL::Queue self, OpenCL::Buffer src, OpenCL::Buffer dst, size_t src_x, size_t src_y, size_t src_z, size_t dst_x, size_t dst_y, size_t dst_z, size_t width, size_t height, size_t depth, size_t src_row_pitch, size_t src_slice_pitch, size_t dst_row_pitch, size_t dst_slice_pitch, ...)
	ALIAS:
	enqueue_copy_buffer_rect = 0
	PPCODE:
        EVENT_LIST (16);

        const size_t src_origin[3] = { src_x, src_y, src_z };
        const size_t dst_origin[3] = { dst_x, dst_y, dst_z };
        const size_t region[3] = { width, height, depth };

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueCopyBufferRect, (self, src, dst, src_origin, dst_origin, region, src_row_pitch, src_slice_pitch, dst_row_pitch, dst_slice_pitch, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
read_image (OpenCL::Queue self, OpenCL::Image src, cl_bool blocking, size_t src_x, size_t src_y, size_t src_z, size_t width, size_t height, size_t depth, size_t row_pitch, size_t slice_pitch, SV *data, ...)
	ALIAS:
	enqueue_read_image = 0
	PPCODE:
        EVENT_LIST (12);

        const size_t src_origin[3] = { src_x, src_y, src_z };
        const size_t region[3] = { width, height, depth };

	if (!row_pitch)
	  row_pitch = img_row_pitch (src);

        if (depth > 1 && !slice_pitch)
          slice_pitch = row_pitch * height;

        size_t len = slice_pitch ? slice_pitch * depth : row_pitch * height;

        SvUPGRADE (data, SVt_PV);
        SvGROW (data, len);
        SvPOK_only (data);
        SvCUR_set (data, len);

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueReadImage, (self, src, blocking, src_origin, region, row_pitch, slice_pitch, SvPVX (data), event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
write_image (OpenCL::Queue self, OpenCL::Image dst, cl_bool blocking, size_t dst_x, size_t dst_y, size_t dst_z, size_t width, size_t height, size_t depth, size_t row_pitch, size_t slice_pitch, SV *data, ...)
	ALIAS:
	enqueue_write_image = 0
	PPCODE:
        EVENT_LIST (12);

        const size_t dst_origin[3] = { dst_x, dst_y, dst_z };
        const size_t region[3] = { width, height, depth };
	STRLEN len;
        char *ptr = SvPVbyte (data, len);

	if (!row_pitch)
	  row_pitch = img_row_pitch (dst);

        if (depth > 1 && !slice_pitch)
          slice_pitch = row_pitch * height;

        size_t min_len = slice_pitch ? slice_pitch * depth : row_pitch * height;

        if (len < min_len)
          croak ("clEnqueueWriteImage: data string is shorter than what would be transferred");

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueWriteImage, (self, dst, blocking, dst_origin, region, row_pitch, slice_pitch, ptr, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
copy_image (OpenCL::Queue self, OpenCL::Image src, OpenCL::Image dst, size_t src_x, size_t src_y, size_t src_z, size_t dst_x, size_t dst_y, size_t dst_z, size_t width, size_t height, size_t depth, ...)
	ALIAS:
	enqueue_copy_image = 0
	PPCODE:
        EVENT_LIST (12);

        const size_t src_origin[3] = { src_x, src_y, src_z };
        const size_t dst_origin[3] = { dst_x, dst_y, dst_z };
        const size_t region[3] = { width, height, depth };

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueCopyImage, (self, src, dst, src_origin, dst_origin, region, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
copy_image_to_buffer (OpenCL::Queue self, OpenCL::Image src, OpenCL::Buffer dst, size_t src_x, size_t src_y, size_t src_z, size_t width, size_t height, size_t depth, size_t dst_offset, ...)
	ALIAS:
	enqueue_copy_image_to_buffer = 0
	PPCODE:
        EVENT_LIST (10);

        const size_t src_origin[3] = { src_x,  src_y, src_z };
        const size_t region    [3] = { width, height, depth };

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueCopyImageToBuffer, (self, src, dst, src_origin, region, dst_offset, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
copy_buffer_to_image (OpenCL::Queue self, OpenCL::Buffer src, OpenCL::Image dst, size_t src_offset, size_t dst_x, size_t dst_y, size_t dst_z, size_t width, size_t height, size_t depth, ...)
	ALIAS:
	enqueue_copy_buffer_to_image = 0
	PPCODE:
        EVENT_LIST (10);

        const size_t dst_origin[3] = { dst_x,  dst_y, dst_z };
        const size_t region    [3] = { width, height, depth };

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueCopyBufferToImage, (self, src, dst, src_offset, dst_origin, region, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
map_buffer (OpenCL::Queue self, OpenCL::Buffer buf, cl_bool blocking = 1, cl_map_flags map_flags = CL_MAP_READ | CL_MAP_WRITE, size_t offset = 0, SV *cb_ = &PL_sv_undef, ...)
	ALIAS:
        enqueue_map_buffer = 0
        PPCODE:
        EVENT_LIST (6);

        size_t cb = SvIV (cb_);

        if (!SvOK (cb_))
          {
            NEED_SUCCESS (GetMemObjectInfo, (buf, CL_MEM_SIZE, sizeof (cb), &cb, 0));
            cb -= offset;
          }

	cl_event ev;
        NEED_SUCCESS_ARG (void *ptr, EnqueueMapBuffer, (self, buf, blocking, map_flags, offset, cb, event_list_count, event_list_ptr, &ev, &res));
        XPUSHs (mapped_new (stash_mappedbuffer, self, buf, map_flags, ptr, cb, ev, 0, 0, 1, cb, 1, 1));

void
map_image (OpenCL::Queue self, OpenCL::Image img, cl_bool blocking = 1, cl_map_flags map_flags = CL_MAP_READ | CL_MAP_WRITE, size_t x = 0, size_t y = 0, size_t z = 0, SV *width_ = &PL_sv_undef, SV *height_ = &PL_sv_undef, SV *depth_ = &PL_sv_undef, ...)
	ALIAS:
        enqueue_map_image = 0
        PPCODE:
        size_t width = SvIV (width_);
        if (!SvOK (width_))
          {
            NEED_SUCCESS (GetImageInfo, (img, CL_IMAGE_WIDTH, sizeof (width), &width, 0));
            width -= x;
          }

        size_t height = SvIV (width_);
        if (!SvOK (height_))
          {
            NEED_SUCCESS (GetImageInfo, (img, CL_IMAGE_HEIGHT, sizeof (height), &height, 0));
            height -= y;

            // stupid opencl returns 0 for depth, but requires 1 for 2d images
            if (!height)
              height = 1;
          }

        size_t depth = SvIV (width_);
        if (!SvOK (depth_))
          {
            NEED_SUCCESS (GetImageInfo, (img, CL_IMAGE_DEPTH, sizeof (depth), &depth, 0));
            depth -= z;

            // stupid opencl returns 0 for depth, but requires 1 for 2d images
            if (!depth)
              depth = 1;
          }

        const size_t origin[3] = {     x,      y,     z };
        const size_t region[3] = { width, height, depth };
        size_t row_pitch, slice_pitch;
        EVENT_LIST (10);

	cl_event ev;
        NEED_SUCCESS_ARG (void *ptr, EnqueueMapImage, (self, img, blocking, map_flags, origin, region, &row_pitch, &slice_pitch, event_list_count, event_list_ptr, &ev, &res));

        size_t cb = slice_pitch ? slice_pitch * region [2]
                  : row_pitch   ? row_pitch   * region [1]
                                :               region [0];

        XPUSHs (mapped_new (stash_mappedimage, self, img, map_flags, ptr, cb, ev, row_pitch, slice_pitch, 0, width, height, depth));

void
unmap (OpenCL::Queue self, OpenCL::Mapped mapped, ...)
	PPCODE:
        mapped_unmap (cv, ST (1), mapped, self, &ST (2), items - 2);
        if (GIMME_V != G_VOID)
	  {
            clRetainEvent (mapped->event);
            XPUSH_CLOBJ (stash_event, mapped->event);
          }

void
task (OpenCL::Queue self, OpenCL::Kernel kernel, ...)
	ALIAS:
	enqueue_task = 0
	PPCODE:
        EVENT_LIST (2);

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueTask, (self, kernel, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
nd_range_kernel (OpenCL::Queue self, OpenCL::Kernel kernel, SV *global_work_offset, SV *global_work_size, SV *local_work_size = &PL_sv_undef, ...)
	ALIAS:
	enqueue_nd_range_kernel = 0
	PPCODE:
        EVENT_LIST (5);

        size_t *gwo = 0, *gws, *lws = 0;
        int gws_len;
        size_t *lists;
        int i;

        if (!SvROK (global_work_size) || SvTYPE (SvRV (global_work_size)) != SVt_PVAV)
          croak ("clEnqueueNDRangeKernel: global_work_size must be an array reference");

        gws_len = AvFILLp (SvRV (global_work_size)) + 1;

        lists = tmpbuf (sizeof (size_t) * 3 * gws_len);

        gws = lists + gws_len * 0;
        for (i = 0; i < gws_len; ++i)
          {
            gws [i] = SvIV (AvARRAY (SvRV (global_work_size))[i]);
            // at least nvidia crashes for 0-sized work group sizes, work around
            if (!gws [i])
              croak ("clEnqueueNDRangeKernel: global_work_size[%d] is zero, must be non-zero", i);
          }

        if (SvOK (global_work_offset))
          {
            if (!SvROK (global_work_offset) || SvTYPE (SvRV (global_work_offset)) != SVt_PVAV)
              croak ("clEnqueueNDRangeKernel: global_work_offset must be undef or an array reference");

            if (AvFILLp (SvRV (global_work_size)) + 1 != gws_len)
              croak ("clEnqueueNDRangeKernel: global_work_offset must be undef or an array of same size as global_work_size");

            gwo = lists + gws_len * 1;
            for (i = 0; i < gws_len; ++i)
              gwo [i] = SvIV (AvARRAY (SvRV (global_work_offset))[i]);
          }

        if (SvOK (local_work_size))
          {
            if ((SvOK (local_work_size) && !SvROK (local_work_size)) || SvTYPE (SvRV (local_work_size)) != SVt_PVAV)
              croak ("clEnqueueNDRangeKernel: local_work_size must be undef or an array reference");

            if (AvFILLp (SvRV (local_work_size)) + 1 != gws_len)
              croak ("clEnqueueNDRangeKernel: local_work_local must be undef or an array of same size as global_work_size");

            lws = lists + gws_len * 2;
            for (i = 0; i < gws_len; ++i)
              {
                lws [i] = SvIV (AvARRAY (SvRV (local_work_size))[i]);
                // at least nvidia crashes for 0-sized work group sizes, work around
                if (!lws [i])
                  croak ("clEnqueueNDRangeKernel: local_work_size[%d] is zero, must be non-zero", i);
              }
          }

	cl_event ev = 0;
        NEED_SUCCESS (EnqueueNDRangeKernel, (self, kernel, gws_len, gwo, gws, lws, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

#if CL_VERSION_1_2

void
migrate_mem_objects (OpenCL::Queue self, SV *objects, cl_mem_migration_flags flags, ...)
	ALIAS:
        enqueue_migrate_mem_objects = 0
	PPCODE:
        EVENT_LIST (3);

        cl_uint obj_count;
        cl_mem *obj_list  = object_list (cv, 0, "objects", objects, "OpenCL::Memory", &obj_count);

        cl_event ev = 0;
        NEED_SUCCESS (EnqueueMigrateMemObjects, (self, obj_count, obj_list, flags, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

#endif

#if cl_apple_gl_sharing || cl_khr_gl_sharing

void
acquire_gl_objects (OpenCL::Queue self, SV *objects, ...)
	ALIAS:
        release_gl_objects = 1
	enqueue_acquire_gl_objects = 0
        enqueue_release_gl_objects = 1
	PPCODE:
        EVENT_LIST (2);

        cl_uint obj_count;
        cl_mem *obj_list  = object_list (cv, 0, "objects", objects, "OpenCL::Memory", &obj_count);

	cl_event ev = 0;

        if (ix)
          NEED_SUCCESS (EnqueueReleaseGLObjects, (self, obj_count, obj_list, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));
        else
          NEED_SUCCESS (EnqueueAcquireGLObjects, (self, obj_count, obj_list, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));

        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

#endif

void
wait_for_events (OpenCL::Queue self, ...)
	ALIAS:
	enqueue_wait_for_events = 0
	CODE:
        EVENT_LIST (1);
#if PREFER_1_1
        NEED_SUCCESS (EnqueueWaitForEvents, (self, event_list_count, event_list_ptr));
#else
        NEED_SUCCESS (EnqueueBarrierWithWaitList, (self, event_list_count, event_list_ptr, 0));
#endif

void
marker (OpenCL::Queue self, ...)
	ALIAS:
	enqueue_marker = 0
	PPCODE:
        EVENT_LIST (1);
	cl_event ev = 0;
#if PREFER_1_1
	if (!event_list_count)
          NEED_SUCCESS (EnqueueMarker, (self, GIMME_V != G_VOID ? &ev : 0));
        else
#if CL_VERSION_1_2
          NEED_SUCCESS (EnqueueMarkerWithWaitList, (self, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));
#else
          {
            NEED_SUCCESS (EnqueueWaitForEvents, (self, event_list_count, event_list_ptr)); // also a barrier
            NEED_SUCCESS (EnqueueMarker, (self, GIMME_V != G_VOID ? &ev : 0));
          }
#endif
#else
        NEED_SUCCESS (EnqueueMarkerWithWaitList, (self, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));
#endif
        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
barrier (OpenCL::Queue self, ...)
	ALIAS:
	enqueue_barrier = 0
	PPCODE:
        EVENT_LIST (1);
	cl_event ev = 0;
#if PREFER_1_1
        if (!event_list_count && GIMME_V == G_VOID)
          NEED_SUCCESS (EnqueueBarrier, (self));
        else
#if CL_VERSION_1_2
          NEED_SUCCESS (EnqueueBarrierWithWaitList, (self, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));
#else
          {
            if (event_list_count)
              NEED_SUCCESS (EnqueueWaitForEvents, (self, event_list_count, event_list_ptr));

            if (GIMME_V != G_VOID)
              NEED_SUCCESS (EnqueueMarker, (self, &ev));
          }
#endif
#else
        NEED_SUCCESS (EnqueueBarrierWithWaitList, (self, event_list_count, event_list_ptr, GIMME_V != G_VOID ? &ev : 0));
#endif
        if (ev)
          XPUSH_CLOBJ (stash_event, ev);

void
flush (OpenCL::Queue self)
	CODE:
        NEED_SUCCESS (Flush, (self));

void
finish (OpenCL::Queue self)
	CODE:
        NEED_SUCCESS (Finish, (self));

void
info (OpenCL::Queue self, cl_command_queue_info name)
	PPCODE:
        INFO (CommandQueue)

#BEGIN:command_queue

void
context (OpenCL::Queue self)
 PPCODE:
 cl_context value [1];
 NEED_SUCCESS (GetCommandQueueInfo, (self, CL_QUEUE_CONTEXT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainContext, (value [i]));
 PUSH_CLOBJ (stash_context, value [i]);

void
device (OpenCL::Queue self)
 PPCODE:
 cl_device_id value [1];
 NEED_SUCCESS (GetCommandQueueInfo, (self, CL_QUEUE_DEVICE, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSH_CLOBJ (stash_device, value [i]);

void
reference_count (OpenCL::Queue self)
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetCommandQueueInfo, (self, CL_QUEUE_REFERENCE_COUNT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
properties (OpenCL::Queue self)
 PPCODE:
 cl_ulong value [1];
 NEED_SUCCESS (GetCommandQueueInfo, (self, CL_QUEUE_PROPERTIES, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

#END:command_queue

MODULE = OpenCL		PACKAGE = OpenCL::Memory

void
DESTROY (OpenCL::Memory self)
	CODE:
        clReleaseMemObject (self);

void
info (OpenCL::Memory self, cl_mem_info name)
	PPCODE:
        INFO (MemObject)

void
destructor_callback (OpenCL::Memory self, SV *notify)
	PPCODE:
        clSetMemObjectDestructorCallback (self, eq_destructor_notify, SvREFCNT_inc (s_get_cv (notify)));

#BEGIN:mem

void
type (OpenCL::Memory self)
 ALIAS:
 type = CL_MEM_TYPE
 map_count = CL_MEM_MAP_COUNT
 reference_count = CL_MEM_REFERENCE_COUNT
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetMemObjectInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
flags (OpenCL::Memory self)
 PPCODE:
 cl_ulong value [1];
 NEED_SUCCESS (GetMemObjectInfo, (self, CL_MEM_FLAGS, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
size (OpenCL::Memory self)
 ALIAS:
 size = CL_MEM_SIZE
 offset = CL_MEM_OFFSET
 PPCODE:
 size_t value [1];
 NEED_SUCCESS (GetMemObjectInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
host_ptr (OpenCL::Memory self)
 PPCODE:
 void * value [1];
 NEED_SUCCESS (GetMemObjectInfo, (self, CL_MEM_HOST_PTR, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv ((IV)(intptr_t)value [i])));

void
context (OpenCL::Memory self)
 PPCODE:
 cl_context value [1];
 NEED_SUCCESS (GetMemObjectInfo, (self, CL_MEM_CONTEXT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainContext, (value [i]));
 PUSH_CLOBJ (stash_context, value [i]);

void
associated_memobject (OpenCL::Memory self)
 PPCODE:
 cl_mem value [1];
 NEED_SUCCESS (GetMemObjectInfo, (self, CL_MEM_ASSOCIATED_MEMOBJECT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainMemObject, (value [i]));
 PUSH_CLOBJ (stash_memory, value [i]);

#END:mem

#if cl_apple_gl_sharing || cl_khr_gl_sharing

void
gl_object_info (OpenCL::Memory self)
        PPCODE:
        cl_gl_object_type type;
        cl_GLuint name;
        NEED_SUCCESS (GetGLObjectInfo, (self, &type, &name));
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSVuv (type)));
        PUSHs (sv_2mortal (newSVuv (name)));

#endif

MODULE = OpenCL		PACKAGE = OpenCL::BufferObj

void
sub_buffer_region (OpenCL::BufferObj self, cl_mem_flags flags, size_t origin, size_t size)
	PPCODE:
        if (flags & (CL_MEM_USE_HOST_PTR | CL_MEM_COPY_HOST_PTR | CL_MEM_ALLOC_HOST_PTR))
          croak ("clCreateSubBuffer: cannot use/copy/alloc host ptr, doesn't make sense, check your flags!");

        cl_buffer_region crdata = { origin, size };
        
        NEED_SUCCESS_ARG (cl_mem mem, CreateSubBuffer, (self, flags, CL_BUFFER_CREATE_TYPE_REGION, &crdata, &res));
        XPUSH_CLOBJ (stash_buffer, mem);

MODULE = OpenCL		PACKAGE = OpenCL::Image

void
image_info (OpenCL::Image self, cl_image_info name)
	PPCODE:
        INFO (Image)

void
format (OpenCL::Image self)
	PPCODE:
        cl_image_format format;
	NEED_SUCCESS (GetImageInfo, (self, CL_IMAGE_FORMAT, sizeof (format), &format, 0));
        EXTEND (SP, 2);
        PUSHs (sv_2mortal (newSVuv (format.image_channel_order)));
        PUSHs (sv_2mortal (newSVuv (format.image_channel_data_type)));

#BEGIN:image

void
element_size (OpenCL::Image self)
 ALIAS:
 element_size = CL_IMAGE_ELEMENT_SIZE
 row_pitch = CL_IMAGE_ROW_PITCH
 slice_pitch = CL_IMAGE_SLICE_PITCH
 width = CL_IMAGE_WIDTH
 height = CL_IMAGE_HEIGHT
 depth = CL_IMAGE_DEPTH
 PPCODE:
 size_t value [1];
 NEED_SUCCESS (GetImageInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

#END:image

#if cl_apple_gl_sharing || cl_khr_gl_sharing

#BEGIN:gl_texture

void
target (OpenCL::Image self)
 PPCODE:
 cl_GLenum value [1];
 NEED_SUCCESS (GetGLTextureInfo, (self, CL_GL_TEXTURE_TARGET, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
gl_mipmap_level (OpenCL::Image self)
 PPCODE:
 cl_GLint value [1];
 NEED_SUCCESS (GetGLTextureInfo, (self, CL_GL_MIPMAP_LEVEL, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSViv (value [i])));

#END:gl_texture

#endif

MODULE = OpenCL		PACKAGE = OpenCL::Sampler

void
DESTROY (OpenCL::Sampler self)
	CODE:
        clReleaseSampler (self);

void
info (OpenCL::Sampler self, cl_sampler_info name)
	PPCODE:
        INFO (Sampler)

#BEGIN:sampler

void
reference_count (OpenCL::Sampler self)
 ALIAS:
 reference_count = CL_SAMPLER_REFERENCE_COUNT
 normalized_coords = CL_SAMPLER_NORMALIZED_COORDS
 addressing_mode = CL_SAMPLER_ADDRESSING_MODE
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetSamplerInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
context (OpenCL::Sampler self)
 PPCODE:
 cl_context value [1];
 NEED_SUCCESS (GetSamplerInfo, (self, CL_SAMPLER_CONTEXT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainContext, (value [i]));
 PUSH_CLOBJ (stash_context, value [i]);

void
filter_mode (OpenCL::Sampler self)
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetSamplerInfo, (self, CL_SAMPLER_FILTER_MODE, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (value [i] ? &PL_sv_yes : &PL_sv_no));

#END:sampler

MODULE = OpenCL		PACKAGE = OpenCL::Program

void
DESTROY (OpenCL::Program self)
	CODE:
        clReleaseProgram (self);

void
build (OpenCL::Program self, SV *devices = &PL_sv_undef, SV *options = &PL_sv_undef, SV *notify = &PL_sv_undef)
	ALIAS:
        build_async = 1
	CODE:
        cl_uint       device_count = 0;
        cl_device_id *device_list  = 0;

        if (SvOK (devices))
          device_list = object_list (cv, 1, "devices", devices, "OpenCL::Device", &device_count);

        void *user_data;
        program_callback pfn_notify = make_program_callback (notify, &user_data);

	if (ix)
          build_program_async (self, device_count, device_list, SvPVbyte_nolen (options), user_data);
        else
          NEED_SUCCESS (BuildProgram, (self, device_count, device_list, SvPVbyte_nolen (options), pfn_notify, user_data));

#if CL_VERSION_1_2

void
compile (OpenCL::Program self, SV *devices, SV *options = &PL_sv_undef, SV *headers = &PL_sv_undef, SV *notify = &PL_sv_undef)
	CODE:
        cl_uint       device_count = 0;
        cl_device_id *device_list  = 0;

        if (SvOK (devices))
          device_list = object_list (cv, 1, "devices", devices, "OpenCL::Device", &device_count);

        cl_uint      header_count = 0;
        cl_program  *header_list  = 0;
        const char **header_name  = 0;

        if (SvOK (headers))
          {
            if (!SvROK (devices) || SvTYPE (SvRV (devices)) != SVt_PVHV)
              croak ("clCompileProgram: headers must be undef or a hashref of name => OpenCL::Program pairs");

            HV *hv = (HV *)SvRV (devices);

            header_count = hv_iterinit (hv);
            header_list  = tmpbuf (sizeof (*header_list) * header_count);
            header_name  = tmpbuf (sizeof (*header_name) * header_count);

            HE *he;
            int i = 0;
            while (he = hv_iternext (hv))
              {
                header_name [i] = SvPVbyte_nolen (HeSVKEY_force (he));
                header_list [i] = SvCLOBJ (cv, "headers", HeVAL (he), "OpenCL::Program");
                ++i;
              }
          }

        void *user_data;
        program_callback pfn_notify = make_program_callback (notify, &user_data);

        NEED_SUCCESS (CompileProgram, (self, device_count, device_list, SvPVbyte_nolen (options),
                                       header_count, header_list, header_name, pfn_notify, user_data));

#endif

void
build_info (OpenCL::Program self, OpenCL::Device device, cl_program_build_info name)
	PPCODE:
	size_t size;
	NEED_SUCCESS (GetProgramBuildInfo, (self, device, name, 0, 0, &size));
        SV *sv = sv_2mortal (newSV (size));
        SvUPGRADE (sv, SVt_PV);
        SvPOK_only (sv);
        SvCUR_set (sv, size);
	NEED_SUCCESS (GetProgramBuildInfo, (self, device, name, size, SvPVX (sv), 0));
        XPUSHs (sv);

#BEGIN:program_build

void
build_status (OpenCL::Program self, OpenCL::Device device)
 PPCODE:
 cl_int value [1];
 NEED_SUCCESS (GetProgramBuildInfo, (self, device, CL_PROGRAM_BUILD_STATUS, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSViv (value [i])));

void
build_options (OpenCL::Program self, OpenCL::Device device)
 ALIAS:
 build_options = CL_PROGRAM_BUILD_OPTIONS
 build_log = CL_PROGRAM_BUILD_LOG
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetProgramBuildInfo, (self, device, ix,    0,     0, &size));
 char *value = tmpbuf (size);
 NEED_SUCCESS (GetProgramBuildInfo, (self, device, ix, size, value,     0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVpv (value, 0)));

void
binary_type (OpenCL::Program self, OpenCL::Device device)
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetProgramBuildInfo, (self, device, CL_PROGRAM_BINARY_TYPE, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv ((UV)value [i])));

#END:program_build

void
kernel (OpenCL::Program program, SV *function)
	PPCODE:
	NEED_SUCCESS_ARG (cl_kernel kernel, CreateKernel, (program, SvPVbyte_nolen (function), &res));
        XPUSH_CLOBJ (stash_kernel, kernel);

void
kernels_in_program (OpenCL::Program program)
	PPCODE:
        cl_uint num_kernels;
	NEED_SUCCESS (CreateKernelsInProgram, (program, 0, 0, &num_kernels));
        cl_kernel *kernels = tmpbuf (sizeof (cl_kernel) * num_kernels);
	NEED_SUCCESS (CreateKernelsInProgram, (program, num_kernels, kernels, 0));

        int i;
        EXTEND (SP, num_kernels);
        for (i = 0; i < num_kernels; ++i)
          PUSH_CLOBJ (stash_kernel, kernels [i]);

void
info (OpenCL::Program self, cl_program_info name)
	PPCODE:
        INFO (Program)

void
binaries (OpenCL::Program self)
	PPCODE:
        cl_uint n, i;
        size_t size;

        NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_NUM_DEVICES , sizeof (n)          , &n   , 0));
        if (!n) XSRETURN_EMPTY;

        size_t *sizes = tmpbuf (sizeof (*sizes) * n);
        NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_BINARY_SIZES, sizeof (*sizes) * n, sizes, &size));
        if (size != sizeof (*sizes) * n) XSRETURN_EMPTY;
        unsigned char **ptrs = tmpbuf (sizeof (*ptrs) * n);

        EXTEND (SP, n);
        for (i = 0; i < n; ++i)
          {
            SV *sv = sv_2mortal (newSV (sizes [i]));
            SvUPGRADE (sv, SVt_PV);
            SvPOK_only (sv);
            SvCUR_set (sv, sizes [i]);
            ptrs [i] = (void *)SvPVX (sv);
            PUSHs (sv);
          }

        NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_BINARIES    , sizeof (*ptrs ) * n, ptrs , &size));
        if (size != sizeof (*ptrs) * n) XSRETURN_EMPTY;

#BEGIN:program

void
reference_count (OpenCL::Program self)
 ALIAS:
 reference_count = CL_PROGRAM_REFERENCE_COUNT
 num_devices = CL_PROGRAM_NUM_DEVICES
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetProgramInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
context (OpenCL::Program self)
 PPCODE:
 cl_context value [1];
 NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_CONTEXT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainContext, (value [i]));
 PUSH_CLOBJ (stash_context, value [i]);

void
devices (OpenCL::Program self)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_DEVICES,    0,     0, &size));
 cl_device_id *value = tmpbuf (size);
 NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_DEVICES, size, value,     0));
 int i, n = size / sizeof (*value);
 EXTEND (SP, n);
 for (i = 0; i < n; ++i)
 PUSH_CLOBJ (stash_device, value [i]);

void
source (OpenCL::Program self)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_SOURCE,    0,     0, &size));
 char *value = tmpbuf (size);
 NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_SOURCE, size, value,     0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVpv (value, 0)));

void
binary_sizes (OpenCL::Program self)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_BINARY_SIZES,    0,     0, &size));
 size_t *value = tmpbuf (size);
 NEED_SUCCESS (GetProgramInfo, (self, CL_PROGRAM_BINARY_SIZES, size, value,     0));
 int i, n = size / sizeof (*value);
 EXTEND (SP, n);
 for (i = 0; i < n; ++i)
 PUSHs (sv_2mortal (newSVuv (value [i])));

#END:program

MODULE = OpenCL		PACKAGE = OpenCL::Kernel

void
DESTROY (OpenCL::Kernel self)
	CODE:
        clReleaseKernel (self);

void
setf (OpenCL::Kernel self, const char *format, ...)
	CODE:
        int i;
        for (i = 2; ; ++i)
          {
            while (*format == ' ')
              ++format;

            char type = *format++;

            if (!type)
              break;

            if (i >= items)
              croak ("OpenCL::Kernel::setf format string too long (not enough arguments)");

            SV *sv = ST (i);

            union
            {
              cl_char    cc; cl_uchar   cC; cl_short   cs; cl_ushort  cS;
              cl_int     ci; cl_uint    cI; cl_long    cl; cl_ulong   cL;
              cl_half    ch; cl_float   cf; cl_double  cd;
              cl_mem     cm;
              cl_sampler ca;
              size_t     cz;
              cl_event   ce;
            } arg;
            size_t size;
            int nullarg = 0;

            switch (type)
              {
                case 'c': arg.cc = SvIV (sv); size = sizeof (arg.cc); break;
                case 'C': arg.cC = SvUV (sv); size = sizeof (arg.cC); break;
                case 's': arg.cs = SvIV (sv); size = sizeof (arg.cs); break;
                case 'S': arg.cS = SvUV (sv); size = sizeof (arg.cS); break;
                case 'i': arg.ci = SvIV (sv); size = sizeof (arg.ci); break;
                case 'I': arg.cI = SvUV (sv); size = sizeof (arg.cI); break;
                case 'l': arg.cl = SvIV (sv); size = sizeof (arg.cl); break;
                case 'L': arg.cL = SvUV (sv); size = sizeof (arg.cL); break;

                case 'h': arg.ch = SvUV (sv); size = sizeof (arg.ch); break;
                case 'f': arg.cf = SvNV (sv); size = sizeof (arg.cf); break;
                case 'd': arg.cd = SvNV (sv); size = sizeof (arg.cd); break;

                case 'z': nullarg = 1; size = SvIV (sv); break;

                case 'm': nullarg = !SvOK (sv); arg.cm = SvCLOBJ (cv, "m", sv, "OpenCL::Memory" ); size = sizeof (arg.cm); break;
                case 'a': nullarg = !SvOK (sv); arg.ca = SvCLOBJ (cv, "a", sv, "OpenCL::Sampler"); size = sizeof (arg.ca); break;
                case 'e': nullarg = !SvOK (sv); arg.ca = SvCLOBJ (cv, "e", sv, "OpenCL::Event"  ); size = sizeof (arg.ce); break;

                default:
                  croak ("OpenCL::Kernel::setf format character '%c' not supported", type);
              }

            res = clSetKernelArg (self, i - 2, size, nullarg ? 0 : &arg);
            if (res)
              croak ("OpenCL::Kernel::setf kernel parameter '%c' (#%d): %s", type, i - 2, err2str (res));
          }

        if (i != items)
          croak ("OpenCL::Kernel::setf format string too short (too many arguments)");

void
set_char (OpenCL::Kernel self, cl_uint idx, cl_char value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_uchar (OpenCL::Kernel self, cl_uint idx, cl_uchar value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_short (OpenCL::Kernel self, cl_uint idx, cl_short value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_ushort (OpenCL::Kernel self, cl_uint idx, cl_ushort value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_int (OpenCL::Kernel self, cl_uint idx, cl_int value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_uint (OpenCL::Kernel self, cl_uint idx, cl_uint value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_long (OpenCL::Kernel self, cl_uint idx, cl_long value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_ulong (OpenCL::Kernel self, cl_uint idx, cl_ulong value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_half (OpenCL::Kernel self, cl_uint idx, cl_half value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_float (OpenCL::Kernel self, cl_uint idx, cl_float value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_double (OpenCL::Kernel self, cl_uint idx, cl_double value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_memory (OpenCL::Kernel self, cl_uint idx, OpenCL::Memory_ornull value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), value ? &value : 0);

void
set_buffer (OpenCL::Kernel self, cl_uint idx, OpenCL::Buffer_ornull value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), value ? &value : 0);

void
set_image (OpenCL::Kernel self, cl_uint idx, OpenCL::Image_ornull value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), value ? &value : 0);

void
set_sampler (OpenCL::Kernel self, cl_uint idx, OpenCL::Sampler value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
set_local (OpenCL::Kernel self, cl_uint idx, size_t size)
	CODE:
        clSetKernelArg (self, idx, size, 0);

void
set_event (OpenCL::Kernel self, cl_uint idx, OpenCL::Event value)
	CODE:
        clSetKernelArg (self, idx, sizeof (value), &value);

void
info (OpenCL::Kernel self, cl_kernel_info name)
	PPCODE:
        INFO (Kernel)

#BEGIN:kernel

void
function_name (OpenCL::Kernel self)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetKernelInfo, (self, CL_KERNEL_FUNCTION_NAME,    0,     0, &size));
 char *value = tmpbuf (size);
 NEED_SUCCESS (GetKernelInfo, (self, CL_KERNEL_FUNCTION_NAME, size, value,     0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVpv (value, 0)));

void
num_args (OpenCL::Kernel self)
 ALIAS:
 num_args = CL_KERNEL_NUM_ARGS
 reference_count = CL_KERNEL_REFERENCE_COUNT
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetKernelInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
context (OpenCL::Kernel self)
 PPCODE:
 cl_context value [1];
 NEED_SUCCESS (GetKernelInfo, (self, CL_KERNEL_CONTEXT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainContext, (value [i]));
 PUSH_CLOBJ (stash_context, value [i]);

void
program (OpenCL::Kernel self)
 PPCODE:
 cl_program value [1];
 NEED_SUCCESS (GetKernelInfo, (self, CL_KERNEL_PROGRAM, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainProgram, (value [i]));
 PUSH_CLOBJ (stash_program, value [i]);

#END:kernel

void
work_group_info (OpenCL::Kernel self, OpenCL::Device device, cl_kernel_work_group_info name)
	PPCODE:
	size_t size;
	NEED_SUCCESS (GetKernelWorkGroupInfo, (self, device, name, 0, 0, &size));
        SV *sv = sv_2mortal (newSV (size));
        SvUPGRADE (sv, SVt_PV);
        SvPOK_only (sv);
        SvCUR_set (sv, size);
	NEED_SUCCESS (GetKernelWorkGroupInfo, (self, device, name, size, SvPVX (sv), 0));
        XPUSHs (sv);

#BEGIN:kernel_work_group

void
work_group_size (OpenCL::Kernel self, OpenCL::Device device)
 ALIAS:
 work_group_size = CL_KERNEL_WORK_GROUP_SIZE
 preferred_work_group_size_multiple = CL_KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE
 PPCODE:
 size_t value [1];
 NEED_SUCCESS (GetKernelWorkGroupInfo, (self, device, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
compile_work_group_size (OpenCL::Kernel self, OpenCL::Device device)
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetKernelWorkGroupInfo, (self, device, CL_KERNEL_COMPILE_WORK_GROUP_SIZE,    0,     0, &size));
 size_t *value = tmpbuf (size);
 NEED_SUCCESS (GetKernelWorkGroupInfo, (self, device, CL_KERNEL_COMPILE_WORK_GROUP_SIZE, size, value,     0));
 int i, n = size / sizeof (*value);
 EXTEND (SP, n);
 for (i = 0; i < n; ++i)
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
local_mem_size (OpenCL::Kernel self, OpenCL::Device device)
 ALIAS:
 local_mem_size = CL_KERNEL_LOCAL_MEM_SIZE
 private_mem_size = CL_KERNEL_PRIVATE_MEM_SIZE
 PPCODE:
 cl_ulong value [1];
 NEED_SUCCESS (GetKernelWorkGroupInfo, (self, device, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

#END:kernel_work_group

#if CL_VERSION_1_2

void
arg_info (OpenCL::Kernel self, cl_uint idx, cl_kernel_arg_info name)
	PPCODE:
	size_t size;
	NEED_SUCCESS (GetKernelArgInfo, (self, idx, name, 0, 0, &size));
        SV *sv = sv_2mortal (newSV (size));
        SvUPGRADE (sv, SVt_PV);
        SvPOK_only (sv);
        SvCUR_set (sv, size);
	NEED_SUCCESS (GetKernelArgInfo, (self, idx, name, size, SvPVX (sv), 0));
        XPUSHs (sv);

#BEGIN:kernel_arg

void
arg_address_qualifier (OpenCL::Kernel self, cl_uint idx)
 ALIAS:
 arg_address_qualifier = CL_KERNEL_ARG_ADDRESS_QUALIFIER
 arg_access_qualifier = CL_KERNEL_ARG_ACCESS_QUALIFIER
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetKernelArgInfo, (self, idx, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
arg_type_name (OpenCL::Kernel self, cl_uint idx)
 ALIAS:
 arg_type_name = CL_KERNEL_ARG_TYPE_NAME
 arg_name = CL_KERNEL_ARG_NAME
 PPCODE:
 size_t size;
 NEED_SUCCESS (GetKernelArgInfo, (self, idx, ix,    0,     0, &size));
 char *value = tmpbuf (size);
 NEED_SUCCESS (GetKernelArgInfo, (self, idx, ix, size, value,     0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVpv (value, 0)));

void
arg_type_qualifier (OpenCL::Kernel self, cl_uint idx)
 PPCODE:
 cl_ulong value [1];
 NEED_SUCCESS (GetKernelArgInfo, (self, idx, CL_KERNEL_ARG_TYPE_QUALIFIER, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

#END:kernel_arg

#endif

MODULE = OpenCL		PACKAGE = OpenCL::Event

void
DESTROY (OpenCL::Event self)
	CODE:
        clReleaseEvent (self);

void
wait (OpenCL::Event self)
	CODE:
	clWaitForEvents (1, &self);

void
cb (OpenCL::Event self, cl_int command_exec_callback_type, SV *cb)
	CODE:
        clSetEventCallback (self, command_exec_callback_type, eq_event_notify, SvREFCNT_inc (s_get_cv (cb)));

void
info (OpenCL::Event self, cl_event_info name)
	PPCODE:
        INFO (Event)

#BEGIN:event

void
command_queue (OpenCL::Event self)
 PPCODE:
 cl_command_queue value [1];
 NEED_SUCCESS (GetEventInfo, (self, CL_EVENT_COMMAND_QUEUE, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainCommandQueue, (value [i]));
 PUSH_CLOBJ (stash_queue, value [i]);

void
command_type (OpenCL::Event self)
 ALIAS:
 command_type = CL_EVENT_COMMAND_TYPE
 reference_count = CL_EVENT_REFERENCE_COUNT
 command_execution_status = CL_EVENT_COMMAND_EXECUTION_STATUS
 PPCODE:
 cl_uint value [1];
 NEED_SUCCESS (GetEventInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

void
context (OpenCL::Event self)
 PPCODE:
 cl_context value [1];
 NEED_SUCCESS (GetEventInfo, (self, CL_EVENT_CONTEXT, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 NEED_SUCCESS (RetainContext, (value [i]));
 PUSH_CLOBJ (stash_context, value [i]);

#END:event

void
profiling_info (OpenCL::Event self, cl_profiling_info name)
	PPCODE:
        INFO (EventProfiling)

#BEGIN:profiling

void
profiling_command_queued (OpenCL::Event self)
 ALIAS:
 profiling_command_queued = CL_PROFILING_COMMAND_QUEUED
 profiling_command_submit = CL_PROFILING_COMMAND_SUBMIT
 profiling_command_start = CL_PROFILING_COMMAND_START
 profiling_command_end = CL_PROFILING_COMMAND_END
 PPCODE:
 cl_ulong value [1];
 NEED_SUCCESS (GetEventProfilingInfo, (self, ix, sizeof (value), value, 0));
 EXTEND (SP, 1);
 const int i = 0;
 PUSHs (sv_2mortal (newSVuv (value [i])));

#END:profiling

MODULE = OpenCL		PACKAGE = OpenCL::UserEvent

void
set_status (OpenCL::UserEvent self, cl_int execution_status)
	CODE:
	clSetUserEventStatus (self, execution_status);

MODULE = OpenCL		PACKAGE = OpenCL::Mapped

void
DESTROY (SV *self)
	CODE:
	OpenCL__Mapped mapped = SvMAPPED (self);
	
	clEnqueueUnmapMemObject (mapped->queue, mapped->memobj, mapped->ptr, 1, &mapped->event, 0);
	mapped_detach (self, mapped);
	
	clReleaseCommandQueue (mapped->queue);
	clReleaseEvent (mapped->event);
	Safefree (mapped);

void
unmap (OpenCL::Mapped self, ...)
	CODE:
        mapped_unmap (cv, ST (0), self, self->queue, &ST (1), items - 1);

bool
mapped (OpenCL::Mapped self)
	CODE:
        RETVAL = !!self->ptr;
	OUTPUT:
        RETVAL

void
wait (OpenCL::Mapped self)
	PPCODE:
        if (self->event)
          NEED_SUCCESS (WaitForEvents, (1, &self->event));

void
event (OpenCL::Mapped self)
	PPCODE:
        if (!self->event)
          XSRETURN_UNDEF;

        clRetainEvent (self->event);
        XPUSH_CLOBJ (stash_event, self->event);

#define MAPPED_OFFSET_CB          offsetof (struct mapped, cb)
#define MAPPED_OFFSET_ROW_PITCH   offsetof (struct mapped, row_pitch)
#define MAPPED_OFFSET_SLICE_PITCH offsetof (struct mapped, slice_pitch)
#define MAPPED_OFFSET_WIDTH       offsetof (struct mapped, width)
#define MAPPED_OFFSET_HEIGHT      offsetof (struct mapped, height)
#define MAPPED_OFFSET_DEPTH       offsetof (struct mapped, depth)

IV
size (OpenCL::Mapped self)
	ALIAS:
        size        = MAPPED_OFFSET_CB
        row_pitch   = MAPPED_OFFSET_ROW_PITCH
        slice_pitch = MAPPED_OFFSET_SLICE_PITCH
        width       = MAPPED_OFFSET_WIDTH
        height      = MAPPED_OFFSET_HEIGHT
        depth       = MAPPED_OFFSET_DEPTH
	CODE:
        RETVAL = *(size_t *)((char *)self + ix);
	OUTPUT:
        RETVAL

IV
ptr (OpenCL::Mapped self)
	CODE:
        RETVAL = PTR2IV (self->ptr);
	OUTPUT:
        RETVAL

void
set (OpenCL::Mapped self, size_t offset, SV *data)
	CODE:
        STRLEN len;
        const char *ptr = SvPVbyte (data, len);

        if (offset + len > self->cb)
          croak ("OpenCL::Mapped::set out of bound condition detected");

        memcpy (offset + (char *)self->ptr, ptr, len);

void
get_row (OpenCL::Mapped self, size_t count, size_t x = 0, size_t y = 0, size_t z = 0)
	PPCODE:
        if (!SvOK (ST (1)))
          count = self->width - x;

        if (x + count > self->width)
          croak ("OpenCL::Mapped::get: x + count crosses a row boundary");

        if (y >= self->height)
          croak ("OpenCL::Mapped::get: y coordinate out of bounds");

        if (z >= self->depth)
          croak ("OpenCL::Mapped::get: z coordinate out of bounds");

        size_t element = mapped_element_size (self);

        count *= element;
        x     *= element;

        char *ptr = (char *)self->ptr + x + y * self->row_pitch + z * self->slice_pitch;
        XPUSHs (sv_2mortal (newSVpvn (ptr, count)));

void
set_row (OpenCL::Mapped self, SV *data, size_t x = 0, size_t y = 0, size_t z = 0)
	PPCODE:
        STRLEN count;
        char *dataptr = SvPVbyte (data, count);
        size_t element = mapped_element_size (self);

        x *= element;

        if (x + count > self->width * element)
          croak ("OpenCL::Mapped::set: x + data size crosses a row boundary");

        if (y >= self->height)
          croak ("OpenCL::Mapped::set: y coordinate out of bounds");

        if (z >= self->depth)
          croak ("OpenCL::Mapped::set: z coordinate out of bounds");

        char *ptr = (char *)self->ptr + x + y * self->row_pitch + z * self->slice_pitch;
        memcpy (ptr, dataptr, count);

MODULE = OpenCL		PACKAGE = OpenCL::MappedBuffer

MODULE = OpenCL		PACKAGE = OpenCL::MappedImage

IV
element_size (OpenCL::Mapped self)
	CODE:
        RETVAL = mapped_element_size (self);
	OUTPUT:
        RETVAL

