using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Type__Character_cpp
#define __CPP__INCLUDED__Perl__Type__Character_cpp 0.003_000

// [[[ INCLUDES ]]]
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h
#include <Perl/Type/Character.h>  // -> NULL (relies on native C type)
#include <Perl/Type/Boolean.cpp>  // -> Boolean.h
#include <Perl/Type/NonsignedInteger.cpp>  // -> NonsignedInteger.h
#include <Perl/Type/Integer.cpp>  // -> Integer.h
#include <Perl/Type/Number.cpp>  // -> Number.h
#include <Perl/Type/String.cpp>  // -> String.h

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

// DEV NOTE, CORRELATION #rp010: the pack/unpack subs (below) are called by *_to_string_CPPTYPES(), moved outside #ifdef blocks
//# ifdef __CPP__TYPES

// convert from (Perl SV containing character) to (C character)
character XS_unpack_character(SV* input_sv) {
//	character_CHECK(input_sv);
	character_CHECKTRACE(input_sv, "input_sv", "XS_unpack_character()");
	return((character) (SvPV_nolen(input_sv))[1]);
}

// convert from (C character) to (Perl SV containing character)
void XS_pack_character(SV* output_sv, character input_character) {
//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_character(), top of subroutine\n");
//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_character(), received input_character = %"INTEGER"\n", input_character);

	sv_setsv(output_sv, sv_2mortal(newSVpvf("%c", input_character)));

//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_character(), have output_sv = '%s'\n", SvPV_nolen(output_sv));
//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_character(), bottom of subroutine\n");
}

//# endif

// [[[ BOOLEANIFY ]]]
// [[[ BOOLEANIFY ]]]
// [[[ BOOLEANIFY ]]]

# ifdef __PERL__TYPES

/* DISABLE UNTIL COMPLETE, TO AVOID C++ COMPILER WARNINGS
SV* character_to_boolean(SV* input_character) {
//  character_CHECK(input_character);
    character_CHECKTRACE(input_character, "input_character", "character_to_boolean()");
    // NEED ADD CODE
}
*/

# elif defined __CPP__TYPES

boolean character_to_boolean(character input_character) {
    if ((input_character - '0') == 0) { return 0; }
    else { return 1; }
}

# endif

// [[[ UNSIGNED INTEGERIFY ]]]
// [[[ UNSIGNED INTEGERIFY ]]]
// [[[ UNSIGNED INTEGERIFY ]]]

# ifdef __PERL__TYPES

/* DISABLE UNTIL COMPLETE, TO AVOID C++ COMPILER WARNINGS
SV* character_to_nonsigned_integer(SV* input_character) {
//  character_CHECK(input_character);
    character_CHECKTRACE(input_character, "input_character", "character_to_nonsigned_integer()");
    // NEED ADD CODE
}
*/

# elif defined __CPP__TYPES

nonsigned_integer character_to_nonsigned_integer(character input_character) {
    return (nonsigned_integer) (input_character - '0');
}

# endif

// [[[ INTEGERIFY ]]]
// [[[ INTEGERIFY ]]]
// [[[ INTEGERIFY ]]]

# ifdef __PERL__TYPES

/* DISABLE UNTIL COMPLETE, TO AVOID C++ COMPILER WARNINGS
SV* character_to_integer(SV* input_character) {
//  character_CHECK(input_character);
    character_CHECKTRACE(input_character, "input_character", "character_to_integer()");
    // NEED ADD CODE
}
*/

# elif defined __CPP__TYPES

integer character_to_integer(character input_character) {
    return (integer) (input_character - '0');
}

# endif

// [[[ NUMBERIFY ]]]
// [[[ NUMBERIFY ]]]
// [[[ NUMBERIFY ]]]

# ifdef __PERL__TYPES

/* DISABLE UNTIL COMPLETE, TO AVOID C++ COMPILER WARNINGS
SV* character_to_number(SV* input_character) {
//  character_CHECK(input_character);
    character_CHECKTRACE(input_character, "input_character", "character_to_number()");
    // NEED ADD CODE
}
*/

# elif defined __CPP__TYPES

number character_to_number(character input_character) {
    return (number) (input_character - '0');
}

# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES

SV* character_to_string(SV* input_character) {
//	character_CHECK(input_character);
	character_CHECKTRACE(input_character, "input_character", "character_to_string()");
//	fprintf(stderr, "in CPPOPS_PERLTYPES character_to_string(), top of subroutine, received unformatted input_character = %s\n", SvPV_nolen(input_character));
	return input_character;
}

# elif defined __CPP__TYPES

string character_to_string(character input_character) {
    string retval(1, input_character);
    return retval;
}

# endif

// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES

SV* character_typetest0() {
	return newSVpvf("%c", (character) (SvIV(Perl__Type__Character__MODE_ID()) + '0'));
}

SV* character_typetest1(SV* lucky_character) {
//	character_CHECK(lucky_character);
	character_CHECKTRACE(lucky_character, "lucky_character", "character_typetest1()");
//fprintf(stderr, "in CPPOPS_PERLTYPES character_typetest1(), received lucky_character = %"INTEGER"\n", SvIV(lucky_character));
	return newSVpvf("%c", (character) ((SvPV_nolen(lucky_character))[0] + SvIV(Perl__Type__Character__MODE_ID())));
}

# elif defined __CPP__TYPES

character character_typetest0() {
	return (Perl__Type__Character__MODE_ID() + '0');
}

character character_typetest1(character lucky_character) {
    return (lucky_character + Perl__Type__Character__MODE_ID());
}

# endif

#endif
