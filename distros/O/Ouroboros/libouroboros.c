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
#include "libouroboros.h"

void ouroboros_stack_init(pTHX_ ouroboros_stack_t* stack)
{
        dXSARGS;
        SP -= items;
        stack->sp = sp;
        stack->mark = mark;
        stack->ax = ax;
        stack->items = items;
}

int ouroboros_stack_items(pTHX_ ouroboros_stack_t* stack)
{
	return stack->items;
}

#define sp (stack->sp)
#define mark (stack->mark)
#define ax (stack->ax)
#define items (stack->items)

SV* ouroboros_stack_fetch(pTHX_ ouroboros_stack_t* stack, SSize_t item)
{
        return ST(item);
}

void ouroboros_stack_store(pTHX_ ouroboros_stack_t* stack, SSize_t item, SV* value)
{
        ST(item) = value;
}

int ouroboros_xcpt_try(pTHX_ ouroboros_xcpt_callback_t cb, void* arg)
{
	int rc = 0;
	dJMPENV;
	JMPENV_PUSH(rc);
	if (rc == 0) {
		cb(arg);
	}
	JMPENV_POP;
	return rc;
}

void ouroboros_xcpt_rethrow(pTHX_ int rc)
{
	JMPENV_JUMP(rc);
}

U32 ouroboros_perl_hash(pTHX_ U8* key, STRLEN len)
{
	U32 hash;
	PERL_HASH(hash, key, len);
	return hash;
}

SV* ouroboros_sv_undef(pTHX)
{
        return &PL_sv_undef;
}

SV* ouroboros_sv_no(pTHX)
{
        return &PL_sv_no;
}

SV* ouroboros_sv_yes(pTHX)
{
        return &PL_sv_yes;
}

/* functions { */
void ouroboros_stack_putback(pTHX_ ouroboros_stack_t* stack)
{
        PUTBACK;
}

void ouroboros_stack_extend(pTHX_ ouroboros_stack_t* stack, SSize_t a)
{
        EXTEND(SP, a);
}

void ouroboros_stack_pushmark(pTHX_ ouroboros_stack_t* stack)
{
        PUSHMARK(SP);
}

void ouroboros_stack_spagain(pTHX_ ouroboros_stack_t* stack)
{
        SPAGAIN;
}

void ouroboros_stack_xpush_sv(pTHX_ ouroboros_stack_t* stack, SV* sv)
{
        XPUSHs(sv);
}

void ouroboros_stack_xpush_sv_mortal(pTHX_ ouroboros_stack_t* stack, SV* sv)
{
        mXPUSHs(sv);
}

void ouroboros_stack_xpush_iv(pTHX_ ouroboros_stack_t* stack, IV a)
{
        mXPUSHi(a);
}

void ouroboros_stack_xpush_uv(pTHX_ ouroboros_stack_t* stack, UV a)
{
        mXPUSHu(a);
}

void ouroboros_stack_xpush_nv(pTHX_ ouroboros_stack_t* stack, NV a)
{
        mXPUSHn(a);
}

void ouroboros_stack_xpush_pv(pTHX_ ouroboros_stack_t* stack, const char* a, STRLEN b)
{
        mXPUSHp(a, b);
}

void ouroboros_stack_xpush_mortal(pTHX_ ouroboros_stack_t* stack)
{
        XPUSHmortal;
}

void ouroboros_stack_push_sv(pTHX_ ouroboros_stack_t* stack, SV* sv)
{
        PUSHs(sv);
}

void ouroboros_stack_push_sv_mortal(pTHX_ ouroboros_stack_t* stack, SV* sv)
{
        mPUSHs(sv);
}

void ouroboros_stack_push_iv(pTHX_ ouroboros_stack_t* stack, IV a)
{
        mPUSHi(a);
}

void ouroboros_stack_push_uv(pTHX_ ouroboros_stack_t* stack, UV a)
{
        mPUSHu(a);
}

void ouroboros_stack_push_nv(pTHX_ ouroboros_stack_t* stack, NV a)
{
        mPUSHn(a);
}

void ouroboros_stack_push_pv(pTHX_ ouroboros_stack_t* stack, const char* a, STRLEN b)
{
        mPUSHp(a, b);
}

void ouroboros_stack_push_mortal(pTHX_ ouroboros_stack_t* stack)
{
        PUSHmortal;
}

void ouroboros_sv_upgrade(pTHX_ SV* sv, svtype a)
{
        SvUPGRADE(sv, a);
}

U32 ouroboros_sv_niok(pTHX_ SV* sv)
{
        return SvNIOK(sv);
}

U32 ouroboros_sv_niok_priv(pTHX_ SV* sv)
{
        return SvNIOKp(sv);
}

void ouroboros_sv_niok_off(pTHX_ SV* sv)
{
        SvNIOK_off(sv);
}

U32 ouroboros_sv_ok(pTHX_ SV* sv)
{
        return SvOK(sv);
}

U32 ouroboros_sv_iok_priv(pTHX_ SV* sv)
{
        return SvIOKp(sv);
}

U32 ouroboros_sv_nok_priv(pTHX_ SV* sv)
{
        return SvNOKp(sv);
}

U32 ouroboros_sv_pok_priv(pTHX_ SV* sv)
{
        return SvPOKp(sv);
}

U32 ouroboros_sv_iok(pTHX_ SV* sv)
{
        return SvIOK(sv);
}

void ouroboros_sv_iok_on(pTHX_ SV* sv)
{
        SvIOK_on(sv);
}

void ouroboros_sv_iok_off(pTHX_ SV* sv)
{
        SvIOK_off(sv);
}

void ouroboros_sv_iok_only(pTHX_ SV* sv)
{
        SvIOK_only(sv);
}

void ouroboros_sv_iok_only_uv(pTHX_ SV* sv)
{
        SvIOK_only_UV(sv);
}

bool ouroboros_sv_iok_uv(pTHX_ SV* sv)
{
        return SvIOK_UV(sv);
}

bool ouroboros_sv_uok(pTHX_ SV* sv)
{
        return SvUOK(sv);
}

bool ouroboros_sv_iok_not_uv(pTHX_ SV* sv)
{
        return SvIOK_notUV(sv);
}

U32 ouroboros_sv_nok(pTHX_ SV* sv)
{
        return SvNOK(sv);
}

void ouroboros_sv_nok_on(pTHX_ SV* sv)
{
        SvNOK_on(sv);
}

void ouroboros_sv_nok_off(pTHX_ SV* sv)
{
        SvNOK_off(sv);
}

void ouroboros_sv_nok_only(pTHX_ SV* sv)
{
        SvNOK_only(sv);
}

U32 ouroboros_sv_pok(pTHX_ SV* sv)
{
        return SvPOK(sv);
}

void ouroboros_sv_pok_on(pTHX_ SV* sv)
{
        SvPOK_on(sv);
}

void ouroboros_sv_pok_off(pTHX_ SV* sv)
{
        SvPOK_off(sv);
}

void ouroboros_sv_pok_only(pTHX_ SV* sv)
{
        SvPOK_only(sv);
}

void ouroboros_sv_pok_only_utf8(pTHX_ SV* sv)
{
        SvPOK_only_UTF8(sv);
}

bool ouroboros_sv_vok(pTHX_ SV* sv)
{
        return SvVOK(sv);
}

U32 ouroboros_sv_ook(pTHX_ SV* sv)
{
        return SvOOK(sv);
}

void ouroboros_sv_ook_offset(pTHX_ SV* sv, STRLEN* a)
{
        SvOOK_offset(sv, *a);
}

U32 ouroboros_sv_rok(pTHX_ SV* sv)
{
        return SvROK(sv);
}

void ouroboros_sv_rok_on(pTHX_ SV* sv)
{
        SvROK_on(sv);
}

void ouroboros_sv_rok_off(pTHX_ SV* sv)
{
        SvROK_off(sv);
}

IV ouroboros_sv_iv(pTHX_ SV* sv)
{
        return SvIV(sv);
}

IV ouroboros_sv_iv_nomg(pTHX_ SV* sv)
{
        return SvIV_nomg(sv);
}

IV ouroboros_sv_iv_raw(pTHX_ SV* sv)
{
        return SvIVX(sv);
}

void ouroboros_sv_iv_set(pTHX_ SV* sv, IV a)
{
        SvIV_set(sv, a);
}

UV ouroboros_sv_uv(pTHX_ SV* sv)
{
        return SvUV(sv);
}

UV ouroboros_sv_uv_nomg(pTHX_ SV* sv)
{
        return SvUV_nomg(sv);
}

UV ouroboros_sv_uv_raw(pTHX_ SV* sv)
{
        return SvUVX(sv);
}

void ouroboros_sv_uv_set(pTHX_ SV* sv, UV a)
{
        SvUV_set(sv, a);
}

NV ouroboros_sv_nv(pTHX_ SV* sv)
{
        return SvNV(sv);
}

NV ouroboros_sv_nv_nomg(pTHX_ SV* sv)
{
        return SvNV_nomg(sv);
}

NV ouroboros_sv_nv_raw(pTHX_ SV* sv)
{
        return SvNVX(sv);
}

void ouroboros_sv_nv_set(pTHX_ SV* sv, NV a)
{
        SvNV_set(sv, a);
}

const char* ouroboros_sv_pv(pTHX_ SV* sv, STRLEN* a)
{
        return SvPV(sv, *a);
}

const char* ouroboros_sv_pv_nomg(pTHX_ SV* sv, STRLEN* a)
{
        return SvPV_nomg(sv, *a);
}

const char* ouroboros_sv_pv_nolen(pTHX_ SV* sv)
{
        return SvPV_nolen(sv);
}

const char* ouroboros_sv_pv_nomg_nolen(pTHX_ SV* sv)
{
        return SvPV_nomg_nolen(sv);
}

char* ouroboros_sv_pv_raw(pTHX_ SV* sv)
{
        return SvPVX(sv);
}

STRLEN ouroboros_sv_pv_cur(pTHX_ SV* sv)
{
        return SvCUR(sv);
}

void ouroboros_sv_pv_cur_set(pTHX_ SV* sv, STRLEN a)
{
        SvCUR_set(sv, a);
}

STRLEN ouroboros_sv_pv_len(pTHX_ SV* sv)
{
        return SvLEN(sv);
}

void ouroboros_sv_pv_len_set(pTHX_ SV* sv, STRLEN a)
{
        SvLEN_set(sv, a);
}

char* ouroboros_sv_pv_end(pTHX_ SV* sv)
{
        return SvEND(sv);
}

SV* ouroboros_sv_rv(pTHX_ SV* sv)
{
        return SvRV(sv);
}

void ouroboros_sv_rv_set(pTHX_ SV* sv, SV* sv1)
{
        SvRV_set(sv, sv1);
}

bool ouroboros_sv_true(pTHX_ SV* sv)
{
        return SvTRUE(sv);
}

bool ouroboros_sv_true_nomg(pTHX_ SV* sv)
{
        return SvTRUE_nomg(sv);
}

svtype ouroboros_sv_type(pTHX_ SV* sv)
{
        return SvTYPE(sv);
}

UV ouroboros_sv_flags(pTHX_ SV* sv)
{
        return SvFLAGS(sv);
}

bool ouroboros_sv_utf8(pTHX_ SV* sv)
{
        return SvUTF8(sv);
}

void ouroboros_sv_utf8_on(pTHX_ SV* sv)
{
        SvUTF8_on(sv);
}

void ouroboros_sv_utf8_off(pTHX_ SV* sv)
{
        SvUTF8_off(sv);
}

U32 ouroboros_sv_is_cow(pTHX_ SV* sv)
{
        return SvIsCOW(sv);
}

bool ouroboros_sv_is_cow_shared_hash(pTHX_ SV* sv)
{
        return SvIsCOW_shared_hash(sv);
}

bool ouroboros_sv_tainted(pTHX_ SV* sv)
{
        return SvTAINTED(sv);
}

void ouroboros_sv_tainted_on(pTHX_ SV* sv)
{
        SvTAINTED_on(sv);
}

void ouroboros_sv_tainted_off(pTHX_ SV* sv)
{
        SvTAINTED_off(sv);
}

void ouroboros_sv_taint(pTHX_ SV* sv)
{
        SvTAINT(sv);
}

void ouroboros_sv_share(pTHX_ SV* sv)
{
        SvSHARE(sv);
}

void ouroboros_sv_lock(pTHX_ SV* sv)
{
        SvLOCK(sv);
}

void ouroboros_sv_unlock(pTHX_ SV* sv)
{
        SvUNLOCK(sv);
}

U32 ouroboros_sv_get_a_magic(pTHX_ SV* sv)
{
        return SvGAMAGIC(sv);
}

void ouroboros_sv_magic_set(pTHX_ SV* sv, MAGIC* a)
{
        SvMAGIC_set(sv, a);
}

void ouroboros_sv_get_magic(pTHX_ SV* sv)
{
        SvGETMAGIC(sv);
}

void ouroboros_sv_set_magic(pTHX_ SV* sv)
{
        SvSETMAGIC(sv);
}

SV* ouroboros_gv_sv(pTHX_ GV* a)
{
        return GvSV(a);
}

AV* ouroboros_gv_av(pTHX_ GV* a)
{
        return GvAV(a);
}

HV* ouroboros_gv_hv(pTHX_ GV* a)
{
        return GvHV(a);
}

CV* ouroboros_gv_cv(pTHX_ CV* a)
{
        return GvCV(a);
}

HV* ouroboros_sv_stash(pTHX_ SV* sv)
{
        return SvSTASH(sv);
}

void ouroboros_sv_stash_set(pTHX_ SV* sv, HV* a)
{
        SvSTASH_set(sv, a);
}

void ouroboros_cv_stash(pTHX_ CV* a)
{
        CvSTASH(a);
}

const char* ouroboros_hv_name(pTHX_ HV* a)
{
        return HvNAME(a);
}

STRLEN ouroboros_hv_name_len(pTHX_ HV* a)
{
        return HvNAMELEN(a);
}

unsigned char ouroboros_hv_name_utf8(pTHX_ HV* a)
{
        return HvNAMEUTF8(a);
}

const char* ouroboros_hv_ename(pTHX_ HV* a)
{
        return HvENAME(a);
}

STRLEN ouroboros_hv_ename_len(pTHX_ HV* a)
{
        return HvENAMELEN(a);
}

unsigned char ouroboros_hv_ename_utf8(pTHX_ HV* a)
{
        return HvENAMEUTF8(a);
}

const char* ouroboros_he_pv(pTHX_ HE* a, STRLEN* b)
{
        return HePV(a, *b);
}

SV* ouroboros_he_val(pTHX_ HE* a)
{
        return HeVAL(a);
}

U32 ouroboros_he_hash(pTHX_ HE* a)
{
        return HeHASH(a);
}

SV* ouroboros_he_svkey(pTHX_ HE* a)
{
        return HeSVKEY(a);
}

SV* ouroboros_he_svkey_force(pTHX_ HE* a)
{
        return HeSVKEY_force(a);
}

SV* ouroboros_he_svkey_set(pTHX_ HE* a, SV* sv)
{
        return HeSVKEY_set(a, sv);
}

U32 ouroboros_sv_refcnt(pTHX_ SV* sv)
{
        return SvREFCNT(sv);
}

SV* ouroboros_sv_refcnt_inc(pTHX_ SV* sv)
{
        return SvREFCNT_inc_simple(sv);
}

SV* ouroboros_sv_refcnt_inc_nn(pTHX_ SV* sv)
{
        return SvREFCNT_inc_simple_NN(sv);
}

void ouroboros_sv_refcnt_inc_void(pTHX_ SV* sv)
{
        SvREFCNT_inc_simple_void(sv);
}

void ouroboros_sv_refcnt_inc_void_nn(pTHX_ SV* sv)
{
        SvREFCNT_inc_simple_void_NN(sv);
}

void ouroboros_sv_refcnt_dec(pTHX_ SV* sv)
{
        SvREFCNT_dec(sv);
}

void ouroboros_sv_refcnt_dec_nn(pTHX_ SV* sv)
{
        SvREFCNT_dec_NN(sv);
}

void ouroboros_enter(pTHX)
{
        ENTER;
}

void ouroboros_leave(pTHX)
{
        LEAVE;
}

void ouroboros_savetmps(pTHX)
{
        SAVETMPS;
}

void ouroboros_freetmps(pTHX)
{
        FREETMPS;
}

void ouroboros_sys_init3(int* a, char*** b, char*** c)
{
        PERL_SYS_INIT3(a, b, c);
}

void ouroboros_sys_term()
{
        PERL_SYS_TERM();
}

U32 ouroboros_gimme(pTHX)
{
        return GIMME_V;
}
/* } */
