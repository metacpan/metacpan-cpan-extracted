#if !defined( _KEYBOARD_DISTANCE_H )
#define _KEYBOARD_DISTANCE_H

double c_qwertyKeyboardDistance( char* left, int llen, char* right, int rlen );
double c_qwertyCharDistance( char c1, char c2 );
int c_qwertyGetCharPos( char ch, int* x, int* y );

double c_qwertyKeyboardDistanceMatch( char* left, int llen, char* right, int rlen );

int c_initQwertyMap(void);

#endif
