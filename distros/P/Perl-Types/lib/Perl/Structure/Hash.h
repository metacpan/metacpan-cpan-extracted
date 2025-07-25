////use strict;  use warnings;
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Structure__Hash_h
#define __CPP__INCLUDED__Perl__Structure__Hash_h 0.009_000

#include <perltypes_mode.h> // for definitions of __PERL__TYPES or __CPP__TYPES

// [[[ SUB-TYPES BEFORE INCLUDES ]]]
#include <Perl/Structure/Hash/SubTypes.cpp>   // -> SubTypes.h
#include <Perl/Structure/Hash/SubTypes1D.cpp> // -> SubTypes1D.h
#include <Perl/Structure/Hash/SubTypes2D.cpp> // -> SubTypes2D.h
#include <Perl/Structure/Hash/SubTypes3D.cpp> // -> SubTypes3D.h

// for type-checking subroutines & macros
#include <Perl/HelperFunctions.cpp>  // -> HelperFunctions.h

// [[[ OPERATIONS & DATA TYPES REPORTER ]]]
# ifdef __PERL__TYPES
SV* Perl__Structure__Hash__MODE_ID() { return(newSViv(1)); }  // CPPOPS_PERLTYPES is 1
# elif defined __CPP__TYPES
integer Perl__Structure__Hash__MODE_ID() { return 2; }  // CPPOPS_CPPTYPES is 2
# else
Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!
# endif

#endif
