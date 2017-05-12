/* $Id$ */

#include "IPAsupp.h"
#include "Global.h"
#include "GlobalSupp.h"

#define lcUnclassified  0
#define lcEdge          1
#define lcSmall         2
#define lcLarge         3
#define lcNormal        10    /* from this code all 'normal' codes begin */

#undef METHOD
#define WHINE(msg) croak( "%s: %s", METHOD, (msg))

/* Primitive line - building block of a LAG */

typedef struct _LAGLine
{
    int beg;
    int end;
    int code;
    int y;
    struct _LAGLine *next;    /* Next with the same code */
} LAGLine, *PLAGLine;


/*  One scan line may contain a big number of LAGLines */

/*  An example of a scan line with recognized lines indicated: */

/*     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
/*     | | |X|X|X|X| | |X|X|X|X|X|X| | |X|X| | */
/*     +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+ */
/*          ^^^^^^^     ^^^^^^^^^^^     ^^^ */
/*         line # 1       line #2     line #3 */


/* Complete LAG structure */

typedef struct _LAG
{
   int h, w;                     /* original image dimensions */
   PLAGLine *scanLines;          /* array of pointers to every scan line */
   int *lineCount;               /* number of lines (chords) in every scan line */
   int maxComponentCode;
   int codedCollectionSize;
   PLAGLine *codedLines;
   int *codedAreas;              /* Area of components is very useful */
} LAG, *PLAG;


/* LAG freeing function */
void
free_lag( PLAG lag)
{
   int i;

   if ( lag == nil)  return;

   free( lag-> codedLines);
   free( lag-> codedAreas);

   if ( lag-> scanLines != nil)
      for ( i = 0; i < lag-> h; i++)
         free( lag-> scanLines[ i]);

   free( lag-> scanLines);
   free( lag-> lineCount);

   free( lag);
}

void
clean_codes( PLAG lag)
{
   int i, j;

   if ( lag-> codedLines)
      free( lag-> codedLines);
   if ( lag-> codedAreas)
      free( lag-> codedAreas);
   lag-> maxComponentCode = lcNormal;
   lag-> codedCollectionSize = 256;
   lag-> codedLines = allocnz( PLAGLine, lag-> codedCollectionSize);
   lag-> codedAreas = allocnz( int, lag-> codedCollectionSize);

   /* Clean next pointer everywere */
   if ( lag-> scanLines != nil)
      for ( i = 0; i < lag-> h; i++)
         for ( j = 0; j < lag-> lineCount[ i]; j++)
            lag-> scanLines[ i][ j]. next = nil;
}


/* LAG building function */

PLAG
build_lag( PImage im, unsigned char c, const char *METHOD)
{
   PLAG lag;            /* structure to be built */
   int w, h;            /* width and height of an image */
   int i, j, n;         /* indices & counters */
   PLAGLine scan;       /* temporary scan line */
   unsigned char *row;  /* a row of an image */

   /* build_lag() can only work with byte images */
   if ( im-> type != imByte)
      WHINE( "unsupported image type");

   h = im-> h;
   w = im-> w;

   /* Allocate and initialize main LAG structure */
   lag = malloc( sizeof( LAG));
   if ( lag == nil)
      WHINE( "no memory");
   memset( lag, 0, sizeof( LAG));
   lag-> scanLines = malloc( sizeof( PLAGLine) * h);
   if ( lag-> scanLines == nil)
   {
      free_lag( lag);
      WHINE( "no memory");
   }
   memset( lag-> scanLines, 0, sizeof( PLAGLine) * h);
   lag-> lineCount = malloc( sizeof( int) * h);
   if ( lag-> lineCount == nil)
   {
      free_lag( lag);
      WHINE( "no memory");
   }
   memset( lag-> lineCount, 0, sizeof( int) * h);
   lag-> h = h;
   lag-> w = w;

   /* Allocate intermediate LAGScanLine of big enough size. */
   /* It is impossible to have more than ( w + 1) / 2 distinct lines in a scan line. */
   scan = malloc( sizeof( LAGLine) * ( w + 1) / 2);
   if ( scan == nil)
   {
      free_lag( lag);
      WHINE( "no memory");
   }

   /* Scan through every line of the image */
   for ( i = 0; i < h; i++)
   {
      n = 0;      /* n holds the number of distinct lines in the current scan line */
      j = 0;      /* start scan from the leftmost pixel */
      row = im-> data + im-> lineSize * i;

      while ( j < w)
      {
         /* Skip from the current position to the first pixel having specified color c */
         while (( j < w) && ( row[ j] != c))    j++;

         /* Store the line, if any */
         if ( j < w)
         {
            scan[ n]. next = nil;      /* this field is not used in this function at all! */
            scan[ n]. y = i;           /* reference to the scan line */
            scan[ n]. beg = j;         /* The line begins from j */
            scan[ n]. code = lcUnclassified;
            /* Seeking the end of the line... */
            while (( j < w) && ( row[ j] == c))    j++;
            scan[ n]. end = j - 1;     /* The line ends here */
            /* Update the lines counter */
            n++;
         }
      }

      /* Add the scan line description to the LAG (if needed) */
      if ( n > 0)
      {
         lag-> scanLines[ i] = malloc( sizeof( LAGLine) * n);
         lag-> lineCount[ i] = n;
         memcpy( lag-> scanLines[ i], scan, sizeof( LAGLine) * n);
      }
   }

   free(scan);
   return lag;
}


/*  Searching the connected components in a LAG */

/*  edgeSize specifies the frame around the border of the */
/*     image;  all the components any part of which is */
/*     inside that frame are marked as lcEdge */

void
find_lag_components( PLAG lag, int edgeSize, Bool eightConnectivity)
{
   int y, i, j;
   PLAGLine line, prevLine;
   PLAGLine prevScanLine;
   PLAGLine curScanLine = nil;
   int prevLineCount, curLineCount = 0;

   /* Necessary adjustment! */
   eightConnectivity = ( eightConnectivity) ? 1 : 0;

   clean_codes( lag);
   /* After this call we garanteed to have size of codedLines and */
   /* codedAreas to be at least lcNormal;  hence no checking for */
   /* lcEdge (lcEdge < lcNormal). */

   /* Initial marking of a priori edge-touched lines */
   /*  (not all of them, though;  only bottom border stripe is considered here */
   for ( y = 0; y < edgeSize; y++)
   {
      curScanLine = lag-> scanLines[ y];
      curLineCount = lag-> lineCount[ y];
      for ( i = 0; i < curLineCount; i++)
      {
         line = curScanLine + i;
         line-> code = lcEdge;
         line-> next = lag-> codedLines[ lcEdge];
         lag-> codedLines[ lcEdge] = line;
         lag-> codedAreas[ lcEdge] += line-> end - line-> beg + 1;
      }
   }

   /* Main loop through the rest of the lines */
   for ( y = edgeSize; y < lag-> h; y++)
   {
      prevScanLine = curScanLine;
      curScanLine = lag-> scanLines[ y];
      prevLineCount = curLineCount;
      curLineCount = lag-> lineCount[ y];

      for ( i = 0; i < curLineCount; i++)
      {
         int lastScanned = 0;    /* In the previous scan line! */
         Bool edgeTouched = false;
         Bool overlaps = false;
         int overlappedWith = 0;
         int oldCode, newCode;
         PLAGLine toChange;

         line = curScanLine + i;

         for ( j = lastScanned; j < prevLineCount; j++)
         {
            prevLine = prevScanLine + j;
            if (( line-> beg <= prevLine-> end + eightConnectivity) &&
                ( line-> end >= prevLine-> beg - eightConnectivity))
            {
               overlaps = true;
               lastScanned = j + 1;
               overlappedWith = prevLine-> code;
               break;  /* the j loop */
            }
         }

         if ( overlaps)
         {
            line-> code = overlappedWith;
            line-> next = lag-> codedLines[ overlappedWith];
            lag-> codedLines[ overlappedWith] = line;
            lag-> codedAreas[ overlappedWith] += line-> end - line-> beg + 1;

            edgeTouched = ( overlappedWith == lcEdge);

            /* Check for multiple overlapping */
            while ( overlaps)
            {
               overlaps = false;

               for ( j = lastScanned; j < prevLineCount; j++)
               {
                  prevLine = prevScanLine + j;
                  if (( line-> beg <= prevLine-> end + eightConnectivity) &&
                      ( line-> end >= prevLine-> beg - eightConnectivity))
                  {
                     overlaps = true;
                     lastScanned = j + 1;
                     overlappedWith = prevLine-> code;
                     break;  /* the j loop */
                  }
               }

               if ( !overlaps)   break;      /* Good boy! */

               if ( line-> code == overlappedWith) continue;      /* Not bad... */

               if ( edgeTouched && ( overlappedWith != lcEdge))
               {
                  oldCode = overlappedWith;
                  newCode = lcEdge;
               }
               else
               {
                  oldCode = line-> code;
                  newCode = overlappedWith;
               }

               /* Perform code adjustment */
               toChange = lag-> codedLines[ oldCode];
               if ( toChange != nil)
               {
                  while ( toChange-> next != nil)
                  {
                     toChange-> code = newCode;
                     toChange = toChange-> next;
                  }
                  toChange-> code = newCode;
                  toChange-> next = lag-> codedLines[ newCode];
                  lag-> codedLines[ newCode] = lag-> codedLines[ oldCode];
                  lag-> codedAreas[ newCode] += lag-> codedAreas[ oldCode];
                  lag-> codedLines[ oldCode] = nil;
                  lag-> codedAreas[ oldCode] = 0;
               }

               edgeTouched = ( overlappedWith == lcEdge) ? true : edgeTouched;

            }
         }
         else
         {
            /* Didn't overlap;  assign the unique code here */
            /* Check the collection on overflow (expand if necessary) */
            if ( lag-> maxComponentCode >= lag-> codedCollectionSize)
            {
               PLAGLine *codedLines;
               int *codedAreas;
               int sz;

               sz = lag-> codedCollectionSize * 2;
               codedLines = allocnz( PLAGLine, sz);
               codedAreas = allocnz( int, sz);
               memcpy( codedLines, lag-> codedLines, lag-> maxComponentCode * sizeof( PLAGLine));
               memcpy( codedAreas, lag-> codedAreas, lag-> maxComponentCode * sizeof( int));
               free( lag-> codedLines);
               free( lag-> codedAreas);
               lag-> codedLines = codedLines;
               lag-> codedAreas = codedAreas;
               lag-> codedCollectionSize = sz;
            }
            line-> code = lag-> maxComponentCode;
            line-> next = lag-> codedLines[ line-> code];
            lag-> codedLines[ line-> code] = line;
            lag-> codedAreas[ line-> code] = line-> end - line-> beg + 1;
            lag-> maxComponentCode++;
         }

         if (( !edgeTouched) &&
             (( line-> beg < edgeSize) ||
              ( line-> end >= lag-> w - edgeSize) ||
              ( y >= lag-> h - edgeSize)))
         {
            oldCode = line-> code;
            newCode = lcEdge;
            toChange = lag-> codedLines[ oldCode];
            if ( toChange)
            {
               while ( toChange-> next)
               {
                  toChange-> code = newCode;
                  toChange = toChange-> next;
               }
               toChange-> code = newCode;
               toChange-> next = lag-> codedLines[ newCode];
               lag-> codedLines[ newCode] = lag-> codedLines[ oldCode];
               lag-> codedAreas[ newCode] += lag-> codedAreas[ oldCode];
               lag-> codedLines[ oldCode] = nil;
               lag-> codedAreas[ oldCode] = 0;
            }

         }

      }
   }
}

#undef METHOD
#define METHOD "IPA::Global::fill_holes"

PImage
IPA__Global_fill_holes( PImage in, HV *profile)
{
   dPROFILE;
   Bool inPlace = false;
   PImage out = in;
   int edgeSize = 1;
   int backColor = 0;
   int foreColor = 255;
   int neighborhood = 4;	/* beware of the default */
   PLAG lag;
   int i;
   PLAGLine line;

   if ( !in || !kind_of(( Handle) in, CImage)) WHINE("Not an image passed");

   if ( profile && pexist( inPlace))
      inPlace = pget_B( inPlace);
   if ( profile && pexist( edgeSize))
      edgeSize = pget_i( edgeSize);
   if ( edgeSize <= 0 || edgeSize > min( in-> w, in-> h)/2)
      WHINE( "bad edgeSize");
   if ( profile && pexist( backColor))
      backColor = pget_i( backColor);
   if ( profile && pexist( foreColor))
      foreColor = pget_i( foreColor);
   if ( profile && pexist( neighborhood))
      neighborhood = pget_i( neighborhood);
   if ( neighborhood != 8 && neighborhood != 4)
      WHINE( "cannot handle neighborhoods other than 4 and 8");

   if (!inPlace) {
      SV * name;
      out = (PImage)in-> self-> dup((Handle)in);
      if (!out)
	 WHINE( "error creating output image");
      SvREFCNT(SvRV(out-> mate))++;
      name = newSVpv( METHOD, 0);
      out-> self-> set_name((Handle)out, name);
      sv_free( name);
      SvREFCNT(SvRV(out-> mate))--;
   }

   lag = build_lag( out, (U8)backColor, METHOD);
   find_lag_components( lag, edgeSize, neighborhood == 8);
   for ( i = lcNormal; i < lag-> maxComponentCode; i++)
   {
      for ( line = lag-> codedLines[ i]; line != nil; line = line-> next) {
         memset( out-> data + line-> y * out-> lineSize + line-> beg,
                 (U8)foreColor, line-> end - line-> beg + 1);
      }
   }
   free_lag( lag);
   if (inPlace) out-> self-> update_change((Handle)out);
   return out;
}

#undef METHOD
#define METHOD "IPA::Global::area_filter"

PImage
IPA__Global_area_filter( PImage in, HV *profile)
{
   dPROFILE;
   Bool inPlace = false;
   PImage out = in;
   int edgeSize = 1;
   int backColor = 0;
   int foreColor = 255;
   int neighborhood = 8;
   int minArea = 0;
   int maxArea = INT_MAX;
   PLAG lag;
   PLAGLine line;
   int i;

   if ( !in || !kind_of(( Handle) in, CImage)) WHINE("Not an image passed");

   if ( profile && pexist( inPlace))
      inPlace = pget_B( inPlace);
   if ( profile && pexist( edgeSize))
      edgeSize = pget_i( edgeSize);
   if ( edgeSize <= 0 || edgeSize > min( in-> w, in-> h)/2)
      WHINE( "bad edgeSize");
   if ( profile && pexist( backColor))
      backColor = pget_i( backColor);
   if ( profile && pexist( foreColor))
      foreColor = pget_i( foreColor);
   if ( profile && pexist( neighborhood))
      neighborhood = pget_i( neighborhood);
   if ( neighborhood != 8 && neighborhood != 4)
      WHINE( "cannot handle neighborhoods other than 4 and 8");
   if ( profile && pexist( minArea))
      minArea = pget_i( minArea);
   if ( profile && pexist( maxArea))
      maxArea = pget_i( maxArea);

   if (!inPlace) {
      SV * name;
      out = (PImage)in-> self-> dup((Handle)in);
      if (!out)
	 WHINE( "error creating output image");
      SvREFCNT(SvRV(out-> mate))++;
      name = newSVpv( METHOD, 0);
      out-> self-> set_name((Handle)out, name);
      sv_free( name);
      SvREFCNT(SvRV(out-> mate))--;
   }

   lag = build_lag( out, (U8)foreColor, METHOD);
   find_lag_components( lag, edgeSize, neighborhood == 8);

   /* Remove edge-touched */
   for ( line = lag-> codedLines[ lcEdge]; line != nil; line = line-> next)
      memset( out-> data + line-> y * out-> lineSize + line-> beg,
              (U8)backColor, line-> end - line-> beg + 1);

   /* Remove by area */
   for ( i = lcNormal; i < lag-> maxComponentCode; i++)
   {
      if (( minArea > 0) && ( lag-> codedAreas[ i] < minArea))
         for ( line = lag-> codedLines[ i]; line != nil; line = line-> next)
            memset( out-> data + line-> y * out-> lineSize + line-> beg,
                    (U8)backColor, line-> end - line-> beg + 1);

      if (( maxArea > 0) && ( lag-> codedAreas[ i] > maxArea))
         for ( line = lag-> codedLines[ i]; line != nil; line = line-> next)
            memset( out-> data + line-> y * out-> lineSize + line-> beg,
                    (U8)backColor, line-> end - line-> beg + 1);
   }

   free_lag( lag);
   if (inPlace) out-> self-> update_change((Handle)out);
   return out;
}

#undef METHOD
#define METHOD "IPA::Global::identify_contours"

SV*
/* [[x00,y00,x01,y01,...,x0n,y0n,x00,y00],[x10,y10,x11,y11,...],[x20,y20,x21,y21,...]] */
IPA__Global_identify_contours( PImage in, HV *profile)
{
   dPROFILE;
   int edgeSize = 1;
   int backColor = 0;
   int foreColor = 255;
   int neighborhood = 8;
   PLAG lag;
   PLAGLine line;
   int i;
   AV *result;
   AV *contour;
   int di[8], xi[8], yi[8];
   int x0, y0, x, y, d, times;
   Bool first, found;
   unsigned char *s;

   if ( !in || !kind_of(( Handle) in, CImage)) WHINE("Not an image passed");

   if ( profile && pexist( edgeSize))
      edgeSize = pget_i( edgeSize);
   if ( edgeSize <= 0 || edgeSize > min( in-> w, in-> h)/2)
      WHINE( "bad edgeSize");
   if ( profile && pexist( backColor))
      backColor = pget_i( backColor);
   if ( profile && pexist( foreColor))
      foreColor = pget_i( foreColor);
   if ( profile && pexist( neighborhood))
      neighborhood = pget_i( neighborhood);
   if ( neighborhood != 8 && neighborhood != 4)
      WHINE( "cannot handle neighborhoods other than 4 and 8");

   lag = build_lag( in, (U8)foreColor, METHOD);
   find_lag_components( lag, edgeSize, neighborhood == 8);

   result = newAV();
   if (!result)
      WHINE( "error creating AV");

/*    Setting up direction index */
/*     3 2 1 */
/*     4 P 0 */
/*     5 6 7 */
   di[0] = 1;
   di[1] = -in-> lineSize + 1;
   di[2] = -in-> lineSize;
   di[3] = -in-> lineSize - 1;
   di[4] = -1;
   di[5] = in-> lineSize - 1;
   di[6] = in-> lineSize;
   di[7] = in-> lineSize + 1;

   /* Setting up x index & y index */
   xi[0] =  1;    yi[0] = 0;
   xi[1] =  1;    yi[1] = -1;
   xi[2] =  0;    yi[2] = -1;
   xi[3] = -1;    yi[3] = -1;
   xi[4] = -1;    yi[4] = 0;
   xi[5] = -1;    yi[5] = 1;
   xi[6] =  0;    yi[6] = 1;
   xi[7] =  1;    yi[7] = 1;

   for ( i = lcNormal; i < lag-> maxComponentCode; i++)
   {
      if (!(line = lag-> codedLines[ i]))
	 continue;
      contour = newAV();
      if (!contour)
	 WHINE( "error creating AV");

      y = y0 = line-> y;
      x = x0 = line-> beg;
      first = true;
      d = 6; /* initial direction */

      /* contour tracing */
      while ( x != x0 || y != y0 || first) {
	 s = in-> data + in-> lineSize*y + x;
	 av_push( contour, newSViv( x));
	 av_push( contour, newSViv( y));
         if (x <= 0) croak("assertion x > 0 failed");
         if (y <= 0) croak("assertion y > 0 failed");
         if (x >= in->w-1) croak("assertion x < w-1 failed");
         if (y >= in->h-1) croak("assertion y < h-1 failed");
	 for ( found = false, times = 3; (!found) && ( times > 0); times--) {
	    if (s[di[(d-1)&0x07]] == foreColor) {
	       x += xi[(d-1)&0x07];
	       y += yi[(d-1)&0x07];
	       d = (d - 2) & 0x07;
	       found = true;
	    } else if (s[di[d]] == foreColor) {
	       x += xi[d];
	       y += yi[d];
	       found = true;
	    } else if (s[di[(d+1)&0x07]] == foreColor) {
	       x += xi[(d+1)&0x07];
	       y += yi[(d+1)&0x07];
	       found = true;
	    } else
	       d = (d + 2) & 0x07;
	 }
         /* if (!found) croak("\nNOTFOUND\n"); */
	 first = false;
      }
      av_push( contour, newSViv( x));
      av_push( contour, newSViv( y));
      av_push( result, newRV_noinc((SV*)contour));
   }
   free_lag( lag);
   return newRV_noinc((SV*)result);
}

#undef METHOD
#define METHOD "IPA::Global::identify_scanlines"

SV*
/* [[x1,x2,y,...]],[x1,x2,y...]] */
IPA__Global_identify_scanlines( PImage in, HV *profile)
{
   dPROFILE;
   PLAG lag;
   PLAGLine line;
   int i;
   AV *result;
   AV *contour;

   int edgeSize = 1;
   int foreColor = 255;
   int neighborhood = 8;

   if ( !in || !kind_of(( Handle) in, CImage)) WHINE("Not an image passed");

   if ( profile && pexist( edgeSize))
      edgeSize = pget_i( edgeSize);
   if ( edgeSize <= 0 || edgeSize > min( in-> w, in-> h)/2)
      WHINE( "bad edgeSize");
   if ( profile && pexist( foreColor))
      foreColor = pget_i( foreColor);
   if ( profile && pexist( neighborhood))
      neighborhood = pget_i( neighborhood);
   if ( neighborhood != 8 && neighborhood != 4)
      WHINE( "cannot handle neighborhoods other than 4 and 8");

   lag = build_lag( in, (U8)foreColor, METHOD);
   find_lag_components( lag, edgeSize, neighborhood == 8);

   result = newAV();
   if (!result)
      WHINE( "error creating AV");

   for ( i = lcNormal; i < lag-> maxComponentCode; i++) {
      if ( !( line = lag-> codedLines[ i])) continue;
      if ( !( contour = newAV()))
	  WHINE( "error creating AV");
       while ( line) {
	  av_push( contour, newSViv( line-> beg));
	  av_push( contour, newSViv( line-> end));
	  av_push( contour, newSViv( line-> y));
	  line = line-> next;
       }
       av_push( result, newRV_noinc((SV*)contour));
   }
   free_lag( lag);
   return newRV_noinc((SV*)result);
}

#undef METHOD
#define METHOD "IPA::Global::identify_pixels"

SV*
/* [x,y,x,y] */
IPA__Global_identify_pixels( PImage in, HV *profile)
{
   dPROFILE;
   AV *result;

   Byte match = 0x0, eq = 0;
   Byte * src;
   int x, y; 

   if ( !in || !kind_of(( Handle) in, CImage)) WHINE("Not an image passed");
   if (( in->type & imBPP) != 8) WHINE("Not an 8-bit image image passed");

   if ( pexist( match)) match = (Byte) pget_i(match);
   if ( pexist( eq  ))  eq    = pget_B(eq);
   
   result = newAV();
   if (!result)
      WHINE( "error creating AV");

   for ( y = 0, src = in-> data; y < in-> h; y++, src += in-> lineSize) {
      for ( x = 0; x < in-> w; x++) {
         if ( eq ) {
             if (src[x] != match ) continue;
	 } else {
             if (src[x] == match ) continue;
	 }
         av_push( result, newSViv(x));
         av_push( result, newSViv(y));
      }
   }

   return newRV_noinc((SV*)result);
}   
