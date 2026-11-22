#define PERL_NO_GET_CONTEXT
#include "xs/protobuf/message.h"
#include "xs/protobuf.h"
#include "upb/reflection/def.h"
#include "xs/protobuf/obj_cache.h"
#include "xs/protobuf/arena.h"
#include "xs/protobuf/utils.h"
#include "xs/protobuf/port.h"
#if defined(USE_ITHREADS) && !defined(_WIN32)
#include <pthread.h>
#endif

static int descriptor_cleanup(pTHX_ SV* sv, MAGIC* mg) {
    // No explicit cleanup needed for the descriptor IV,
    // but having the magic ensures we don't trigger the "unreferenced scalar"
    // warnings during global destruction by explicitly managing it.
    return 0;
}

static SV* wrap_message_internal(pTHX_ const upb_Message* msg, const upb_MessageDef* mdef, SV* arena_sv, uint16_t flags) {
    HV* stash = PerlUpb_GetMessageStash(aTHX_ mdef);
    SV *self = PerlUpb_WrapArenaBoundObject(aTHX_ msg, arena_sv, stash, flags);

    // Store the descriptor C pointer in magic-protected state (and HV for diagnostic introspection).
    PerlUpb_SetArenaBoundMeta(aTHX_ self, mdef);
    HV* hv = (HV*)SvRV(self);
    hv_store(hv, "_mdef_ptr", 9, newSViv(PTR2IV(mdef)), 0);

    return self;
}

SV *PerlUpb_WrapMessage(pTHX_ const upb_Message *msg, const upb_MessageDef *mdef, SV *arena_sv, uint16_t flags) {
    if (!msg) return &PL_sv_undef;

    SV* cached = PerlUpb_ObjCache_Get(aTHX_ msg);
    if (cached) return cached;

    return wrap_message_internal(aTHX_ msg, mdef, arena_sv, flags);
}

SV *PerlUpb_WrapMessage_NoCache(pTHX_ const upb_Message *msg, const upb_MessageDef *mdef, SV *arena_sv, uint16_t flags) {
    if (!msg) return &PL_sv_undef;
    return wrap_message_internal(aTHX_ msg, mdef, arena_sv, flags);
}

SV* PerlUpb_MaybeGetMessage(pTHX_ const upb_Message *msg) {
    if (!msg) return NULL;
    return PerlUpb_ObjCache_Get(aTHX_ msg);
}

void PerlUpb_Message_Free(pTHX_ SV *message_sv) {
    if (PL_dirty) return; // Let Perl handle cleanup during global destruction

    const upb_Message *msg = PerlUpb_Message_GetMsg(aTHX_ message_sv);
    if (msg) {
        PerlUpb_ObjCache_Delete(aTHX_ msg);
    }
}

const upb_Message* PerlUpb_Message_GetMsg(pTHX_ SV* message_sv) {
    return (const upb_Message*)PerlUpb_GetArenaBoundObject(aTHX_ message_sv, "Protobuf::Message");
}

const upb_MessageDef* PerlUpb_Message_GetDef(pTHX_ SV* message_sv) {
    return (const upb_MessageDef*)PerlUpb_GetArenaBoundMeta(aTHX_ message_sv, "Protobuf::Message");
}

SV* PerlUpb_Message_GetArena(pTHX_ SV* message_sv) {
    return PerlUpb_GetArenaFromObject(aTHX_ message_sv);
}

SV* PerlUpb_Message_GetFingerprint(pTHX_ SV* message_sv) {
    const upb_Message* msg = PerlUpb_Message_GetMsg(aTHX_ message_sv);
    if (!msg) return &PL_sv_undef;
    char buf[64];
    sprintf(buf, "%p", msg);
    return newSVpv(buf, 0);
}

typedef struct DetachedMsgNode {
    const upb_Message* msg;
    const upb_MessageDef* mdef;
    struct DetachedMsgNode* next;
} DetachedMsgNode;

static DetachedMsgNode* detached_msgs_head = NULL;
static PERL_PROTOBUF_MUTEX_T detached_msgs_mutex;
#if defined(USE_ITHREADS) && !defined(_WIN32)
static pthread_once_t detached_msgs_once = PTHREAD_ONCE_INIT;
static void init_detached_msgs_mutex(void) {
    PERL_PROTOBUF_MUTEX_INIT(&detached_msgs_mutex);
}
static inline void ensure_detached_msgs_mutex(void) {
    pthread_once(&detached_msgs_once, init_detached_msgs_mutex);
}
#else
static inline void ensure_detached_msgs_mutex(void) {}
#endif

SV* PerlUpb_Message_Detach(pTHX_ SV* self) {
    const upb_Message* msg = PerlUpb_Message_GetMsg(aTHX_ self);
    const upb_MessageDef* mdef = PerlUpb_Message_GetDef(aTHX_ self);
    if (!msg || !mdef) croak("Cannot detach invalid message");

    PerlUpb_ObjCache_Delete(aTHX_ msg);
    MAGIC* mg = PerlUpb_GetMagic(aTHX_ self);
    if (mg) mg->mg_ptr = NULL;

    DetachedMsgNode* node = (DetachedMsgNode*)malloc(sizeof(DetachedMsgNode));
    if (!node) croak("Failed to allocate detached message registry entry");
    node->msg = msg;
    node->mdef = mdef;

    ensure_detached_msgs_mutex();
    PERL_PROTOBUF_MUTEX_LOCK(&detached_msgs_mutex);
    node->next = detached_msgs_head;
    detached_msgs_head = node;
    PERL_PROTOBUF_MUTEX_UNLOCK(&detached_msgs_mutex);

    HV* res = newHV();
    hv_store(res, "upb_ptr", 7, newSViv(PTR2IV(msg)), 0);
    hv_store(res, "mdef_ptr", 8, newSViv(PTR2IV(mdef)), 0);
    return newRV_noinc((SV*)res);
}

SV* PerlUpb_Message_Attach(pTHX_ const char* class_name, SV* info_rv, SV* arena_sv) {
    if (!SvROK(info_rv) || SvTYPE(SvRV(info_rv)) != SVt_PVHV) {
        croak("attach() info must be a hash ref");
    }
    upb_Arena* arena = PerlUpb_Arena_Get(aTHX_ arena_sv);
    if (!arena) croak("attach() requires a valid Protobuf::Arena");

    HV* info = (HV*)SvRV(info_rv);
    SV** p_upb = hv_fetch(info, "upb_ptr", 7, 0);
    SV** p_mdef = hv_fetch(info, "mdef_ptr", 8, 0);
    if (!p_upb || !SvIOK(*p_upb) || !p_mdef || !SvIOK(*p_mdef)) {
        croak("Invalid attach() info");
    }

    const upb_Message* req_msg = INT2PTR(const upb_Message*, SvIV(*p_upb));
    const upb_MessageDef* req_mdef = INT2PTR(const upb_MessageDef*, SvIV(*p_mdef));

    ensure_detached_msgs_mutex();
    PERL_PROTOBUF_MUTEX_LOCK(&detached_msgs_mutex);
    DetachedMsgNode** prev = &detached_msgs_head;
    DetachedMsgNode* found = NULL;
    while (*prev) {
        if ((*prev)->msg == req_msg && (*prev)->mdef == req_mdef) {
            found = *prev;
            *prev = found->next;
            break;
        }
        prev = &((*prev)->next);
    }
    PERL_PROTOBUF_MUTEX_UNLOCK(&detached_msgs_mutex);

    if (!found) {
        croak("Invalid or unowned detached message handle");
    }
    free(found);

    return PerlUpb_WrapMessage(aTHX_ req_msg, req_mdef, arena_sv, 0);
}
