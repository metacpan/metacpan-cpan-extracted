#ifndef PIGTYPE_OBJECT_H
#define PIGTYPE_OBJECT_H

/*
 * Pig support for the basic C++ class objects
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigtype.h"
#include "pigfunc.h"

#define PIGOBJECT_ALLOCATED	0x01
#define PIGOBJECT_CONST		0x02

#define PIGOBJECT_CONSTED	0x10
#define PIGOBJECT_MUTED		0x20
#define PIGOBJECT_IMMORTALIZED	0x40
#define PIGOBJECT_MORTALIZED	0x80
#define PIGOBJECT_BREAK		0x100
#define PIGOBJECT_CONTINUED	0x200

#define PIGTYPEOBJECT_ARGUMENT(name, type) \
inline type name ## _argument(const char *pig0) { \
    return (*(type (*)(const char *))(_ ## name->pigargument))(pig0); \
}

#define PIGTYPEOBJECT_DEFARGUMENT(name, type) \
inline type name ## _defargument(type pig0, const char *pig1) { \
    return (*(type (*)(type, const char *))(_ ## name->pigdefargument))(pig0, pig1); \
}

#define PIGTYPEOBJECT_RETURN(name, type) \
inline void name ## _return(type pig0, const char *pig1) { \
    (*(void (*)(type, const char *))(_ ## name->pigreturn))(pig0, pig1); \
}

#define PIGTYPEOBJECT_PUSH(name, type) \
inline void name ## _push(type pig0, const char *pig1) { \
    (*(void (*)(type, const char *))(_ ## name->pigpush))(pig0, pig1); \
}

#define PIGTYPEOBJECT_POP(name, type) \
inline type name ## _pop(const char *pig0) { \
    return (*(type (*)(const char *))(_ ## name->pigpop))(pig0); \
}

#define PIGTYPEOBJECT_ALL(name, type) \
PIGTYPEOBJECT_ARGUMENT(name, type)    \
PIGTYPEOBJECT_DEFARGUMENT(name, type) \
PIGTYPEOBJECT_RETURN(name, type)      \
PIGTYPEOBJECT_PUSH(name, type)        \
PIGTYPEOBJECT_POP(name, type)

PIG_DECLARE_TYPE(pig_type_object)
PIG_DECLARE_TYPE(pig_type_object_ref)
PIG_DECLARE_TYPE(pig_type_const_object)
PIG_DECLARE_TYPE(pig_type_const_object_ref)
PIG_DECLARE_TYPE(pig_type_this_object)
PIG_DECLARE_TYPE(pig_type_this_const_object)

PIGTYPEOBJECT_ALL(pig_type_object, void *)
PIGTYPEOBJECT_ALL(pig_type_object_ref, void *)
PIGTYPEOBJECT_ALL(pig_type_const_object, const void *)
PIGTYPEOBJECT_ALL(pig_type_const_object_ref, const void *)
PIGTYPEOBJECT_ALL(pig_type_this_object, void *)
PIGTYPEOBJECT_ALL(pig_type_this_const_object, void *)

struct pig_object_data {
    const void *pigptr;
    struct pig_classinfo *piginfo;
    long pigflags;
};

PIG_DECLARE_VOID_FUNC_2(pig_type_new_object_return, void *, const char *)
PIG_DECLARE_VOID_FUNC_3(pig_type_new_castobject_return, void *, const char *, const char *)
PIG_DECLARE_FUNC_1(void *, pig_type_object_destructor_argument, const char *)

PIG_IMPORT_TABLE(pigtype_object)
    PIG_IMPORT_TYPE(pig_type_object, "object")
    PIG_IMPORT_TYPE(pig_type_object_ref, "object&")
    PIG_IMPORT_TYPE(pig_type_const_object, "const object")
    PIG_IMPORT_TYPE(pig_type_const_object_ref, "const object&")
    PIG_IMPORT_TYPE(pig_type_this_object, "this")
    PIG_IMPORT_TYPE(pig_type_this_const_object, "const this")
    PIG_IMPORT_FUNC(pig_type_new_object_return)
    PIG_IMPORT_FUNC(pig_type_new_castobject_return)
    PIG_IMPORT_FUNC(pig_type_object_destructor_argument)
PIG_IMPORT_ENDTABLE

#endif  // PIGTYPEOBJECT_OBJECT_H
