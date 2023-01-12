/* prototypes of functions in color_space.c */
double  rgb_quant( double p, double q, double h );
void    rgb2cmyk( double *rgb, double *cmyk );
void    cmyk2rgb( double *cmyk, double *rgb );
void    rgb2hsl( double *rgb, double *hsl );
void    hsl2rgb( double *hsl, double *rgb );
void    rgb2hsv( double *rgb, double *hsv );
void    hsv2rgb( double *hsv, double *rgb );
void    rgb2xyz( double *rgb, double gamma, double *m0, double *m1, double *m2, double *xyz );
void    xyz2rgb( double *xyz, double gamma, double *m0, double *m1, double *m2, double *rgb );
void    rgb2linear( double *rgb, double gamma, double *out );
void    rgb2gamma( double *rgb, double gamma, double *out );
void    xyY2xyz( double *xyY, double *xyz );
void    xyz2lab( double *xyz, double *w, double *lab );
void    lab2lch( double *lab, double *lch );
void    lch2lab( double *lch, double *lab );
void    lab2xyz( double *lab, double *w, double *xyz );
