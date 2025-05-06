////use strict;  use warnings;
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Structure__Hash__SubTypes1D_h
#define __CPP__INCLUDED__Perl__Structure__Hash__SubTypes1D_h 0.005_000

#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// for type-checking subroutines & macros
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h

// [[[ DATA TYPES ]]]
#include <Perl/Type/Integer.cpp>
#include <Perl/Type/Number.cpp>
#include <Perl/Type/String.cpp>

// [[[ TYPEDEFS ]]]
typedef std::unordered_map<string, integer> hashref_integer;
typedef std::unordered_map<string, integer>::iterator hashref_integer_iterator;
typedef std::unordered_map<string, integer>::const_iterator hashref_integer_const_iterator;
typedef std::unordered_map<string, number> hashref_number;
typedef std::unordered_map<string, number>::iterator hashref_number_iterator;
typedef std::unordered_map<string, number>::const_iterator hashref_number_const_iterator;
typedef std::unordered_map<string, string> hashref_string;
typedef std::unordered_map<string, string>::iterator hashref_string_iterator;
typedef std::unordered_map<string, string>::const_iterator hashref_string_const_iterator;

// [[[ TYPE-CHECKING SUBROUTINES ]]]
void hashref_integer_CHECK(SV* possible_hashref_integer);
void hashref_integer_CHECKTRACE(SV* possible_hashref_integer, const char* variable_name, const char* subroutine_name);
void hashref_number_CHECK(SV* possible_hashref_number);
void hashref_number_CHECKTRACE(SV* possible_hashref_number, const char* variable_name, const char* subroutine_name);
void hashref_string_CHECK(SV* possible_hashref_string);
void hashref_string_CHECKTRACE(SV* possible_hashref_string, const char* variable_name, const char* subroutine_name);

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__Structure__Hash__SubTypes1D__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
integer Perl__Structure__Hash__SubTypes1D__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
# ifdef __CPP__TYPES
hashref_integer XS_unpack_hashref_integer(SV* input_hvref);
void XS_pack_hashref_integer(SV* output_hvref, hashref_integer input_umap);
hashref_number XS_unpack_hashref_number(SV* input_hvref);
void XS_pack_hashref_number(SV* output_hvref, hashref_number input_umap);
hashref_string XS_unpack_hashref_string(SV* input_hvref);
void XS_pack_hashref_string(SV* output_hvref, hashref_string input_umap);
# endif

// [[[ STRINGIFY ]]]
# ifdef __PERL__TYPES
SV* hashref_integer_to_string_compact(SV* input_hvref);
SV* hashref_integer_to_string(SV* input_hvref);
SV* hashref_integer_to_string_pretty(SV* input_hvref);
SV* hashref_integer_to_string_expand(SV* input_hvref);
SV* hashref_integer_to_string_format(SV* input_hvref, SV* format_level, SV* indent_level);
SV* hashref_number_to_string_compact(SV* input_hvref);
SV* hashref_number_to_string(SV* input_hvref);
SV* hashref_number_to_string_pretty(SV* input_hvref);
SV* hashref_number_to_string_expand(SV* input_hvref);
SV* hashref_number_to_string_format(SV* input_hvref, SV* format_level, SV* indent_level);
SV* hashref_string_to_string_compact(SV* input_hvref);
SV* hashref_string_to_string(SV* input_hvref);
SV* hashref_string_to_string_pretty(SV* input_hvref);
SV* hashref_string_to_string_expand(SV* input_hvref);
SV* hashref_string_to_string_format(SV* input_hvref, SV* format_level, SV* indent_level);
# elif defined __CPP__TYPES
string hashref_integer_to_string_compact(hashref_integer input_umap);
string hashref_integer_to_string(hashref_integer input_umap);
string hashref_integer_to_string_pretty(hashref_integer input_umap);
string hashref_integer_to_string_expand(hashref_integer input_umap);
string hashref_integer_to_string_format(hashref_integer input_umap, integer format_level, integer indent_level);
string hashref_number_to_string_compact(hashref_number input_umap);
string hashref_number_to_string(hashref_number input_umap);
string hashref_number_to_string_pretty(hashref_number input_umap);
string hashref_number_to_string_expand(hashref_number input_umap);
string hashref_number_to_string_format(hashref_number input_umap, integer format_level, integer indent_level);
string hashref_string_to_string_compact(hashref_string input_umap);
string hashref_string_to_string(hashref_string input_umap);
string hashref_string_to_string_pretty(hashref_string input_umap);
string hashref_string_to_string_expand(hashref_string input_umap);
string hashref_string_to_string_format(hashref_string input_umap, integer format_level, integer indent_level);
# endif

// [[[ TYPE TESTING ]]]
# ifdef __PERL__TYPES
SV* hashref_integer_typetest0(SV* lucky_integers);
SV* hashref_integer_typetest1(SV* my_size);
SV* hashref_number_typetest0(SV* lucky_numbers);
SV* hashref_number_typetest1(SV* my_size);
SV* hashref_string_typetest0(SV* people);
SV* hashref_string_typetest1(SV* my_size);
# elif defined __CPP__TYPES
string hashref_integer_typetest0(hashref_integer lucky_integers);
hashref_integer hashref_integer_typetest1(integer my_size);
string hashref_number_typetest0(hashref_number lucky_numbers);
hashref_number hashref_number_typetest1(integer my_size);
string hashref_string_typetest0(hashref_string people);
hashref_string hashref_string_typetest1(integer my_size);
# endif

#endif
