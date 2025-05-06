using std::cout;  using std::cerr;  using std::endl;  using std::to_string;

#ifndef __CPP__INCLUDED__Perl__Structure__Array__SubTypes2D_cpp
#define __CPP__INCLUDED__Perl__Structure__Array__SubTypes2D_cpp 0.006_000

#include <Perl/Structure/Array/SubTypes2D.h>  // -> ??? (relies on <vector> being included via Inline::CPP's AUTO_INCLUDE config option in RPerl/Inline.pm)

// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]
// [[[ TYPE-CHECKING ]]]

void arrayref_arrayref_integer_CHECK(SV* possible_arrayref_arrayref_integer)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_integer_CHECK(), top of subroutine\n");

    if ( not( SvOK(possible_arrayref_arrayref_integer) ) ) { croak( "\nERROR EAVRVAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_integer value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvAROKp(possible_arrayref_arrayref_integer) ) ) { croak( "\nERROR EAVRVAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_integer value expected but non-arrayref value found,\ncroaking" ); }

    AV* possible_array_arrayref_integer;

    integer possible_array_arrayref_integer__length;
    integer i;
    SV** possible_array_arrayref_integer__element;

    possible_array_arrayref_integer = (AV*)SvRV(possible_arrayref_arrayref_integer);
	possible_array_arrayref_integer__length = av_len(possible_array_arrayref_integer) + 1;

	for (i = 0;  i < possible_array_arrayref_integer__length;  ++i)  // incrementing iteration
	{
		possible_array_arrayref_integer__element = av_fetch(possible_array_arrayref_integer, i, 0);
		if ( not( SvOK(*possible_array_arrayref_integer__element) ) ) { croak( "\nERROR EAVRVAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found at index %"INTEGER",\ncroaking", i ); }
		if ( not( SvAROKp(*possible_array_arrayref_integer__element) ) ) { croak( "\nERROR EAVRVAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found at index %"INTEGER",\ncroaking", i ); }

		SV* possible_arrayref_integer = *possible_array_arrayref_integer__element;

	    AV* possible_array_integer;
	    integer possible_array_integer__length;
	    integer j;
	    SV** possible_array_integer__element;

	    possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
	    possible_array_integer__length = av_len(possible_array_integer) + 1;

	    for (j = 0;  j < possible_array_integer__length;  ++j)  // incrementing iteration
	    {
	        possible_array_integer__element = av_fetch(possible_array_integer, j, 0);
	        if (not(SvOK(*possible_array_integer__element))) { croak("\nERROR EAVRVAVRVIV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at index (%"INTEGER", %"INTEGER"),\ncroaking", i, j); }
	        if (not(SvIOKp(*possible_array_integer__element))) { croak("\nERROR EAVRVAVRVIV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index (%"INTEGER", %"INTEGER"),\ncroaking", i, j); }
	    }
	}
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_integer_CHECK(), bottom of subroutine\n");
}

void arrayref_arrayref_integer_CHECKTRACE(SV* possible_arrayref_arrayref_integer, const char* variable_name, const char* subroutine_name)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_integer_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_integer_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    if ( not( SvOK(possible_arrayref_arrayref_integer) ) ) { croak( "\nERROR EAVRVAVRVIV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_integer value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvAROKp(possible_arrayref_arrayref_integer) ) ) { croak( "\nERROR EAVRVAVRVIV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_integer value expected but non-arrayref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    AV* possible_array_arrayref_integer;
    integer possible_array_arrayref_integer__length;
    integer i;
    SV** possible_array_arrayref_integer__element;

    possible_array_arrayref_integer = (AV*)SvRV(possible_arrayref_arrayref_integer);
    possible_array_arrayref_integer__length = av_len(possible_array_arrayref_integer) + 1;

    for (i = 0;  i < possible_array_arrayref_integer__length;  ++i)  // incrementing iteration
    {
        possible_array_arrayref_integer__element = av_fetch(possible_array_arrayref_integer, i, 0);
        if ( not( SvOK(*possible_array_arrayref_integer__element) ) ) { croak( "\nERROR EAVRVAVRVIV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but undefined/null value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name ); }
        if ( not( SvAROKp(*possible_array_arrayref_integer__element) ) ) { croak( "\nERROR EAVRVAVRVIV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_integer value expected but non-arrayref value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name ); }

        SV* possible_arrayref_integer = *possible_array_arrayref_integer__element;

        AV* possible_array_integer;
        integer possible_array_integer__length;
        integer j;
        SV** possible_array_integer__element;

        possible_array_integer = (AV*)SvRV(possible_arrayref_integer);
        possible_array_integer__length = av_len(possible_array_integer) + 1;

        for (j = 0;  j < possible_array_integer__length;  ++j)  // incrementing iteration
        {
            possible_array_integer__element = av_fetch(possible_array_integer, j, 0);
            if (not(SvOK(*possible_array_integer__element))) { croak("\nERROR EAVRVAVRVIV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but undefined/null value found at index (%"INTEGER", %"INTEGER"),\nin variable %s from subroutine %s,\ncroaking", i, j, variable_name, subroutine_name ); }
            if (not(SvIOKp(*possible_array_integer__element))) { croak("\nERROR EAVRVAVRVIV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ninteger value expected but non-integer value found at index (%"INTEGER", %"INTEGER"),\nin variable %s from subroutine %s,\ncroaking", i, j, variable_name, subroutine_name ); }
        }
    }
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_integer_CHECKTRACE(), bottom of subroutine\n");
}


void arrayref_arrayref_number_CHECK(SV* possible_arrayref_arrayref_number)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_number_CHECK(), top of subroutine\n");

    if ( not( SvOK(possible_arrayref_arrayref_number) ) ) { croak( "\nERROR EAVRVAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_number value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvAROKp(possible_arrayref_arrayref_number) ) ) { croak( "\nERROR EAVRVAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_number value expected but non-arrayref value found,\ncroaking" ); }

    AV* possible_array_arrayref_number;
    integer possible_array_arrayref_number__length;
    integer i;
    SV** possible_array_arrayref_number__element;

    possible_array_arrayref_number = (AV*)SvRV(possible_arrayref_arrayref_number);
	possible_array_arrayref_number__length = av_len(possible_array_arrayref_number) + 1;

	for (i = 0;  i < possible_array_arrayref_number__length;  ++i)  // incrementing iteration
	{
		possible_array_arrayref_number__element = av_fetch(possible_array_arrayref_number, i, 0);
		if ( not( SvOK(*possible_array_arrayref_number__element) ) ) { croak( "\nERROR EAVRVAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found at index %"INTEGER",\ncroaking", i ); }
		if ( not( SvAROKp(*possible_array_arrayref_number__element) ) ) { croak( "\nERROR EAVRVAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found at index %"INTEGER",\ncroaking", i ); }

		SV* possible_arrayref_number = *possible_array_arrayref_number__element;

	    AV* possible_array_number;
	    integer possible_array_number__length;
	    integer j;
	    SV** possible_array_number__element;

	    possible_array_number = (AV*)SvRV(possible_arrayref_number);
	    possible_array_number__length = av_len(possible_array_number) + 1;

	    for (j = 0;  j < possible_array_number__length;  ++j)  // incrementing iteration
	    {
	        possible_array_number__element = av_fetch(possible_array_number, j, 0);
	        if (not(SvOK(*possible_array_number__element))) { croak("\nERROR EAVRVAVRVNV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index (%"INTEGER", %"INTEGER"),\ncroaking", i, j); }
	        if (not(SvNOKp(*possible_array_number__element))) { croak("\nERROR EAVRVAVRVNV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index (%"INTEGER", %"INTEGER"),\ncroaking", i, j); }
	    }
	}
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_number_CHECK(), bottom of subroutine\n");
}

void arrayref_arrayref_number_CHECKTRACE(SV* possible_arrayref_arrayref_number, const char* variable_name, const char* subroutine_name)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_number_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_number_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    if ( not( SvOK(possible_arrayref_arrayref_number) ) ) { croak( "\nERROR EAVRVAVRVNV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_number value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvAROKp(possible_arrayref_arrayref_number) ) ) { croak( "\nERROR EAVRVAVRVNV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_number value expected but non-arrayref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    AV* possible_array_arrayref_number;
    integer possible_array_arrayref_number__length;
    integer i;
    SV** possible_array_arrayref_number__element;

    possible_array_arrayref_number = (AV*)SvRV(possible_arrayref_arrayref_number);
    possible_array_arrayref_number__length = av_len(possible_array_arrayref_number) + 1;

    for (i = 0;  i < possible_array_arrayref_number__length;  ++i)  // incrementing iteration
    {
        possible_array_arrayref_number__element = av_fetch(possible_array_arrayref_number, i, 0);
        if ( not( SvOK(*possible_array_arrayref_number__element) ) ) { croak( "\nERROR EAVRVAVRVNV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but undefined/null value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name ); }
        if ( not( SvAROKp(*possible_array_arrayref_number__element) ) ) { croak( "\nERROR EAVRVAVRVNV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_number value expected but non-arrayref value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name ); }

        SV* possible_arrayref_number = *possible_array_arrayref_number__element;

        AV* possible_array_number;
        integer possible_array_number__length;
        integer j;
        SV** possible_array_number__element;

        possible_array_number = (AV*)SvRV(possible_arrayref_number);
        possible_array_number__length = av_len(possible_array_number) + 1;

        for (j = 0;  j < possible_array_number__length;  ++j)  // incrementing iteration
        {
            possible_array_number__element = av_fetch(possible_array_number, j, 0);
            if (not(SvOK(*possible_array_number__element))) { croak("\nERROR EAVRVAVRVNV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but undefined/null value found at index (%"INTEGER", %"INTEGER"),\nin variable %s from subroutine %s,\ncroaking", i, j, variable_name, subroutine_name ); }
            if (not(SvNOKp(*possible_array_number__element))) { croak("\nERROR EAVRVAVRVNV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nnumber value expected but non-number value found at index (%"INTEGER", %"INTEGER"),\nin variable %s from subroutine %s,\ncroaking", i, j, variable_name, subroutine_name ); }
        }
    }
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_number_CHECKTRACE(), bottom of subroutine\n");
}


void arrayref_arrayref_string_CHECK(SV* possible_arrayref_arrayref_string)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_string_CHECK(), top of subroutine\n");

    if ( not( SvOK(possible_arrayref_arrayref_string) ) ) { croak( "\nERROR EAVRVAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_string value expected but undefined/null value found,\ncroaking" ); }
    if ( not( SvAROKp(possible_arrayref_arrayref_string) ) ) { croak( "\nERROR EAVRVAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_string value expected but non-arrayref value found,\ncroaking" ); }

    AV* possible_array_arrayref_string;
    integer possible_array_arrayref_string__length;
    integer i;
    SV** possible_array_arrayref_string__element;

    possible_array_arrayref_string = (AV*)SvRV(possible_arrayref_arrayref_string);
	possible_array_arrayref_string__length = av_len(possible_array_arrayref_string) + 1;

	for (i = 0;  i < possible_array_arrayref_string__length;  ++i)  // incrementing iteration
	{
		possible_array_arrayref_string__element = av_fetch(possible_array_arrayref_string, i, 0);
		if ( not( SvOK(*possible_array_arrayref_string__element) ) ) { croak( "\nERROR EAVRVAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found at index %"INTEGER",\ncroaking", i ); }
		if ( not( SvAROKp(*possible_array_arrayref_string__element) ) ) { croak( "\nERROR EAVRVAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found at index %"INTEGER",\ncroaking", i ); }

		SV* possible_arrayref_string = *possible_array_arrayref_string__element;

	    AV* possible_array_string;
	    integer possible_array_string__length;
	    integer j;
	    SV** possible_array_string__element;

	    possible_array_string = (AV*)SvRV(possible_arrayref_string);
	    possible_array_string__length = av_len(possible_array_string) + 1;

	    for (j = 0;  j < possible_array_string__length;  ++j)  // incrementing iteration
	    {
	        possible_array_string__element = av_fetch(possible_array_string, j, 0);
	        if (not(SvOK(*possible_array_string__element))) { croak("\nERROR EAVRVAVRVPV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index (%"INTEGER", %"INTEGER"),\ncroaking", i, j); }
	        if (not(SvPOKp(*possible_array_string__element))) { croak("\nERROR EAVRVAVRVPV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index (%"INTEGER", %"INTEGER"),\ncroaking", i, j); }
	    }
	}
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_string_CHECK(), bottom of subroutine\n");
}

void arrayref_arrayref_string_CHECKTRACE(SV* possible_arrayref_arrayref_string, const char* variable_name, const char* subroutine_name)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_string_CHECKTRACE(), top of subroutine, received variable_name = %s\n", variable_name);
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_string_CHECKTRACE(), top of subroutine, received subroutine_name = %s\n", subroutine_name);

    if ( not( SvOK(possible_arrayref_arrayref_string) ) ) { croak( "\nERROR EAVRVAVRVPV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_string value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }
    if ( not( SvAROKp(possible_arrayref_arrayref_string) ) ) { croak( "\nERROR EAVRVAVRVPV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_arrayref_string value expected but non-arrayref value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name ); }

    AV* possible_array_arrayref_string;
    integer possible_array_arrayref_string__length;
    integer i;
    SV** possible_array_arrayref_string__element;

    possible_array_arrayref_string = (AV*)SvRV(possible_arrayref_arrayref_string);
    possible_array_arrayref_string__length = av_len(possible_array_arrayref_string) + 1;

    for (i = 0;  i < possible_array_arrayref_string__length;  ++i)  // incrementing iteration
    {
        possible_array_arrayref_string__element = av_fetch(possible_array_arrayref_string, i, 0);
        if ( not( SvOK(*possible_array_arrayref_string__element) ) ) { croak( "\nERROR EAVRVAVRVPV02, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but undefined/null value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name ); }
        if ( not( SvAROKp(*possible_array_arrayref_string__element) ) ) { croak( "\nERROR EAVRVAVRVPV03, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\narrayref_string value expected but non-arrayref value found at index %"INTEGER",\nin variable %s from subroutine %s,\ncroaking", i, variable_name, subroutine_name ); }

        SV* possible_arrayref_string = *possible_array_arrayref_string__element;

        AV* possible_array_string;
        integer possible_array_string__length;
        integer j;
        SV** possible_array_string__element;

        possible_array_string = (AV*)SvRV(possible_arrayref_string);
        possible_array_string__length = av_len(possible_array_string) + 1;

        for (j = 0;  j < possible_array_string__length;  ++j)  // incrementing iteration
        {
            possible_array_string__element = av_fetch(possible_array_string, j, 0);
            if (not(SvOK(*possible_array_string__element))) { croak("\nERROR EAVRVAVRVPV04, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but undefined/null value found at index (%"INTEGER", %"INTEGER"),\nin variable %s from subroutine %s,\ncroaking", i, j, variable_name, subroutine_name ); }
            if (not(SvPOKp(*possible_array_string__element))) { croak("\nERROR EAVRVAVRVPV05, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\nstring value expected but non-string value found at index (%"INTEGER", %"INTEGER"),\nin variable %s from subroutine %s,\ncroaking", i, j, variable_name, subroutine_name ); }
        }
    }
//	fprintf(stderr, "in CPPOPS_CPPTYPES arrayref_arrayref_string_CHECKTRACE(), bottom of subroutine\n");
}

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

# ifdef __CPP__TYPES

// convert from (Perl SV containing RV to (Perl AV of (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs))))) to (C++ std::vector of (C++ std::vector of integers))
arrayref_arrayref_integer XS_unpack_arrayref_arrayref_integer(SV* input_avref_avref)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_integer(), top of subroutine\n");
//	arrayref_arrayref_integer_CHECK(input_avref_avref);
	arrayref_arrayref_integer_CHECKTRACE(input_avref_avref, "input_avref_avref", "XS_unpack_arrayref_arrayref_integer()");

    AV* input_av_avref;
    integer input_av_avref__length;
    integer i;
    SV** input_av_avref__element;
    arrayref_arrayref_integer output_vector_vector;

    input_av_avref = (AV*)SvRV(input_avref_avref);
	input_av_avref__length = av_len(input_av_avref) + 1;
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_integer(), have input_av_avref__length = %"INTEGER"\n", input_av_avref__length);

	// VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
	// resize() ahead of time to allow l-value subscript notation
	output_vector_vector.resize((size_t)input_av_avref__length);

	for (i = 0;  i < input_av_avref__length;  ++i)  // incrementing iteration
	{
	    AV* input_av;
	    integer input_av__length;
	    integer j;
	    SV** input_av__element;
	    arrayref_integer output_vector;

	    // utilizes i in element retrieval
	    input_av_avref__element = av_fetch(input_av_avref, i, 0);

//	    input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_av_avref__element
	    input_av = (AV*)SvRV(*input_av_avref__element);
	    input_av__length = av_len(input_av) + 1;
//	    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_integer(), have input_av__length = %"INTEGER"\n", input_av__length);

	    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
	    // resize() ahead of time to allow l-value subscript notation
	    output_vector.resize((size_t)input_av__length);

	    for (j = 0;  j < input_av__length;  ++j)  // incrementing iteration
	    {
	        // utilizes j in element retrieval
	        input_av__element = av_fetch(input_av, j, 0);

	        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes j in assignment
	        output_vector[j] = SvIV(*input_av__element);
	    }

//	    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_integer(), bottom of outer for() loop i = %"INTEGER", have output_vector.size() = %"INTEGER"\n", i, (integer) output_vector.size());

	    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes i in assignment
	    output_vector_vector[i] = output_vector;
	}

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_integer(), after for() loop, have output_vector_vector.size() = %"INTEGER"\n", (integer) output_vector_vector.size());

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_integer(), bottom of subroutine\n");

	return(output_vector_vector);
}


// convert from (C++ std::vector of (C++ std::vector of integers)) to (Perl SV containing RV to (Perl AV of (Perl SV containing RV to (Perl AV of (Perl SVs containing IVs)))))
void XS_pack_arrayref_arrayref_integer(SV* output_avref_avref, arrayref_arrayref_integer input_vector_vector)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), top of subroutine\n");

	AV* output_av_avref = newAV();  // initialize output array-of-arrays to empty
	integer input_vector_vector__length = input_vector_vector.size();
	integer i;
	SV* temp_sv_pointer;

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), have input_vector_vector__length = %"INTEGER"\n", input_vector_vector__length);

	if (input_vector_vector__length > 0) {
	    for (i = 0;  i < input_vector_vector__length;  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), top of outer loop, have i = %"INTEGER"\n", i);
	        arrayref_integer input_vector = input_vector_vector[i];

	        AV* output_av = newAV();  // initialize output sub-array to empty
	        integer input_vector__length = input_vector.size();
	        integer j;

//	        fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), have input_vector__length = %"INTEGER"\n", input_vector__length);

	        if (input_vector__length > 0) {
	            for (j = 0;  j < input_vector__length;  ++j) {
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), top of inner loop, have (i, j) = (%"INTEGER", %"INTEGER")\n", i, j);
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), have input_vector_vector[%"INTEGER"][%"INTEGER"] = %"INTEGER"\n", i, j, input_vector[j]);
	                av_push(output_av, newSViv(input_vector[j]));
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), bottom of inner loop, have (i, j) = (%"INTEGER", %"INTEGER")\n", i, j);
	            }
	        }
	        else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), sub-array was empty, returning empty sub-array via newAV()");

	        // NEED ANSWER: is it really okay to NOT increase the reference count below???
	        av_push(output_av_avref, newRV_noinc((SV*)output_av));  // reference, do not increase reference count
//	        av_push(output_av_avref, newRV_inc((SV*)output_av));  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), bottom of outer loop, have i = %"INTEGER"\n", i);
	    }
	}
	else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), array was empty, returning empty array via newAV()");

	temp_sv_pointer = newSVrv(output_avref_avref, NULL);	  // upgrade output stack SV to an RV
	SvREFCNT_dec(temp_sv_pointer);		 // discard temporary pointer
	SvRV(output_avref_avref) = (SV*)output_av_avref;	   // make output stack RV point at our output AV

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_integer(), bottom of subroutine\n");
}


// convert from (Perl SV containing RV to (Perl AV of (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs))))) to (C++ std::vector of (C++ std::vector of numbers))
arrayref_arrayref_number XS_unpack_arrayref_arrayref_number(SV* input_avref_avref)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_number(), top of subroutine\n");
//	arrayref_arrayref_number_CHECK(input_avref_avref);
	arrayref_arrayref_number_CHECKTRACE(input_avref_avref, "input_avref_avref", "XS_unpack_arrayref_arrayref_number()");

    AV* input_av_avref;
    integer input_av_avref__length;
    integer i;
    SV** input_av_avref__element;
    arrayref_arrayref_number output_vector_vector;

    input_av_avref = (AV*)SvRV(input_avref_avref);
	input_av_avref__length = av_len(input_av_avref) + 1;
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_number(), have input_av_avref__length = %"INTEGER"\n", input_av_avref__length);

	// VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
	// resize() ahead of time to allow l-value subscript notation
	output_vector_vector.resize((size_t)input_av_avref__length);

	for (i = 0;  i < input_av_avref__length;  ++i)  // incrementing iteration
	{
	    AV* input_av;
	    integer input_av__length;
	    integer j;
	    SV** input_av__element;
	    arrayref_number output_vector;

	    // utilizes i in element retrieval
	    input_av_avref__element = av_fetch(input_av_avref, i, 0);

//	    input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_av_avref__element
	    input_av = (AV*)SvRV(*input_av_avref__element);
	    input_av__length = av_len(input_av) + 1;
//	    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_number(), have input_av__length = %"INTEGER"\n", input_av__length);

	    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
	    // resize() ahead of time to allow l-value subscript notation
	    output_vector.resize((size_t)input_av__length);

	    for (j = 0;  j < input_av__length;  ++j)  // incrementing iteration
	    {
	        // utilizes j in element retrieval
	        input_av__element = av_fetch(input_av, j, 0);

	        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes j in assignment
	        output_vector[j] = SvNV(*input_av__element);
	    }

//	    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_number(), bottom of outer for() loop i = %"INTEGER", have output_vector.size() = %"INTEGER"\n", i, (integer) output_vector.size());

	    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes i in assignment
	    output_vector_vector[i] = output_vector;
	}

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_number(), after for() loop, have output_vector_vector.size() = %"INTEGER"\n", (integer) output_vector_vector.size());
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_number(), bottom of subroutine\n");

	return(output_vector_vector);
}


// convert from (C++ std::vector of (C++ std::vector of numbers)) to (Perl SV containing RV to (Perl AV of (Perl SV containing RV to (Perl AV of (Perl SVs containing NVs)))))
void XS_pack_arrayref_arrayref_number(SV* output_avref_avref, arrayref_arrayref_number input_vector_vector)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), top of subroutine\n");

	AV* output_av_avref = newAV();  // initialize output array-of-arrays to empty
	integer input_vector_vector__length = input_vector_vector.size();
	integer i;
	SV* temp_sv_pointer;

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), have input_vector_vector__length = %"INTEGER"\n", input_vector_vector__length);

	if (input_vector_vector__length > 0) {
	    for (i = 0;  i < input_vector_vector__length;  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), top of outer loop, have i = %"INTEGER"\n", i);
	        arrayref_number input_vector = input_vector_vector[i];

	        AV* output_av = newAV();  // initialize output sub-array to empty
	        integer input_vector__length = input_vector.size();
	        integer j;

//	        fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), have input_vector__length = %"INTEGER"\n", input_vector__length);

	        if (input_vector__length > 0) {
	            for (j = 0;  j < input_vector__length;  ++j) {
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), top of inner loop, have (i, j) = (%"INTEGER", %"INTEGER")\n", i, j);
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), have input_vector_vector[%"INTEGER"][%"INTEGER"] = %"INTEGER"\n", i, j, input_vector[j]);
	                av_push(output_av, newSVnv(input_vector[j]));
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), bottom of inner loop, have (i, j) = (%"INTEGER", %"INTEGER")\n", i, j);
	            }
	        }
	        else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), sub-array was empty, returning empty sub-array via newAV()");

	        // NEED ANSWER: is it really okay to NOT increase the reference count below???
	        av_push(output_av_avref, newRV_noinc((SV*)output_av));  // reference, do not increase reference count
//	        av_push(output_av_avref, newRV_inc((SV*)output_av));  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), bottom of outer loop, have i = %"INTEGER"\n", i);
	    }
	}
	else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), array was empty, returning empty array via newAV()");

	temp_sv_pointer = newSVrv(output_avref_avref, NULL);	  // upgrade output stack SV to an RV
	SvREFCNT_dec(temp_sv_pointer);		 // discard temporary pointer
	SvRV(output_avref_avref) = (SV*)output_av_avref;	   // make output stack RV point at our output AV

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_number(), bottom of subroutine\n");
}


// convert from (Perl SV containing RV to (Perl AV of (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs))))) to (C++ std::vector of (C++ std::vector of strings))
arrayref_arrayref_string XS_unpack_arrayref_arrayref_string(SV* input_avref_avref)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_string(), top of subroutine\n");
//	arrayref_arrayref_string_CHECK(input_avref_avref);
	arrayref_arrayref_string_CHECKTRACE(input_avref_avref, "input_avref_avref", "XS_unpack_arrayref_arrayref_string()");

    AV* input_av_avref;
    integer input_av_avref__length;
    integer i;
    SV** input_av_avref__element;
    arrayref_arrayref_string output_vector_vector;

    input_av_avref = (AV*)SvRV(input_avref_avref);
	input_av_avref__length = av_len(input_av_avref) + 1;
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_string(), have input_av_avref__length = %"INTEGER"\n", input_av_avref__length);

	// VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
	// resize() ahead of time to allow l-value subscript notation
	output_vector_vector.resize((size_t)input_av_avref__length);

	for (i = 0;  i < input_av_avref__length;  ++i)  // incrementing iteration
	{
	    AV* input_av;
	    integer input_av__length;
	    integer j;
	    SV** input_av__element;
	    arrayref_string output_vector;

	    // utilizes i in element retrieval
	    input_av_avref__element = av_fetch(input_av_avref, i, 0);

//	    input_av = (AV*)SvRV(*input_avref);  // input_avref is an unused shorthand for input_av_avref__element
	    input_av = (AV*)SvRV(*input_av_avref__element);
	    input_av__length = av_len(input_av) + 1;
//	    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_string(), have input_av__length = %"INTEGER"\n", input_av__length);

	    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: vector has programmer-provided const size or compiler-guessable size,
	    // resize() ahead of time to allow l-value subscript notation
	    output_vector.resize((size_t)input_av__length);

	    for (j = 0;  j < input_av__length;  ++j)  // incrementing iteration
	    {
	        // utilizes j in element retrieval
	        input_av__element = av_fetch(input_av, j, 0);

	        // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes j in assignment
	        output_vector[j] = SvPV_nolen(*input_av__element);
	    }

//	    fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_string(), bottom of outer for() loop i = %"INTEGER", have output_vector.size() = %"INTEGER"\n", i, (integer) output_vector.size());

	    // VECTOR ELEMENT ASSIGNMENT, OPTION A, SUBSCRIPT, KNOWN SIZE: l-value subscript notation with no further resize(); utilizes i in assignment
	    output_vector_vector[i] = output_vector;
	}

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_string(), after for() loop, have output_vector_vector.size() = %"INTEGER"\n", (integer) output_vector_vector.size());
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_arrayref_arrayref_string(), bottom of subroutine\n");

	return(output_vector_vector);
}


// convert from (C++ std::vector of (C++ std::vector of strings)) to (Perl SV containing RV to (Perl AV of (Perl SV containing RV to (Perl AV of (Perl SVs containing PVs)))))
void XS_pack_arrayref_arrayref_string(SV* output_avref_avref, arrayref_arrayref_string input_vector_vector)
{
//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), top of subroutine\n");

	AV* output_av_avref = newAV();  // initialize output array-of-arrays to empty
	integer input_vector_vector__length = input_vector_vector.size();
	integer i;
	SV* temp_sv_pointer;

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), have input_vector_vector__length = %"INTEGER"\n", input_vector_vector__length);

	if (input_vector_vector__length > 0) {
	    for (i = 0;  i < input_vector_vector__length;  ++i) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), top of outer loop, have i = %"INTEGER"\n", i);
	        arrayref_string input_vector = input_vector_vector[i];

	        AV* output_av = newAV();  // initialize output sub-array to empty
	        integer input_vector__length = input_vector.size();
	        integer j;

//	        fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), have input_vector__length = %"INTEGER"\n", input_vector__length);

	        if (input_vector__length > 0) {
	            for (j = 0;  j < input_vector__length;  ++j) {
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), top of inner loop, have (i, j) = (%"INTEGER", %"INTEGER")\n", i, j);
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), have input_vector_vector[%"INTEGER"][%"INTEGER"] = %"INTEGER"\n", i, j, input_vector[j]);
	                av_push(output_av, newSVpv((const char *) input_vector[j].c_str(), 0));
//	                fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), bottom of inner loop, have (i, j) = (%"INTEGER", %"INTEGER")\n", i, j);
	            }
	        }
	        else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), sub-array was empty, returning empty sub-array via newAV()");

	        // NEED ANSWER: is it really okay to NOT increase the reference count below???
	        av_push(output_av_avref, newRV_noinc((SV*)output_av));  // reference, do not increase reference count
//	        av_push(output_av_avref, newRV_inc((SV*)output_av));  // reference, do increase reference count

//            fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), bottom of outer loop, have i = %"INTEGER"\n", i);
	    }
	}
	else warn("in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), array was empty, returning empty array via newAV()");

	temp_sv_pointer = newSVrv(output_avref_avref, NULL);	  // upgrade output stack SV to an RV
	SvREFCNT_dec(temp_sv_pointer);		 // discard temporary pointer
	SvRV(output_avref_avref) = (SV*)output_av_avref;	   // make output stack RV point at our output AV

//	fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_arrayref_arrayref_string(), bottom of subroutine\n");
}

# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES

// THEN START HERE: implement arrayref_arrayref_*_to_string() & arrayref_hashref_*_to_string() CPPOPS_PERLTYPES
// THEN START HERE: implement arrayref_arrayref_*_to_string() & arrayref_hashref_*_to_string() CPPOPS_PERLTYPES
// THEN START HERE: implement arrayref_arrayref_*_to_string() & arrayref_hashref_*_to_string() CPPOPS_PERLTYPES

# elif defined __CPP__TYPES

// START HERE: implement arrayref_arrayref_*_to_string() & arrayref_hashref_*_to_string() CPPOPS_CPPTYPES
// START HERE: implement arrayref_arrayref_*_to_string() & arrayref_hashref_*_to_string() CPPOPS_CPPTYPES
// START HERE: implement arrayref_arrayref_*_to_string() & arrayref_hashref_*_to_string() CPPOPS_CPPTYPES

# else

Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!

# endif


// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES

// NEED ADD CODE HERE
// NEED ADD CODE HERE
// NEED ADD CODE HERE

# elif defined __CPP__TYPES

// NEED ADD CODE HERE
// NEED ADD CODE HERE
// NEED ADD CODE HERE

# endif

#endif
