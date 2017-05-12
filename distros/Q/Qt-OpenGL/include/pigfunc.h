#ifndef PIGFUNC_H
#define PIGFUNC_H

/*
 * Macros to declare and define functions for import and export
 * using Pig symbol-tables.
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

#include "pigtype.h"

#define PIG_DECLARE_FUNC_0(ret, name)		\
PIGFPTR _ ## name;				\
inline ret name() {				\
    return (*(ret (*)())_ ## name)();		\
}

#define PIG_DECLARE_FUNC_1(ret, name, t0)	\
PIGFPTR _ ## name;				\
inline ret name(t0 pig0) {			\
    return (*(ret (*)(t0))_ ## name)(pig0);	\
}

#define PIG_DECLARE_FUNC_2(ret, name, t0, t1)	\
PIGFPTR _ ## name;				\
inline ret name(t0 pig0, t1 pig1) {		\
    return (*(ret (*)(t0, t1))_ ## name)(pig0, pig1);	\
}

#define PIG_DECLARE_FUNC_3(ret, name, t0, t1, t2)	\
PIGFPTR _ ## name;					\
inline ret name(t0 pig0, t1 pig1, t2 pig2) {		\
    return (*(ret (*)(t0, t1, t2))_ ## name)(pig0, pig1, pig2);	\
}

#define PIG_DECLARE_FUNC_4(ret, name, t0, t1, t2, t3)	\
PIGFPTR _ ## name;					\
inline ret name(t0 pig0, t1 pig1, t2 pig2, t3 pig3) {	\
    return (*(ret (*)(t0, t1, t2, t3))_ ## name)(pig0, pig1, pig2, pig3);\
}

#define PIG_DECLARE_VOID_FUNC_0(name)		\
PIGFPTR _ ## name;				\
inline void name() {				\
    (*(void (*)())_ ## name)();			\
}

#define PIG_DECLARE_VOID_FUNC_1(name, t0)	\
PIGFPTR _ ## name;				\
inline void name(t0 pig0) {			\
    (*(void (*)(t0))_ ## name)(pig0);		\
}

#define PIG_DECLARE_VOID_FUNC_2(name, t0, t1)	\
PIGFPTR _ ## name;				\
inline void name(t0 pig0, t1 pig1) {		\
    (*(void (*)(t0, t1))_ ## name)(pig0, pig1);	\
}

#define PIG_DECLARE_VOID_FUNC_3(name, t0, t1, t2)	\
PIGFPTR _ ## name;					\
inline void name(t0 pig0, t1 pig1, t2 pig2) {		\
    (*(void (*)(t0, t1, t2))_ ## name)(pig0, pig1, pig2);\
}

#define PIG_DECLARE_VOID_FUNC_4(name, t0, t1, t2, t3)	\
PIGFPTR _ ## name;					\
inline void name(t0 pig0, t1 pig1, t2 pig2, t3 pig3) {	\
    (*(void (*)(t0, t1, t2, t3))_ ## name)(pig0, pig1, pig2, pig3);\
}

#define PIG_DEFINE_FUNC_0(ret, name) \
static ret __ ## name()

#define PIG_DEFINE_FUNC_1(ret, name, t0) \
static ret __ ## name(t0 pig0)

#define PIG_DEFINE_FUNC_2(ret, name, t0, t1) \
static ret __ ## name(t0 pig0, t1 pig1)

#define PIG_DEFINE_FUNC_3(ret, name, t0, t1, t2) \
static ret __ ## name(t0 pig0, t1 pig1, t2 pig2)

#define PIG_DEFINE_FUNC_4(ret, name, t0, t1, t2, t3) \
static ret __ ## name(t0 pig0, t1 pig1, t2 pig2, t3 pig3)


#define PIG_DEFINE_VOID_FUNC_0(name) \
static void __ ## name()

#define PIG_DEFINE_VOID_FUNC_1(name, t0) \
static void __ ## name(t0 pig0)

#define PIG_DEFINE_VOID_FUNC_2(name, t0, t1) \
static void __ ## name(t0 pig0, t1 pig1)

#define PIG_DEFINE_VOID_FUNC_3(name, t0, t1, t2) \
static void __ ## name(t0 pig0, t1 pig1, t2 pig2)

#define PIG_DEFINE_VOID_FUNC_4(name, t0, t1, t2, t3) \
static void __ ## name(t0 pig0, t1 pig1, t2 pig2, t3 pig3)


#define PIG_DEFINE_STUB_0(ret, name) \
static ret __ ## name() { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
    return 0; \
}

#define PIG_DEFINE_STUB_1(ret, name, t0) \
static ret __ ## name(t0) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
    return 0; \
}

#define PIG_DEFINE_STUB_2(ret, name, t0, t1) \
static ret __ ## name(t0, t1) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
    return 0; \
}

#define PIG_DEFINE_STUB_3(ret, name, t0, t1, t2) \
static ret __ ## name(t0, t1, t2) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
    return 0; \
}

#define PIG_DEFINE_STUB_4(ret, name, t0, t1, t2, t3) \
static ret __ ## name(t0, t1, t2, t3) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
    return 0; \
}


#define PIG_DEFINE_VOID_STUB_0(name) \
static void __ ## name() { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
}

#define PIG_DEFINE_VOID_STUB_1(name, t0) \
static void __ ## name(t0) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
}

#define PIG_DEFINE_VOID_STUB_2(name, t0, t1) \
static void __ ## name(t0, t1) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
}

#define PIG_DEFINE_VOID_STUB_3(name, t0, t1, t2) \
static void __ ## name(t0, t1, t2) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
}

#define PIG_DEFINE_VOID_STUB_4(name, t0, t1, t2, t3) \
static void __ ## name(t0, t1, t2, t3) { \
    croak("Undefined function %s at %s:%d called", #name, __FILE__,__LINE__); \
}

#endif  // PIGFUNC_H
