/*

   fft.c - Global operators.
   Fourier transform and Butterworth band filter routines.

   created by Dmitry Karasik <dk@plab.ku.dk>
   routines fft_2d, fft_1d and butter are modified code from KUIM sources

   
No place for beginners or sensitive hearts
When sentiment is left to chance
No place to be ending but somewhere to start 
No need to ask
He's a smooth operator
                /Sade
*/   

#include "IPAsupp.h"
#include "Global.h"
#include <math.h>
#include <stdio.h>

/* Confusing bu true */
#define FFT_DIRECT  -1
#define FFT_INVERSE 1

/*
   Frequency domain functions
*/   

#undef METHOD
#define fail(err)       {failed=true;warn("%s: err",METHOD); goto EXIT;}   


static void fft_2d(double * data, int nn, int mm, int isign, double * buffer);

static Bool pow2( int k) 
{
   int i = 1, j = k;
   while (j > 1) {
      i = i << 1;
      j = j >> 1;
   }
   return i == k;
}   

/*
   FFT
   profile keys: inverse => BOOL; direct or inverse transform
*/
PImage 
IPA__Global_fft(PImage img,HV *profile)
{ 
#define METHOD "IPA::Global::fft"
   dPROFILE;
   Bool inverse = 0, failed = false;
   PImage ret = nil;
   double * buffer = nil;

   if ( sizeof(double) % 2) {
      warn("%s:'double' is even-sized on this platform", METHOD);
      return nil;      
   }   
      
   if ( !img || !kind_of(( Handle) img, CImage))
       croak("%s: not an image passed", METHOD);
   if ( !pow2( img-> w))
      croak("%s: image width is not a power of 2", METHOD);
   if ( !pow2( img-> h))
      croak("%s: image height is not a power of 2", METHOD);
   
   if ( pexist( inverse)) inverse = pget_i( inverse);
   
   /* preparing structures */ 
   ret = ( PImage) img-> self-> dup(( Handle) img);
   if ( !ret) fail( "%s: Return image allocation failed");
   ++SvREFCNT( SvRV( ret-> mate));
   ret-> self-> set_type(( Handle) ret, imDComplex); 
   if ( ret-> type != imDComplex) {
      warn("%s:Cannot set image to imDComplex", METHOD);
      failed = 1;
      goto EXIT;
   }   
  
   buffer = malloc((sizeof(double) * img-> w * 2));
   if ( !buffer) {
      warn("%s: Error allocating %d bytes", METHOD, (int)(sizeof(double) * img-> w * 2));
      failed = 1;
      goto EXIT;
   }   

   fft_2d(( double *) ret-> data, ret-> w, ret-> h, inverse ? FFT_INVERSE : FFT_DIRECT, buffer);
EXIT:  
   free( buffer); 
   if ( ret)
      --SvREFCNT( SvRV( ret-> mate));           
   return failed ? nil : ret;
#undef METHOD   
}   

#define SWAP(a,b) tempr=(a); (a)=(b); (b)=tempr
#define TWOPI (2*3.14159265358979323846264338327950288419716939937510)
/*---------------------------------------------------------------------------*/
/* Purpose:  This routine replaces DATA by its one-dimensional discrete      */
/*           transform if ISIGN=1 or replaces DATA by its inverse transform  */
/*           if ISIGN=-1.  DATA is a complex array of length NN which is     */
/*           input as a real array of length 2*NN.  No error checking is     */
/*           performed                                                       */
/*                                                                           */
/* Note:     Because this code was adapted from a FORTRAN library, the       */
/*           data array is 1-indexed.  In other words, the first element     */
/*           of the array is assumed to be in data[1].  Because C is zero    */
/*           indexed, the first element of the array is in data[0].  Hence,  */
/*           we must subtract 1 from the data address at the start of this   */
/*           routine so references to data[1] will really access data[0].    */
/*---------------------------------------------------------------------------*/

static void fft_1d(double *data, int nn, int isign)
{
   int n, mmax, m, j, istep, i;
   double wtemp, wr, wi, wpr, wpi, theta, tempr, tempi;

   /* Fix indexing problems (see above) */
   data = data - 1;

   /* Bit reversal section */
   n = nn << 1;
   j = 1;
   for (i = 1; i < n; i += 2)
   {
      if (j > i)
      {
	 SWAP(data[j], data[i]);
	 SWAP(data[j + 1], data[i + 1]);
      }
      m = n >> 1;
      while (m >= 2 && j > m)
      {
	 j -= m;
	 m = m >> 1;
      }
      j += m;
   }

   /* Danielson-Lanczos section */
   mmax = 2;
   while (n > mmax)
   {
      istep = 2 * mmax;
      theta = TWOPI / (isign * mmax);
      wtemp = sin(0.5 * theta);
      wpr = -2.0 * wtemp * wtemp;
      wpi = sin(theta);
      wr = 1.0;
      wi = 0.0;
      for (m = 1; m < mmax; m += 2)
      {
	 for (i = m; i <= n; i += istep)
	 {
	    j = i + mmax;
	    tempr = (double)(wr * data[j] - wi * data[j + 1]);
	    tempi = (double)(wr * data[j + 1] + wi * data[j]);
	    data[j] = data[i] - tempr;
	    data[j + 1] = data[i + 1] - tempi;
	    data[i] += tempr;
	    data[i + 1] += tempi;
	 }
	 wtemp = wr;
	 wr += wr * wpr - wi * wpi;
	 wi += wi * wpr + wtemp * wpi;
      }
      mmax = istep;
   }

   /* Normalizing section */
   if (isign == 1)
   {
      n = nn << 1;
      for (i = 1; i <= n; i++)
	 data[i] = data[i] / nn;
   }
}

/*---------------------------------------------------------------------------*/
/* Purpose:  This routine replaces DATA by its two-dimensional discrete      */
/*           transform if ISIGN=1 or replaces DATA by its inverse transform  */
/*           if ISIGN=-1.  DATA is a complex array with NN columns and MM    */
/*           rows. No error checking is performed. copy must point at valid  */
/*           buffer mm * 2 * sizeof(double) bytes long.                      */
/*---------------------------------------------------------------------------*/
static void fft_2d(double * data, int nn, int mm, int isign, double * copy)
{
   int i, j, index1, index2;

   /* Transform by ROWS for forward transform */
   if (isign == 1)
   {
      index1 = 0;
      for (i = 0; i < mm; i++)
      {
         fft_1d(data+index1, nn, isign);
	 index1 += (nn << 1);
      }
   }
   
   /* Transform by COLUMNS */
   for (j = 0; j < nn; j++)
   {
      /* Copy pixels into temp array */
      index1 = (j << 1);
      index2 = 0;
      for (i = 0; i < mm; i++)
      {
	 copy[index2++] = data[index1];
	 copy[index2++] = data[index1 + 1];
	 index1 += (nn << 1);
      }

      /* Perform transform */
      fft_1d(copy, mm, isign);

      /* Copy pixels back into data array */
      index1 = (j << 1);
      index2 = 0;
      for (i = 0; i < mm; i++)
      {
	 data[index1] = copy[index2++];
	 data[index1 + 1] = copy[index2++];
	 index1 += (nn << 1);
      }
   }

   /* Transform by ROWS for inverse transform */
   if (isign == -1)
   {
      index1 = 0;
      for (i = 0; i < mm; i++)
      {
	 fft_1d(data+index1, nn, isign);
	 index1 += (nn << 1);
      }
   }
}

/*
   Butterworth filter, performs band filtering in the frequency domain.
   profile keys:
      spatial   => 1. Domain selector. if 1, fft is performed; 
                      if 0, accepts only imDComplex format.
      homomorph => 0. Preforms homomorph equalization; couldn't be 1 if spatial == 0.
      low       => 0. pass pointer
      boost, cutoff and power - controlling vars 
*/

static void butterworth( double * data, int Xdim, int Ydim, 
             int Homomorph, int LowPass,
             double Power, double CutOff, double Boost);


PImage 
IPA__Global_band_filter(PImage img,HV *profile)
{
#define METHOD "IPA::Global::band_filter"
   dPROFILE;
   PImage ret;
   int spatial = 1, homomorph = 0, lw, failed = 0, LowPass = 0;
   double MinVal = 0.0, Power = 2.0, CutOff = 20.0, Boost = 0.7;
   double * data, * buffer = nil;
   
   
   if ( sizeof(double) % 2) {
      warn("%s:'double' is even-sized on this platform", METHOD);
      return nil;      
   }   
   if ( !img || !kind_of(( Handle) img, CImage))
     croak("%s: not an image passed", METHOD);

   if ( pexist( spatial))  spatial = pget_i( spatial);
   if ( pexist( homomorph)) homomorph = pget_i( homomorph);
   if ( pexist( power))  Power = pget_f( power);
   if ( pexist( cutoff)) CutOff = pget_f( cutoff);
   if ( pexist( boost))  Boost = pget_f( boost);
   if ( pexist( low))    LowPass = pget_i( low);
   if ( homomorph && !spatial)
      croak("%s:Cannot perform the homomorph equalization in the spatial domain", METHOD);
   if ( LowPass && ( CutOff < 0.0000001))
      croak("%s:cutoff is too small for low pass", METHOD);
   
   if ( !spatial && (( img-> type & imCategory) != imComplexNumber))
      croak("%s: not an im::DComplex image passed", METHOD); 
   
   ret = ( PImage) img-> self-> dup(( Handle) img);
   if ( !ret) fail( "%s: Return image allocation failed");
   ++SvREFCNT( SvRV( ret-> mate));
   if ( spatial) {
      ret-> self-> set_type(( Handle) ret, imDComplex);
      if ( ret-> type != imDComplex) {
          warn("%s: Cannot convert image to im::DComplex", METHOD);
          failed = 1;
          goto EXIT;
      }   
   }   

   data = ( double *) ret-> data;
   lw = ret-> w * 2;

   /* Take log of input image */
   if ( homomorph) {
      long i, k = ret-> w * ret-> h * 2;
      
      MinVal = *data;
      for ( i = 0; i < k; i += 2)
         if ( MinVal > data[i])
            MinVal = data[i];
      for ( i = 0; i < k; i += 2)
         data[i] = ( double) log(( double) ( 1.0 + data[i] - MinVal));
   }

   /* fft */
   if ( spatial) {
      if ( !pow2( img-> w))
         croak("%s: image width is not a power of 2", METHOD);
      if ( !pow2( img-> h))
         croak("%s: image height is not a power of 2", METHOD);
      buffer = malloc((sizeof(double) * ret-> w * 2));
      if ( !buffer) {
         warn("%s: Error allocating %d bytes", METHOD, (int)(sizeof(double) * img-> w * 2));
         failed = 1;
         goto EXIT;
      }   
      fft_2d( data, ret-> w, ret-> h, FFT_DIRECT, buffer);
   }   

   butterworth( data, ret-> w, ret-> h, homomorph, LowPass, Power, CutOff, Boost);

   /* inverse fft */
   if ( spatial) {
      fft_2d( data, ret-> w, ret-> h, FFT_INVERSE, buffer);
      free( buffer);
      buffer = nil;
   }   
   
   /* Take exp of input image */
   if ( homomorph) {
      long i, k = ret-> w * ret-> h * 2;
      for ( i = 0; i < k; i += 2)
         data[i] = ( double) ( exp( data[i]) - 1.0 + MinVal);
   }  

   /* converting type back */
   if ( spatial && ret-> self-> get_preserveType(( Handle) ret))
      ret-> self-> set_type(( Handle) ret, img-> type);
   
EXIT:   
   free( buffer);
   if ( ret)
      --SvREFCNT( SvRV( ret-> mate));           
   return failed ? nil : ret;
#undef METHOD   
}  


void butterworth( double * data, int Xdim, int Ydim, 
             int Homomorph, int LowPass,
             double Power, double CutOff, double Boost)
{
   int x, y, x1, y1, halfx, halfy;
   double Filter;
   double CutOff2 = CutOff * CutOff;
   
   /* Prepare to filter */
   halfx = Xdim / 2;
   halfy = Ydim / 2;

   /* Loop over Y axis */
   for (y = 0; y < Ydim; y++)
   {
      if (y < halfy)
	 y1 = y;
      else
	 y1 = y - Ydim;

      /* Loop over X axis */
      for (x = 0; x < Xdim; x++)
      {
	 if (x < halfx)
	    x1 = x;
	 else
	    x1 = x - Xdim;

	 /* Calculate value of Butterworth filter */
	 if (LowPass)
	    Filter = (float) (1 / (1 + pow((x1 * x1 + y1 * y1) /
					   CutOff2, Power)));
	 else if ((x1 != 0) || (y1 != 0))
	    Filter = (float) (1 / (1 + pow( CutOff2 /
					   (x1 * x1 + y1 * y1), Power)));
	 else
	    Filter = (float) 0.0;
	 if (Homomorph)
	    Filter = Boost + (1 - Boost) * Filter;

	 /* Do pointwise multiplication */
         *(data++) *= Filter;
         *(data++) *= Filter;
      }
   }
}

