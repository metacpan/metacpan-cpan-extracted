#pragma once

#include "use_perl.h"
#include "context.h"

HV* newState (pTHX);
HV* initState (pTHX_ HV* state);
SV* _get_parser_context (pTHX_ HV* state);
SV* _get_parser_recent_context (pTHX_ HV* state);
SV* _get_nest (pTHX_ HV* state);
SV* _get_recent_nest (pTHX_ HV* state);
void set_parser_context (pTHX_ HV* state, const IV context);
void restore_context (pTHX_ HV* state);
IV get_parser_context (pTHX_ HV* state);
IV get_nest (pTHX_ HV* state);
void incr_nest (pTHX_ HV* state);
void decr_nest (pTHX_ HV* state);
void set_table (pTHX_ HV* state, const char* name, const size_t length);
SV* get_table (pTHX_ HV* state);
HV* get_current_schema (pTHX_ HV* state);
HV* get_or_create_schema (pTHX_ HV* state, SV* key);
AV* get_or_create_columns (pTHX_ HV* table);
