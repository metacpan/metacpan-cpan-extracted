#include "bit.h"
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

int bitCount (unsigned int value, int set){
 
    unsigned int bit_count;
    unsigned int c = 0;
 
    if (set){
        while (value != 0){
            c++;
            value &= value - 1;
        }
        bit_count = c;
    }
    else {
        int zeros = __builtin_clz(value);
        bit_count = (sizeof(int) * 8) - zeros;
    }
 
    return bit_count;
}
 
int bitMask (unsigned int bits, int lsb){
    return ((1 << bits) - 1) << lsb;
}
 
int bitGet (const unsigned int data, int msb, const int lsb){
 
    _checkMSB(msb);
    msb++; // we count from one

    _checkLSB(msb, lsb);
 
    return (data & (1 << msb) -1) >> lsb;
}
 
int bitSet (unsigned int data, int lsb, int bits, int value){
 
    _checkValue(value);
 
    unsigned int value_bits = bitCount(value, 0);
 
    if (value_bits != bits){
        value_bits = bits;
    }
 
    unsigned int mask = ((1 << value_bits) - 1) << lsb;
 
    data = (data & ~(mask)) | (value << lsb);
 
    return data;
}
 
int bitTog (unsigned int data, int bit){
    return data ^= 1 << bit;
}
 
int bitOn (unsigned int data, int bit){
    return data |= 1 << bit;
}
 
int bitOff (unsigned int data, int bit){
    return data &= ~(1 << bit);
}
 
void _checkMSB (int msb){
    if (msb < 0){
        croak("\nbit_get() $msb param must be greater than zero\n\n");
    }
}
 
void _checkLSB (int msb, int lsb){
    if (lsb < 0){
        croak("\nbit_get() $lsb param can not be negative\n\n");
    }
 
    if (lsb + 1 > (msb)){
        croak("\nbit_get() $lsb param must be less than or equal to $msb\n\n");
    }
}
 
void _checkValue (int value){
    if (value < 0){
        croak("\nbit_set() $value param must be zero or greater\n\n");
    }
}
