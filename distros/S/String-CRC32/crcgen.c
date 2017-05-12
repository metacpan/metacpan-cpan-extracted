/*
 Generation of CRC lookup table
 as used in Perl module "String::CRC32"

 1999 by Soenke J. Peters <peters__perl@opcenter.de>
*/

#include <stdio.h>

int
main ( void )
{ 
  unsigned long crc, poly;
  int     i, j;

  poly = 0xEDB88320L;
  
  printf("unigned long\ncrcTable[256] = {\n");
  for (i=0; i<256; i++) {
    crc = i;
    for (j=8; j>0; j--) {
      if (crc&1) {
        crc = (crc >> 1) ^ poly;
      } else {
        crc >>= 1;
      }
    }
    printf( "0x%lx,", crc);
    if( (i&7) == 7 )
      printf("\n" );
    else
      printf(" ");
  }
  printf("};\n");
  return 0;
}
