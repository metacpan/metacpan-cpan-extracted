////use strict;  use warnings;
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Structure__Array__SubTypes3D_h
#define __CPP__INCLUDED__Perl__Structure__Array__SubTypes3D_h 0.001_000

#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// for type-checking subroutines & macros
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h

// NEED ADD CODE HERE
// NEED ADD CODE HERE
// NEED ADD CODE HERE

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__Structure__Array__SubTypes3D__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
integer Perl__Structure__Array__SubTypes3D__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

// NEED ADD CODE HERE
// NEED ADD CODE HERE
// NEED ADD CODE HERE

#endif
