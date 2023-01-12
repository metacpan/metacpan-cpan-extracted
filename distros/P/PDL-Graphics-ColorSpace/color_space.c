#include <stdio.h>
#include <math.h>

#define epsilon   0.008856
#define kappa   903.3

struct pixel {
	double a;
	double b;
	double c;
};

#include "color_space.h"  /* Local decs */

/*** util functions ***/
double _apow (double a, double p) {
	return pow(a >= 0.0 ? a : -a, p);
}
#define EXTREME(var, a, b, c, cmp) \
  double var = a; \
  if (b cmp var) var = b; \
  if (c cmp var) var = c
#define BOUNDED(v, min, max) while (v < min) v += max;while (v >= max) v -= max
#define CALC_HS(h, s, max, delta, r, g, b, satscale) \
	/* set up a greyscale if rgb values are identical */ \
	/* Note: automatically includes max = 0 */ \
	if (delta <= 0.0) { \
		h = s = 0; \
		return; \
	} \
	s = delta / satscale; \
	h = (r == max) ?  (g - b) / delta : \
		 (g == max) ?  2 + (b - r) / delta : \
		 4 + (r - g) / delta; \
	h *= 60.0; \
	BOUNDED(h, 0, 360)
double _rad2deg( double rad )
{
	return 180.0 * rad / M_PI;
}
double _deg2rad( double deg )
{
    return deg * (M_PI / 180.0);
}
void _mult_v3_m33( struct pixel *p, double *m0, double *m1, double *m2, double *result )
{
	result[0] = p->a * m0[0]  +  p->b * m1[0]  +  p->c * m2[0];
	result[1] = p->a * m0[1]  +  p->b * m1[1]  +  p->c * m2[1];
	result[2] = p->a * m0[2]  +  p->b * m1[2]  +  p->c * m2[2];
}

/* ~~~~~~~~~~:> */

double rgb_quant( double p, double q, double h )
{
	BOUNDED(h, 0, 360);
	if (h < 60)       { return p + (q-p)*h/60; }
	else if (h < 180) { return q; }
	else if (h < 240) { return p + (q-p)*(240-h)/60; }
	else              { return p; }
}


void rgb2cmyk( double *rgb, double *cmyk )
{
	struct pixel  cmy = { 1.0-rgb[0], 1.0-rgb[1], 1.0-rgb[2] };

	EXTREME(k, cmy.a, cmy.b, cmy.c, <);

	cmyk[0] = cmy.a - k;
	cmyk[1] = cmy.b - k;
	cmyk[2] = cmy.c - k;
	cmyk[3] = k;
}


void cmyk2rgb( double *cmyk, double *rgb )
{
	double k = cmyk[3];
	rgb[0] = 1.0 - cmyk[0] - k;
	rgb[1] = 1.0 - cmyk[1] - k;
	rgb[2] = 1.0 - cmyk[2] - k;
}


void hsl2rgb( double *hsl, double *rgb )
{
	double h = hsl[0];
	double s = hsl[1];
	double l = hsl[2];

    double p, q;

	if ( l <= 0.5) {
		p = l*(1 - s);
		q = 2*l - p;
	}
	else {
		q = l + s - (l*s);
		p = 2*l - q;
	}

	rgb[0] = rgb_quant(p, q, h+120);
	rgb[1] = rgb_quant(p, q, h);
	rgb[2] = rgb_quant(p, q, h-120);
}


void rgb2hsl( double *rgb, double *hsl )
{
	double r = rgb[0];
	double g = rgb[1];
	double b = rgb[2];
	/* compute the min and max */
	EXTREME(max, r, g, b, >);
	EXTREME(min, r, g, b, <);
	double delta = max - min;
	double sum   = max + min;
	/* luminance */
	hsl[2] = sum / 2.0;
	CALC_HS(hsl[0], hsl[1], max, delta, r, g, b, (hsl[2] <= 0.5 ? sum : (2.0 - sum)));
}


void rgb2hsv( double *rgb, double *hsv )
{
	double r = rgb[0];
	double g = rgb[1];
	double b = rgb[2];
	/* compute the min and max */
	EXTREME(max, r, g, b, >);
	EXTREME(min, r, g, b, <);
	/* got V */
	hsv[2] = max;
	double delta = max - min;
	CALC_HS(hsv[0], hsv[1], max, delta, r, g, b, max);
}


void hsv2rgb( double *hsv, double *rgb )
{
    double h = hsv[0];
    double s = hsv[1];
    double v = hsv[2];

	h /= 60.0;
	double i = floor( h );
	double f = h - i;

	double p = v * (1 - s);
	double q = v * (1 - s * f);
	double t = v * (1 - s * (1 - f));

	switch( (int) i )
	{
		case 0:
			rgb[0] = v;
			rgb[1] = t;
			rgb[2] = p;
			break;
		case 1:
			rgb[0] = q;
			rgb[1] = v;
			rgb[2] = p;
			break;
		case 2:
			rgb[0] = p;
			rgb[1] = v;
			rgb[2] = t;
			break;
		case 3:
			rgb[0] = p;
			rgb[1] = q;
			rgb[2] = v;
			break;
		case 4:
			rgb[0] = t;
			rgb[1] = p;
			rgb[2] = v;
			break;
		default:
			rgb[0] = v;
			rgb[1] = p;
			rgb[2] = q;
			break;
	}
}


void rgb2xyz( double *rgb, double gamma, double *m0, double *m1, double *m2, double *xyz )
{
	rgb2linear(rgb, gamma, xyz);
	struct pixel  p = { xyz[0], xyz[1], xyz[2] };
	_mult_v3_m33( &p, m0, m1, m2, xyz );
}


void rgb2linear( double *rgb, double gamma, double *out )
{
	int i;
	if (gamma < 0) { /* special case for sRGB gamma curve */
	  for (i = 0; i < 3; i++)
	    out[i] = fabs(rgb[i]) <= 0.04045 ? rgb[i] / 12.92 : _apow( (rgb[i] + 0.055)/1.055, 2.4 );
	} else if (gamma == 1.0) { /* copy if different locations */
	  if (rgb != out)
	    for (i = 0; i < 3; i++)
	      out[i] = rgb[i];
	} else {
	  for (i = 0; i < 3; i++)
	    out[i] = _apow(rgb[i], gamma);
	}
}


void xyz2rgb( double *xyz, double gamma, double *m0, double *m1, double *m2, double *rgb )
{
	struct pixel  p = { xyz[0], xyz[1], xyz[2] };
	_mult_v3_m33( &p, m0, m1, m2, rgb );
	rgb2gamma(rgb, gamma, rgb);
}


void rgb2gamma( double *rgb, double gamma, double *out )
{
	int i;
	if (gamma < 0) { /* special case for sRGB gamma curve */
	  for (i = 0; i < 3; i++)
	    out[i] = (fabs(rgb[i]) <= 0.0031308) ? 12.92 * rgb[i] : 1.055 * _apow(rgb[i], 1.0/2.4) - 0.055;
	} else if (gamma == 1.0) { /* copy if different locations */
	  if (rgb != out)
	    for (i = 0; i < 3; i++)
	      out[i] = rgb[i];
	} else {
	  for (i = 0; i < 3; i++)
	    out[i] = _apow(rgb[i], 1.0 / gamma);
	}
}


void xyY2xyz( double *xyY, double *xyz )
{
	if ( xyY[1] == 0.0 ) {
		xyz[0] = xyz[1] = xyz[2] = 0.0;
		return;
	}
	xyz[0] = xyY[0]  /  xyY[1];
	xyz[1] = 1.0;
	xyz[2] = (1.0 - xyY[0] - xyY[1])  /  xyY[1];
}


void xyz2lab( double *xyz, double *w, double *lab )
{
	double xr = xyz[0] / w[0];
	double yr = xyz[1] / w[1];
	double zr = xyz[2] / w[2];

	double fx = (xr > epsilon)?  pow(xr, 1.0/3.0) : (kappa * xr + 16.0) / 116.0;
	double fy = (yr > epsilon)?  pow(yr, 1.0/3.0) : (kappa * yr + 16.0) / 116.0;
	double fz = (zr > epsilon)?  pow(zr, 1.0/3.0) : (kappa * zr + 16.0) / 116.0;

	lab[0] = 116.0 * fy - 16.0;
	lab[1] = 500.0 * (fx - fy);
	lab[2] = 200.0 * (fy - fz);
}

void lab2lch( double *lab, double *lch )
{
	lch[0] = lab[0];
	lch[1] = sqrt( pow(lab[1], 2) + pow(lab[2], 2) );
	lch[2] = _rad2deg( atan2( lab[2], lab[1] ) );

	BOUNDED(lch[2], 0.0, 360.0);
}

void lch2lab( double *lch, double *lab )
{
    /* l is set */
    lab[0] = lch[0];

    double c = lch[1];
    double h = _deg2rad( lch[2] );
    double th = tan(h);

    double *a = lab+1;
    double *b = lab+2;

    *a = c / sqrt( pow(th,2) + 1 );
    *b = sqrt( pow(c, 2) - pow(*a, 2) );

    if (h < 0.0)
        h += 2*M_PI;
    if (h > M_PI/2 && h < M_PI*3/2)
        *a = -*a;
    if (h > M_PI)
        *b = -*b;
}


void lab2xyz( double *lab, double *w, double *xyz )
{
	double yr = (lab[0] > kappa * epsilon) ?  pow( (lab[0] + 16.0)/116.0, 3 )  :  lab[0] / kappa;

	double fy = (yr > epsilon) ?  (lab[0] + 16.0)/116.0  :  (kappa * yr + 16.0)/116.0;
	double fx = fy + lab[1] / 500.0;
	double fz = fy - lab[2] / 200.0;

	double xr = (pow(fx, 3) > epsilon) ?  pow(fx, 3)  :  (fx * 116.0 - 16.0) / kappa;
	double zr = (pow(fz, 3) > epsilon) ?  pow(fz, 3)  :  (fz * 116.0 - 16.0) / kappa;

	xyz[0] = xr * w[0];
	xyz[1] = yr * w[1];
	xyz[2] = zr * w[2];
}
