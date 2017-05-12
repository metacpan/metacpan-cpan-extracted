// This is the template used by PP to generate the FFTW routines.
// FFTW3.pd includes this file

// This is passed into pp_def() in the 'Code' key. Before this file is passed to
// pp_def, the following strings are replaced:
//
// INVERSE      If this is a c2r transform rather than r2c
// RANK         The rank of this transform

#ifndef __TEMPLATE_ALREADY_INCLUDED__

/* the Linux kernel does something similar to assert at compile time */
#define static_assert(x) (void)( sizeof( int[ 1 - 2* !(x) ]) )

#define __TEMPLATE_ALREADY_INCLUDED__
#endif


{
  // make sure the PDL data type I'm using matches the FFTW data type
  static_assert( sizeof($GENERIC())*2 == sizeof($TFD(fftwf_,fftw_)complex) );

  $TFD(fftwf_,fftw_)plan plan = INT2PTR( $TFD(fftwf_,fftw_)plan, $COMP(plan));

  if( !INVERSE )
    $TFD(fftwf_,fftw_)execute_dft_r2c( plan,
                                       ($TFD(float,double)*)$P(real),
                                       ($TFD(fftwf_,fftw_)complex*)$P(complex) );
  else
  {
    // FFTW inverse real transforms clobber their input. I thus make a new
    // buffer and transform from there
    unsigned long nelem = 1;
    for( int i=0; i<=RANK; i++ )
      nelem *= $PDL(complex)->dims[i];
    $GENERIC()* input_copy = $TFD(fftwf_,fftw_)alloc_real( nelem );
    memcpy( input_copy, $P(complex), sizeof($GENERIC()) * nelem );

    $TFD(fftwf_,fftw_)execute_dft_c2r( plan,
                                       ($TFD(fftwf_,fftw_)complex*)input_copy,
                                       ($TFD(float,double)*)$P(real) );

    $TFD(fftwf_,fftw_)free( input_copy );
  }
}
