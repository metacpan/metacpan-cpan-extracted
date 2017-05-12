#ifndef _DEFS_H_
#define _DEFS_H_

#define TOKEN_TYPE_BASIC 1
#define TOKEN_TYPE_MAYBE 2
#define TOKEN_TYPE_PARAMETRIZABLE 3
#define TOKEN_TYPE_SIGNED 4
#define TOKEN_TYPE_SIGNATURE_ITEM 5
#define TOKEN_TYPE_LENGTH 6

#define SIG_SEQ_ITEM_TYPE 1
#define SIG_SEQ_ITEM_NAME 2
#define SIG_SEQ_ITEM_DELIM 3

#define SIG_SEQ_MIN 1
#define SIG_SEQ_MAX 3

typedef struct {

    short strict_signature;

} my_stack_opts_t;

typedef struct {

    int size;
    intptr_t * data;
    my_stack_opts_t * opts;

} my_stack_t;

typedef struct {

    int loose;

} tokenizer_options_t;

typedef struct {

    short token_type;

} abstract_type_t;

typedef struct {

    abstract_type_t base;
    char * type;

} basic_type_t;

typedef struct {

    abstract_type_t base;
    my_stack_t * stack;

} maybe_type_t;

typedef struct {

    abstract_type_t base;
    char * class;
    my_stack_t * param;
    my_stack_t * stack;

} parameterizable_type_t;

typedef struct {

    abstract_type_t base;
    char * source;
    intptr_t type;
    my_stack_t * signature;

} signed_type_t;

typedef struct {

    short named;
    short positional;

    short required;
    short optional;

    char * name;

} signature_param_t;

typedef struct {

    abstract_type_t base;
    my_stack_t * type;
    signature_param_t * param;

} signature_item_t;

typedef struct {

    abstract_type_t base;
    short has_min;
    short has_max;
    char * min;
    char * max;
    intptr_t type;

} length_type_t;

#endif /* end of include guard: _DEFS_H_ */
