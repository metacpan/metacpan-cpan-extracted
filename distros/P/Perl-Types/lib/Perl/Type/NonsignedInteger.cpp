using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Type__NonsignedInteger_cpp
#define __CPP__INCLUDED__Perl__Type__NonsignedInteger_cpp 0.009_000

// [[[ INCLUDES ]]]
#include <Perl/Type/NonsignedInteger.h>  // -> NULL (relies on native C type)
#include <Perl/Type/Boolean.cpp>  // -> Boolean.h
#include <Perl/Type/Integer.cpp>  // -> Integer.h
#include <Perl/Type/Number.cpp>  // -> Number.h
#include <Perl/Type/Character.cpp>  // -> Character.h
#include <Perl/Type/String.cpp>  // -> String.h

// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]
// [[[ TYPEMAP PACK/UNPACK FOR __CPP__TYPES ]]]

// DEV NOTE, CORRELATION #rp010: the pack/unpack subs (below) are called by *_to_string_CPPTYPES(), moved outside #ifdef blocks
//# ifdef __CPP__TYPES

// convert from (Perl SV containing nonsigned_integer) to (C nonsigned_integer)
nonsigned_integer XS_unpack_nonsigned_integer(SV* input_sv) {
//fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_nonsigned_integer(), top of subroutine\n");
//	nonsigned_integer_CHECK(input_sv);
	nonsigned_integer_CHECKTRACE(input_sv, "input_sv", "XS_unpack_nonsigned_integer()");

//	nonsigned_integer output_nonsigned_integer;

//	if (SvIOKp(input_sv)) { output_nonsigned_integer = SvIV(input_sv); } else { croak("in CPPOPS_CPPTYPES XS_unpack_nonsigned_integer(), input_sv was not an nonsigned_integer"); }
//	output_nonsigned_integer = SvIV(input_sv);

//fprintf(stderr, "in CPPOPS_CPPTYPES XS_unpack_nonsigned_integer(), bottom of subroutine\n");

	return((nonsigned_integer)SvIV(input_sv));
//	return(output_nonsigned_integer);
}

// convert from (C nonsigned_integer) to (Perl SV containing nonsigned_integer)
void XS_pack_nonsigned_integer(SV* output_sv, nonsigned_integer input_nonsigned_integer) {
//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_nonsigned_integer(), top of subroutine\n");
//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_nonsigned_integer(), received input_nonsigned_integer = %"INTEGER"\n", input_nonsigned_integer);

	sv_setsv(output_sv, sv_2mortal(newSViv(input_nonsigned_integer)));

//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_nonsigned_integer(), have output_sv = '%s'\n", SvPV_nolen(output_sv));
//fprintf(stderr, "in CPPOPS_CPPTYPES XS_pack_nonsigned_integer(), bottom of subroutine\n");
}

//# endif

// [[[ BOOLEANIFY ]]]
// [[[ BOOLEANIFY ]]]
// [[[ BOOLEANIFY ]]]

# ifdef __PERL__TYPES

SV* nonsigned_integer_to_boolean(SV* input_nonsigned_integer) {
//  nonsigned_integer_CHECK(input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE(input_nonsigned_integer, "input_nonsigned_integer", "nonsigned_integer_to_boolean()");
    if (SvIV(input_nonsigned_integer) == 0) { return input_nonsigned_integer; }
    else { return newSViv(1); }
}

# elif defined __CPP__TYPES

boolean nonsigned_integer_to_boolean(nonsigned_integer input_nonsigned_integer) {
    if (input_nonsigned_integer == 0) { return (boolean) input_nonsigned_integer; }
    else { return 1; }
}

# endif

// [[[ UNSIGNED INTEGERIFY ]]]
// [[[ UNSIGNED INTEGERIFY ]]]
// [[[ UNSIGNED INTEGERIFY ]]]

# ifdef __PERL__TYPES

SV* nonsigned_integer_to_integer(SV* input_nonsigned_integer) {
//  nonsigned_integer_CHECK(input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE(input_nonsigned_integer, "input_nonsigned_integer", "nonsigned_integer_to_integer()");
    if (SvIV(input_nonsigned_integer) < 0) { return newSViv(SvIV(input_nonsigned_integer) * -1); }
    else { return input_nonsigned_integer; }
}

# elif defined __CPP__TYPES

integer nonsigned_integer_to_integer(nonsigned_integer input_nonsigned_integer) {
    // DEV NOTE: do not perform comparison with nonsigned_integer, "comparison of unsigned expression < 0 is always false"
//    if (input_nonsigned_integer < 0) { return (integer) (input_nonsigned_integer * -1); }
//    else { return (integer) input_nonsigned_integer; }
    return (integer) input_nonsigned_integer;
}

# endif

// [[[ NUMBERIFY ]]]
// [[[ NUMBERIFY ]]]
// [[[ NUMBERIFY ]]]

# ifdef __PERL__TYPES

SV* nonsigned_integer_to_number(SV* input_nonsigned_integer) {
//  nonsigned_integer_CHECK(input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE(input_nonsigned_integer, "input_nonsigned_integer", "nonsigned_integer_to_number()");
    return input_nonsigned_integer;
}

# elif defined __CPP__TYPES

number nonsigned_integer_to_number(nonsigned_integer input_nonsigned_integer) {
    return (number) input_nonsigned_integer;
}

# endif

// [[[ CHARACTERIFY ]]]
// [[[ CHARACTERIFY ]]]
// [[[ CHARACTERIFY ]]]

# ifdef __PERL__TYPES

/* DISABLE UNTIL COMPLETE, TO AVOID C++ COMPILER WARNINGS
SV* nonsigned_integer_to_character(SV* input_nonsigned_integer) {
//  nonsigned_integer_CHECK(input_nonsigned_integer);
    nonsigned_integer_CHECKTRACE(input_nonsigned_integer, "input_nonsigned_integer", "nonsigned_integer_to_character()");
    // NEED ADD CODE
}
*/

# elif defined __CPP__TYPES

character nonsigned_integer_to_character(nonsigned_integer input_nonsigned_integer) {
    // NEED OPTIMIZE: remove call to nonsigned_integer_to_string_CPPTYPES()
    return (character) nonsigned_integer_to_string_CPPTYPES(input_nonsigned_integer).at(0);
}

# endif

// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]
// [[[ STRINGIFY ]]]

# ifdef __PERL__TYPES

SV* nonsigned_integer_to_string(SV* input_nonsigned_integer) {
//	nonsigned_integer_CHECK(input_nonsigned_integer);
	nonsigned_integer_CHECKTRACE(input_nonsigned_integer, "input_nonsigned_integer", "nonsigned_integer_to_string()");
//	fprintf(stderr, "in CPPOPS_PERLTYPES nonsigned_integer_to_string(), top of subroutine, received unformatted input_nonsigned_integer = %"INTEGER"\n", (nonsigned_integer)SvIV(input_nonsigned_integer));
//	fprintf(stderr, "in CPPOPS_PERLTYPES nonsigned_integer_to_string()...\n");

    // DEV NOTE: disable old stringify w/out underscores
//	return(newSVpvf("%"INTEGER"", (nonsigned_integer)SvIV(input_nonsigned_integer)));

    return(newSVpv((const char *)((nonsigned_integer_to_string_CPPTYPES((nonsigned_integer)SvIV(input_nonsigned_integer))).c_str()), 0));
}

# elif defined __CPP__TYPES

// DEV NOTE, CORRELATION #rp010: shim CPPTYPES sub
string nonsigned_integer_to_string(nonsigned_integer input_nonsigned_integer) {
    return(nonsigned_integer_to_string_CPPTYPES(input_nonsigned_integer));
}

# endif

// DEV NOTE, CORRELATION #rp009: must use return type 'string' instead of 'std::string' for proper typemap pack/unpack function name alignment;
// can cause silent failure, falling back to __PERL__TYPES implementation and NOT failure of tests!
// DEV NOTE, CORRELATION #rp010: the real CPPTYPES sub (below) is called by the wrapper PERLTYPES sub and shim CPPTYPES subs (above), moved outside #ifdef blocks
string nonsigned_integer_to_string_CPPTYPES(nonsigned_integer input_nonsigned_integer)
{
//    fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES(), top of subroutine, received unformatted input_nonsigned_integer = %"INTEGER"\n", input_nonsigned_integer);
//    fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES()...\n");

    std::ostringstream output_stream;
    output_stream.precision(std::numeric_limits<double>::digits10);
    output_stream << input_nonsigned_integer;

    // DEV NOTE: disable old stringify w/out underscores
//  return(output_stream.str());

    string output_string = output_stream.str();
//    fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES(), have output_string = %s\n", output_string.c_str());

    boolean is_negative = 0;
    // DEV NOTE: do not perform comparison with nonsigned_integer, "comparison of unsigned expression < 0 is always false"
//    if (input_nonsigned_integer < 0) { is_negative = 1; }

    std::reverse(output_string.begin(), output_string.end());

//    fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES(), have reversed output_string = %s\n", output_string.c_str());
    if (is_negative) { output_string.pop_back(); }  // remove negative sign

    string output_string_underscores = "";
    for(std::string::size_type i = 0; i < output_string.size(); ++i) {
//        fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES(), inside output_string underscore loop, have i = %"INTEGER", output_string[i] = %c\n", (int)i, output_string[i]);
        output_string_underscores += output_string[i];
        if (((i % 3) == 2) && (i > 0) && (i != (output_string.size() - 1))) {
//            fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES(), AND UNDERSCORE \n");
            output_string_underscores += '_';
        }
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES(), have reversed output_string_underscores = %s\n", output_string_underscores.c_str());

    std::reverse(output_string_underscores.begin(), output_string_underscores.end());

    if (output_string_underscores == "") {
        output_string_underscores = "0";
    }

//    fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_to_string_CPPTYPES(), have unreversed output_string_underscores = %s\n", output_string_underscores.c_str());

    if (is_negative) { output_string_underscores = '-' + output_string_underscores; }

    return output_string_underscores;
}

// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]
// [[[ TYPE TESTING ]]]

# ifdef __PERL__TYPES

SV* nonsigned_integer_typetest0() {
	SV* retval = newSViv((21 / 7) + SvIV(Perl__Type__NonsignedInteger__MODE_ID()));
//fprintf(stderr, "in CPPOPS_PERLTYPES nonsigned_integer_typetest0(), have retval = %"INTEGER"\n", (nonsigned_integer)SvIV(retval));
	return retval;
}

SV* nonsigned_integer_typetest1(SV* lucky_nonsigned_integer) {
//	nonsigned_integer_CHECK(lucky_nonsigned_integer);
	nonsigned_integer_CHECKTRACE(lucky_nonsigned_integer, "lucky_nonsigned_integer", "nonsigned_integer_typetest1()");
//fprintf(stderr, "in CPPOPS_PERLTYPES nonsigned_integer_typetest1(), received lucky_nonsigned_integer = %"INTEGER"\n", (nonsigned_integer)SvIV(lucky_nonsigned_integer));
	return newSViv((SvIV(lucky_nonsigned_integer) * 2) + SvIV(Perl__Type__NonsignedInteger__MODE_ID()));
}

# elif defined __CPP__TYPES

nonsigned_integer nonsigned_integer_typetest0() {
	nonsigned_integer retval = (21 / 7) + Perl__Type__NonsignedInteger__MODE_ID();
//fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_typetest0(), have retval = %"INTEGER"\n", retval);
	return retval;
}

nonsigned_integer nonsigned_integer_typetest1(nonsigned_integer lucky_nonsigned_integer) {
//fprintf(stderr, "in CPPOPS_CPPTYPES nonsigned_integer_typetest1(), received lucky_nonsigned_integer = %"INTEGER"\n", lucky_nonsigned_integer);
	return (lucky_nonsigned_integer * 2) + Perl__Type__NonsignedInteger__MODE_ID();
}

# endif

#endif
