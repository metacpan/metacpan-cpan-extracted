using std::cout;  using std::cerr;  using std::endl;  using std::to_string;

#ifndef __CPP__INCLUDED__Perl__Structure__Hash__SubTypes1D_cpp
#define __CPP__INCLUDED__Perl__Structure__Hash__SubTypes1D_cpp 0.008_000

#include <Perl/Structure/Hash/SubTypes1D.h>  // -> ??? (relies on <unordered_map> being included via Inline::CPP's AUTO_INCLUDE config option in RPerl/Inline.pm)

// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]

// DEV NOTE: for() loops are statements not expressions, so they can't be embedded in ternary operators, and thus this type-checking must be done with subroutines instead of macros
void hashref_integer_CHECK(SV* possible_hashref_integer)
{
    // DEV NOTE: the following two if() statements are functionally equivalent to the hashref_CHECK() macro, but with integer-specific error codes
    if ( not( SvOK(possible_hashref_integer) ) ) { croak( "\nERROR EHVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_integer value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_integer) ) ) { croak( "\nERROR EHVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_integer value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_integer;
    integer possible_hash_integer__num_keys;
    integer i;
    HE* possible_hash_integer__hashentry;
    SV* possible_hash_integer__hashentry_value;
    SV* possible_hash_integer__hashentry_key;
    string possible_hash_integer__hashentry_key_string;

    possible_hash_integer = (HV*)SvRV(possible_hashref_integer);
    possible_hash_integer__num_keys = hv_iterinit(possible_hash_integer);

    for (i = 0;  i < possible_hash_integer__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        possible_hash_integer__hashentry = hv_iternext(possible_hash_integer);

        // DEV NOTE: the following if() statement is functionally equivalent to the hashentry_CHECK() macro, but with integer-specific error code
        if (possible_hash_integer__hashentry == NULL) { croak("\nERROR EIVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_integer__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_integer__hashentry_value = hv_iterval(possible_hash_integer, possible_hash_integer__hashentry);

        // DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() macro & subroutine, but with hash-specific error codes
        if (not(SvOK(possible_hash_integer__hashentry_value)))
        {
            possible_hash_integer__hashentry_key = hv_iterkeysv(possible_hash_integer__hashentry);
            possible_hash_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_integer__hashentry_key_string.c_str());
        }
        if (not(SvIOKp(possible_hash_integer__hashentry_value)))
        {
            possible_hash_integer__hashentry_key = hv_iterkeysv(possible_hash_integer__hashentry);
            possible_hash_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at key '%s',\ncroaking", possible_hash_integer__hashentry_key_string.c_str());
        }
    }
}

void hashref_integer_CHECKTRACE(SV* possible_hashref_integer, const char* variable_name, const char* subroutine_name)
{
    if ( not( SvOK(possible_hashref_integer) ) ) { croak( "\nERROR EHVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_integer value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_integer) ) ) { croak( "\nERROR EHVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_integer value expected but non-hashref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_integer;
    integer possible_hash_integer__num_keys;
    integer i;
    HE* possible_hash_integer__hashentry;
    SV* possible_hash_integer__hashentry_value;
    SV* possible_hash_integer__hashentry_key;
    string possible_hash_integer__hashentry_key_string;

    possible_hash_integer = (HV*)SvRV(possible_hashref_integer);
    possible_hash_integer__num_keys = hv_iterinit(possible_hash_integer);

    for (i = 0;  i < possible_hash_integer__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        possible_hash_integer__hashentry = hv_iternext(possible_hash_integer);

        if (possible_hash_integer__hashentry == NULL) { croak("\nERROR EIVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_integer__hashentry value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name); }
        possible_hash_integer__hashentry_value = hv_iterval(possible_hash_integer, possible_hash_integer__hashentry);

        if (not(SvOK(possible_hash_integer__hashentry_value)))
        {
            possible_hash_integer__hashentry_key = hv_iterkeysv(possible_hash_integer__hashentry);
            possible_hash_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at key '%s',\nin variable %s from subroutine %s,\ncroaking", possible_hash_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
        if (not(SvIOKp(possible_hash_integer__hashentry_value)))
        {
            possible_hash_integer__hashentry_key = hv_iterkeysv(possible_hash_integer__hashentry);
            possible_hash_integer__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_integer__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at key '%s',\nin variable %s from subroutine %s,\ncroaking", possible_hash_integer__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
    }
}

void hashref_number_CHECK(SV* possible_hashref_number)
{
    if ( not( SvOK(possible_hashref_number) ) ) { croak( "\nERROR EHVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_number value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_number) ) ) { croak( "\nERROR EHVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_number value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_number;
    integer possible_hash_number__num_keys;
    integer i;
    HE* possible_hash_number__hashentry;
    SV* possible_hash_number__hashentry_value;
    SV* possible_hash_number__hashentry_key;
    string possible_hash_number__hashentry_key_string;

    possible_hash_number = (HV*)SvRV(possible_hashref_number);
    possible_hash_number__num_keys = hv_iterinit(possible_hash_number);

    for (i = 0;  i < possible_hash_number__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        possible_hash_number__hashentry = hv_iternext(possible_hash_number);

        if (possible_hash_number__hashentry == NULL) { croak("\nERROR ENVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_number__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_number__hashentry_value = hv_iterval(possible_hash_number, possible_hash_number__hashentry);

        if (not(SvOK(possible_hash_number__hashentry_value)))
        {
            possible_hash_number__hashentry_key = hv_iterkeysv(possible_hash_number__hashentry);
            possible_hash_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_number__hashentry_key_string.c_str());
        }
        if (not(SvNOKp(possible_hash_number__hashentry_value) || SvIOKp(possible_hash_number__hashentry_value)))
        {
            possible_hash_number__hashentry_key = hv_iterkeysv(possible_hash_number__hashentry);
            possible_hash_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at key '%s',\ncroaking", possible_hash_number__hashentry_key_string.c_str());
        }
    }
}

void hashref_number_CHECKTRACE(SV* possible_hashref_number, const char* variable_name, const char* subroutine_name)
{
    if ( not( SvOK(possible_hashref_number) ) ) { croak( "\nERROR EHVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_number value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_number) ) ) { croak( "\nERROR EHVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_number value expected but non-hashref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_number;
    integer possible_hash_number__num_keys;
    integer i;
    HE* possible_hash_number__hashentry;
    SV* possible_hash_number__hashentry_value;
    SV* possible_hash_number__hashentry_key;
    string possible_hash_number__hashentry_key_string;

    possible_hash_number = (HV*)SvRV(possible_hashref_number);
    possible_hash_number__num_keys = hv_iterinit(possible_hash_number);

    for (i = 0;  i < possible_hash_number__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        possible_hash_number__hashentry = hv_iternext(possible_hash_number);

        if (possible_hash_number__hashentry == NULL) { croak("\nERROR ENVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_number__hashentry value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name); }
        possible_hash_number__hashentry_value = hv_iterval(possible_hash_number, possible_hash_number__hashentry);

        if (not(SvOK(possible_hash_number__hashentry_value)))
        {
            possible_hash_number__hashentry_key = hv_iterkeysv(possible_hash_number__hashentry);
            possible_hash_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at key '%s',\nin variable %s from subroutine %s,\ncroaking", possible_hash_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
        if (not(SvNOKp(possible_hash_number__hashentry_value) || SvIOKp(possible_hash_number__hashentry_value)))
        {
            possible_hash_number__hashentry_key = hv_iterkeysv(possible_hash_number__hashentry);
            possible_hash_number__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_number__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at key '%s',\nin variable %s from subroutine %s,\ncroaking", possible_hash_number__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
    }
}

void hashref_string_CHECK(SV* possible_hashref_string)
{
    if ( not( SvOK(possible_hashref_string) ) ) { croak( "\nERROR EHVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_string value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvHROKp(possible_hashref_string) ) ) { croak( "\nERROR EHVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_string value expected but non-hashref value found,\ncroaking" ); }

    HV* possible_hash_string;
    integer possible_hash_string__num_keys;
    integer i;
    HE* possible_hash_string__hashentry;
    SV* possible_hash_string__hashentry_value;
    SV* possible_hash_string__hashentry_key;
    string possible_hash_string__hashentry_key_string;

    possible_hash_string = (HV*)SvRV(possible_hashref_string);
    possible_hash_string__num_keys = hv_iterinit(possible_hash_string);

    for (i = 0;  i < possible_hash_string__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        possible_hash_string__hashentry = hv_iternext(possible_hash_string);

        if (possible_hash_string__hashentry == NULL) { croak("\nERROR EPVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_string__hashentry value expected but undefined/null value found,\ncroaking"); }
        possible_hash_string__hashentry_value = hv_iterval(possible_hash_string, possible_hash_string__hashentry);

        if (not(SvOK(possible_hash_string__hashentry_value)))
        {
            possible_hash_string__hashentry_key = hv_iterkeysv(possible_hash_string__hashentry);
            possible_hash_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at key '%s',\ncroaking", possible_hash_string__hashentry_key_string.c_str());
        }
        if (not(SvPOKp(possible_hash_string__hashentry_value)))
        {
            possible_hash_string__hashentry_key = hv_iterkeysv(possible_hash_string__hashentry);
            possible_hash_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at key '%s',\ncroaking", possible_hash_string__hashentry_key_string.c_str());
        }
    }
}

void hashref_string_CHECKTRACE(SV* possible_hashref_string, const char* variable_name, const char* subroutine_name)
{
    if ( not( SvOK(possible_hashref_string) ) ) { croak( "\nERROR EHVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_string value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvHROKp(possible_hashref_string) ) ) { croak( "\nERROR EHVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhashref_string value expected but non-hashref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    HV* possible_hash_string;
    integer possible_hash_string__num_keys;
    integer i;
    HE* possible_hash_string__hashentry;
    SV* possible_hash_string__hashentry_value;
    SV* possible_hash_string__hashentry_key;
    string possible_hash_string__hashentry_key_string;

    possible_hash_string = (HV*)SvRV(possible_hashref_string);
    possible_hash_string__num_keys = hv_iterinit(possible_hash_string);

    for (i = 0;  i < possible_hash_string__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        possible_hash_string__hashentry = hv_iternext(possible_hash_string);

        if (possible_hash_string__hashentry == NULL) { croak("\nERROR EPVHE00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nhash_string__hashentry value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name); }
        possible_hash_string__hashentry_value = hv_iterval(possible_hash_string, possible_hash_string__hashentry);

        if (not(SvOK(possible_hash_string__hashentry_value)))
        {
            possible_hash_string__hashentry_key = hv_iterkeysv(possible_hash_string__hashentry);
            possible_hash_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at key '%s',\nin variable %s from subroutine %s,\ncroaking", possible_hash_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
        if (not(SvPOKp(possible_hash_string__hashentry_value)))
        {
            possible_hash_string__hashentry_key = hv_iterkeysv(possible_hash_string__hashentry);
            possible_hash_string__hashentry_key_string = escape_backslash_singlequote(string(SvPV_nolen(possible_hash_string__hashentry_key)));  // escape key string for error message
            croak("\nERROR EHVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at key '%s',\nin variable %s from subroutine %s,\ncroaking", possible_hash_string__hashentry_key_string.c_str(), variable_name, subroutine_name);
        }
    }
}

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

# ifdef __CPP__TYPES

// convert from (Perl SV containing reference to (Perl HV of (Perl SVs containing IVs))) to (C++ std::unordered_map of integers)
hashref_integer XS_unpack_hashref_integer(SV* input_hvref)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_integer(), top of subroutine\n");
//  hashref_integer_CHECK(input_hvref);
    hashref_integer_CHECKTRACE(input_hvref, "input_hvref", "XS_unpack_hashref_integer()");

    HV* input_hv;
    integer input_hv__num_keys;
    integer i;
    HE* input_hv__entry;
    SV* input_hv__entry_key;
    SV* input_hv__entry_value;
    hashref_integer output_umap;

    input_hv = (HV*)SvRV(input_hvref);

    input_hv__num_keys = hv_iterinit(input_hv);
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_integer(), have input_hv__num_keys = %"INTEGER"\n", input_hv__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: std::unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap.reserve((size_t)input_hv__num_keys);

    for (i = 0;  i < input_hv__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        // does not utilize i in entry retrieval
        input_hv__entry = hv_iternext(input_hv);
        // DEV NOTE: hash entry type-checking already done as part of hashref_integer_CHECKTRACE()
//      hashentry_CHECK(input_hv__entry);
//      hashentry_CHECKTRACE(input_hv__entry, "input_hv__entry", "XS_unpack_hashref_integer()");

        input_hv__entry_key = hv_iterkeysv(input_hv__entry);
        input_hv__entry_value = hv_iterval(input_hv, input_hv__entry);
        // DEV NOTE: integer type-checking already done as part of hashref_integer_CHECKTRACE()
//      integer_CHECK(input_hv__entry_value);
//      integer_CHECKTRACE(input_hv__entry_value, (char*)((string)"input_hv__entry_value at key '" + (string)SvPV_nolen(input_hv__entry_key) + "'").c_str(), "XS_unpack_hashref_integer()");

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap[SvPV_nolen(input_hv__entry_key)] = SvIV(input_hv__entry_value);
    }

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_integer(), after for() loop, have output_umap.size() = %"INTEGER"\n", output_umap.size());
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_integer(), bottom of subroutine\n");

    return(output_umap);
}

// convert from (C++ std::unordered_map of integers) to (Perl SV containing reference to (Perl HV of (Perl SVs containing IVs)))
void XS_pack_hashref_integer(SV* output_hvref, hashref_integer input_umap)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_integer(), top of subroutine\n");

    HV* output_hv = newHV();  // initialize output hash to empty
    integer input_umap__num_keys = input_umap.size();
    hashref_integer_const_iterator i;
    SV* temp_sv_pointer;

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_integer(), have input_umap__num_keys = %"INTEGER"\n", input_umap__num_keys);

    if (input_umap__num_keys > 0)
    {
        for (i = input_umap.begin();  i != input_umap.end();  ++i)
            { hv_store(output_hv, (const char*)((i->first).c_str()), (U32)((i->first).size()), newSViv(i->second), (U32)0); }
    }
//  else warn("in CPPOPS_CPPTYPES XS_pack_hashref_integer(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref) = (SV*)output_hv;       // make output stack RV point at our output HV

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_integer(), bottom of subroutine\n");
}

// convert from (Perl SV containing reference to (Perl HV of (Perl SVs containing NVs))) to (C++ std::unordered_map of doubles)
hashref_number XS_unpack_hashref_number(SV* input_hvref)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_number(), top of subroutine\n");
//  hashref_number_CHECK(input_hvref);
    hashref_number_CHECKTRACE(input_hvref, "input_hvref", "XS_unpack_hashref_number()");

    HV* input_hv;
    integer input_hv__num_keys;
    integer i;
    HE* input_hv__entry;
    SV* input_hv__entry_key;
    SV* input_hv__entry_value;
    hashref_number output_umap;

    input_hv = (HV*)SvRV(input_hvref);

    input_hv__num_keys = hv_iterinit(input_hv);
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_number(), have input_hv__num_keys = %"INTEGER"\n", input_hv__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: std::unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap.reserve((size_t)input_hv__num_keys);

    for (i = 0;  i < input_hv__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        // does not utilize i in entry retrieval
        input_hv__entry = hv_iternext(input_hv);
        input_hv__entry_key = hv_iterkeysv(input_hv__entry);
        input_hv__entry_value = hv_iterval(input_hv, input_hv__entry);

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap[SvPV_nolen(input_hv__entry_key)] = SvNV(input_hv__entry_value);
    }

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_number(), after for() loop, have output_umap.size() = %"INTEGER"\n", output_umap.size());
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_number(), bottom of subroutine\n");

    return(output_umap);
}

// convert from (C++ std::unordered_map of doubles) to (Perl SV containing reference to (Perl HV of (Perl SVs containing NVs)))
void XS_pack_hashref_number(SV* output_hvref, hashref_number input_umap)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_number(), top of subroutine\n");

    HV* output_hv = newHV();  // initialize output hash to empty
    integer input_umap__num_keys = input_umap.size();
    hashref_number_const_iterator i;
    SV* temp_sv_pointer;

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_number(), have input_umap__num_keys = %"INTEGER"\n", input_umap__num_keys);

    if (input_umap__num_keys > 0)
    {
        for (i = input_umap.begin();  i != input_umap.end();  ++i)
            { hv_store(output_hv, (const char*)((i->first).c_str()), (U32)((i->first).size()), newSVnv(i->second), (U32)0); }
    }
//  else warn("in CPPOPS_CPPTYPES XS_pack_hashref_number(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref) = (SV*)output_hv;       // make output stack RV point at our output HV

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_number(), bottom of subroutine\n");
}

// convert from (Perl SV containing reference to (Perl HV of (Perl SVs containing PVs))) to (C++ std::unordered_map of strings)
hashref_string XS_unpack_hashref_string(SV* input_hvref)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_string(), top of subroutine\n");
//  hashref_string_CHECK(input_hvref);
    hashref_string_CHECKTRACE(input_hvref, "input_hvref", "XS_unpack_hashref_string()");

    HV* input_hv;
    integer input_hv__num_keys;
    integer i;
    HE* input_hv__entry;
    SV* input_hv__entry_key;
    SV* input_hv__entry_value;
    hashref_string output_umap;

    input_hv = (HV*)SvRV(input_hvref);

    input_hv__num_keys = hv_iterinit(input_hv);
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_string(), have input_hv__num_keys = %"INTEGER"\n", input_hv__num_keys);

    // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: std::unordered_map has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid resizing and rehashing in for() loop
    output_umap.reserve((size_t)input_hv__num_keys);

    for (i = 0;  i < input_hv__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        // does not utilize i in entry retrieval
        input_hv__entry = hv_iternext(input_hv);
        input_hv__entry_key = hv_iterkeysv(input_hv__entry);
        input_hv__entry_value = hv_iterval(input_hv, input_hv__entry);

        // UNORDERED MAP ENTRY ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further reserve(); does not utilize i in assignment
        output_umap[SvPV_nolen(input_hv__entry_key)] = SvPV_nolen(input_hv__entry_value);
    }

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_string(), after for() loop, have output_umap.size() = %"INTEGER"\n", output_umap.size());
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_hashref_string(), bottom of subroutine\n");

    return(output_umap);
}

// convert from (C++ std::unordered_map of strings) to (Perl SV containing reference to (Perl HV of (Perl SVs containing PVs)))
void XS_pack_hashref_string(SV* output_hvref, hashref_string input_umap)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_string(), top of subroutine\n");

    HV* output_hv = newHV();  // initialize output hash to empty
    integer input_umap__num_keys = input_umap.size();
    hashref_string_const_iterator i;
    SV* temp_sv_pointer;

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_string(), have input_umap__num_keys = %"INTEGER"\n", input_umap__num_keys);

    if (input_umap__num_keys > 0)
    {
        for (i = input_umap.begin();  i != input_umap.end();  ++i)
            { hv_store(output_hv, (const char*)((i->first).c_str()), (U32)((i->first).size()), newSVpv((i->second).c_str(), 0), (U32)0); }
    }
//  else warn("in CPPOPS_CPPTYPES XS_pack_hashref_string(), hash was empty, returning empty hash via newHV()");

    temp_sv_pointer = newSVrv(output_hvref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_hvref) = (SV*)output_hv;       // make output stack RV point at our output HV

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_hashref_string(), bottom of subroutine\n");
}

# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
SV* hashref_integer_to_string_compact(SV* input_hvref) {
    return hashref_integer_to_string_format(input_hvref, newSViv(-2), newSViv(0));
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
SV* hashref_integer_to_string(SV* input_hvref) {
    return hashref_integer_to_string_format(input_hvref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (pretty), indent level 0
SV* hashref_integer_to_string_pretty(SV* input_hvref) {
    return hashref_integer_to_string_format(input_hvref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (expand), indent level 0
SV* hashref_integer_to_string_expand(SV* input_hvref) {
    return hashref_integer_to_string_format(input_hvref, newSViv(1), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing IVs))) to Perl-parsable (Perl SV containing PV)
SV* hashref_integer_to_string_format(SV* input_hvref, SV* format_level, SV* indent_level)
{
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_integer_to_string(), top of subroutine\n");
//  hashref_integer_CHECK(input_hvref);
    hashref_integer_CHECKTRACE(input_hvref, "input_hvref", "hashref_integer_to_string()");

    // declare local variables
    HV* input_hv;
    integer input_hv__num_keys;
    integer i;
    boolean i_is_0 = 1;
    HE* input_hv__entry;
    SV* input_hv__entry_key;
    string input_hv__entry_key_string;
    SV* input_hv__entry_value;
    SV* output_sv = newSVpv("", 0);

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // compute length of (number of keys in) input hash
    input_hv = (HV*)SvRV(input_hvref);
    input_hv__num_keys = hv_iterinit(input_hv);
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_integer_to_string(), have input_hv__num_keys = %"INTEGER"\n", input_hv__num_keys);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { sv_catsv(output_sv, indent); }

    // begin output string with left-curly-brace, as required for all RPerl hashes
    sv_setpvn(output_sv, "{", 1);

    // loop through all hash keys
    for (i = 0;  i < input_hv__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_integer_to_string(), top of loop i = %"INTEGER"\n", i);

        // does not utilize i in entry retrieval
        input_hv__entry = hv_iternext(input_hv);
        // DEV NOTE: hash entry type-checking already done as part of hashref_integer_CHECKTRACE()
//      hashentry_CHECK(input_hv__entry);
//      hashentry_CHECKTRACE(input_hv__entry, "input_hv__entry", "hashref_integer_to_string()");

        // retrieve input hash's entry value at key
        input_hv__entry_key = hv_iterkeysv(input_hv__entry);
        input_hv__entry_value = hv_iterval(input_hv, input_hv__entry);
        // DEV NOTE: integer type-checking already done as part of hashref_integer_CHECKTRACE()
//      integer_CHECK(input_hv__entry_value);
//      integer_CHECKTRACE(input_hv__entry_value, (char*)((string)"input_hv__entry_value at key '" + (string)SvPV_nolen(input_hv__entry_key) + "'").c_str(), "hashref_integer_to_string()");

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { sv_catpvn(output_sv, ",", 1); }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }
        else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

        // escape key string
        input_hv__entry_key_string = escape_backslash_singlequote(string(SvPV_nolen(input_hv__entry_key)));

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        sv_catpvf(output_sv, "'%s'", SvPV_nolen(input_hv__entry_key));  // alternative form
        sv_catpvf(output_sv, "'%s'", input_hv__entry_key_string.c_str());

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " => ", 4); }
        else                               { sv_catpvn(output_sv, "=>", 2); }

//        sv_catpvf(output_sv, "%"INTEGER"", (integer)SvIV(input_hv__entry_value));  // NO UNDERSCORES
        sv_catsv(output_sv, integer_to_string(input_hv__entry_value));  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }
    else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

    // end output string with right-curly-brace, as required for all RPerl hashes
    sv_catpvn(output_sv, "}", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_integer_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_integer_to_string(), bottom of subroutine\n");

    return(output_sv);
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
SV* hashref_number_to_string_compact(SV* input_hvref) {
    return hashref_number_to_string_format(input_hvref, newSViv(-2), newSViv(0));
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
SV* hashref_number_to_string(SV* input_hvref) {
    return hashref_number_to_string_format(input_hvref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (pretty), indent level 0
SV* hashref_number_to_string_pretty(SV* input_hvref) {
    return hashref_number_to_string_format(input_hvref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (expand), indent level 0
SV* hashref_number_to_string_expand(SV* input_hvref) {
    return hashref_number_to_string_format(input_hvref, newSViv(1), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing NVs))) to Perl-parsable (Perl SV containing PV)
SV* hashref_number_to_string_format(SV* input_hvref, SV* format_level, SV* indent_level)
{
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_number_to_string(), top of subroutine\n");
//  hashref_number_CHECK(input_hvref);
    hashref_number_CHECKTRACE(input_hvref, "input_hvref", "hashref_number_to_string()");

    // declare local variables
    HV* input_hv;
    integer input_hv__num_keys;
    integer i;
    boolean i_is_0 = 1;
    HE* input_hv__entry;
    SV* input_hv__entry_key;
    string input_hv__entry_key_string;
    SV* input_hv__entry_value;
    SV* output_sv = newSV(0);

    // NEED ANSWER: do we actually need to be using ostringstream here for precision, since the actual numbers are being stringified by number_to_string() below???
    ostringstream temp_stream;
    temp_stream.precision(std::numeric_limits<double>::digits10);

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // compute length of (number of keys in) input hash
    input_hv = (HV*)SvRV(input_hvref);
    input_hv__num_keys = hv_iterinit(input_hv);
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_number_to_string(), have input_hv__num_keys = %"INTEGER"\n", input_hv__num_keys);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { temp_stream << SvPV_nolen(indent); }

    // begin output string with left-curly-brace, as required for all RPerl hashes
    temp_stream << "{";

    // loop through all hash keys
    for (i = 0;  i < input_hv__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        // does not utilize i in entry retrieval
        input_hv__entry = hv_iternext(input_hv);
        input_hv__entry_key = hv_iterkeysv(input_hv__entry);
        input_hv__entry_value = hv_iterval(input_hv, input_hv__entry);

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { temp_stream << ","; }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >=  1) { temp_stream << "\n" << SvPV_nolen(indent) << "    "; }
        else if (SvIV(format_level) >= -1) { temp_stream << " "; }

        // escape key string
        input_hv__entry_key_string = escape_backslash_singlequote(string(SvPV_nolen(input_hv__entry_key)));

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        temp_stream << "'" << SvPV_nolen(input_hv__entry_key) << "'";  // alternative form
        temp_stream << "'" << input_hv__entry_key_string.c_str() << "'";

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= -1) { temp_stream << " => "; }
        else                               { temp_stream << "=>"; }

//      temp_stream << (double)SvNV(input_hv__entry_value);  // NO UNDERSCORES
        temp_stream << (string)SvPV_nolen(number_to_string(input_hv__entry_value));  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (SvIV(format_level) >=  1) { temp_stream << "\n" << SvPV_nolen(indent); }
    else if (SvIV(format_level) >= -1) { temp_stream << " "; }

    // end output string with right-curly-brace, as required for all RPerl hashes
    temp_stream << "}";
    sv_setpv(output_sv, (char*)(temp_stream.str().c_str()));

//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_number_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_number_to_string(), bottom of subroutine\n");

    return(output_sv);
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
SV* hashref_string_to_string_compact(SV* input_hvref) {
    return hashref_string_to_string_format(input_hvref, newSViv(-2), newSViv(0));
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
SV* hashref_string_to_string(SV* input_hvref) {
    return hashref_string_to_string_format(input_hvref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (pretty), indent level 0
SV* hashref_string_to_string_pretty(SV* input_hvref) {
    return hashref_string_to_string_format(input_hvref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (expand), indent level 0
SV* hashref_string_to_string_expand(SV* input_hvref) {
    return hashref_string_to_string_format(input_hvref, newSViv(1), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl HV of (Perl SVs containing PVs))) to Perl-parsable (Perl SV containing PV)
SV* hashref_string_to_string_format(SV* input_hvref, SV* format_level, SV* indent_level)
{
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_string_to_string(), top of subroutine\n");
//  hashref_string_CHECK(input_hvref);
    hashref_string_CHECKTRACE(input_hvref, "input_hvref", "hashref_string_to_string()");

    // declare local variables
    HV* input_hv;
    integer input_hv__num_keys;
    integer i;
    boolean i_is_0 = 1;
    HE* input_hv__entry;
    SV* input_hv__entry_key;
    string input_hv__entry_key_string;
    SV* input_hv__entry_value;
    string input_hv__entry_value_string;
    SV* output_sv = newSVpv("", 0);

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // compute length of (number of keys in) input hash
    input_hv = (HV*)SvRV(input_hvref);
    input_hv__num_keys = hv_iterinit(input_hv);
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_string_to_string(), have input_hv__num_keys = %"INTEGER"\n", input_hv__num_keys);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { sv_catsv(output_sv, indent); }

    // begin output string with left-curly-brace, as required for all RPerl hashes
    sv_setpvn(output_sv, "{", 1);

    // loop through all hash keys
    for (i = 0;  i < input_hv__num_keys;  ++i)  // incrementing iteration, iterator i not actually used in loop body
    {
        // does not utilize i in entry retrieval
        input_hv__entry = hv_iternext(input_hv);
        input_hv__entry_key = hv_iterkeysv(input_hv__entry);
        input_hv__entry_value = hv_iterval(input_hv, input_hv__entry);

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { sv_catpvn(output_sv, ",", 1); }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }
        else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

        // escape key string
        input_hv__entry_key_string = escape_backslash_singlequote(string(SvPV_nolen(input_hv__entry_key)));

        // escape value string
        input_hv__entry_value_string = escape_backslash_singlequote(string(SvPV_nolen(input_hv__entry_value)));

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        sv_catpvf(output_sv, "'%s'", SvPV_nolen(input_hv__entry_key));  // alternative form
        sv_catpvf(output_sv, "'%s'", input_hv__entry_key_string.c_str());

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if      (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " => ", 4); }
        else                               { sv_catpvn(output_sv, "=>", 2); }

//      sv_catpvf(output_sv, "'%s'", SvPV_nolen(input_hv__entry_value));  // alternative form
        sv_catpvf(output_sv, "'%s'", input_hv__entry_value_string.c_str());
    }

    // append newline-indent or space, depending on format level
    if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }
    else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

    // end output string with right-curly-brace, as required for all RPerl hashes
    sv_catpvn(output_sv, "}", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_string_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES hashref_string_to_string(), bottom of subroutine\n");

    return(output_sv);
}

# elif defined __CPP__TYPES

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
string hashref_integer_to_string_compact(hashref_integer input_umap)
{
    return hashref_integer_to_string_format(input_umap, -2, 0);
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
string hashref_integer_to_string(hashref_integer input_umap)
{
    return hashref_integer_to_string_format(input_umap, -1, 0);
}

// call actual stringify routine, format level 0 (pretty), indent level 0
string hashref_integer_to_string_pretty(hashref_integer input_umap)
{
    return hashref_integer_to_string_format(input_umap, 0, 0);
}

// call actual stringify routine, format level 1 (expand), indent level 0
string hashref_integer_to_string_expand(hashref_integer input_umap)
{
    return hashref_integer_to_string_format(input_umap, 1, 0);
}

// convert from (C++ std::unordered_map of integers) to Perl-parsable (C++ std::string)
string hashref_integer_to_string_format(hashref_integer input_umap, integer format_level, integer indent_level)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_integer_to_string(), top of subroutine\n");

    // declare local variables
    ostringstream output_stream;
    hashref_integer_const_iterator i;
    boolean i_is_0 = 1;
    string key_string;

    // generate indent
    string indent = "";
    for (integer indent_i = 0; indent_i < indent_level; indent_i++) { indent += "    "; }

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_stream << indent; }

    // begin output string with left-curly-brace, as required for all RPerl hashes
    output_stream << '{';

    // loop through all hash keys
    for (i = input_umap.begin();  i != input_umap.end();  ++i)
    {
        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_stream << ','; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >=  1) { output_stream << endl << indent << "    "; }
        else if (format_level >= -1) { output_stream << ' '; }

        // escape key string
        key_string = escape_backslash_singlequote(i->first);

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        output_stream << "'" << (i->first).c_str() << "'";  // alternative format
        output_stream << "'" << key_string.c_str() << "'";

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if (format_level >= -1) { output_stream << " => "; }
        else                    { output_stream << "=>"; }

//        output_stream << i->second;  // NO UNDERSCORES
        output_stream << integer_to_string(i->second);  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (format_level >=  1) { output_stream << endl << indent; }
    else if (format_level >= -1) { output_stream << ' '; }

    // end output string with right-curly-brace, as required for all RPerl hashes
    output_stream << '}';

//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_integer_to_string(), after for() loop, have output_stream =\n%s\n", (char*)(output_stream.str().c_str()));
//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_integer_to_string(), bottom of subroutine\n");

    return(output_stream.str());
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
string hashref_number_to_string_compact(hashref_number input_umap)
{
    return hashref_number_to_string_format(input_umap, -2, 0);
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
string hashref_number_to_string(hashref_number input_umap)
{
    return hashref_number_to_string_format(input_umap, -1, 0);
}

// call actual stringify routine, format level 0 (pretty), indent level 0
string hashref_number_to_string_pretty(hashref_number input_umap)
{
    return hashref_number_to_string_format(input_umap, 0, 0);
}

// call actual stringify routine, format level 1 (expand), indent level 0
string hashref_number_to_string_expand(hashref_number input_umap)
{
    return hashref_number_to_string_format(input_umap, 1, 0);
}

// convert from (C++ std::unordered_map of doubles) to Perl-parsable (C++ std::string)
string hashref_number_to_string_format(hashref_number input_umap, integer format_level, integer indent_level)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_number_to_string(), top of subroutine\n");

    // declare local variables
    ostringstream output_stream;
    hashref_number_const_iterator i;
    boolean i_is_0 = 1;
    string key_string;

    // NEED ANSWER: do we actually need to be using ostringstream here for precision, since the actual numbers are being stringified by number_to_string() below???
    output_stream.precision(std::numeric_limits<double>::digits10);

    // generate indent
    string indent = "";
    for (integer indent_i = 0; indent_i < indent_level; indent_i++) { indent += "    "; }

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_stream << indent; }

    // begin output string with left-curly-brace, as required for all RPerl hashes
    output_stream << '{';

    // loop through all hash keys
    for (i = input_umap.begin();  i != input_umap.end();  ++i)
    {
        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_stream << ','; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >=  1) { output_stream << endl << indent << "    "; }
        else if (format_level >= -1) { output_stream << ' '; }

        // escape key string
        key_string = escape_backslash_singlequote(i->first);

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//        output_stream << "'" << (i->first).c_str() << "'";  // alternative format
        output_stream << "'" << key_string.c_str() << "'";

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if (format_level >= -1) { output_stream << " => "; }
        else                    { output_stream << "=>"; }

//        output_stream << i->second;  // NO UNDERSCORES
        output_stream << number_to_string(i->second);  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (format_level >=  1) { output_stream << endl << indent; }
    else if (format_level >= -1) { output_stream << ' '; }

    // end output string with right-curly-brace, as required for all RPerl hashes
    output_stream << '}';

//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_number_to_string(), after for() loop, have output_stream =\n%s\n", (char*)(output_stream.str().c_str()));
//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_number_to_string(), bottom of subroutine\n");

    return(output_stream.str());
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
string hashref_string_to_string_compact(hashref_string input_umap)
{
    return hashref_string_to_string_format(input_umap, -2, 0);
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
string hashref_string_to_string(hashref_string input_umap)
{
    return hashref_string_to_string_format(input_umap, -1, 0);
}

// call actual stringify routine, format level 0 (pretty), indent level 0
string hashref_string_to_string_pretty(hashref_string input_umap)
{
    return hashref_string_to_string_format(input_umap, 0, 0);
}

// call actual stringify routine, format level 1 (expand), indent level 0
string hashref_string_to_string_expand(hashref_string input_umap)
{
    return hashref_string_to_string_format(input_umap, 1, 0);
}

// convert from (C++ std::unordered_map of std::strings) to Perl-parsable (C++ std::string)
string hashref_string_to_string_format(hashref_string input_umap, integer format_level, integer indent_level)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_string_to_string(), top of subroutine\n");

    // declare local variables
    string output_string;
    hashref_string_const_iterator i;
    boolean i_is_0 = 1;
    string key_string;
    string value_string;

    // generate indent
    string indent = "";
    for (integer indent_i = 0; indent_i < indent_level; indent_i++) { indent += "    "; }

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_string += indent; }

    // begin output string with left-curly-brace, as required for all RPerl hashes
    output_string = "{";

    // loop through all hash keys
    for (i = input_umap.begin();  i != input_umap.end();  ++i)
    {
        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_string += ","; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >=  1) { output_string += "\n" + indent + "    "; }
        else if (format_level >= -1) { output_string += " "; }

        // escape key string
        key_string = escape_backslash_singlequote(i->first);

        // escape value string
        value_string = escape_backslash_singlequote(i->second);

        // DEV NOTE: emulate Data::Dumper & follow PBP by using single quotes for key strings
//      output_string += "'" + (string)(i->first).c_str() + "'";  // alternative format
        output_string += "'" + key_string + "'";

        // append spaces before and after fat arrow AKA fat comma, depending on format level
        if (format_level >= -1) { output_string += " => "; }
        else                    { output_string += "=>"; }

//      output_string += "'" + (string)(i->second) + "'";  // alternative format
        output_string += "'" + value_string + "'";
    }

    // append newline-indent or space, depending on format level
    if      (format_level >=  1) { output_string += "\n" + indent; }
    else if (format_level >= -1) { output_string += " "; }

    // end output string with right-curly-brace, as required for all RPerl hashes
    output_string += "}";

//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_string_to_string(), after for() loop, have output_string =\n%s\n", output_string.c_str());
//  fprintf(stderr, "in CPPOPS_CPPTYPES hashref_string_to_string(), bottom of subroutine\n");

    return(output_string);
}

# else

Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!

# endif

// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES

SV* hashref_integer_typetest0(SV* lucky_integers)
{
//  hashref_integer_CHECK(lucky_integers);
    hashref_integer_CHECKTRACE(lucky_integers, "lucky_integers", "hashref_integer_typetest0()");

/*
    HV* lucky_integers_deref = (HV*)SvRV(lucky_integers);
    integer how_lucky = hv_iterinit(lucky_integers_deref);
    integer i;

    for (i = 0;  i < how_lucky;  ++i)
    {
        HE* lucky_integer_entry = hv_iternext(lucky_integers_deref);
        // DEV NOTE: hash entry type-checking already done as part of hashref_integer_CHECKTRACE()
//      hashentry_CHECK(lucky_integer_entry);
//      hashentry_CHECKTRACE(lucky_integer_entry, "lucky_integer_entry", "hashref_integer_typetest0()");

        // DEV NOTE: not using lucky_number variable as in Hash.pm
        // DEV NOTE: integer type-checking already done as part of hashref_integer_CHECKTRACE()
//      integer_CHECK(hv_iterval(lucky_integers_deref, lucky_integer_entry));
//      integer_CHECKTRACE(hv_iterval(lucky_integers_deref, lucky_integer_entry), (char*)((string)"hv_iterval(lucky_integers_deref, lucky_integer_entry) at key '" + (string)SvPV_nolen(hv_iterkeysv(lucky_integer_entry)) + "'").c_str(), "hashref_integer_typetest0()");

//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_integer_typetest0(), have lucky integer '%s' => %"INTEGER", BARSTOOL\n", SvPV_nolen(hv_iterkeysv(lucky_integer_entry)), (integer)SvIV(hv_iterval(lucky_integers_deref, lucky_integer_entry)));
    }
*/

    return(newSVpvf("%s%s", SvPV_nolen(hashref_integer_to_string(lucky_integers)), "CPPOPS_PERLTYPES"));
}

SV* hashref_integer_typetest1(SV* my_size)
{
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "hashref_integer_typetest1()");
    HV* output_hv = newHV();
    integer i;
    char temp_key[30];

    for (i = 0;  i < SvIV(my_size);  ++i)
    {
        sprintf(temp_key, "CPPOPS_PERLTYPES_funkey%"INTEGER"", i);
        hv_store(output_hv, (const char*)temp_key, (U32)strlen(temp_key), newSViv(i * 5), (U32)0);
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_integer_typetest1(), setting entry '%s' => %"INTEGER", BARBAT\n", temp_key, (integer)SvIV(*hv_fetch(output_hv, (const char*)temp_key, (U32)strlen(temp_key), (I32)0)));
    }

    return(newRV_noinc((SV*) output_hv));
}

SV* hashref_number_typetest0(SV* lucky_numbers)
{
//  hashref_number_CHECK(lucky_numbers);
    hashref_number_CHECKTRACE(lucky_numbers, "lucky_numbers", "hashref_number_typetest0()");

/*
    HV* lucky_numbers_deref = (HV*)SvRV(lucky_numbers);
    integer how_lucky = hv_iterinit(lucky_numbers_deref);
    integer i;

    for (i = 0;  i < how_lucky;  ++i)
    {
        HE* lucky_number_entry = hv_iternext(lucky_numbers_deref);
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_number_typetest0(), have lucky number '%s' => %"NUMBER", BARSTOOP\n", SvPV_nolen(hv_iterkeysv(lucky_number_entry)), (number)SvNV(hv_iterval(lucky_numbers_deref, lucky_number_entry)));
    }
*/

    return(newSVpvf("%s%s", SvPV_nolen(hashref_number_to_string(lucky_numbers)), "CPPOPS_PERLTYPES"));
}

SV* hashref_number_typetest1(SV* my_size)
{
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "hashref_number_typetest1()");
    HV* output_hv = newHV();
    integer i;
    char temp_key[30];

    for (i = 0;  i < SvIV(my_size);  ++i)
    {
        sprintf(temp_key, "CPPOPS_PERLTYPES_funkey%"INTEGER"", i);
        hv_store(output_hv, (const char*)temp_key, (U32)strlen(temp_key), newSVnv(i * 5.123456789), (U32)0);
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_number_typetest1(), setting entry '%s' => %"NUMBER", BARTAB\n", temp_key, (number)SvNV(*hv_fetch(output_hv, (const char*)temp_key, (U32)strlen(temp_key), (I32)0)));
    }

    return(newRV_noinc((SV*) output_hv));
}

SV* hashref_string_typetest0(SV* people)
{
//  hashref_string_CHECK(people);
    hashref_string_CHECKTRACE(people, "people", "hashref_string_typetest0()");

/*
    HV* people_deref = (HV*)SvRV(people);
    integer how_crowded = hv_iterinit(people_deref);
    integer i;

    for (i = 0;  i < how_crowded;  ++i)
    {
        HE* person_entry = hv_iternext(people_deref);
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_string_typetest0(), have person '%s' => '%s', BARSPOON\n", (char*)SvPV_nolen(hv_iterkeysv(person_entry)), (char*)SvPV_nolen(hv_iterval(people_deref, person_entry)));
    }
*/

    return(newSVpvf("%s%s", SvPV_nolen(hashref_string_to_string(people)), "CPPOPS_PERLTYPES"));
}

SV* hashref_string_typetest1(SV* my_size)
{
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "hashref_string_typetest1()");
    HV* people = newHV();
    integer i;
    char temp_key[30];

    for (i = 0;  i < SvIV(my_size);  ++i)
    {
        sprintf(temp_key, "CPPOPS_PERLTYPES_Luker_key%"INTEGER"", i);
        hv_store(people, (const char*)temp_key, (U32)strlen(temp_key), newSVpvf("Jeffy Ten! %"INTEGER"/%"INTEGER"", i, (integer)(SvIV(my_size) - 1)), (U32)0);
//      fprintf(stderr, "in CPPOPS_PERLTYPES hashref_string_typetest1(), have temp_key = '%s', just set another Jeffy, BARTAT\n", temp_key);
    }

    return(newRV_noinc((SV*) people));
}

# elif defined __CPP__TYPES

string hashref_integer_typetest0(hashref_integer lucky_integers)
{
    /*
    hashref_integer_const_iterator i;
    for (i = lucky_integers.begin();  i != lucky_integers.end();  ++i)
    {
        fprintf(stderr, "in CPPOPS_CPPTYPES hashref_integer_typetest0(), have lucky integer '%s' => %"INTEGER", BARSTOOL\n", (i->first).c_str(), i->second);
    }
    */
    return(hashref_integer_to_string(lucky_integers) + "CPPOPS_CPPTYPES");
}

hashref_integer hashref_integer_typetest1(integer my_size)
{
    hashref_integer new_umap(my_size);
    integer i;
    string temp_key;
    for (i = 0;  i < my_size;  ++i)
    {
        temp_key = "CPPOPS_CPPTYPES_funkey" + std::to_string(i);
        new_umap[temp_key] = i * 5;
//      fprintf(stderr, "in CPPOPS_CPPTYPES hashref_integer_typetest1(), setting entry '%s' => %"INTEGER", BARSTOOL\n", temp_key.c_str(), new_umap[temp_key]);
    }
    return(new_umap);
}

string hashref_number_typetest0(hashref_number lucky_numbers)
{
    /*
    hashref_number_const_iterator i;
    for (i = lucky_numbers.begin();  i != lucky_numbers.end();  ++i)
    {
        fprintf(stderr, "in CPPOPS_CPPTYPES hashref_number_typetest0(), have lucky number '%s' => %"NUMBER", BARSTOOL\n", (i->first).c_str(), i->second);
    }
    */
    return(hashref_number_to_string(lucky_numbers) + "CPPOPS_CPPTYPES");
}

hashref_number hashref_number_typetest1(integer my_size)
{
    hashref_number new_umap(my_size);
    integer i;
    string temp_key;
    for (i = 0;  i < my_size;  ++i)
    {
        temp_key = "CPPOPS_CPPTYPES_funkey" + std::to_string(i);
        new_umap[temp_key] = i * 5.123456789;
//      fprintf(stderr, "in CPPOPS_CPPTYPES hashref_number_typetest1(), setting entry '%s' => %"NUMBER", BARSTOOL\n", temp_key.c_str(), new_umap[temp_key]);
    }
    return(new_umap);
}

string hashref_string_typetest0(hashref_string people)
{
    /*
    hashref_string_const_iterator i;
    for (i = people.begin();  i != people.end();  ++i)
    {
        fprintf(stderr, "in CPPOPS_CPPTYPES hashref_string_typetest0(), have person '%s' => '%s', STARBOOL\n", (i->first).c_str(), (i->second).c_str());
    }
    */
    return(hashref_string_to_string(people) + "CPPOPS_CPPTYPES");
}

hashref_string hashref_string_typetest1(integer my_size)
{
    hashref_string people;
    integer i;
    people.reserve((size_t)my_size);
    for (i = 0;  i < my_size;  ++i)
    {
        people["CPPOPS_CPPTYPES_Luker_key" + std::to_string(i)] = "Jeffy Ten! " + std::to_string(i) + "/" + std::to_string(my_size - 1);
//      fprintf(stderr, "in CPPOPS_CPPTYPES hashref_string_typetest1(), bottom of for() loop, have i = %"INTEGER", just set another Jeffy!\n", i);
    }
    return(people);
}

# endif

#endif
