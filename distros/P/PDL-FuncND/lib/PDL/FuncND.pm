package PDL::FuncND;

# ABSTRACT: N dimensional version of functions

use strict;
use warnings;

use PDL::LiteF;
use PDL::Constants qw[ PI ];
use PDL::Math      qw[ lgamma ];
use PDL::MatrixOps qw[ determinant identity ];
use PDL::Transform qw[];
use PDL::Options   qw[ iparse ];

use Scalar::Util qw[ looks_like_number ];

use base 'PDL::Exporter';

use Carp;

our @EXPORT_OK = qw[
  cauchyND
  gaussND
  lorentzND
  mahalanobis
  moffatND
];

our %EXPORT_TAGS = ( Func => [@EXPORT_OK], );

#<<< no tidy
our $VERSION = '0.13';
#>>>

# keep option handling uniform.  barf if there's a problem
sub _handle_options {    ## no critic (Subroutines::ProhibitExcessComplexity)

    # remove known arguments from @_ so can use new_from_specification
    my $self = shift;
    my $opt  = shift;

    my ( $vectors, $output, $ndims, $center, $scale );

    if ( $opt->{vectors} ) {
        croak( "first argument must be a piddle if vectors option is set\n" )
          unless eval { $self->isa( 'PDL' ) };

        $output  = shift;
        $vectors = $self;

        croak( 'wrong dimensions for input vectors; expected <= 2, got ', $vectors->ndims )
          if $vectors->ndims > 2;

        # transform 0D piddle into 1D
        $vectors = $vectors->dummy( 0 )
          if $vectors->ndims == 0;

        ( $ndims ) = $vectors->dims;

        $vectors = $opt->{transform}->apply( $vectors )
          if defined $opt->{transform};

        if ( defined $opt->{center} ) {
            croak( "cannot use center = 'auto' if vectors is set\n" )
              if !ref $opt->{center} && $opt->{center} eq 'auto';

            croak( "cannot use center = [ $opt->{center}[0], ... ] if vectors is set\n" )
              if 'ARRAY' eq ref $opt->{center}
              && !ref $opt->{center}[0]
              && !looks_like_number( $opt->{center}[0] );

            $center = PDL::Core::topdl( $opt->{center} );
        }
    }

    else {
        $output
          = @_
          ? $self->new_from_specification( @_ )
          : $self->new_or_inplace;

        $ndims = $output->ndims;

        $vectors = $output->ndcoords->reshape( $ndims, $output->nelem );

        $vectors->inplace->apply( $opt->{transform} )
          if defined $opt->{transform};

        if ( defined $opt->{center} ) {
            if ( !ref $opt->{center} && $opt->{center} eq 'auto' ) {
                $center = ( pdl( [ $output->dims ] ) - 1 ) / 2;
                $center->inplace->apply( $opt->{transform} )
                  if defined $opt->{transform};
            }
            elsif ('ARRAY' eq ref $opt->{center}
                && !ref $opt->{center}[0]
                && $opt->{center}[0] eq 'offset' )
            {

                $center = ( pdl( [ $output->dims ] ) - 1 ) / 2;

                # inplace bug ( PDL == 2.4.11, at least) causes SEGV
                # if this is done in place. so. don't.
                $center = $center->apply( $opt->{transform} )
                  if defined $opt->{transform};

                # allow:
                #  offset => piddle
                #  offset => [ ... ]
                #  offset => ( list )

                # NOTE!!!! bug in topdl ( PDL == 2.4.11, at least )
                # topdl only uses the first argument
                my @offset = @{ $opt->{center} };
                shift @offset;

                $center += PDL::Core::topdl( @offset > 1 ? \@offset : @offset );
            }

            else {

                $center = PDL::Core::topdl( $opt->{center} );

            }
        }
        else {

            $center = zeroes( $vectors->type, $ndims );

        }
    }

    # for 1D output $center may be a 0D PDL; this causes grief;
    # promote it to a 1D
    $center = $center->dummy( 0 ) if defined $center && $center->ndims == 0;

    croak( "center vector has wrong dimensions\n" )
      if defined $center
      && ( $center->ndims != 1
        || ( $center->dims )[0] != $ndims );

    ## no critic( ControlStructures::ProhibitCascadingIfElse )

    # handle scale
    # scalar -> symmetric, independent
    if ( !defined $opt->{scale} || !ref $opt->{scale} ) {

        $scale = identity( $ndims ) * ( defined $opt->{scale} ? $opt->{scale}**2 : 1 );
    }

    # 1D piddle of length N
    elsif ( 'ARRAY' eq ref $opt->{scale}
        && @{ $opt->{scale} } == $ndims )
    {
        $scale = identity( $ndims ) * pdl( $opt->{scale} )**2;
    }

    # 1D piddle of length N
    elsif (eval { $opt->{scale}->isa( 'PDL' ) }
        && $opt->{scale}->ndims == 1
        && ( $opt->{scale}->dims )[0] == $ndims )
    {
        $scale = identity( $ndims ) * $opt->{scale}**2;
    }

    # full  matrix N^N piddle
    elsif (eval { $opt->{scale}->isa( 'PDL' ) }
        && $opt->{scale}->ndims == 2
        && all( pdl( $opt->{scale}->dims ) == pdl( $ndims, $ndims ) ) )
    {
        $scale = $opt->{scale};
    }

    else {
        croak(
            "scale argument is not a scalar, an array of length $ndims,",
            " or a piddle of shape ($ndims) or shape ($ndims,$ndims)\n"
        );
    }

    # apply a rotation to the scale matrix
    if ( defined $opt->{theta} ) {
        croak( "theta may only be used for 2D PDFs\n" )
          if $ndims != 2;

        my $R = pdl( [ cos( $opt->{theta} ), -sin( $opt->{theta} ) ],
            [ sin( $opt->{theta} ), cos( $opt->{theta} ) ] );
        $scale = $R->transpose x $scale x $R;
    }

    return (
        vectors => $vectors,
        output  => $output,
        ndims   => $ndims,
        center  => $center,
        ndims   => $ndims,
        scale   => $scale
    );

}


############################################################################

sub _gamma { exp( ( lgamma( @_ ) )[0] ) }

############################################################################

sub _genericND {

    my ( $xopts, $sub ) = ( shift, shift );

    # handle being called as a method or a function
    my $self = eval { ref $_[0] && $_[0]->isa( 'PDL' ) } ? shift @_ : 'PDL';

    # handle options.
    my $opt = 'HASH' eq ref $_[-1] ? pop( @_ ) : {};
    my %opt = iparse( {
            center    => undef,
            scale     => 1,
            transform => undef,
            vectors   => 0,
            theta     => undef,
            %$xopts,
        },
        $opt
    );

    my %par = _handle_options( $self, \%opt, @_ );

    my $d2 = mahalanobis(
        $par{vectors},
        $par{scale},
        {
            squared => 1,
            center  => $par{center},
        } );

    my $retval = $sub->( $d2, \%opt, \%par );

    my $output = $par{output};

    if ( $opt{vectors} ) {
        $output = $retval;
    }

    else {
        $output .= $retval->reshape( $output->dims );
    }

    return wantarray
      ? (
        vals      => $output,
        center    => $par{center},
        scale     => $par{scale},
        transform => $par{transform} )
      : $output;

}

############################################################################

# from http://en.wikipedia.org/wiki/Cauchy_distribution#Multivariate_Cauchy_distribution

#                                    1 + k
#                              Gamma(-----)
#                                      2
#     ------------------------------------------------------------
#                                                          1 + k
#                                                          -----
#           1     k/2    1/2              T   -1             2
#     Gamma(-)  pi    |S|    (1 + (x - mu)   S    (x - mu))
#           2
#


sub _cauchyND {

    my ( $d2, $opt, $par ) = @_;

    my $k = $par->{ndims};

    my $pdf
      = _gamma( ( 1 + $k ) / 2 )
      / ( _gamma( 1 / 2 ) * PI**( $k / 2 ) * sqrt( determinant( $par->{scale} ) ) * ( 1 + $d2 )
          **( ( 1 + $k ) / 2 ) );

    return $opt->{log} ? log( $pdf ) : $pdf;
}

sub cauchyND {

    unshift @_, { log => 0 }, \&_cauchyND;
    goto \&_genericND;
}

*PDL::cauchyND = \&cauchyND;

############################################################################

sub _gaussND {

    my ( $d2, $opt, $par ) = @_;

    my $tmp = $d2;

    if ( $opt->{norm} == 1 ) {

        $tmp += $par->{ndims} * log( 2 * PI ) + log( determinant( $par->{scale} ) );

    }

    my $log_pdf = -$tmp / 2;

    return $opt->{log} ? $log_pdf : exp( $log_pdf );

}

sub gaussND {

    unshift @_,
      {
        log  => 0,
        norm => 1,
      },
      \&_gaussND;
    goto \&_genericND;
}


*PDL::gaussND = \&gaussND;

############################################################################


sub _lorentzND {

    my ( $d2, $opt, undef ) = @_;

    return 1 / ( 1 + $d2 );

}

sub lorentzND {

    unshift @_, {}, \&_lorentzND;
    goto \&_genericND;
}


*PDL::lorentzND = \&lorentzND;

############################################################################


sub _moffatND {

    my ( $d2, $opt, $par ) = @_;

    croak( "missing beta parameter\n" )
      unless defined $opt->{beta};

    my $n = $par->{ndims};

    my $tmp = ( 1 + $d2 )**-$opt->{beta};

    if ( $opt->{norm} == 1 ) {

        # scale is a matrix with elements ~alpha**2
        # det(scale) ~ (alpha**2)**$n
        # sqrt(det(scale)) ~ alpha**$n

        my $alpha_n = sqrt( determinant( $par->{scale} ) );

        $tmp *= _gamma( $opt->{beta} ) / _gamma( $opt->{beta} - $n / 2 ) / ( PI**( $n / 2 ) * $alpha_n );

    }

    return $tmp;
}

sub moffatND {

    unshift @_,
      {
        alpha => undef,
        beta  => undef,
        norm  => 1,
      },
      \&_moffatND;
    goto \&_genericND;

}

*PDL::moffatND = \&moffatND;

############################################################################



sub mahalanobis {

    # handle options.
    my $opt = 'HASH' eq ref $_[-1] ? pop( @_ ) : {};
    my %opt = PDL::Options::iparse( {
            center   => undef,
            inverted => 0,
            squared  => 0,
        },
        $opt
    );

    my ( $x, $scale, $out ) = @_;

    my $xc;
    if ( defined $opt{center} ) {
        my $c = PDL::Core::topdl( $opt{center} );
        $xc = $x - $c;
    }
    else {
        $xc = $x;
    }

    # may be passed a single vector; be nice
    my $m = $x->ndims > 1 ? ( $x->dims )[-1] : 1;

    $out = zeroes( double, $m )
      unless defined $out;

    # if this is 1D, $scale may come in with shapes [], [1], or [1][1]
    # we want the latter
    $scale = $scale->dummy( 1 ) if $scale->dims < 2;

    # invert the matrix if it hasn't already been inverted
    $scale = $scale->inv
      unless $opt{inverted};

    inner2( $xc, $scale, $xc, $out );

    $out->inplace->sqrt unless $opt{squared};

    return $out;
}

*PDL::mahalanobis = \&mahalanobis;

#
# This file is part of PDL-FuncND
#
# This software is Copyright (c) 2025 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory Cartesion HWHM
Mahalanobis Moffat NxN aprt cauchyND gaussND lorentzND mahalanobis moffatND

=head1 NAME

PDL::FuncND - N dimensional version of functions

=head1 VERSION

version 0.13

=head1 SYNOPSIS

    use PDL::FuncND;

=head1 DESCRIPTION

This module provides multi-dimensional implementations of common
functions.

=head1 INTERNALS

=head1 FUNCTIONS

=head2 cauchyND

=begin ref




=end ref

Evaluate the multi-variate Cauchy function on an N-dimensional grid or
at a set of locations.

=begin usage




=end usage

  $a = cauchyND( [OPTIONAL TYPE], $nx, $ny, ..., \%options );
  $b = cauchyND( $a, \%options );
  cauchyND( inplace $a, \%options );
  $a->inplace->cauchyND( \%options );

B<cauchyND> can evaluate the function either on a grid or at discrete
locations:

=over

=item * evaluation on a grid

Either specify the output piddle dimensions explicitly,

  $f = cauchyND( [ OPTIONAL TYPE], $nx, $ny, ..., \%options );

or specify a template piddle I<without> specifying the C<vectors>
option:

  $f = cauchyND( $piddle, \%options );

By default B<cauchyND> will evaluate the function at the I<indices> of
the points in the input piddle.  These may be mapped to other values
by specifying a transform with the C<transform> option.  B<cauchyND>
is inplace aware, and will use B<$piddle> as the output piddle if its
inplace flag is set.

  cauchyND( inplace $f, \%options );
  $f->inplace->cauchyND( \%options );

=item * evaluation at a set of locations

The input piddle should represent a set of vectors and should have a
shape of (N,m), where C<m> is the number of vectors in the set. The
C<vectors> option must also be set:

  $piddle = pdl( [2,1], [3,1], [4,2]  );
  $f = cauchyND( $piddle, { vectors => 1 } );

The vectors may be transformed before use via the C<transform> option.

=back

The following options are available:

=over

=item C<center> | C<centre>

The center of the distribution.  If not specified it defaults to the
origin.

This may take one of the following forms

=over

=item * A vector of shape (N).

The location of the center. This may be either a Perl arrayref or a
one dimensional piddle.  If the input coordinates are transformed,
this is in the I<transformed> space.

=item * the string C<auto>

If the PDF is calculated on a grid, this will center the distribution on
the grid. It is an error to use this for explicit locations.

=item * An arrayref

The first element of the array is a string indicating the meaning of
the rest of the array.  The following are supported:

=over

=item * C<offset>

The second element of the array is a piddle indicating an offset from
an automatically generated center.  This allows easily accumulating
multiple offset offsets.  For example:

  $img  = cauchyND( double, 32, 32, { %attr, center => 'auto' } );
  $img += moffatND( $img, { %moffat_attr,
                            center => [ offset => [ 5.24, 0.3 ] ] } );

=back

=back

=item C<transform>

A PDL::Transform object to be applied to the input coordinates.

=item C<scale>

The scale. If the input coordinates are transformed
via the C<transform> option, the units of scale are those in the
I<transformed> space.  This may be specified as:

=over

=item * a scalar (Perl or piddle)

This results in a symmetric distribution with the given scale along each
coordinate.

=item * a vector of shape (N) (piddle or Perl arrayref)

This results in a distribution with the specified scales for each
coordinate.

=item * a matrix (piddle of shape (N,N))

This should be a positive-definite matrix containing squared
scales.

=back

=item C<theta> (Perl scalar)

B<Only for 2D!> Applies a rotation (clockwise, e.g. +X
rotates towards -Y) by the specified angle (specified in radians).

=item C<log> (Boolean)

If true, return the logarithm of the function. Defaults to false.

=back

=head2 gaussND

=begin ref




=end ref

Evaluate the sampled multi-dimensional Gaussian PDF on an
N-dimensional grid or at a set of locations.

=begin usage




=end usage

  $f = gaussND( [OPTIONAL TYPE], $nx, $ny, ..., \%options );
  $f = gaussND( $piddle, \%options );
  gaussND( inplace $piddle, \%options );
  $a->inplace->gaussND( \%options );

B<gaussND> can evaluate the function either on a grid or at discrete
locations:

=over

=item * evaluation on a grid

Either specify the output piddle dimensions explicitly,

  $f = gaussND( [ OPTIONAL TYPE], $nx, $ny, ..., \%options );

or specify a template piddle I<without> specifying the C<vectors>
option:

  $f = gaussND( $piddle, \%options );

By default B<gaussND> will evaluate the function at the I<indices> of
the points in the input piddle.  These may be mapped to other values
by specifying a transform with the C<transform> option.  B<gaussND> is
inplace aware, and will use B<$piddle> as the output piddle if its
inplace flag is set.

  gaussND( inplace $f, \%options );
  $f->inplace->gaussND( \%options );

=item * evaluation at a set of locations

The input piddle should represent a set of vectors and should have a
shape of (N,m), where C<m> is the number of vectors in the set. The
C<vectors> option must also be set:

  $piddle = pdl( [2,1], [3,1], [4,2]  );
  $f = gaussND( $piddle, { vectors => 1 } );

The vectors may be transformed before use via the C<transform> option.

=back

The following options are available:

=over

=item C<center> | C<centre>

The center of the distribution.  If not specified it defaults to the
origin.

This may take one of the following values:

=over

=item * A vector of shape (N).

The location of the center. This may be either a Perl arrayref or a
one dimensional piddle.  If the input coordinates are transformed,
this is in the I<transformed> space.

=item * the string C<auto>

If the PDF is calculated on a grid, this will center the distribution on
the grid. It is an error to use this for explicit locations.

=back

=item C<transform>

A PDL::Transform object to be applied to the input coordinates.

=item C<scale>

The scale. If the input coordinates are transformed
via the C<transform> option, the units of scale are those in the
I<transformed> space.  This may be specified as:

=over

=item * a scalar (Perl or piddle)

This results in a symmetric distribution with the given scale along each
coordinate.

=item * a vector of shape (N) (piddle or Perl arrayref)

This results in a distribution with the specified scales for each
coordinate.

=item * the full covariance matrix (piddle of shape (N,N))

This results in a distribution with correlated scales. At present this
matrix is not verified to be a legitimate covariance matrix.

=back

=item C<theta> (Perl scalar)

B<Only for 2D!> Applies a rotation (clockwise, e.g. +X
rotates towards -Y) by the specified angle (specified in radians).

=item C<log> (Boolean)

If true, return the logarithm of the function. Defaults to false.

=back

=head2 lorentzND

=begin ref




=end ref

Evaluate the multi-dimensional Lorentz function on an
N-dimensional grid or at a set of locations.

=begin usage




=end usage

  $f = lorentzND( [OPTIONAL TYPE], $nx, $ny, ..., \%options );
  $f = lorentzND( $piddle, \%options );
  lorentzND( inplace $piddle, \%options );
  $a->inplace->lorentzND( \%options );

The Lorentz function is usually defined in one dimension as.

                       2
                      g
  f(x; x0, g) = --------------
                       2    2
                (x - x0)  + g

where I<g> is the half-width at half-max (HWHM).  The two dimensional
symmetric analogue (sometimes called the "radial Lorentz
function") is

                                    2
                                   g
  f(x, y; x0, y0, g) = --------------------------
                               2           2    2
                       (x - x0)  + (y - y0)  + g

One can extend this to an asymmetric form by writing it as

                            1
  f(x; u, S) = ---------------------------
                      T    -1
               (x - u)  . S  . (x - u) + 1

where I<x> is now a vector, I<u> is the expectation value of the
distribution, and I<S> is a matrix describing the N-dimensional scale
of the distribution akin to (but not the same as!) a covariance matrix.

For example, a symmetric 2D Lorentz with HWHM of I<g> has

       [  2     ]
       [ g   0  ]
  S =  [        ]
       [      2 ]
       [ 0   g  ]

while an elliptical distribution elongated twice as much along the
I<X> axis as the I<Y> axis would be:

       [     2      ]
       [ (2*g)   0  ]
  S =  [            ]
       [          2 ]
       [ 0       g  ]

B<lorentzND> extends the Lorentz function to N dimensions by treating
I<x> and I<u> as vectors of length I<N>, and I<S> as an I<NxN> matrix.

B<Please note!> While the one dimensional Lorentz function is
equivalent to the one-dimensional Cauchy (aprt from, in this
formulation, the normalization constant), this formulation of the
multi-dimensional Lorentz function is B<not> equivalent to the
multi-dimensional Cauchy!

It can evaluate the function either on a grid or at discrete
locations:

=over

=item * evaluation on a grid

Either specify the output piddle dimensions explicitly,

  $f = lorentzND( [ OPTIONAL TYPE], $nx, $ny, ..., \%options );

or specify a template piddle I<without> specifying the C<vectors>
option:

  $f = lorentzND( $piddle, \%options );

By default B<lorentzND> will evaluate the function at the I<indices> of
the points in the input piddle.  These may be mapped to other values
by specifying a transform with the C<transform> option.  B<lorentzND> is
inplace aware, and will use B<$piddle> as the output piddle if its
inplace flag is set.

  lorentzND( inplace $f, \%options );
  $f->inplace->lorentzND( \%options );

=item * evaluation at a set of locations

The input piddle should represent a set of vectors and should have a
shape of (N,m), where C<m> is the number of vectors in the set. The
C<vectors> option must also be set:

  $piddle = pdl( [2,1], [3,1], [4,2]  );
  $f = lorentzND( $piddle, { vectors => 1 } );

The vectors may be transformed before use via the C<transform> option.

=back

The following options are available:

=over

=item C<center> | C<centre>

The center of the distribution.  If not specified it defaults to the
origin.

This may take one of the following values:

=over

=item * A vector of shape (N).

The location of the center. This may be either a Perl arrayref or a
one dimensional piddle.  If the input coordinates are transformed,
this is in the I<transformed> space.

=item * the string C<auto>

If the PDF is calculated on a grid, this will center the distribution on
the grid. It is an error to use this for explicit locations.

=back

=item C<transform>

A PDL::Transform object to be applied to the input coordinates.

=item C<scale>

The scale. If the input coordinates are transformed
via the C<transform> option, the units of scale are those in the
I<transformed> space.  This may be specified as:

=over

=item * a scalar (Perl or piddle)

This results in a symmetric distribution with the given scale along each
coordinate.

=item * a vector of shape (N) (piddle or Perl arrayref)

This results in a distribution with the specified scales for each
coordinate.

=item * a matrix (piddle of shape (N,N))

This should be a positive-definite matrix containing squared
scales.

=back

=item C<theta> (Perl scalar)

B<Only for 2D!> Applies a rotation (clockwise, e.g. +X
rotates towards -Y) by the specified angle (specified in radians).

=back

=head2 moffatND

=begin ref




=end ref

Evaluate the multi-dimensional Moffat distribution on an
N-dimensional grid or at a set of locations.

=begin usage




=end usage

  $f = moffatND( [OPTIONAL TYPE], $nx, $ny, ..., \%options );
  $f = moffatND( $piddle, \%options );
  moffatND( inplace $piddle, \%options );
  $a->inplace->moffatND( \%options );

The Moffat distribution is usually defined in two dimensions as.

                                                           2    2
                                              2  -1       x  + y  -beta
  f(x, y, alpha, beta) := (beta - 1) (pi alpha  )    (a + -------)
                                                                2
                                                           alpha

In astronomy this is also known (confusingly) as the beta function, and is
often expressed in radial form:

                                               2
                        2 r (beta - 1)        r    -beta
  fr(r, alpha, beta) := -------------- (1 + ------)
                                 2               2
                            alpha           alpha

One can extend the Cartesion expression to an n-dimensional asymmetric
form by writing it as

  fn(x, u, S, alpha, beta) :=

       gamma(beta)        n/2    1/2  -1              T   -1         -beta
    ----------------- ( pi    |S|    )    (1 + (x - u) . S . (x - u))
          2 beta - n
    gamma(----------)
              2

where I<n> is the number of dimensions, I<x> is now a vector, I<u> is
the expectation value of the distribution, and I<S> is a matrix
describing the N-dimensional scale of the distribution akin to (but
not the same as!) a covariance matrix.

Note that the integral of the distribution diverges for C<< beta <= n/2 >>.

B<moffatND> extends the Moffat function to N dimensions by treating
I<x> and I<u> as vectors of length I<N>, and I<S> as an I<NxN> matrix.

It can evaluate the function either on a grid or at discrete
locations:

=over

=item * evaluation on a grid

Either specify the output piddle dimensions explicitly,

  $f = moffatND( [ OPTIONAL TYPE], $nx, $ny, ..., \%options );

or specify a template piddle I<without> specifying the C<vectors>
option:

  $f = moffatND( $piddle, \%options );

By default B<moffatND> will evaluate the function at the I<indices> of
the points in the input piddle.  These may be mapped to other values
by specifying a transform with the C<transform> option.  B<moffatND> is
inplace aware, and will use B<$piddle> as the output piddle if its
inplace flag is set.

  moffatND( inplace $f, \%options );
  $f->inplace->moffatND( \%options );

=item * evaluation at a set of locations

The input piddle should represent a set of vectors and should have a
shape of (N,m), where C<m> is the number of vectors in the set. The
C<vectors> option must also be set:

  $piddle = pdl( [2,1], [3,1], [4,2]  );
  $f = moffatND( $piddle, { vectors => 1 } );

The vectors may be transformed before use via the C<transform> option.

=back

The following options are available:

=over

=item C<beta>

The Moffat I<beta> parameter. Required.

=item C<center> | C<centre>

The center of the distribution.  If not specified it defaults to the
origin.

This may take one of the following values:

=over

=item * A vector of shape (N).

The location of the center. This may be either a Perl arrayref or a
one dimensional piddle.  If the input coordinates are transformed,
this is in the I<transformed> space.

=item * the string C<auto>

If the PDF is calculated on a grid, this will center the distribution on
the grid. It is an error to use this for explicit locations.

=back

=item C<transform>

A PDL::Transform object to be applied to the input coordinates.

=item C<scale>

The scale. If the input coordinates are transformed
via the C<transform> option, the units of scale are those in the
I<transformed> space.  This may be specified as:

=over

=item * a scalar (Perl or piddle)

This results in a symmetric distribution with the given scale along each
coordinate.

=item * a vector of shape (N) (piddle or Perl arrayref)

This results in a distribution with the specified scales for each
coordinate.

=item * a matrix (piddle of shape (N,N))

This should be a positive-definite matrix containing squared
scales.

=back

=item C<theta> (Perl scalar)

B<Only for 2D!> Applies a rotation (clockwise, e.g. +X
rotates towards -Y) by the specified angle (specified in radians).

=back

=head2 mahalanobis

=begin ref




=end ref

Calculate the Mahalanobis distance for one or more vectors

=begin sig




=end sig

  Signature: ( x(n,m), s(n,n), [o]d(m), \%options )

=begin usage




=end usage

  $d = mahalanobis( $v, $S, \%options );
  mahalanobis( $v, $S, $d, \%options );

The Mahalanobis distance of a multivariate vector (v) from a location
(u) with a covariance matrix (S) is defined as

  dm(x,u) = sqrt( (v-u)T S^-1 (v-u) )

The input piddle representing the vectors (C<$v>) must have shape (N,m),
where C<N> is the dimension of the vector space and C<m> is the number
of vectors.

The input covariance matrix (C<$S>) must have shape (N,N).  It is I<not>
checked for validity.

The available options are:

=over

=item C<center> | C<centre>

The vector from which the distance is to be calculated.  It must have shape (N).
It defaults to the origin.

=item C<inverted>

If true, the input matrix is the inverse of the covariance matrix.
Defaults to false.

=item C<squared>

if true, the returned values are the distances squared.

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-pdl-funcnd@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=PDL-FuncND>

=head2 Source

Source is available at

  https://gitlab.com/djerius/pdl-funcnd

and may be cloned from

  https://gitlab.com/djerius/pdl-funcnd.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
