#include "xlib.h"

/*
 * the following functions were originally taken from sox-12.16/libst.c
 * license is unclear, but the header file contained this notice:
 */

/*
** Copyright (C) 1989 by Jef Poskanzer.
**
** Permission to use, copy, modify, and distribute this software and its
** documentation for any purpose and without fee is hereby granted, provided
** that the above copyright notice appear in all copies and that both that
** copyright notice and this permission notice appear in supporting
** documentation.  This software is provided "as is" without express or
** implied warranty.
*/

/*
** This routine converts from linear to ulaw.
**
** Craig Reese: IDA/Supercomputing Research Center
** Joe Campbell: Department of Defense
** 29 September 1989
**
** References:
** 1) CCITT Recommendation G.711  (very difficult to follow)
** 2) "A New Digital Technique for Implementation of Any
**     Continuous PCM Companding Law," Villeret, Michel,
**     et al. 1973 IEEE Int. Conf. on Communications, Vol 1,
**     1973, pg. 11.12-11.17
** 3) MIL-STD-188-113,"Interoperability and Performance Standards
**     for Analog-to_Digital Conversion Techniques,"
**     17 February 1987
**
** Input: Signed 16 bit linear sample
** Output: 8 bit ulaw sample
*/

#undef ZEROTRAP      /* turn off the trap as per the MIL-STD */
#define uBIAS 0x84   /* define the add-in bias for 16 bit samples */
#define uCLIP 32635
#define ACLIP 31744

unsigned char
st_linear_to_ulaw(int sample)
    {
    static int exp_lut[256] = {0,0,1,1,2,2,2,2,3,3,3,3,3,3,3,3,
                               4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,
                               5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
                               5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
                               6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
                               6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
                               6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
                               6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7};
    int sign, exponent, mantissa;
    unsigned char ulawbyte;

    /* Get the sample into sign-magnitude. */
    sign = (sample >> 8) & 0x80;		/* set aside the sign */
    if ( sign != 0 ) sample = -sample;		/* get magnitude */
    if ( sample > uCLIP ) sample = uCLIP;		/* clip the magnitude */

    /* Convert from 16 bit linear to ulaw. */
    sample = sample + uBIAS;
    exponent = exp_lut[( sample >> 7 ) & 0xFF];
    mantissa = ( sample >> ( exponent + 3 ) ) & 0x0F;
    ulawbyte = ~ ( sign | ( exponent << 4 ) | mantissa );
#ifdef ZEROTRAP
    if ( ulawbyte == 0 ) ulawbyte = 0x02;	/* optional CCITT trap */
#endif

    return ulawbyte;
    }

/*
** This routine converts from ulaw to 16 bit linear.
**
** Craig Reese: IDA/Supercomputing Research Center
** 29 September 1989
**
** References:
** 1) CCITT Recommendation G.711  (very difficult to follow)
** 2) MIL-STD-188-113,"Interoperability and Performance Standards
**     for Analog-to_Digital Conversion Techniques,"
**     17 February 1987
**
** Input: 8 bit ulaw sample
** Output: signed 16 bit linear sample
*/

int
st_ulaw_to_linear(unsigned char ulawbyte)
    {
    static int exp_lut[8] = { 0, 132, 396, 924, 1980, 4092, 8316, 16764 };
    int sign, exponent, mantissa, sample;

    ulawbyte = ~ ulawbyte;
    sign = ( ulawbyte & 0x80 );
    exponent = ( ulawbyte >> 4 ) & 0x07;
    mantissa = ulawbyte & 0x0F;
    sample = exp_lut[exponent] + ( mantissa << ( exponent + 3 ) );
    if ( sign != 0 ) sample = -sample;

    return sample;
    }

/*
 * A-law routines by Graeme W. Gill.
 * Date: 93/5/7
 *
 * References:
 * 1) CCITT Recommendation G.711
 *
 * These routines were used to create the fast
 * lookup tables.
 */

#define ACLIP 31744

unsigned char
st_linear_to_Alaw(int sample)
    {
    static int exp_lut[128] = {1,1,2,2,3,3,3,3,
                               4,4,4,4,4,4,4,4,
                               5,5,5,5,5,5,5,5,
                               5,5,5,5,5,5,5,5,
                               6,6,6,6,6,6,6,6,
                               6,6,6,6,6,6,6,6,
                               6,6,6,6,6,6,6,6,
                               6,6,6,6,6,6,6,6,
                               7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7,
                               7,7,7,7,7,7,7,7};

    int sign, exponent, mantissa;
    unsigned char Alawbyte;

    /* Get the sample into sign-magnitude. */
    sign = ((~sample) >> 8) & 0x80;		/* set aside the sign */
    if ( sign == 0 ) sample = -sample;		/* get magnitude */
    if ( sample > ACLIP ) sample = ACLIP;	/* clip the magnitude */

    /* Convert from 16 bit linear to ulaw. */
    if (sample >= 256)
	{
	exponent = exp_lut[( sample >> 8 ) & 0x7F];
	mantissa = ( sample >> ( exponent + 3 ) ) & 0x0F;
	Alawbyte = (( exponent << 4 ) | mantissa);
	}
    else
	Alawbyte = (sample >> 4);
    Alawbyte ^= (sign ^ 0x55);

    return Alawbyte;
    }

int
st_Alaw_to_linear(unsigned char Alawbyte)
    {
    static int exp_lut[8] = { 0, 264, 528, 1056, 2112, 4224, 8448, 16896 };
    int sign, exponent, mantissa, sample;

    Alawbyte ^= 0x55;
    sign = ( Alawbyte & 0x80 );
    Alawbyte &= 0x7f;			/* get magnitude */
    if (Alawbyte >= 16)
	{
	exponent = (Alawbyte >> 4 ) & 0x07;
	mantissa = Alawbyte & 0x0F;
	sample = exp_lut[exponent] + ( mantissa << ( exponent + 3 ) );
	}
    else
	sample = (Alawbyte << 4) + 8;
    if ( sign == 0 ) sample = -sample;

    return sample;
    }

/* adapted from clm.c, by Bill Schottstaedt C<bil@ccrma.stanford.edu> */

#define SRC_SINC_DENSITY 1000
#define SRC_SINC_WIDTH 10

static Float **sinc_tables = 0;
static int *sinc_widths = 0;
static int sincs = 0;

static Float *
init_sinc_table (int width)
{
  int i, size, loc;
  Float sinc_freq, win_freq, sinc_phase, win_phase;
  for (i = 0; i < sincs; i++)
    if (sinc_widths[i] == width)
      return (sinc_tables[i]);

  if (sincs == 0)
    {
      sinc_tables = (Float **) calloc (8, sizeof (Float *));
      sinc_widths = (int *) calloc (8, sizeof (int));
      sincs = 8;
      loc = 0;
    }
  else
    {
      loc = -1;
      for (i = 0; i < sincs; i++)
	if (sinc_widths[i] == 0)
	  {
	    loc = i;
	    break;
	  }

      if (loc == -1)
	{
	  sinc_tables = (Float **) realloc (sinc_tables, (sincs + 8) * sizeof (Float *));
	  sinc_widths = (int *) realloc (sinc_widths, (sincs + 8) * sizeof (int));
	  for (i = sincs; i < (sincs + 8); i++)
	    {
	      sinc_widths[i] = 0;
	      sinc_tables[i] = NULL;
	    }

	  loc = sincs;
	  sincs += 8;
	}
    }
  sinc_tables[loc] = (Float *) calloc (width * SRC_SINC_DENSITY + 1, sizeof (Float));
  sinc_widths[loc] = width;
  size = width * SRC_SINC_DENSITY;
  sinc_freq = M_PI / (Float) SRC_SINC_DENSITY;
  win_freq = M_PI / (Float) size;
  sinc_tables[loc][0] = 1.0;

  for (i = 1, sinc_phase = sinc_freq, win_phase = win_freq; i < size; i++, sinc_phase += sinc_freq, win_phase += win_freq)
    sinc_tables[loc][i] = sin (sinc_phase) * (0.5 + 0.5 * cos (win_phase)) / sinc_phase;

  return (sinc_tables[loc]);
}

void
mus_src (Float *input, int inpsize, Float *output, int outsize, Float srate, Float *sr_mod, int width)
{
  int i, lim, len, fsx, k, loc;

  Float x, xx, factor, *data, *sinc_table, sum, zf, srx, incr;

  Float *in0 = input;
  Float *in1 = input + inpsize;
  Float *out1 = output + outsize;

  if (width == 0)
    width = SRC_SINC_WIDTH;

  x = 0.0;
  lim = 2 * width;
  len = width * SRC_SINC_DENSITY;
  data = (Float *) calloc (lim + 1, sizeof (Float));
  sinc_table = init_sinc_table (width);

  for (i = width; i < lim; i++) data[i] = *input++;

  while (output < out1)
    {
      fsx = (int)x;
      if (fsx > 0)
	{
	  /* realign data, reset x */
	  for (i = fsx, loc = 0; i < lim; i++, loc++)
	    data[loc] = data[i];

	  for (i = loc; i < lim; i++)
	    {
	      if (srx < 0)
                input = (input > in0 ? input : in1) - 1;
	      else
                input = input < in1 ? input+1 : in0;

	      data[i] = *input;
	    }

	  x -= fsx;
	}

      srx = srate + (sr_mod ? *sr_mod++ : 0);
      srx = srx ? fabs (srx) : 0.001;
      factor = srx > 1 ? 1 / srx : 1;

      sum = 0.0;
      zf = factor * SRC_SINC_DENSITY;
      xx = zf * (1.0 - x - width);
      for (i = 0; i < lim; i++)
	{
	  /* we're moving backwards in the data array, so xx has to mimic that (hence the '1.0 - x') */
          k = abs ((int)xx);

	  if (k < len)
	    sum += data[i] * sinc_table[k];

          xx += zf;
	}

      x += srx;
      *output++ = sum * factor;
    }

  free (data);
}

static unsigned long randx = 1;

static int 
irandom (int amp)
{
  int val;

  randx = randx * 1103515245 + 12345;
  val = (unsigned int) (randx >> 16) & 0x7fff;
  return ((int) (amp * (((Float) val / 32768))));
}

#define max(a,b) ((a)>(b) ? (a) : (b))
#define min(a,b) ((a)<(b) ? (a) : (b))

void
mus_granulate (Float *input, int insize,
	       Float *output, int outsize,
	       Float expansion, Float flength, Float scaler,
	       Float hop, Float ramp, Float jitter, int max_size)
/* hop, jitter, length (*= smapling_rate) */
{
  int length = (int)ceil (flength);
  int rmp = (int) (ramp * length);
  int output_hop = (int)hop;
  int input_hop = (int)(output_hop / expansion);
  int s20 = (int) (jitter / 20);
  int s50 = (int) (jitter / 50);
  int outlen = max_size > 0 ? min ((int)(hop + flength), max_size)  : (int)(hop + flength);
  int in_data_len = outlen + s20 + 1;
  int in_data_start = in_data_len;
  Float *data = (Float *) calloc (outlen, sizeof (Float));
  Float *in_data = (Float *) calloc (in_data_len, sizeof (Float));

  Float *in1  = input  + insize;
  Float *out1 = output + outsize;

  int ctr = 0;
  Float cur_out = 0;

  int start, len, end, i, j, k;
  int  steady_end, curstart;
  Float incr, result, amp;

  if (s50 > output_hop)
    s50 = output_hop;

  for(;;)
    {
      while (ctr < cur_out)
        {
          *output++ = data[ctr++];
          if (output >= out1)
            goto ok;
        }

      start = cur_out;
      end = length - start;
      
      if (end <= 0)
        end = 0;
      else
        for (i = 0, j = start; i < end; i++, j++)
          data[i] = data[j];

      for (i = end; i < outlen; i++)
        data[i] = 0;

      start = in_data_start;
      len = in_data_len;

      if (start > len)
        {
          input += start - len;
          input = input < in1 ? input : in1;
          start = len;
        }
      else if (start < len)
        for (i = 0, k = start; k < len; i++, k++)
          in_data[i] = in_data[k];

      for (i = len - start; i < len; i++)
        {
          in_data[i] = *input;
          input = input < in1 ? input+1 : input;
        }

      in_data_start = input_hop;

      amp = 0.0;
      incr = scaler / (Float) rmp;
      steady_end = length - rmp;
      curstart = irandom (s20);

      for (i = 0, j = curstart; i < length; i++, j++)
        {
          data[i] += (amp * in_data[j]);

          if (i < rmp)
            amp += incr;
          else if (i > steady_end)
            amp -= incr;
        }

      ctr -= cur_out;
      cur_out = output_hop + irandom (s50) - (s50 >> 1);
    }

  ok:
  free (data);
  free (in_data);
}

static void
mus_shuffle (Float* rl, Float* im, int n)
{
  /* bit reversal */

  int i,m,j;
  Float tempr,tempi;
  j=0;
  for (i=0;i<n;i++)
    {
      if (j>i)
	{
	  tempr = rl[j];
	  tempi = im[j];
	  rl[j] = rl[i];
	  im[j] = im[i];
	  rl[i] = tempr;
	  im[i] = tempi;
	}
      m = n>>1;
      while ((m>=2) && (j>=m))
	{
	  j -= m;
	  m = m>>1;
	}
      j += m;
    }
}

static void
mus_fft (Float *rl, Float *im, int n, int isign)
{
  /* standard fft: real part in rl, imaginary in im,        */
  /* rl and im are zero-based.                              */
  int mmax,j,pow,prev,lg,i,ii,jj,ipow;
  Float wrs,wis,tempr,tempi;
  double wr,wi,theta,wtemp,wpr,wpi;
  ipow = (int)(ceil(log(n)/log(2.0)));
  mus_shuffle(rl,im,n);
  mmax = 2;
  prev = 1;
  pow = (int)(n*0.5);
  theta = (M_PI*isign);
  for (lg=0;lg<ipow;lg++)
    {
      wpr = cos(theta);
      wpi = sin(theta);
      wr = 1.0;
      wi = 0.0;
      for (ii=0;ii<prev;ii++)
	{
	  wrs = (Float) wr;
	  wis = (Float) wi;
#ifdef LINUX 
	  if (isnan(wis)) wis=0.0;
#endif
	  i = ii;
	  j = ii + prev;
	  for (jj=0;jj<pow;jj++)
	    {
	      tempr = wrs*rl[j] - wis*im[j];
	      tempi = wrs*im[j] + wis*rl[j];
	      rl[j] = rl[i] - tempr;
	      im[j] = im[i] - tempi;
	      rl[i] += tempr;
	      im[i] += tempi;
	      i += mmax;
	      j += mmax;
	    }
	  wtemp = wr;
	  wr = (wr*wpr) - (wi*wpi);
	  wi = (wi*wpr) + (wtemp*wpi);
	}
      pow = (int)(pow*0.5);
      prev = mmax;
      theta = theta*0.5;
      mmax = mmax*2;
    }
}

static void
mus_convolution (Float* rl1, Float* rl2, int n)
{
  /* convolves two real arrays.                                           */
  /* rl1 and rl2 are assumed to be set up correctly for the convolution   */
  /* (that is, rl1 (the "signal") is zero-padded by length of             */
  /* (non-zero part of) rl2 and rl2 is stored in wrap-around order)       */
  /* We treat rl2 as the imaginary part of the first fft, then do         */
  /* the split, scaling, and (complex) spectral multiply in one step.     */
  /* result in rl1                                                        */

  int j,n2,nn2;
  Float rem,rep,aim,aip,invn;

  mus_fft(rl1,rl2,n,1);
  
  n2=(int)(n*0.5);
  invn = 0.25/n;
  rl1[0] = ((rl1[0]*rl2[0])/n);
  rl2[0] = 0.0;

  for (j=1;j<=n2;j++)
    {
      nn2 = n-j;
      rep = (rl1[j]+rl1[nn2]);
      rem = (rl1[j]-rl1[nn2]);
      aip = (rl2[j]+rl2[nn2]);
      aim = (rl2[j]-rl2[nn2]);

      rl1[j] = invn*(rep*aip + aim*rem);
      rl1[nn2] = rl1[j];
      rl2[j] = invn*(aim*aip - rep*rem);
      rl2[nn2] = -rl2[j];
    }
  
  mus_fft(rl1,rl2,n,-1);
}

void
mus_convolve (Float * input, Float * output, int size, Float * filter, int fftsize, int filtersize)
{
  int fftsize2 = fftsize >> 1;
  Float *rl1, *rl2, *buf;
  Float *in1 = input + size;
  int ctr = fftsize2;
  int i, j;

  rl1 = (Float *) calloc (fftsize, sizeof (Float));
  rl2 = (Float *) calloc (fftsize, sizeof (Float));
  buf = (Float *) calloc (fftsize, sizeof (Float));

  while (size > 0)
    {
      ctr++;
      if (ctr >= fftsize2)
	{
	  for (i = 0, j = fftsize2; i < fftsize2; i++, j++)
	    {
	      buf[i] = buf[j];
	      buf[j] = 0.0;
	      rl1[i] = *input;
	      rl1[j] = 0.0;
	      rl2[i] = 0.0;
	      rl2[j] = 0.0;

	      input = input < in1 ? input+1 : input;
	    }

	  for (i = 0; i < filtersize; i++)
	    rl2[i] = filter[i];

	  mus_convolution (rl1, rl2, fftsize);

	  for (i = 0, j = fftsize2; i < fftsize2; i++, j++)
	    {
	      buf[i] += rl1[i];
	      buf[j] = rl1[j];
	    }

	  ctr = 0;
	}

      *output++ = buf[ctr];
      size--;
    }
}
