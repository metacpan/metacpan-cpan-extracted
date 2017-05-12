#include "keyboardDistance.h"
#include <stdlib.h>
#include <math.h>
#include <string.h>


/* sqrt( 13**2 + 3**2 ) */
#define MAX_KBD_DISTANCE 13.34166406412633371248

/* character map for fast lookups... */
#define X_POS 0
#define Y_POS 0
int qwertyMap[0xFF][2];

char* qwertyGrid[] = {
  "`1234567890-= ",
  "\tqwertyuiop[]\\",
  " asdfghjkl;\' ",
  " zxcvbnm,./  ",
};

char* qwertyShiftedGrid[] = {
  "~!@#$%^&*()_+ ",
  "\tQWERTYUIOP{}|",
  " ASDFGHJKL:\" ",
  " ZXCVBNM<>?  ",
};

#define GRID_DISTANCE(x1,y1,x2,y2) ( ( x1 == x2 && y1 == y2 ) ? 0 : ( 1 == abs(x1-x2) && 1 == abs(y1-y2) ) ? 1 : sqrt( (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) ) )

double c_gridDistance( int x1, int y1, int x2, int y2 )
{
  return ( x1 == x2 && y1 == y2 ) ? 0
       : ( 1 == abs(x1-x2) && 1 == abs(y1-y2) ) ? 1
       : sqrt( (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) );
            
}

double c_qwertyKeyboardDistanceMatch( char* left, int llen, char* right, int rlen )
{
  char *ptmp;
	int i;
	double maxDist;

  if( rlen > llen ) {
    i = llen;
		llen = rlen;
		rlen = i;

		ptmp = left;
		left = right;
		right = ptmp;
  }

	maxDist = MAX_KBD_DISTANCE * llen;

	return (maxDist - c_qwertyKeyboardDistance(left,llen,right,rlen)) / maxDist;
}

double c_qwertyKeyboardDistance( char* left, int llen, char* right, int rlen )
{
  char *ptmp;
	int i;
	double distance = 0.0, dist;

  if( rlen > llen ) {
    i = llen;
		llen = rlen;
		rlen = i;

		ptmp = left;
		left = right;
		right = ptmp;
  }

	for( i = 0; i < rlen; ++i ) {
    dist = c_qwertyCharDistance( left[i], right[i] );
		/* printf("%s(%d) dist(%c,%c) = %f\n",__FILE__,__LINE__,left[i],right[i],dist); */
    distance += dist;
  }

	while( i < llen ) {
    distance += MAX_KBD_DISTANCE;
		++i;
  }

	return distance;
}

double c_qwertyCharDistance( char c1, char c2 )
{
#if 0
  int x1,y1,x2,y2;
  if( ! c_qwertyGetCharPos( c1, &x1, &y1 ) ) {
    return MAX_KBD_DISTANCE;
  }

  if( ! c_qwertyGetCharPos( c2, &x2, &y2 ) ) {
    return MAX_KBD_DISTANCE;
  }

  return GRID_DISTANCE( x1,y1, x2,y2 );
#else
	if( c1 > 0xFF || c2 > 0xFF ) {
    return MAX_KBD_DISTANCE;
  }

  return GRID_DISTANCE( qwertyMap[c1][X_POS], qwertyMap[c1][Y_POS],
                        qwertyMap[c2][X_POS], qwertyMap[c2][Y_POS] );
#endif
}


int c_qwertyGetCharPos( char ch, int* x, int* y )
{
  int i,j,gridSize,elementSize;
  gridSize = sizeof(qwertyGrid) / sizeof(qwertyGrid[0]);
  elementSize = strlen(qwertyGrid[0]);

  for( i = 0; i < gridSize; ++i ) {
    for( j = 0; j < elementSize; ++j ) {
      if( ch == qwertyGrid[i][j] || ch == qwertyShiftedGrid[i][j] ) {
        *x = i;
        *y = j;
        return 1;
      }
    }
  }
  return 0;
}


int c_initQwertyMap( void )
{
  int i,j,gridSize,elementSize;
	char ch;

	memset( qwertyMap, MAX_KBD_DISTANCE, 0xFF * 2 );
  gridSize = sizeof(qwertyGrid) / sizeof(qwertyGrid[0]);
  elementSize = strlen(qwertyGrid[0]);
  for( i = 0; i < gridSize; ++i ) {
    for( j = 0; j < elementSize; ++j ) {
      ch = qwertyGrid[i][j];
      qwertyMap[ (int)ch ][X_POS] = i;
      qwertyMap[ (int)ch ][Y_POS] = j;

      ch = qwertyShiftedGrid[i][j];
      qwertyMap[ (int)ch ][X_POS] = i;
      qwertyMap[ (int)ch ][Y_POS] = j;
    }
  }
  return 1;
}


