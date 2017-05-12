/* $Id$ */

#include "IPAsupp.h"
#include "Misc.h"
#include "MiscSupp.h"

#undef METHOD
#define METHOD "IPA::Misc::split_channels"
#define WHINE(msg) croak( "%s: %s", METHOD, (msg))

/*
Ranges:
  Hue - 0-360
  Saturation: 0-1
  Value: 0-1
   */
static void
hsv2rgb( float h, float s, float v, Byte * rgb)
{
   long i;
   float w, q, t, f; 

   h /= 60;
   v *= 255;

   i = (long) h;
   f = h - i;
   w = v * ( 1 - s);
   q = v * ( 1 - s * f);
   t = v * ( 1 - s * ( 1 - f ));

#define Dch(X) *(rgb++)=(Byte)(X+.5)
#define DRGB(R,G,B) Dch(B);Dch(G);Dch(R);break
   
   switch ( i) {
   case 0:  DRGB(v, t, w);
   case 1:  DRGB(q, v, w);
   case 2:  DRGB(w, v, t);
   case 3:  DRGB(w, q, v);
   case 4:  DRGB(t, w, v);
   default: DRGB(v, w, q);
   }
}

static void 
rgb2hsv( Byte * rgb, float * h, float * s, float * v)
{
   Byte R, G, B, max, min, delta;
   B = *(rgb++); G = *(rgb++); R = *(rgb++);
   min = max = R; 
   if ( G > max) max = G; 
   if ( B > max) max = B;
   if ( G < min) min = G; 
   if ( B < min) min = B;
   *v = ( float) max / 255;
   if (( delta = max - min) == 0) {
      *s = *h = 0;
      return;
   } else {
      *s = ( float) delta / max;
   }
      
   if ( R == max)
     *h = (float) 0.0 + (float)( G - B ) / delta;
   else if ( G == max) 
     *h = (float) 2.0 + (float)( B - R ) / delta;
   else
     *h = (float) 4.0 + (float)( R - G ) / delta;
   if ( *h < 0) *h += 6.0;
   *h *= 60;
}


SV * 
IPA__Misc_split_channels( PImage input, char * mode)
{
   int m, count = 0;
   AV * av;
   PImage ch[16];
   
   if ( !input || !kind_of(( Handle) input, CImage))
      croak("%s: not an image passed", METHOD);
   
   if ( stricmp( mode, "rgb") == 0) m = 0; else
   if ( stricmp( mode, "hsv") == 0) m = 1; else
   WHINE("unknown mode");

      
   switch ( m) {
   case 0:  {
      Byte * src = input-> data;
      Byte * dst[3];      
      int y = input-> h, srcd = input-> lineSize - input-> w * 3, dstd;
      if ( input-> type != imbpp24) WHINE("mode 'rgb' accepts 24 RGB images only");
      count = 3;
      for ( m = 0; m < 3; m++) {
         ch[m] = createImage( input->w, input->h, imByte);
         dst[m] = ch[m]-> data;
      }
      dstd = ch[0]-> lineSize - input-> w;
      while ( y--) {
         int x = input-> w;
         while ( x--) {
            *((dst[0])++) = *(src++);
            *((dst[1])++) = *(src++);
            *((dst[2])++) = *(src++);
         }   
         src += srcd;
         for ( m = 0; m < 3; m++) dst[m] += dstd;
      }
      /* swap r and b */
      ch[3] = ch[0];
      ch[0] = ch[2];
      ch[2] = ch[3];
      break;
   }   
   case 1:  {
      Byte * src = input-> data;
      float * dst[3];      
      int y = input-> h, srcd = input-> lineSize - input-> w * 3, dstd;
      if ( input-> type != imbpp24) WHINE("mode 'hsv' accepts 24 RGB images only");
      count = 3;
      for ( m = 0; m < 3; m++) {
         ch[m] = createImage( input->w, input->h, imFloat);
         dst[m] = ( float*) ch[m]-> data;
      }
      dstd = ch[0]-> lineSize - input-> w * sizeof(float);
      while ( y--) {
         int x = input-> w;
         while ( x--) {
            rgb2hsv( src, (dst[0])++, (dst[1])++, (dst[2])++);
            src += 3;
         }   
         src += srcd;
         for ( m = 0; m < 3; m++) dst[m] += dstd;
      }
      break;
   }   
   }
   
   av = newAV();
   for ( m = 0; m < count; m++)
      av_push( av, newRV( SvRV( ch[m]-> mate)));
   return newRV_noinc(( SV*) av);
}   

#undef METHOD
#define METHOD "IPA::Misc::combine_channels"

PImage
IPA__Misc_combine_channels( SV * input, char * mode)
{
   int i, n, m, w=0, h=0;
   AV * av;
   Handle ch[16];
   if ( !SvOK(input) || !SvROK(input) || SvTYPE(SvRV(input))!=SVt_PVAV) {
      croak("%s: first parameter is not an array", METHOD);
   }
   av = ( AV *) SvRV( input);
   n = av_len( av) + 1;
   if ( n > 16) n = 16;
   for ( i = 0; i < n; i++) {
      SV **sv = av_fetch( av, i, 0);
      if ( !sv || !SvOK(*sv) || !SvROK(*sv) || 
         (!( ch[i] = gimme_the_mate( *sv))) || !(kind_of( ch[i], CImage))) 
         croak( "%s: item #%d is not an image", METHOD, i);
      if ( i == 0) {
         w = PImage(ch[i])-> w;
         h = PImage(ch[i])-> h;
      } else if ( w != PImage(ch[i])-> w || h != PImage(ch[i])-> h) {
         croak( "%s: image dimensions #%d are different from [%d,%d]", METHOD, i, w, h); 
      }
   }
   
   if ( stricmp( mode, "rgb") == 0) m = 0; else
   if ( stricmp( mode, "hsv") == 0) m = 1; else
   if ( strncmp( mode, "alpha", 5) == 0) m = 2; else
   croak("%s: unknown mode %s", METHOD, mode);

   switch ( m) {
   case 0:
      if ( n != 3) croak( "%s: mode 'rgb' expects 3 images", METHOD);
      for ( i = 0; i < 3; i++) 
         if ( PImage(ch[0])-> type != imByte)
            croak( "%s: image #%d is not 8-bit grayscale", METHOD);
      {
         PImage ret;
         int srcl, dstl;
         register Byte *dst, *r, *g, *b;
         
         if ( !( ret = createImage( w, h, imRGB)))
            croak("%s: error creating image", METHOD);

         r    = PImage(ch[0])-> data;
         g    = PImage(ch[1])-> data;
         b    = PImage(ch[2])-> data;
         dst  = ret-> data;
         dstl = ret-> lineSize - w * 3;
         srcl = PImage(ch[0])-> lineSize - w;

         while (h--) {
            register int x = w;
            while ( x--) {
               *(dst++) = *(b++);
               *(dst++) = *(g++);
               *(dst++) = *(r++);
            }
            r += srcl;
            g += srcl;
            b += srcl;
            dst += dstl;
         }
         return ret;
      }
      break;
   case 1:
      if ( n != 3) croak( "%s: mode 'hsv' expects 3 images", METHOD);
      for ( i = 0; i < 3; i++) 
         if ( PImage(ch[0])-> type != imFloat)
            croak( "%s: type of image #%d is not float", METHOD);
      {
         PImage ret;
         int srcl, dstl;
         register Byte *dst;
         register float *H, *s, *v;
         
         if ( !( ret = createImage( w, h, imRGB)))
            croak("%s: error creating image", METHOD);

         H    = (float*) PImage(ch[0])-> data;
         s    = (float*) PImage(ch[1])-> data;
         v    = (float*) PImage(ch[2])-> data;
         dst  = ret-> data;
         dstl = ret-> lineSize - w * 3;
         srcl = PImage(ch[0])-> lineSize - w * sizeof(float);

         while (h--) {
            register int x = w;
            while ( x--) {
               hsv2rgb( *(H++), *(s++), *(v++), dst);
               dst += 3;
            }
            H += srcl;
            s += srcl;
            v += srcl;
            dst += dstl;
         }
         return ret;
      }
      break;
   case 2: {
      char * eptr;
      int  mul, ds;
      Byte * i1, * i2, * dst;
      PImage ret;
      float mul1, mul2;

      mul = strtol( mode + 5, &eptr, 10);
      if (*eptr || mul < 0 || mul > 255) 
         croak("%s: format alphaNUM where NUM in 0..255", METHOD);
      if ( n != 2) croak( "%s: mode 'alpha' expects 2 images", METHOD);
      if ( mul == 255) 
         return (PImage) CImage(ch[0])-> dup(ch[0]);
      if ( mul == 0) 
         return (PImage) CImage(ch[1])-> dup(ch[1]);

      if ( PImage(ch[0])-> type == imByte) {
         if ( PImage(ch[1])-> type != imByte)
            croak( "%s: type of image #1 is not Byte", METHOD);
         if ( !( ret = createImage( w, h, imByte)))
            croak("%s: error creating image", METHOD);
      } else if ( PImage(ch[0])-> type == imRGB) {
         if ( PImage(ch[1])-> type != imRGB)
            croak( "%s: type of image #1 is not RGB", METHOD);
         if ( !( ret = createImage( w, h, imRGB)))
            croak("%s: error creating image", METHOD);
      } else {
         croak("%s: mode 'alpha' expects either RGB or Byte images", METHOD);
      }

      i1   = PImage(ch[0])-> data;
      i2   = PImage(ch[1])-> data;
      dst  = ret-> data;
      
      mul1 = (float) mul / 256;
      mul2 = (float) 1.0 - mul1;
      ds   = ret-> dataSize;

      if ( ds > 65536) {
	 int i, j;
	 Byte tab[256][256];
         for ( i = 0; i < 256; i++) {
            for ( j = 0; j < 256; j++) {
               tab[i][j] = (int)((((float)(i)) * mul1) + (((float)(j)) * mul2) + .5);
            }
         }
         while (ds--)
       	    *(dst++) = tab[*(i1++)][*(i2++)];
      } else {
         while (ds--)
            *(dst++) = (int)((((float)*(i1++)) * mul1) + (((float)*(i2++)) * mul2) + .5);
      }

      return ret;
      
      } break;
   }

   return (void*)0;
}
