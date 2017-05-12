#ifndef PIG_H
#define PIG_H

/*
 * Primary Pig header
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#ifdef PIG_QT

// Qt defines its own bool type which we need to honor for PerlQt

#undef bool
#define QT_CLEAN_NAMESPACE
#define NO_DEBUG
#define NO_CHECK
#undef ASSERT
#include "qglobal.h"
#undef CHECK_PTR
#undef NO_CHECK
#undef NO_DEBUG
#endif  // PIG_QT

#include "pigdebug.h"

struct pig_symboltable {
    const char *pigname;
    void *pigptr;
};

#ifdef PIGPTR_DEFINITION
#define PIG_DECLARE_VARIABLE(type, name) type *_ ## name;
#else
#define PIG_DECLARE_VARIABLE(type, name) extern type *_ ## name;
#endif

#define PIG_DEFINE_VARIABLE(type, name) static type __ ## name
#define PIG_VARIABLE(name) (*_ ## name)

#define PIG_EXPORTTABLE(name) name ## _export
#define PIG_IMPORTTABLE(name) name ## _import

#define PIG_GLOBAL_EXPORT_TABLE(name) struct pig_symboltable PIG_EXPORTTABLE(name)[] = {
#define PIG_EXPORT_TABLE(name) PIG_GLOBAL_EXPORT_TABLE(name)
#define PIG_EXPORT_EXPLICIT(string, pointer) { string, (void *)pointer },
#define PIG_EXPORT_ENDTABLE { 0, 0 } };

#define PIG_EXPORT_TYPE(name, type) PIG_EXPORT_EXPLICIT("type " ## type, &__ ## name)
#define PIG_EXPORT_FUNC(name) PIG_EXPORT_EXPLICIT(# name, __ ## name)
#define PIG_EXPORT_VIRTUAL(proto, pointer) PIG_EXPORT_EXPLICIT("virtual " ## proto, pointer)
#define PIG_EXPORT_VARIABLE(name) PIG_EXPORT_EXPLICIT(# name, &__ ## name)
#define PIG_EXPORT_SUBTABLE(name) PIG_EXPORT_EXPLICIT(0, &PIG_EXPORTTABLE(name))

#ifdef PIGPTR_DEFINITION
#define PIG_GLOBAL_IMPORT_TABLE(name) struct pig_symboltable PIG_IMPORTTABLE(name)[] = {
#define PIG_IMPORT_TABLE(name) static PIG_GLOBAL_IMPORT_TABLE(name)
#define PIG_IMPORT_EXPLICIT(string, pointer) { string, (void *)pointer },
#define PIG_IMPORT_ENDTABLE { 0, 0 } };
#else
#define PIG_GLOBAL_IMPORT_TABLE(name)
#define PIG_IMPORT_TABLE(name)
#define PIG_IMPORT_EXPLICIT(string, pointer)
#define PIG_IMPORT_ENDTABLE
#endif // PIGPTR_DEFINITION

#define PIG_IMPORT_TYPE(name, type) PIG_IMPORT_EXPLICIT("type " ## type, &_ ## name)
#define PIG_IMPORT_FUNC(name) PIG_IMPORT_EXPLICIT(# name, &_ ## name)
#define PIG_IMPORT_VIRTUAL(proto, pointer) PIG_IMPORT_EXPLICIT("virtual " ## proto, pointer)
#define PIG_IMPORT_VARIABLE(name) PIG_IMPORT_EXPLICIT(# name, &_ ## name)
#define PIG_IMPORT_SUBTABLE(name) PIG_IMPORT_EXPLICIT(0, &PIG_IMPORTTABLE(name))

#define PIG_DECLARE_EXPORT_TABLE(name) extern struct pig_symboltable PIG_EXPORTTABLE(name)[];
#define PIG_DECLARE_IMPORT_TABLE(name) extern struct pig_symboltable PIG_IMPORTTABLE(name)[];
#define PIG_DECLARE_TABLES(name) PIG_DECLARE_EXPORT_TABLE(name) PIG_DECLARE_IMPORT_TABLE(name)

struct pig_method {
    const char *pigmethodname;
    void (*pigmethodfptr)(void *);
};

struct pig_constant {
    void *pigconstantlist;
    int pigtype;
};

struct pig_constant_int {
    const char *pigname;
    long pigval;
};

struct pig_constant_object {
    const char *pigname;
    void *pigptr;
    const char *pigtype;
};

struct pig_classinfo {
    const char *pigclassname;
    const char *pigalias;
    pig_method *pigmethodlist;
    pig_constant *pigconstant;
    const char **pigisa;
    void *(*pigtocastfunc)(const char *, void *);
    void *(*pigfromcastfunc)(const char *, void *);
    unsigned int pigclassinfo;
};


#define PIG_CONSTANT_INT 1
#define PIG_CONSTANT_OBJECT 2

#define PIG_CLASS_SUICIDAL 0x1

#define PIG_PROTONAME(name) name
#define PIG_PROTO(name) void PIG_PROTONAME(name)(void *pigCV)

#define PIG_BEGIN(method) pig_begin(pigCV, # method)
#define PIG_VIRTUAL(method) pig_begin_virtual(pig0, # method)
#define PIG_END_ARGUMENTS pig_lastargument()
#define PIG_END pig_end()

#define PIGTYPE_UNDEF    0x01
#define PIGTYPE_STRING   0x02
#define PIGTYPE_INT      0x04
#define PIGTYPE_FLOAT    0x08
#define PIGTYPE_BOOL     0x10
#define PIGTYPE_OBJECT   0x20
#define PIGTYPE_REF      0x40

#define pig_is_undef(idx) (pigi##idx & PIGTYPE_UNDEF)
#define pig_is_string(idx) (pigi##idx & PIGTYPE_STRING)
#define pig_is_int(idx) (pigi##idx & PIGTYPE_INT)
#define pig_is_float(idx) (pigi##idx & PIGTYPE_FLOAT)
#define pig_is_bool(idx) (pigi##idx & PIGTYPE_BOOL)
#define pig_is_number(idx) (pig_is_int(idx) || pig_is_float(idx))
#define pig_is_object(idx) (pigi##idx & PIGTYPE_OBJECT)
#define pig_is_class(idx, class) (pig_is_object(idx) && pig_object_isa(idx, class))

#define pig_is_mystery(idx) (!pig_is_object(idx) && !pig_is_number(idx))

#endif  // PIG_H
