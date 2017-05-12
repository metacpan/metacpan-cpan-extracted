MODULE = PDL::FFTW3 PACKAGE = PDL::FFTW3

IV
compute_plan( dims_ref, do_double_precision, is_real_fft, do_inverse_fft, in_pdl, out_pdl, in_alignment, out_alignment )
  SV*  dims_ref
  bool do_double_precision
  bool is_real_fft
  bool do_inverse_fft
  pdl* in_pdl
  pdl* out_pdl
  int  in_alignment
  int  out_alignment
CODE:
{
  // Given input and output matrices, this function computes the FFTW plan

  // PDL stores its data in the opposite dimension order from what FFTW wants. I
  // handle this by passing in the dimension counts backwards.
  AV* dims_av = (AV*)SvRV(dims_ref);
  int rank = av_len(dims_av) + 1;

  int dims_row_first[rank];
  for( int i=0; i<rank; i++)
    dims_row_first[i] = SvIV( *av_fetch( dims_av, rank-i-1, 0) );

  // I apply the requested mis-alignment. This comes from later thread slices
  UVTYPE in_data = PTR2UV(in_pdl->data);
  if( in_alignment < 16 )
    in_data |= in_alignment;

  UVTYPE out_data = PTR2UV(out_pdl->data);
  if( out_alignment < 16 )
    out_data |= out_alignment;

  void* plan;
  if( !is_real_fft )
  {
    int direction = do_inverse_fft ? FFTW_BACKWARD : FFTW_FORWARD;

    // complex-complex FFT. Input/output have identical dimensions
    if( !do_double_precision )
      plan =
        fftwf_plan_dft( rank, dims_row_first,
                        NUM2PTR(fftwf_complex*, in_data), NUM2PTR(fftwf_complex*, out_data),
                        direction, FFTW_ESTIMATE);
    else
      plan =
        fftw_plan_dft( rank, dims_row_first,
                       NUM2PTR(fftw_complex*, in_data), NUM2PTR(fftw_complex*, out_data),
                       direction, FFTW_ESTIMATE);
  }
  else
  {
    // real-complex FFT. Input/output have different dimensions
    if( !do_double_precision)
    {
      if( !do_inverse_fft )
        plan =
          fftwf_plan_dft_r2c( rank, dims_row_first,
                              NUM2PTR(float*, in_data), NUM2PTR(fftwf_complex*, out_data),
                              FFTW_ESTIMATE );
      else
        plan =
          fftwf_plan_dft_c2r( rank, dims_row_first,
                              NUM2PTR(fftwf_complex*, in_data), NUM2PTR(float*, out_data),
                              FFTW_ESTIMATE );
    }
    else
    {
      if( !do_inverse_fft )
        plan =
          fftw_plan_dft_r2c( rank, dims_row_first,
                             NUM2PTR(double*, in_data), NUM2PTR(fftw_complex*, out_data),
                             FFTW_ESTIMATE );
      else
        plan =
          fftw_plan_dft_c2r( rank, dims_row_first,
                             NUM2PTR(fftw_complex*, in_data), NUM2PTR(double*, out_data),
                             FFTW_ESTIMATE );
    }
  }

  if( plan == NULL )
    XSRETURN_UNDEF;
  else
    RETVAL = PTR2IV(plan);
}
OUTPUT:
 RETVAL



int
is_same_data( in, out )
  pdl* in
  pdl* out
CODE:
{
  RETVAL = (in->data == out->data) ? 1 : 0;
}
OUTPUT:
 RETVAL


#define _get_data_alignment_int( x )            \
 ( x %  16 == 0 ) ? 16 :                        \
 ( x %  8  == 0 ) ?  8 :                        \
 ( x %  4  == 0 ) ?  4 :                        \
 ( x %  2  == 0 ) ?  2 : 1;

int
get_data_alignment_int( x )
  UV x
CODE:
{
  RETVAL = _get_data_alignment_int( x );
}
OUTPUT:
 RETVAL


int
get_data_alignment_pdl( in )
  pdl* in
CODE:
{
  RETVAL = _get_data_alignment_int( PTR2UV(in->data) );
}
OUTPUT:
 RETVAL
