/* $Id$ */

#include "IPAsupp.h"
#include "Geometry.h"
#include "GeometrySupp.h"

PImage IPA__Geometry_shift_rotate( PImage img, HV *profile)
{
   dPROFILE;
   const char *method="IPA::Geometry::shift_rotate";
   PImage oimg;
   int where = 0;
   int size = 0;
   int mult;
   int y;

   if ( !img || !kind_of(( Handle) img, CImage))
      croak("%s: not an image passed", method);

   /* these will croak if absent; that's ok */
   where = pget_i(where);
   size  = pget_i(size);

   if (!(oimg = createNamedImage(img->w,img->h,img->type,method)))
      croak( "%s: error creating an image", method);
   memcpy(oimg->palette,img->palette,img->palSize*sizeof(RGBColor));
   oimg->palSize=img->palSize;

   size %= (size < 0 ? -1 : 1) * (where == VERTICAL ? img->h : img->w);

   if (size == 0) {
      /* nothing to do, just copy */
      memcpy(oimg->data, img->data, img->dataSize);
   } else if (where == VERTICAL) {
      if ( size < 0) size = img->h + size;
      memcpy(oimg->data, img->data + img->lineSize*size,
             img->dataSize - img->lineSize*size);
      memcpy(oimg->data + oimg->dataSize - oimg->lineSize*size,
             img->data, img->lineSize*size);
   } else if (where == HORIZONTAL) {
      if ((img->type & imBPP) < 8)
         croak( "%s-horizontal is not implemented for %d-bit images",
                method, img->type & imBPP);
      mult = (img->type & imBPP)/8;
      if ( size < 0) size = img->w + size;
      for ( y = 0; y < img->h; y++) {
         memcpy(oimg->data + y*oimg->lineSize,
                img->data + y*img->lineSize + mult*size,
                img->w*mult - mult*size);
         memcpy(oimg->data + y*oimg->lineSize + oimg->w*mult - mult*size,
                img->data + y*img->lineSize,
                mult*size);
      }
   } else {
      Object_destroy((Handle)oimg);
      croak( "%s: unrecognized `where' direction", method);
   }
   return oimg;
}
