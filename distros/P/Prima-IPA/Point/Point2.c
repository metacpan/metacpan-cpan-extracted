/* $Id$ */

#include "IPAsupp.h"
#include "Point.h"
#include "PointSupp.h"

#undef METHOD
#define METHOD "IPA::Point::mask"

static PImage constant( int w, int h, int type, I32 vv) {
   PImage r = createNamedImage( w, h, type, "(temporary)");
   U8 *line;
   int y;
   if (!r) croak( "%s: error creating temporary image", METHOD);
   line = r-> data;
   switch ( type) {
      case imByte: memset( line, (U8)vv, w); break;
      case imShort: {
         I16 v = (I16)vv;
         I16 *l = (I16*)line;
         while (w--) *l++ = v;
      }
      break;
      case imLong: {
         I32 *l = (I32*)line;
         while (w--) *l++ = vv;
      }
      break;
   }
   for ( y = 1; y < h; y++) memcpy( r-> data + r-> lineSize*y, line, r-> lineSize);
   return r;
}

PImage IPA__Point_mask( PImage mask, HV *profile) {
   dPROFILE;
   PImage ifMatch = nil;
   PImage ifNoMatch = nil;
   PImage itest = nil;
   PImage o;
   I32 test = 0;
   I32 match = 0;
   I32 nomatch = 255;
   U8 *src, *dst;
   U8 *nnn, *mmm, *ttt;
   int y, sz, w, h;
   Bool freeMatch = false;
   Bool freeNoMatch = false;
   Bool freeTest = false;

  if ( !mask || !kind_of(( Handle) mask, CImage))
       croak("%s: not an image passed", METHOD);

   switch ( mask-> type) {
      case imByte:      sz = sizeof(U8);  break;
      case imShort:     sz = sizeof(I16); break;
      case imLong:      sz = sizeof(I32); break;
      default:
         croak( "%s: mask image should have integer grayscale type", METHOD);
   }

   if ( profile) {
      SV *dummy;
      char *key;
      I32 l;
      hv_iterinit( profile);
      for (;;) {
         dummy = hv_iternextsv( profile, &key, &l);
         if ( key == nil || dummy == nil) break;
         if ( strcmp( key, "test") != 0 &&
              strcmp( key, "match") != 0 &&
              strcmp( key, "mismatch") != 0 &&
              strncmp( key, "__", 2) != 0)
            croak( "%s: illegal option ``%s'' passed", METHOD, key);
      }
   }

   if ( profile && pexist(test)) {
      SV *sv = pget_sv(test);
      if (sv && SvROK(sv))  itest = (PImage)pget_H(test);
      else test = pget_i(test);
   }
   if ( profile && pexist(match)) {
      SV *sv = pget_sv(match);
      if (sv && SvROK(sv))  ifMatch = (PImage)pget_H(match);
      else match = pget_i(match);
   }
   if ( profile && pexist(mismatch)) {
      SV *sv = pget_sv(mismatch);
      if (sv && SvROK(sv))  ifNoMatch = (PImage)pget_H(mismatch);
      else nomatch = pget_i(mismatch);
   }
   if (ifMatch &&
       (!kind_of((Handle)ifMatch,CImage) ||
        ifMatch-> w != mask-> w || ifMatch-> h != mask-> h ||
        ifMatch-> type != mask-> type))
      croak( "%s: illegal ``ifMatch'' image passed", METHOD);
   if (itest &&
       (!kind_of((Handle)itest,CImage) ||
        itest-> w != mask-> w || itest-> h != mask-> h ||
        itest-> type != mask-> type))
      croak( "%s: illegal ``test'' image passed", METHOD);
   if (ifNoMatch &&
       (!kind_of((Handle)ifNoMatch,CImage) ||
        ifNoMatch-> w != mask-> w || ifNoMatch-> h != mask-> h ||
        ifNoMatch-> type != mask-> type))
      croak( "%s: illegal ``ifNoMatch'' image passed", METHOD);

   o = createNamedImage( mask-> w, mask-> h, mask-> type, METHOD);
   if (!o) croak( "%s: error creating output image", METHOD);

   w = mask-> w;
   h = mask-> h;
   if ( !itest) {
      freeTest = true;
      itest = constant( w, h, mask-> type, test);
   }
   if ( !ifMatch) {
      freeMatch = true;
      ifMatch = constant( w, h, mask-> type, match);
   }
   if ( !ifNoMatch) {
      freeNoMatch = true;
      ifNoMatch = constant( w, h, mask-> type, nomatch);
   }

   src = mask-> data;
   dst = o-> data;
#define DOMASKING(TYP)                                        \
   {                                                          \
      TYP *m, *n, *t, *s, *d, *stop;                          \
      mmm = ifMatch-> data;                                   \
      nnn = ifNoMatch-> data;                                 \
      ttt = itest-> data;                                     \
      for ( y = 0; y < mask-> h; y++) {                       \
         s = (TYP*)src;  d = (TYP*)dst;  stop = s + w;        \
         m = (TYP*)mmm;  n = (TYP*)nnn;  t = (TYP*)ttt;       \
         while ( s != stop) {                                 \
            *d = *s == *t ? *m : *n;                          \
            m++; n++; s++; t++; d++;                          \
         }                                                    \
         src += mask-> lineSize;                              \
         dst += o-> lineSize;                                 \
         mmm += ifMatch-> lineSize;                           \
         nnn += ifNoMatch-> lineSize;                         \
         ttt += itest-> lineSize;                             \
      }                                                       \
   }
   switch ( mask-> type) {
      case imByte:  DOMASKING(U8);  break;
      case imShort: DOMASKING(I16); break;
      case imLong:  DOMASKING(I32); break;
   }
#undef DOMASKING

   if ( freeTest) destroyImage( itest);
   if ( freeMatch) destroyImage( ifMatch);
   if ( freeNoMatch) destroyImage( ifNoMatch);

   return o;
}
