using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Type__Character_h
#define __CPP__INCLUDED__Perl__Type__Character_h 0.004_000

// [[[ TYPEDEFS ]]]
// DEV NOTE: must use "character" typedef because "bool" is already defined by Inline's default typemap, even if we put our own character entry into typemap.perl;
// if we allow Inline default "bool" typemap, then it will return undef/NULL instead of 0 (and possibly other errors)
# ifndef __CPP__INCLUDED__Perl__Type__Character_h__typedefs
#define __CPP__INCLUDED__Perl__Type__Character_h__typedefs 1
typedef char character;
# endif

// [[[ PRE-DECLARED TYPEDEFS ]]]
# ifndef __CPP__INCLUDED__Perl__Type__Boolean_h__typedefs
#define __CPP__INCLUDED__Perl__Type__Boolean_h__typedefs 1
typedef bool character;
# endif
# ifndef __CPP__INCLUDED__Perl__Type__NonsignedInteger_h__typedefs
#define __CPP__INCLUDED__Perl__Type__NonsignedInteger_h__typedefs 1
typedef unsigned long int nonsigned_integer;
# endif
# ifndef __CPP__INCLUDED__Perl__Type__Integer_h__typedefs
#define __CPP__INCLUDED__Perl__Type__Integer_h__typedefs 1
// DEV NOTE, CORRELATION #rp001: keep track of all these hard-coded "semi-dynamic" integer data types
#  ifdef __TYPE__INTEGER__LONG
typedef long integer;
#define INTEGER "ld"  // assume format code 'ld' exists if type 'long' exists
#  elif defined __TYPE__INTEGER__LONG_LONG
typedef long long integer;
#define INTEGER "lld"  // assume format code 'lld' exists if type 'long long' exists
#  elif defined __TYPE__INTEGER____INT8
typedef __int8 integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I8d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId8"
#   endif
#  elif defined __TYPE__INTEGER____INT16
typedef __int16 integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I16d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId16"
#   endif
#  elif defined __TYPE__INTEGER____INT32
typedef __int32 integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I32d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId32"
#   endif
#  elif defined __TYPE__INTEGER____INT64
typedef __int64 integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I64d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId64"
#   endif
#  elif defined __TYPE__INTEGER____INT128
typedef __int128 integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I128d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId128"
#   endif
#  elif defined __TYPE__INTEGER__INT8_T
typedef int8_t integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I8d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId8"
#   endif
#  elif defined __TYPE__INTEGER__INT16_T
typedef int16_t integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I16d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId16"
#   endif
#  elif defined __TYPE__INTEGER__INT32_T
typedef int32_t integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I32d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId32"
#   endif
#  elif defined __TYPE__INTEGER__INT64_T
typedef int64_t integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I64d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId64"
#   endif
#  elif defined __TYPE__INTEGER__INT128_T
typedef int128_t integer;
#   if defined(_MSC_VER) && (_MSC_VER < 1800)  // MSVC older-than-2013
#define INTEGER "I128d"
#   else  // non-Windows, Windows w/ GCC, or MSVC 2013-or-newer
#include <inttypes.h>
#define INTEGER "PRId128"
#   endif
#  else
typedef long integer;  // default
#define INTEGER "ld"  // assume format code 'ld' exists if type 'long' exists
#  endif
# endif
# ifndef __CPP__INCLUDED__Perl__Type__Number_h__typedefs
#define __CPP__INCLUDED__Perl__Type__Number_h__typedefs 1
#  ifdef __TYPE__NUMBER__DOUBLE
typedef double number;
#define NUMBER "f"
#  elif defined __TYPE__NUMBER__LONG__DOUBLE
typedef long double number;
#define NUMBER "Lf"  // assume format code 'Lf' exists if type 'long double' exists
#  else
typedef double number;  // default
#define NUMBER "f"
#  endif
# endif
# ifndef __CPP__INCLUDED__Perl__Type__String_h__typedefs
#define __CPP__INCLUDED__Perl__Type__String_h__typedefs 1
typedef std::string string;
typedef std::ostringstream ostringstream;
# endif

// [[[ INCLUDES ]]]
#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// [[[ TYPE-CHECKING MACROS ]]]
#define character_CHECK(possible_character) \
	(not(SvOK(possible_character)) ? \
			croak("\nERROR ETV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ncharacter value expected but undefined/null value found,\ncroaking") : \
			(not(SvCOKp(possible_character)) ? \
					croak("\nERROR ETV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ncharacter value expected but non-character value found,\ncroaking") : \
					(void)0))
#define character_CHECKTRACE(possible_character, variable_name, subroutine_name) \
	(not(SvOK(possible_character)) ? \
			croak("\nERROR ETV00, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ncharacter value expected but undefined/null value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name) : \
			(not(SvCOKp(possible_character)) ? \
					croak("\nERROR ETV01, TYPE-CHECKING MISMATCH, CPPOPS_PERLTYPES & CPPOPS_CPPTYPES:\ncharacter value expected but non-character value found,\nin variable %s from subroutine %s,\ncroaking", variable_name, subroutine_name) : \
					(void)0))

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__Type__Character__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
int Perl__Type__Character__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// DEV NOTE, CORRELATION #rp010: the pack/unpack subs (below) are called by *_to_string_CPPTYPES(), moved outside #ifdef blocks
//# ifdef __CPP__TYPES
character XS_unpack_character(SV* input_sv);
void XS_pack_character(SV* output_sv, character input_character);
//# endif

// [[[ BOOLEANIFY ]]]
# ifdef __PERL__TYPES
SV* character_to_boolean(SV* input_character);
# elif defined __CPP__TYPES
boolean character_to_boolean(character input_character);
# endif

// [[[ UNSIGNED INTEGERIFY ]]]
# ifdef __PERL__TYPES
SV* character_to_nonsigned_integer(SV* input_character);
# elif defined __CPP__TYPES
nonsigned_integer character_to_nonsigned_integer(character input_character);
# endif

// [[[ INTEGERIFY ]]]
# ifdef __PERL__TYPES
SV* character_to_integer(SV* input_character);
# elif defined __CPP__TYPES
integer character_to_integer(character input_character);
# endif

// [[[ NUMBERIFY ]]]
# ifdef __PERL__TYPES
SV* character_to_number(SV* input_character);
# elif defined __CPP__TYPES
number character_to_number(character input_character);
# endif

// [[[ STRINGIFY ]]]
# ifdef __PERL__TYPES
SV* character_to_string(SV* input_character);
# elif defined __CPP__TYPES
string character_to_string(character input_character);
# endif

// [[[ TYPE TESTING ]]]
# ifdef __PERL__TYPES
SV* character_typetest0();
SV* character_typetest1(SV* lucky_character);
# elif defined __CPP__TYPES
character character_typetest0();
character character_typetest1(character lucky_character);
# endif

#endif
