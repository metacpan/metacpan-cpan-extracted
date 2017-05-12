/**
   @file test layout of structures

   This is the source used to create the newest version (highest version
   number N) of the test data t/data/debug_info_N.lst.

   Copyright (C) 2006-2012 by Thomas Dorner

   @author Thomas Dorner

   @note

   compile, execute and get test data with

   @verbatim
   g++ -g -O2 -W -Wall -c StructureLayoutTest.cpp && \
   g++ -g -o StructureLayoutTest StructureLayoutTest.o && \
   ./StructureLayoutTest && \
   readelf --debug-dump=line,info --wide StructureLayoutTest \
      >StructureLayoutTest.debug
   @endverbatim

   that is:   readelf -wli -W StructureLayoutTest > StructureLayoutTest.debug

   alternative: objdump -W -w StructureLayoutTest > StructureLayoutTest.debug
*/
#include <cstddef>
#include <iostream>

struct Structure1; // forward reference
typedef struct Structure1* Ptr2Structure1;

struct Structure1
{
    long            m_00_long;
    char            m_01_char_followed_by_filler_for_short;
    short           m_02_short;
    char            m_03_char_array_6[6];
    void*           m_04_pointer;
    char            m_06_char_followed_by_filler_for_bit_array;
    unsigned int    m_07_00_1_int_bit:1;
    unsigned int    m_07_01_2_int_bits:2;
    unsigned int    m_07_02_3_int_bits:3;
    char            m_08_char_between_bit_arrays_followed_by_filler;
    unsigned char   m_09_00_1_char_bit:1;
    unsigned char   m_09_01_2_char_bits:2;
    unsigned char   m_09_02_3_char_bits:3;
    struct
    {
	char        m_10_00_char;
	short       m_10_01_short;
    }               m_10_substructure;
    char            m_11_final_char;
};

struct Structure2
{
    char            m_00_char;
    long long       m_01_long_long;
};
struct Structure5
{
    char            m_00_char;
    short           m_01_short_array_3_4[3][4];
    long            m_02_long;
};

class StructureWithUnion
{
    unsigned short  m_00_short;
    struct
    {
        short       m_01_00_4_short_bits:4;
        short       m_01_01_12_short_bits:12;
    }               m_01_substructure;
    int             m_02_int;
    union
    {
        unsigned    m_03_00_24_first_int_bits:24;
        struct
        {
            char     m_03_01_00_char_array_3[3];
            unsigned m_03_01_01_24_second_int_bits:24;
        };
    };
};
class ClassWithInline
{
    Structure2 m_01_structure2;
public:
    void foo(long long p_long_long)
        {
            m_01_structure2.m_01_long_long = p_long_long;
            Structure2 l_object2_foo = m_01_structure2;
            std::cout << "sizeof(l_object2_foo) == "
                      << sizeof(l_object2_foo) << "\n";
        };
    void bar(long long p_long_long);
};
inline void ClassWithInline::bar(long long p_long_long)
{
    m_01_structure2.m_01_long_long = p_long_long;
    Structure2 l_object2_bar = m_01_structure2;
    std::cout << "sizeof(l_object2_bar) == " << sizeof(l_object2_bar) << "\n";
};

int main()
{
    Structure1 l_object1;
    Ptr2Structure1 l_pointer1 = &l_object1;
    Structure2 l_object2a;
    Structure2 l_object2b;
    const Structure2& l_cObject2b = l_object2b;
    struct Structure3
    {
	short       m_00_short;
	short       m_01_short;
    } l_object3;
    struct
    {
	int         m_00_int;
	std::string m_string;
	int         m_01_int;
    } l_object4;
    volatile const int& l_cvInt = l_object4.m_01_int;
    l_object4.m_string = "Teststring";
    Structure5 l_object5;
    static StructureWithUnion l_objectU;
    std::cout << "sizeof(Structure1) == "  << sizeof(Structure1)  << "\n"
	      << "offsetof(Structure1, m_04_pointer) == "
	      <<  offsetof(Structure1, m_04_pointer)              << "\n"
	      << "sizeof(l_pointer1) == "  << sizeof(l_pointer1)  << "\n"
	      << "sizeof(l_object1) == "   << sizeof(l_object1)   << "\n"
	      << "sizeof(l_object2a) == "  << sizeof(l_object2a)  << "\n"
	      << "sizeof(l_object2b) == "  << sizeof(l_object2b)  << "\n"
	      << "sizeof(l_cObject2b) == " << sizeof(l_cObject2b) << "\n"
	      << "sizeof(l_object3) == "   << sizeof(l_object3)   << "\n"
	      << "sizeof(l_object4) == "   << sizeof(l_object4)   << "\n"
	      << "sizeof(l_object5) == "   << sizeof(l_object5)   << "\n"
	      << "sizeof(l_cvInt) == "     << sizeof(l_cvInt)     << "\n"
	      << "sizeof(l_objectU) == "   << sizeof(l_objectU)   << "\n";
    ClassWithInline l_objectI;
    l_objectI.foo(42);
    l_objectI.bar(42);
}
