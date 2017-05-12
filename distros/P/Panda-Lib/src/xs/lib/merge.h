#pragma once
#include <xs/xs.h>

namespace xs { namespace lib {

const int MERGE_ARRAY_CONCAT =  1;
const int MERGE_ARRAY_MERGE  =  2;
const int MERGE_ARRAY_CM     =  3;
const int MERGE_COPY_DEST    =  4;
const int MERGE_LAZY         =  8;
const int MERGE_SKIP_UNDEF   = 16;
const int MERGE_DELETE_UNDEF = 32;
const int MERGE_COPY_SOURCE  = 64;
const int MERGE_COPY         = MERGE_COPY_DEST | MERGE_COPY_SOURCE;

HV* hash_merge (pTHX_ HV* dest, HV* source, IV flags = 0);

SV* merge (pTHX_ SV* dest, SV* source, IV flags = 0);

}}
