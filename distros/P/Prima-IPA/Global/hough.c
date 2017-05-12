/*
   Hough line transform. 
   Direct transform code adapted from code by Timothy Sharman
   (http://homepages.inf.ed.ac.uk/rbf/HIPR2/flatjavasrc/Hough.java)
*/   

#include "IPAsupp.h"
#include "Global.h"
#include <math.h>
#include <stdio.h>

static struct {
	int	  size;
	double  * sinx;
	double  * cosx;
} trig_table = { 0, NULL, NULL };

#define SIN(x) trig_table.sinx[x]
#define COS(x) trig_table.cosx[x]

static void
fill_trig_table( int resolution )
{
	int i;
	double dth;
	if ( trig_table.size == resolution)
		return;
	dth = 3.14159265358979323846264338327950288419716939937510 / resolution;
	if (trig_table.size > 0) {
		free( trig_table. sinx);
		trig_table. sinx = NULL;
	}
	trig_table. sinx = malloc( sizeof(double) * resolution * 2);
	if ( !trig_table. sinx)
		croak("cannot allocate %d bytes", 
		sizeof(double) * resolution * 2);
	trig_table. cosx = trig_table. sinx + resolution;
	trig_table. size = resolution;
	for ( i = 0; i < resolution; i++) {
		trig_table. sinx[i] = sin(dth * (double)i);
		trig_table. cosx[i] = cos(dth * (double)i);
	}
}

/* direct Hough transform */
PImage 
IPA__Global_hough(PImage img,HV *profile)
{
#define METHOD "IPA::Global::hough"
	dPROFILE;
	PImage ret;
	int resolution = 500;
	char * type = "line";

	int cx, cy, x, y, z;
	double  h_h, dh;
	PImage dup = NULL;
	Byte * src, * dst;
	
	/* check input */
	if ( !img || !kind_of(( Handle) img, CImage))
		croak("%s: not an image passed", METHOD);
	
	if ( pexist( resolution))  resolution = pget_i( resolution);
	if ( resolution < 4 || resolution > 16384)
		croak("%s: bad resolution", METHOD);
	
	if ( pexist( type)) type = pget_c( type);
	if ( strcmp( type, "line") != 0)
		croak("%s: bad type: must be 'line'", METHOD);
	
	/* create intermediate image */
	if ( img-> type != imByte) {
   		dup = ( PImage) img-> self-> dup(( Handle) img);
		if ( !dup) croak( "%s: Return image allocation failed", METHOD);
   		dup-> self-> set_type(( Handle) dup, imByte); 
		img = dup;
	}

	/* create output image */
	cx  = img-> w / 2;
	cy  = img-> h / 2;
	h_h = sqrt(2) * (double) (( img-> w > img-> h) ? img-> w : img-> h);
	dh  = h_h / 2;
	ret = createImage( resolution, (int)(h_h + 0.5), imByte);
	if ( !ret) croak( "%s: Return image allocation failed", METHOD);
	dst = ret-> data;
	++SvREFCNT( SvRV( ret-> mate));
	fill_trig_table(resolution);
	
	/* do the transform */
	for ( 
		y = 0, src = img-> data;
		y < img-> h; 
		y++, src += img-> lineSize
	) {
		for ( x = 0; x < img-> w; x++) {
			if ( src[x] != 0) {
				int dy = ret-> h;
				for ( z = 0; z < resolution; z++) {
					int r = (int)(
						SIN(z) * (double)(x - cx) +
						COS(z) * (double)(y - cy) +
						dh + 0.5);
					if ( r >= 0 && r < dy)
						dst[ r * ret-> lineSize + z]++;
				}
			}
		}
	}

	/* finalize */
	if ( dup) destroyImage( dup);
	--SvREFCNT( SvRV( ret-> mate));           
	return ret;
#undef METHOD   
}

/* inverse Hough transform */
SV * 
IPA__Global_hough2lines(PImage img, HV * profile)
{
#define METHOD "IPA::Global::hough2lines"
	dPROFILE;
	int z, r, dh;
	int width = 1000, height = 1000;
	double cx, cy;
	Byte * src;
	AV * result;

	/* check input */
	if ( !img || !kind_of(( Handle) img, CImage))
		croak("%s: not an image passed", METHOD);
	if (( img->type & imBPP) != 8)
		croak("%s: not a 8-bit image passed", METHOD);

	if ( pexist( height))
		height = pget_i( height);
	if ( height < 2)
		croak("%s: bad height", METHOD);
	
	if ( pexist( width))
		width = pget_i( width);
	if ( width < 2)
		croak("%s: bad width", METHOD);
	
	result = newAV();
	if (!result)
		croak( "%s: error creating AV", METHOD);
	
	fill_trig_table(img-> w);
	cx = ((double)(width))  / 2;
	cy = ((double)(height)) / 2;
	dh = (int)( 0.5 * sqrt(2.0) * (double) (( width > height) ? width : height) + .5);
	for ( r = 0, src = img-> data; r < img-> h; r++, src += img-> lineSize) {
		for ( z = 0; z < img-> w; z++) {
			double x0, y0, x1, y1;
			double R;
			AV * quad;

			if ( src[z] == 0) continue;

			R = (double)(r - dh);
			if ( fabs(trig_table. cosx[z]) < 0.5) { /* just gives better resolution */
				y0 = 0.0;
				y1 = (double) height;
				x0 = (R - COS(z) * ( y0 - cy )) / SIN(z) + cx;
				x1 = (R - COS(z) * ( y1 - cy )) / SIN(z) + cx;
			} else {
				x0 = 0.0;
				x1 = (double) width;
				y0 = (R - SIN(z) * ( x0 - cx )) / COS(z) + cy;
				y1 = (R - SIN(z) * ( x1 - cx )) / COS(z) + cy;
			}
			quad = newAV();
			if ( !quad) croak( "%s: error creating AV", METHOD);
			av_push( quad, newSVnv(x0));
			av_push( quad, newSVnv(y0));
			av_push( quad, newSVnv(x1));
			av_push( quad, newSVnv(y1));
			av_push( result, newRV_noinc((SV*) quad));
		}
	}

	return newRV_noinc((SV*)result);
#undef METHOD  
}
