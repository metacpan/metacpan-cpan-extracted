#include <math.h>
#include <stdio.h>
#include <stdlib.h>

double double_double( double d );
float  double_float(  float  f );
int    double_int(    int    i );
short  double_short(  short  s );

char * change_string( char *p );
float  square_root(   float x );

int multiply_ints( int x, int y );

typedef struct _some_struct
{
	int    x;
	double y;
} some_struct;

some_struct* make_struct();
void set_x_value( some_struct *s, int x );
int  get_x_value( some_struct *s );
void free_struct( some_struct *s );

double double_double( double d )
{
	return d * 2.0;
}

float double_float( float f )
{
	return f * 2.0;
}

int double_int( int i )
{
	return i * 2;
}

short double_short( short s )
{
	return s * 2;
}

int multiply_ints( int x, int y )
{
	return x * y;
}

static char s[] = "X string\n";
char* change_string( char *p )
{
	s[0] = p[0];
	return s;
}

float square_root( float x )
{
	return sqrt( x );
}

some_struct* make_struct ()
{
	some_struct *s = malloc( sizeof( some_struct ) );
	return s;
}

void set_x_value ( some_struct *s, int x )
{
	s->x = x;
	return;
}

int  get_x_value ( some_struct *s )
{
	return s->x;
}

void free_struct ( some_struct *s )
{
	free( s );
	return;
}
