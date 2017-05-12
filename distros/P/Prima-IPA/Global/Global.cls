# $Id$
local $PImage => Handle;

package Prima::IPA::Global {
    PImage close_edges(PImage input,HV *profile);
    PImage fill_holes(PImage input,HV *profile);
    PImage area_filter(PImage input,HV *profile);
    SV* identify_contours(PImage input,HV *profile);
    SV* identify_scanlines(PImage input,HV *profile);
    SV* identify_pixels(PImage input,HV *profile);
    PImage fft( PImage input, HV * profile); 
    PImage band_filter( PImage input, HV * profile);
    PImage hough( PImage input, HV * profile);
    SV*  hough2lines(PImage hough, HV * profile);
    void hlines( PImage input, int x, int y, SV * points, double color);
    void bar( PImage input, int x1, int y1, int x2, int y2, double color);
    void line( PImage input, int x1, int y1, int x2, int y2, double color);
}
