////use strict;  use warnings;
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Structure__Array__SubTypes2D_h
#define __CPP__INCLUDED__Perl__Structure__Array__SubTypes2D_h 0.005_000

#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// for type-checking subroutines & macros
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h

// [[[ DATA TYPES ]]]
#include <Perl/Type/Integer.cpp>
#include <Perl/Type/Number.cpp>
#include <Perl/Type/String.cpp>

// NEED FIX, RPERL UPGRADE: CREATE MISSING C++ CLASSES TO ENABLE USE OF :: SCOPE RESOLUTION OPERATOR IN TYPEDEF TYPE NAMES
// NEED FIX, RPERL UPGRADE: CREATE MISSING C++ CLASSES TO ENABLE USE OF :: SCOPE RESOLUTION OPERATOR IN TYPEDEF TYPE NAMES
// NEED FIX, RPERL UPGRADE: CREATE MISSING C++ CLASSES TO ENABLE USE OF :: SCOPE RESOLUTION OPERATOR IN TYPEDEF TYPE NAMES

// [[[ TYPEDEFS, 1D REPEATED ]]]
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

// [[[ TYPEDEFS ]]]
// [[[ TYPEDEFS ]]]
// [[[ TYPEDEFS ]]]

// [[[ ARRAY REF ARRAY REF ]]]
typedef std::vector<std::vector<integer>> arrayref_arrayref_integer;
typedef std::vector<std::vector<integer>>::iterator arrayref_arrayref_integer_iterator;
typedef std::vector<std::vector<integer>>::const_iterator arrayref_arrayref_integer_const_iterator;
typedef std::vector<std::vector<number>> arrayref_arrayref_number;
typedef std::vector<std::vector<number>>::iterator arrayref_arrayref_number_iterator;
typedef std::vector<std::vector<number>>::const_iterator arrayref_arrayref_number_const_iterator;
typedef std::vector<std::vector<string>> arrayref_arrayref_string;
typedef std::vector<std::vector<string>>::iterator arrayref_arrayref_string_iterator;
typedef std::vector<std::vector<string>>::const_iterator arrayref_arrayref_xtring_const_iterator;

// [[[ ARRAY REF HASH REF ]]]
typedef std::vector<std::unordered_map<string, integer>> arrayref_hashref_integer;
typedef std::vector<std::unordered_map<string, integer>>::iterator arrayref_hashref_integer_iterator;
typedef std::vector<std::unordered_map<string, integer>>::const_iterator arrayref_hashref_integer_const_iterator;
typedef std::vector<std::unordered_map<string, number>> arrayref_hashref_number;
typedef std::vector<std::unordered_map<string, number>>::iterator arrayref_hashref_number_iterator;
typedef std::vector<std::unordered_map<string, number>>::const_iterator arrayref_hashref_number_const_iterator;
typedef std::vector<std::unordered_map<string, string>> arrayref_hashref_string;
typedef std::vector<std::unordered_map<string, string>>::iterator arrayref_hashref_string_iterator;
typedef std::vector<std::unordered_map<string, string>>::const_iterator arrayref_hashref_string_const_iterator;

// [[[ TYPE-CHECKING SUBROUTINES ]]]
// [[[ TYPE-CHECKING SUBROUTINES ]]]
// [[[ TYPE-CHECKING SUBROUTINES ]]]

// [[[ ARRAY REF ARRAY REF ]]]
void arrayref_arrayref_integer_CHECK(SV* possible_arrayref_arrayref_integer);
void arrayref_arrayref_integer_CHECKTRACE(SV* possible_arrayref_arrayref_integer, const char* variable_name, const char* subroutine_name);
void arrayref_arrayref_number_CHECK(SV* possible_arrayref_arrayref_number);
void arrayref_arrayref_number_CHECKTRACE(SV* possible_arrayref_arrayref_number, const char* variable_name, const char* subroutine_name);
void arrayref_arrayref_string_CHECK(SV* possible_arrayref_arrayref_string);
void arrayref_arrayref_string_CHECKTRACE(SV* possible_arrayref_arrayref_string, const char* variable_name, const char* subroutine_name);

// [[[ ARRAY REF HASH REF ]]]
/* NEED IMPLEMENT IN SubTypes2D.cpp
void arrayref_hashref_integer_CHECK(SV* possible_arrayref_hashref_integer);
void arrayref_hashref_integer_CHECKTRACE(SV* possible_arrayref_hashref_integer, const char* variable_name, const char* subroutine_name);
void arrayref_hashref_number_CHECK(SV* possible_arrayref_hashref_number);
void arrayref_hashref_number_CHECKTRACE(SV* possible_arrayref_hashref_number, const char* variable_name, const char* subroutine_name);
void arrayref_hashref_string_CHECK(SV* possible_arrayref_hashref_string);
void arrayref_hashref_string_CHECKTRACE(SV* possible_arrayref_hashref_string, const char* variable_name, const char* subroutine_name);
*/

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__Structure__Array__SubTypes2D__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
integer Perl__Structure__Array__SubTypes2D__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

# ifdef __CPP__TYPES
// [[[ ARRAY REF ARRAY REF ]]]
arrayref_arrayref_integer XS_unpack_arrayref_arrayref_integer(SV* input_avref_avref);
void XS_pack_arrayref_arrayref_integer(SV* output_avref_avref, arrayref_arrayref_integer input_vector_vector);
arrayref_arrayref_number XS_unpack_arrayref_arrayref_number(SV* input_avref_avref);
void XS_pack_arrayref_arrayref_number(SV* output_avref_avref, arrayref_arrayref_number input_vector_vector);
arrayref_arrayref_string XS_unpack_arrayref_arrayref_string(SV* input_avref_avref);
void XS_pack_arrayref_arrayref_string(SV* output_avref_avref, arrayref_arrayref_string input_vector_vector);

// [[[ ARRAY REF HASH REF ]]]
/* NEED IMPLEMENT IN SubTypes2D.cpp
arrayref_hashref_integer XS_unpack_arrayref_hashref_integer(SV* input_avref_hvref);
void XS_pack_arrayref_hashref_integer(SV* output_avref_hvref, arrayref_hashref_integer input_vector_umap);
arrayref_hashref_number XS_unpack_arrayref_hashref_number(SV* input_avref_hvref);
void XS_pack_arrayref_hashref_number(SV* output_avref_hvref, arrayref_hashref_number input_vector_umap);
arrayref_hashref_string XS_unpack_arrayref_hashref_string(SV* input_avref_hvref);
void XS_pack_arrayref_hashref_string(SV* output_avref_hvref, arrayref_hashref_string input_vector_umap);
*/
# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES
/* NEED IMPLEMENT IN SubTypes2D.cpp
// [[[ ARRAY REF ARRAY REF ]]]
SV* arrayref_arrayref_integer_to_string(SV* input_avref_avref);
SV* arrayref_arrayref_number_to_string(SV* input_avref_avref);
SV* arrayref_arrayref_string_to_string(SV* input_avref_avref);

// [[[ ARRAY REF HASH REF ]]]
SV* arrayref_hashref_integer_to_string(SV* input_avref_hvref);
SV* arrayref_hashref_number_to_string(SV* input_avref_hvref);
SV* arrayref_hashref_string_to_string(SV* input_avref_hvref);
*/
# elif defined __CPP__TYPES
/* NEED IMPLEMENT IN SubTypes2D.cpp
// [[[ ARRAY REF ARRAY REF ]]]
string arrayref_arrayref_integer_to_string(arrayref_arrayref_integer input_vector_vector);
string arrayref_arrayref_number_to_string(arrayref_arrayref_number input_vector_vector);
string arrayref_arrayref_string_to_string(arrayref_arrayref_string input_vector_vector);

// [[[ ARRAY REF HASH REF ]]]
string arrayref_hashref_integer_to_string(arrayref_hashref_integer input_vector_umap);
string arrayref_hashref_number_to_string(arrayref_hashref_number input_vector_umap);
string arrayref_hashref_string_to_string(arrayref_hashref_string input_vector_umap);
*/
# endif

// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES
/* NEED IMPLEMENT IN SubTypes2D.cpp
// [[[ ARRAY REF ARRAY REF ]]]
SV* arrayref_arrayref_integer_typetest0(SV* lucky_integers);
SV* arrayref_arrayref_integer_typetest1(SV* my_size);
SV* arrayref_arrayref_number_typetest0(SV* lucky_numbers);
SV* arrayref_arrayref_number_typetest1(SV* my_size);
SV* arrayref_arrayref_string_typetest0(SV* people);
SV* arrayref_arrayref_string_typetest1(SV* my_size);

// [[[ ARRAY REF HASH REF ]]]
SV* arrayref_hashref_integer_typetest0(SV* lucky_integers);
SV* arrayref_hashref_integer_typetest1(SV* my_size);
SV* arrayref_hashref_number_typetest0(SV* lucky_numbers);
SV* arrayref_hashref_number_typetest1(SV* my_size);
SV* arrayref_hashref_string_typetest0(SV* people);
SV* arrayref_hashref_string_typetest1(SV* my_size);
*/
# elif defined __CPP__TYPES
/* NEED IMPLEMENT IN SubTypes2D.cpp
// [[[ ARRAY REF ARRAY REF ]]]
string arrayref_arrayref_integer_typetest0(arrayref_arrayref_integer lucky_integers);
arrayref_arrayref_integer arrayref_arrayref_integer_typetest1(integer my_size);
string arrayref_arrayref_number_typetest0(arrayref_arrayref_number lucky_numbers);
arrayref_arrayref_number arrayref_arrayref_number_typetest1(integer my_size);
string arrayref_arrayref_string_typetest0(arrayref_arrayref_string people);
arrayref_arrayref_string arrayref_arrayref_string_typetest1(integer my_size);

// [[[ ARRAY REF HASH REF ]]]
string arrayref_hashref_integer_typetest0(arrayref_hashref_integer lucky_integers);
arrayref_hashref_integer arrayref_hashref_integer_typetest1(integer my_size);
string arrayref_hashref_number_typetest0(arrayref_hashref_number lucky_numbers);
arrayref_hashref_number arrayref_hashref_number_typetest1(integer my_size);
string arrayref_hashref_string_typetest0(arrayref_hashref_string people);
arrayref_hashref_string arrayref_hashref_string_typetest1(integer my_size);
*/
# endif

#endif
