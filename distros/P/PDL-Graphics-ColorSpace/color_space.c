#include <stdio.h>
#include <math.h>

#define epsilon   0.008856
#define kappa   903.3

struct pixel {
	double a;
	double b;
	double c;
};


/*** function defs ***/
double  rgb_quant( double p, double q, double h );
void    rgb2cmyk( double *rgb, double *cmyk );
void    cmyk2rgb( double *cmyk, double *rgb );
void    rgb2hsl( double *rgb, double *hsl );
void    hsl2rgb( double *hsl, double *rgb );
void    rgb2hsv( double *rgb, double *hsv );
void    hsv2rgb( double *hsv, double *rgb );
void    rgb2xyz( double *rgb, double gamma, double *m0, double *m1, double *m2, double *xyz );
void    xyz2rgb( double *xyz, double gamma, double *m0, double *m1, double *m2, double *rgb );
double  _apow( double a, double p );
double  _rad2deg( double rad );
double  _deg2rad( double deg );
void    _mult_v3_m33( struct pixel *p, double *m0, double *m1, double *m2, double *result );
void    xyY2xyz( double *xyY, double *xyz );
void    xyz2lab( double *xyz, double *w, double *lab );
void	lab2lch( double *lab, double *lch );
void    lch2lab( double *lch, double *lab );
void    lab2xyz( double *lab, double *w, double *xyz );


/* ~~~~~~~~~~:> */

double rgb_quant( double p, double q, double h )
{
	while (h < 0)     { h += 360; }
	while (h >= 360 ) { h -= 360; }

	if (h < 60)       { return p + (q-p)*h/60; }
	else if (h < 180) { return q; }
	else if (h < 240) { return p + (q-p)*(240-h)/60; }
	else              { return p; }
}


void rgb2cmyk( double *rgb, double *cmyk )
{
	struct pixel  cmy = { 1.0-*rgb, 1.0-*(rgb+1), 1.0-*(rgb+2) };

	double k = cmy.a;
	if (cmy.b < k)  k = cmy.b; 
	if (cmy.c < k)  k = cmy.c; 

	*cmyk     = cmy.a - k;
	*(cmyk+1) = cmy.b - k;
	*(cmyk+2) = cmy.c - k;
	*(cmyk+3) = k;
}


void cmyk2rgb( double *cmyk, double *rgb )
{
	double k = *(cmyk+3);

	struct pixel cmy = { *cmyk + k, *(cmyk+1) + k, *(cmyk+2) + k };

	*rgb     = 1.0 - cmy.a;
	*(rgb+1) = 1.0 - cmy.b;
	*(rgb+2) = 1.0 - cmy.c;
}


void hsl2rgb( double *hsl, double *rgb )
{
	double h = *hsl; 
	double s = *(hsl+1);
	double l = *(hsl+2);

    double p, q;

	if ( l <= 0.5) {
		p = l*(1 - s);
		q = 2*l - p;
	}
	else {
		q = l + s - (l*s);
		p = 2*l - q;
	}
	
	*rgb = rgb_quant(p, q, h+120);
	*(rgb+1) = rgb_quant(p, q, h);
	*(rgb+2) = rgb_quant(p, q, h-120);
}


void rgb2hsl( double *rgb, double *hsl )
{
    double r = *rgb;
    double g = *(rgb+1);
    double b = *(rgb+2);

	/* compute the min and max */
	double max = r;
	if (max < g) max = g;
	if (max < b) max = b;
	double min = r;
	if (g < min) min = g;
	if (b < min) min = b;
	
	/* Set the sum and delta */
	double delta = max - min;
	double sum   = max + min;

	/* luminance */
	*(hsl+2) = sum / 2.0;
	
	/* set up a greyscale if rgb values are identical */
	/* Note: automatically includes max = 0 */
	if (delta == 0.0) {
		*hsl = 0.0;
		*(hsl+1) = 0.0;
	}
	else {
		/* satuaration */
		if (*(hsl+2) <= 0.5) {
			*(hsl+1) = delta / sum;
		}
		else {
			*(hsl+1) = delta / (2.0 - sum);
		}
		
		/* compute hue */
		if (r == max) {
			*hsl = (g - b) / delta;
		}
		else if (g == max) {
			*hsl = 2.0 + (b - r) / delta;
		}
		else {
			*hsl = 4.0 + (r - g) / delta;
		}
		*hsl *= 60.0;
		while (*hsl < 0.0)   { *hsl += 360; }
		while (*hsl > 360.0) { *hsl -= 360; }
    }
}


void rgb2hsv( double *rgb, double *hsv )
{
    double r = *rgb;
    double g = *(rgb+1);
    double b = *(rgb+2);

	/* compute the min and max */
	double max = r;
	if (max < g) max = g;
	if (max < b) max = b;
	double min = r;
	if (g < min) min = g;
	if (b < min) min = b;

	/* got V */	
	*(hsv+2) = max;

	double delta = max - min;

	if (delta > 0.0) {
		/* got S */	
		*(hsv+1) = delta / max;
	}
	else {
		*hsv = 0;
		*(hsv+1) = 0;
		return;
	}

	/* getting H */	
	*hsv = (r == max) ?  (g - b) / delta
		 : (g == max) ?  2 + (b - r) / delta
		 :               4 + (r - g) / delta
		 ;

	*hsv *= 60;
	while (*hsv < 0.0)    { *hsv += 360; }
	while (*hsv >= 360.0) { *hsv -= 360; }
}


void hsv2rgb( double *hsv, double *rgb )
{
    double h = *hsv;
    double s = *(hsv+1);
    double v = *(hsv+2);

	h /= 60.0;
	double i = floor( h );
	double f = h - i;

	double p = v * (1 - s);
	double q = v * (1 - s * f);
	double t = v * (1 - s * (1 - f));

	switch( (int) i )
	{
		case 0:
			*rgb     = v;
			*(rgb+1) = t;
			*(rgb+2) = p;
			break;
		case 1:
			*rgb     = q;
			*(rgb+1) = v;
			*(rgb+2) = p;
			break;
		case 2:
			*rgb     = p;
			*(rgb+1) = v;
			*(rgb+2) = t;
			break;
		case 3:
			*rgb     = p;
			*(rgb+1) = q;
			*(rgb+2) = v;
			break;
		case 4:
			*rgb     = t;
			*(rgb+1) = p;
			*(rgb+2) = v;
			break;
		default:
			*rgb     = v;
			*(rgb+1) = p;
			*(rgb+2) = q;
			break;
	}
}


void rgb2xyz( double *rgb, double gamma, double *m0, double *m1, double *m2, double *xyz )
{
	/* weighted RGB */
	struct pixel  p = { *rgb, *(rgb+1), *(rgb+2) };

	if (gamma < 0) {
		/* special case for sRGB gamma curve */
		if ( fabs(p.a) <= 0.04045 ) { p.a /= 12.92; }
		else { p.a =_apow( (p.a + 0.055)/1.055, 2.4 ); }

		if ( fabs(p.b) <= 0.04045 ) { p.b /= 12.92; }
		else { p.b =_apow( (p.b + 0.055)/1.055, 2.4 ); }

		if ( fabs(p.c) <= 0.04045 ) { p.c /= 12.92; }
		else { p.c =_apow( (p.c + 0.055)/1.055, 2.4 ); }
	}
	else {
		p.a = _apow(p.a, gamma);
		p.b = _apow(p.b, gamma);
		p.c = _apow(p.c, gamma);
	}

	_mult_v3_m33( &p, m0, m1, m2, xyz );
}


void xyz2rgb( double *xyz, double gamma, double *m0, double *m1, double *m2, double *rgb )
{
	struct pixel  p = { *xyz, *(xyz+1), *(xyz+2) };

	_mult_v3_m33( &p, m0, m1, m2, rgb );

	double *r;  r = rgb;
	double *g;  g = rgb+1;
	double *b;  b = rgb+2;

	if (gamma < 0) {
		/* special case for sRGB gamma curve */
		*r = (fabs(*r) <= 0.0031308) ?  12.92 * *r  :  1.055 * _apow(*r, 1.0/2.4) - 0.055;
		*g = (fabs(*g) <= 0.0031308) ?  12.92 * *g  :  1.055 * _apow(*g, 1.0/2.4) - 0.055;
		*b = (fabs(*b) <= 0.0031308) ?  12.92 * *b  :  1.055 * _apow(*b, 1.0/2.4) - 0.055;
	}
	else {
		*r = _apow(*r, 1.0 / gamma);
		*g = _apow(*g, 1.0 / gamma);
		*b = _apow(*b, 1.0 / gamma);
	}
}


double _apow (double a, double p) {
	return a >= 0.0?   pow(a, p) : -pow(-a, p);
}

void _mult_v3_m33( struct pixel *p, double *m0, double *m1, double *m2, double *result )
{
	*result     = p->a  *  *m0      +  p->b  *  *m1      +  p->c  *  *m2;
	*(result+1) = p->a  *  *(m0+1)  +  p->b  *  *(m1+1)  +  p->c  *  *(m2+1);
	*(result+2) = p->a  *  *(m0+2)  +  p->b  *  *(m1+2)  +  p->c  *  *(m2+2);
}


void xyY2xyz( double *xyY, double *xyz )
{

	*(xyz+1) = *(xyY+2);

	if ( *(xyY+1) != 0.0 ) {
		*xyz     = *xyY  *  *(xyY+2)  /  *(xyY+1);
		*(xyz+2) = (1.0 - *xyY - *(xyY+1))  *  *(xyY+2)  /  *(xyY+1);
	}
	else {
		*xyz = *(xyz+1) = *(xyz+2) = 0.0;
	}
}


void xyz2lab( double *xyz, double *w, double *lab )
{
	double xr, yr, zr;

	xr = *xyz / *w;
	yr = *(xyz+1) / *(w+1);
	zr = *(xyz+2) / *(w+2);

	double fx, fy, fz;

	fx = (xr > epsilon)?  pow(xr, 1.0/3.0) : (kappa * xr + 16.0) / 116.0;
	fy = (yr > epsilon)?  pow(yr, 1.0/3.0) : (kappa * yr + 16.0) / 116.0;
	fz = (zr > epsilon)?  pow(zr, 1.0/3.0) : (kappa * zr + 16.0) / 116.0;

	*lab     = 116.0 * fy - 16.0;
	*(lab+1) = 500.0 * (fx - fy);
	*(lab+2) = 200.0 * (fy - fz);
}

void lab2lch( double *lab, double *lch )
{
	*lch = *lab;

	*(lch+1) = sqrt( pow(*(lab+1), 2) + pow(*(lab+2), 2) );
	*(lch+2) = _rad2deg( atan2( *(lab+2), *(lab+1) ) );

	while (*(lch+2) < 0.0)   { *(lch+2) += 360; }
	while (*(lch+2) > 360.0) { *(lch+2) -= 360; }
}

void lch2lab( double *lch, double *lab )
{
    /* l is set */
    *lab = *lch;

    double c = *(lch+1);
    double h = _deg2rad( *(lch+2) );
    double th = tan(h);

    double *a;
    double *b;

    a = lab+1;
    b = lab+2;

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
	double xr, yr, zr;

	yr = (*lab > kappa * epsilon) ?  pow( (*lab + 16.0)/116.0, 3 )  :  *lab / kappa;

	double fx, fy, fz;

	fy = (yr > epsilon) ?  (*lab + 16.0)/116.0  :  (kappa * yr + 16.0)/116.0;
	fx = *(lab+1) / 500.0 + fy;
	fz = fy - *(lab+2) / 200.0;

	xr = (pow(fx, 3) > epsilon) ?  pow(fx, 3)  :  (fx * 116.0 - 16.0) / kappa;
	zr = (pow(fz, 3) > epsilon) ?  pow(fz, 3)  :  (fz * 116.0 - 16.0) / kappa;

	*xyz     = xr * *w;
	*(xyz+1) = yr * *(w+1);
	*(xyz+2) = zr * *(w+2);
}


double _rad2deg( double rad )
{
	return 180.0 * rad / M_PI;
}

double _deg2rad( double deg )
{
    return deg * (M_PI / 180.0); 
}
