/* $Id$ */

#include "IPAsupp.h"
#include "Morphology.h"
#include "MorphologySupp.h"

#ifndef max
#define max(A,B)  ((A) > (B) ? (A) : (B))
#endif
#ifndef min
#define min(A,B)  ((A) < (B) ? (A) : (B))
#endif


/*******************************************/
/*  Morphological binary thinning          */
/*                                         */
/*  Implemented by Dmitry Karasik          */
/*  February 28, 2003                      */
/*                                         */
/*  Reference:                             */
/*  Rafael C.Gonzalez, Richard E.Woods     */
/*  Digital Image Processing, pp 491-494   */
/*  Addison Wesley, 1993                   */
/*******************************************/
/* tables generated with the following perl code:

   for ( 0 .. 255) {
      my $r = $_;
      my @d = map {($r & ( 0x80 >> $_)) ? 1 : 0} 0 .. 7;
      my ($s,$n,$l) = (0,0,$d[-1]);
      for ( @d) { 
         $s++ if !$l && $_;
         $n++ if $l = $_;
      } 
      my ( $p2, $p4, $p6, $p8) = map { !$_ } @d[6,0,2,4];
      $T1 .= (( $n > 1 && $n < 7) && ($s == 1) && (( $p4 || $p6) || ( $p2 && $p8))) ? '0xff,' : '0x00,';
      $T2 .= (( $n > 1 && $n < 7) && ($s == 1) && (( $p2 || $p8) || ( $p4 && $p6))) ? '0xff,' : '0x00,';
      $T1 .= "\n", $T2 .= "\n" if ( $r % 16) == 15;
   }
   print "$T1\n$T2";
*/

#undef METHOD
#define METHOD "IPA::Morphology::thinning"
#define WHINE(msg) croak( "%s: %s", METHOD, (msg))

PImage
IPA__Morphology_thinning( PImage i, HV *profile)
{
   static const Byte thin1[] = {
0x00,0x00,0x00,0xff,0x00,0x00,0xff,0xff,0x00,0x00,0x00,0x00,0xff,0x00,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0xff,0x00,
0x00,0xff,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
   };
   static const Byte thin2[] = {
0x00,0x00,0x00,0xff,0x00,0x00,0xff,0xff,0x00,0x00,0x00,0x00,0xff,0x00,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0xff,0xff,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00,
0x00,0xff,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0x00,0xff,0x00,0x00,0x00,0xff,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0xff,0xff,0x00,0xff,0x00,0x00,0x00,0x00,0xff,0xff,0x00,0x00,0xff,0x00,0x00,0x00
   };

   PImage o;
   int w, h, y, maxy, maxx, line_size;
   Byte *to, *from, *m, *x;
   Bool change;
   SV * name;

   if ( i-> type != imByte)
      WHINE( "cannot handle images other than 8-bit gray scale");

   w = i-> w;   h = i-> h;
   maxx = w - 1;  maxy = h - 1;
   line_size = i-> lineSize;

   if ( w < 3 || h < 3)
      WHINE( "input image too small (should be at least 3x3)");

   o = (PImage)i->self->dup((Handle)i);
   if (!o)
        WHINE( "error creating output image");
   SvREFCNT(SvRV(o-> mate))++;
   name = newSVpv( METHOD, 0);
   o-> self-> set_name((Handle)o, name);
   sv_free( name);
   SvREFCNT(SvRV(o-> mate))--;

   m = malloc( line_size * h);
   if (!m) WHINE( "no memory");
   
   memset( m, 0, line_size);
   memset( m + maxy * line_size, 0, line_size);
  
   change = true;
   while (change) {

      change = false;

      for ( y = 1; y < maxy; y++) {
	 to = m + y * line_size;
	 from = o-> data + y * line_size + 1;
	 *to++ = 0;

	 for ( x = to + w - 2; to < x; to++, from++) {
	    if ( *from == 0)
	       *to = 0;
	    else {
	       *to =
		  thin1[
		  ( from[ 1] & 0x80) |
		  ( from[ 1 - line_size] & 0x40) |
		  ( from[ -line_size] & 0x20) |
		  ( from[ -1 - line_size] & 0x10) |
		  ( from[ -1] & 0x08) |
		  ( from[ -1 + line_size] & 0x04) |
		  ( from[ line_size] & 0x02) |
		  ( from[ 1 + line_size] & 0x01)
		  ];
	    }
	 }
	 *to = 0;
      }

      for ( y = 1; y < maxy; y++) {
	 to = o-> data + y * line_size;
	 from = m + y * line_size + 1;
	 *to++ = 0;

         if ( change) {
            for ( x = to + w - 2; to < x; to++, from++) {
               if ( *from) *to = 0;
            }
         } else {
            for ( x = to + w - 2; to < x; to++, from++) {
               if ( *from && *to) {
                  *to = 0;
                  change = true;
               }
            }
         }
	 *to = 0;
      }

      for ( y = 1; y < maxy; y++) {
	 to = m + y * line_size;
	 from = o-> data + y * line_size + 1;
	 *to++ = 0;

	 for ( x = to + w - 2; to < x; to++, from++) {
	    if ( *from == 0)
	       *to = 0;
	    else {
	       *to =
		  thin2[
		  ( from[ 1] & 0x80) |
		  ( from[ 1 - line_size] & 0x40) |
		  ( from[ -line_size] & 0x20) |
		  ( from[ -1 - line_size] & 0x10) |
		  ( from[ -1] & 0x08) |
		  ( from[ -1 + line_size] & 0x04) |
		  ( from[ line_size] & 0x02) |
		  ( from[ 1 + line_size] & 0x01)
		  ];
	    }
	 }
	 *to = 0;
      }

      for ( y = 1; y < maxy; y++) {
	 to = o-> data + y * line_size;
	 from = m + y * line_size + 1;
	 *to++ = 0;

         if ( change) {
            for ( x = to + w - 2; to < x; to++, from++) {
               if ( *from) *to = 0;
            }
         } else {
            for ( x = to + w - 2; to < x; to++, from++) {
               if ( *from && *to) {
                  *to = 0;
                  change = true;
               }
            }
         }
	 *to = 0;
      }
   }
   free( m);
   return o;
}

/******************************************************/
/*  Grayscale dilation and erosion of size 1,         */
/*  using 4- and 8-neighborhood.                      */
/*                                                    */
/*  Implemented by Anton Berezin <tobez@plab.ku.dk>,  */
/*  March 31, 1998                                    */
/*                                                    */
/*  Reference:                                        */
/*  William K. Pratt.  Digital Image Processing.      */
/*  John Wiley, New York, 2nd edition, 1991, p. 485   */
/******************************************************/

#undef METHOD
#define METHOD "IPA::Morphology::dilate"

#define DILATEERODE8(TYP,extremum) {                                                        \
   TYP *p, *c = nil, *n = (TYP *)(IMi-> data);                                                    \
   TYP *o = (TYP *)(IMo-> data);                                                            \
   for (y = 0; y < h; y++) {                                                                \
      p = c; c = n; n = (TYP *)(((U8 *)n) + IMi-> lineSize);                                \
      if ( y == 0) {                                                                        \
         o[0] = extremum(extremum(c[0],c[1]),extremum(n[0],n[1]));                          \
         o[maxx] = extremum(extremum(c[maxx-1],c[maxx]),extremum(n[maxx-1],n[maxx]));       \
         for (x=1;x<maxx;x++)                                                               \
            o[x] = extremum(extremum(extremum(c[x-1],c[x]),extremum(n[x-1],n[x])),          \
                   extremum(c[x+1],n[x+1]));                                                \
      } else if ( y == maxy) {                                                              \
         o[0] = extremum(extremum(c[0],c[1]),extremum(p[0],p[1]));                          \
         o[maxx] = extremum(extremum(c[maxx-1],c[maxx]),extremum(p[maxx-1],p[maxx]));       \
         for (x=1;x<maxx;x++)                                                               \
            o[x] = extremum(extremum(extremum(c[x-1],c[x]),extremum(p[x-1],p[x])),          \
                   extremum(p[x+1],p[x+1]));                                                \
      } else {                                                                              \
         o[0] = extremum(extremum(extremum(p[0],p[1]),extremum(c[0],c[1])),                 \
                extremum(n[0],n[1]));                                                       \
         o[maxx] = extremum(extremum(extremum(p[maxx-1],p[maxx]),                           \
                   extremum(c[maxx-1],c[maxx])),extremum(n[maxx-1],n[maxx]));               \
         for (x=1;x<maxx;x++)                                                               \
            o[x] = extremum(extremum(extremum(extremum(p[x-1],p[x]),extremum(c[x-1],c[x])), \
                   extremum(extremum(n[x-1],n[x]),extremum(p[x+1],c[x+1]))),n[x+1]);        \
      }                                                                                     \
      o = (TYP *)(((U8 *)o) + IMo-> lineSize);                                              \
   }                                                                                        \
}

#define DILATEERODE4(TYP,extremum) {                                                        \
   TYP *p, *c = nil, *n = (TYP *)(IMi-> data);                                                    \
   TYP *o = (TYP *)(IMo-> data);                                                            \
   for (y = 0; y < h; y++) {                                                                \
      p = c; c = n; n = (TYP *)(((U8 *)n) + IMi-> lineSize);                                \
      if ( y == 0) {                                                                        \
         o[0] = extremum(extremum(c[0],c[1]),n[0]);                                         \
         o[maxx] = extremum(extremum(c[maxx-1],c[maxx]),n[maxx]);                           \
         for (x=1;x<maxx;x++)                                                               \
            o[x] = extremum(extremum(c[x-1],c[x]),extremum(c[x+1],n[x]));                   \
      } else if ( y == maxy) {                                                              \
         o[0] = extremum(extremum(c[0],c[1]),p[0]);                                         \
         o[maxx] = extremum(extremum(c[maxx-1],c[maxx]),p[maxx]);                           \
         for (x=1;x<maxx;x++)                                                               \
            o[x] = extremum(extremum(c[x-1],c[x]),extremum(c[x+1],p[x]));                   \
      } else {                                                                              \
         o[0] = extremum(extremum(p[0],n[0]),extremum(c[0],c[1]));                          \
         o[maxx] = extremum(extremum(n[maxx],p[maxx]), extremum(c[maxx-1],c[maxx]));        \
         for (x=1;x<maxx;x++)                                                               \
            o[x] = extremum(extremum(extremum(p[x],n[x]),extremum(c[x-1],c[x+1])),c[x]);    \
      }                                                                                     \
      o = (TYP *)(((U8 *)o) + IMo-> lineSize);                                              \
   }                                                                                        \
}

PImage
IPA__Morphology_dilate( PImage IMi, HV *profile)
{
   dPROFILE;
   PImage IMo;
   int w, h, x, y, maxy, maxx;
   int neighborhood = 8;
   
   if ( !IMi || !kind_of(( Handle) IMi, CImage))
       croak("%s: not an image passed", METHOD);

   if ( IMi-> type != imByte && IMi-> type != imShort && IMi-> type != imLong && IMi-> type != imFloat && IMi-> type != imDouble)
      croak( "%s: cannot handle images other than gray scale ones", METHOD);

   if ( profile && pexist( neighborhood))   neighborhood = pget_i( neighborhood);
   if ( neighborhood != 8 && neighborhood != 4)
      croak( "%s: cannot handle neighborhoods other than 4 and 8", METHOD);

   w = IMi-> w;   h = IMi-> h;
   maxx = w - 1;  maxy = h - 1;

   if ( w < 2 || h < 2)
      croak( "%s: input image too small (should be at least 2x2)", METHOD);

   IMo = createNamedImage( w, h, IMi-> type, METHOD);
   if (!IMo) croak( "%s: cannot create output image", METHOD);

   if ( neighborhood == 8) {
      switch (IMi-> type) {
         case imByte:   DILATEERODE8(U8,max);     break;
         case imShort:  DILATEERODE8(I16,max);    break;
         case imLong:   DILATEERODE8(I32,max);    break;
         case imFloat:  DILATEERODE8(float,max);  break;
         case imDouble: DILATEERODE8(double,max); break;
      }
   } else if ( neighborhood == 4) {
      switch (IMi-> type) {
         case imByte:   DILATEERODE4(U8,max);     break;
         case imShort:  DILATEERODE4(I16,max);    break;
         case imLong:   DILATEERODE4(I32,max);    break;
         case imFloat:  DILATEERODE4(float,max);  break;
         case imDouble: DILATEERODE4(double,max); break;
      }
   }

   return IMo;
}


#undef METHOD
#define METHOD "IPA::Morphology::erode"
PImage
IPA__Morphology_erode( PImage IMi, HV *profile)
{
   dPROFILE;
   PImage IMo;
   int w, h, x, y, maxy, maxx;
   int neighborhood = 8;

   if ( !IMi || !kind_of(( Handle) IMi, CImage))
       croak("%s: not an image passed", METHOD);

   if ( IMi-> type != imByte && IMi-> type != imShort && IMi-> type != imLong && IMi-> type != imFloat && IMi-> type != imDouble)
      croak( "%s: cannot handle images other than gray scale ones", METHOD);

   if ( profile && pexist( neighborhood))   neighborhood = pget_i( neighborhood);
   if ( neighborhood != 8 && neighborhood != 4)
      croak( "%s: cannot handle neighborhoods other than 4 and 8", METHOD);

   w = IMi-> w;   h = IMi-> h;
   maxx = w - 1;  maxy = h - 1;

   if ( w < 2 || h < 2)
      croak( "%s: input image too small (should be at least 2x2)", METHOD);

   IMo = createNamedImage( w, h, IMi-> type, METHOD);
   if (!IMo) croak( "%s: cannot create output image", METHOD);

   if ( neighborhood == 8) {
      switch (IMi-> type) {
         case imByte:   DILATEERODE8(U8,min);     break;
         case imShort:  DILATEERODE8(I16,min);    break;
         case imLong:   DILATEERODE8(I32,min);    break;
         case imFloat:  DILATEERODE8(float,min);  break;
         case imDouble: DILATEERODE8(double,min); break;
      }
   } else if ( neighborhood == 4) {
      switch (IMi-> type) {
         case imByte:   DILATEERODE4(U8,min);     break;
         case imShort:  DILATEERODE4(I16,min);    break;
         case imLong:   DILATEERODE4(I32,min);    break;
         case imFloat:  DILATEERODE4(float,min);  break;
         case imDouble: DILATEERODE4(double,min); break;
      }
   }

   return IMo;
}


/******************************************************/
/*  Algebraic difference of two gray scale images of  */
/*  any supported format (imByte, imShort, imLong,    */
/*  imFloat, imDouble).  Strictly speaking, this      */
/*  operation does not belong to the mathematical     */
/*  morphology.  But it is so often used by           */
/*  morphologists that I decided to put it here.      */
/*                                                    */
/*  Implemented by Anton Berezin <tobez@plab.ku.dk>,  */
/*  April 1, 1998                                     */
/******************************************************/

#undef METHOD
#define METHOD "IPA::Morphology::algebraic_difference"

#define ALGDIFF(TYP) {                                               \
   for ( y = 0; y < h; y++) {                                        \
      TYP *dst = (TYP *)(o-> data + o-> lineSize * y);               \
      TYP *src1 = (TYP *)(i1-> data + i1-> lineSize * y);            \
      TYP *src2 = (TYP *)(i2-> data + i2-> lineSize * y);            \
      for ( x = 0; x < w; x++)   dst[x] = src1[x] - src2[x];         \
   }                                                                 \
}

PImage
IPA__Morphology_algebraic_difference( PImage i1, PImage i2, HV *profile)
{
   dPROFILE;
   Bool inPlace = false;
   PImage o = i1;
   int w, h, y, x;

   if ( !i1 || !kind_of(( Handle) i1, CImage))
      croak("%s: not an image passed to 1st parameter", METHOD);
   if ( !i2 || !kind_of(( Handle) i2, CImage))
      croak("%s: not an image passed to 2nd parameter", METHOD);
   
   if ( i1-> type != imByte && i1-> type != imShort && i1-> type != imLong && i1-> type != imFloat && i1-> type != imDouble)
      croak( "%s: cannot handle images other than gray scale ones", METHOD);

   if ( i2-> type != i1-> type || i2-> w != i1-> w || i2-> h != i1-> h)
      croak( "%s: two input images should have the same dimensions", METHOD);

   w = i1-> w;   h = i1-> h;

   if ( profile && pexist( inPlace))
      inPlace = pget_B( inPlace);

   if ( !inPlace) o = createNamedImage( w, h, i1-> type, METHOD);
   if (!o) croak( "%s: cannot create output image", METHOD);

   switch (o-> type) {
      case imByte:   ALGDIFF(U8);     break;
      case imShort:  ALGDIFF(I16);    break;
      case imLong:   ALGDIFF(I32);    break;
      case imFloat:  ALGDIFF(float);  break;
      case imDouble: ALGDIFF(double); break;
   }

   if (inPlace) o-> self-> update_change((Handle)o);
   return o;
}


/********************************************************/
/*  Watersheds.  An efficient algorithm based           */
/*  on immersion simulations.  Works for 4- and         */
/*  8-neighborhood for byte images.                     */
/*                                                      */
/*  Implemented by Anton Berezin <tobez@plab.ku.dk>,    */
/*  March 27, 1998                                      */
/*                                                      */
/*  Reference:                                          */
/*  L. Vincent & P. Soille.  Watersheds in digital      */
/*  spaces:  an efficient algorithm based on immersion  */
/*  simulations.  IEEE Trans. Patt. Anal. and Mach.     */
/*  Intell., vol. 13, no. 6, pp. 583-598, 1991          */
/********************************************************/

#undef METHOD
#define METHOD "IPA::Morphology::watershed"
#define WMASK   -2
#define WINIT   -1
#define WSHED    0
#define FICTION ((U32)(I32)-1)

#define FIFO_EMPTY (head==tail)
#define FIFO_ADD(pixel) {queue[tail]=(pixel);tail++;if(tail>=qsize)tail=0;if(tail==head)croak("%s: queue overflow", METHOD);qn++;if(qn>maxqueue)maxqueue=qn;}
#define FIFO_FIRST(pixel) {if(head==tail)croak("%s: attempt to read from the empty queue", METHOD);(pixel)=queue[head];head++;if(head>=qsize)head=0;qn--;}

static U32 *
watershed_sorting_step( U8 *img, int N, int *hmin, int *hmax, U32 *fr)
{
   U32 freq[ 256];
   int i;
   U32 *sort;

   /* Obtain frequency distribution */
   memset( freq, 0, 256*sizeof(U32));
   for ( i = 0; i < N; i++) freq[img[i]]++;
   memcpy( fr, freq, 256*sizeof(U32));

   /* Calculate hmin & hmax */
   *hmin = 0;   while ( *hmin < 256 && freq[*hmin] == 0) (*hmin)++;
   *hmax = 255; while ( *hmax > 0 && freq[*hmax] == 0)   (*hmax)--;

   /* Obtain cumulative frequency distribution */
   for ( i = 1; i < 256; i++) freq[i] += freq[i-1];

   /* allocate and fill an array of sorted positions */
   sort = malloc( N*sizeof(U32));
   for ( i = 0; i < N; i++) sort[--freq[img[i]]] = i;

   return sort;
}

PImage
IPA__Morphology_watershed( PImage IMi, HV *profile)
{
   dPROFILE;
   int neighborhood = 4;
   U32 *sorted;
   I16 *out;
   U16 *distance;
   U8 *inp;
   int N, x, y, width, height, i, n, maxx, maxy;
   int hmin, hmax, h;
   U32 p, pp, pbs;
   U16 dist;
   U16 maxdist = 1;
   int maxqueue = 0, qn = 0;
   I16 label;
   U32 freq[ 256];
   U32 pbis[8];
   int npbis;
   U32 *queue;
   int qsize, head, tail;
   PImage IMo;

   if ( !IMi || !kind_of(( Handle) IMi, CImage))
       croak("%s: not an image passed", METHOD);
   
   if ( IMi-> type != imByte)
      croak( "%s: cannot handle images different from 8-bit gray scale", METHOD);

   if ( pexist(neighborhood)) neighborhood = pget_i(neighborhood);
   if ( neighborhood != 4 && neighborhood != 8)
      croak( "%s: wrong neighborhood;  can only be 4 or 8", METHOD);

   /* Initialization */
   width = IMi-> w; height = IMi-> h;
   maxx = width - 1;  maxy = height - 1;
   N = width*height;

   /* Convert our image to non-aligned data structure */
   inp = malloc( N);
   for (y = 0; y < height; y++)  memcpy( inp+width*y, IMi-> data + IMi-> lineSize*y, width);

   /* Obtain sorted array of pixel positions */
   sorted = watershed_sorting_step( inp, N, &hmin, &hmax, freq);

   /* Check the correctness of sorting */
   if (0) {                                                                           
      U8 last = 0;                                                             
      for ( i = 0; i < N; i++)                                                 
         if ( inp[sorted[i]] < last) croak( "%s: incorrectly sorted", METHOD); 
         else last = inp[sorted[i]];                                           
   }                                                                           

   /* create and initialize output data array */
   out = malloc( N*sizeof(I16));
   for ( i = 0; i < N; i++) out[i] = WINIT;

   /* create and initialize distance work image */
   distance = malloc( N*sizeof(U16));
   memset( distance, 0, N*sizeof(U16));

   /* create and initialize the queue */
   queue = malloc( N/4*sizeof(U32));
   qsize = N/4;  head = 0;  tail = 0;

   /* other initialization */
   label = 0;
   i = 0;

   /* main loop */
   for ( h = hmin; h <= hmax; h++) {
      /*=== geodesic SKIZ of level h-1 inside level h */
      /*=== for every pixel p such that IMi(p) == h */
      n = freq[h];
      if ( neighborhood == 4)
         while (n--) {
            p = sorted[i++];
            if (inp[p] != h) croak("sort assertion failed: %d(%d) != %d", inp[p], p, h);
            x = p % width;
            y = p / width;
            out[p] = WMASK;
            if (
               (x < maxx && out[p+1] >= WSHED) ||
               (x > 0 && out[p-1] >= WSHED) ||
               (y > 0 && out[p-width] >= WSHED) ||
               (y < maxy && out[p+width] >= WSHED)
            ) {
               distance[p] = 1;
               FIFO_ADD(p);
            }
         }
      else /* neighborhood == 8 */
         while (n--) {
            p = sorted[i++];
            x = p % width;
            y = p / width;
            out[p] = WMASK;
            if (
               (x < maxx && (out[p+1] >= WSHED || ( y > 0 && out[p-width+1] >= WSHED) || ( y < maxy && out[p+width+1] >= WSHED))) ||
               (x > 0 && (out[p-1] >= WSHED || ( y > 0 && out[p-width-1] >= WSHED) || ( y < maxy && out[p+width-1] >= WSHED))) ||
               (y > 0 && out[p-width] >= WSHED) ||
               (y < maxy && out[p+width] >= WSHED)
            ) {
               distance[p] = 1;
               FIFO_ADD(p);
            }
         }
      dist = 1; FIFO_ADD(FICTION);
      while (1) {
         FIFO_FIRST(p);
         if ( p == FICTION) {
            if ( FIFO_EMPTY) break;
            FIFO_ADD( FICTION);
            dist++;
if(dist>maxdist)maxdist=dist;
            FIFO_FIRST(p);
         }
         if ( FIFO_EMPTY) croak("assertion failed: !FIFO_EMPTY");
         x = p % width;
         y = p / width;
         if (neighborhood == 4) {
            npbis = 0;
            if ( x > 0) pbis[npbis++] = p-1;
            if ( x < maxx) pbis[npbis++] = p+1;
            if ( y > 0) pbis[npbis++] = p-width;
            if ( y < maxy) pbis[npbis++] = p+width;
         } else /* neighborhood == 8 */ {
            npbis = 0;
            if ( x > 0) {
               pbis[npbis++] = p-1;
               if ( y > 0) pbis[npbis++] = p-width-1;
               if ( y < maxy) pbis[npbis++] = p+width-1;
            }
            if ( x < maxx) {
               pbis[npbis++] = p+1;
               if ( y > 0) pbis[npbis++] = p-width+1;
               if ( y < maxy) pbis[npbis++] = p+width+1;
            }
            if ( y > 0) pbis[npbis++] = p-width;
            if ( y < maxy) pbis[npbis++] = p+width;
         }
         /*=== for every pixel p' belonging to Ng(p) */
         while (--npbis >= 0) {
            pbs = pbis[npbis];
            if (distance[pbs]<dist && out[pbs] >= WSHED) {
               if (out[pbs]>0) {
                  if (out[p]==WMASK || out[p]==WSHED)
                     out[p] = out[pbs];
                  else if (out[p] != out[pbs])
                     out[p] = WSHED;
               } else if (out[p] == WMASK)
                  out[p] = WSHED;
            } else if (out[pbs]==WMASK && distance[pbs] == 0) {
               distance[pbs] = dist + 1;
               FIFO_ADD(pbs);
            }
         }
      } /* while(1) */
      /*=== checks if new minima have been discovered */
      n = freq[h]; i -= n;
      while (n--) {
         p = sorted[i++];
         distance[p] = 0;
         if ( out[p] == WMASK) {
            label++;
            FIFO_ADD(p);
            out[p] = label;
            while (!FIFO_EMPTY) {
               FIFO_FIRST(pp);
               x = pp % width;
               y = pp / width;
               if (neighborhood == 4) {
                  npbis = 0;
                  if ( x > 0) pbis[npbis++] = pp-1;
                  if ( x < maxx) pbis[npbis++] = pp+1;
                  if ( y > 0) pbis[npbis++] = pp-width;
                  if ( y < maxy) pbis[npbis++] = pp+width;
               } else /* neighborhood == 8 */ {
                  npbis = 0;
                  if ( x > 0) {
                     pbis[npbis++] = pp-1;
                     if ( y > 0) pbis[npbis++] = pp-width-1;
                     if ( y < maxy) pbis[npbis++] = pp+width-1;
                  }
                  if ( x < maxx) {
                     pbis[npbis++] = pp+1;
                     if ( y > 0) pbis[npbis++] = pp-width+1;
                     if ( y < maxy) pbis[npbis++] = pp+width+1;
                  }
                  if ( y > 0) pbis[npbis++] = pp-width;
                  if ( y < maxy) pbis[npbis++] = pp+width;
               }
               while (--npbis >= 0) {
                  pbs = pbis[npbis];
                  if ( out[pbs] == WMASK) {
                     FIFO_ADD(pbs);
                     out[pbs] = label;
                  }
               }
            }
         }
      }
   }

   if (!FIFO_EMPTY) warn( "%s: queue is not empty - can't be", METHOD);

   /* Convert the result to a suitable form */
   IMo = createNamedImage( width, height, imByte, "Watershed lines");
   if (!IMo) {
      free( queue);
      free( distance);
      free( out);
      free( sorted);
      free( inp);
      croak( "%s: cannot create output image", METHOD);
   }
   for ( y = 0; y < height; y++)
      for ( x = 0; x < width; x++) {
         p = x+width*y;
         if (out[p] == WMASK) croak("%s: %d,%d has mask",METHOD,x,y);
         if (out[p] == WINIT) croak("%s: %d,%d has init",METHOD,x,y);
         if (out[p] == WSHED) continue;
         if ( neighborhood == 4) {
            if (
               (x < maxx && out[p+1] > WSHED && out[p+1] < out[p]) ||
               (x > 0 && out[p-1] > WSHED && out[p-1] < out[p]) ||
               (y > 0 && out[p-width] > WSHED && out[p-width] < out[p]) ||
               (y < maxy && out[p+width] > WSHED && out[p+width] < out[p])
            )
               out[p] = WSHED;
         } else {
            if (
               (x < maxx && ((out[p+1] > WSHED && out[p+1] < out[p])
                  || ( y > 0 && out[p-width+1] > WSHED && out[p-width+1] < out[p])
                  || ( y < maxy && out[p+width+1] > WSHED && out[p+width+1] < out[p]))) ||
               (x > 0 && ((out[p-1] > WSHED && out[p-1] < out[p])
                  || ( y > 0 && out[p-width-1] > WSHED && out[p-width-1] < out[p])
                  || ( y < maxy && out[p+width-1] > WSHED && out[p+width-1] < out[p]))) ||
               (y > 0 && out[p-width] > WSHED && out[p-width] < out[p]) ||
               (y < maxy && out[p+width] > WSHED && out[p+width] < out[p])
            )
               out[p] = WSHED;
         }
      }


   if ( IMo-> type == imByte)
      for ( y = 0; y < height; y++)
         for ( x = 0; x < width; x++)
            IMo-> data[ y*IMo-> lineSize+x] = ((out[x+width*y] == WSHED) ? 255 : 0);
   else { /* i.e. IMi-> type == imShort */
      for ( y = 0; y < height; y++) {
         I16 *o = (I16*)(IMo-> data + y*IMo-> lineSize);
         I16 *i = out+width*y;
         for ( x = 0; x < width; x++) o[x] = i[x];
      }
   }

   free( queue);
   free( distance);
   free( out);
   free( sorted);
   free( inp);

   return IMo;
}

#undef METHOD
#define METHOD "IPA::Morphology::reconstruct"

#define define_reconstruct(TYP,NEIGHBORHOOD)                                   \
static void reconstruct_##TYP##_##NEIGHBORHOOD( PImage I, PImage J) {          \
   int w, h, x, y, maxx, maxy, p, nn, nn1, lineSize;                           \
   int nabo[NEIGHBORHOOD];                                                     \
   U8 *i = I-> data;                                                           \
   U8 *j = J-> data;                                                           \
   TYP v, v2, v3;                                                              \
int maxqueue = 0, qn = 0;                                                      \
   U32 *queue;                                                                 \
   int qsize, head, tail;                                                      \
   int sz;                                                                     \
                                                                               \
   w = I-> w;    h = I-> h;                                                    \
   maxx = w - 1; maxy = h - 1;                                                 \
   sz = sizeof(TYP);  lineSize = I-> lineSize;                                 \
                                                                               \
   /* create and initialize the queue */                                       \
   queue = malloc( w*h/4*sizeof(U32));                                         \
   qsize = w*h/4;  head = 0;  tail = 0;                                        \
                                                                               \
if(0)debug_write( "raster"); \
   /* scan image in raster order */                                            \
   for ( y = 0; y < h; y++) {                                                  \
if(0)debug_write( "yyyyyyy: %d", y); \
      p = lineSize * y;                                                        \
if(0)if(y==1)debug_write( "p: %d", p); \
      for ( x = 0; x < w; x++,p+=sizeof(TYP)) {                                \
         NPLUS;                                                                \
if(0)if(y==1)debug_write( "x: %d, nn: %d", x, nn); \
         v = *((TYP*)(j+p));                                                   \
         while (--nn >= 0) {                                                   \
            v2 = *((TYP*)(j+nabo[nn]));                                        \
            if ( v2 > v) v = v2;                                               \
         }                                                                     \
         v2 = *((TYP*)(i+p));                                                  \
         *((TYP*)(j+p)) = min(v,v2);                                           \
      }                                                                        \
   }                                                                           \
                                                                               \
if(0)debug_write( "anti"); \
   /* scan image in anti-raster order */                                       \
   for ( y = maxy; y >= 0; y--) {                                              \
if(0)debug_write( "%d", y); \
      p = lineSize * y + (w-1)*sizeof(TYP);                                    \
      for ( x = maxx; x >= 0; x--,p-=sizeof(TYP)) {                            \
         NMINUS; nn1 = nn;                                                     \
         v = *((TYP*)(j+p));                                                   \
         while (--nn >= 0) {                                                   \
            v2 = *((TYP*)(j+nabo[nn]));                                        \
            if ( v2 > v) v = v2;                                               \
         }                                                                     \
         v2 = *((TYP*)(i+p));                                                  \
         *((TYP*)(j+p)) = v = min(v,v2);                                       \
         nn = nn1;                                                             \
         while (--nn >= 0) {                                                   \
            v2 = *((TYP*)(j+nabo[nn]));                                        \
            if (v2 < v && v2 < *((TYP*)(i+nabo[nn]))) {                        \
               FIFO_ADD(p);                                                    \
               break;                                                          \
            }                                                                  \
         }                                                                     \
      }                                                                        \
   }                                                                           \
                                                                               \
if(0)debug_write( "prop"); \
   /* propagation step */                                                      \
   while (!FIFO_EMPTY) {                                                       \
      FIFO_FIRST(p);                                                           \
      v = *((TYP*)(j+p));  /* J(p) */                                          \
      x = (p % lineSize) / sizeof(TYP);                                        \
      y = p / lineSize;                                                        \
      NABO;                                                                    \
      while (--nn >= 0) {                                                      \
         v2 = *((TYP*)(j+nabo[nn])); /* J(q) */                                \
         v3 = *((TYP*)(i+nabo[nn])); /* I(q) */                                \
         if ( v2 < v && v3 != v2) {                                            \
            *((TYP*)(j+nabo[nn])) = min(v,v3);                                 \
            FIFO_ADD(nabo[nn]);                                                \
         }                                                                     \
      }                                                                        \
   }                                                                           \
                                                                               \
   free(queue);                                                                \
}

#undef NABO
#define NABO  {                                             \
   nn = 0;                                                  \
   if ( x > 0) {                                            \
      nabo[nn++] = p-sz;                                    \
      if ( y > 0) nabo[nn++] = p-lineSize-sz;               \
      if ( y < maxy) nabo[nn++] = p+lineSize-sz;            \
   }                                                        \
   if ( x < maxx) {                                         \
      nabo[nn++] = p+sz;                                    \
      if ( y > 0) nabo[nn++] = p-lineSize+sz;               \
      if ( y < maxy) nabo[nn++] = p+lineSize+sz;            \
   }                                                        \
   if ( y > 0) nabo[nn++] = p-lineSize;                     \
   if ( y < maxy) nabo[nn++] = p+lineSize;                  \
}
#undef NPLUS
#define NPLUS {                                             \
   nn = 0;                                                  \
   if ( x > 0) {                                            \
      nabo[nn++] = p-sz;                                    \
      if ( y > 0) nabo[nn++] = p-lineSize-sz;               \
   }                                                        \
   if ( x < maxx) {                                         \
      if ( y > 0) nabo[nn++] = p-lineSize+sz;               \
   }                                                        \
   if ( y > 0) nabo[nn++] = p-lineSize;                     \
}
#undef NMINUS
#define NMINUS {                                            \
   nn = 0;                                                  \
   if ( x > 0) {                                            \
      if ( y < maxy) nabo[nn++] = p+lineSize-sz;            \
   }                                                        \
   if ( x < maxx) {                                         \
      nabo[nn++] = p+sz;                                    \
      if ( y < maxy) nabo[nn++] = p+lineSize+sz;            \
   }                                                        \
   if ( y < maxy) nabo[nn++] = p+lineSize;                  \
}
#define define_reconstruct8(TYP) define_reconstruct(TYP,8)
define_reconstruct8(U8)
define_reconstruct8(I16)
define_reconstruct8(I32)
define_reconstruct8(float)
define_reconstruct8(double)

#undef NABO
#define NABO {                                         \
   nn = 0;                                             \
   if ( x > 0) nabo[nn++] = p-sz;                      \
   if ( x < maxx) nabo[nn++] = p+sz;                   \
   if ( y > 0) nabo[nn++] = p-lineSize;                \
   if ( y < maxy) nabo[nn++] = p+lineSize;             \
}
#undef NPLUS
#define NPLUS {                                        \
   nn = 0;                                             \
   if ( x > 0) nabo[nn++] = p-sz;                      \
   if ( y > 0) nabo[nn++] = p-lineSize;                \
}
#undef NMINUS
#define NMINUS {                                       \
   nn = 0;                                             \
   if ( x < maxx) nabo[nn++] = p+sz;                   \
   if ( y < maxy) nabo[nn++] = p+lineSize;             \
}
#define define_reconstruct4(TYP) define_reconstruct(TYP,4)
define_reconstruct4(U8)
define_reconstruct4(I16)
define_reconstruct4(I32)
define_reconstruct4(float)
define_reconstruct4(double)

PImage
IPA__Morphology_reconstruct( PImage I, PImage J, HV *profile)
{
/* Mask image I
 Marker image J
 if inPlace turned on, the result will be placed into J */
   dPROFILE;
   Bool inPlace = false;
   int neighborhood = 8;
   SV * name;

   if ( !I || !kind_of(( Handle) I, CImage))
       croak("%s: not an image passed to 1st parameter", METHOD);
   if ( !J || !kind_of(( Handle) J, CImage))
       croak("%s: not an image passed to 2nd parameter", METHOD);

   if ( I-> type != imByte && I-> type != imShort && I-> type != imLong && I-> type != imFloat && I-> type != imDouble)
      croak( "%s: cannot handle images other than gray scale ones", METHOD);
   if ( J-> type != I-> type || J-> w != I-> w || J-> h != I-> h)
      croak( "%s: two input images should have the same dimensions", METHOD);
   if ( I-> w < 2 || I-> h < 2)
      croak( "%s: input image too small (should be at least 2x2)", METHOD);
   if ( I-> lineSize != J-> lineSize)
      croak( "%s: strange inconsistency in line sizes", METHOD);

   if ( profile && pexist( inPlace)) inPlace = pget_B( inPlace);
   if ( profile && pexist( neighborhood)) neighborhood = pget_i( neighborhood);
   if ( neighborhood != 8 && neighborhood != 4)
      croak( "%s: cannot handle neighborhoods other than 4 and 8", METHOD);

   if ( !inPlace) {
      PImage o = (PImage)J-> self-> dup((Handle)J);
      if (!o) croak( "%s: cannot create output image", METHOD);
      J = o;
   }
   name = newSVpv( METHOD, 0);
   J-> self-> set_name((Handle)J, name);
   sv_free( name);

   switch ( neighborhood) {
      case 4:
      switch (J-> type) {
         case imByte:   reconstruct_U8_4(I,J);     break;
         case imShort:  reconstruct_I16_4(I,J);    break;
         case imLong:   reconstruct_I32_4(I,J);    break;
         case imFloat:  reconstruct_float_4(I,J);  break;
         case imDouble: reconstruct_double_4(I,J); break;
      }
      break;
      case 8:
      switch (J-> type) {
         case imByte:   reconstruct_U8_8(I,J);     break;
         case imShort:  reconstruct_I16_8(I,J);    break;
         case imLong:   reconstruct_I32_8(I,J);    break;
         case imFloat:  reconstruct_float_8(I,J);  break;
         case imDouble: reconstruct_double_8(I,J); break;
      }
      break;
   }

   if (inPlace) J-> self-> update_change((Handle)J);
   return J;
}
#undef METHOD
