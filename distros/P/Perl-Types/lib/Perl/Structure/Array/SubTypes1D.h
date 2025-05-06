////use strict;  use warnings;
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Structure__Array__SubTypes1D_h
#define __CPP__INCLUDED__Perl__Structure__Array__SubTypes1D_h 0.020_000

#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// for type-checking subroutines & macros
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h

// [[[ DATA TYPES ]]]
#include <Perl/Type/Integer.cpp>
#include <Perl/Type/Number.cpp>
#include <Perl/Type/String.cpp>

// [[[ TYPEDEFS ]]]
// DEV NOTE: type names can't use scope resolution op "::", use underscore instead; "error: typedef name may not be a nested-name-specifier"
typedef std::vector<integer> arrayref_integer;
typedef std::vector<integer>::iterator arrayref_integer_iterator;
typedef std::vector<integer>::const_iterator arrayref_integer_const_iterator;
typedef std::vector<number> arrayref_number;
typedef std::vector<number>::iterator arrayref_number_iterator;
typedef std::vector<number>::const_iterator arrayref_number_const_iterator;
typedef std::vector<string> arrayref_string;
typedef std::vector<string>::iterator arrayref_string_iterator;
typedef std::vector<string>::const_iterator arrayref_string_const_iterator;

// [[[ TYPE-CHECKING SUBROUTINES ]]]
void arrayref_integer_CHECK(SV* possible_arrayref_integer);
void arrayref_integer_CHECKTRACE(SV* possible_arrayref_integer, const char* variable_name, const char* subroutine_name);
void arrayref_number_CHECK(SV* possible_arrayref_number);
void arrayref_number_CHECKTRACE(SV* possible_arrayref_number, const char* variable_name, const char* subroutine_name);
void arrayref_string_CHECK(SV* possible_arrayref_string);
void arrayref_string_CHECKTRACE(SV* possible_arrayref_string, const char* variable_name, const char* subroutine_name);

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__Structure__Array__SubTypes1D__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
integer Perl__Structure__Array__SubTypes1D__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
# ifdef __CPP__TYPES
arrayref_integer XS_unpack_arrayref_integer(SV* input_avref);
void XS_pack_arrayref_integer(SV* output_avref, arrayref_integer input_vector);
arrayref_number XS_unpack_arrayref_number(SV* input_avref);
void XS_pack_arrayref_number(SV* output_avref, arrayref_number input_vector);
arrayref_string XS_unpack_arrayref_string(SV* input_avref);
void XS_pack_arrayref_string(SV* output_avref, arrayref_string input_vector);
# endif

// [[[ STRINGIFY ]]]
# ifdef __PERL__TYPES
SV* arrayref_integer_to_string_compact(SV* input_avref);
SV* arrayref_integer_to_string(SV* input_avref);
SV* arrayref_integer_to_string_pretty(SV* input_avref);
SV* arrayref_integer_to_string_extend(SV* input_avref);
SV* arrayref_integer_to_string_format(SV* input_avref, SV* format_level, SV* indent_level);
SV* arrayref_number_to_string_compact(SV* input_avref);
SV* arrayref_number_to_string(SV* input_avref);
SV* arrayref_number_to_string_pretty(SV* input_avref);
SV* arrayref_number_to_string_extend(SV* input_avref);
SV* arrayref_number_to_string_format(SV* input_avref, SV* format_level, SV* indent_level);
SV* arrayref_string_to_string_compact(SV* input_avref);
SV* arrayref_string_to_string(SV* input_avref);
SV* arrayref_string_to_string_pretty(SV* input_avref);
SV* arrayref_string_to_string_extend(SV* input_avref);
SV* arrayref_string_to_string_format(SV* input_avref, SV* format_level, SV* indent_level);
# elif defined __CPP__TYPES
string arrayref_integer_to_string_compact(arrayref_integer input_vector);
string arrayref_integer_to_string(arrayref_integer input_vector);
string arrayref_integer_to_string_pretty(arrayref_integer input_vector);
string arrayref_integer_to_string_extend(arrayref_integer input_vector);
string arrayref_integer_to_string_format(arrayref_integer input_vector, integer format_level, integer indent_level);
string arrayref_number_to_string_compact(arrayref_number input_vector);
string arrayref_number_to_string(arrayref_number input_vector);
string arrayref_number_to_string_pretty(arrayref_number input_vector);
string arrayref_number_to_string_extend(arrayref_number input_vector);
string arrayref_number_to_string_format(arrayref_number input_vector, integer format_level, integer indent_level);
string arrayref_string_to_string_compact(arrayref_string input_vector);
string arrayref_string_to_string(arrayref_string input_vector);
string arrayref_string_to_string_pretty(arrayref_string input_vector);
string arrayref_string_to_string_extend(arrayref_string input_vector);
string arrayref_string_to_string_format(arrayref_string input_vector, integer format_level, integer indent_level);
# endif

// [[[ TYPE TESTING ]]]
# ifdef __PERL__TYPES
SV* arrayref_integer_typetest0(SV* lucky_integers);
SV* arrayref_integer_typetest1(SV* my_size);
SV* arrayref_number_typetest0(SV* lucky_numbers);
SV* arrayref_number_typetest1(SV* my_size);
SV* arrayref_string_typetest0(SV* people);
SV* arrayref_string_typetest1(SV* my_size);
# elif defined __CPP__TYPES
string arrayref_integer_typetest0(arrayref_integer lucky_integers);
arrayref_integer arrayref_integer_typetest1(integer my_size);
string arrayref_number_typetest0(arrayref_number lucky_numbers);
arrayref_number arrayref_number_typetest1(integer my_size);
string arrayref_string_typetest0(arrayref_string people);
arrayref_string arrayref_string_typetest1(integer my_size);
# endif

#endif
