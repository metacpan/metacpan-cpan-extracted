using std::cout;  using std::cerr;  using std::endl;  using std::to_string;

#ifndef __CPP__INCLUDED__Perl__Structure__Hash__SubTypes2D_cpp
#define __CPP__INCLUDED__Perl__Structure__Hash__SubTypes2D_cpp 0.011_000

#include <Perl/Structure/Hash/SubTypes2D.h>  // -> ??? (relies on <unordered_map> being included via Inline::CPP's AUTO_INCLUDE config option in RPerl/Inline.pm)

// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]

void hashref_arrayref_integer_CHECK(SV* possible_hashref_arrayref_integer) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_CHECK(), top of subroutine\n");

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with integer-specific error codes
    if ( not( SvOK(possible_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_arrayref_integer;
    integer possible_hash_arrayref_integer__num_keys;
    integer i;
    HE* possible_hash_arrayref_integer__hashentry;
    SV* possible_hash_arrayref_integer__hashentry_value;
    SV* possible_hash_arrayref_integer__hashentry_key;
    string possible_hash_arrayref_integer__hashentry_key_string;

    possible_hash_arrayref_integer = (HV*)SvRV(possible_hashref_arrayref_integer);
    possible_hash_arrayref_integer__num_keys = hv_iterinit(possible_hash_arrayref_integer);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_arrayref_integer__num_keys;  ++i) {
        possible_hash_arrayref_integer__hashentry = hv_iternext(possible_hash_arrayref_integer);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with integer-specific error code
        if (possible_hash_arrayref_integer__hashentry == NULL) { croak("\nERROR EHVRVAVRVIVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_integer__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_arrayref_integer__hashentry_value = hv_iterval(possible_hash_arrayref_integer, possible_hash_arrayref_integer__hashentry);

        // DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() macro & subroutine, but with hash-specific error codes
        if (not(SvOK(possible_hash_arrayref_integer__hashentry_value))) {
            possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
            possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str());
        }

        if (not(SvAROKp(possible_hash_arrayref_integer__hashentry_value))) {
            possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
            possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found at key '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str());
        }

        SV* possible_arrayref_integer = possible_hash_arrayref_integer__hashentry_value;

        AV* possible_array_integer;
        integer possible_array_integer__length;
        integer j;
        SV** possible_array_integer__element;

        possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
        possible_array_integer__length = av_len(possible_array_integer) + 1;

        // incrementing iteration
        for (j = 0;  j < possible_array_integer__length;  ++j) {
            possible_array_integer__element = av_fetch(possible_array_integer, j, 0);
            if (not(SvOK(*possible_array_integer__element))) {
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVIV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at index %"INTEGER", key '%s',\ncroaking", j, possible_hash_arrayref_integer__hashentry_key_string.c_str());
            }
            if (not(SvIOKp(*possible_array_integer__element))) {
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVIV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index %"INTEGER", key '%s',\ncroaking", j, possible_hash_arrayref_integer__hashentry_key_string.c_str());
            }
        }
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_CHECK(), bottom of subroutine\n");
}

void hashref_arrayref_integer_CHECKTRACE(SV* possible_hashref_arrayref_integer, const char* variable_name, const char* subroutine_name)
{
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with integer-specific error codes
    if ( not( SvOK(possible_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but non-hashref value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_arrayref_integer;
    integer possible_hash_arrayref_integer__num_keys;
    integer i;
    HE* possible_hash_arrayref_integer__hashentry;
    SV* possible_hash_arrayref_integer__hashentry_value;
    SV* possible_hash_arrayref_integer__hashentry_key;
    string possible_hash_arrayref_integer__hashentry_key_string;

    possible_hash_arrayref_integer = (HV*)SvRV(possible_hashref_arrayref_integer);
    possible_hash_arrayref_integer__num_keys = hv_iterinit(possible_hash_arrayref_integer);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_arrayref_integer__num_keys;  ++i) {
        possible_hash_arrayref_integer__hashentry = hv_iternext(possible_hash_arrayref_integer);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with integer-specific error code
        if (possible_hash_arrayref_integer__hashentry == NULL) { croak("\nERROR EHVRVAVRVIVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_integer__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
        possible_hash_arrayref_integer__hashentry_value = hv_iterval(possible_hash_arrayref_integer, possible_hash_arrayref_integer__hashentry);

        // DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() macro & subroutine, but with hash-specific error codes
        if (not(SvOK(possible_hash_arrayref_integer__hashentry_value))) {
            possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
            possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        if (not(SvAROKp(possible_hash_arrayref_integer__hashentry_value))) {
            possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
            possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        SV* possible_arrayref_integer = possible_hash_arrayref_integer__hashentry_value;

        AV* possible_array_integer;
        integer possible_array_integer__length;
        integer j;
        SV** possible_array_integer__element;

        possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
        possible_array_integer__length = av_len(possible_array_integer) + 1;

        // incrementing iteration
        for (j = 0;  j < possible_array_integer__length;  ++j) {
            possible_array_integer__element = av_fetch(possible_array_integer, j, 0);
            if (not(SvOK(*possible_array_integer__element))) {
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVIV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at index %"INTEGER", key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", j, possible_hash_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }
            if (not(SvIOKp(*possible_array_integer__element))) {
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVIV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index %"INTEGER", key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", j, possible_hash_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }
        }
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_CHECKTRACE(), bottom of subroutine\n");
}

void hashref_arrayref_number_CHECK(SV* possible_hashref_arrayref_number) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_CHECK(), top of subroutine\n");

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with number-specific error codes
    if ( not( SvOK(possible_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_arrayref_number;
    integer possible_hash_arrayref_number__num_keys;
    integer i;
    HE* possible_hash_arrayref_number__hashentry;
    SV* possible_hash_arrayref_number__hashentry_value;
    SV* possible_hash_arrayref_number__hashentry_key;
    string possible_hash_arrayref_number__hashentry_key_string;

    possible_hash_arrayref_number = (HV*)SvRV(possible_hashref_arrayref_number);
    possible_hash_arrayref_number__num_keys = hv_iterinit(possible_hash_arrayref_number);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_arrayref_number__num_keys;  ++i) {
        possible_hash_arrayref_number__hashentry = hv_iternext(possible_hash_arrayref_number);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with number-specific error code
        if (possible_hash_arrayref_number__hashentry == NULL) { croak("\nERROR EHVRVAVRVNVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_number__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_arrayref_number__hashentry_value = hv_iterval(possible_hash_arrayref_number, possible_hash_arrayref_number__hashentry);

        // DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECK() macro & subroutine, but with hash-specific error codes
        if (not(SvOK(possible_hash_arrayref_number__hashentry_value))) {
            possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
            possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str());
        }

        if (not(SvAROKp(possible_hash_arrayref_number__hashentry_value))) {
            possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
            possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found at key '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str());
        }

        SV* possible_arrayref_number = possible_hash_arrayref_number__hashentry_value;

        AV* possible_array_number;
        integer possible_array_number__length;
        integer j;
        SV** possible_array_number__element;

        possible_array_number = (AV*)SvRV(possible_arrayref_number);
        possible_array_number__length = av_len(possible_array_number) + 1;

        // incrementing iteration
        for (j = 0;  j < possible_array_number__length;  ++j) {
            possible_array_number__element = av_fetch(possible_array_number, j, 0);
            if (not(SvOK(*possible_array_number__element))) {
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVNV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index %"INTEGER", key '%s',\ncroaking", j, possible_hash_arrayref_number__hashentry_key_string.c_str());
            }
            if (not(SvNOKp(*possible_array_number__element) or
                    SvIOKp(*possible_array_number__element))) {
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVNV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index %"INTEGER", key '%s',\ncroaking", j, possible_hash_arrayref_number__hashentry_key_string.c_str());
            }
        }
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_CHECK(), bottom of subroutine\n");
}

void hashref_arrayref_number_CHECKTRACE(SV* possible_hashref_arrayref_number, const char* variable_name, const char* subroutine_name) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with number-specific error codes
    if ( not( SvOK(possible_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but non-hashref value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_arrayref_number;
    integer possible_hash_arrayref_number__num_keys;
    integer i;
    HE* possible_hash_arrayref_number__hashentry;
    SV* possible_hash_arrayref_number__hashentry_value;
    SV* possible_hash_arrayref_number__hashentry_key;
    string possible_hash_arrayref_number__hashentry_key_string;

    possible_hash_arrayref_number = (HV*)SvRV(possible_hashref_arrayref_number);
    possible_hash_arrayref_number__num_keys = hv_iterinit(possible_hash_arrayref_number);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_arrayref_number__num_keys;  ++i) {
        possible_hash_arrayref_number__hashentry = hv_iternext(possible_hash_arrayref_number);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with number-specific error code
        if (possible_hash_arrayref_number__hashentry == NULL) { croak("\nERROR EHVRVAVRVNVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_number__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
        possible_hash_arrayref_number__hashentry_value = hv_iterval(possible_hash_arrayref_number, possible_hash_arrayref_number__hashentry);

        // DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECK() macro & subroutine, but with hash-specific error codes
        if (not(SvOK(possible_hash_arrayref_number__hashentry_value))) {
            possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
            possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        if (not(SvAROKp(possible_hash_arrayref_number__hashentry_value))) {
            possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
            possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        SV* possible_arrayref_number = possible_hash_arrayref_number__hashentry_value;

        AV* possible_array_number;
        integer possible_array_number__length;
        integer j;
        SV** possible_array_number__element;

        possible_array_number = (AV*)SvRV(possible_arrayref_number);
        possible_array_number__length = av_len(possible_array_number) + 1;

        // incrementing iteration
        for (j = 0;  j < possible_array_number__length;  ++j) {
            possible_array_number__element = av_fetch(possible_array_number, j, 0);
            if (not(SvOK(*possible_array_number__element))) {
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVNV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index %"INTEGER", key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", j, possible_hash_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }
            if (not(SvNOKp(*possible_array_number__element) or
                    SvIOKp(*possible_array_number__element))) {
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVNV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index %"INTEGER", key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", j, possible_hash_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }
        }
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_CHECKTRACE(), bottom of subroutine\n");
}

void hashref_arrayref_string_CHECK(SV* possible_hashref_arrayref_string) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_CHECK(), top of subroutine\n");

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with string-specific error codes
    if ( not( SvOK(possible_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_arrayref_string;
    integer possible_hash_arrayref_string__num_keys;
    integer i;
    HE* possible_hash_arrayref_string__hashentry;
    SV* possible_hash_arrayref_string__hashentry_value;
    SV* possible_hash_arrayref_string__hashentry_key;
    string possible_hash_arrayref_string__hashentry_key_string;

    possible_hash_arrayref_string = (HV*)SvRV(possible_hashref_arrayref_string);
    possible_hash_arrayref_string__num_keys = hv_iterinit(possible_hash_arrayref_string);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_arrayref_string__num_keys;  ++i) {
        possible_hash_arrayref_string__hashentry = hv_iternext(possible_hash_arrayref_string);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with string-specific error code
        if (possible_hash_arrayref_string__hashentry == NULL) { croak("\nERROR EHVRVAVRVPVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_string__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_arrayref_string__hashentry_value = hv_iterval(possible_hash_arrayref_string, possible_hash_arrayref_string__hashentry);

        // DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECK() macro & subroutine, but with hash-specific error codes
        if (not(SvOK(possible_hash_arrayref_string__hashentry_value))) {
            possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
            possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str());
        }

        if (not(SvAROKp(possible_hash_arrayref_string__hashentry_value))) {
            possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
            possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found at key '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str());
        }

        SV* possible_arrayref_string = possible_hash_arrayref_string__hashentry_value;

        AV* possible_array_string;
        integer possible_array_string__length;
        integer j;
        SV** possible_array_string__element;

        possible_array_string = (AV*)SvRV(possible_arrayref_string);
        possible_array_string__length = av_len(possible_array_string) + 1;

        // incrementing iteration
        for (j = 0;  j < possible_array_string__length;  ++j) {
            possible_array_string__element = av_fetch(possible_array_string, j, 0);
            if (not(SvOK(*possible_array_string__element))) {
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVPV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index %"INTEGER", key '%s',\ncroaking", j, possible_hash_arrayref_string__hashentry_key_string.c_str());
            }
            if (not(SvPOKp(*possible_array_string__element))) {
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVPV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index %"INTEGER", key '%s',\ncroaking", j, possible_hash_arrayref_string__hashentry_key_string.c_str());
            }
        }
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_CHECK(), bottom of subroutine\n");
}

void hashref_arrayref_string_CHECKTRACE(SV* possible_hashref_arrayref_string, const char* variable_name, const char* subroutine_name) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with string-specific error codes
    if ( not( SvOK(possible_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but non-hashref value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_arrayref_string;
    integer possible_hash_arrayref_string__num_keys;
    integer i;
    HE* possible_hash_arrayref_string__hashentry;
    SV* possible_hash_arrayref_string__hashentry_value;
    SV* possible_hash_arrayref_string__hashentry_key;
    string possible_hash_arrayref_string__hashentry_key_string;

    possible_hash_arrayref_string = (HV*)SvRV(possible_hashref_arrayref_string);
    possible_hash_arrayref_string__num_keys = hv_iterinit(possible_hash_arrayref_string);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_arrayref_string__num_keys;  ++i) {
        possible_hash_arrayref_string__hashentry = hv_iternext(possible_hash_arrayref_string);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with string-specific error code
        if (possible_hash_arrayref_string__hashentry == NULL) { croak("\nERROR EHVRVAVRVPVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_string__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
        possible_hash_arrayref_string__hashentry_value = hv_iterval(possible_hash_arrayref_string, possible_hash_arrayref_string__hashentry);

        // DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECK() macro & subroutine, but with hash-specific error codes
        if (not(SvOK(possible_hash_arrayref_string__hashentry_value))) {
            possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
            possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        if (not(SvAROKp(possible_hash_arrayref_string__hashentry_value))) {
            possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
            possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        SV* possible_arrayref_string = possible_hash_arrayref_string__hashentry_value;

        AV* possible_array_string;
        integer possible_array_string__length;
        integer j;
        SV** possible_array_string__element;

        possible_array_string = (AV*)SvRV(possible_arrayref_string);
        possible_array_string__length = av_len(possible_array_string) + 1;

        // incrementing iteration
        for (j = 0;  j < possible_array_string__length;  ++j) {
            possible_array_string__element = av_fetch(possible_array_string, j, 0);
            if (not(SvOK(*possible_array_string__element))) {
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVPV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index %"INTEGER", key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", j, possible_hash_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }
            if (not(SvPOKp(*possible_array_string__element))) {
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVAVRVPV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index %"INTEGER", key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", j, possible_hash_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }
        }
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_CHECKTRACE(), bottom of subroutine\n");
}

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

# ifdef __CPP__TYPES

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs))))) to (C++ std::unordered_map of (C++ std::vector of integers))
hashref_arrayref_integer XS_unpack_hashref_arrayref_integer(SV* input_hvref_avref) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_integer(), top of subroutine\n");

//    hashref_arrayref_integer_CHECK(input_hvref_avref);
    hashref_arrayref_integer_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "XS_unpack_hashref_arrayref_integer()");

    HV* input_hv_avref;
    integer input_hv_avref__num_keys;
    integer i;
    HE* input_hv_avref__entry;
    SV* input_hv_avref__entry_key;
    SV* input_hv_avref__entry_value;
    hashref_arrayref_integer output_umap_vector;

    input_hv_avref = (HV*)SvRV(input_hvref_avref);

    input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_integer(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap_vector.reserve((size_t)input_hv_avref__num_keys);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_avref__num_keys;  ++i) {
        // does not utilize i in entry retrieval
        input_hv_avref__entry = hv_iternext(input_hv_avref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
//      hashentry_CHECK(input_hv_avref__entry);
//      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "XS_unpack_hashref_arrayref_integer()");

        input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
        input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);
        // DEV NOTE: integer type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
//      integer_CHECK(input_hv_avref__entry_value);
//      integer_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_arrayref_integer()");

        // BEGIN ARRAY CODE
        AV* input_av;
        integer input_av__length;
        integer j;
        SV** input_av__element;
        arrayref_integer output_vector;

//      input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_hv_avref__entry_value
//        input_av = (AV*)SvRV(*input_hv_avref__entry_value);  // error: base operand of ‘->’ has non-pointer type ‘SV {aka sv}’, in expansion of macro ‘SvRV’
        input_av = (AV*)SvRV(input_hv_avref__entry_value);
        input_av__length = av_len(input_av) + 1;
//        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_integer(), have input_av__length = %"INTEGER"\n", input_av__length);

        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
        // resize() ahead of time to allow l-value subscript notation
        output_vector.resize((size_t)input_av__length);

        // incrementing iteration
        for (j = 0;  j < input_av__length;  ++j) {
            // utilizes j in element retrieval
            input_av__element = av_fetch(input_av, j, 0);

            // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes j in assignment
            output_vector[j] = SvIV(*input_av__element);
        }

//        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_integer(), bottom of inner for() loop j = %"INTEGER", have output_vector.size() = %"INTEGER"\n", j, (integer) output_vector.size());
        // END ARRAY CODE

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap_vector[SvPV_nolen(input_hv_avref__entry_key)] = output_vector;
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_integer(), after outer for() loop, have output_umap_vector.size() = %"INTEGER"\n", output_umap_vector.size());
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_integer(), bottom of subroutine\n");

    return(output_umap_vector);
}

// convert from (C++ std::unordered_map of (C++ std::vector of integers)) to (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs)))))
void XS_pack_hashref_arrayref_integer(SV* output_hvref_avref, hashref_arrayref_integer input_umap_vector) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), top of subroutine\n");

    HV* output_hv_avref = newHV();  // initialize output hash-of-arrays to empty
    integer input_umap_vector__num_keys = input_umap_vector.size();
    hashref_arrayref_integer_const_iterator i;
    SV* temp_sv_pointer;

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), have input_umap_vector__num_keys = %"INTEGER"\n", input_umap_vector__num_keys);

    if (input_umap_vector__num_keys > 0) {
        for (i = input_umap_vector.begin();  i != input_umap_vector.end();  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), top of outer loop, have i->first AKA key = '%s'\n", (i->first).c_str());
            arrayref_integer input_vector = i->second;

            // BEGIN ARRAY CODE
            AV* output_av = newAV();  // initialize output sub-array to empty
            integer input_vector__length = input_vector.size();
            integer j;

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), have input_vector__length = %"INTEGER"\n", input_vector__length);

            if (input_vector__length > 0) {
                for (j = 0;  j < input_vector__length;  ++j) {
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), top of inner loop, have (i->first, j) = ('%s', %"INTEGER")\n", (i->first).c_str(), j);
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), have input_umap_vector['%s'][%"INTEGER"] = %"INTEGER"\n", (i->first).c_str(), j, input_vector[j]);
                    av_push(output_av, newSViv(input_vector[j]));
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), bottom of inner loop, have (i->first, j) = ('%s', %"INTEGER")\n", (i->first).c_str(), j);
                }
            }
            else warn("in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), sub-array was empty, returning empty sub-array via newAV()");
            // END ARRAY CODE

            // NEED ANSWER: is it really okay to NOT increase the reference count below???
            hv_store(output_hv_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_noinc((SV*)output_av), (U32)0);  // reference, do not increase reference count
//            hv_store(output_hv_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_inc((SV*)output_av), (U32)0);  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), bottom of outer loop, have i->first = '%s'\n", (i->first).c_str());
        }
    }
    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref_avref) = (SV*)output_hv_avref;       // make output stack RV point at our output HV

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_integer(), bottom of subroutine\n");
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs))))) to (C++ std::unordered_map of (C++ std::vector of numbers))
hashref_arrayref_number XS_unpack_hashref_arrayref_number(SV* input_hvref_avref) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_number(), top of subroutine\n");

//    hashref_arrayref_number_CHECK(input_hvref_avref);
    hashref_arrayref_number_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "XS_unpack_hashref_arrayref_number()");

    HV* input_hv_avref;
    integer input_hv_avref__num_keys;
    integer i;
    HE* input_hv_avref__entry;
    SV* input_hv_avref__entry_key;
    SV* input_hv_avref__entry_value;
    hashref_arrayref_number output_umap_vector;

    input_hv_avref = (HV*)SvRV(input_hvref_avref);

    input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_number(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap_vector.reserve((size_t)input_hv_avref__num_keys);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_avref__num_keys;  ++i) {
        // does not utilize i in entry retrieval
        input_hv_avref__entry = hv_iternext(input_hv_avref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
//      hashentry_CHECK(input_hv_avref__entry);
//      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "XS_unpack_hashref_arrayref_number()");

        input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
        input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);
        // DEV NOTE: number type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
//      number_CHECK(input_hv_avref__entry_value);
//      number_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_arrayref_number()");

        // BEGIN ARRAY CODE
        AV* input_av;
        integer input_av__length;
        integer j;
        SV** input_av__element;
        arrayref_number output_vector;

//      input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_hv_avref__entry_value
//        input_av = (AV*)SvRV(*input_hv_avref__entry_value);  // error: base operand of ‘->’ has non-pointer type ‘SV {aka sv}’, in expansion of macro ‘SvRV’
        input_av = (AV*)SvRV(input_hv_avref__entry_value);
        input_av__length = av_len(input_av) + 1;
//        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_number(), have input_av__length = %"INTEGER"\n", input_av__length);

        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
        // resize() ahead of time to allow l-value subscript notation
        output_vector.resize((size_t)input_av__length);

        // incrementing iteration
        for (j = 0;  j < input_av__length;  ++j) {
            // utilizes j in element retrieval
            input_av__element = av_fetch(input_av, j, 0);

            // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes j in assignment
            output_vector[j] = SvNV(*input_av__element);
        }

//        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_number(), bottom of inner for() loop j = %"INTEGER", have output_vector.size() = %"INTEGER"\n", j, (integer) output_vector.size());
        // END ARRAY CODE

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap_vector[SvPV_nolen(input_hv_avref__entry_key)] = output_vector;
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_number(), after outer for() loop, have output_umap_vector.size() = %"INTEGER"\n", output_umap_vector.size());
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_number(), bottom of subroutine\n");

    return(output_umap_vector);
}

// convert from (C++ std::unordered_map of (C++ std::vector of numbers)) to (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs)))))
void XS_pack_hashref_arrayref_number(SV* output_hvref_avref, hashref_arrayref_number input_umap_vector) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), top of subroutine\n");

    HV* output_hv_avref = newHV();  // initialize output hash-of-arrays to empty
    integer input_umap_vector__num_keys = input_umap_vector.size();
    hashref_arrayref_number_const_iterator i;
    SV* temp_sv_pointer;

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), have input_umap_vector__num_keys = %"INTEGER"\n", input_umap_vector__num_keys);

    if (input_umap_vector__num_keys > 0) {
        for (i = input_umap_vector.begin();  i != input_umap_vector.end();  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), top of outer loop, have i->first AKA key = '%s'\n", (i->first).c_str());
            arrayref_number input_vector = i->second;

            // BEGIN ARRAY CODE
            AV* output_av = newAV();  // initialize output sub-array to empty
            integer input_vector__length = input_vector.size();
            integer j;

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), have input_vector__length = %"INTEGER"\n", input_vector__length);

            if (input_vector__length > 0) {
                for (j = 0;  j < input_vector__length;  ++j) {
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), top of inner loop, have (i->first, j) = ('%s', %"INTEGER")\n", (i->first).c_str(), j);
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), have input_umap_vector['%s'][%"INTEGER"] = %"NUMBER"\n", (i->first).c_str(), j, input_vector[j]);
                    av_push(output_av, newSVnv(input_vector[j]));
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), bottom of inner loop, have (i->first, j) = ('%s', %"INTEGER")\n", (i->first).c_str(), j);
                }
            }
            else warn("in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), sub-array was empty, returning empty sub-array via newAV()");
            // END ARRAY CODE

            // NEED ANSWER: is it really okay to NOT increase the reference count below???
            hv_store(output_hv_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_noinc((SV*)output_av), (U32)0);  // reference, do not increase reference count
//            hv_store(output_hv_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_inc((SV*)output_av), (U32)0);  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), bottom of outer loop, have i->first = '%s'\n", (i->first).c_str());
        }
    }
    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref_avref) = (SV*)output_hv_avref;       // make output stack RV point at our output HV

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_number(), bottom of subroutine\n");
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs))))) to (C++ std::unordered_map of (C++ std::vector of strings))
hashref_arrayref_string XS_unpack_hashref_arrayref_string(SV* input_hvref_avref) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_string(), top of subroutine\n");

//    hashref_arrayref_string_CHECK(input_hvref_avref);
    hashref_arrayref_string_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "XS_unpack_hashref_arrayref_string()");

    HV* input_hv_avref;
    integer input_hv_avref__num_keys;
    integer i;
    HE* input_hv_avref__entry;
    SV* input_hv_avref__entry_key;
    SV* input_hv_avref__entry_value;
    hashref_arrayref_string output_umap_vector;

    input_hv_avref = (HV*)SvRV(input_hvref_avref);

    input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_string(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap_vector.reserve((size_t)input_hv_avref__num_keys);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_avref__num_keys;  ++i) {
        // does not utilize i in entry retrieval
        input_hv_avref__entry = hv_iternext(input_hv_avref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
//      hashentry_CHECK(input_hv_avref__entry);
//      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "XS_unpack_hashref_arrayref_string()");

        input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
        input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);
        // DEV NOTE: string type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
//      string_CHECK(input_hv_avref__entry_value);
//      string_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_arrayref_string()");

        // BEGIN ARRAY CODE
        AV* input_av;
        integer input_av__length;
        integer j;
        SV** input_av__element;
        arrayref_string output_vector;

//      input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_hv_avref__entry_value
//        input_av = (AV*)SvRV(*input_hv_avref__entry_value);  // error: base operand of ‘->’ has non-pointer type ‘SV {aka sv}’, in expansion of macro ‘SvRV’
        input_av = (AV*)SvRV(input_hv_avref__entry_value);
        input_av__length = av_len(input_av) + 1;
//        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_string(), have input_av__length = %"INTEGER"\n", input_av__length);

        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
        // resize() ahead of time to allow l-value subscript notation
        output_vector.resize((size_t)input_av__length);

        // incrementing iteration
        for (j = 0;  j < input_av__length;  ++j) {
            // utilizes j in element retrieval
            input_av__element = av_fetch(input_av, j, 0);

            // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes j in assignment
            output_vector[j] = SvPV_nolen(*input_av__element);
        }

//        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_string(), bottom of inner for() loop j = %"INTEGER", have output_vector.size() = %"INTEGER"\n", j, (integer) output_vector.size());
        // END ARRAY CODE

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap_vector[SvPV_nolen(input_hv_avref__entry_key)] = output_vector;
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_string(), after outer for() loop, have output_umap_vector.size() = %"INTEGER"\n", output_umap_vector.size());
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_arrayref_string(), bottom of subroutine\n");

    return(output_umap_vector);
}

// convert from (C++ std::unordered_map of (C++ std::vector of strings)) to (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs)))))
void XS_pack_hashref_arrayref_string(SV* output_hvref_avref, hashref_arrayref_string input_umap_vector) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), top of subroutine\n");

    HV* output_hv_avref = newHV();  // initialize output hash-of-arrays to empty
    integer input_umap_vector__num_keys = input_umap_vector.size();
    hashref_arrayref_string_const_iterator i;
    SV* temp_sv_pointer;

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), have input_umap_vector__num_keys = %"INTEGER"\n", input_umap_vector__num_keys);

    if (input_umap_vector__num_keys > 0) {
        for (i = input_umap_vector.begin();  i != input_umap_vector.end();  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), top of outer loop, have i->first AKA key = '%s'\n", (i->first).c_str());
            arrayref_string input_vector = i->second;

            // BEGIN ARRAY CODE
            AV* output_av = newAV();  // initialize output sub-array to empty
            integer input_vector__length = input_vector.size();
            integer j;

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), have input_vector__length = %"INTEGER"\n", input_vector__length);

            if (input_vector__length > 0) {
                for (j = 0;  j < input_vector__length;  ++j) {
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), top of inner loop, have (i->first, j) = ('%s', %"INTEGER")\n", (i->first).c_str(), j);
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), have input_umap_vector['%s'][%"INTEGER"] = '%s'\n", (i->first).c_str(), j, input_vector[j].c_str());
                    av_push(output_av, newSVpv(input_vector[j].c_str(), 0));
//                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), bottom of inner loop, have (i->first, j) = ('%s', %"INTEGER")\n", (i->first).c_str(), j);
                }
            }
            else warn("in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), sub-array was empty, returning empty sub-array via newAV()");
            // END ARRAY CODE

            // NEED ANSWER: is it really okay to NOT increase the reference count below???
            hv_store(output_hv_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_noinc((SV*)output_av), (U32)0);  // reference, do not increase reference count
//            hv_store(output_hv_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_inc((SV*)output_av), (U32)0);  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), bottom of outer loop, have i->first = '%s'\n", (i->first).c_str());
        }
    }
    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref_avref) = (SV*)output_hv_avref;       // make output stack RV point at our output HV

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_arrayref_string(), bottom of subroutine\n");
}

# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES

// call actual stringify routine, format level -1 (compact), indent level 0
SV* hashref_arrayref_integer_to_string_compact(SV* input_hvref) {
    return hashref_arrayref_integer_to_string_format(input_hvref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
SV* hashref_arrayref_integer_to_string(SV* input_hvref) {
    return hashref_arrayref_integer_to_string_format(input_hvref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (pretty), indent level 0
SV* hashref_arrayref_integer_to_string_pretty(SV* input_hvref) {
    return hashref_arrayref_integer_to_string_format(input_hvref, newSViv(1), newSViv(0));
}

// call actual stringify routine, format level 2 (expand), indent level 0
SV* hashref_arrayref_integer_to_string_expand(SV* input_hvref) {
    return hashref_arrayref_integer_to_string_format(input_hvref, newSViv(2), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs))))) to Perl-parsable (Perl SV containing PV)
SV* hashref_arrayref_integer_to_string_format(SV* input_hvref_avref, SV* format_level, SV* indent_level) {
//    fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_to_string(), top of subroutine...\n");
//    fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", SvIV(format_level), SvIV(indent_level));

//  hashref_arrayref_integer_CHECK(input_hvref_avref);
    hashref_arrayref_integer_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "hashref_arrayref_integer_to_string()");

    // declare local variables
    HV* input_hv_avref;
    integer input_hv_avref__num_keys;
    integer i;
    boolean i_is_0 = 1;
    HE* input_hv_avref__entry;
    SV* input_hv_avref__entry_key;
    string input_hv_avref__entry_key_string;
    SV* input_hv_avref__entry_value;
    SV* output_sv = newSVpv("", 0);

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // compute length of (number of keys in) input hash
    input_hv_avref = (HV*)SvRV(input_hvref_avref);
    input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_to_string(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { sv_catsv(output_sv, indent); }  // pretty

    // begin output string with left-curly-brace, as required for all RPerl hashes
    sv_setpvn(output_sv, "{", 1);

    // loop through all hash keys
    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_avref__num_keys;  ++i) {
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_to_string(), top of loop i = %"INTEGER"\n", i);

        // does not utilize i in entry retrieval
        input_hv_avref__entry = hv_iternext(input_hv_avref);

        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
//      hashentry_CHECK(input_hv_avref__entry);
//      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "hashref_arrayref_integer_to_string()");

        // retrieve input hash's entry value at key
        input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
        input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);

        // DEV NOTE: integer type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
//      integer_CHECK(input_hv_avref__entry_value);
//      integer_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "hashref_arrayref_integer_to_string()");

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { sv_catpvn(output_sv, ",", 1); }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >= 1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }  // pretty & expand
        else if (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " ", 1); }                                                                   // normal

        input_hv_avref__entry_key_string = escape_backslash_singlequote(string(SvPV_nolen(input_hv_avref__entry_key)));  // escape key string for error message

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        sv_catpvf(output_sv, "'%s'", SvPV_nolen(input_hv_avref__entry_key));  // alternative form
        sv_catpvf(output_sv, "'%s'", input_hv_avref__entry_key_string.c_str());

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " => ", 4); }  // normal & pretty & expand
        else                               { sv_catpvn(output_sv, "=>", 2); }   // compact

        // append newline after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= 2) { sv_catpvn(output_sv, "\n", 1); }    // expand

        // call *_to_string_format() for data sub-structure
        sv_catsv(output_sv, arrayref_integer_to_string_format(input_hv_avref__entry_value, newSViv(SvIV(format_level) - 1), newSViv(SvIV(indent_level) + 1)));  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (SvIV(format_level) >= 1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }  // pretty & expand
    else if (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " ", 1); }                                 // normal

    // end output string with right-curly-brace, as required for all RPerl hashes
    sv_catpvn(output_sv, "}", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_to_string(), bottom of subroutine\n");

    return(output_sv);
}

// call actual stringify routine, format level -1 (compact), indent level 0
SV* hashref_arrayref_number_to_string_compact(SV* input_hvref) {
    return hashref_arrayref_number_to_string_format(input_hvref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
SV* hashref_arrayref_number_to_string(SV* input_hvref) {
    return hashref_arrayref_number_to_string_format(input_hvref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (pretty), indent level 0
SV* hashref_arrayref_number_to_string_pretty(SV* input_hvref) {
    return hashref_arrayref_number_to_string_format(input_hvref, newSViv(1), newSViv(0));
}

// call actual stringify routine, format level 2 (expand), indent level 0
SV* hashref_arrayref_number_to_string_expand(SV* input_hvref) {
    return hashref_arrayref_number_to_string_format(input_hvref, newSViv(2), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs))))) to Perl-parsable (Perl SV containing PV)
SV* hashref_arrayref_number_to_string_format(SV* input_hvref_avref, SV* format_level, SV* indent_level) {
//    fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_to_string(), top of subroutine...\n");
//    fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", SvIV(format_level), SvIV(indent_level));

//  hashref_arrayref_number_CHECK(input_hvref_avref);
    hashref_arrayref_number_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "hashref_arrayref_number_to_string()");

    // declare local variables
    HV* input_hv_avref;
    integer input_hv_avref__num_keys;
    integer i;
    boolean i_is_0 = 1;
    HE* input_hv_avref__entry;
    SV* input_hv_avref__entry_key;
    string input_hv_avref__entry_key_string;
    SV* input_hv_avref__entry_value;
    SV* output_sv = newSVpv("", 0);

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // compute length of (number of keys in) input hash
    input_hv_avref = (HV*)SvRV(input_hvref_avref);
    input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_to_string(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { sv_catsv(output_sv, indent); }  // pretty

    // begin output string with left-curly-brace, as required for all RPerl hashes
    sv_setpvn(output_sv, "{", 1);

    // loop through all hash keys
    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_avref__num_keys;  ++i) {
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_to_string(), top of loop i = %"INTEGER"\n", i);

        // does not utilize i in entry retrieval
        input_hv_avref__entry = hv_iternext(input_hv_avref);

        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
//      hashentry_CHECK(input_hv_avref__entry);
//      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "hashref_arrayref_number_to_string()");

        // retrieve input hash's entry value at key
        input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
        input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);

        // DEV NOTE: integer type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
//      number_CHECK(input_hv_avref__entry_value);
//      number_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "hashref_arrayref_number_to_string()");

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { sv_catpvn(output_sv, ",", 1); }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >= 1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }  // pretty & expand
        else if (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " ", 1); }                                                                   // normal

        input_hv_avref__entry_key_string = escape_backslash_singlequote(string(SvPV_nolen(input_hv_avref__entry_key)));  // escape key string for error message

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        sv_catpvf(output_sv, "'%s'", SvPV_nolen(input_hv_avref__entry_key));  // alternative form
        sv_catpvf(output_sv, "'%s'", input_hv_avref__entry_key_string.c_str());

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " => ", 4); }  // normal & pretty & expand
        else                               { sv_catpvn(output_sv, "=>", 2); }   // compact

        // append newline after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= 2) { sv_catpvn(output_sv, "\n", 1); }    // expand

        // call *_to_string_format() for data sub-structure
        sv_catsv(output_sv, arrayref_number_to_string_format(input_hv_avref__entry_value, newSViv(SvIV(format_level) - 1), newSViv(SvIV(indent_level) + 1)));  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (SvIV(format_level) >= 1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }  // pretty & expand
    else if (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " ", 1); }                                 // normal

    // end output string with right-curly-brace, as required for all RPerl hashes
    sv_catpvn(output_sv, "}", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_to_string(), bottom of subroutine\n");

    return(output_sv);
}

// call actual stringify routine, format level -1 (compact), indent level 0
SV* hashref_arrayref_string_to_string_compact(SV* input_hvref) {
    return hashref_arrayref_string_to_string_format(input_hvref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
SV* hashref_arrayref_string_to_string(SV* input_hvref) {
    return hashref_arrayref_string_to_string_format(input_hvref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (pretty), indent level 0
SV* hashref_arrayref_string_to_string_pretty(SV* input_hvref) {
    return hashref_arrayref_string_to_string_format(input_hvref, newSViv(1), newSViv(0));
}

// call actual stringify routine, format level 2 (expand), indent level 0
SV* hashref_arrayref_string_to_string_expand(SV* input_hvref) {
    return hashref_arrayref_string_to_string_format(input_hvref, newSViv(2), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs))))) to Perl-parsable (Perl SV containing PV)
SV* hashref_arrayref_string_to_string_format(SV* input_hvref_avref, SV* format_level, SV* indent_level) {
//    fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_to_string(), top of subroutine...\n");
//    fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", SvIV(format_level), SvIV(indent_level));

//  hashref_arrayref_string_CHECK(input_hvref_avref);
    hashref_arrayref_string_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "hashref_arrayref_string_to_string()");

    // declare local variables
    HV* input_hv_avref;
    integer input_hv_avref__num_keys;
    integer i;
    boolean i_is_0 = 1;
    HE* input_hv_avref__entry;
    SV* input_hv_avref__entry_key;
    string input_hv_avref__entry_key_string;
    SV* input_hv_avref__entry_value;
    SV* output_sv = newSVpv("", 0);

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // compute length of (number of keys in) input hash
    input_hv_avref = (HV*)SvRV(input_hvref_avref);
    input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_to_string(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { sv_catsv(output_sv, indent); }  // pretty

    // begin output string with left-curly-brace, as required for all RPerl hashes
    sv_setpvn(output_sv, "{", 1);

    // loop through all hash keys
    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_avref__num_keys;  ++i) {
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_to_string(), top of loop i = %"INTEGER"\n", i);

        // does not utilize i in entry retrieval
        input_hv_avref__entry = hv_iternext(input_hv_avref);

        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
//      hashentry_CHECK(input_hv_avref__entry);
//      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "hashref_arrayref_string_to_string()");

        // retrieve input hash's entry value at key
        input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
        input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);

        // DEV NOTE: integer type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
//      string_CHECK(input_hv_avref__entry_value);
//      string_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "hashref_arrayref_string_to_string()");

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { sv_catpvn(output_sv, ",", 1); }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >= 1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }  // pretty & expand
        else if (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " ", 1); }                                                                   // normal

        input_hv_avref__entry_key_string = escape_backslash_singlequote(string(SvPV_nolen(input_hv_avref__entry_key)));  // escape key string for error message

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        sv_catpvf(output_sv, "'%s'", SvPV_nolen(input_hv_avref__entry_key));  // alternative form
        sv_catpvf(output_sv, "'%s'", input_hv_avref__entry_key_string.c_str());

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " => ", 4); }  // normal & pretty & expand
        else                               { sv_catpvn(output_sv, "=>", 2); }   // compact

        // append newline after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= 2) { sv_catpvn(output_sv, "\n", 1); }    // expand

        // call *_to_string_format() for data sub-structure
        sv_catsv(output_sv, arrayref_string_to_string_format(input_hv_avref__entry_value, newSViv(SvIV(format_level) - 1), newSViv(SvIV(indent_level) + 1)));  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (SvIV(format_level) >= 1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }  // pretty & expand
    else if (SvIV(format_level) >= 0) { sv_catpvn(output_sv, " ", 1); }                                 // normal

    // end output string with right-curly-brace, as required for all RPerl hashes
    sv_catpvn(output_sv, "}", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_to_string(), bottom of subroutine\n");

    return(output_sv);
}

# elif defined __CPP__TYPES

// call actual stringify routine, format level -1 (compact), indent level 0
string hashref_arrayref_integer_to_string_compact(hashref_arrayref_integer input_umap_vector) {
    return hashref_arrayref_integer_to_string_format(input_umap_vector, -1, 0);
}

// call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
string hashref_arrayref_integer_to_string(hashref_arrayref_integer input_umap_vector) {
    return hashref_arrayref_integer_to_string_format(input_umap_vector, 0, 0);
}

// call actual stringify routine, format level 1 (pretty), indent level 0
string hashref_arrayref_integer_to_string_pretty(hashref_arrayref_integer input_umap_vector) {
    return hashref_arrayref_integer_to_string_format(input_umap_vector, 1, 0);
}

// call actual stringify routine, format level 2 (expand), indent level 0
string hashref_arrayref_integer_to_string_expand(hashref_arrayref_integer input_umap_vector) {
    return hashref_arrayref_integer_to_string_format(input_umap_vector, 2, 0);
}

// convert from (C++ std::unordered_map of (C++ std::vector of integers)) to Perl-parsable (C++ std::string)
string hashref_arrayref_integer_to_string_format(hashref_arrayref_integer input_umap_vector, integer format_level, integer indent_level) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_to_string(), top of subroutine\n");
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", format_level, indent_level);

    // declare local variables
    ostringstream output_stream;
    hashref_arrayref_integer_const_iterator i;
    boolean i_is_0 = 1;
    string key_string;

    // generate indent
    string indent = "";
    for (integer indent_i = 0; indent_i < indent_level; indent_i++) { indent += "    "; }

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_stream << indent; }  // pretty

    // begin output string with left-curly-brace, as required for all RPerl hashes
    output_stream << '{';

    // loop through all hash keys
    for (i = input_umap_vector.begin();  i != input_umap_vector.end();  ++i) {
        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_stream << ','; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >= 1) { output_stream << endl << indent << "    "; }  // pretty & expand
        else if (format_level >= 0) { output_stream << ' '; }                       // normal

        // escape key string
        key_string = escape_backslash_singlequote(i->first);

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        output_stream << "'" << (i->first).c_str() << "'";  // alternative format
        output_stream << "'" << key_string.c_str() << "'";

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if (format_level >= 0) { output_stream << " => "; }  // normal & pretty & expand
        else                   { output_stream << "=>"; }    // compact

        // append newline after fat arrow AKA fat comma, depending on format level
        if (format_level >= 2) { output_stream << "\n"; }    // expand

        // call *_to_string_format() for data sub-structure
        output_stream << arrayref_integer_to_string_format(i->second, format_level - 1, indent_level + 1);  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (format_level >= 1) { output_stream << endl << indent; }  // pretty & expand
    else if (format_level >= 0) { output_stream << ' '; }             // normal

    // end output string with right-curly-brace, as required for all RPerl hashes
    output_stream << '}';

//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_to_string(), after for() loop, have output_stream =\n%s\n", (char*)(output_stream.str().c_str()));
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_to_string(), bottom of subroutine\n");

    return(output_stream.str());
}

// call actual stringify routine, format level -1 (compact), indent level 0
string hashref_arrayref_number_to_string_compact(hashref_arrayref_number input_umap_vector) {
    return hashref_arrayref_number_to_string_format(input_umap_vector, -1, 0);
}

// call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
string hashref_arrayref_number_to_string(hashref_arrayref_number input_umap_vector) {
    return hashref_arrayref_number_to_string_format(input_umap_vector, 0, 0);
}

// call actual stringify routine, format level 1 (pretty), indent level 0
string hashref_arrayref_number_to_string_pretty(hashref_arrayref_number input_umap_vector) {
    return hashref_arrayref_number_to_string_format(input_umap_vector, 1, 0);
}

// call actual stringify routine, format level 2 (expand), indent level 0
string hashref_arrayref_number_to_string_expand(hashref_arrayref_number input_umap_vector) {
    return hashref_arrayref_number_to_string_format(input_umap_vector, 2, 0);
}

// convert from (C++ std::unordered_map of (C++ std::vector of numbers)) to Perl-parsable (C++ std::string)
string hashref_arrayref_number_to_string_format(hashref_arrayref_number input_umap_vector, integer format_level, integer indent_level) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_to_string(), top of subroutine\n");
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", format_level, indent_level);

    // declare local variables
    ostringstream output_stream;
    hashref_arrayref_number_const_iterator i;
    boolean i_is_0 = 1;
    string key_string;

    // generate indent
    string indent = "";
    for (integer indent_i = 0; indent_i < indent_level; indent_i++) { indent += "    "; }

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_stream << indent; }  // pretty

    // begin output string with left-curly-brace, as required for all RPerl hashes
    output_stream << '{';

    // loop through all hash keys
    for (i = input_umap_vector.begin();  i != input_umap_vector.end();  ++i) {
        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_stream << ','; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >= 1) { output_stream << endl << indent << "    "; }  // pretty & expand
        else if (format_level >= 0) { output_stream << ' '; }                       // normal

        // escape key string
        key_string = escape_backslash_singlequote(i->first);

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        output_stream << "'" << (i->first).c_str() << "'";  // alternative format
        output_stream << "'" << key_string.c_str() << "'";

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if (format_level >= 0) { output_stream << " => "; }  // normal & pretty & expand
        else                   { output_stream << "=>"; }    // compact

        // append newline after fat arrow AKA fat comma, depending on format level
        if (format_level >= 2) { output_stream << "\n"; }    // expand

        // call *_to_string_format() for data sub-structure
        output_stream << arrayref_number_to_string_format(i->second, format_level - 1, indent_level + 1);  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (format_level >= 1) { output_stream << endl << indent; }  // pretty & expand
    else if (format_level >= 0) { output_stream << ' '; }             // normal

    // end output string with right-curly-brace, as required for all RPerl hashes
    output_stream << '}';

//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_to_string(), after for() loop, have output_stream =\n%s\n", (char*)(output_stream.str().c_str()));
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_to_string(), bottom of subroutine\n");

    return(output_stream.str());
}

// call actual stringify routine, format level -1 (compact), indent level 0
string hashref_arrayref_string_to_string_compact(hashref_arrayref_string input_umap_vector) {
    return hashref_arrayref_string_to_string_format(input_umap_vector, -1, 0);
}

// call actual stringify routine, format level 0 (normal), indent level 0, DEFAULT
string hashref_arrayref_string_to_string(hashref_arrayref_string input_umap_vector) {
    return hashref_arrayref_string_to_string_format(input_umap_vector, 0, 0);
}

// call actual stringify routine, format level 1 (pretty), indent level 0
string hashref_arrayref_string_to_string_pretty(hashref_arrayref_string input_umap_vector) {
    return hashref_arrayref_string_to_string_format(input_umap_vector, 1, 0);
}

// call actual stringify routine, format level 2 (expand), indent level 0
string hashref_arrayref_string_to_string_expand(hashref_arrayref_string input_umap_vector) {
    return hashref_arrayref_string_to_string_format(input_umap_vector, 2, 0);
}

// convert from (C++ std::unordered_map of (C++ std::vector of strings)) to Perl-parsable (C++ std::string)
string hashref_arrayref_string_to_string_format(hashref_arrayref_string input_umap_vector, integer format_level, integer indent_level) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_to_string(), top of subroutine\n");
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", format_level, indent_level);

    // declare local variables
    ostringstream output_stream;
    hashref_arrayref_string_const_iterator i;
    boolean i_is_0 = 1;
    string key_string;

    // generate indent
    string indent = "";
    for (integer indent_i = 0; indent_i < indent_level; indent_i++) { indent += "    "; }

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_stream << indent; }  // pretty

    // begin output string with left-curly-brace, as required for all RPerl hashes
    output_stream << '{';

    // loop through all hash keys
    for (i = input_umap_vector.begin();  i != input_umap_vector.end();  ++i) {
        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_stream << ','; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >= 1) { output_stream << endl << indent << "    "; }  // pretty & expand
        else if (format_level >= 0) { output_stream << ' '; }                       // normal

        // escape key string
        key_string = escape_backslash_singlequote(i->first);

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        output_stream << "'" << (i->first).c_str() << "'";  // alternative format
        output_stream << "'" << key_string.c_str() << "'";

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if (format_level >= 0) { output_stream << " => "; }  // normal & pretty & expand
        else                   { output_stream << "=>"; }    // compact

        // append newline after fat arrow AKA fat comma, depending on format level
        if (format_level >= 2) { output_stream << "\n"; }    // expand

        // call *_to_string_format() for data sub-structure
        output_stream << arrayref_string_to_string_format(i->second, format_level - 1, indent_level + 1);  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (format_level >= 1) { output_stream << endl << indent; }  // pretty & expand
    else if (format_level >= 0) { output_stream << ' '; }             // normal

    // end output string with right-curly-brace, as required for all RPerl hashes
    output_stream << '}';

//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_to_string(), after for() loop, have output_stream =\n%s\n", (char*)(output_stream.str().c_str()));
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_to_string(), bottom of subroutine\n");

    return(output_stream.str());
}

# else

Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!

# endif

// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES

SV* hashref_arrayref_integer_typetest0(SV* lucky_arrayref_integers) {
//  hashref_arrayref_integer_CHECK(lucky_arrayref_integers);
    hashref_arrayref_integer_CHECKTRACE(lucky_arrayref_integers, "lucky_arrayref_integers", "hashref_arrayref_integer_typetest0()");

/*
    // BEGIN DEBUG CODE
    HV* lucky_arrayref_integers__deref = (HV*)SvRV(lucky_arrayref_integers);
    integer how_lucky = hv_iterinit(lucky_arrayref_integers__deref);
    integer i;

    for (i = 0;  i < how_lucky;  ++i) {
        HE* lucky_arrayref_integer__entry = hv_iternext(lucky_arrayref_integers__deref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
//      hashentry_CHECK(lucky_arrayref_integer__entry);
//      hashentry_CHECKTRACE(lucky_arrayref_integer__entry, "lucky_arrayref_integer__entry", "hashref_arrayref_integer_typetest0()");

        // DEV NOTE: not using lucky_number variable as in Hash.pm
        // DEV NOTE: integer type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
//      integer_CHECK(hv_iterval(lucky_arrayref_integers__deref, lucky_arrayref_integer__entry));
//      integer_CHECKTRACE(hv_iterval(lucky_arrayref_integers__deref, lucky_arrayref_integer__entry), (char*)((string)"hv_iterval(lucky_arrayref_integers__deref, lucky_arrayref_integer__entry) at key '" + (string)SvPV_nolen(hv_iterkeysv(lucky_arrayref_integer__entry)) + "'").c_str(), "hashref_arrayref_integer_typetest0()");

        SV* lucky_arrayref_integer__key = hv_iterkeysv(lucky_arrayref_integer__entry);
        SV* lucky_arrayref_integer__value = hv_iterval(lucky_arrayref_integers__deref, lucky_arrayref_integer__entry);

        AV* lucky_array_integer = (AV*)SvRV(lucky_arrayref_integer__value);
        integer how_luckier = av_len(lucky_array_integer) + 1;
        integer j;

        for (j = 0;  j < how_luckier;  ++j) {
            integer_CHECK(*av_fetch(lucky_array_integer, j, 0));
            integer_CHECKTRACE(*av_fetch(lucky_array_integer, j, 0), (char*)((string)"*av_fetch(lucky_array_integer, j, 0) at index " + to_string(j)).c_str() + (string)", key '" + (string)SvPV_nolen(lucky_arrayref_integer__key) + (string)"'", "hashref_arrayref_integer_typetest0()");
//            fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_typetest0(), have lucky integer %"INTEGER"/%"INTEGER" = %"INTEGER", key '%s', BARSTEP\n", j, (how_luckier - 1), (integer)SvIV(*av_fetch(lucky_array_integer, j, 0)), SvPV_nolen(lucky_arrayref_integer__key));
        }
    }
    // END DEBUG CODE
*/

    return(newSVpvf("%s%s", SvPV_nolen(hashref_arrayref_integer_to_string(lucky_arrayref_integers)), "CPPOPS_PERLTYPES"));
}

SV* hashref_arrayref_integer_typetest1(SV* my_size) {
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "hashref_arrayref_integer_typetest1()");
    HV* output_hv = newHV();
    integer i;
    char temp_key[30];

    for (i = 0;  i < SvIV(my_size);  ++i) {
        // set key up here so it can be used by the debugging print statement inside the inner loop
        sprintf(temp_key, "CPPOPS_PERLTYPES_funkey%"INTEGER"", i);

        // BEGIN ARRAY CODE
        AV* temp_av = newAV();
        integer j;

        av_extend(temp_av, (I32)(SvIV(my_size) - 1));

        for (j = 0;  j < SvIV(my_size);  ++j) {
            av_store(temp_av, (I32)j, newSViv(i * j));
//            fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_integer_typetest1(), setting element at key '%s', at index %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAT\n", temp_key, j, (integer)(SvIV(my_size) - 1), (integer)SvIV(*av_fetch(temp_av, (I32)j, 0)));
        }
        // END ARRAY CODE

        hv_store(output_hv, (const char*)temp_key, (U32)strlen(temp_key), newRV_noinc((SV*) temp_av), (U32)0);
    }

    return(newRV_noinc((SV*) output_hv));
}

SV* hashref_arrayref_number_typetest0(SV* lucky_arrayref_numbers) {
//  hashref_arrayref_number_CHECK(lucky_arrayref_numbers);
    hashref_arrayref_number_CHECKTRACE(lucky_arrayref_numbers, "lucky_arrayref_numbers", "hashref_arrayref_number_typetest0()");

/*
    // BEGIN DEBUG CODE
    HV* lucky_arrayref_numbers_deref = (HV*)SvRV(lucky_arrayref_numbers);
    integer how_lucky = hv_iterinit(lucky_arrayref_numbers_deref);
    integer i;

    for (i = 0;  i < how_lucky;  ++i) {
        HE* lucky_arrayref_number_entry = hv_iternext(lucky_arrayref_numbers_deref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
//      hashentry_CHECK(lucky_arrayref_number_entry);
//      hashentry_CHECKTRACE(lucky_arrayref_number_entry, "lucky_arrayref_number_entry", "hashref_arrayref_number_typetest0()");

        // DEV NOTE: not using lucky_number variable as in Hash.pm
        // DEV NOTE: number type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
//      number_CHECK(hv_iterval(lucky_arrayref_numbers_deref, lucky_arrayref_number_entry));
//      number_CHECKTRACE(hv_iterval(lucky_arrayref_numbers_deref, lucky_arrayref_number_entry), (char*)((string)"hv_iterval(lucky_arrayref_numbers_deref, lucky_arrayref_number_entry) at key '" + (string)SvPV_nolen(hv_iterkeysv(lucky_arrayref_number_entry)) + "'").c_str(), "hashref_arrayref_number_typetest0()");

        SV* lucky_arrayref_number_key = hv_iterkeysv(lucky_arrayref_number_entry);
        SV* lucky_arrayref_number_value = hv_iterval(lucky_arrayref_numbers_deref, lucky_arrayref_number_entry);

        AV* lucky_array_number = (AV*)SvRV(lucky_arrayref_number_value);
        integer how_luckier = av_len(lucky_array_number) + 1;
        integer j;

        for (j = 0;  j < how_luckier;  ++j) {
            number_CHECK(*av_fetch(lucky_array_number, j, 0));
            number_CHECKTRACE(*av_fetch(lucky_array_number, j, 0), (char*)((string)"*av_fetch(lucky_array_number, j, 0) at index " + to_string(j)).c_str() + (string)", key '" + (string)SvPV_nolen(lucky_arrayref_number_key) + (string)"'", "hashref_arrayref_number_typetest0()");
//            fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_typetest0(), have lucky number %"INTEGER"/%"INTEGER" = %"NUMBER", key '%s', BARSTEP\n", j, (how_luckier - 1), (number)SvNV(*av_fetch(lucky_array_number, j, 0)), SvPV_nolen(lucky_arrayref_number_key));
        }
    }
    // END DEBUG CODE
*/

    return(newSVpvf("%s%s", SvPV_nolen(hashref_arrayref_number_to_string(lucky_arrayref_numbers)), "CPPOPS_PERLTYPES"));
}

SV* hashref_arrayref_number_typetest1(SV* my_size) {
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "hashref_arrayref_number_typetest1()");
    HV* output_hv = newHV();
    integer i;
    char temp_key[30];

    for (i = 0;  i < SvIV(my_size);  ++i) {
        // set key up here so it can be used by the debugging print statement inside the inner loop
        sprintf(temp_key, "CPPOPS_PERLTYPES_funkey%"INTEGER"", i);

        // BEGIN ARRAY CODE
        AV* temp_av = newAV();
        integer j;

        av_extend(temp_av, (I32)(SvIV(my_size) - 1));

        for (j = 0;  j < SvIV(my_size);  ++j) {
            av_store(temp_av, (I32)j, newSVnv(i * j * 5.123456789));
//            fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_number_typetest1(), setting element at key '%s', at index %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAT\n", temp_key, j, (integer)(SvIV(my_size) - 1), (number)SvNV(*av_fetch(temp_av, (I32)j, 0)));
        }
        // END ARRAY CODE

        hv_store(output_hv, (const char*)temp_key, (U32)strlen(temp_key), newRV_noinc((SV*) temp_av), (U32)0);
    }

    return(newRV_noinc((SV*) output_hv));
}

SV* hashref_arrayref_string_typetest0(SV* lucky_arrayref_strings) {
//  hashref_arrayref_string_CHECK(lucky_arrayref_strings);
    hashref_arrayref_string_CHECKTRACE(lucky_arrayref_strings, "lucky_arrayref_strings", "hashref_arrayref_string_typetest0()");

/*
    // BEGIN DEBUG CODE
    HV* lucky_arrayref_strings_deref = (HV*)SvRV(lucky_arrayref_strings);
    integer how_lucky = hv_iterinit(lucky_arrayref_strings_deref);
    integer i;

    for (i = 0;  i < how_lucky;  ++i) {
        HE* lucky_arrayref_string_entry = hv_iternext(lucky_arrayref_strings_deref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
//      hashentry_CHECK(lucky_arrayref_string_entry);
//      hashentry_CHECKTRACE(lucky_arrayref_string_entry, "lucky_arrayref_string_entry", "hashref_arrayref_string_typetest0()");

        // DEV NOTE: not using lucky_string variable as in Hash.pm
        // DEV NOTE: string type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
//      string_CHECK(hv_iterval(lucky_arrayref_strings_deref, lucky_arrayref_string_entry));
//      string_CHECKTRACE(hv_iterval(lucky_arrayref_strings_deref, lucky_arrayref_string_entry), (char*)((string)"hv_iterval(lucky_arrayref_strings_deref, lucky_arrayref_string_entry) at key '" + (string)SvPV_nolen(hv_iterkeysv(lucky_arrayref_string_entry)) + "'").c_str(), "hashref_arrayref_string_typetest0()");

        SV* lucky_arrayref_string_key = hv_iterkeysv(lucky_arrayref_string_entry);
        SV* lucky_arrayref_string_value = hv_iterval(lucky_arrayref_strings_deref, lucky_arrayref_string_entry);

        AV* lucky_array_string = (AV*)SvRV(lucky_arrayref_string_value);
        integer how_luckier = av_len(lucky_array_string) + 1;
        integer j;

        for (j = 0;  j < how_luckier;  ++j) {
            string_CHECK(*av_fetch(lucky_array_string, j, 0));
            string_CHECKTRACE(*av_fetch(lucky_array_string, j, 0), (char*)((string)"*av_fetch(lucky_array_string, j, 0) at index " + to_string(j)).c_str() + (string)", key '" + (string)SvPV_nolen(lucky_arrayref_string_key) + (string)"'", "hashref_arrayref_string_typetest0()");
//            fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_typetest0(), have lucky string %"INTEGER"/%"INTEGER" = '%s', key '%s', BARSTEP\n", j, (how_luckier - 1), (string)SvPV(*av_fetch(lucky_array_string, j, 0)), SvPV_nolen(lucky_arrayref_string_key));
        }
    }
    // END DEBUG CODE
*/

    return(newSVpvf("%s%s", SvPV_nolen(hashref_arrayref_string_to_string(lucky_arrayref_strings)), "CPPOPS_PERLTYPES"));
}

SV* hashref_arrayref_string_typetest1(SV* my_size) {
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "hashref_arrayref_string_typetest1()");
    HV* output_hv = newHV();
    integer i;
    char temp_key[30];

    for (i = 0;  i < SvIV(my_size);  ++i) {
        // set key up here so it can be used by the debugging print statement inside the inner loop
        sprintf(temp_key, "CPPOPS_PERLTYPES_funkey%"INTEGER"", i);

        // BEGIN ARRAY CODE
        AV* temp_av = newAV();
        integer j;

        av_extend(temp_av, (I32)(SvIV(my_size) - 1));

        for (j = 0;  j < SvIV(my_size);  ++j) {
            av_store( temp_av, (I32)j, newSVpvf( "Jeffy Ten! (%"INTEGER", %"INTEGER")/%"INTEGER"", i, j, (integer)(SvIV(my_size) - 1) ) );
//            fprintf(stderr, "in CPPOPS_PERLTYPES hashref_arrayref_string_typetest1(), setting element at key '%s', at index %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAT\n", temp_key, j, (integer)(SvIV(my_size) - 1), (string)SvPV(*av_fetch(temp_av, (I32)j, 0)));
        }
        // END ARRAY CODE

        hv_store(output_hv, (const char*)temp_key, (U32)strlen(temp_key), newRV_noinc((SV*) temp_av), (U32)0);
    }

    return(newRV_noinc((SV*) output_hv));
}

# elif defined __CPP__TYPES

string hashref_arrayref_integer_typetest0(hashref_arrayref_integer lucky_arrayref_integers) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_typetest0(), top of subroutine...\n");

/*
    // BEGIN DEBUG CODE
    hashref_arrayref_integer_const_iterator i;
    for (i = lucky_arrayref_integers.begin();  i != lucky_arrayref_integers.end();  ++i) {
        // BEGIN ARRAY CODE
        arrayref_integer lucky_arrayref_integer = i->second;
        integer how_luckier = lucky_arrayref_integer.size();
        integer j;

        for (j = 0;  j < how_luckier;  ++j) {
            fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_typetest0(), have lucky integer %"INTEGER"/%"INTEGER" = %"INTEGER", key '%s', BARSTEP\n", j, (how_luckier - 1), lucky_arrayref_integer[j], (i->first).c_str());
        }
        // END ARRAY CODE
    }
    // END DEBUG CODE
*/

    return(hashref_arrayref_integer_to_string(lucky_arrayref_integers) + "CPPOPS_CPPTYPES");
}

hashref_arrayref_integer hashref_arrayref_integer_typetest1(integer my_size) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_typetest1(), top of subroutine...\n");

    hashref_arrayref_integer new_umap_vector(my_size);
    integer i;
    string temp_key;
    for (i = 0;  i < my_size;  ++i) {
        temp_key = "CPPOPS_CPPTYPES_funkey" + std::to_string(i);

        // BEGIN ARRAY CODE
        arrayref_integer temp_vec(my_size);
        integer j;
        for (j = 0;  j < my_size;  ++j)
        {
            temp_vec[j] = i * j;
//            fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_integer_typetest1(), setting element at key '%s', at index %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAZ\n", temp_key.c_str(), j, (my_size - 1), temp_vec[j]);
        }
        // END ARRAY CODE

        new_umap_vector[temp_key] = temp_vec;
    }
    return(new_umap_vector);
}

string hashref_arrayref_number_typetest0(hashref_arrayref_number lucky_arrayref_numbers) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_typetest0(), top of subroutine...\n");

/*
    // BEGIN DEBUG CODE
    hashref_arrayref_number_const_iterator i;
    for (i = lucky_arrayref_numbers.begin();  i != lucky_arrayref_numbers.end();  ++i) {
        // BEGIN ARRAY CODE
        arrayref_number lucky_arrayref_number = i->second;
        integer how_luckier = lucky_arrayref_number.size();
        integer j;

        for (j = 0;  j < how_luckier;  ++j) {
            fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_typetest0(), have lucky number %"INTEGER"/%"INTEGER" = %"NUMBER", key '%s', BARSTEP\n", j, (how_luckier - 1), lucky_arrayref_number[j], (i->first).c_str());
        }
        // END ARRAY CODE
    }
    // END DEBUG CODE
*/

    return(hashref_arrayref_number_to_string(lucky_arrayref_numbers) + "CPPOPS_CPPTYPES");
}

hashref_arrayref_number hashref_arrayref_number_typetest1(integer my_size) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_typetest1(), top of subroutine...\n");

    hashref_arrayref_number new_umap_vector(my_size);
    integer i;
    string temp_key;
    for (i = 0;  i < my_size;  ++i) {
        temp_key = "CPPOPS_CPPTYPES_funkey" + std::to_string(i);

        // BEGIN ARRAY CODE
        arrayref_number temp_vec(my_size);
        integer j;
        for (j = 0;  j < my_size;  ++j)
        {
            temp_vec[j] = i * j * 5.123456789;
//            fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_number_typetest1(), setting element at key '%s', at index %"INTEGER"/%"INTEGER" = %"NUMBER", BARBAZ\n", temp_key.c_str(), j, (my_size - 1), temp_vec[j]);
        }
        // END ARRAY CODE

        new_umap_vector[temp_key] = temp_vec;
    }
    return(new_umap_vector);
}

string hashref_arrayref_string_typetest0(hashref_arrayref_string lucky_arrayref_strings) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_typetest0(), top of subroutine...\n");

/*
    // BEGIN DEBUG CODE
    hashref_arrayref_string_const_iterator i;
    for (i = lucky_arrayref_strings.begin();  i != lucky_arrayref_strings.end();  ++i) {
        // BEGIN ARRAY CODE
        arrayref_string lucky_arrayref_string = i->second;
        integer how_luckier = lucky_arrayref_string.size();
        integer j;

        for (j = 0;  j < how_luckier;  ++j) {
            fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_typetest0(), have lucky string %"INTEGER"/%"INTEGER" = '%s', key '%s', BARSTEP\n", j, (how_luckier - 1), lucky_arrayref_string[j].c_str(), (i->first).c_str());
        }
        // END ARRAY CODE
    }
    // END DEBUG CODE
*/

    return(hashref_arrayref_string_to_string(lucky_arrayref_strings) + "CPPOPS_CPPTYPES");
}

hashref_arrayref_string hashref_arrayref_string_typetest1(integer my_size) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_typetest1(), top of subroutine...\n");

    hashref_arrayref_string new_umap_vector(my_size);
    integer i;
    string temp_key;
    for (i = 0;  i < my_size;  ++i) {
        temp_key = "CPPOPS_CPPTYPES_funkey" + std::to_string(i);

        // BEGIN ARRAY CODE
        arrayref_string temp_vec(my_size);
        integer j;
        for (j = 0;  j < my_size;  ++j)
        {
            temp_vec[j] = "Jeffy Ten! (" + integer_to_string(i) + ", " + integer_to_string(j) + ")/" + integer_to_string(my_size - 1);

            // DEV NOTE: there are many complicated options for storing a printf-style formatted character stream into a std::string data type,
            // fall back to data conversion and string concatenation instead
//            "Jeffy Ten! (%"INTEGER", %"INTEGER")/%"INTEGER"", i, j, (my_size - 1)

//            fprintf(stderr, "in CPPOPS_CPPTYPES hashref_arrayref_string_typetest1(), setting element at key '%s', at index %"INTEGER"/%"INTEGER" = '%s', BARBAZ\n", temp_key.c_str(), j, (my_size - 1), temp_vec[j].c_str());
        }
        // END ARRAY CODE

        new_umap_vector[temp_key] = temp_vec;
    }
    return(new_umap_vector);
}

# endif

#endif
