/* $Id$ */

#include "IPAsupp.h"

PImage_vmt CImage;

extern void register_IPA__Global_Package( void);
extern void register_IPA__Geometry_Package( void);
extern void register_IPA__Misc_Package( void);
extern void register_IPA__Local_Package( void);
extern void register_IPA__Point_Package( void);
extern void register_IPA__Morphology_Package( void);

XS( boot_Prima__IPA)
{
    dXSARGS;

    (void)items;

    XS_VERSION_BOOTCHECK;
    PRIMA_VERSION_BOOTCHECK;

    CImage = (PImage_vmt)gimme_the_vmt( "Prima::Image");
    register_IPA__Global_Package( );
    register_IPA__Geometry_Package( );
    register_IPA__Misc_Package( );
    register_IPA__Local_Package( );
    register_IPA__Point_Package( );
    register_IPA__Morphology_Package( );

    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}

PImage create_compatible_image(PImage img,Bool copyData)
{
    PImage oimg;
    oimg=createImage(img->w,img->h,img->type);
    if (!oimg) {
        return NULL;
    }
    if ((( img-> type & imBPP) <= 8) && !(img->type & imGrayScale))
       memcpy(oimg->palette,img->palette,img->palSize * 3);
    if (copyData)
        memcpy(oimg->data,img->data,img->dataSize);
    return oimg;
}
