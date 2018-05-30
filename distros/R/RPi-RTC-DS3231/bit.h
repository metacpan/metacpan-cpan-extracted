#ifndef _BIT_H_
#define _BIT_H_
#endif

int bitCount (unsigned int value, int set);
int bitMask  (unsigned int bits, int lsb);
int bitGet   (const unsigned int data, int msb, const int lsb);
int bitSet   (unsigned int data, int lsb, int bits, int value);
int bitTog   (unsigned int data, int bit);
int bitOn    (unsigned int data, int bit);
int bitOff   (unsigned int data, int bit);
 
void _checkMSB   (int msb);
void _checkLSB   (int msb, int lsb);
void _checkValue (int value);
