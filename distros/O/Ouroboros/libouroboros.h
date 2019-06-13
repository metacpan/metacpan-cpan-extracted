/*
Copyright (c) 2016 Vickenty Fesunov.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#ifndef OUROBOROS_H
#define OUROBOROS_H

#ifndef OUROBOROS_STATIC
#define OUROBOROS_STATIC
#endif

#define PERL_NO_GET_CONTEXT
#define NO_XSLOCKS
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct {
        SV **sp;
        SV **mark;
        int ax;
        int items;
} ouroboros_stack_t;

typedef void (*ouroboros_xcpt_callback_t)(void *);

/* functions { */
OUROBOROS_STATIC void ouroboros_stack_init(pTHX_ ouroboros_stack_t*);
OUROBOROS_STATIC int ouroboros_stack_items(pTHX_ ouroboros_stack_t*);
OUROBOROS_STATIC void ouroboros_stack_putback(pTHX_ ouroboros_stack_t*);
OUROBOROS_STATIC SV* ouroboros_stack_fetch(pTHX_ ouroboros_stack_t*, SSize_t);
OUROBOROS_STATIC void ouroboros_stack_store(pTHX_ ouroboros_stack_t*, SSize_t, SV*);
OUROBOROS_STATIC void ouroboros_stack_extend(pTHX_ ouroboros_stack_t*, SSize_t);
OUROBOROS_STATIC void ouroboros_stack_pushmark(pTHX_ ouroboros_stack_t*);
OUROBOROS_STATIC void ouroboros_stack_spagain(pTHX_ ouroboros_stack_t*);
OUROBOROS_STATIC void ouroboros_stack_xpush_sv(pTHX_ ouroboros_stack_t*, SV*);
OUROBOROS_STATIC void ouroboros_stack_xpush_sv_mortal(pTHX_ ouroboros_stack_t*, SV*);
OUROBOROS_STATIC void ouroboros_stack_xpush_iv(pTHX_ ouroboros_stack_t*, IV);
OUROBOROS_STATIC void ouroboros_stack_xpush_uv(pTHX_ ouroboros_stack_t*, UV);
OUROBOROS_STATIC void ouroboros_stack_xpush_nv(pTHX_ ouroboros_stack_t*, NV);
OUROBOROS_STATIC void ouroboros_stack_xpush_pv(pTHX_ ouroboros_stack_t*, const char*, STRLEN);
OUROBOROS_STATIC void ouroboros_stack_xpush_mortal(pTHX_ ouroboros_stack_t*);
OUROBOROS_STATIC void ouroboros_stack_push_sv(pTHX_ ouroboros_stack_t*, SV*);
OUROBOROS_STATIC void ouroboros_stack_push_sv_mortal(pTHX_ ouroboros_stack_t*, SV*);
OUROBOROS_STATIC void ouroboros_stack_push_iv(pTHX_ ouroboros_stack_t*, IV);
OUROBOROS_STATIC void ouroboros_stack_push_uv(pTHX_ ouroboros_stack_t*, UV);
OUROBOROS_STATIC void ouroboros_stack_push_nv(pTHX_ ouroboros_stack_t*, NV);
OUROBOROS_STATIC void ouroboros_stack_push_pv(pTHX_ ouroboros_stack_t*, const char*, STRLEN);
OUROBOROS_STATIC void ouroboros_stack_push_mortal(pTHX_ ouroboros_stack_t*);
OUROBOROS_STATIC void ouroboros_sv_upgrade(pTHX_ SV*, svtype);
OUROBOROS_STATIC U32 ouroboros_sv_niok(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_niok_priv(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_niok_off(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_ok(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_iok_priv(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_nok_priv(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_pok_priv(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_iok(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_iok_on(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_iok_off(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_iok_only(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_iok_only_uv(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_iok_uv(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_uok(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_iok_not_uv(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_nok(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_nok_on(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_nok_off(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_nok_only(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_pok(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_pok_on(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_pok_off(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_pok_only(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_pok_only_utf8(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_vok(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_ook(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_ook_offset(pTHX_ SV*, STRLEN*);
OUROBOROS_STATIC U32 ouroboros_sv_rok(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_rok_on(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_rok_off(pTHX_ SV*);
OUROBOROS_STATIC IV ouroboros_sv_iv(pTHX_ SV*);
OUROBOROS_STATIC IV ouroboros_sv_iv_nomg(pTHX_ SV*);
OUROBOROS_STATIC IV ouroboros_sv_iv_raw(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_iv_set(pTHX_ SV*, IV);
OUROBOROS_STATIC UV ouroboros_sv_uv(pTHX_ SV*);
OUROBOROS_STATIC UV ouroboros_sv_uv_nomg(pTHX_ SV*);
OUROBOROS_STATIC UV ouroboros_sv_uv_raw(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_uv_set(pTHX_ SV*, UV);
OUROBOROS_STATIC NV ouroboros_sv_nv(pTHX_ SV*);
OUROBOROS_STATIC NV ouroboros_sv_nv_nomg(pTHX_ SV*);
OUROBOROS_STATIC NV ouroboros_sv_nv_raw(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_nv_set(pTHX_ SV*, NV);
OUROBOROS_STATIC const char* ouroboros_sv_pv(pTHX_ SV*, STRLEN*);
OUROBOROS_STATIC const char* ouroboros_sv_pv_nomg(pTHX_ SV*, STRLEN*);
OUROBOROS_STATIC const char* ouroboros_sv_pv_nolen(pTHX_ SV*);
OUROBOROS_STATIC const char* ouroboros_sv_pv_nomg_nolen(pTHX_ SV*);
OUROBOROS_STATIC char* ouroboros_sv_pv_raw(pTHX_ SV*);
OUROBOROS_STATIC STRLEN ouroboros_sv_pv_cur(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_pv_cur_set(pTHX_ SV*, STRLEN);
OUROBOROS_STATIC STRLEN ouroboros_sv_pv_len(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_pv_len_set(pTHX_ SV*, STRLEN);
OUROBOROS_STATIC char* ouroboros_sv_pv_end(pTHX_ SV*);
OUROBOROS_STATIC SV* ouroboros_sv_rv(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_rv_set(pTHX_ SV*, SV*);
OUROBOROS_STATIC bool ouroboros_sv_true(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_true_nomg(pTHX_ SV*);
OUROBOROS_STATIC svtype ouroboros_sv_type(pTHX_ SV*);
OUROBOROS_STATIC UV ouroboros_sv_flags(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_utf8(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_utf8_on(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_utf8_off(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_is_cow(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_is_cow_shared_hash(pTHX_ SV*);
OUROBOROS_STATIC bool ouroboros_sv_tainted(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_tainted_on(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_tainted_off(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_taint(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_share(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_lock(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_unlock(pTHX_ SV*);
OUROBOROS_STATIC U32 ouroboros_sv_get_a_magic(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_magic_set(pTHX_ SV*, MAGIC*);
OUROBOROS_STATIC void ouroboros_sv_get_magic(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_set_magic(pTHX_ SV*);
OUROBOROS_STATIC SV* ouroboros_gv_sv(pTHX_ GV*);
OUROBOROS_STATIC AV* ouroboros_gv_av(pTHX_ GV*);
OUROBOROS_STATIC HV* ouroboros_gv_hv(pTHX_ GV*);
OUROBOROS_STATIC CV* ouroboros_gv_cv(pTHX_ CV*);
OUROBOROS_STATIC HV* ouroboros_sv_stash(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_stash_set(pTHX_ SV*, HV*);
OUROBOROS_STATIC HV* ouroboros_cv_stash(pTHX_ CV*);
OUROBOROS_STATIC const char* ouroboros_hv_name(pTHX_ HV*);
OUROBOROS_STATIC STRLEN ouroboros_hv_name_len(pTHX_ HV*);
OUROBOROS_STATIC unsigned char ouroboros_hv_name_utf8(pTHX_ HV*);
OUROBOROS_STATIC const char* ouroboros_hv_ename(pTHX_ HV*);
OUROBOROS_STATIC STRLEN ouroboros_hv_ename_len(pTHX_ HV*);
OUROBOROS_STATIC unsigned char ouroboros_hv_ename_utf8(pTHX_ HV*);
OUROBOROS_STATIC const char* ouroboros_he_pv(pTHX_ HE*, STRLEN*);
OUROBOROS_STATIC SV* ouroboros_he_val(pTHX_ HE*);
OUROBOROS_STATIC U32 ouroboros_he_hash(pTHX_ HE*);
OUROBOROS_STATIC SV* ouroboros_he_svkey(pTHX_ HE*);
OUROBOROS_STATIC SV* ouroboros_he_svkey_force(pTHX_ HE*);
OUROBOROS_STATIC SV* ouroboros_he_svkey_set(pTHX_ HE*, SV*);
OUROBOROS_STATIC U32 ouroboros_perl_hash(pTHX_ U8*, STRLEN);
OUROBOROS_STATIC U32 ouroboros_sv_refcnt(pTHX_ SV*);
OUROBOROS_STATIC SV* ouroboros_sv_refcnt_inc(pTHX_ SV*);
OUROBOROS_STATIC SV* ouroboros_sv_refcnt_inc_nn(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_refcnt_inc_void(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_refcnt_inc_void_nn(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_refcnt_dec(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_sv_refcnt_dec_nn(pTHX_ SV*);
OUROBOROS_STATIC void ouroboros_enter(pTHX);
OUROBOROS_STATIC void ouroboros_leave(pTHX);
OUROBOROS_STATIC void ouroboros_savetmps(pTHX);
OUROBOROS_STATIC void ouroboros_freetmps(pTHX);
OUROBOROS_STATIC void ouroboros_sys_init3(int*, char***, char***);
OUROBOROS_STATIC void ouroboros_sys_term();
OUROBOROS_STATIC SV* ouroboros_sv_undef(pTHX);
OUROBOROS_STATIC SV* ouroboros_sv_no(pTHX);
OUROBOROS_STATIC SV* ouroboros_sv_yes(pTHX);
OUROBOROS_STATIC U32 ouroboros_gimme(pTHX);
OUROBOROS_STATIC int ouroboros_xcpt_try(pTHX_ ouroboros_xcpt_callback_t, void*);
OUROBOROS_STATIC void ouroboros_xcpt_rethrow(pTHX_ int);
/* } */

#endif
