# This file is included by FFTW3.pd


use PDL::Types;
use List::Util 'reduce';

# when I compute an FFTW plan, it goes here
my %existingPlans;

# these are for the unit tests
our $_Nplans = 0;
our $_last_do_double_precision;

# This file is included verbatim into the final module via pp_addpm()

# This is a function that sits between the user's call into this module and the
# PP-generated internals. Specifically, this function is called BEFORE any PDL
# threading happens. Here I make sure the FFTW plan exists, or if it doesn't, I
# make it. Thus the PP-based internals can safely assume that the plan exists
sub __fft_internal
{
  my $thisfunction = shift;

  my ($do_inverse_fft, $is_real_fft, $rank) = $thisfunction =~ /^(i?)((?:r)?).*fft([0-9]+)/;

  # first I parse the variables. This is a very direct translation of what PP
  # does normally. Plan-creation has to be outside of PP, so I must re-do this
  # here
  my $Nargs = scalar @_;

  my ($in, $out);
  if( $Nargs == 2 )
  {
    # all variables on stack, read in output and temp vars
    ($in, $out) = map {defined $_ ? PDL::Core::topdl($_) : $_} @_;
  }
  elsif( $Nargs == 1 )
  {
    $in = PDL::Core::topdl $_[0];
    if( $in->is_inplace )
    {
      barf <<EOF if $is_real_fft;
$thisfunction: in-place real FFTs are not supported since the input/output types and data sizes differ.
Giving up.
EOF

      $out = $in;
      $in->set_inplace(0);
    }
    else
    {
      $out = PDL::null();
    }
  }
  else
  {
    barf( <<EOF );
$thisfunction must be given the input or the input and output as args.
Exactly 1 or 2 arguments are required. Instead I got $Nargs args. Giving up.
EOF
  }

  # make sure the in/out types match. Convert $in if needed. This needs to
  # happen before we instantiante $out (if it's null) to make sure we know the
  # type
  processTypes( $thisfunction, \$in, \$out );

  # I now create a piddle for the null output. Normally PP does this, but I need
  # to have the piddle made to create plans. If I don't, the alignment may
  # differ between plan-time and run-time
  if( $out->isnull )
  {
    my @dims = getOutDims($in, $is_real_fft, $do_inverse_fft);
    $out .= zeros($in->type, @dims);
  }

  validateArguments( $rank, $is_real_fft, $do_inverse_fft, $thisfunction, $in, $out );

  # I need to physical-ize the piddles before I make a plan. Again, normally PP
  # does this, but to make sure alignments match, I need to do this myself, now
  $in ->make_physical;
  $out->make_physical;

  my $plan = getPlan( $thisfunction, $rank, $is_real_fft, $do_inverse_fft, $in, $out );
  barf "$thisfunction couldn't make a plan. Giving up\n" unless defined $plan;

  # I now have the arguments and the plan. Go!
  my $internal_function =
    $is_real_fft ?
    ( $do_inverse_fft ? "PDL::__irfft$rank" : "PDL::__rfft$rank") : "PDL::__fft$rank";
  eval( $internal_function . '( $in, $out, $plan );' );
  barf "$thisfunction: eval failed calling the internal FFT routine: $@" if $@;

  return $out;





  sub getOutDims
  {
    my ($in, $is_real_fft, $do_inverse_fft) = @_;

    my @dims = $in->dims;

    if ( !$is_real_fft )
    {
      # complex fft. Output is the same size as the input.
    }
    elsif ( !$do_inverse_fft )
    {
      # forward real fft
      my $d0 = shift @dims;
      unshift @dims, 1+int($d0/2);
      unshift @dims, 2;
    }
    else
    {
      # backward real fft
      #
      # there's an ambiguity here. I want int($out->dim(0)/2) + 1 == $in->dim(1),
      # however this could mean that
      #  $out->dim(0) = 2*$in->dim(1) - 2
      # or
      #  $out->dim(0) = 2*$in->dim(1) - 1
      #
      # WITHOUT ANY OTHER INFORMATION, I ASSUME EVEN INPUT SIZES, SO I ASSUME
      #  $out->dim(0) = 2*$in->dim(1) - 2
      shift @dims;
      $dims[0] = 2*($dims[0])-2;
    }
    return @dims;
  }

sub validateArguments
  {
    my ($rank, $is_real_fft, $do_inverse_fft, $thisfunction, $in, $out) = @_;

    for my $arg ( $in, $out )
    {
      barf <<EOF unless defined $arg;
$thisfunction arguments must all be defined. If you want an auto-growing piddle, use 'null' such as
 $thisfunction( \$in, \$out = null )
Giving up.
EOF

      my $type = ref $arg;
      $type = 'scalar' unless defined $arg;

      barf <<EOF unless ref $arg && ref $arg eq 'PDL';
$thisfunction arguments must be of type 'PDL'. Instead I got an arg of
type '$type'. Giving up.
EOF
    }

    # validate dimensionality of the piddles
    my @inout = ($in, $out);

    for my $iarg ( 0..1 )
    {
      my $arg = $inout[$iarg];

      if( $arg->isnull )
      {
        barf "$thisfunction: don't know what to do with a null input. Giving up";
      }

      if( !$is_real_fft )
      { validateArgumentDimensions_complex( $rank, $thisfunction, $arg); }
      else
      { validateArgumentDimensions_real( $rank, $do_inverse_fft, $thisfunction, $iarg, $arg); }
    }

    # we have an explicit output piddle we're filling in. Make sure the
    # input/output dimensions match up
    if ( !$is_real_fft )
    { matchDimensions_complex($thisfunction, $rank, $in, $out); }
    else
    { matchDimensions_real($thisfunction, $rank, $do_inverse_fft, $in, $out); }






    sub validateArgumentDimensions_complex
    {
      my ( $rank, $thisfunction, $arg ) = @_;

      # complex FFT. Identically-sized inputs/outputs
      barf <<EOF if $arg->dim(0) != 2;
$thisfunction must have dim(0) == 2 for the inputs and outputs.
This is the (real,imag) dimension. Giving up.
EOF

      barf <<EOF if $arg->ndims-1 < $rank;
Tried to compute a $rank-dimensional FFT, but an array has fewer than $rank dimensions.
Giving up.
EOF
    }

    sub validateArgumentDimensions_real
    {
      my ( $rank, $do_inverse_fft, $thisfunction, $iarg, $arg ) = @_;

      # real FFT. Forward transform takes in real and spits out complex;
      # backward transform does the reverse
      if ( $arg->dim(0) != 2 )
      {
        if ( !$do_inverse_fft && $iarg == 1 )
        {
          barf <<EOF;
$thisfunction produces complex output, so \$output->dim(0) == 2 should be true,
but it's not. This is the (real,imag) dimension. Giving up.
EOF
        }
        elsif ( $do_inverse_fft && $iarg == 0 )
        {
          barf <<EOF;
$thisfunction takes complex input, so \$input->dim(0) == 2 should be true, but
it's not. This is the (real,imag) dimension. Giving up.
EOF
        }
      }

      if( $iarg == 0 )
      {
        # The input needs at least $rank dimensions. If this is a backward
        # transform, the input is complex, so it needs an extra dimension
        my $min_dimensionality = $rank;
        $min_dimensionality++ if $do_inverse_fft;
        if ( $arg->ndims < $min_dimensionality )
        {
          barf <<EOF;
$thisfunction: The input needs at least $min_dimensionality dimensions, but
it has fewer. Giving up.
EOF
        }
      }
      else
      {
        # The output needs at least $rank dimensions. If this is a forward
        # transform, the output is complex, so it needs an extra dimension
        my $min_dimensionality = $rank;
        $min_dimensionality++ if !$do_inverse_fft;
        if ( $arg->ndims < $min_dimensionality )
        {
          barf <<EOF;
$thisfunction: The output needs at least $min_dimensionality dimensions, but
it has fewer. Giving up.
EOF
        }
      }
    }

    sub matchDimensions_complex
    {
      my ($thisfunction, $rank, $in, $out) = @_;

      for my $idim(0..$rank)
      {
        if( $in->dim($idim) != $out->dim($idim) )
        {
          barf <<EOF;
$thisfunction was given input/output matrices of non-matching sizes.
Giving up.
EOF
        }
      }
    }

    sub matchDimensions_real
    {
      my ($thisfunction, $rank, $do_inverse_fft, $in, $out) = @_;

      if( !$do_inverse_fft )
      {
        # Forward FFT. The input is real, the output is complex. $output->dim(0)
        # == 2, since that's the (real, imag) dimension. Furthermore,
        # $output->dim(1) should be int($input->dim(0)/2) + 1 (Section 2.4 of
        # the FFTW3 documentation)

        barf <<EOF if int($in->dim(0)/2) + 1 != $out->dim(1);
$thisfunction: mismatched first dimension:
\$output->dim(1) == int(\$input->dim(0)/2) + 1 wasn't true.
Giving up.
EOF

        for my $idim (1..$rank-1)
        {
          if ( $in->dim($idim) != $out->dim($idim + 1) )
          {
            barf <<EOF;
$thisfunction was given input/output matrices of non-matching sizes.
Giving up.
EOF
          }
        }
      }
      else
      {
        # Backward FFT. The input is complex, the output is real. $input->dim(0)
        # == 2, since that's the (real, imag) dimension. Furthermore,
        # $input->dim(1) should be int($output->dim(0)/2) + 1 (Section 2.4 of
        # the FFTW3 documentation)

        barf <<EOF if int($out->dim(0)/2) + 1 != $in->dim(1);
$thisfunction: mismatched first dimension:
\$input->dim(1) == int(\$output->dim(0)/2) + 1 wasn't true.
Giving up.
EOF

        for my $idim (1..$rank-1)
        {
          if ( $out->dim($idim) != $in->dim($idim + 1) )
          {
            barf <<EOF;
$thisfunction was given input/output matrices of non-matching sizes.
Giving up.
EOF
          }
        }
      }
    }
  }

  sub processTypes
  {
    my ($thisfunction, $in, $out) = @_;

    # types:
    #
    # Input and output types must match, and I can only really deal with float and
    # double. If given an output, I refuse to tweak the type of the output,
    # otherwise, I upgrade to float and then to double
    if( $$out->isnull )
    {
      if( $$in->type < float )
      {
        forceType( $in, (float) );
      }
    }
    else
    {
      # I'm given an output. Make sure this is of a type I can work with,
      # otherwise give up
      my $targetType;

      my $out_type = $$out->type;

      barf <<EOF if $out_type < float;
$thisfunction can only generate 'float' or 'double' output. You gave an output
of type '$out_type'. I can't change this so I give up
EOF

      $targetType = ( $out_type < float ) ? (float) : $out_type;

      forceType( $in,  $targetType );
      forceType( $out, $targetType );
    }


    sub forceType
    {
      my ($x, $type) = @_;
      $$x = convert( $$x, $type ) unless $$x->type == $type;
    }
  }

  sub getPlan
  {
    my ($thisfunction, $rank, $is_real_fft, $do_inverse_fft, $in, $out) = @_;

    # I get the plan ID, check if I already have a plan, and make a new plan if I
    # don't already have one

    my @dims; # the dimensionality of the FFT
    if( !$is_real_fft )
    {
      # complex FFT - ignore first dimension which is (real, imag)
      @dims = $in->dims;
      shift @dims;
    }
    elsif( !$do_inverse_fft )
    {
      # forward real FFT - the input IS the dimensionality
      @dims = $in->dims;
    }
    else
    {
      # backward real FFT
      # we're given an output, and this is the dimensionality
      @dims = $out->dims;
    }

    my $Nslices = reduce {$a*$b} splice(@dims, $rank);
    $Nslices = 1 unless defined $Nslices;

    my $do_double_precision = $in->get_datatype == $PDL_F ? 0 : 1;
    $_last_do_double_precision = $do_double_precision;

    my $do_inplace = is_same_data( $in, $out );

    # I compute a single plan for the whole set of thread slices. I make a
    # worst-case plan, so I find the worst-aligned thread slice and plan off of
    # it. So if $Nslices>1 then the worst-case alignment is the worse of (1st,
    # 2nd) slices
    my $in_alignment  = get_data_alignment_pdl( $in );
    my $out_alignment = get_data_alignment_pdl( $out );
    my $stride_bytes  = ($do_double_precision ? 8 : 4) * reduce {$a*$b} @dims;
    if( $Nslices > 1 )
    {
      my $in_alignment_2nd  = get_data_alignment_int($in_alignment  + $stride_bytes);
      my $out_alignment_2nd = get_data_alignment_int($out_alignment + $stride_bytes);
      $in_alignment         = $in_alignment_2nd  if $in_alignment_2nd  < $in_alignment;
      $out_alignment        = $out_alignment_2nd if $out_alignment_2nd < $out_alignment;
    }

    my $planID = join('_',
                      $thisfunction,
                      $do_double_precision,
                      $do_inplace,
                      $in_alignment,
                      $out_alignment,
                      @dims);
    if ( !exists $existingPlans{$planID} )
    {
      $existingPlans{$planID} = compute_plan( \@dims, $do_double_precision, $is_real_fft, $do_inverse_fft,
                                              $in, $out, $in_alignment, $out_alignment );
      $_Nplans++;
    }

    return $existingPlans{$planID};
  }
}
