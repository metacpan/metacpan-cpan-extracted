////use strict;  use warnings;
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Structure__Hash__SubTypes2D_h
#define __CPP__INCLUDED__Perl__Structure__Hash__SubTypes2D_h 0.009_000

#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// for type-checking subroutines & macros
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h

// [[[ DATA TYPES ]]]
#include <Perl/Type/Integer.cpp>
#include <Perl/Type/Number.cpp>
#include <Perl/Type/String.cpp>
#include <Perl/Structure/Array.cpp>  // -> ???    for arrayref_integer_to_string_format() used in hashref_arrayref_integer_to_string_format()

// [[[ TYPEDEFS, 1D REPEATED ]]]
typedef std::unordered_map<string, integer> hashref_integer;
typedef std::unordered_map<string, integer>::iterator hashref_integer_iterator;
typedef std::unordered_map<string, integer>::const_iterator hashref_integer_const_iterator;
typedef std::unordered_map<string, number> hashref_number;
typedef std::unordered_map<string, number>::iterator hashref_number_iterator;
typedef std::unordered_map<string, number>::const_iterator hashref_number_const_iterator;
typedef std::unordered_map<string, string> hashref_string;
typedef std::unordered_map<string, string>::iterator hashref_string_iterator;
typedef std::unordered_map<string, string>::const_iterator hashref_string_const_iterator;

// [[[ TYPEDEFS ]]]
// [[[ TYPEDEFS ]]]
// [[[ TYPEDEFS ]]]

// [[[ HASH REF HASH REF ]]]
typedef std::unordered_map<string, std::unordered_map<string, integer>> hashref_hashref_integer;
typedef std::unordered_map<string, std::unordered_map<string, integer>>::iterator hashref_hashref_integer_iterator;
typedef std::unordered_map<string, std::unordered_map<string, integer>>::const_iterator hashref_hashref_integer_const_iterator;
typedef std::unordered_map<string, std::unordered_map<string, number>> hashref_hashref_number;
typedef std::unordered_map<string, std::unordered_map<string, number>>::iterator hashref_hashref_number_iterator;
typedef std::unordered_map<string, std::unordered_map<string, number>>::const_iterator hashref_hashref_number_const_iterator;
typedef std::unordered_map<string, std::unordered_map<string, string>> hashref_hashref_string;
typedef std::unordered_map<string, std::unordered_map<string, string>>::iterator hashref_hashref_string_iterator;
typedef std::unordered_map<string, std::unordered_map<string, string>>::const_iterator hashref_hashref_string_const_iterator;

// [[[ HASH REF ARRAY REF ]]]
typedef std::unordered_map<string, std::vector<integer>> hashref_arrayref_integer;
typedef std::unordered_map<string, std::vector<integer>>::iterator hashref_arrayref_integer_iterator;
typedef std::unordered_map<string, std::vector<integer>>::const_iterator hashref_arrayref_integer_const_iterator;
typedef std::unordered_map<string, std::vector<number>> hashref_arrayref_number;
typedef std::unordered_map<string, std::vector<number>>::iterator hashref_arrayref_number_iterator;
typedef std::unordered_map<string, std::vector<number>>::const_iterator hashref_arrayref_number_const_iterator;
typedef std::unordered_map<string, std::vector<string>> hashref_arrayref_string;
typedef std::unordered_map<string, std::vector<string>>::iterator hashref_arrayref_string_iterator;
typedef std::unordered_map<string, std::vector<string>>::const_iterator hashref_arrayref_string_const_iterator;

// [[[ TYPE-CHECKING SUBROUTINES ]]]
// [[[ TYPE-CHECKING SUBROUTINES ]]]
// [[[ TYPE-CHECKING SUBROUTINES ]]]

// [[[ HASH REF HASH REF ]]]
/* NEED IMPLEMENT IN SubTypes2D.cpp
void hashref_hashref_integer_CHECK(SV* possible_hashref_hashref_integer);
void hashref_hashref_integer_CHECKTRACE(SV* possible_hashref_hashref_integer, const char* variable_name, const char* subroutine_name);
void hashref_hashref_number_CHECK(SV* possible_hashref_hashref_number);
void hashref_hashref_number_CHECKTRACE(SV* possible_hashref_hashref_number, const char* variable_name, const char* subroutine_name);
void hashref_hashref_string_CHECK(SV* possible_hashref_hashref_string);
void hashref_hashref_string_CHECKTRACE(SV* possible_hashref_hashref_string, const char* variable_name, const char* subroutine_name);
*/

// [[[ HASH REF ARRAY REF ]]]
void hashref_arrayref_integer_CHECK(SV* possible_hashref_arrayref_integer);
void hashref_arrayref_integer_CHECKTRACE(SV* possible_hashref_arrayref_integer, const char* variable_name, const char* subroutine_name);
void hashref_arrayref_number_CHECK(SV* possible_hashref_arrayref_number);
void hashref_arrayref_number_CHECKTRACE(SV* possible_hashref_arrayref_number, const char* variable_name, const char* subroutine_name);
void hashref_arrayref_string_CHECK(SV* possible_hashref_arrayref_string);
void hashref_arrayref_string_CHECKTRACE(SV* possible_hashref_arrayref_string, const char* variable_name, const char* subroutine_name);

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__Structure__Hash__SubTypes2D__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
integer Perl__Structure__Hash__SubTypes2D__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

# ifdef __CPP__TYPES
// [[[ HASH REF HASH REF ]]]
/* NEED IMPLEMENT IN SubTypes2D.cpp
hashref_hashref_integer XS_unpack_hashref_hashref_integer(SV* input_hvref_hvref);
void XS_pack_hashref_hashref_integer(SV* output_hvref_hvref, hashref_hashref_integer input_umap_umap);
hashref_hashref_number XS_unpack_hashref_hashref_number(SV* input_hvref_hvref);
void XS_pack_hashref_hashref_number(SV* output_hvref_hvref, hashref_hashref_number input_umap_umap);
hashref_hashref_string XS_unpack_hashref_hashref_string(SV* input_hvref_hvref);
void XS_pack_hashref_hashref_string(SV* output_hvref_hvref, hashref_hashref_string input_umap_umap);
*/

// [[[ HASH REF ARRAY REF ]]]
hashref_arrayref_integer XS_unpack_hashref_arrayref_integer(SV* input_hvref_avref);
void XS_pack_hashref_arrayref_integer(SV* output_hvref_avref, hashref_arrayref_integer input_umap_vector);
hashref_arrayref_number XS_unpack_hashref_arrayref_number(SV* input_hvref_avref);
void XS_pack_hashref_arrayref_number(SV* output_hvref_avref, hashref_arrayref_number input_umap_vector);
hashref_arrayref_string XS_unpack_hashref_arrayref_string(SV* input_hvref_avref);
void XS_pack_hashref_arrayref_string(SV* output_hvref_avref, hashref_arrayref_string input_umap_vector);
# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES
/* NEED IMPLEMENT IN SubTypes2D.cpp, NEED UPDATE TO LIST MULTIPLE VARIATIONS HERE
// [[[ HASH REF HASH REF ]]]
SV* hashref_hashref_integer_to_string(SV* input_hvref_hvref);
SV* hashref_hashref_number_to_string(SV* input_hvref_hvref);
SV* hashref_hashref_string_to_string(SV* input_hvref_hvref);
*/

// [[[ HASH REF ARRAY REF ]]]
SV* hashref_arrayref_integer_to_string_compact(SV* input_hvref_avref);
SV* hashref_arrayref_integer_to_string(SV* input_hvref_avref);
SV* hashref_arrayref_integer_to_string_pretty(SV* input_hvref_avref);
SV* hashref_arrayref_integer_to_string_extend(SV* input_hvref_avref);
SV* hashref_arrayref_integer_to_string_format(SV* input_hvref_avref, SV* format_level, SV* indent_level);
SV* hashref_arrayref_number_to_string_compact(SV* input_hvref_avref);
SV* hashref_arrayref_number_to_string(SV* input_hvref_avref);
SV* hashref_arrayref_number_to_string_pretty(SV* input_hvref_avref);
SV* hashref_arrayref_number_to_string_extend(SV* input_hvref_avref);
SV* hashref_arrayref_number_to_string_format(SV* input_hvref_avref, SV* format_level, SV* indent_level);
SV* hashref_arrayref_string_to_string_compact(SV* input_hvref_avref);
SV* hashref_arrayref_string_to_string(SV* input_hvref_avref);
SV* hashref_arrayref_string_to_string_pretty(SV* input_hvref_avref);
SV* hashref_arrayref_string_to_string_extend(SV* input_hvref_avref);
SV* hashref_arrayref_string_to_string_format(SV* input_hvref_avref, SV* format_level, SV* indent_level);

# elif defined __CPP__TYPES

/* NEED IMPLEMENT IN SubTypes2D.cpp, NEED UPDATE TO LIST MULTIPLE VARIATIONS HERE
// [[[ HASH REF HASH REF ]]]
string hashref_hashref_integer_to_string(hashref_hashref_integer input_umap_umap);
string hashref_hashref_number_to_string(hashref_hashref_number input_umap_umap);
string hashref_hashref_string_to_string(hashref_hashref_string input_umap_umap);
*/

// [[[ HASH REF ARRAY REF ]]]
string hashref_arrayref_integer_to_string_compact(hashref_arrayref_integer input_umap_vector);
string hashref_arrayref_integer_to_string(hashref_arrayref_integer input_umap_vector);
string hashref_arrayref_integer_to_string_pretty(hashref_arrayref_integer input_umap_vector);
string hashref_arrayref_integer_to_string_expand(hashref_arrayref_integer input_umap_vector);
string hashref_arrayref_integer_to_string_format(hashref_arrayref_integer input_umap_vector, integer format_level, integer indent_level);
string hashref_arrayref_number_to_string_compact(hashref_arrayref_number input_umap_vector);
string hashref_arrayref_number_to_string(hashref_arrayref_number input_umap_vector);
string hashref_arrayref_number_to_string_pretty(hashref_arrayref_number input_umap_vector);
string hashref_arrayref_number_to_string_expand(hashref_arrayref_number input_umap_vector);
string hashref_arrayref_number_to_string_format(hashref_arrayref_number input_umap_vector, integer format_level, integer indent_level);
string hashref_arrayref_string_to_string_compact(hashref_arrayref_string input_umap_vector);
string hashref_arrayref_string_to_string(hashref_arrayref_string input_umap_vector);
string hashref_arrayref_string_to_string_pretty(hashref_arrayref_string input_umap_vector);
string hashref_arrayref_string_to_string_expand(hashref_arrayref_string input_umap_vector);
string hashref_arrayref_string_to_string_format(hashref_arrayref_string input_umap_vector, integer format_level, integer indent_level);
# endif

// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES
/* NEED IMPLEMENT IN SubTypes2D.cpp
// [[[ HASH REF HASH REF ]]]
SV* hashref_hashref_integer_typetest0(SV* lucky_arrayref_integers);
SV* hashref_hashref_integer_typetest1(SV* my_size);
SV* hashref_hashref_number_typetest0(SV* lucky_arrayref_numbers);
SV* hashref_hashref_number_typetest1(SV* my_size);
SV* hashref_hashref_string_typetest0(SV* lucky_arrayref_strings);
SV* hashref_hashref_string_typetest1(SV* my_size);
*/

// [[[ HASH REF ARRAY REF ]]]
SV* hashref_arrayref_integer_typetest0(SV* lucky_arrayref_integers);
SV* hashref_arrayref_integer_typetest1(SV* my_size);
SV* hashref_arrayref_number_typetest0(SV* lucky_arrayref_numbers);
SV* hashref_arrayref_number_typetest1(SV* my_size);
SV* hashref_arrayref_string_typetest0(SV* lucky_arrayref_strings);
SV* hashref_arrayref_string_typetest1(SV* my_size);

# elif defined __CPP__TYPES

/* NEED IMPLEMENT IN SubTypes2D.cpp
// [[[ HASH REF HASH REF ]]]
string hashref_hashref_integer_typetest0(hashref_hashref_integer lucky_arrayref_integers);
hashref_hashref_integer hashref_hashref_integer_typetest1(integer my_size);
string hashref_hashref_number_typetest0(hashref_hashref_number lucky_arrayref_numbers);
hashref_hashref_number hashref_hashref_number_typetest1(integer my_size);
string hashref_hashref_string_typetest0(hashref_hashref_string lucky_arrayref_strings);
hashref_hashref_string hashref_hashref_string_typetest1(integer my_size);
*/

// [[[ HASH REF ARRAY REF ]]]
string hashref_arrayref_integer_typetest0(hashref_arrayref_integer lucky_arrayref_integers);
hashref_arrayref_integer hashref_arrayref_integer_typetest1(integer my_size);
string hashref_arrayref_number_typetest0(hashref_arrayref_number lucky_arrayref_numbers);
hashref_arrayref_number hashref_arrayref_number_typetest1(integer my_size);
string hashref_arrayref_string_typetest0(hashref_arrayref_string lucky_arrayref_strings);
hashref_arrayref_string hashref_arrayref_string_typetest1(integer my_size);
# endif

#endif
