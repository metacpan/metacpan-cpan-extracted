// [[[ HEADER ]]]
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Type__Class__CPP_cpp
#define __CPP__INCLUDED__Perl__Type__Class__CPP_cpp 0.001_001

// [[[ INCLUDES ]]]
// BASE CLASS DOES NOT INCLUDE RPerl.cpp OR HelperFunctions.cpp
#include <Perl/Type/Class.h>  // -> (perltypes_mode.h; rperloperations.h; perltypes.h)

# ifdef __PERL__TYPES

// [[[<<< BEGIN PERL TYPES >>>]]]
// [[[<<< BEGIN PERL TYPES >>>]]]
// [[[<<< BEGIN PERL TYPES >>>]]]

// BASE CLASS CURRENTLY HAS NO FUNCTIONALITY

// [[[<<< END PERL TYPES >>>]]]
// [[[<<< END PERL TYPES >>>]]]
// [[[<<< END PERL TYPES >>>]]]

# elif defined __CPP__TYPES

// [[[<<< BEGIN CPP TYPES >>>]]]
// [[[<<< BEGIN CPP TYPES >>>]]]
// [[[<<< BEGIN CPP TYPES >>>]]]

// BASE CLASS CURRENTLY HAS NO FUNCTIONALITY

// [[[<<< END CPP TYPES >>>]]]
// [[[<<< END CPP TYPES >>>]]]
// [[[<<< END CPP TYPES >>>]]]

# else

Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!

# endif

#endif
