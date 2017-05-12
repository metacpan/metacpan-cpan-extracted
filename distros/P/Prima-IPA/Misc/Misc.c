/* $Id$ */

#include "IPAsupp.h"
#include "Misc.h"
#include "Misc.inc"
#include "MiscSupp.h"

Histogram *
IPA__Misc_histogram( PImage img)
{
    const char *method = "IPA::Point::histogram";
    Histogram *histogram;
    int x, y;
    Byte *p;

    if ( !img || !kind_of(( Handle) img, CImage))
       croak("%s: not an image passed", method);

    if ( ( img->type & imBPP) != imbpp8) {
	croak( "%s: unsupported image type", method);
    }

    histogram = alloc1z( Histogram);
    p = img->data;
    if ( ! p) {
	croak( "%s: image doesn't contain any data", method);
    }
    for ( y = 0; y < img->h; y++, p += img->lineSize) {
	for ( x = 0; x < img->w; x++) {
	    ( *histogram)[ p[ x]]++;
	}
    }
    return histogram;
}
