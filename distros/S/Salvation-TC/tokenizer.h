#ifndef _TOKENIZER_H_
#define _TOKENIZER_H_

#include "helper.h"

HV * perl_tokenize_type_str( char * class, const char * s, HV * options );
HV * perl_tokenize_signature_str( char * class, const char * s, HV * options );

#endif /* end of include guard: _TOKENIZER_H_ */
