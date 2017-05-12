/* $Id: prima.h,v 1.3 2012/08/01 08:11:16 dk Exp $ */

#ifdef __cplusplus
extern "C" {
#endif

#define IS_GRAY     1
#define IS_FLOAT    2
#define IS_DOUBLE   4
#define IS_COMPLEX  8

typedef struct _pim_image {
	unsigned char * data;
	unsigned char * palette;
	unsigned int    colors;
	unsigned int    line_size;
	unsigned int    width;
	unsigned int    height;
	unsigned int    bpp;
	unsigned int    category;
	
	double   resample_coeff_a;
	double   resample_coeff_b;
} pim_image;

typedef void BitCopyProc( pim_image * pim, void * src, void * dst, int width);

void
prima_bootcheck(void);

void
read_prima_image_data( SV * input, pim_image * pim);

BitCopyProc *
get_prima_bitcopy_proc( int category, int bpp_from, int bpp_to );

void
allocate_prima_image( SV * input, int width, int height, int rgb);

#ifdef __cplusplus
}
#endif
