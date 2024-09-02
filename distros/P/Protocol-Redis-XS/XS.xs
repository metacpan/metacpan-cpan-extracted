#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#define NEED_sv_2pv_flags
#include "ppport.h"
#include <xs_object_magic.h>
#include <hiredis.h>

#ifdef PERL_IMPLICIT_CONTEXT

#define dTHXREDIS(task)                     \
  dTHXa(task->privdata);

#define SET_THX_REDIS(r)                    \
  do { r->privdata = aTHX; } while(0)

#else

#define dTHXREDIS(task)
#define SET_THX_REDIS(r)

#endif

static const char redisTypes[] = {
  [REDIS_REPLY_STRING]  = '$',
  [REDIS_REPLY_ARRAY]   = '*',
  [REDIS_REPLY_INTEGER] = ':',
  [REDIS_REPLY_NIL]     = '$',
  [REDIS_REPLY_STATUS]  = '+',
  [REDIS_REPLY_ERROR]   = '-'
#if HIREDIS_MAJOR > 0
  ,
  [REDIS_REPLY_DOUBLE]  = ',',
  [REDIS_REPLY_BOOL]    = '#'
#endif
};

static SV *createReply(pTHX_ SV *sv, int type)
{
  char reply_type = redisTypes[type];
  HV *reply = newHV();

  hv_stores(reply, "type", newSVpvn(&reply_type, sizeof reply_type));
  hv_stores(reply, "data", sv);
  return newRV_noinc((SV*)reply);
}

static void freeReplyObjectSV(void *reply) {
  dTHX;
  SV* r = reply;
  sv_2mortal(r);
}

static inline void storeParent(pTHX_ const redisReadTask *task, SV *reply)
{
  if (task->parent) {
    SV *const obj = task->parent->obj;
    HV *const parent = (HV*)SvRV(obj);
    SV **const data = hv_fetchs(parent, "data", FALSE);
    assert(data && SvTYPE(SvRV(*data)) == SVt_PVAV);
    av_store((AV*)SvRV(*data), task->idx, reply);
  }
}

static void *createStringObjectSV(const redisReadTask *task, char *str,
  size_t len)
{
  dTHXREDIS(task);

  SV *const reply = createReply(aTHX_ newSVpvn(str, len), task->type);
  storeParent(aTHX_ task, reply);
  return reply;
}

#if HIREDIS_MAJOR > 0
static void *createArrayObjectSV(const redisReadTask *task, size_t elements)
#else
static void *createArrayObjectSV(const redisReadTask *task, int elements)
#endif
{
  dTHXREDIS(task);

  AV *av = newAV();
  SV *const reply = createReply(aTHX_ newRV_noinc((SV*)av), task->type);
  av_extend(av, elements);
  storeParent(aTHX_ task, reply);
  return reply;
}

static void *createIntegerObjectSV(const redisReadTask *task, long long value)
{
  dTHXREDIS(task);
  /* Not pretty, but perl doesn't always have a sane way to store long long in
   * a SV.
   */
#if defined(LONGLONGSIZE) && LONGLONGSIZE == IVSIZE
  SV *sv = newSViv(value);
#else
  SV *sv = newSVnv(value);
#endif

  SV *reply = createReply(aTHX_ sv, task->type);
  storeParent(aTHX_ task, reply);
  return reply;
}

#if HIREDIS_MAJOR > 0
static void *createDoubleObjectSV(const redisReadTask *task, double value,
  char* str, size_t len)
{
  dTHXREDIS(task);

  SV *sv = newSVpvn(str, len);
  SvUPGRADE(sv, SVt_PVNV);
  SvNV_set(sv, value);
  SvNOK_on(sv);
  SV *const reply = createReply(aTHX_ sv, task->type);
  storeParent(aTHX_ task, reply);
  return reply;
}
#endif

static void *createNilObjectSV(const redisReadTask *task)
{
  dTHXREDIS(task);

  SV *reply = createReply(aTHX_ &PL_sv_undef, task->type);
  storeParent(aTHX_ task, reply);
  return reply;
}

#if HIREDIS_MAJOR > 0
static void *createBoolObjectSV(const redisReadTask *task, int value)
{
  dTHXREDIS(task);
  SV *sv = newSViv(value);

  SV *reply = createReply(aTHX_ sv, task->type);
  storeParent(aTHX_ task, reply);
  return reply;
}
#endif

/* Declarations below are used in the XS section */

static redisReplyObjectFunctions perlRedisFunctions = {
  createStringObjectSV,
  createArrayObjectSV,
  createIntegerObjectSV,
#if HIREDIS_MAJOR > 0
  createDoubleObjectSV,
#endif
  createNilObjectSV,
#if HIREDIS_MAJOR > 0
  createBoolObjectSV,
#endif
  freeReplyObjectSV
};

static void encodeMessage(pTHX_ SV *target, SV *message_p);

static void encodeString(pTHX_ SV *target, SV *message_p) {
  HV *const message = (HV*)SvRV(message_p);
  SV **const type_sv = hv_fetchs(message, "type", FALSE);
  SV **const data_sv = hv_fetchs(message, "data", FALSE);

  char *type = SvPV_nolen(*type_sv);
  char *data = SvPV_nolen(*data_sv);

  sv_catpvf(target, "%s%s\r\n", type, data);
}

static void encodeBulk(pTHX_ SV *target, SV *message_p) {
  HV *const message = (HV*)SvRV(message_p);
  SV **const data_sv = hv_fetchs(message, "data", FALSE);

  if (!SvOK(*data_sv)) {
    sv_catpv(target, "$-1\r\n");
    return;
  }

  STRLEN msglen;

  char *data = SvPV(*data_sv, msglen);
  const char term[] = "\r\n";
  char initmsg[32];

  STRLEN initlen = sprintf( initmsg, "$%lu\r\n", msglen );

  STRLEN targlen = sv_len(target);
  SvGROW(target, targlen + initlen + msglen + sizeof(term)-1 + 1);

  sv_catpvn(target, initmsg, initlen);
  sv_catpvn(target, data,    msglen);
  sv_catpvn(target, term,    sizeof(term)-1);
}

static void encodeMultiBulk (pTHX_ SV *target, SV *message_p) {
  HV *const message = (HV*)SvRV(message_p);
  SV **const data_sv = hv_fetchs(message, "data", FALSE);

  if (!SvOK(*data_sv)) {
    sv_catpv(target, "*-1\r\n");
    return;
  }

  AV *const data = (AV*)SvRV(*data_sv);
  I32 len = av_len(data);
  sv_catpvf(target, "*%d\r\n", len+1);

  I32 i;
  for (i = 0; i <= len; i++) {
    encodeMessage(aTHX_ target, *av_fetch(data, i, FALSE));
  }
}

static void encodeMessage(pTHX_ SV *target, SV *message_p) {
  HV *const message = (HV*)SvRV(message_p);
  SV **const type_sv = hv_fetchs(message, "type", FALSE);

  STRLEN type_len;
  char *type = SvPV(*type_sv, type_len);
  const char op = type[0];

  if (1 != type_len || op == '\0' || NULL == strchr("+-:$*", op))
    croak("Unknown message type: \"%s\"", type);

  switch (op) {
    case '+':
    case '-':
    case ':':
      encodeString(aTHX_ target, message_p);
      return;
    case '$':
      encodeBulk(aTHX_ target, message_p);
      return;
    case '*':
      encodeMultiBulk(aTHX_ target, message_p);
      return;
  }
}

MODULE = Protocol::Redis::XS  PACKAGE = Protocol::Redis::XS
PROTOTYPES: ENABLE

void
_create(SV *self)
  PREINIT:
    redisReader *r;
  CODE:
    r = redisReaderCreate();
    r->fn = &perlRedisFunctions;
    SET_THX_REDIS(r);
    xs_object_magic_attach_struct(aTHX_ SvRV(self), r);

void
DESTROY(redisReader *r)
  CODE:
    redisReaderFree(r);

void
parse(SV *self, SV *data)
  PREINIT:
    redisReader *r;
    SV **callback;
  CODE:
    r = xs_object_magic_get_struct(aTHX_ SvRV(self));
    redisReaderFeed(r, SvPVX(data), SvCUR(data));

    callback = hv_fetchs((HV*)SvRV(self), "_on_message_cb", FALSE);
    if (callback && SvOK(*callback)) {
      /* There's a callback, do parsing now. */
      SV *reply;
      do {
        if(redisReaderGetReply(r, (void**)&reply) == REDIS_ERR) {
          croak("%s", r->errstr);
        }

        if (reply) {
          /* Call the callback */
          dSP;
          ENTER;
          SAVETMPS;
          PUSHMARK(SP);
          XPUSHs(self);
          XPUSHs(reply);
          PUTBACK;

          call_sv(*callback, G_DISCARD);
          sv_2mortal(reply);

          /* May free reply; we still use the presence of a pointer in the loop
           * condition below though.
           */
          FREETMPS;
          LEAVE;
        }
      } while(reply != NULL);
    }

SV*
get_message(redisReader *r)
  CODE:
    if(redisReaderGetReply(r, (void**)&RETVAL) == REDIS_ERR) {
      croak("%s", r->errstr);
    }
    if(!RETVAL)
      RETVAL = &PL_sv_undef;

  OUTPUT:
    RETVAL

SV*
encode(SV *self, SV *message)
  CODE:
    RETVAL = sv_2mortal(newSVpvn("", 0));
    encodeMessage(aTHX_ RETVAL, message);
    SvREFCNT_inc(RETVAL);
  OUTPUT:
    RETVAL
