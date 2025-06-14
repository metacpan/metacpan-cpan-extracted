#ifndef __CPP__INCLUDED__perltypes_h
#define __CPP__INCLUDED__perltypes_h 0.004_000

#include <perltypes_mode.h>
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h

#include <Perl/DataType/Boolean.cpp>	// -> Boolean.h
#include <Perl/DataType/NonsignedInteger.cpp>	// -> NonsignedInteger.h
#include <Perl/DataType/Integer.cpp>	// -> Integer.h
#include <Perl/DataType/Number.cpp>	// -> Number.h
#include <Perl/DataType/Character.cpp>	// -> Character.h
#include <Perl/DataType/String.cpp>	// -> String.h
#include <Perl/DataStructure/Array.cpp>	// -> Array.h
#include <Perl/DataStructure/Hash.cpp>	// -> Hash.h

// [[[ GENERIC OVERLOADED TYPE CONVERSION ]]]
// [[[ GENERIC OVERLOADED TYPE CONVERSION ]]]
// [[[ GENERIC OVERLOADED TYPE CONVERSION ]]]

# ifdef __PERL__TYPES

// NEED ADD CODE

# elif defined __CPP__TYPES

//number to_number(unknown input_unknown) { return std::to_number(input_boolean); }  // NEED IMPLEMENT
number to_number(boolean input_boolean) { return boolean_to_number(input_boolean); }
number to_number(nonsigned_integer input_nonsigned_integer) { return nonsigned_integer_to_number(input_nonsigned_integer); }
number to_number(integer input_integer) { return integer_to_number(input_integer); }
//number to_number(gmp_integer input_gmp_integer) { return gmp_integer_to_number(input_gmp_integer); }  // NEED IMPLEMENT
//number to_number(number input_number) { return number_to_number(input_number); }  // NEED ANSWER: is this totally unneeded, and should it be deleted?
number to_number(character input_character) { return character_to_number(input_character); }
number to_number(string input_string) { return string_to_number(input_string); }
//number to_number(* input_*) { return std::to_number(input_*); }  // NEED IMPLEMENT

// DEV NOTE, CORRELATION #rp028: renamed from Perl to_string() to C++ To_string() to avoid error redefining std::to_string()
//string To_string(unknown input_unknown) { return std::to_string(input_boolean); }  // NEED IMPLEMENT
string To_string(boolean input_boolean) { return boolean_to_string(input_boolean); }
string To_string(nonsigned_integer input_nonsigned_integer) { return nonsigned_integer_to_string(input_nonsigned_integer); }
string To_string(integer input_integer) { return integer_to_string(input_integer); }
//string To_string(gmp_integer input_gmp_integer) { return gmp_integer_to_string(input_gmp_integer); }  // NEED IMPLEMENT
string To_string(number input_number) { return number_to_string(input_number); }
string To_string(character input_character) { return character_to_string(input_character); }
string To_string(string input_string) { return string_to_string(input_string); }
//string To_string(* input_*) { return std::to_string(input_*); }  // NEED IMPLEMENT

# endif

#endif
