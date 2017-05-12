/**
   @file test layout of structures compiled with the C (!) compiler

   This is the source used to create the test data t/data/debug_info_0.lst.

   Copyright (C) 2012 by Thomas Dorner

   @author Thomas Dorner

   @note

   compile, execute and get test data with

   @verbatim
   gcc -g -O2 -W -Wall -c GccTests.c && \
   gcc -g -o GccTests GccTests.o && \
   ./GccTests && \
   readelf --debug-dump=line,info --wide GccTests \
      >GccTests.debug
   @endverbatim

   that is:   readelf -wli -W GccTests > GccTests.debug

   alternative: objdump -W -w GccTests > GccTests.debug
*/

#include <stdio.h>

#define SIZEOF(var) printf("sizeof(%s) == %ld\n", #var, sizeof(var))

typedef union
{
    short int m_00_two_shorts[2];
    long int  m_01_long;
} AnonTypedefUnion;


typedef enum
{
    value_1 = 1,
    value_2 = 42
} AnonTypedefEnum;

typedef struct
{
    long int        m_00_long;
    struct
    {
	char        m_01_00_char;
	short int   m_01_01_short;
    }               m_02_substructure;
} Structure1;
typedef Structure1* Ptr2Structure;

int main(int argc __attribute__((unused)),
         char *argv[] __attribute__((unused)))
{
    char l_object2a __attribute__((unused)); // needed by test loop
    char l_object2b __attribute__((unused)); // needed by test loop
    AnonTypedefUnion l_objectATU;
    SIZEOF(l_objectATU);
    AnonTypedefEnum l_objectATE;
    SIZEOF(l_objectATE);
    Structure1 l_object1;
    SIZEOF(l_object1);
    Ptr2Structure l_pointer1 = &l_object1;
    SIZEOF(l_pointer1);
    return 0;
}
