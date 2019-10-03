#pragma once

#include "use_perl.h"

AV*   parse (pTHX_ HV* state, register char* p);
char* parse_global (pTHX_ HV* state, register char* p);
char* parse_block_comment (pTHX_ HV* state, register char* p);
char* parse_create_table (pTHX_ HV* state, register char* p);
char* parse_create_table_column (pTHX_ HV* state, register char* p);
char* parse_insert_into (pTHX_ HV* state, register char* p);
char* parse_insert_values (pTHX_ HV* state, register char* p, AV* ret);
