# --8<--8<--8<--8<--
#
# Copyright (C) 2010 Smithsonian Astrophysical Observatory
#
# This file is part of PDL::FuncND
#
# PDL::FuncND is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package PDL::FuncND;

use strict;
use warnings;


use PDL::LiteF;
use PDL::Constants qw[ PI ];
use PDL::Math qw[ lgamma ];
use PDL::MatrixOps qw[ determinant identity ];
use PDL::Transform qw[];
use PDL::Options qw[ iparse ];

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

# bizarre spurious errors are being thrown by this policy
## no critic (ProhibitAccessOfPrivateData)

our $VERSION = '0.11';

# keep option handling uniform.  barf if there's a problem
sub _handle_options {


    # remove known arguments from @_ so can use new_from_specification
    my $self = shift;
    my $opt  = shift;

    my ( $vectors, $output, $ndims, $center, $scale );

    if ( $opt->{vectors} ) {
        croak( "first argument must be a piddle if vectors option is set\n" )
          unless eval { $self->isa( 'PDL' ) };

        $output  = shift;
        $vectors = $self;

        croak( "wrong dimensions for input vectors; expected <= 2, got ",
            $vectors->ndims )
          unless $vectors->ndims <= 2;

        # transform 0D piddle into 1D
        $vectors = $vectors->dummy( 0 )
          if $vectors->ndims == 0;

        ( $ndims ) = $vectors->dims;

        $vectors = $opt->{transform}->apply( $vectors )
          if defined $opt->{transform};

        if ( defined $opt->{center} ) {
            croak( "cannot use center = 'auto' if vectors is set\n" )
              if !ref $opt->{center} && $opt->{center} eq 'auto';

            croak(
                "cannot use center = [ $opt->{center}[0], ... ] if vectors is set\n"
              )
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

            $center = zeroes( $vectors->type, $ndims )

        }
    }

    # for 1D output $center may be a 0D PDL; this causes grief;
    # promote it to a 1D
    $center = $center->dummy( 0 ) if defined $center && $center->ndims == 0;

    croak( "center vector has wrong dimensions\n" )
      if defined $center
      && ( $center->ndims != 1
        || ( $center->dims )[0] != $ndims );

    # handle scale
    # scalar -> symmetric, independent
    if ( !defined $opt->{scale} || !ref $opt->{scale} ) {

        $scale = identity( $ndims )
          * ( defined $opt->{scale} ? $opt->{scale}**2 : 1 );
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

        my $R = pdl(
            [ cos( $opt->{theta} ), -sin( $opt->{theta} ) ],
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
      / (   _gamma( 1 / 2 )
          * PI**( $k / 2 )
          * sqrt( determinant( $par->{scale} ) )
          * ( 1 + $d2 )**( ( 1 + $k ) / 2 ) );

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

        $tmp += $par->{ndims} * log( 2 * PI )
          + log( determinant( $par->{scale} ) )

    }

    my $log_pdf = -$tmp / 2;

    return $opt->{log} ? $log_pdf : exp( $log_pdf );

}

sub gaussND {

    unshift @_, {
		 log => 0,
		 norm => 1,
		}, \&_gaussND;
    goto \&_genericND;
}


*PDL::gaussND = \&gaussND;

############################################################################


sub _lorentzND {

    my ( $d2, $opt, $par ) = @_;

    return 1 / ( 1 + $d2 );

}

sub lorentzND {

    unshift @_, {}, \&_lorentzND;
    goto \&_genericND;
}


*PDL::lorentzND = \&lorentz;

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

        $tmp
          *= _gamma( $opt->{beta} )
          / _gamma( $opt->{beta} - $n / 2 )
          / ( PI**( $n / 2 ) * $alpha_n );

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
    my $m = $x->ndims > 1 ? ($x->dims)[-1] : 1;

    $out = zeroes( double, $m )
      unless defined $out;

    # if this is 1D, $scale may come in with shapes [], [1], or [1][1]
    # we want the latter
    $scale = $scale->dummy(1) if $scale->dims < 2;

    # invert the matrix if it hasn't already been inverted
    $scale = $scale->inv
      unless $opt{inverted};

    inner2( $xc, $scale, $xc, $out );

    $out->inplace->sqrt unless $opt{squared};

    return $out;
}

*PDL::mahalanobis = \&mahalanobis;

1;
