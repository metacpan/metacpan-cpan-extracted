using std::cout;  using std::cerr;  using std::endl;  using std::to_string;

#ifndef __CPP__INCLUDED__Perl__Structure__Hash__SubTypes3D_cpp
#define __CPP__INCLUDED__Perl__Structure__Hash__SubTypes3D_cpp 0.001_000

#include <Perl/Structure/Hash/SubTypes3D.h>  // -> ??? (relies on <unordered_map> being included via Inline::CPP's AUTO_INCLUDE config option in RPerl/Inline.pm)

// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]

// DEV NOTE, STEPS TO CONVERT FROM CHECKTRACE TO CHECK
// 1.  CHECKTRACE -> CHECK
// 2.  remove 2 extra args from function header
// 3.  remove var & sub info from error messages
// 4.  remove var & sub info from opening debug statements

void hashref_hashref_arrayref_integer_CHECK(SV* possible_hashref_hashref_arrayref_integer) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_integer_CHECK(), top of subroutine\n");

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with integer-specific error codes
    if ( not( SvOK(possible_hashref_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVHVRVAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_integer value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVHVRVAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_integer value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_hashref_arrayref_integer;
    integer possible_hash_hashref_arrayref_integer__num_keys;
    integer i;
    HE* possible_hash_hashref_arrayref_integer__hashentry;
    SV* possible_hash_hashref_arrayref_integer__hashentry_value;
    SV* possible_hash_hashref_arrayref_integer__hashentry_key;
    string possible_hash_hashref_arrayref_integer__hashentry_key_string;

    possible_hash_hashref_arrayref_integer = (HV*)SvRV(possible_hashref_hashref_arrayref_integer);
    possible_hash_hashref_arrayref_integer__num_keys = hv_iterinit(possible_hash_hashref_arrayref_integer);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_hashref_arrayref_integer__num_keys;  ++i) {
        possible_hash_hashref_arrayref_integer__hashentry = hv_iternext(possible_hash_hashref_arrayref_integer);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with integer-specific error code
        if (possible_hash_hashref_arrayref_integer__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVIVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_hashref_arrayref_integer__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_hashref_arrayref_integer__hashentry_value = hv_iterval(possible_hash_hashref_arrayref_integer, possible_hash_hashref_arrayref_integer__hashentry);

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  naming bridge
        // 2.  HVRVAVRV -> HVRVHVRVAVRV
        // 3.  AVRVHE -> HVRVAVRVHE
        // 4.  increment error code serial numbers by 2 for HVRV codes, by 1 for HE codes
        // 5.  add key info to first 2 pasted error messages
        // 6.  add sub-key info to remaining pasted error messages
        // 7.  j -> k
        // 8.  i -> j
        // 9.  delete pre-existing 1D ARRAY CODE

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* possible_hashref_arrayref_integer = possible_hash_hashref_arrayref_integer__hashentry_value;

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with integer-specific error codes
        if ( not( SvOK(possible_hashref_arrayref_integer) ) ) {
            possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
            possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str());
        }
        if ( not( SvHROKp(possible_hashref_arrayref_integer) ) ) {
            possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
            possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but non-hashref value found at key '%s',\ncroaking", possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str());
        }

        HV* possible_hash_arrayref_integer;
        integer possible_hash_arrayref_integer__num_keys;
        integer j;
        HE* possible_hash_arrayref_integer__hashentry;
        SV* possible_hash_arrayref_integer__hashentry_value;
        SV* possible_hash_arrayref_integer__hashentry_key;
        string possible_hash_arrayref_integer__hashentry_key_string;

        possible_hash_arrayref_integer = (HV*)SvRV(possible_hashref_arrayref_integer);
        possible_hash_arrayref_integer__num_keys = hv_iterinit(possible_hash_arrayref_integer);

        // incrementing iteration, iterator j not actually used in loop body
        for (j = 0;  j < possible_hash_arrayref_integer__num_keys;  ++j) {
            possible_hash_arrayref_integer__hashentry = hv_iternext(possible_hash_arrayref_integer);

            // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with integer-specific error code
            if (possible_hash_arrayref_integer__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVIVHE01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_integer__hashentry value expected but undefined/null value found,\ncroaking"); }
            possible_hash_arrayref_integer__hashentry_value = hv_iterval(possible_hash_arrayref_integer, possible_hash_arrayref_integer__hashentry);

            // DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() macro & subroutine, but with hash-specific error codes
            if (not(SvOK(possible_hash_arrayref_integer__hashentry_value))) {
                possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message

                croak("\nERROR EHVRVHVRVAVRVIV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found at sub-key '%s', key '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str());
            }

            if (not(SvAROKp(possible_hash_arrayref_integer__hashentry_value))) {
                possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVIV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found at sub-key '%s', key '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str());
            }

            SV* possible_arrayref_integer = possible_hash_arrayref_integer__hashentry_value;

            AV* possible_array_integer;
            integer possible_array_integer__length;
            integer k;
            SV** possible_array_integer__element;

            possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
            possible_array_integer__length = av_len(possible_array_integer) + 1;

            // incrementing iteration
            for (k = 0;  k < possible_array_integer__length;  ++k) {
                possible_array_integer__element = av_fetch(possible_array_integer, k, 0);
                if (not(SvOK(*possible_array_integer__element))) {
                    possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                    possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                    possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVIV06, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at index %"INTEGER", sub-key '%s', key '%s',\ncroaking", k, possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str());
                }
                if (not(SvIOKp(*possible_array_integer__element))) {
                    possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                    possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                    possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVIV07, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index %"INTEGER", sub-key '%s', key '%s',\ncroaking", k, possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str());
                }
            }
        }

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_integer_CHECK(), bottom of subroutine\n");
}

// DEV NOTE, STEPS TO CONVERT FROM 2D TO 3D CHECK(TRACE)
// 1.  hashref_arrayref_ -> hashref_hashref_arrayref_
// 2.  _hash_arrayref_ - _hash_hashref_arrayref_
// 3.  possible_hash_arrayref_TYPE -> possible_hash_hashref_arrayref_TYPE  (manual search, not full auto replace)
// 4.  arrayref_TYPE_hashentry -> hashref_arrayref_TYPE__hashentry
// 5.  HVRVAVRV -> HVRVHVRVAVRV
// 6.  AVRVHE -> HVRVAVRVHE
// 7.  paste 2D code, follow steps to convert below  (make sure to use corresponding CHECK vs CHECKTRACE)

void hashref_hashref_arrayref_integer_CHECKTRACE(SV* possible_hashref_hashref_arrayref_integer, const char* variable_name, const char* subroutine_name) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_integer_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_integer_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with integer-specific error codes
    if ( not( SvOK(possible_hashref_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVHVRVAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_integer value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_hashref_arrayref_integer) ) ) { croak( "\nERROR EHVRVHVRVAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_integer value expected but non-hashref value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_hashref_arrayref_integer;
    integer possible_hash_hashref_arrayref_integer__num_keys;
    integer i;
    HE* possible_hash_hashref_arrayref_integer__hashentry;
    SV* possible_hash_hashref_arrayref_integer__hashentry_value;
    SV* possible_hash_hashref_arrayref_integer__hashentry_key;
    string possible_hash_hashref_arrayref_integer__hashentry_key_string;

    possible_hash_hashref_arrayref_integer = (HV*)SvRV(possible_hashref_hashref_arrayref_integer);
    possible_hash_hashref_arrayref_integer__num_keys = hv_iterinit(possible_hash_hashref_arrayref_integer);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_hashref_arrayref_integer__num_keys;  ++i) {
        possible_hash_hashref_arrayref_integer__hashentry = hv_iternext(possible_hash_hashref_arrayref_integer);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with integer-specific error code
        if (possible_hash_hashref_arrayref_integer__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVIVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_hashref_arrayref_integer__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
        possible_hash_hashref_arrayref_integer__hashentry_value = hv_iterval(possible_hash_hashref_arrayref_integer, possible_hash_hashref_arrayref_integer__hashentry);

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  naming bridge
        // 2.  HVRVAVRV -> HVRVHVRVAVRV
        // 3.  AVRVHE -> HVRVAVRVHE
        // 4.  increment error code serial numbers by 2 for HVRV codes, by 1 for HE codes
        // 5.  add key info to first 2 pasted error messages
        // 6.  add sub-key info to remaining pasted error messages
        // 7.  j -> k
        // 8.  i -> j
        // 9.  delete pre-existing 1D ARRAY CODE

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* possible_hashref_arrayref_integer = possible_hash_hashref_arrayref_integer__hashentry_value;

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with integer-specific error codes
        if ( not( SvOK(possible_hashref_arrayref_integer) ) ) {
            possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
            possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but undefined/null value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
        if ( not( SvHROKp(possible_hashref_arrayref_integer) ) ) {
            possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
            possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_integer value expected but non-hashref value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        HV* possible_hash_arrayref_integer;
        integer possible_hash_arrayref_integer__num_keys;
        integer j;
        HE* possible_hash_arrayref_integer__hashentry;
        SV* possible_hash_arrayref_integer__hashentry_value;
        SV* possible_hash_arrayref_integer__hashentry_key;
        string possible_hash_arrayref_integer__hashentry_key_string;

        possible_hash_arrayref_integer = (HV*)SvRV(possible_hashref_arrayref_integer);
        possible_hash_arrayref_integer__num_keys = hv_iterinit(possible_hash_arrayref_integer);

        // incrementing iteration, iterator j not actually used in loop body
        for (j = 0;  j < possible_hash_arrayref_integer__num_keys;  ++j) {
            possible_hash_arrayref_integer__hashentry = hv_iternext(possible_hash_arrayref_integer);

            // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with integer-specific error code
            if (possible_hash_arrayref_integer__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVIVHE01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_integer__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
            possible_hash_arrayref_integer__hashentry_value = hv_iterval(possible_hash_arrayref_integer, possible_hash_arrayref_integer__hashentry);

            // DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() macro & subroutine, but with hash-specific error codes
            if (not(SvOK(possible_hash_arrayref_integer__hashentry_value))) {
                possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVIV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found at sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }

            if (not(SvAROKp(possible_hash_arrayref_integer__hashentry_value))) {
                possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVIV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found at sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }

            SV* possible_arrayref_integer = possible_hash_arrayref_integer__hashentry_value;

            AV* possible_array_integer;
            integer possible_array_integer__length;
            integer k;
            SV** possible_array_integer__element;

            possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
            possible_array_integer__length = av_len(possible_array_integer) + 1;

            // incrementing iteration
            for (k = 0;  k < possible_array_integer__length;  ++k) {
                possible_array_integer__element = av_fetch(possible_array_integer, k, 0);
                if (not(SvOK(*possible_array_integer__element))) {
                    possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                    possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                    possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVIV06, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at index %"INTEGER", sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", k, possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
                }
                if (not(SvIOKp(*possible_array_integer__element))) {
                    possible_hash_hashref_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_integer__hashentry);
                    possible_hash_hashref_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_integer__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_integer__hashentry_key = hv_iterkeysv(possible_hash_arrayref_integer__hashentry);
                    possible_hash_arrayref_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_integer__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVIV07, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index %"INTEGER", sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", k, possible_hash_arrayref_integer__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
                }
            }
        }

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_integer_CHECKTRACE(), bottom of subroutine\n");
}

// DEV NOTE, STEPS TO CONVERT FROM integer TO number:
// 1.  IV -> NV
// 2.  add SvNOKp to SvIOKp
// 3.  integer_ -> number_
// 4.  integer value -> number value
// 5.  integer- -> number-

void hashref_hashref_arrayref_number_CHECK(SV* possible_hashref_hashref_arrayref_number) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_number_CHECK(), top of subroutine\n");

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with number-specific error codes
    if ( not( SvOK(possible_hashref_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVHVRVAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_number value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVHVRVAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_number value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_hashref_arrayref_number;
    integer possible_hash_hashref_arrayref_number__num_keys;
    integer i;
    HE* possible_hash_hashref_arrayref_number__hashentry;
    SV* possible_hash_hashref_arrayref_number__hashentry_value;
    SV* possible_hash_hashref_arrayref_number__hashentry_key;
    string possible_hash_hashref_arrayref_number__hashentry_key_string;

    possible_hash_hashref_arrayref_number = (HV*)SvRV(possible_hashref_hashref_arrayref_number);
    possible_hash_hashref_arrayref_number__num_keys = hv_iterinit(possible_hash_hashref_arrayref_number);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_hashref_arrayref_number__num_keys;  ++i) {
        possible_hash_hashref_arrayref_number__hashentry = hv_iternext(possible_hash_hashref_arrayref_number);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with number-specific error code
        if (possible_hash_hashref_arrayref_number__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVNVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_hashref_arrayref_number__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_hashref_arrayref_number__hashentry_value = hv_iterval(possible_hash_hashref_arrayref_number, possible_hash_hashref_arrayref_number__hashentry);

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  naming bridge
        // 2.  HVRVAVRV -> HVRVHVRVAVRV
        // 3.  AVRVHE -> HVRVAVRVHE
        // 4.  increment error code serial numbers by 2 for HVRV codes, by 1 for HE codes
        // 5.  add key info to first 2 pasted error messages
        // 6.  add sub-key info to remaining pasted error messages
        // 7.  j -> k
        // 8.  i -> j
        // 9.  delete pre-existing 1D ARRAY CODE

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* possible_hashref_arrayref_number = possible_hash_hashref_arrayref_number__hashentry_value;

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with number-specific error codes
        if ( not( SvOK(possible_hashref_arrayref_number) ) ) {
            possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
            possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_hashref_arrayref_number__hashentry_key_string.c_str());
        }
        if ( not( SvHROKp(possible_hashref_arrayref_number) ) ) {
            possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
            possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but non-hashref value found at key '%s',\ncroaking", possible_hash_hashref_arrayref_number__hashentry_key_string.c_str());
        }

        HV* possible_hash_arrayref_number;
        integer possible_hash_arrayref_number__num_keys;
        integer j;
        HE* possible_hash_arrayref_number__hashentry;
        SV* possible_hash_arrayref_number__hashentry_value;
        SV* possible_hash_arrayref_number__hashentry_key;
        string possible_hash_arrayref_number__hashentry_key_string;

        possible_hash_arrayref_number = (HV*)SvRV(possible_hashref_arrayref_number);
        possible_hash_arrayref_number__num_keys = hv_iterinit(possible_hash_arrayref_number);

        // incrementing iteration, iterator j not actually used in loop body
        for (j = 0;  j < possible_hash_arrayref_number__num_keys;  ++j) {
            possible_hash_arrayref_number__hashentry = hv_iternext(possible_hash_arrayref_number);

            // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with number-specific error code
            if (possible_hash_arrayref_number__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVNVHE01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_number__hashentry value expected but undefined/null value found,\ncroaking"); }
            possible_hash_arrayref_number__hashentry_value = hv_iterval(possible_hash_arrayref_number, possible_hash_arrayref_number__hashentry);

            // DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECK() macro & subroutine, but with hash-specific error codes
            if (not(SvOK(possible_hash_arrayref_number__hashentry_value))) {
                possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVNV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found at sub-key '%s', key '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str());
            }

            if (not(SvAROKp(possible_hash_arrayref_number__hashentry_value))) {
                possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVNV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found at sub-key '%s', key '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str());
            }

            SV* possible_arrayref_number = possible_hash_arrayref_number__hashentry_value;

            AV* possible_array_number;
            integer possible_array_number__length;
            integer k;
            SV** possible_array_number__element;

            possible_array_number = (AV*)SvRV(possible_arrayref_number);
            possible_array_number__length = av_len(possible_array_number) + 1;

            // incrementing iteration
            for (k = 0;  k < possible_array_number__length;  ++k) {
                possible_array_number__element = av_fetch(possible_array_number, k, 0);
                if (not(SvOK(*possible_array_number__element))) {
                    possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                    possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                    possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVNV06, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index %"INTEGER", sub-key '%s', key '%s',\ncroaking", k, possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str());
                }
                if (not(SvNOKp(*possible_array_number__element) or
                        SvIOKp(*possible_array_number__element))) {
                    possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                    possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                    possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVNV07, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index %"INTEGER", sub-key '%s', key '%s',\ncroaking", k, possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str());
                }
            }
        }

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_number_CHECK(), bottom of subroutine\n");
}

void hashref_hashref_arrayref_number_CHECKTRACE(SV* possible_hashref_hashref_arrayref_number, const char* variable_name, const char* subroutine_name) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_number_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_number_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with number-specific error codes
    if ( not( SvOK(possible_hashref_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVHVRVAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_number value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_hashref_arrayref_number) ) ) { croak( "\nERROR EHVRVHVRVAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_number value expected but non-hashref value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_hashref_arrayref_number;
    integer possible_hash_hashref_arrayref_number__num_keys;
    integer i;
    HE* possible_hash_hashref_arrayref_number__hashentry;
    SV* possible_hash_hashref_arrayref_number__hashentry_value;
    SV* possible_hash_hashref_arrayref_number__hashentry_key;
    string possible_hash_hashref_arrayref_number__hashentry_key_string;

    possible_hash_hashref_arrayref_number = (HV*)SvRV(possible_hashref_hashref_arrayref_number);
    possible_hash_hashref_arrayref_number__num_keys = hv_iterinit(possible_hash_hashref_arrayref_number);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_hashref_arrayref_number__num_keys;  ++i) {
        possible_hash_hashref_arrayref_number__hashentry = hv_iternext(possible_hash_hashref_arrayref_number);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with number-specific error code
        if (possible_hash_hashref_arrayref_number__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVNVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_hashref_arrayref_number__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
        possible_hash_hashref_arrayref_number__hashentry_value = hv_iterval(possible_hash_hashref_arrayref_number, possible_hash_hashref_arrayref_number__hashentry);

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  naming bridge
        // 2.  HVRVAVRV -> HVRVHVRVAVRV
        // 3.  AVRVHE -> HVRVAVRVHE
        // 4.  increment error code serial numbers by 2 for HVRV codes, by 1 for HE codes
        // 5.  add key info to first 2 pasted error messages
        // 6.  add sub-key info to remaining pasted error messages
        // 7.  j -> k
        // 8.  i -> j
        // 9.  delete pre-existing 1D ARRAY CODE

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* possible_hashref_arrayref_number = possible_hash_hashref_arrayref_number__hashentry_value;

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with number-specific error codes
        if ( not( SvOK(possible_hashref_arrayref_number) ) ) {
            possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
            possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but undefined/null value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_hashref_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
        if ( not( SvHROKp(possible_hashref_arrayref_number) ) ) {
            possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
            possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_number value expected but non-hashref value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_hashref_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        HV* possible_hash_arrayref_number;
        integer possible_hash_arrayref_number__num_keys;
        integer j;
        HE* possible_hash_arrayref_number__hashentry;
        SV* possible_hash_arrayref_number__hashentry_value;
        SV* possible_hash_arrayref_number__hashentry_key;
        string possible_hash_arrayref_number__hashentry_key_string;

        possible_hash_arrayref_number = (HV*)SvRV(possible_hashref_arrayref_number);
        possible_hash_arrayref_number__num_keys = hv_iterinit(possible_hash_arrayref_number);

        // incrementing iteration, iterator j not actually used in loop body
        for (j = 0;  j < possible_hash_arrayref_number__num_keys;  ++j) {
            possible_hash_arrayref_number__hashentry = hv_iternext(possible_hash_arrayref_number);

            // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with number-specific error code
            if (possible_hash_arrayref_number__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVNVHE01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_number__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
            possible_hash_arrayref_number__hashentry_value = hv_iterval(possible_hash_arrayref_number, possible_hash_arrayref_number__hashentry);

            // DEV NOTE: the following two if() statements are functionally equivalent to the number_CHECK() macro & subroutine, but with hash-specific error codes
            if (not(SvOK(possible_hash_arrayref_number__hashentry_value))) {
                possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVNV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found at sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }

            if (not(SvAROKp(possible_hash_arrayref_number__hashentry_value))) {
                possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVNV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found at sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }

            SV* possible_arrayref_number = possible_hash_arrayref_number__hashentry_value;

            AV* possible_array_number;
            integer possible_array_number__length;
            integer k;
            SV** possible_array_number__element;

            possible_array_number = (AV*)SvRV(possible_arrayref_number);
            possible_array_number__length = av_len(possible_array_number) + 1;

            // incrementing iteration
            for (k = 0;  k < possible_array_number__length;  ++k) {
                possible_array_number__element = av_fetch(possible_array_number, k, 0);
                if (not(SvOK(*possible_array_number__element))) {
                    possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                    possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                    possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVNV06, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index %"INTEGER", sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", k, possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
                }
                if (not(SvNOKp(*possible_array_number__element) or
                        SvIOKp(*possible_array_number__element))) {
                    possible_hash_hashref_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_number__hashentry);
                    possible_hash_hashref_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_number__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_number__hashentry_key = hv_iterkeysv(possible_hash_arrayref_number__hashentry);
                    possible_hash_arrayref_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_number__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVNV07, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index %"INTEGER", sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", k, possible_hash_arrayref_number__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
                }
            }
        }

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_number_CHECKTRACE(), bottom of subroutine\n");
}

// DEV NOTE, STEPS TO CONVERT FROM number TO string:
// 1.  EAVNV -> EAVPV
// 2.  remove SvIOKp
// 3.  SvNOKp -> SvPOKp
// 4.  number_ -> string_
// 5.  number value -> string value
// x.  number- -> string-

void hashref_hashref_arrayref_string_CHECK(SV* possible_hashref_hashref_arrayref_string) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_string_CHECK(), top of subroutine\n");

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with string-specific error codes
    if ( not( SvOK(possible_hashref_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVHVRVAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_string value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVHVRVAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_string value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_hashref_arrayref_string;
    integer possible_hash_hashref_arrayref_string__num_keys;
    integer i;
    HE* possible_hash_hashref_arrayref_string__hashentry;
    SV* possible_hash_hashref_arrayref_string__hashentry_value;
    SV* possible_hash_hashref_arrayref_string__hashentry_key;
    string possible_hash_hashref_arrayref_string__hashentry_key_string;

    possible_hash_hashref_arrayref_string = (HV*)SvRV(possible_hashref_hashref_arrayref_string);
    possible_hash_hashref_arrayref_string__num_keys = hv_iterinit(possible_hash_hashref_arrayref_string);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_hashref_arrayref_string__num_keys;  ++i) {
        possible_hash_hashref_arrayref_string__hashentry = hv_iternext(possible_hash_hashref_arrayref_string);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with string-specific error code
        if (possible_hash_hashref_arrayref_string__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVPVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_hashref_arrayref_string__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_hashref_arrayref_string__hashentry_value = hv_iterval(possible_hash_hashref_arrayref_string, possible_hash_hashref_arrayref_string__hashentry);

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  naming bridge
        // 2.  HVRVAVRV -> HVRVHVRVAVRV
        // 3.  AVRVHE -> HVRVAVRVHE
        // 4.  increment error code serial numbers by 2 for HVRV codes, by 1 for HE codes
        // 5.  add key info to first 2 pasted error messages
        // 6.  add sub-key info to remaining pasted error messages
        // 7.  j -> k
        // 8.  i -> j
        // 9.  delete pre-existing 1D ARRAY CODE

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* possible_hashref_arrayref_string = possible_hash_hashref_arrayref_string__hashentry_value;

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with string-specific error codes
        if ( not( SvOK(possible_hashref_arrayref_string) ) ) {
            possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
            possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_hashref_arrayref_string__hashentry_key_string.c_str());
        }
        if ( not( SvHROKp(possible_hashref_arrayref_string) ) ) {
            possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
            possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but non-hashref value found at key '%s',\ncroaking", possible_hash_hashref_arrayref_string__hashentry_key_string.c_str());
        }

        HV* possible_hash_arrayref_string;
        integer possible_hash_arrayref_string__num_keys;
        integer j;
        HE* possible_hash_arrayref_string__hashentry;
        SV* possible_hash_arrayref_string__hashentry_value;
        SV* possible_hash_arrayref_string__hashentry_key;
        string possible_hash_arrayref_string__hashentry_key_string;

        possible_hash_arrayref_string = (HV*)SvRV(possible_hashref_arrayref_string);
        possible_hash_arrayref_string__num_keys = hv_iterinit(possible_hash_arrayref_string);

        // incrementing iteration, iterator j not actually used in loop body
        for (j = 0;  j < possible_hash_arrayref_string__num_keys;  ++j) {
            possible_hash_arrayref_string__hashentry = hv_iternext(possible_hash_arrayref_string);

            // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with string-specific error code
            if (possible_hash_arrayref_string__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVPVHE01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_string__hashentry value expected but undefined/null value found,\ncroaking"); }
            possible_hash_arrayref_string__hashentry_value = hv_iterval(possible_hash_arrayref_string, possible_hash_arrayref_string__hashentry);

            // DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECK() macro & subroutine, but with hash-specific error codes
            if (not(SvOK(possible_hash_arrayref_string__hashentry_value))) {
                possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVPV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found at sub-key '%s', key '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str());
            }

            if (not(SvAROKp(possible_hash_arrayref_string__hashentry_value))) {
                possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVPV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found at sub-key '%s', key '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str());
            }

            SV* possible_arrayref_string = possible_hash_arrayref_string__hashentry_value;

            AV* possible_array_string;
            integer possible_array_string__length;
            integer k;
            SV** possible_array_string__element;

            possible_array_string = (AV*)SvRV(possible_arrayref_string);
            possible_array_string__length = av_len(possible_array_string) + 1;

            // incrementing iteration
            for (k = 0;  k < possible_array_string__length;  ++k) {
                possible_array_string__element = av_fetch(possible_array_string, k, 0);
                if (not(SvOK(*possible_array_string__element))) {
                    possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                    possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                    possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVPV06, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index %"INTEGER", sub-key '%s', key '%s',\ncroaking", k, possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str());
                }
                if (not(SvPOKp(*possible_array_string__element))) {
                    possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                    possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                    possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVPV07, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index %"INTEGER", sub-key '%s', key '%s',\ncroaking", k, possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str());
                }
            }
        }

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_string_CHECK(), bottom of subroutine\n");
}

void hashref_hashref_arrayref_string_CHECKTRACE(SV* possible_hashref_hashref_arrayref_string, const char* variable_name, const char* subroutine_name) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_string_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_string_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with string-specific error codes
    if ( not( SvOK(possible_hashref_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVHVRVAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_string value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_hashref_arrayref_string) ) ) { croak( "\nERROR EHVRVHVRVAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_hashref_arrayref_string value expected but non-hashref value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_hashref_arrayref_string;
    integer possible_hash_hashref_arrayref_string__num_keys;
    integer i;
    HE* possible_hash_hashref_arrayref_string__hashentry;
    SV* possible_hash_hashref_arrayref_string__hashentry_value;
    SV* possible_hash_hashref_arrayref_string__hashentry_key;
    string possible_hash_hashref_arrayref_string__hashentry_key_string;

    possible_hash_hashref_arrayref_string = (HV*)SvRV(possible_hashref_hashref_arrayref_string);
    possible_hash_hashref_arrayref_string__num_keys = hv_iterinit(possible_hash_hashref_arrayref_string);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < possible_hash_hashref_arrayref_string__num_keys;  ++i) {
        possible_hash_hashref_arrayref_string__hashentry = hv_iternext(possible_hash_hashref_arrayref_string);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with string-specific error code
        if (possible_hash_hashref_arrayref_string__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVPVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_hashref_arrayref_string__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
        possible_hash_hashref_arrayref_string__hashentry_value = hv_iterval(possible_hash_hashref_arrayref_string, possible_hash_hashref_arrayref_string__hashentry);

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  naming bridge
        // 2.  HVRVAVRV -> HVRVHVRVAVRV
        // 3.  AVRVHE -> HVRVAVRVHE
        // 4.  increment error code serial numbers by 2 for HVRV codes, by 1 for HE codes
        // 5.  add key info to first 2 pasted error messages
        // 6.  add sub-key info to remaining pasted error messages
        // 7.  j -> k
        // 8.  i -> j
        // 9.  delete pre-existing 1D ARRAY CODE

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* possible_hashref_arrayref_string = possible_hash_hashref_arrayref_string__hashentry_value;

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with string-specific error codes
        if ( not( SvOK(possible_hashref_arrayref_string) ) ) {
            possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
            possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but undefined/null value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_hashref_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
        if ( not( SvHROKp(possible_hashref_arrayref_string) ) ) {
            possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
            possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
            croak( "\nERROR EHVRVHVRVAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_arrayref_string value expected but non-hashref value found at key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_hashref_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }

        HV* possible_hash_arrayref_string;
        integer possible_hash_arrayref_string__num_keys;
        integer j;
        HE* possible_hash_arrayref_string__hashentry;
        SV* possible_hash_arrayref_string__hashentry_value;
        SV* possible_hash_arrayref_string__hashentry_key;
        string possible_hash_arrayref_string__hashentry_key_string;

        possible_hash_arrayref_string = (HV*)SvRV(possible_hashref_arrayref_string);
        possible_hash_arrayref_string__num_keys = hv_iterinit(possible_hash_arrayref_string);

        // incrementing iteration, iterator j not actually used in loop body
        for (j = 0;  j < possible_hash_arrayref_string__num_keys;  ++j) {
            possible_hash_arrayref_string__hashentry = hv_iternext(possible_hash_arrayref_string);

            // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with string-specific error code
            if (possible_hash_arrayref_string__hashentry == NULL) { croak("\nERROR EHVRVHVRVAVRVPVHE01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_arrayref_string__hashentry value expected but undefined/null value found,\nin variable '%s' from subroutine '%s',\ncroaking", variable_name, subroutine_name); }
            possible_hash_arrayref_string__hashentry_value = hv_iterval(possible_hash_arrayref_string, possible_hash_arrayref_string__hashentry);

            // DEV NOTE: the following two if() statements are functionally equivalent to the string_CHECK() macro & subroutine, but with hash-specific error codes
            if (not(SvOK(possible_hash_arrayref_string__hashentry_value))) {
                possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVPV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found at sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }

            if (not(SvAROKp(possible_hash_arrayref_string__hashentry_value))) {
                possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                croak("\nERROR EHVRVHVRVAVRVPV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found at sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
            }

            SV* possible_arrayref_string = possible_hash_arrayref_string__hashentry_value;

            AV* possible_array_string;
            integer possible_array_string__length;
            integer k;
            SV** possible_array_string__element;

            possible_array_string = (AV*)SvRV(possible_arrayref_string);
            possible_array_string__length = av_len(possible_array_string) + 1;

            // incrementing iteration
            for (k = 0;  k < possible_array_string__length;  ++k) {
                possible_array_string__element = av_fetch(possible_array_string, k, 0);
                if (not(SvOK(*possible_array_string__element))) {
                    possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                    possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                    possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVPV06, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index %"INTEGER", sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", k, possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
                }
                if (not(SvPOKp(*possible_array_string__element))) {
                    possible_hash_hashref_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_hashref_arrayref_string__hashentry);
                    possible_hash_hashref_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_hashref_arrayref_string__hashentry_key)));  // escape key string for error message
                    possible_hash_arrayref_string__hashentry_key = hv_iterkeysv(possible_hash_arrayref_string__hashentry);
                    possible_hash_arrayref_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_arrayref_string__hashentry_key)));  // escape key string for error message
                    croak("\nERROR EHVRVHVRVAVRVPV07, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index %"INTEGER", sub-key '%s', key '%s',\nin variable '%s' from subroutine '%s',\ncroaking", k, possible_hash_arrayref_string__hashentry_key_string.c_str(), possible_hash_hashref_arrayref_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
                }
            }
        }

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]
    }
//    fprintf(stderr, "in CPPOPS_CPPTYPES hashref_hashref_arrayref_string_CHECKTRACE(), bottom of subroutine\n");
}

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

# ifdef __CPP__TYPES

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs))))))) to (C++ std::unordered_map of (C++ std::unordered_map of (C++ std::vector of integers)))
hashref_hashref_arrayref_integer XS_unpack_hashref_hashref_arrayref_integer(SV* input_hvref_hvref_avref) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), top of subroutine\n");

//    hashref_hashref_arrayref_integer_CHECK(input_hvref_hvref_avref);
    hashref_hashref_arrayref_integer_CHECKTRACE(input_hvref_hvref_avref, "input_hvref_hvref_avref", "XS_unpack_hashref_hashref_arrayref_integer()");

    HV* input_hv_hvref_avref;
    integer input_hv_hvref_avref__num_keys;
    integer i;
    HE* input_hv_hvref_avref__entry;
    SV* input_hv_hvref_avref__entry_key;
    SV* input_hv_hvref_avref__entry_value;
    hashref_hashref_arrayref_integer output_umap_umap_vector;

    input_hv_hvref_avref = (HV*)SvRV(input_hvref_hvref_avref);

    input_hv_hvref_avref__num_keys = hv_iterinit(input_hv_hvref_avref);
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), have input_hv_hvref_avref__num_keys = %"INTEGER"\n", input_hv_hvref_avref__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap_umap_vector.reserve((size_t)input_hv_hvref_avref__num_keys);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_hvref_avref__num_keys;  ++i) {
        // does not utilize i in entry retrieval
        input_hv_hvref_avref__entry = hv_iternext(input_hv_hvref_avref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_hashref_arrayref_integer_CHECKTRACE()
//      hashentry_CHECK(input_hv_hvref_avref__entry);
//      hashentry_CHECKTRACE(input_hv_hvref_avref__entry, "input_hv_hvref_avref__entry", "XS_unpack_hashref_hashref_arrayref_integer()");

        input_hv_hvref_avref__entry_key = hv_iterkeysv(input_hv_hvref_avref__entry);
        input_hv_hvref_avref__entry_value = hv_iterval(input_hv_hvref_avref, input_hv_hvref_avref__entry);
        // DEV NOTE: integer type-checking already done as part of hashref_hashref_arrayref_integer_CHECKTRACE()
//      integer_CHECK(input_hv_hvref_avref__entry_value);
//      integer_CHECKTRACE(input_hv_hvref_avref__entry_value, (char*)((string)"input_hv_hvref_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_hvref_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_hashref_arrayref_integer()");

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  delete pre-existing 1D ARRAY CODE
        // 2.  naming bridge
        // 3.  XS_unpack_hashref_arrayref_TYPE -> XS_unpack_hashref_hashref_arrayref_TYPE
        // 4.  UNORDERED MAP ENTRY ASSIGNMENT under pasted 2D code, output_vector -> output_umap_vector
        // 5.  j -> k
        // 6.  i -> j

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* input_hvref_avref = input_hv_hvref_avref__entry_value;

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        //    hashref_arrayref_integer_CHECK(input_hvref_avref);
            hashref_arrayref_integer_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "XS_unpack_hashref_hashref_arrayref_integer()");

            HV* input_hv_avref;
            integer input_hv_avref__num_keys;
            integer j;
            HE* input_hv_avref__entry;
            SV* input_hv_avref__entry_key;
            SV* input_hv_avref__entry_value;
            hashref_arrayref_integer output_umap_vector;

            input_hv_avref = (HV*)SvRV(input_hvref_avref);

            input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

            // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
            // reserve() ahead of time to avoid resizing and rehashing in for() loop
            output_umap_vector.reserve((size_t)input_hv_avref__num_keys);

            // incrementing iteration, iterator i not actually used in loop body
            for (j = 0;  j < input_hv_avref__num_keys;  ++j) {
                // does not utilize j in entry retrieval
                input_hv_avref__entry = hv_iternext(input_hv_avref);
                // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
        //      hashentry_CHECK(input_hv_avref__entry);
        //      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "XS_unpack_hashref_hashref_arrayref_integer()");

                input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
                input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);
                // DEV NOTE: integer type-checking already done as part of hashref_arrayref_integer_CHECKTRACE()
        //      integer_CHECK(input_hv_avref__entry_value);
        //      integer_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_hashref_arrayref_integer()");

                // [[[ BEGIN PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                AV* input_av;
                integer input_av__length;
                integer k;
                SV** input_av__element;
                arrayref_integer output_vector;

        //      input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_hv_avref__entry_value
        //        input_av = (AV*)SvRV(*input_hv_avref__entry_value);  // error: base operand of ‘->’ has non-pointer type ‘SV {aka sv}’, in expansion of macro ‘SvRV’
                input_av = (AV*)SvRV(input_hv_avref__entry_value);
                input_av__length = av_len(input_av) + 1;
        //        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), have input_av__length = %"INTEGER"\n", input_av__length);

                // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
                // resize() ahead of time to allow l-value subscript notation
                output_vector.resize((size_t)input_av__length);

                // incrementing iteration
                for (k = 0;  k < input_av__length;  ++k) {
                    // utilizes k in element retrieval
                    input_av__element = av_fetch(input_av, k, 0);

                    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes k in assignment
                    output_vector[k] = SvIV(*input_av__element);
                }

        //        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), bottom of inner for() loop k = %"INTEGER", have output_vector.size() = %"INTEGER"\n", k, (integer) output_vector.size());

                // [[[ END PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize j in assignment
                output_umap_vector[SvPV_nolen(input_hv_avref__entry_key)] = output_vector;
            }

        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), after outer for() loop, have output_umap_vector.size() = %"INTEGER"\n", output_umap_vector.size());

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap_umap_vector[SvPV_nolen(input_hv_hvref_avref__entry_key)] = output_umap_vector;
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), after outer for() loop, have output_umap_umap_vector.size() = %"INTEGER"\n", output_umap_umap_vector.size());
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_integer(), bottom of subroutine\n");

    return(output_umap_umap_vector);
}

// convert from (C++ std::unordered_map of (C++ std::unordered_map of (C++ std::vector of integers))) to (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs)))))))
void XS_pack_hashref_hashref_arrayref_integer(SV* output_hvref_hvref_avref, hashref_hashref_arrayref_integer input_umap_umap_vector) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), top of subroutine\n");

    HV* output_hv_hvref_avref = newHV();  // initialize output hash-of-hashes-of-arrays to empty
    integer input_umap_umap_vector__num_keys = input_umap_umap_vector.size();
    hashref_hashref_arrayref_integer_const_iterator i;
    SV* temp_sv_pointer;

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), have input_umap_umap_vector__num_keys = %"INTEGER"\n", input_umap_umap_vector__num_keys);

    if (input_umap_umap_vector__num_keys > 0) {
        for (i = input_umap_umap_vector.begin();  i != input_umap_umap_vector.end();  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), top of outer loop, have i->first AKA key = '%s'\n", (i->first).c_str());
            hashref_arrayref_integer input_umap_vector = i->second;

            // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
            // 1.  delete pre-existing 1D ARRAY CODE
            // 2.  no naming bridge required
            // 3.  XS_unpack_hashref_arrayref_TYPE -> XS_unpack_hashref_hashref_arrayref_TYPE
            // 4.  hv_store under pasted 2D code, output_av -> output_hv_avref
            // 5.  j -> k
            // 6.  i -> j

            // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

            // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

            HV* output_hv_avref = newHV();  // initialize output hash-of-arrays to empty
            integer input_umap_vector__num_keys = input_umap_vector.size();
            hashref_arrayref_integer_const_iterator j;
            SV* temp_sv_pointer;

        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), have input_umap_vector__num_keys = %"INTEGER"\n", input_umap_vector__num_keys);

            if (input_umap_vector__num_keys > 0) {
                for (j = input_umap_vector.begin();  j != input_umap_vector.end();  ++j) {
        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), top of outer loop, have j->first AKA key = '%s'\n", (j->first).c_str());
                    arrayref_integer input_vector = j->second;

                    // [[[ BEGIN PASTED-AND-CONVERTED 1D ARRAY CODE ]]]
                    AV* output_av = newAV();  // initialize output sub-array to empty
                    integer input_vector__length = input_vector.size();
                    integer k;

        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), have input_vector__length = %"INTEGER"\n", input_vector__length);

                    if (input_vector__length > 0) {
                        for (k = 0;  k < input_vector__length;  ++k) {
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), top of inner loop, have (j->first, k) = ('%s', %"INTEGER")\n", (j->first).c_str(), k);
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), have input_umap_vector['%s'][%"INTEGER"] = %"INTEGER"\n", (j->first).c_str(), k, input_vector[k]);
                            av_push(output_av, newSViv(input_vector[k]));
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), bottom of inner loop, have (j->first, k) = ('%s', %"INTEGER")\n", (j->first).c_str(), k);
                        }
                    }
                    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), sub-array was empty, returning empty sub-array via newAV()");
                    // [[[ END PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                    // NEED ANSWER: is it really okay to NOT increase the reference count below???
                    hv_store(output_hv_avref, (const char*)((j->first).c_str()), (U32)((j->first).size()), newRV_noinc((SV*)output_av), (U32)0);  // reference, do not increase reference count
        //            hv_store(output_hv_avref, (const char*)((j->first).c_str()), (U32)((j->first).size()), newRV_inc((SV*)output_av), (U32)0);  // reference, do increase reference count

        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), bottom of outer loop, have j->first = '%s'\n", (j->first).c_str());
                }
            }
            else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), hash was empty, returning empty hash via newHV()");

            // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]

            // NEED ANSWER: is it really okay to NOT increase the reference count below???
            hv_store(output_hv_hvref_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_noinc((SV*)output_hv_avref), (U32)0);  // reference, do not increase reference count
//            hv_store(output_hv_hvref_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_inc((SV*)output_hv_avref), (U32)0);  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), bottom of outer loop, have i->first = '%s'\n", (i->first).c_str());
        }
    }
    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref_hvref_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref_hvref_avref) = (SV*)output_hv_hvref_avref;       // make output stack RV point at our output HV

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_integer(), bottom of subroutine\n");
}

// DEV NOTE, STEPS TO CONVERT FROM integer TO number:
// 1.  IV -> NV
// 2.  SViv -> SVnv
// 3.  integers -> numbers
// 4.  _integer -> _number

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs))))))) to (C++ std::unordered_map of (C++ std::unordered_map of (C++ std::vector of numbers)))
hashref_hashref_arrayref_number XS_unpack_hashref_hashref_arrayref_number(SV* input_hvref_hvref_avref) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), top of subroutine\n");

//    hashref_hashref_arrayref_number_CHECK(input_hvref_hvref_avref);
    hashref_hashref_arrayref_number_CHECKTRACE(input_hvref_hvref_avref, "input_hvref_hvref_avref", "XS_unpack_hashref_hashref_arrayref_number()");

    HV* input_hv_hvref_avref;
    integer input_hv_hvref_avref__num_keys;
    integer i;
    HE* input_hv_hvref_avref__entry;
    SV* input_hv_hvref_avref__entry_key;
    SV* input_hv_hvref_avref__entry_value;
    hashref_hashref_arrayref_number output_umap_umap_vector;

    input_hv_hvref_avref = (HV*)SvRV(input_hvref_hvref_avref);

    input_hv_hvref_avref__num_keys = hv_iterinit(input_hv_hvref_avref);
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), have input_hv_hvref_avref__num_keys = %"INTEGER"\n", input_hv_hvref_avref__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap_umap_vector.reserve((size_t)input_hv_hvref_avref__num_keys);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_hvref_avref__num_keys;  ++i) {
        // does not utilize i in entry retrieval
        input_hv_hvref_avref__entry = hv_iternext(input_hv_hvref_avref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_hashref_arrayref_number_CHECKTRACE()
//      hashentry_CHECK(input_hv_hvref_avref__entry);
//      hashentry_CHECKTRACE(input_hv_hvref_avref__entry, "input_hv_hvref_avref__entry", "XS_unpack_hashref_hashref_arrayref_number()");

        input_hv_hvref_avref__entry_key = hv_iterkeysv(input_hv_hvref_avref__entry);
        input_hv_hvref_avref__entry_value = hv_iterval(input_hv_hvref_avref, input_hv_hvref_avref__entry);
        // DEV NOTE: integer type-checking already done as part of hashref_hashref_arrayref_number_CHECKTRACE()
//      number_CHECK(input_hv_hvref_avref__entry_value);
//      number_CHECKTRACE(input_hv_hvref_avref__entry_value, (char*)((string)"input_hv_hvref_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_hvref_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_hashref_arrayref_number()");

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  delete pre-existing 1D ARRAY CODE
        // 2.  naming bridge
        // 3.  XS_unpack_hashref_arrayref_TYPE -> XS_unpack_hashref_hashref_arrayref_TYPE
        // 4.  UNORDERED MAP ENTRY ASSIGNMENT under pasted 2D code, output_vector -> output_umap_vector
        // 5.  j -> k
        // 6.  i -> j

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* input_hvref_avref = input_hv_hvref_avref__entry_value;

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        //    hashref_arrayref_number_CHECK(input_hvref_avref);
            hashref_arrayref_number_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "XS_unpack_hashref_hashref_arrayref_number()");

            HV* input_hv_avref;
            integer input_hv_avref__num_keys;
            integer j;
            HE* input_hv_avref__entry;
            SV* input_hv_avref__entry_key;
            SV* input_hv_avref__entry_value;
            hashref_arrayref_number output_umap_vector;

            input_hv_avref = (HV*)SvRV(input_hvref_avref);

            input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

            // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
            // reserve() ahead of time to avoid resizing and rehashing in for() loop
            output_umap_vector.reserve((size_t)input_hv_avref__num_keys);

            // incrementing iteration, iterator i not actually used in loop body
            for (j = 0;  j < input_hv_avref__num_keys;  ++j) {
                // does not utilize j in entry retrieval
                input_hv_avref__entry = hv_iternext(input_hv_avref);
                // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
        //      hashentry_CHECK(input_hv_avref__entry);
        //      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "XS_unpack_hashref_hashref_arrayref_number()");

                input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
                input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);
                // DEV NOTE: integer type-checking already done as part of hashref_arrayref_number_CHECKTRACE()
        //      number_CHECK(input_hv_avref__entry_value);
        //      number_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_hashref_arrayref_number()");

                // [[[ BEGIN PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                AV* input_av;
                integer input_av__length;
                integer k;
                SV** input_av__element;
                arrayref_number output_vector;

        //      input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_hv_avref__entry_value
        //        input_av = (AV*)SvRV(*input_hv_avref__entry_value);  // error: base operand of ‘->’ has non-pointer type ‘SV {aka sv}’, in expansion of macro ‘SvRV’
                input_av = (AV*)SvRV(input_hv_avref__entry_value);
                input_av__length = av_len(input_av) + 1;
        //        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), have input_av__length = %"INTEGER"\n", input_av__length);

                // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
                // resize() ahead of time to allow l-value subscript notation
                output_vector.resize((size_t)input_av__length);

                // incrementing iteration
                for (k = 0;  k < input_av__length;  ++k) {
                    // utilizes k in element retrieval
                    input_av__element = av_fetch(input_av, k, 0);

                    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes k in assignment
                    output_vector[k] = SvNV(*input_av__element);
                }

        //        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), bottom of inner for() loop k = %"INTEGER", have output_vector.size() = %"INTEGER"\n", k, (integer) output_vector.size());

                // [[[ END PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize j in assignment
                output_umap_vector[SvPV_nolen(input_hv_avref__entry_key)] = output_vector;
            }

        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), after outer for() loop, have output_umap_vector.size() = %"INTEGER"\n", output_umap_vector.size());

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap_umap_vector[SvPV_nolen(input_hv_hvref_avref__entry_key)] = output_umap_vector;
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), after outer for() loop, have output_umap_umap_vector.size() = %"INTEGER"\n", output_umap_umap_vector.size());
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_number(), bottom of subroutine\n");

    return(output_umap_umap_vector);
}

// convert from (C++ std::unordered_map of (C++ std::unordered_map of (C++ std::vector of numbers))) to (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs)))))))
void XS_pack_hashref_hashref_arrayref_number(SV* output_hvref_hvref_avref, hashref_hashref_arrayref_number input_umap_umap_vector) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), top of subroutine\n");

    HV* output_hv_hvref_avref = newHV();  // initialize output hash-of-hashes-of-arrays to empty
    integer input_umap_umap_vector__num_keys = input_umap_umap_vector.size();
    hashref_hashref_arrayref_number_const_iterator i;
    SV* temp_sv_pointer;

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), have input_umap_umap_vector__num_keys = %"INTEGER"\n", input_umap_umap_vector__num_keys);

    if (input_umap_umap_vector__num_keys > 0) {
        for (i = input_umap_umap_vector.begin();  i != input_umap_umap_vector.end();  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), top of outer loop, have i->first AKA key = '%s'\n", (i->first).c_str());
            hashref_arrayref_number input_umap_vector = i->second;

            // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
            // 1.  delete pre-existing 1D ARRAY CODE
            // 2.  no naming bridge required
            // 3.  XS_unpack_hashref_arrayref_TYPE -> XS_unpack_hashref_hashref_arrayref_TYPE
            // 4.  hv_store under pasted 2D code, output_av -> output_hv_avref
            // 5.  j -> k
            // 6.  i -> j

            // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

            // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

            HV* output_hv_avref = newHV();  // initialize output hash-of-arrays to empty
            integer input_umap_vector__num_keys = input_umap_vector.size();
            hashref_arrayref_number_const_iterator j;
            SV* temp_sv_pointer;

        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), have input_umap_vector__num_keys = %"INTEGER"\n", input_umap_vector__num_keys);

            if (input_umap_vector__num_keys > 0) {
                for (j = input_umap_vector.begin();  j != input_umap_vector.end();  ++j) {
        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), top of outer loop, have j->first AKA key = '%s'\n", (j->first).c_str());
                    arrayref_number input_vector = j->second;

                    // [[[ BEGIN PASTED-AND-CONVERTED 1D ARRAY CODE ]]]
                    AV* output_av = newAV();  // initialize output sub-array to empty
                    integer input_vector__length = input_vector.size();
                    integer k;

        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), have input_vector__length = %"INTEGER"\n", input_vector__length);

                    if (input_vector__length > 0) {
                        for (k = 0;  k < input_vector__length;  ++k) {
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), top of inner loop, have (j->first, k) = ('%s', %"INTEGER")\n", (j->first).c_str(), k);
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), have input_umap_vector['%s'][%"INTEGER"] = %"INTEGER"\n", (j->first).c_str(), k, input_vector[k]);
                            av_push(output_av, newSVnv(input_vector[k]));
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), bottom of inner loop, have (j->first, k) = ('%s', %"INTEGER")\n", (j->first).c_str(), k);
                        }
                    }
                    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), sub-array was empty, returning empty sub-array via newAV()");
                    // [[[ END PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                    // NEED ANSWER: is it really okay to NOT increase the reference count below???
                    hv_store(output_hv_avref, (const char*)((j->first).c_str()), (U32)((j->first).size()), newRV_noinc((SV*)output_av), (U32)0);  // reference, do not increase reference count
        //            hv_store(output_hv_avref, (const char*)((j->first).c_str()), (U32)((j->first).size()), newRV_inc((SV*)output_av), (U32)0);  // reference, do increase reference count

        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), bottom of outer loop, have j->first = '%s'\n", (j->first).c_str());
                }
            }
            else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), hash was empty, returning empty hash via newHV()");

            // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]

            // NEED ANSWER: is it really okay to NOT increase the reference count below???
            hv_store(output_hv_hvref_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_noinc((SV*)output_hv_avref), (U32)0);  // reference, do not increase reference count
//            hv_store(output_hv_hvref_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_inc((SV*)output_hv_avref), (U32)0);  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), bottom of outer loop, have i->first = '%s'\n", (i->first).c_str());
        }
    }
    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref_hvref_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref_hvref_avref) = (SV*)output_hv_hvref_avref;       // make output stack RV point at our output HV

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_number(), bottom of subroutine\n");
}

// DEV NOTE, STEPS TO CONVERT FROM number TO string:
// 1.  NVs -> PVs
// 2.  SvNV -> SvPV_nolen
// 3.  newSVnv(FOO) -> newSVpv(FOO.c_str(), 0)
// 4.  numbers -> strings
// 5.  _number -> _string

// convert from (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs))))))) to (C++ std::unordered_map of (C++ std::unordered_map of (C++ std::vector of strings)))
hashref_hashref_arrayref_string XS_unpack_hashref_hashref_arrayref_string(SV* input_hvref_hvref_avref) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), top of subroutine\n");

//    hashref_hashref_arrayref_string_CHECK(input_hvref_hvref_avref);
    hashref_hashref_arrayref_string_CHECKTRACE(input_hvref_hvref_avref, "input_hvref_hvref_avref", "XS_unpack_hashref_hashref_arrayref_string()");

    HV* input_hv_hvref_avref;
    integer input_hv_hvref_avref__num_keys;
    integer i;
    HE* input_hv_hvref_avref__entry;
    SV* input_hv_hvref_avref__entry_key;
    SV* input_hv_hvref_avref__entry_value;
    hashref_hashref_arrayref_string output_umap_umap_vector;

    input_hv_hvref_avref = (HV*)SvRV(input_hvref_hvref_avref);

    input_hv_hvref_avref__num_keys = hv_iterinit(input_hv_hvref_avref);
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), have input_hv_hvref_avref__num_keys = %"INTEGER"\n", input_hv_hvref_avref__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap_umap_vector.reserve((size_t)input_hv_hvref_avref__num_keys);

    // incrementing iteration, iterator i not actually used in loop body
    for (i = 0;  i < input_hv_hvref_avref__num_keys;  ++i) {
        // does not utilize i in entry retrieval
        input_hv_hvref_avref__entry = hv_iternext(input_hv_hvref_avref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_hashref_arrayref_string_CHECKTRACE()
//      hashentry_CHECK(input_hv_hvref_avref__entry);
//      hashentry_CHECKTRACE(input_hv_hvref_avref__entry, "input_hv_hvref_avref__entry", "XS_unpack_hashref_hashref_arrayref_string()");

        input_hv_hvref_avref__entry_key = hv_iterkeysv(input_hv_hvref_avref__entry);
        input_hv_hvref_avref__entry_value = hv_iterval(input_hv_hvref_avref, input_hv_hvref_avref__entry);
        // DEV NOTE: integer type-checking already done as part of hashref_hashref_arrayref_string_CHECKTRACE()
//      string_CHECK(input_hv_hvref_avref__entry_value);
//      string_CHECKTRACE(input_hv_hvref_avref__entry_value, (char*)((string)"input_hv_hvref_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_hvref_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_hashref_arrayref_string()");

        // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
        // 1.  delete pre-existing 1D ARRAY CODE
        // 2.  naming bridge
        // 3.  XS_unpack_hashref_arrayref_TYPE -> XS_unpack_hashref_hashref_arrayref_TYPE
        // 4.  UNORDERED MAP ENTRY ASSIGNMENT under pasted 2D code, output_vector -> output_umap_vector
        // 5.  j -> k
        // 6.  i -> j

        // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

        // DEV NOTE: naming bridge between 3D code and pasted 2D code
        SV* input_hvref_avref = input_hv_hvref_avref__entry_value;

        // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

        //    hashref_arrayref_string_CHECK(input_hvref_avref);
            hashref_arrayref_string_CHECKTRACE(input_hvref_avref, "input_hvref_avref", "XS_unpack_hashref_hashref_arrayref_string()");

            HV* input_hv_avref;
            integer input_hv_avref__num_keys;
            integer j;
            HE* input_hv_avref__entry;
            SV* input_hv_avref__entry_key;
            SV* input_hv_avref__entry_value;
            hashref_arrayref_string output_umap_vector;

            input_hv_avref = (HV*)SvRV(input_hvref_avref);

            input_hv_avref__num_keys = hv_iterinit(input_hv_avref);
        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), have input_hv_avref__num_keys = %"INTEGER"\n", input_hv_avref__num_keys);

            // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: unordered_map has programmer-provided const size or compiler-guessable size,
            // reserve() ahead of time to avoid resizing and rehashing in for() loop
            output_umap_vector.reserve((size_t)input_hv_avref__num_keys);

            // incrementing iteration, iterator i not actually used in loop body
            for (j = 0;  j < input_hv_avref__num_keys;  ++j) {
                // does not utilize j in entry retrieval
                input_hv_avref__entry = hv_iternext(input_hv_avref);
                // DEV NOTE: hash entry type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
        //      hashentry_CHECK(input_hv_avref__entry);
        //      hashentry_CHECKTRACE(input_hv_avref__entry, "input_hv_avref__entry", "XS_unpack_hashref_hashref_arrayref_string()");

                input_hv_avref__entry_key = hv_iterkeysv(input_hv_avref__entry);
                input_hv_avref__entry_value = hv_iterval(input_hv_avref, input_hv_avref__entry);
                // DEV NOTE: integer type-checking already done as part of hashref_arrayref_string_CHECKTRACE()
        //      string_CHECK(input_hv_avref__entry_value);
        //      string_CHECKTRACE(input_hv_avref__entry_value, (char*)((string)"input_hv_avref__entry_value at key '" + (string)SvPV_nolen(input_hv_avref__entry_key) + "'").c_str(), "XS_unpack_hashref_hashref_arrayref_string()");

                // [[[ BEGIN PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                AV* input_av;
                integer input_av__length;
                integer k;
                SV** input_av__element;
                arrayref_string output_vector;

        //      input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_hv_avref__entry_value
        //        input_av = (AV*)SvRV(*input_hv_avref__entry_value);  // error: base operand of ‘->’ has non-pointer type ‘SV {aka sv}’, in expansion of macro ‘SvRV’
                input_av = (AV*)SvRV(input_hv_avref__entry_value);
                input_av__length = av_len(input_av) + 1;
        //        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), have input_av__length = %"INTEGER"\n", input_av__length);

                // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
                // resize() ahead of time to allow l-value subscript notation
                output_vector.resize((size_t)input_av__length);

                // incrementing iteration
                for (k = 0;  k < input_av__length;  ++k) {
                    // utilizes k in element retrieval
                    input_av__element = av_fetch(input_av, k, 0);

                    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes k in assignment
                    output_vector[k] = SvPV_nolen(*input_av__element);
                }

        //        fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), bottom of inner for() loop k = %"INTEGER", have output_vector.size() = %"INTEGER"\n", k, (integer) output_vector.size());

                // [[[ END PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize j in assignment
                output_umap_vector[SvPV_nolen(input_hv_avref__entry_key)] = output_vector;
            }

        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), after outer for() loop, have output_umap_vector.size() = %"INTEGER"\n", output_umap_vector.size());

        // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap_umap_vector[SvPV_nolen(input_hv_hvref_avref__entry_key)] = output_umap_vector;
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), after outer for() loop, have output_umap_umap_vector.size() = %"INTEGER"\n", output_umap_umap_vector.size());
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_hashref_arrayref_string(), bottom of subroutine\n");

    return(output_umap_umap_vector);
}

// convert from (C++ std::unordered_map of (C++ std::unordered_map of (C++ std::vector of strings))) to (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl HV of (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs)))))))
void XS_pack_hashref_hashref_arrayref_string(SV* output_hvref_hvref_avref, hashref_hashref_arrayref_string input_umap_umap_vector) {
//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), top of subroutine\n");

    HV* output_hv_hvref_avref = newHV();  // initialize output hash-of-hashes-of-arrays to empty
    integer input_umap_umap_vector__num_keys = input_umap_umap_vector.size();
    hashref_hashref_arrayref_string_const_iterator i;
    SV* temp_sv_pointer;

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), have input_umap_umap_vector__num_keys = %"INTEGER"\n", input_umap_umap_vector__num_keys);

    if (input_umap_umap_vector__num_keys > 0) {
        for (i = input_umap_umap_vector.begin();  i != input_umap_umap_vector.end();  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), top of outer loop, have i->first AKA key = '%s'\n", (i->first).c_str());
            hashref_arrayref_string input_umap_vector = i->second;

            // DEV NOTE, STEPS TO CONVERT PASTED 2D CODE:
            // 1.  delete pre-existing 1D ARRAY CODE
            // 2.  no naming bridge required
            // 3.  XS_unpack_hashref_arrayref_TYPE -> XS_unpack_hashref_hashref_arrayref_TYPE
            // 4.  hv_store under pasted 2D code, output_av -> output_hv_avref
            // 5.  j -> k
            // 6.  i -> j

            // [[[ DELETED ORIGINAL PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

            // [[[ BEGIN PASTED-AND-CONVERTED 2D CODE ]]]

            HV* output_hv_avref = newHV();  // initialize output hash-of-arrays to empty
            integer input_umap_vector__num_keys = input_umap_vector.size();
            hashref_arrayref_string_const_iterator j;
            SV* temp_sv_pointer;

        //    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), have input_umap_vector__num_keys = %"INTEGER"\n", input_umap_vector__num_keys);

            if (input_umap_vector__num_keys > 0) {
                for (j = input_umap_vector.begin();  j != input_umap_vector.end();  ++j) {
        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), top of outer loop, have j->first AKA key = '%s'\n", (j->first).c_str());
                    arrayref_string input_vector = j->second;

                    // [[[ BEGIN PASTED-AND-CONVERTED 1D ARRAY CODE ]]]
                    AV* output_av = newAV();  // initialize output sub-array to empty
                    integer input_vector__length = input_vector.size();
                    integer k;

        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), have input_vector__length = %"INTEGER"\n", input_vector__length);

                    if (input_vector__length > 0) {
                        for (k = 0;  k < input_vector__length;  ++k) {
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), top of inner loop, have (j->first, k) = ('%s', %"INTEGER")\n", (j->first).c_str(), k);
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), have input_umap_vector['%s'][%"INTEGER"] = %"INTEGER"\n", (j->first).c_str(), k, input_vector[k]);
                            av_push(output_av, newSVpv(input_vector[k].c_str(), 0));
        //                    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), bottom of inner loop, have (j->first, k) = ('%s', %"INTEGER")\n", (j->first).c_str(), k);
                        }
                    }
                    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), sub-array was empty, returning empty sub-array via newAV()");
                    // [[[ END PASTED-AND-CONVERTED 1D ARRAY CODE ]]]

                    // NEED ANSWER: is it really okay to NOT increase the reference count below???
                    hv_store(output_hv_avref, (const char*)((j->first).c_str()), (U32)((j->first).size()), newRV_noinc((SV*)output_av), (U32)0);  // reference, do not increase reference count
        //            hv_store(output_hv_avref, (const char*)((j->first).c_str()), (U32)((j->first).size()), newRV_inc((SV*)output_av), (U32)0);  // reference, do increase reference count

        //            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), bottom of outer loop, have j->first = '%s'\n", (j->first).c_str());
                }
            }
            else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), hash was empty, returning empty hash via newHV()");

            // [[[ END PASTED-AND-CONVERTED 2D CODE ]]]

            // NEED ANSWER: is it really okay to NOT increase the reference count below???
            hv_store(output_hv_hvref_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_noinc((SV*)output_hv_avref), (U32)0);  // reference, do not increase reference count
//            hv_store(output_hv_hvref_avref, (const char*)((i->first).c_str()), (U32)((i->first).size()), newRV_inc((SV*)output_hv_avref), (U32)0);  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), bottom of outer loop, have i->first = '%s'\n", (i->first).c_str());
        }
    }
    else warn("in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref_hvref_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref_hvref_avref) = (SV*)output_hv_hvref_avref;       // make output stack RV point at our output HV

//    fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_hashref_arrayref_string(), bottom of subroutine\n");
}

# endif

#endif
