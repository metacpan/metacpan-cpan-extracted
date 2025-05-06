using std::cout;  using std::cerr;  using std::endl;  using std::to_string;

#ifndef __CPP__INCLUDED__Perl__Structure__Array__SubTypes1D_cpp
#define __CPP__INCLUDED__Perl__Structure__Array__SubTypes1D_cpp 0.023_000

#include <Perl/Structure/Array/SubTypes1D.h>  // -> ??? (relies on <vector> being included via Inline::CPP's AUTO_INCLUDE config option in RPerl/Inline.pm)

/*
* NEED FIX, CORRELATION #rp002: bug, possibly in Inline, causing inability to declare 3rd count_FOO argument to T_PACKEDARRAY;
* temporarily fixed by changing typemap to set char** to T_PACKED;
* may need Inline to add declaration of count_FOO to PREINIT section of auto-generated XS code
*
* eval_FOO.c: In function ‘void XS_main_XS_unpack_charPtrPtr(PerlInterpreter*, CV*)’:
* eval_FOO.c:1322:36: error: ‘count_charPtrPtr’ was not declared in this scope
*/

// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]

// DEV NOTE: for() loops are statements not expressions, so they can't be embedded in ternary operators, and thus this type-checking must be done with subroutines instead of macros
void arrayref_integer_CHECK(SV* possible_arrayref_integer)
{
    // DEV NOTE: the following two if() statements are functionally equivalent to the arrayref_CHECK() macro, but with integer-specific error codes
    if ( not( SvOK(possible_arrayref_integer) ) ) { croak( "\nERROR EAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvAROKp(possible_arrayref_integer) ) ) { croak( "\nERROR EAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found,\ncroaking" ); }

    AV* possible_array_integer;
    integer possible_array_integer__length;
    integer i;
    SV** possible_array_integer__element;

    possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
    possible_array_integer__length = av_len(possible_array_integer) + 1;

    for (i = 0;  i < possible_array_integer__length;  ++i)  // incrementing iteration
    {
        possible_array_integer__element = av_fetch(possible_array_integer, i, 0);

        // DEV NOTE: the following two if() statements are functionally equivalent to the integer_CHECK() macro & subroutine, but with array-specific error codes
        if (not(SvOK(*possible_array_integer__element))) { croak("\nERROR EAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at index %"INTEGER",\ncroaking", i); }
        if (not(SvIOKp(*possible_array_integer__element))) { croak("\nERROR EAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index %"INTEGER",\ncroaking", i); }
    }
}

void arrayref_integer_CHECKTRACE(SV* possible_arrayref_integer, const char* variable_name, const char* subroutine_name)
{
    if ( not( SvOK(possible_arrayref_integer) ) ) { croak( "\nERROR EAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvAROKp(possible_arrayref_integer) ) ) { croak( "\nERROR EAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    AV* possible_array_integer;
    integer possible_array_integer__length;
    integer i;
    SV** possible_array_integer__element;

    possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
    possible_array_integer__length = av_len(possible_array_integer) + 1;

    for (i = 0;  i < possible_array_integer__length;  ++i)  // incrementing iteration
    {
        possible_array_integer__element = av_fetch(possible_array_integer, i, 0);

        if (not(SvOK(*possible_array_integer__element))) { croak("\nERROR EAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger expected but undefined/null value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name); }
        if (not(SvIOKp(*possible_array_integer__element))) { croak("\nERROR EAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name); }
    }
}

void arrayref_number_CHECK(SV* possible_arrayref_number)
{
    if ( not( SvOK(possible_arrayref_number) ) ) { croak( "\nERROR EAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvAROKp(possible_arrayref_number) ) ) { croak( "\nERROR EAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found,\ncroaking" ); }

    AV* possible_array_number;
    integer possible_array_number__length;
    integer i;
    SV** possible_array_number__element;

    possible_array_number = (AV*)SvRV(possible_arrayref_number);
    possible_array_number__length = av_len(possible_array_number) + 1;

    for (i = 0;  i < possible_array_number__length;  ++i)  // incrementing iteration
    {
        possible_array_number__element = av_fetch(possible_array_number, i, 0);

        if (not(SvOK(*possible_array_number__element))) { croak("\nERROR EAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index %"INTEGER",\ncroaking", i); }
        if (not(SvNOKp(*possible_array_number__element) || SvIOKp(*possible_array_number__element))) { croak("\nERROR EAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index %"INTEGER",\ncroaking", i); }
    }
}

void arrayref_number_CHECKTRACE(SV* possible_arrayref_number, const char* variable_name, const char* subroutine_name)
{
    if ( not( SvOK(possible_arrayref_number) ) ) { croak( "\nERROR EAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvAROKp(possible_arrayref_number) ) ) { croak( "\nERROR EAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    AV* possible_array_number;
    integer possible_array_number__length;
    integer i;
    SV** possible_array_number__element;

    possible_array_number = (AV*)SvRV(possible_arrayref_number);
    possible_array_number__length = av_len(possible_array_number) + 1;

    for (i = 0;  i < possible_array_number__length;  ++i)  // incrementing iteration
    {
        possible_array_number__element = av_fetch(possible_array_number, i, 0);

        if (not(SvOK(*possible_array_number__element))) { croak("\nERROR EAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name); }
        if (not(SvNOKp(*possible_array_number__element) || SvIOKp(*possible_array_number__element))) { croak("\nERROR EAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name); }
    }
}

void arrayref_string_CHECK(SV* possible_arrayref_string)
{
    if ( not( SvOK(possible_arrayref_string) ) ) { croak( "\nERROR EAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvAROKp(possible_arrayref_string) ) ) { croak( "\nERROR EAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found,\ncroaking" ); }

    AV* possible_array_string;
    integer possible_array_string__length;
    integer i;
    SV** possible_array_string__element;

    possible_array_string = (AV*)SvRV(possible_arrayref_string);
    possible_array_string__length = av_len(possible_array_string) + 1;

    for (i = 0;  i < possible_array_string__length;  ++i)  // incrementing iteration
    {
        possible_array_string__element = av_fetch(possible_array_string, i, 0);

        if (not(SvOK(*possible_array_string__element))) { croak("\nERROR EAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index %"INTEGER",\ncroaking", i); }
        if (not(SvPOKp(*possible_array_string__element))) { croak("\nERROR EAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index %"INTEGER",\ncroaking", i); }
    }
}

void arrayref_string_CHECKTRACE(SV* possible_arrayref_string, const char* variable_name, const char* subroutine_name)
{
    if ( not( SvOK(possible_arrayref_string) ) ) { croak( "\nERROR EAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvAROKp(possible_arrayref_string) ) ) { croak( "\nERROR EAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    AV* possible_array_string;
    integer possible_array_string__length;
    integer i;
    SV** possible_array_string__element;

    possible_array_string = (AV*)SvRV(possible_arrayref_string);
    possible_array_string__length = av_len(possible_array_string) + 1;

    for (i = 0;  i < possible_array_string__length;  ++i)  // incrementing iteration
    {
        possible_array_string__element = av_fetch(possible_array_string, i, 0);

        if (not(SvOK(*possible_array_string__element))) { croak("\nERROR EAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name); }
        if (not(SvPOKp(*possible_array_string__element))) { croak("\nERROR EAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name); }
    }
}

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

# ifdef __CPP__TYPES

// convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs))) to (C++ std::vector of integers)
arrayref_integer XS_unpack_arrayref_integer(SV* input_avref)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_integer(), top of subroutine\n");
//  arrayref_integer_CHECK(input_avref);
    arrayref_integer_CHECKTRACE(input_avref, "input_avref", "XS_unpack_arrayref_integer()");

    AV* input_av;
    integer input_av__length;
    integer i;
    SV** input_av__element;
    arrayref_integer output_vector;

    input_av = (AV*)SvRV(input_avref);
    input_av__length = av_len(input_av) + 1;
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_integer(), have input_av__length = %"INTEGER"\n", input_av__length);

    // DEV NOTE: VECTOR ELEMENT ASSIGNMENT OPTION information is not specific to this subroutine or packing/unpacking

    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
    // resize() ahead of time to allow l-value subscript notation
    output_vector.resize((size_t)input_av__length);

    // VECTOR ELEMENT ASSIGNMENT, OPTION C, PUSH, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
    // reserve() ahead of time to avoid memory reallocation(s) (aka change in vector capacity) during element copying in for() loop
//  output_vector.reserve((size_t)input_av__length);

    // VECTOR ELEMENT ASSIGNMENT, OPTION E, ITERATOR, KNOWN SIZE:
//  output_vector.reserve((size_t)input_av__length);  // if incrementing iteration
//  output_vector.resize((size_t)input_av__length);  // if decrementing iteration

    for (i = 0;  i < input_av__length;  ++i)  // incrementing iteration
//  for (i = (input_av__length - 1);  i >= 0;  --i)  // decrementing iteration
    {
        // utilizes i in element retrieval
        input_av__element = av_fetch(input_av, i, 0);
        // DEV NOTE: integer type-checking already done as part of arrayref_integer_CHECKTRACE()
//      integer_CHECK(*input_av__element);
//      integer_CHECKTRACE(*input_av__element, (char*)((string)"*input_av__element at index " + to_string(i)).c_str(), "XS_unpack_arrayref_integer()");

        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes i in assignment
        output_vector[i] = SvIV(*input_av__element);

        // VECTOR ELEMENT ASSIGNMENT, OPTION B, SUBSCRIPT, UNKNOWN SIZE: unpredictable value of i and thus unpredictable vector size,
        // call resize() every time we use l-value subscript; utilizes i in assignment
//      VECTOR_RESIZE_NOSHRINK(output_vector, (i + 1));  output_vector[i] = SvIV(*input_av__element);

        // VECTOR ELEMENT ASSIGNMENT, OPTIONS C & D, PUSH, KNOWN & UNKNOWN SIZE: push_back() calls resize(); does not utilize i in assignment;
        // only works for incrementing iteration!!!  will reverse list order for decrementing iteration, there is no push_front() method
//      output_vector.push_back(SvIV(*input_av__element));

        // VECTOR ELEMENT ASSIGNMENT, OPTION E, ITERATOR, KNOWN SIZE: utilizes i in assignment
//      output_vector.insert((i + output_vector.begin()), SvIV(*input_av__element));  // if incrementing iteration
//      output_vector.erase(i + output_vector.begin());  output_vector.insert((i + output_vector.begin()), SvIV(*input_av__element));  // if decrementing iteration

        // VECTOR ELEMENT ASSIGNMENT, OPTION F, ITERATOR, UNKNOWN SIZE: unpredictable value of i and thus unpredictable vector size,
        // call resize() every time we use insert(); utilizes i in assignment
//      VECTOR_RESIZE_NOSHRINK(output_vector, (i + 1));  output_vector.erase(i + output_vector.begin());  output_vector.insert((i + output_vector.begin()), SvIV(*input_av__element));
    }

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_integer(), after for() loop, have output_vector.size() = %"INTEGER"\n", output_vector.size());
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_integer(), bottom of subroutine\n");

    return(output_vector);
}

// convert from (C++ std::vector of integers) to (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs)))
void XS_pack_arrayref_integer(SV* output_avref, arrayref_integer input_vector)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_integer(), top of subroutine\n");

    AV* output_av = newAV();  // initialize output array to empty
    integer input_vector__length = input_vector.size();
    integer i;
    SV* temp_sv_pointer;

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_integer(), have input_vector__length = %"INTEGER"\n", input_vector__length);

    if (input_vector__length > 0) { for (i = 0;  i < input_vector__length;  ++i) { av_push(output_av, newSViv(input_vector[i])); } }
//  else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_integer(), array was empty, returning empty array via newAV()");

    temp_sv_pointer = newSVrv(output_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_avref) = (SV*)output_av;       // make output stack RV point at our output AV

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_integer(), bottom of subroutine\n");
}

// convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs))) to (C++ std::vector of numbers)
arrayref_number XS_unpack_arrayref_number(SV* input_avref)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_number(), top of subroutine\n");
//  arrayref_number_CHECK(input_avref);
    arrayref_number_CHECKTRACE(input_avref, "input_avref", "XS_unpack_arrayref_number()");

    AV* input_av;
    integer input_av__length;
    integer i;
    SV** input_av__element;
    arrayref_number output_vector;

    input_av = (AV*)SvRV(input_avref);
    input_av__length = av_len(input_av) + 1;
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_number(), have input_av__length = %"INTEGER"\n", input_av__length);

    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
    // resize() ahead of time to allow l-value subscript notation
    output_vector.resize((size_t)input_av__length);

    for (i = 0;  i < input_av__length;  ++i)  // incrementing iteration
    {
        // utilizes i in element retrieval
        input_av__element = av_fetch(input_av, i, 0);

        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes i in assignment
        output_vector[i] = SvNV(*input_av__element);
    }

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_number(), after for() loop, have output_vector.size() = %"INTEGER"\n", output_vector.size());
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_number(), bottom of subroutine\n");

    return(output_vector);
}

// convert from (C++ std::vector of numbers) to (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs)))
void XS_pack_arrayref_number(SV* output_avref, arrayref_number input_vector)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_number(), top of subroutine\n");

    AV* output_av = newAV();  // initialize output array to empty
    integer input_vector__length = input_vector.size();
    integer i;
    SV* temp_sv_pointer;

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_number(), have input_vector__length = %"INTEGER"\n", input_vector__length);

    if (input_vector__length > 0) { for (i = 0;  i < input_vector__length;  ++i) { av_push(output_av, newSVnv(input_vector[i])); } }
//  else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_number(), array was empty, returning empty array via newAV()");

    temp_sv_pointer = newSVrv(output_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_avref) = (SV*)output_av;       // make output stack RV point at our output AV

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_number(), bottom of subroutine\n");
}

// convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs))) to (C++ std::vector of std::strings)
arrayref_string XS_unpack_arrayref_string(SV* input_avref)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_string(), top of subroutine\n");
//  arrayref_string_CHECK(input_avref);
    arrayref_string_CHECKTRACE(input_avref, "input_avref", "XS_unpack_arrayref_string()");

    AV* input_av;
    integer input_av__length;
    integer i;
    SV** input_av__element;
    arrayref_string output_vector;

    input_av = (AV*)SvRV(input_avref);
    input_av__length = av_len(input_av) + 1;
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_string(), have input_av__length = %"INTEGER"\n", input_av__length);

    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
    // resize() ahead of time to allow l-value subscript notation
    output_vector.resize((size_t)input_av__length);

    for (i = 0;  i < input_av__length;  ++i)  // incrementing iteration
    {
        // utilizes i in element retrieval
        input_av__element = av_fetch(input_av, i, 0);

        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes i in assignment
        output_vector[i] = SvPV_nolen(*input_av__element);
    }

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_string(), after for() loop, have output_vector.size() = %"INTEGER"\n", output_vector.size());
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_string(), bottom of subroutine\n");

    return(output_vector);
}

// convert from (C++ std::vector of std::strings) to (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs)))
void XS_pack_arrayref_string(SV* output_avref, arrayref_string input_vector)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_string(), top of subroutine\n");

    AV* output_av = newAV();  // initialize output array to empty
    integer input_vector__length = input_vector.size();
    integer i;
    SV* temp_sv_pointer;

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_string(), have input_vector__length = %"INTEGER"\n", input_vector__length);

    if (input_vector__length > 0) { for (i = 0;  i < input_vector__length;  ++i) { av_push(output_av, newSVpv(input_vector[i].data(), input_vector[i].size())); } }
//  else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_string(), array was empty, returning empty array via newAV()");

    temp_sv_pointer = newSVrv(output_avref, NULL);    // upgrade output stack SV to an RV
    SvREFCNT_dec(temp_sv_pointer);       // discard temporary pointer
    SvRV(output_avref) = (SV*)output_av;       // make output stack RV point at our output AV

//  fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_string(), bottom of subroutine\n");
}

# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
SV* arrayref_integer_to_string_compact(SV* input_avref) {
    return arrayref_integer_to_string_format(input_avref, newSViv(-2), newSViv(0));
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
SV* arrayref_integer_to_string(SV* input_avref) {
    return arrayref_integer_to_string_format(input_avref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (pretty), indent level 0
SV* arrayref_integer_to_string_pretty(SV* input_avref) {
    return arrayref_integer_to_string_format(input_avref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (expand), indent level 0
SV* arrayref_integer_to_string_expand(SV* input_avref) {
    return arrayref_integer_to_string_format(input_avref, newSViv(1), newSViv(0));
}

// DEV NOTE: direct manipulation of the Perl Stack shown in /* block comments */
// NEED UPGRADE: use Perl stack manipulation to enable support for variable number of arguments, multiple return values, not setting var to retval in Perl, etc.
// convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs))) to Perl-parsable (Perl SV containing PV)
//void arrayref_integer_to_string_format(SV* input_avref, SV* format_level, SV* indent_level)
SV* arrayref_integer_to_string_format(SV* input_avref, SV* format_level, SV* indent_level)
{
//  Inline_Stack_Vars;
//define Inline_Stack_Vars  dXSARGS  // from INLINE.h
//  dXSARGS;
//  define dXSARGS dSP; dAXMARK; dITEMS  // from XSUB.h
/*  dSP;
   dAXMARK; */
//  dITEMS;

//    fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_to_string(), top of subroutine...\n");
//    fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", SvIV(format_level), SvIV(indent_level));

//  arrayref_integer_CHECK(input_avref);
    arrayref_integer_CHECKTRACE(input_avref, "input_avref", "arrayref_integer_to_string()");

    // declare local variables
    AV* input_av;
    integer input_av__length;
    integer i;
    SV** input_av__element;
    SV* output_sv = newSVpv("", 0);
    boolean i_is_0 = 1;

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // compute length of (number of elements in) input array
    input_av = (AV*)SvRV(input_avref);
    input_av__length = av_len(input_av) + 1;
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_to_string(), have input_av__length = %"INTEGER"\n", input_av__length);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { sv_catsv(output_sv, indent); }

    // begin output string with left-square-bracket, as required for all RPerl arrays
    sv_catpvn(output_sv, "[", 1);

    // loop through all valid values of i for use as index to input array
    for (i = 0;  i < input_av__length;  ++i)
    {
        // utilizes i in element retrieval
        input_av__element = av_fetch(input_av, i, 0);
        // DEV NOTE: integer type-checking already done as part of arrayref_integer_CHECKTRACE()
//      integer_CHECK(*input_av__element);
//      integer_CHECKTRACE(*input_av__element, (char*)((string)"*input_av__element at index " + to_string(i)).c_str(), "arrayref_integer_to_string()");

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { sv_catpvn(output_sv, ",", 1); }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }
        else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

//      sv_catpvf(output_sv, "%"INTEGER"", (integer)SvIV(*input_av__element));  // NO UNDERSCORES
        sv_catsv(output_sv, integer_to_string(*input_av__element));  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }
    else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

    // end output string with right-square-bracket, as required for all RPerl arrays
    sv_catpvn(output_sv, "]", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_to_string(), bottom of subroutine\n");

//  Inline_Stack_Reset;
//define Inline_Stack_Reset      sp = mark  // from INLINE.h
/*  sp = mark; */

//  Inline_Stack_Push(sv_2mortal(output_sv));
//define Inline_Stack_Push(x)   XPUSHs(x)  // from INLINE.h
/*  XPUSHs(sv_2mortal(output_sv));  // mortalize because we created output_sv with newSV() in this function */
    return(output_sv);

//  Inline_Stack_Done;
//define Inline_Stack_Done  PUTBACK  // from INLINE.h
//  PUTBACK;

//  Inline_Stack_Return(1);
//define Inline_Stack_Return(x) XSRETURN(x)  // from INLINE.h
//  XSRETURN(1);
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
SV* arrayref_number_to_string_compact(SV* input_avref) {
    return arrayref_number_to_string_format(input_avref, newSViv(-2), newSViv(0));
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
SV* arrayref_number_to_string(SV* input_avref) {
    return arrayref_number_to_string_format(input_avref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (pretty), indent level 0
SV* arrayref_number_to_string_pretty(SV* input_avref) {
    return arrayref_number_to_string_format(input_avref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (expand), indent level 0
SV* arrayref_number_to_string_expand(SV* input_avref) {
    return arrayref_number_to_string_format(input_avref, newSViv(1), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs))) to Perl-parsable (Perl SV containing PV)
SV* arrayref_number_to_string_format(SV* input_avref, SV* format_level, SV* indent_level)
{
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_number_to_string(), top of subroutine\n");
//  arrayref_number_CHECK(input_avref);
    arrayref_number_CHECKTRACE(input_avref, "input_avref", "arrayref_number_to_string()");

    // declare local variables
    AV* input_av;
    integer input_av__length;
    integer i;
    SV** input_av__element;
    SV* output_sv = newSVpv("", 0);
    boolean i_is_0 = 1;

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

    // NEED ANSWER: do we actually need to be using ostringstream here for precision, since the actual numbers are being stringified by number_to_string() below???
    ostringstream temp_stream;
    temp_stream.precision(std::numeric_limits<double>::digits10);

    // compute length of (number of elements in) input array
    input_av = (AV*)SvRV(input_avref);
    input_av__length = av_len(input_av) + 1;
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_number_to_string(), have input_av__length = %"INTEGER"\n", input_av__length);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { temp_stream << SvPV_nolen(indent); }

    // begin output string with left-square-bracket, as required for all RPerl arrays
//    sv_catpvn(output_sv, "[", 1);
    temp_stream << "[";

    // loop through all valid values of i for use as index to input array
    for (i = 0;  i < input_av__length;  ++i)
    {
        // utilizes i in element retrieval
        input_av__element = av_fetch(input_av, i, 0);

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
//        else        { sv_catpvn(output_sv, ",", 1); }
        else        { temp_stream << ","; }

        // append newline-indent-tab or space, depending on format level
//        if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }
//        else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }
        if      (SvIV(format_level) >=  1) { temp_stream << "\n" << SvPV_nolen(indent) << "    "; }
        else if (SvIV(format_level) >= -1) { temp_stream << " "; }

        temp_stream << (string)SvPV_nolen(number_to_string(*input_av__element));
//      sv_catpvf(output_sv, "%"NUMBER"", (number)SvNV(*input_av__element));  // NEED ANSWER: can we make fprintf(stderr, )-like %"NUMBER" (AKA %Lf or %f) act like ostringstream's precision?  probably not...
    }

    // append newline-indent or space, depending on format level
//    if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }
//    else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }
    if      (SvIV(format_level) >=  1) { temp_stream << "\n" << SvPV_nolen(indent); }
    else if (SvIV(format_level) >= -1) { temp_stream << " "; }

    // end output string with right-square-bracket, as required for all RPerl arrays
    temp_stream << "]";
    sv_setpv(output_sv, (char *)(temp_stream.str().c_str()));
//  sv_catpvn(output_sv, "]", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_number_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_number_to_string(), bottom of subroutine\n");

    return(output_sv);
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
SV* arrayref_string_to_string_compact(SV* input_avref) {
    return arrayref_string_to_string_format(input_avref, newSViv(-2), newSViv(0));
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
SV* arrayref_string_to_string(SV* input_avref) {
    return arrayref_string_to_string_format(input_avref, newSViv(-1), newSViv(0));
}

// call actual stringify routine, format level 0 (pretty), indent level 0
SV* arrayref_string_to_string_pretty(SV* input_avref) {
    return arrayref_string_to_string_format(input_avref, newSViv(0), newSViv(0));
}

// call actual stringify routine, format level 1 (expand), indent level 0
SV* arrayref_string_to_string_expand(SV* input_avref) {
    return arrayref_string_to_string_format(input_avref, newSViv(1), newSViv(0));
}

// convert from (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs))) to Perl-parsable (Perl SV containing PV)
SV* arrayref_string_to_string_format(SV* input_avref, SV* format_level, SV* indent_level)
{
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_string_to_string(), top of subroutine\n");
//  arrayref_string_CHECK(input_avref);
    arrayref_string_CHECKTRACE(input_avref, "input_avref", "arrayref_string_to_string()");

    // declare local variables
    AV* input_av;
    integer input_av__length;
    integer i;
    SV** input_av__element;
    string input_av__element_string;
    size_t input_av__element_string_pos;
    SV* output_sv = newSV(0);
    boolean i_is_0 = 1;

    // generate indent
    SV* indent = newSVpv("", 0);
    for (i = 0; i < SvIV(indent_level); i++) { sv_catpvn(indent, "    ", 4); }

//  ostringstream temp_stream;

    // compute length of (number of elements in) input array
    input_av = (AV*)SvRV(input_avref);
    input_av__length = av_len(input_av) + 1;
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_string_to_string(), have input_av__length = %"INTEGER"\n", input_av__length);

    // pre-begin with optional indent, depending on format level
    if (SvIV(format_level) >= 1) { sv_catsv(output_sv, indent); }

    // begin output string with left-square-bracket, as required for all RPerl arrays
//  temp_stream << "[";
    sv_setpvn(output_sv, "[", 1);

    // loop through all valid values of i for use as index to input array
    for (i = 0;  i < input_av__length;  ++i)
    {
        // utilizes i in element retrieval
        input_av__element = av_fetch(input_av, i, 0);

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
//        else        { temp_stream << ","; }
        else        { sv_catpvn(output_sv, ",", 1); }

        // append newline-indent-tab or space, depending on format level
        if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent);  sv_catpvn(output_sv, "    ", 4); }
        else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

        // escape all back-slash \ and single-quote ' characters with a back-slash \ character
        input_av__element_string = string(SvPV_nolen(*input_av__element));
        input_av__element_string_pos = 0;
        while((input_av__element_string_pos = input_av__element_string.find("\\", input_av__element_string_pos)) != string::npos)
        {
            input_av__element_string.replace(input_av__element_string_pos, 1, "\\\\");
            input_av__element_string_pos += 2;
        }
        input_av__element_string_pos = 0;
        while((input_av__element_string_pos = input_av__element_string.find("'", input_av__element_string_pos)) != string::npos)
        {
            input_av__element_string.replace(input_av__element_string_pos, 1, "\\'");
            input_av__element_string_pos += 2;
        }

//      temp_stream << "'" << SvPV_nolen(*input_av__element) << "'";
//      sv_catpvf(output_sv, "'%s'", SvPV_nolen(*input_av__element));
        sv_catpvf(output_sv, "'%s'", input_av__element_string.c_str());
    }

    // append newline-indent or space, depending on format level
//    if      (SvIV(format_level) >=  1) { temp_stream << "\n" << SvPV_nolen(indent); }
//    else if (SvIV(format_level) >= -1) { temp_stream << " "; }
    if      (SvIV(format_level) >=  1) { sv_catpvn(output_sv, "\n", 1);  sv_catsv(output_sv, indent); }
    else if (SvIV(format_level) >= -1) { sv_catpvn(output_sv, " ", 1); }

    // end output string with right-square-bracket, as required for all RPerl arrays
//  temp_stream << "]";
//  sv_setpv(output_sv, (char *)(temp_stream.str().c_str()));
    sv_catpvn(output_sv, "]", 1);

//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_string_to_string(), after for() loop, have output_sv =\n%s\n", SvPV_nolen(output_sv));
//  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_string_to_string(), bottom of subroutine\n");

    return(output_sv);
}

# elif defined __CPP__TYPES

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
string arrayref_integer_to_string_compact(arrayref_integer input_vector)
{
    return arrayref_integer_to_string_format(input_vector, -2, 0);
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
string arrayref_integer_to_string(arrayref_integer input_vector)
{
    return arrayref_integer_to_string_format(input_vector, -1, 0);
}

// call actual stringify routine, format level 0 (pretty), indent level 0
string arrayref_integer_to_string_pretty(arrayref_integer input_vector)
{
    return arrayref_integer_to_string_format(input_vector, 0, 0);
}

// call actual stringify routine, format level 1 (expand), indent level 0
string arrayref_integer_to_string_expand(arrayref_integer input_vector)
{
    return arrayref_integer_to_string_format(input_vector, 1, 0);
}

// convert from (C++ std::vector of integers) to Perl-parsable (C++ std::string)
string arrayref_integer_to_string_format(arrayref_integer input_vector, integer format_level, integer indent_level)
{
//    fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_integer_to_string(), top of subroutine...\n");
//    fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_integer_to_string(), received format_level = %"INTEGER", indent_level = %"INTEGER"\n", format_level, indent_level);

    // declare local variables
    ostringstream output_stream;
    integer input_vector__length = input_vector.size();  // compute length of (number of elements in) input array
    integer i;
    integer input_vector__element;
    boolean i_is_0 = 1;

    // generate indent
    string indent = "";
    for (i = 0; i < indent_level; i++) { indent += "    "; }

//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_integer_to_string(), have input_vector__length = %"INTEGER"\n", input_vector__length);

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_stream << indent; }

    // begin output string with left-square-bracket, as required for all RPerl arrays
    output_stream << '[';

    // loop through all valid values of i for use as index to input array
    for (i = 0;  i < input_vector__length;  ++i)
    {
        // utilizes i in element retrieval
        input_vector__element = input_vector[i];

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_stream << ','; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >=  1) { output_stream << endl << indent << "    "; }
        else if (format_level >= -1) { output_stream << ' '; }

//      output_stream << input_vector__element;  // NO UNDERSCORES
        output_stream << integer_to_string(input_vector__element);  // YES UNDERSCORES
    }

    // append newline-indent or space, depending on format level
    if      (format_level >=  1) { output_stream << endl << indent; }
    else if (format_level >= -1) { output_stream << ' '; }

    // end output string with right-square-bracket, as required for all RPerl arrays
    output_stream << ']';

//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_integer_to_string(), after for() loop, have output_stream =\n%s\n", (char *)(output_stream.str().c_str()));
//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_integer_to_string(), bottom of subroutine\n");

    return(output_stream.str());
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
string arrayref_number_to_string_compact(arrayref_number input_vector)
{
    return arrayref_number_to_string_format(input_vector, -2, 0);
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
string arrayref_number_to_string(arrayref_number input_vector)
{
    return arrayref_number_to_string_format(input_vector, -1, 0);
}

// call actual stringify routine, format level 0 (pretty), indent level 0
string arrayref_number_to_string_pretty(arrayref_number input_vector)
{
    return arrayref_number_to_string_format(input_vector, 0, 0);
}

// call actual stringify routine, format level 1 (expand), indent level 0
string arrayref_number_to_string_expand(arrayref_number input_vector)
{
    return arrayref_number_to_string_format(input_vector, 1, 0);
}

// convert from (C++ std::vector of numbers) to Perl-parsable (C++ std::string)
string arrayref_number_to_string_format(arrayref_number input_vector, integer format_level, integer indent_level)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_number_to_string(), top of subroutine\n");

    // declare local variables
    ostringstream output_stream;
    integer input_vector__length = input_vector.size();  // compute length of (number of elements in) input array
    integer i;
    number input_vector__element;
    boolean i_is_0 = 1;

    // generate indent
    string indent = "";
    for (i = 0; i < indent_level; i++) { indent += "    "; }

//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_number_to_string(), have input_vector__length = %"INTEGER"\n", input_vector__length);

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_stream << indent; }

    // NEED ANSWER: do we actually need to be using ostringstream here for precision, since the actual numbers are being stringified by number_to_string() below???
    output_stream.precision(std::numeric_limits<double>::digits10);

    // begin output string with left-square-bracket, as required for all RPerl arrays
    output_stream << '[';

    // loop through all valid values of i for use as index to input array
    for (i = 0;  i < input_vector__length;  ++i)
    {
        // utilizes i in element retrieval
        input_vector__element = input_vector[i];

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
        else        { output_stream << ','; }

        // append newline-indent-tab or space, depending on format level
        if      (format_level >=  1) { output_stream << endl << indent << "    "; }
        else if (format_level >= -1) { output_stream << ' '; }

//      output_stream << input_vector__element;
        output_stream << number_to_string(input_vector__element);
    }

    // append newline-indent or space, depending on format level
    if      (format_level >=  1) { output_stream << endl << indent; }
    else if (format_level >= -1) { output_stream << ' '; }

    // end output string with right-square-bracket, as required for all RPerl arrays
    output_stream << ']';

//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_number_to_string(), after for() loop, have output_stream =\n%s\n", (char *)(output_stream.str().c_str()));
//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_number_to_string(), bottom of subroutine\n");

    return(output_stream.str());
}

// DEV NOTE: 1-D format levels are 1 less than 2-D format levels

// call actual stringify routine, format level -2 (compact), indent level 0
string arrayref_string_to_string_compact(arrayref_string input_vector)
{
    return arrayref_string_to_string_format(input_vector, -2, 0);
}

// call actual stringify routine, format level -1 (normal), indent level 0, DEFAULT
string arrayref_string_to_string(arrayref_string input_vector)
{
    return arrayref_string_to_string_format(input_vector, -1, 0);
}

// call actual stringify routine, format level 0 (pretty), indent level 0
string arrayref_string_to_string_pretty(arrayref_string input_vector)
{
    return arrayref_string_to_string_format(input_vector, 0, 0);
}

// call actual stringify routine, format level 1 (expand), indent level 0
string arrayref_string_to_string_expand(arrayref_string input_vector)
{
    return arrayref_string_to_string_format(input_vector, 1, 0);
}

// convert from (C++ std::vector of std::strings) to Perl-parsable (C++ std::string)
string arrayref_string_to_string_format(arrayref_string input_vector, integer format_level, integer indent_level)
{
//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_string_to_string(), top of subroutine\n");

    // declare local variables
//  ostringstream output_stream;
    string output_string = "";
    integer input_vector__length = input_vector.size();  // compute length of (number of elements in) input array
    integer i;
    string input_vector__element;
    size_t input_vector__element_pos;
    boolean i_is_0 = 1;

    // generate indent
    string indent = "";
    for (i = 0; i < indent_level; i++) { indent += "    "; }

//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_string_to_string(), have input_vector__length = %"INTEGER"\n", input_vector__length);

    // pre-begin with optional indent, depending on format level
    if (format_level >= 1) { output_string += indent; }

    // begin output string with left-square-bracket, as required for all RPerl arrays
//  output_stream << '[';
    output_string += "[";

    // loop through all valid values of i for use as index to input array
    for (i = 0;  i < input_vector__length;  ++i)
    {
        // utilizes i in element retrieval
        input_vector__element = input_vector[i];

        // append comma to output string for all elements except index 0
        if (i_is_0) { i_is_0 = 0; }
//      else        { output_stream << ','; }
        else        { output_string += ','; }

        // append newline-indent-tab or space, depending on format level
//      if      (format_level >=  1) { output_stream << endl << indent << "    "; }
//      else if (format_level >= -1) { output_stream << ' '; }
        if      (format_level >=  1) { output_string += "\n" + indent + "    "; }
        else if (format_level >= -1) { output_string += " "; }

        // escape all back-slash \ and single-quote ' characters with a back-slash \ character
        input_vector__element_pos = 0;
        while((input_vector__element_pos = input_vector__element.find("\\", input_vector__element_pos)) != string::npos)
        {
            input_vector__element.replace(input_vector__element_pos, 1, "\\\\");
            input_vector__element_pos += 2;
        }
        input_vector__element_pos = 0;
        while((input_vector__element_pos = input_vector__element.find("'", input_vector__element_pos)) != string::npos)
        {
            input_vector__element.replace(input_vector__element_pos, 1, "\\'");
            input_vector__element_pos += 2;
        }

//      output_stream <<  "'" << input_vector__element << "'";
        output_string += "'" + input_vector__element + "'";
    }

    // append newline-indent or space, depending on format level
//  if      (format_level >=  1) { output_stream << endl << indent; }
//  else if (format_level >= -1) { output_stream << ' '; }
    if      (format_level >=  1) { output_string += "\n" + indent; }
    else if (format_level >= -1) { output_string += " "; }

    // end output string with right-square-bracket, as required for all RPerl arrays
//  output_stream << ']';
    output_string += "]";

//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_string_to_string(), after for() loop, have output_stream =\n%s\n", (char *)(output_stream.str().c_str()));
//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_string_to_string(), after for() loop, have output_string =\n%s\n", output_string.c_str());
//  fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_string_to_string(), bottom of subroutine\n");

//  return(output_stream.str());
    return(output_string);
}

# else

Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!

# endif

// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES

// DEV NOTE: direct manipulation of the Perl Stack shown in /* block comments */
/*void arrayref_integer_typetest0(SV* lucky_integers) */
SV* arrayref_integer_typetest0(SV* lucky_integers)
{
/*  dSP; */

/*  SV* output_sv; */
//  arrayref_integer_CHECK(lucky_integers);
    arrayref_integer_CHECKTRACE(lucky_integers, "lucky_integers", "arrayref_integer_typetest0()");
//  AV* lucky_integers_deref = (AV*)SvRV(lucky_integers);
//  integer how_lucky = av_len(lucky_integers_deref) + 1;
//  integer i;

//  for (i = 0;  i < how_lucky;  ++i)
//  {
//      fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_typetest0(), have lucky integer %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAT\n", i, (how_lucky - 1), (integer)SvIV(*av_fetch(lucky_integers_deref, i, 0)));
//  }

//  ENTER;
//  SAVETMPS;
/*  arrayref_integer_to_string(lucky_integers); */
/*  output_sv = arrayref_integer_to_string(lucky_integers); */
//  SPAGAIN;

/*  output_sv = POPs; */
//  PUTBACK;

//  FREETMPS;
//  LEAVE;

/*  sv_catpv(output_sv, "BARBAT"); */
/*  fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_typetest0(), have output_sv = %s\n", SvPV_nolen(output_sv)); */

/*
//  SPAGAIN;
//  PUSHMARK(SP);
   XPUSHs(output_sv);  // do not mortalize because we receive value for output_sv from outside this function
//  PUTBACK;
*/
//  SvREFCNT_inc(output_sv);
/*  return(output_sv);  // do not mortalize because we receive value for output_sv from outside this function */
    return(newSVpvf("%s%s", SvPV_nolen(arrayref_integer_to_string(lucky_integers)), "CPPOPS_PERLTYPES"));
}

// DEV NOTE: direct manipulation of the Perl Stack shown in /* block comments */
/*void arrayref_integer_typetest1(integer my_size) */
SV* arrayref_integer_typetest1(SV* my_size)
{
/*  dSP;
   dAXMARK; */

//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "arrayref_integer_typetest1()");
    AV* output_av = newAV();
    integer i;

    av_extend(output_av, (I32)(SvIV(my_size) - 1));

    for (i = 0;  i < SvIV(my_size);  ++i)
    {
        av_store(output_av, (I32)i, newSViv(i * 5));
//      fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_integer_typetest1(), setting element %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAT\n", i, (integer)(SvIV(my_size) - 1), (integer)SvIV(*av_fetch(output_av, (I32)i, 0)));
    }

/*
   sp = mark;
   XPUSHs(sv_2mortal(newRV_noinc((SV*) output_av)));  // do mortalize because we create output_av with newAV() in this function
*/
    return(newRV_noinc((SV*) output_av));
}

SV* arrayref_number_typetest0(SV* lucky_numbers)
{
//  arrayref_number_CHECK(lucky_numbers);
    arrayref_number_CHECKTRACE(lucky_numbers, "lucky_numbers", "arrayref_number_typetest0()");

/*
    AV* lucky_numbers_deref = (AV*)SvRV(lucky_numbers);
    integer how_lucky = av_len(lucky_numbers_deref) + 1;
    integer i;

    for (i = 0;  i < how_lucky;  ++i)
    {
        number_CHECK(*av_fetch(lucky_numbers_deref, i, 0));
        number_CHECKTRACE(*av_fetch(lucky_numbers_deref, i, 0), (char*)((string)"*av_fetch(lucky_numbers_deref, i, 0) at index " + to_string(i)).c_str(), "arrayref_number_typetest0()");
        fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_number_typetest0(), have lucky number %"INTEGER"/%"INTEGER" = %"NUMBER", BARBAT\n", i, (how_lucky - 1), (number)SvNV(*av_fetch(lucky_numbers_deref, i, 0)));
    }
*/
    return(newSVpvf("%s%s", SvPV_nolen(arrayref_number_to_string(lucky_numbers)), "CPPOPS_PERLTYPES"));
}

SV* arrayref_number_typetest1(SV* my_size)
{
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "arrayref_number_typetest1()");
    AV* output_av = newAV();
    integer i;
    av_extend(output_av, (I32)(SvIV(my_size) - 1));
    for (i = 0;  i < SvIV(my_size);  ++i)
    {
        av_store(output_av, (I32)i, newSVnv(i * 5.123456789));
//      fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_number_typetest1(), setting element %"INTEGER"/%"INTEGER" = %"NUMBER", BARBAT\n", i, (integer)(SvIV(my_size) - 1), (number)SvNV(*av_fetch(output_av, (I32)i, 0)));
    }
    return(newRV_noinc((SV*) output_av));
}

SV* arrayref_string_typetest0(SV* people)
{
//  arrayref_string_CHECK(people);
    arrayref_string_CHECKTRACE(people, "people", "arrayref_string_typetest0()");

/*
    AV* people_deref = (AV*)SvRV(people);
    integer i;
    for (i = 0;  i < (av_len(people_deref) + 1);  ++i)
    {
        string_CHECK(*av_fetch(people_deref, i, 0));
        string_CHECKTRACE(*av_fetch(people_deref, i, 0), (char*)((string)"*av_fetch(people_deref, i, 0) at index " + to_string(i)).c_str(), "arrayref_string_typetest0()");
        fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_string_typetest0(), have person %"INTEGER" = '%s', BARBAR\n", i, (char *)SvPV_nolen(*av_fetch(people_deref, i, 0)));
    }
*/
    return(newSVpvf("%s%s", SvPV_nolen(arrayref_string_to_string(people)), "CPPOPS_PERLTYPES"));
}

SV* arrayref_string_typetest1(SV* my_size)
{
//  integer_CHECK(my_size);
    integer_CHECKTRACE(my_size, "my_size", "arrayref_string_typetest1()");
    AV* people = newAV();
    integer i;
    av_extend(people, (I32)(SvIV(my_size) - 1));
    for (i = 0;  i < SvIV(my_size);  ++i)
    {
        av_store(people, (I32)i, newSVpvf("Jeffy Ten! %"INTEGER"/%"INTEGER" CPPOPS_PERLTYPES", i, (integer)(SvIV(my_size) - 1)));
//      fprintf(stderr, "in CPPOPS_PERLTYPES arrayref_string_typetest1(), bottom of for() loop, have i = %"INTEGER", (integer)(SvIV(my_size) - 1) = %"INTEGER", just set another Jeffy, BARBAR\n", i, (integer)(SvIV(my_size) - 1));
    }
    return(newRV_noinc((SV*) people));
}

# elif defined __CPP__TYPES

string arrayref_integer_typetest0(arrayref_integer lucky_integers)
{
/*
    integer how_lucky = lucky_integers.size();
    integer i;
    for (i = 0;  i < how_lucky;  ++i)
    {
        fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_integer_typetest0(), have lucky number %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAT\n", i, (how_lucky - 1), lucky_integers[i]);
    }
*/
    return(arrayref_integer_to_string(lucky_integers) + "CPPOPS_CPPTYPES");
}

arrayref_integer arrayref_integer_typetest1(integer my_size)
{
    arrayref_integer new_vec(my_size);
    integer i;
    for (i = 0;  i < my_size;  ++i) {
        new_vec[i] = i * 5;
//      fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_integer_typetest1(), setting element %"INTEGER"/%"INTEGER" = %"INTEGER", BARBAT\n", i, (my_size - 1), new_vec[i]);
    }
    return(new_vec);
}

string arrayref_number_typetest0(arrayref_number lucky_numbers)
{
/*
    integer how_lucky = lucky_numbers.size();
    integer i;
    for (i = 0;  i < how_lucky;  ++i)
    {
        fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_number_typetest0(), have lucky number %"INTEGER"/%"INTEGER" = %"NUMBER", BARBAZ\n", i, (how_lucky - 1), lucky_numbers[i]);
    }
*/
    return(arrayref_number_to_string(lucky_numbers) + "CPPOPS_CPPTYPES");
}
arrayref_number arrayref_number_typetest1(integer my_size)
{
    arrayref_number new_vec(my_size);
    integer i;
    for (i = 0;  i < my_size;  ++i)
    {
        new_vec[i] = i * 5.123456789;
//      fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_number_typetest1(), setting element %"INTEGER"/%"INTEGER" = %"NUMBER", BARBAZ\n", i, (my_size - 1), new_vec[i]);
    }
    return(new_vec);
}

//string arrayref_string_typetest0(arrayref_string people) { integer i;  for (i = 0;  i < people.size();  ++i) { fprintf(stderr, "in CPPOPS_CPPTYPES fprintf(stderr, ) arrayref_string_typetest0(), have person %"INTEGER" = '%s', BARBAR\n", i, people[i].c_str()); }  return(arrayref_string_to_string(people) + "BARBAR"); }
string arrayref_string_typetest0(arrayref_string people)
{
/*
    integer i;
    for (i = 0;  i < people.size();  ++i)
    {
        cout << "in CPPOPS_CPPTYPES arrayref_string_typetest0(), have person " << i << " = '" << people[i] << "', BARBAR\n";
    }
*/
    return(arrayref_string_to_string(people) + "CPPOPS_CPPTYPES");
}

arrayref_string arrayref_string_typetest1(integer my_size)
{
    arrayref_string people;
    integer i;
    people.resize((size_t)my_size);
    for (i = 0;  i < my_size;  ++i)
    {
        people[i] = "Jeffy Ten! " + std::to_string(i) + "/" + std::to_string(my_size - 1) + " CPPOPS_CPPTYPES";
//      fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_string_typetest1(), bottom of for() loop, have i = %"INTEGER", (my_size - 1) = %"INTEGER", just set another Jeffy, BARBAR\n", i, (my_size - 1));
    }
    return(people);
}

# endif

#endif
