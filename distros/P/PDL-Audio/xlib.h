/* this is an icluded .c file, _not_ a header file */
/* likewise, xaudio.c is an included xs file, _not_ a c file */
/* but well, so's life! */

#include <math.h>
#include <stdlib.h>

#include "remez.h"

#ifndef M_PI
# define M_PI	3.1415926535897932384626433832795029
#endif
#ifndef M_2PI
# define M_2PI	(2. * M_PI)
#endif

unsigned char st_linear_to_ulaw(int sample);
int st_ulaw_to_linear(unsigned char ulawbyte);
unsigned char st_linear_to_Alaw(int sample);
int st_Alaw_to_linear(unsigned char Alawbyte);

typedef double Float;

void mus_src (Float *input, int inpsize, Float *output, int outsize, Float srate, Float *sr_mod, int width);
void mus_granulate (Float *input, int insize,
	       Float *output, int outsize,
	       Float expansion, Float flength, Float scaler,
	       Float hop, Float ramp, Float jitter, int max_size);
void mus_convolve (Float * input, Float * output, int size, Float * filter, int fftsize, int filtersize);

