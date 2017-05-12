#ifndef _HELPER_H_
#define _HELPER_H_

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "defs.h"

char * call_load_parameterizable_type_class( char * class, char * word );
HV * tokens_to_perl( my_stack_t * stack );
tokenizer_options_t * perl_to_options( HV * options );
HV * mortalize_hv( HV * v );
void free_stack_arr( intptr_t * stack, int size );
void free_my_stack( my_stack_t * stack );
void p_die( char * s );
my_stack_t * new_my_stack();

#endif /* end of include guard: _HELPER_H_ */
