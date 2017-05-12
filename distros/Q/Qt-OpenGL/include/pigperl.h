#ifndef PIGPERL_H
#define PIGPERL_H

/*
 * Perl-specific implementation of Pig for PerlQt
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

extern "C" {
#if PIGPERL_PL < 4
#define debug PIGdebug
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#undef debug
#undef dirty
}

#undef bool
#undef list

#undef METHOD
#undef debug

#ifndef PIGPERL_PL
#error PIGPERL_PL must be set to $Config{'PATCHLEVEL'}
#endif

#ifndef PIGPERL_SV
#error PIGPERL_SV must be set to $Config{'SUBVERSION'}
#endif

#include "pig.h"
#include "pigtype.h"
#include "pigfunc.h"
#include "qmetaobject.h"

#define PIG_NUM_SHORT           0x0001
#define PIG_NUM_INT             0x0002
#define PIG_NUM_LONG            0x0004
#define PIG_NUM_LONG_LONG       0x0008
#define PIG_NUM_SIGNED          0x0010
#define PIG_NUM_UNSIGNED        0x0020
#define PIG_NUM_FLOAT           0x0100
#define PIG_NUM_DOUBLE          0x0200

#define PIG_PROTO_CONST         0
#define PIG_PROTO_OBJECT        1
#define PIG_PROTO_LONG          2
#define PIG_PROTO_INT           3
#define PIG_PROTO_SHORT         4
#define PIG_PROTO_BOOL          5
#define PIG_PROTO_STRING        6
#define PIG_PROTO_LDOUBLE       7
#define PIG_PROTO_DOUBLE        8
#define PIG_PROTO_FLOAT         9
#define PIG_PROTO_SCALAR        10
#define PIG_PROTO_SCALARREF     11
#define PIG_PROTO_SVSCALAR      12
#define PIG_PROTO_AVSCALAR      13
#define PIG_PROTO_HVSCALAR      14
#define PIG_PROTO_LIST          15

#if PIGPERL_PL >= 5
#define PIGstack_base PL_stack_base
#define PIGstack_sp PL_stack_sp
#define PIGsv_yes PL_sv_yes
#define PIGsv_no PL_sv_no
#define PIGsv_undef PL_sv_undef
#define PIGdowarn PL_dowarn
#define PIGcurcop PL_curcop
#else
#define PIGstack_base stack_base
#define PIGstack_sp stack_sp
#define PIGsv_yes sv_yes
#define PIGsv_no sv_no
#define PIGsv_undef sv_undef
#define PIGdowarn dowarn
#define PIGcurcop curcop
#endif

#ifndef dTHR
#define dTHR
#endif

typedef void (*pigscopefptr)(void *);

struct pig_sub_scope {
    struct pig_sub_scope *pignext;
    pigscopefptr pigfptr;
    void *pigdata;
};

struct pig_sub_frame {
    struct pig_sub_frame *pignext;
    struct pig_sub_scope *pigscope;
    I32 pigax;
};

PIG_DECLARE_VARIABLE(SV *, pig_virtual_return)
PIG_DECLARE_VARIABLE(int, pig_argument_idx)
PIG_DECLARE_VARIABLE(int, pig_argument_max_idx)
PIG_DECLARE_VARIABLE(int, pig_depth)
PIG_DECLARE_VARIABLE(struct pig_sub_frame *, pig_frame)
PIG_DECLARE_VARIABLE(HV *, pig_classinfo)
PIG_DECLARE_VARIABLE(HV *, pig_classinfo_hv)
PIG_DECLARE_VARIABLE(HV *, pig_classmap_hv)
PIG_DECLARE_VARIABLE(HV *, pig_classunmap_hv)

PIG_DECLARE_FUNC_2(SV *, pig_object_create, const char *, struct pig_object_data **)
PIG_DECLARE_FUNC_1(struct pig_object_data *, pig_object_extract, SV *)
PIG_DECLARE_FUNC_2(void *, pig_object_cast, struct pig_object_data *, const char *)
PIG_DECLARE_VOID_FUNC_1(pig_sub_enter, struct pig_sub_frame *)
PIG_DECLARE_VOID_FUNC_0(pig_sub_leave)
PIG_DECLARE_VOID_FUNC_1(pig_scope_leave, struct pig_sub_scope *)

PIG_DECLARE_VOID_FUNC_2(pig_constant_load, const pig_constant *, const char *)

PIG_DECLARE_FUNC_2(bool, pig_receiver_defined, SV *, SV *)
PIG_DECLARE_FUNC_2(class QObject *, pig_create_slot, SV *, SV *)
PIG_DECLARE_FUNC_2(const char *, pig_member_string, SV *, SV *)

PIG_DECLARE_VOID_FUNC_1(pig_module_used, const char *)
PIG_DECLARE_FUNC_1(HV *, pig_map_class_stash, const char *)

PIG_DECLARE_FUNC_3(SV *, pig_new_castobject, void *, const char *, const char *)

PIG_DECLARE_FUNC_2(class QMetaObject *, pig_createMetaObject, const char *, class QMetaObject *)
PIG_DECLARE_FUNC_1(class QMetaObject *, pig_initMetaObject, const char *)
PIG_DECLARE_FUNC_1(int, pig_sigslot_hash, const char *)
PIG_DECLARE_FUNC_1(QMember, pig_sigslot_stub, SV *)

PIG_DECLARE_FUNC_1(SV *, pig_map_proto, SV *)
PIG_DECLARE_FUNC_1(SV *, pig_parse_proto, SV *)

PIG_DECLARE_VOID_FUNC_2(pig_scope_argument, pigscopefptr, void *)
PIG_DECLARE_VOID_FUNC_2(pig_scope_virtual, pigscopefptr, void *)

PIG_IMPORT_TABLE(pigperl)
    PIG_IMPORT_VARIABLE(pig_classinfo)
    PIG_IMPORT_VARIABLE(pig_classinfo_hv)
    PIG_IMPORT_VARIABLE(pig_classmap_hv)
    PIG_IMPORT_VARIABLE(pig_classunmap_hv)
    PIG_IMPORT_VARIABLE(pig_virtual_return)
    PIG_IMPORT_VARIABLE(pig_argument_idx)
    PIG_IMPORT_VARIABLE(pig_argument_max_idx)
    PIG_IMPORT_VARIABLE(pig_depth)
    PIG_IMPORT_VARIABLE(pig_frame)
    PIG_IMPORT_FUNC(pig_map_class_stash)
    PIG_IMPORT_FUNC(pig_constant_load)
    PIG_IMPORT_FUNC(pig_object_create)
    PIG_IMPORT_FUNC(pig_object_extract)
    PIG_IMPORT_FUNC(pig_object_cast)
    PIG_IMPORT_FUNC(pig_sub_enter)
    PIG_IMPORT_FUNC(pig_sub_leave)
    PIG_IMPORT_FUNC(pig_receiver_defined)
    PIG_IMPORT_FUNC(pig_create_slot)
    PIG_IMPORT_FUNC(pig_member_string)
    PIG_IMPORT_FUNC(pig_module_used)
    PIG_IMPORT_FUNC(pig_new_castobject)
    PIG_IMPORT_FUNC(pig_createMetaObject)
    PIG_IMPORT_FUNC(pig_initMetaObject)
    PIG_IMPORT_FUNC(pig_sigslot_hash)
    PIG_IMPORT_FUNC(pig_sigslot_stub)
    PIG_IMPORT_FUNC(pig_map_proto)
    PIG_IMPORT_FUNC(pig_parse_proto)
    PIG_IMPORT_FUNC(pig_scope_argument)
    PIG_IMPORT_FUNC(pig_scope_virtual)
    PIG_IMPORT_FUNC(pig_scope_leave)
PIG_IMPORT_ENDTABLE

#define pig_virtual_return PIG_VARIABLE(pig_virtual_return)
#define pig_argument_idx PIG_VARIABLE(pig_argument_idx)
#define pig_argument_max_idx PIG_VARIABLE(pig_argument_max_idx)
#define pig_depth PIG_VARIABLE(pig_depth)
#define pig_frame PIG_VARIABLE(pig_frame)
#define pig_frame_ax (pig_frame->pigax)

#define PIG_TOPSTACK pig_virtual_return
#define PIG_ARG ST(pig_argument_idx)
#define PIG_ARGOK ((pig_argument_idx < pig_argument_max_idx) && SvOK(PIG_ARG))
#define PIG_RETARG ST(0)
#define PIGNEXTARG pig_argument_idx++

#define PIGARGUMENTS dTHR; I32 ax = pig_frame_ax
#define PIGARGS \
    dTHR; \
    I32 ax = pig_frame_ax; \
    if(pig_argument_idx < pig_argument_max_idx && SvGMAGICAL(PIG_ARG)) \
        mg_get(PIG_ARG)

#define PIGRET PIGARGS
#define PIGPUSHSTACK dSP
#define PIGPOPSTACK dTHR

#define PIGARGUMENT(value) STMT_START { PIGNEXTARG; return value; } STMT_END
#define PIGRETURN(value) PIG_RETARG = value; XSRETURN(1)
#define PIGPUSH(sv) XPUSHs(sv); PUTBACK; return
//#define PIGPOP(value) return SvREFCNT_dec(PIG_TOPSTACK), value
#define PIGPOP(value) return value

#define PIGSCOPE_ARGUMENT(name, var) \
pig_scope_argument(&__ ## name ## _scope_argument, var)

#define PIGSCOPE_VIRTUAL(name, var) \
pig_scope_virtual(&__ ## name ## _scope_virtual, var)

#endif
