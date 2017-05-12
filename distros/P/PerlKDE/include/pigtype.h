#ifndef PIGTYPE_H
#define PIGTYPE_H

/*
 * Macros to assist in creating valid functions to support Pig types
 * through the pig_type structure
 *
 * Copyright (C) 1999, Ashley Winters <jql@accessone.com>
 *
 * You may distribute under the terms of the LGPL as specified in the
 * README.LICENSE file which should be included with this library.
 *
 */

typedef void (*pigfptr)();

typedef struct pig_type {
    pigfptr pigargument;
    pigfptr pigdefargument;
    pigfptr pigreturn;
    pigfptr pigpush;
    pigfptr pigpop;
    void *pigex;
} *pigtptr;

typedef void *pigvoidptr;

#ifdef PIGPTR_DEFINITION
#define PIGPTR
#else
#define PIGPTR extern
#endif

#define PIGFPTR PIGPTR pigfptr
#define PIGTPTR PIGPTR pigtptr

#define PIGTYPE_ARGUMENT(name, type)				\
inline type name ## _argument() {				\
    return (*(type (*)())(_ ## name->pigargument))();		\
}

#define PIGTYPE_DEFARGUMENT(name, type)				\
inline type name ## _defargument(type pig0) {			\
    return (*(type (*)(type))(_ ## name->pigdefargument))(pig0);\
}

#define PIGTYPE_CONST_DEFARGUMENT(name, type)			\
inline type name ## _defargument(const type pig0) {		\
    return (*(type (*)(const type))(_ ## name->pigdefargument))(pig0);\
}

#define PIGTYPE_RETURN(name, type)				\
inline void name ## _return(type pig0) {			\
    (*(void (*)(type))(_ ## name->pigreturn))(pig0);		\
}

#define PIGTYPE_PUSH(name, type)				\
inline void name ## _push(type pig0) {				\
    (*(void (*)(type))(_ ## name->pigpush))(pig0);		\
}

#define PIGTYPE_POP(name, type)					\
inline type name ## _pop() {					\
    return (*(type (*)())(_ ## name->pigpop))();		\
}

#define PIGTYPE_ALL(name, type)	\
PIGTYPE_ARGUMENT(name, type)	\
PIGTYPE_DEFARGUMENT(name, type)	\
PIGTYPE_RETURN(name, type)	\
PIGTYPE_PUSH(name, type)	\
PIGTYPE_POP(name, type)

#define PIGTYPE_CONST_ALL(name, type)	\
PIGTYPE_ARGUMENT(name, type)		\
PIGTYPE_CONST_DEFARGUMENT(name, type)	\
PIGTYPE_RETURN(name, type)		\
PIGTYPE_PUSH(name, type)		\
PIGTYPE_POP(name, type)

#define PIGTYPE_ARGUMENT2(name, type1, type2)  			\
inline type1 name ## _argument(type2 pig0) {   			\
    return (*(type1 (*)(type2))(_ ## name->pigargument))(pig0);	\
}

#define PIGTYPE_DEFARGUMENT2(name, type1, type2)				\
inline type1 name ## _defargument(type1 pig0, type2 pig1) {			\
    return (*(type1 (*)(type1, type2))(_ ## name->pigdefargument))(pig0, pig1);	\
}


#define PIG_DECLARE_TYPE(type) PIGTPTR _ ## type;

#define PIG_DEFINE_TYPE_ARGUMENT(name, type) \
static type __ ## name ## _argument()

#define PIG_DEFINE_TYPE_ARGUMENT2(name, type, type0) \
static type __ ## name ## _argument(type0 pig0)

#define PIG_DEFINE_TYPE_DEFARGUMENT(name, type) \
static type __ ## name ## _defargument(type pig0)

#define PIG_DEFINE_TYPE_DEFARGUMENT2(name, type, type1) \
static type __ ## name ## _defargument(type pig0, type1 pig1)

#define PIG_DEFINE_TYPE_RETURN(name, type) \
static void __ ## name ## _return(type pig0)

#define PIG_DEFINE_TYPE_RETURN2(name, type, type1) \
static void __ ## name ## _return(type pig0, type1 pig1)

#define PIG_DEFINE_TYPE_PUSH(name, type) \
static void __ ## name ## _push(type pig0)

#define PIG_DEFINE_TYPE_PUSH2(name, type, type1) \
static void __ ## name ## _push(type pig0, type1 pig1)

#define PIG_DEFINE_TYPE_POP(name, type) \
static type __ ## name ## _pop()

#define PIG_DEFINE_TYPE_POP2(name, type, type0) \
static type __ ## name ## _pop(type0 pig0)

#define PIG_DEFINE_TYPE(name) \
static struct pig_type __ ## name = { \
    (pigfptr)__ ## name ## _argument, \
    (pigfptr)__ ## name ## _defargument, \
    (pigfptr)__ ## name ## _return, \
    (pigfptr)__ ## name ## _push, \
    (pigfptr)__ ## name ## _pop, \
    (pigfptr)0 \
};


#define PIG_DEFINE_STUB_ARGUMENT(name, type) \
static void __ ## name ## _argument() { \
    croak("Undefined function %s->argument at %s:%d called", #name, \
	  __FILE__, __LINE__); \
}

#define PIG_DEFINE_STUB_DEFARGUMENT(name, type) \
static void __ ## name ## _defargument(type) { \
    croak("Undefined function %s->defargument at %s:%d called", #name, \
	  __FILE__, __LINE__); \
}

#define PIG_DEFINE_STUB_RETURN(name, type) \
static void __ ## name ## _return() { \
    croak("Undefined function %s->return at %s:%d called", #name, \
	  __FILE__, __LINE__); \
}

#define PIG_DEFINE_STUB_PUSH(name, type) \
static void __ ## name ## _push() { \
    croak("Undefined function %s->push at %s:%d called", #name, \
	  __FILE__, __LINE__); \
}

#define PIG_DEFINE_STUB_POP(name, type) \
static void __ ## name ## _pop() { \
    croak("Undefined function %s->pop at %s:%d called", #name, \
	  __FILE__, __LINE__); \
}

#define PIG_DEFINE_STUB_TYPE(name, type) \
PIG_DEFINE_STUB_ARGUMENT(name, type) \
PIG_DEFINE_STUB_DEFARGUMENT(name, type) \
PIG_DEFINE_STUB_RETURN(name, type) \
PIG_DEFINE_STUB_PUSH(name, type) \
PIG_DEFINE_STUB_POP(name, type)

#define PIG_DEFINE_SCOPE_ARGUMENT(name) \
static void __ ## name ## _scope_argument(void *pig0)

#define PIG_DEFINE_SCOPE_VIRTUAL(name) \
static void __ ## name ## _scope_virtual(void *pig0)

#endif  // PIGTYPE_H
