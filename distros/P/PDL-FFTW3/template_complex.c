// This is the template used by PP to generate the FFTW routines.
// FFTW3.pd includes this file

#ifndef __TEMPLATE_ALREADY_INCLUDED__

/* the Linux kernel does something similar to assert at compile time */
#define static_assert(x) (void)( sizeof( int[ 1 - 2* !(x) ]) )

#define __TEMPLATE_ALREADY_INCLUDED__
#endif


{
  // make sure the PDL data type I'm using matches the FFTW data type
  static_assert( sizeof($GENERIC())*2 == sizeof($TFD(fftwf_,fftw_)complex) );

  $TFD(fftwf_,fftw_)plan plan = INT2PTR( $TFD(fftwf_,fftw_)plan, $COMP(plan));
  $TFD(fftwf_,fftw_)execute_dft( plan,
                                 ($TFD(fftwf_,fftw_)complex*)$P(in),
                                 ($TFD(fftwf_,fftw_)complex*)$P(out) );
}

