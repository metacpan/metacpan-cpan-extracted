// [[[ HEADER ]]]
using std::cout;  using std::cerr;  using std::endl;

#ifndef __CPP__INCLUDED__Perl__Type__Class__CPP_h
#define __CPP__INCLUDED__Perl__Type__Class__CPP_h 0.003_000

// [[[ INCLUDES ]]]
// BASE CLASS DOES NOT INCLUDE RPerl.cpp OR HelperFunctions.cpp
#include <perltypes_mode.h>  // for definitions of __PERL__TYPES or __CPP__TYPES
#include <rperloperations.h>  // for operations
#include <perltypes.h>  // for data types and structures

# ifdef __PERL__TYPES

// [[[<<< BEGIN PERL TYPES >>>]]]
// [[[<<< BEGIN PERL TYPES >>>]]]
// [[[<<< BEGIN PERL TYPES >>>]]]

// [[[ OO INHERITANCE ]]]
// BASE CLASS HAS NO INHERITANCE
class Perl__Type__Class__CPP
{
public:
// [[[ OO METHODS ]]]
    // <<< OO PROPERTIES, ACCESSORS & MUTATORS >>>
    // BASE CLASS HAS NO PROPERTIES

    // <<< CONSTRUCTOR & DESTRUCTOR >>>
    Perl__Type__Class__CPP() {}
    ~Perl__Type__Class__CPP() {}

    // <<< CLASS NAME REPORTER >>>
    virtual SV* myclassname() { return newSVpv("Perl::Type::Class", 0); }

//private:
// [[[ OO PROPERTIES ]]]
// BASE CLASS HAS NO PROPERTIES
};

// [[[ SUBROUTINES ]]]

// DEV NOTE: this is inherited by all RPerl C++ classes, which allows us to call C++ classname(object) as generated from RPerl class($object)
SV* classname(Perl__Type__Class__CPP* my_object) { return my_object->myclassname(); }

// [[[<<< END PERL TYPES >>>]]]
// [[[<<< END PERL TYPES >>>]]]
// [[[<<< END PERL TYPES >>>]]]

# elif defined __CPP__TYPES

// [[[<<< BEGIN CPP TYPES >>>]]]
// [[[<<< BEGIN CPP TYPES >>>]]]
// [[[<<< BEGIN CPP TYPES >>>]]]

// [[[ RAWPTR DEFINES ]]]
#define get_raw() get()
#define set_raw(X) reset(X)

// [[[ OO INHERITANCE ]]]
// BASE CLASS HAS NO INHERITANCE
class Perl__Type__Class__CPP
{
public:
// [[[ OO METHODS ]]]
    // <<< OO PROPERTIES, ACCESSORS & MUTATORS >>>
    // BASE CLASS HAS NO PROPERTIES

    // <<< CONSTRUCTOR & DESTRUCTOR >>>
    Perl__Type__Class__CPP() {}
    ~Perl__Type__Class__CPP() {}

    // <<< CLASS NAME REPORTER >>>
    virtual string myclassname() { return (const string) "Perl::Type::Class"; }

//private:
// [[[ OO PROPERTIES ]]]
// BASE CLASS HAS NO PROPERTIES
};

// [[[ SUBROUTINES ]]]

// DEV NOTE: this is inherited by all RPerl C++ classes, which allows us to call C++ classname(object) as generated from RPerl class($object)
string classname(Perl__Type__Class__CPP* my_object) { return my_object->myclassname(); }

// [[[<<< END CPP TYPES >>>]]]
// [[[<<< END CPP TYPES >>>]]]
// [[[<<< END CPP TYPES >>>]]]

# else

Purposefully_die_from_a_compile-time_error,_due_to_neither___PERL__TYPES_nor___CPP__TYPES_being_defined.__We_need_to_define_exactly_one!

# endif

#endif
