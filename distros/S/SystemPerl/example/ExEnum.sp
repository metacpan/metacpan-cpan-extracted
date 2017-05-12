// DESCRIPTION: SystemPerl: Example source module
//
// Copyright 2001-2014 by Wilson Snyder.  This program is free software;
// you can redistribute it and/or modify it under the terms of either the
// GNU Lesser General Public License Version 3 or the Perl Artistic License
// Version 2.0.

#sp interface
#include <fstream>

#define FUNC0() 7
#define FUNC1(a) a
#define FUNC4(a,b,c,d) 1+d

class MyENumClass {
public:
    static const unsigned SIX_DEF = 6;
    enum en {
	IDLE = 0,
	ONE, TWO, THREE, FOUR,
	SIX = SIX_DEF,
	SEVEN = FUNC0(),
	EIGHT = FUNC1(FUNC4(1,2,3,FUNC0()))
    };
    /*AUTOENUM_CLASS(MyENumClass.en)*/
};
/*AUTOENUM_GLOBAL(MyENumClass.en)*/

class MyENumSimple {
public:
    enum en {
	ONE=1,
	TWO,
	THREE=3, NINE=9, TWENTYSEVEN=27
    };
    /*AUTOENUM_CLASS(MyENumSimple.en)*/
};
/*AUTOENUM_GLOBAL(MyENumSimple.en)*/

#sp implementation

