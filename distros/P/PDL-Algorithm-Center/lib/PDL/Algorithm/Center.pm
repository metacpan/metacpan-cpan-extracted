package PDL::Algorithm::Center;

# ABSTRACT: Various methods of finding the center of a sample

use strict;
use warnings;

require 5.010000;

use feature 'state';

our $VERSION = '0.06';

use Carp;

use Try::Tiny;
use Safe::Isa;
use Ref::Util qw< is_arrayref is_ref is_coderef  >;

use custom::failures;
use Package::Stash;
use Hash::Wrap;

use PDL::Algorithm::Center::Failure ':all';

use PDL::Algorithm::Center::Types -all;
use Types::Standard -types;
use Types::Common::Numeric -types;
use Type::Params qw[ compile_named ];

use PDL::Lite ();

use Exporter 'import';

our @EXPORT_OK = qw[ sigma_clip iterate ];


sub _weighted_mean_center {
    my ( $coords, $mask, $weight, $total_weight ) = @_;

    my $wmask = $mask * $weight;

    $total_weight //= $wmask->dsum;

    iteration_empty_failure->throw( "weighted mean center: all elements excluded or sum(weight) == 0" )
      if $total_weight == 0;

    return ( $coords * $wmask->dummy( 0 ) )->xchg( 0, 1 )->dsumover
      / $total_weight;
}

sub _distance {

    my ( $last, $current ) = @_;

    return sqrt( ( ( $last->center - $current->center )**2 )->dsum );
}

sub _sigma_clip_initialize {

    my ( $init_clip, $dtol, $coords, $mask, $weight, $current, $work ) = @_;

    $current->{clip} = $init_clip;

    my $r2 = $work->{r2} = PDL->null;
    $r2 .= ( ( $coords - $current->center )**2 )->dsumover;

    $mask *= ( $r2 <= $init_clip**2 )
      if defined $init_clip;

    my $wmask = $work->{wmask} = $mask * $weight;

    $current->total_weight( $wmask->dsum );
    $current->nelem( $mask->sum );

    iteration_empty_failure->throw( "sigma_clip initialize: all elements excluded or sum(weight) == 0" )
      if $current->total_weight == 0;

    $current->{sigma} = sqrt( ( $wmask * $r2 )->dsum / $current->total_weight );

    return;
}

sub _sigma_clip_calc_wmask {

    my ( $nsigma, $coords, $mask, $weight, $iter, $work ) = @_;

    my $r2 = $work->{r2};
    $r2 .= ( ( $coords - $iter->center )**2 )->dsumover;

    $iter->clip( $nsigma * $iter->sigma );

    $mask *= $r2 < $iter->clip**2;

    $iter->total_weight( ( $mask * $weight )->dsum );
    $iter->nelem( $mask->sum );

    my $wmask = $work->{wmask};
    $wmask .= $mask * $weight;

    iteration_empty_failure->throw( "sigma_clip calc_wmask: all elements excluded or sum(weight) == 0" )
      if $iter->total_weight == 0;

    $iter->sigma( sqrt( ( $wmask * $r2 )->dsum / $iter->total_weight ) );

    return;
}


sub _sigma_clip_is_converged {

    my ( $init_clip, $dtol, $coords, $mask, $weight, $last, $current ) = @_;

    $current->{dist} = undef;

    # stop if standard deviations and centers haven't changed

    if ( $current->sigma == $last->sigma
        && PDL::all( $current->center == $last->center ) )
    {

        $current->dist( _distance( $last, $current ) )
          if defined $dtol;

        return 1;
    }

    # or, if a tolerance was defined, stop if distance from old
    # to new centers is less than the tolerance.
    if ( defined $dtol ) {
        $current->dist( _distance( $last, $current ) );
        return 1 if $current->dist <= $dtol;
    }

    return;
}


sub _sigma_clip_log_iteration {

    my $iter = shift;

    # iter n clip sigma x y
    # xxxx xxxxxxx xxxxxxxxxx xxxxxxxxxx xxxxxxxxxx xxxxxxxxxx

    my $ncoords = $iter->center->nelem;
    if ( $iter->iter == 0 ) {

        my $fmt = "%4s %7s" . ' %10s' x ( 3 + $ncoords ) . "\n";

        printf $fmt,
          @$_
          for [
            qw{ iter  nelem    weight      clip      sigma   },
            map { "q$_" } 1 .. $ncoords
          ],
          [
            qw{ ---- ------- ---------- ---------- ----------},
            ( "----------" ) x $ncoords
          ];
    }

    my @fmt = ( '%4d', '%7d', ( '%10.6g' ) x ( 3 + $ncoords ) );
    $fmt[3] = '%10s' if !defined $iter->clip;

    printf(
        join( ' ', @fmt ) . "\n",
        $iter->iter, $iter->nelem, $iter->total_weight,
        $iter->clip // 'undef', $iter->sigma, $iter->center->list
    );
}


## no critic (ProhibitAccessOfPrivateData)

#pod =pod
#pod
#pod =sub sigma_clip
#pod
#pod   $results = sigma_clip(
#pod       center      => Optional [ Center | CodeRef ],
#pod       clip        => Optional [PositiveNum],
#pod       coords      => Optional [Coords],
#pod       dtol        => PositiveNum,
#pod       iterlim     => Optional [PositiveInt],
#pod       log         => Optional [Bool | CodeRef],
#pod       mask        => Optional [ Undef | Piddle_min1D_ne ],
#pod       save_mask   => Optional [Bool],
#pod       save_weight => Optional [Bool],
#pod       nsigma      => PositiveNum,
#pod       weight      => Optional [ Undef | Piddle_min1D_ne ],
#pod   );
#pod
#pod Center a dataset by iteratively excluding data outside of a radius
#pod equal to a specified number of standard deviations. The dataset may be
#pod specified as a list of coordinates and optional weights, or as a
#pod weight piddle of shape I<NxM> (e.g., an image).  If only the weight
#pod piddle is provided, it is converted internally into a list of
#pod coordinates with associated weights.
#pod
#pod To operate on a subset of the input data, specify the C<mask> option.
#pod
#pod A L<PDL::Algorithm::Center::Failure::parameter> exception will be
#pod thrown if there is a parameter error.
#pod
#pod The center of a data set is determined by:
#pod
#pod =over
#pod
#pod =item 1
#pod
#pod clipping (ignoring) the data whose distance to the current center is
#pod greater than a specified number of standard deviations
#pod
#pod =item 2
#pod
#pod calculating a new center by performing a (weighted) centroid of the
#pod remaining data
#pod
#pod =item 3
#pod
#pod calculating the standard deviation of the distance from the remaining
#pod data to the center
#pod
#pod =item 4
#pod
#pod repeat step 1 until either a convergence tolerance has been met or
#pod the iteration limit has been exceeded
#pod
#pod =back
#pod
#pod The initial center may be explicitly specified,  or may be calculated
#pod by performing a (weighted) centroid of the data.
#pod
#pod The initial standard deviation is calculated using the initial center and either
#pod the entire dataset, or from a clipped region about the initial center.
#pod
#pod =head3 Options
#pod
#pod The following options are available:
#pod
#pod =over
#pod
#pod =item C<center> => I<ArrayRef | Piddle1D_ne | coderef >
#pod
#pod The initial center.  It may be
#pod
#pod =over
#pod
#pod =item *
#pod
#pod An array of length I<N>
#pod
#pod The array may contain undefined values for each dimension for which the center should
#pod be determined by finding the mean of the values in that dimension.
#pod
#pod =item *
#pod
#pod A piddle with shape I<N>  (or
#pod something that can be coerced into one, see L</TYPES>),
#pod
#pod =item *
#pod
#pod A coderef which will return the center as a piddle with shape I<N>.
#pod The subroutine is called as
#pod
#pod   &$center( $coords, $mask, $weight, $total_weight );
#pod
#pod with
#pod
#pod =over
#pod
#pod =item C<$coords>
#pod
#pod A piddle with shape I<NxM> containing I<M> coordinates with dimension I<N>
#pod
#pod =item C<$mask>
#pod
#pod A piddle with shape I<M>, essentially a flattened copy of the initial C<$mask> option to L</iterate>.
#pod
#pod =item C<$weight>
#pod
#pod A piddle with shape I<M>, essentially a copy of the initial C<$weight> option to L</iterate>.
#pod
#pod =item C<$total_weight>
#pod
#pod A scalar which is the sum of  C<$mask * $weight>
#pod
#pod =back
#pod
#pod =back
#pod
#pod =item C<clip> => I<positive number>
#pod
#pod I<Optional>.  The clipping radius used to determine the initial standard deviation.
#pod
#pod =item C<coords> => I<Coords>
#pod
#pod I<Optional>.  The coordinates to center.  C<coords> is a piddle of
#pod shape I<NxM> (or anything which can be coerced into it, see
#pod L</TYPES>) where I<N> is the number of dimensions in the data and
#pod I<M> is the number of data elements.
#pod
#pod C<weight> may be specified with coords to indicate weighted data.
#pod
#pod C<mask> may be specified to indicate that a subset of the coordinates
#pod should be operated on.
#pod
#pod C<coords> is useful if the data cube is not fully populated; for dense
#pod data, use C<weight> I<instead>.
#pod
#pod =item C<dtol> => I<positive number>
#pod
#pod I<Optional>.  If specified iteration will cease when successive centers are closer
#pod than the specified distance.
#pod
#pod =item C<iterlim> => I<positive integer>
#pod
#pod I<Optional>. The maximum number of iterations to run.  Defaults to 10.
#pod
#pod =item C<log> => I<boolean|coderef>
#pod
#pod I<Optional>.
#pod
#pod If C<log> is true (and not a I<coderef>), a default logger which outputs
#pod to B<STDOUT> will be used.
#pod
#pod If a I<coderef> it will be called before the first iteration and at
#pod the end of each iteration. It is passed a copy of the current
#pod iteration's results object; see L</Sigma Clip Iteration Results>.
#pod
#pod =item C<mask> => I<piddle>
#pod
#pod I<Optional>. This is a piddle which specifies which coordinates to include in
#pod the calculations. Its values are either C<0> or C<1>, where values of C<1>
#pod indicate coordinates to be included.  It defaults to a piddle of all C<1>'s.
#pod
#pod When used with C<coords>, C<mask> must be a piddle of shape I<M>,
#pod where I<M> is the number of data elements in C<coords>.
#pod
#pod If C<coords> is not specified, C<mask> should have the same shape as
#pod C<weight>.
#pod
#pod =item C<save_mask> => I<boolean>
#pod
#pod If true, the mask used in the final iteration will be returned
#pod in the iteration result object.
#pod
#pod =item C<save_weight> => I<boolean>
#pod
#pod If true, the weights used in the final iteration will be returned
#pod in the iteration result object.
#pod
#pod =item C<nsigma> => I<scalar>
#pod
#pod The size of the clipping radius, in units of the standard deviation.
#pod
#pod =item C<weight> => I<piddle>
#pod
#pod I<Optional>. Data weights. When used with C<coords>, C<weight> must be
#pod a piddle of shape I<M>, where I<M> is the number of data elements in
#pod C<coords>. If C<coords> is not specified, C<weight> is a piddle of
#pod shape I<NxM>, where I<N> is the number of dimensions in the data and
#pod I<M> is the number of data elements.
#pod
#pod It defaults to a piddle of all C<1>'s.
#pod
#pod =back
#pod
#pod =head3 Sigma Clip Results
#pod
#pod B<sigma_clip> returns an object which includes all of the attributes
#pod from the final iteration object (See L</Sigma Clip Iterations> ), with
#pod the following additional attributes/methods:
#pod
#pod =over
#pod
#pod =item C<iterations> => I<arrayref>
#pod
#pod An array of results objects for each iteration.
#pod
#pod =item C<success> => I<boolean>
#pod
#pod True if the iteration converged, false otherwise.
#pod
#pod =item C<error> => I<error object>
#pod
#pod If convergence has failed, this will contain an error object
#pod describing the failure.  See L</Errors>.
#pod
#pod =item C<mask> => I<piddle>
#pod
#pod If the C<$save_mask> option is true, this will be the final
#pod inclusion mask.
#pod
#pod =item C<weight> => I<piddle>
#pod
#pod If the C<$save_weight> option is true, this will be the final
#pod weights.
#pod
#pod =back
#pod
#pod =head4 Sigma Clip Iterations
#pod
#pod The results for each iteration are stored in an object with the
#pod following attributes/methods:
#pod
#pod =over
#pod
#pod =item C<center> => I<piddle|undef>
#pod
#pod A 1D piddle containing the derived center.  The value for the last
#pod iteration will be undefined if all of the elements have been clipped.
#pod
#pod =item C<iter> => I<integer>
#pod
#pod The iteration index.  An index of C<0> indicates the values determined
#pod before the iterative loop was entered, and reflects the initial
#pod clipping and mask exclusion.
#pod
#pod =item C<nelem> => I<integer>
#pod
#pod The number of data elements used in the center.
#pod
#pod =item C<total_weight> => I<number>
#pod
#pod The combined weight of the data elements used to determine the center.
#pod
#pod =item C<sigma> => I<number|undef>
#pod
#pod The standard deviation of the clipped data.  The value for the last
#pod iteration will be undefined if all of the elements have been clipped.
#pod
#pod =item C<clip> => I<number|undef>
#pod
#pod The clipping radius.  This will be undefined for the first iteration
#pod if the C<clip> option was not specified.
#pod
#pod =item C<dist> => I<number>
#pod
#pod I<Optional>. The distance between the previous and current centers. This is defined
#pod only if the C<dtol> option was passed.
#pod
#pod =back
#pod
#pod
#pod =cut

use Hash::Wrap ( {
    -as     => 'new_iteration',
    -create => 1,
    -class  => 'PDL::Algorithm::Center::Iteration',
    -clone  => sub {
        my $hash = shift;

        return {
            map {
                my $value = $hash->{$_};
                $value = $value->copy if $value->$_isa( 'PDL' );
                ( $_, $value )
            } keys %$hash
        };
    },
  },
  {
    -as     => 'return_iterate_results',
    -class  => 'PDL::Algorithm::Center::Iterate::Results',
    -create => 1,
  } );


sub sigma_clip {

    state $check = compile_named(
        center      => Optional [ ArrayRef [ Num | Undef ] | Center | CodeRef ],
        clip        => Optional [PositiveNum],
        coords      => Optional [Coords],
        dtol        => PositiveNum,
        iterlim     => Optional [PositiveInt],
        log         => Optional [ Bool | CodeRef ],
        mask        => Optional [ Undef | Piddle_min1D_ne ],
        save_mask   => Optional [Bool],
        save_weight => Optional [Bool],
        nsigma      => PositiveNum,
        weight      => Optional [ Undef | Piddle_min1D_ne ],
    );

    my $opt;
    my @argv = @_;
    try {
        my %opt = %{ $check->( @argv ); };
        $opt = wrap_hash( \%opt );
    }
      catch {
          parameter_failure->throw( $_ );
      };

    $opt->{iterlim} //= 10;

    if ( defined $opt->{log} && !is_coderef( $opt->log ) ) {
        $opt->{log} = $opt->log ? \&_sigma_clip_log_iteration : undef;
    }

    #---------------------------------------------------------------

    # now, see what kind of data we have, and ensure that all dimensions
    # are consistent

    if ( defined $opt->{coords} ) {

        for my $name ( 'mask', 'weight' ) {

            my $value = $opt->{$name};
            next unless defined $value;

            parameter_failure->throw(
                "<$name> must be a 1D piddle if <coords> is specified" )
              if $value->ndims != 1;

            my $nelem_c = $value->getdim( -1 );
            my $nelem_p = $opt->coords->getdim( -1 );

            parameter_failure->throw(
                "number of elements in <$name> ($nelem_p) ) must be the same as in <coords> ($nelem_c)"
            ) if $nelem_c != $nelem_p;
        }

    }

    elsif ( defined $opt->{weight} ) {

        $opt->{coords} = $opt->weight->ndcoords( PDL::indx );

        if ( defined $opt->{mask} ) {
            parameter_failure->throw( "mask must have same shape as weight\n" )
              if $opt->mask->shape != $opt->weight->shape;

            $opt->mask( $opt->mask->flat );
        }

        $opt->weight( $opt->weight->flat );
    }

    else {

        parameter_failure->throw( "must specify one of <coords> or <weight>" );
    }


    my ( $ndims ) = $opt->coords->dims;


    if ( defined $opt->{center} && is_arrayref( $opt->center ) ) {

        my $icenter = PDL->pdl( @{ $opt->center } );

        parameter_failure->throw( "<center> must have $ndims elements" )
          unless $icenter->nelem == $ndims;

        my $defined = PDL->pdl( map { defined } @{ $opt->center } );

        if ( $defined->not->any ) {

            $icenter = $icenter->where( $defined )->sever;

            $opt->{center} = sub {

                my ( $coords, $wmask, $weight ) = @_;
                my $center = _weighted_mean_center( $coords, $wmask, $weight );
                $center->where( $defined ) .= $icenter;

                return $center;
            };
        }
    }
    else {

        $opt->{center} //= \&_weighted_mean_center;
    }


    my $nsigma = delete $opt->{nsigma};
    $opt->{calc_wmask} //= sub {
        _sigma_clip_calc_wmask( $nsigma, @_ );
        return;
    };

    $opt->{calc_center} //= sub {
        my ( $coords, $mask, $weight, $iter ) = @_;

        _weighted_mean_center( $coords, $mask, $weight, $iter->total_weight );
    };

    my ( $clip, $dtol ) = delete @{$opt}{ 'clip', 'dtol' };
    $opt->{initialize} = sub {
        _sigma_clip_initialize( $clip, $dtol, @_ );
    };

    $opt->{is_converged} = sub {
        _sigma_clip_is_converged( $clip, $dtol, @_ );
    };

    delete @{$opt}{ grep { !defined $opt->{$_} } keys %$opt };


    iterate( %$opt );
}


#pod =sub iterate
#pod
#pod   $result = iterate(
#pod     center       => Center | CodeRef,
#pod     initialize   => CodeRef,
#pod     calc_center  => CodeRef,
#pod     calc_wmask   => CodeRef,
#pod     is_converged => CodeRef,
#pod     coords       => Coords,
#pod     iterlim      => PositiveInt,
#pod     log          => Optional [CodeRef],
#pod     mask         => Optional [Piddle1D_ne],
#pod     save_mask    => Optional [Bool],
#pod     save_weight  => Optional [Bool],
#pod     weight       => Optional [Piddle1D_ne],
#pod   );
#pod
#pod A generic iteration loop for centering data using callbacks for
#pod calculating centers, included element masks, weight, and iteration completion.
#pod
#pod A L<PDL::Algorithm::Center::Failure::parameter> exception will be
#pod thrown if there is a parameter error.
#pod
#pod =head3 Options
#pod
#pod The following options are accepted:
#pod
#pod =over
#pod
#pod =item C<center> => I<Piddle1D_ne | coderef >
#pod
#pod The initial center.  It may either be a piddle with shape I<N> (or
#pod something that can be coerced into one, see L</TYPES>) or a coderef
#pod which will return the center as a piddle with shape I<N>.  The coderef
#pod is called as
#pod
#pod   $initial_center = &$center( $coords, $mask, $weight, $total_weight );
#pod
#pod with
#pod
#pod =over
#pod
#pod =item C<$coords>
#pod
#pod A piddle with shape I<NxM> containing I<M> coordinates with dimension I<N>
#pod
#pod =item C<$mask>
#pod
#pod A piddle with shape I<M>, essentially a flattened copy of the initial C<$mask> option to L</iterate>.
#pod
#pod =item C<$weight>
#pod
#pod A piddle with shape I<M>, essentially a copy of the initial C<$weight> option to L</iterate>.
#pod
#pod =item C<$total_weight>
#pod
#pod A scalar which is the sum of C<$mask * $weight>.
#pod
#pod =back
#pod
#pod =item C<initialize> => I<coderef>
#pod
#pod This subroutine provides initialization prior to entering the
#pod iteration loop.  It should initialize the passed iteration object and
#pod work storage.
#pod
#pod It is invoked as:
#pod
#pod   &$initialize( $coords, $mask, $weight, $current, $work );
#pod
#pod with
#pod
#pod =over
#pod
#pod =item C<$coords>
#pod
#pod A piddle of shape I<NxM> with the coordinates of each element
#pod
#pod =item C<$mask>
#pod
#pod A piddle with shape I<M>, essentially a flattened copy of the initial C<$mask> option to L</iterate>.
#pod
#pod =item C<$weight>
#pod
#pod A piddle with shape I<M>, essentially a copy of the initial C<$weight> option to L</iterate>.
#pod
#pod =item C<$current>
#pod
#pod a reference to a L<Hash::Wrap> based object containing data for the
#pod current iteration.  C<initialize> may augment the underlying hash with
#pod its own data (but see L</Work Space>). The following attributes
#pod are provided by C<iterate>:
#pod
#pod =over
#pod
#pod =item C<nelem>
#pod
#pod The number of included coordinates, C<$mask->sum>.
#pod
#pod =item C<total_weight>
#pod
#pod The sum of the weights of the included coordinates, C<< ($mask * $weight)->dsum >>.
#pod
#pod =back
#pod
#pod =item C<$work>
#pod
#pod A hashref which  may use to store temporary data (e.g. work
#pod piddles) which will be available to all of the callback routines.
#pod
#pod =back
#pod
#pod =item C<calc_center> => I<coderef>
#pod
#pod This subroutine should return a piddle of shape I<N> with the
#pod calculated center.
#pod
#pod It will be called as:
#pod
#pod   $center = &$calc_center( $coords, $mask, $weight, $current, $work );
#pod
#pod with
#pod
#pod =over
#pod
#pod =item C<$coords>
#pod
#pod A piddle of shape I<NxM> with the coordinates of each element
#pod
#pod =item C<$mask>
#pod
#pod A piddle with shape I<M> containing the current inclusion mask.
#pod
#pod =item C<$weight>
#pod
#pod A piddle with shape I<M> containing the current weights for the included coordinates.
#pod
#pod =item C<$current>
#pod
#pod A reference to a L<Hash::Wrap> based object containing
#pod data for the current iteration.
#pod
#pod C<calc_center> may augment the underlying hash with its own data (but
#pod see L</Iteration Objects>). The following attributes are provided by
#pod C<iterate>:
#pod
#pod =over
#pod
#pod =item C<nelem>
#pod
#pod The number of included coordinates, C<< $mask->sum >>.
#pod
#pod =item C<total_weight>
#pod
#pod The sum of the weights of the included coordinates, C<< ($mask*$weight)->dsum) >>.
#pod
#pod =back
#pod
#pod =item C<$work>
#pod
#pod A hashref which  may use to store temporary data (e.g. work
#pod piddles) which will be available to all of the callback routines.
#pod
#pod =back
#pod
#pod =item C<calc_wmask> => I<coderef>
#pod
#pod This subroutine should determine the current set of included
#pod coordinates and their current weights.
#pod
#pod It will be called as:
#pod
#pod   &$calc_mask( $coords, $mask, $weight, $current, $work );
#pod
#pod with
#pod
#pod =over
#pod
#pod =item C<$coords>
#pod
#pod A piddle of shape I<NxM> with the coordinates of each element
#pod
#pod =item C<$mask>
#pod
#pod A piddle with shape I<M>, essentially a flattened copy of the initial
#pod C<$mask> option to L</iterate>.  Any changes to it will be discarded
#pod at the end of the iteration.  Be sure to update C<< $current->nelem >>
#pod if this is changed.
#pod
#pod =item C<$weight>
#pod
#pod A piddle with shape I<M>, essentially a flattened copy of the initial
#pod C<$mask> option to L</iterate>.  Any changes to it will be discarded
#pod at the end of the iteration.  Be sure to update C<< $current->total_weight
#pod >> if this is changed.
#pod
#pod =item C<$current>
#pod
#pod A reference to a L<Hash::Wrap> based object containing data for the
#pod current iteration.
#pod
#pod C<calc_center> may augment the underlying hash with its own data (but
#pod see L</Work Space>). The following attributes are provided by
#pod C<iterate>:
#pod
#pod =over
#pod
#pod =item C<nelem>
#pod
#pod The number of included coordinates, C<< $mask->sum >>.  If
#pod C<$mask> is changed this must either be updated or set to the
#pod undefined value.
#pod
#pod =item C<total_weight>
#pod
#pod The sum of the weights of the included coordinates, C<< ($mask *
#pod $weight)->dsum >>.  If C<$weight> is changed this must either be
#pod updated or set to the undefined value.
#pod
#pod =back
#pod
#pod =item C<$work>
#pod
#pod A hashref which  may use to store temporary data (e.g. work
#pod piddles) which will be available to all of the callback routines.
#pod
#pod =back
#pod
#pod =item C<is_converged> => I<coderef>
#pod
#pod This subroutine should return a boolean value indicating whether the
#pod iteration has converged.
#pod
#pod It is invoked as:
#pod
#pod   $bool = &$is_converged( $coords, $mask, $weight, $last, $current, $work );
#pod
#pod with
#pod
#pod =over
#pod
#pod =item C<$coords>
#pod
#pod A piddle of shape I<NxM> with the coordinates of each element
#pod
#pod =item C<$mask>
#pod
#pod A piddle with shape I<M> containing the current inclusion mask.
#pod
#pod =item C<$weight>
#pod
#pod A piddle with shape I<M> containing the current weights for the included coordinates.
#pod
#pod =item C<$last>
#pod
#pod A reference to a L<Hash::Wrap> based object containing data for the
#pod previous iteration.  C<is_converged> may augment the underlying hash
#pod with its own data (but see L</Work Space>). The following
#pod attributes are provided by C<iterate>:
#pod
#pod =over
#pod
#pod =item C<nelem>
#pod
#pod The number of included coordinates.
#pod
#pod =item C<total_weight>
#pod
#pod The sum of the weights of the included coordinates.
#pod
#pod =back
#pod
#pod =item C<$current>
#pod
#pod A reference to a L<Hash::Wrap> based object containing data for the
#pod current iteration, with attributes as described above for C<$last>
#pod
#pod =item C<$work>
#pod
#pod A hashref which  may use to store temporary data (e.g. work
#pod piddles) which will be available to all of the callback routines.
#pod
#pod =back
#pod
#pod The C<is_converged> routine is passed references to the B<actual>
#pod objects used by B<sigma_clip> to keep track of the iterations.  This
#pod means that the C<is_converged> routine may manipulate the starting
#pod point for the next iteration by altering its C<$current> parameter.
#pod
#pod C<is_converged> is called prior to entering the iteration loop with
#pod C<$last> set to C<undef>.  This allows priming the C<$current> structure,
#pod which will be used as C<$last> in the first iteration.
#pod
#pod =item C<coords> => I<Coords>
#pod
#pod The coordinates to center.  C<coords> is a piddle of
#pod shape I<NxM> (or anything which can be coerced into it, see
#pod L</TYPES>) where I<N> is the number of dimensions in the data and
#pod I<M> is the number of data elements.
#pod
#pod =item C<iterlim>
#pod
#pod A positive integer specifying the maximum number of iterations.
#pod
#pod =item C<log> => I<coderef>
#pod
#pod I<Optional>. A subroutine which will be called
#pod
#pod =over
#pod
#pod =item between the call to C<initialize> and the start of the first iteration
#pod
#pod =item at the end of each iteration
#pod
#pod =back
#pod
#pod It is invoked as
#pod
#pod   &$log( $iteration );
#pod
#pod where C<$iteration> is a I<copy> of the current iteration object.  The object will
#pod have at least the following fields:
#pod
#pod =over
#pod
#pod =item C<center> => I<piddle|undef>
#pod
#pod A piddle of shape I<N> containing the derived center.  The value for
#pod the last iteration will be undefined if all of the elements have been
#pod clipped.
#pod
#pod =item C<iter>
#pod
#pod The iteration index
#pod
#pod =item C<nelem>
#pod
#pod The number of included coordinates.
#pod
#pod =item C<total_weight>
#pod
#pod The summed weight of the included coordinates.
#pod
#pod =back
#pod
#pod There may be other attributes added by the various callbacks
#pod (C<calc_wmask>, C<calc_center>, C<is_converged>). See for example,
#pod L</Sigma Clip Iterations>.
#pod
#pod =item C<mask> => I<piddle>
#pod
#pod I<Optional>. This is a piddle which specifies which coordinates to include in
#pod the calculations. Its values are either C<0> or C<1>, where values of C<1>
#pod indicate coordinates to be included.  It defaults to a piddle of all C<1>'s.
#pod
#pod When used with C<coords>, C<mask> must be a piddle of shape I<M>,
#pod where I<M> is the number of data elements in C<coords>.
#pod
#pod If C<coords> is not specified, C<mask> should have the same shape as
#pod C<weight>.
#pod
#pod =item C<save_mask> => I<boolean>
#pod
#pod If true, the mask used in the final iteration will be returned
#pod in the iteration result object.
#pod
#pod =item C<save_weight> => I<boolean>
#pod
#pod If true, the weights used in the final iteration will be returned
#pod in the iteration result object.
#pod
#pod =item C<weight> => I<piddle>
#pod
#pod I<Optional>. Data weights.  When used with C<coords>, C<weight> must
#pod be a piddle of shape I<M>, where I<M> is the number of data elements
#pod in C<coords>. If C<coords> is not specified, C<weight> is a piddle of
#pod shape I<NxM>, where I<N> is the number of dimensions in the data and
#pod I<M> is the number of data elements.
#pod
#pod It defaults to a piddle of all C<1>'s.
#pod
#pod =back
#pod
#pod Callbacks are provided with L<Hash::Wrap> based objects which contain
#pod the data for the current iteration.  They should add data to the
#pod objects underlying hash which records particulars about their specific
#pod operation,
#pod
#pod =head3 Work Space
#pod
#pod Callbacks are passed L<Hash::Wrap> based iteration objects and a
#pod reference to a C<$work> hash.  The iteration objects may have additional
#pod elements added to them (which will be available to the caller),
#pod but should refrain from storing unnecessary data there, as each
#pod new iteration's object is I<copied> from that for the previous iteration.
#pod
#pod Instead, use the passed C<$work> hash.  It is shared amongst the
#pod callbacks, so use it to store data which will not be returned to
#pod the caller.
#pod
#pod =head3 Results
#pod
#pod B<iterate> returns an object which includes all of the attributes
#pod from the final iteration object (See L</Iteration Object> ), with
#pod the following additional attributes/methods:
#pod
#pod =over
#pod
#pod =item C<iterations> => I<arrayref>
#pod
#pod An array of result objects for each iteration.
#pod
#pod =item C<success> => I<boolean>
#pod
#pod True if the iteration converged, false otherwise.
#pod
#pod =item C<error> => I<error object>
#pod
#pod If convergence has failed, this will contain an error object
#pod describing the failure.  See L</Errors>.
#pod
#pod =item C<mask> => I<piddle>
#pod
#pod If the C<$save_mask> option is true, this will be the final
#pod inclusion mask.
#pod
#pod =item C<weight> => I<piddle>
#pod
#pod If the C<$save_weight> option is true, this will be the final
#pod weights.
#pod
#pod =back
#pod
#pod The value of the C<center> attribute in the last iteration will be
#pod undefined if all of the elements have been clipped.
#pod
#pod =head4 Iteration Object
#pod
#pod The results for each iteration are stored in an object with the
#pod following attributes/methods (in addition to those added by the
#pod callbacks).
#pod
#pod =over
#pod
#pod =item C<center> => I<piddle|undef>
#pod
#pod A 1D piddle containing the derived center.  The value for the last
#pod iteration will be undefined if all of the elements have been clipped.
#pod
#pod =item C<iter> => I<integer>
#pod
#pod The iteration index.  An index of C<0> indicates the values determined
#pod before the iterative loop was entered, and reflects the initial
#pod clipping and mask exclusion.
#pod
#pod =item C<nelem> => I<integer>
#pod
#pod The number of data elements used in the center.
#pod
#pod =item C<total_weight> => I<number>
#pod
#pod The combined weight of the data elements used to determine the center.
#pod
#pod =back
#pod
#pod =head3 Iteration Steps
#pod
#pod Before the first iteration:
#pod
#pod =over
#pod
#pod =item 1
#pod
#pod Extract an initial center from C<center>.
#pod
#pod =item 2
#pod
#pod Create a new iteration object.
#pod
#pod =item 3
#pod
#pod Call C<initialize>.
#pod
#pod =item 4
#pod
#pod Call C<log>
#pod
#pod =back
#pod
#pod For each iteration:
#pod
#pod =over
#pod
#pod =item 1
#pod
#pod Creat a new iteration object by B<copying> the old one.
#pod
#pod =item 2
#pod
#pod Call C<calc_wmask>, with a copy of the initial mask and weights. C<calc_mask>
#pod should update (in place) at least one of them
#pod
#pod =item 3
#pod
#pod Update summed weight and number of elements if C<calc_wmask> sets them to C<undef>.
#pod
#pod =item 4
#pod
#pod Call C<calc_center> with the current mask and weights.
#pod
#pod =item 5
#pod
#pod Call C<is_converged> with the current mask and weights.
#pod
#pod =item 6
#pod
#pod Call C<log>
#pod
#pod =item 7
#pod
#pod Goto step 1 if not converged and iteration limit has not been reached.
#pod
#pod =back
#pod
#pod =cut

sub iterate {

    state $check = compile_named(
        center       => Center | CodeRef,
        initialize   => CodeRef,
        calc_center  => CodeRef,
        calc_wmask   => CodeRef,
        is_converged => CodeRef,
        coords       => Coords,
        iterlim      => PositiveInt,
        log          => Optional [CodeRef],
        mask         => Optional [Piddle1D_ne],
        weight       => Optional [Piddle1D_ne],
        save_mask    => Optional [Bool],
        save_weight  => Optional [Bool],
    );

    my $opt = wrap_hash( $check->( @_ ) );

    $opt->{log}         //= undef;
    $opt->{save_mask}   //= 0;
    $opt->{save_weight} //= 0;
    $opt->{mask}        //= undef;
    $opt->{weight}      //= undef;

    my ( $ndims, $nelem ) = $opt->coords->dims;

    parameter_failure->throw( "<$_> must have $nelem elements" )
      for grep { defined $opt->{$_} && $opt->{$_}->nelem != $nelem }
      qw[ mask weight ];

    $opt->weight(
        defined $opt->weight
        ? PDL::convert( $opt->weight, PDL::double )
        : PDL->ones( PDL::double, $nelem ),
    );

    my $total_weight;

    if ( defined $opt->mask ) {
        $nelem = $opt->mask->sum;
        $total_weight = ( $opt->mask * $opt->weight )->dsum;
    }
    else {
        $opt->mask( PDL->ones( PDL::long, $nelem ) );
        $total_weight = $opt->weight->dsum;
    }


    my $mask   = $opt->mask->copy;
    my $weight = $opt->weight->copy;

    $opt->center(
        $opt->center->( $opt->coords, $mask, $weight, $total_weight ) )
      if is_coderef( $opt->center );

    parameter_failure->throw(
        "<center> must be a 1D piddle with $ndims elements" )
      unless is_Piddle1D( $opt->center ) && $opt->center->nelem == $ndims;



    #############################################################################

    # Iterate until convergence.

    my @iteration;

    my $work   = {};

    # Set up initial state

    push @iteration,
      new_iteration( {
          center       => $opt->center,
          total_weight => $total_weight,
          nelem        => $nelem,
          iter         => 0,
      } );

    $mask   .= $opt->mask;
    $weight .= $opt->weight;


    my $iteration = 0;
    my $converged;

    eval {

        $opt->initialize->( $opt->coords, $mask, $weight, $iteration[-1], $work );

        $opt->log && $opt->log->( new_iteration( $iteration[-1] ) );

        while ( !$converged && ++$iteration <= $opt->iterlim ) {

            my $last = $iteration[-1];

            my $current = new_iteration( $last );
            push @iteration, $current;

            ++$current->{iter};

            $current->total_weight( $total_weight );
            $current->nelem( $nelem );

            $mask   .= $opt->mask;
            $weight .= $opt->weight;

            $opt->calc_wmask->( $opt->coords, $mask, $weight, $current, $work );

            $current->total_weight( ( $mask * $weight ) ->dsum ) unless defined $current->total_weight;
            $current->nelem( $mask->sum )
              unless defined $current->nelem;

            iteration_empty_failure->throw( "no elements left after clip" )
              if $current->nelem == 0;

            $current->center(
                $opt->calc_center->( $opt->coords, $mask, $weight, $current, $work ) );

            $converged = $opt->is_converged->(
                $opt->coords, $mask, $weight, $last, $current, $work
            );

            $opt->log && $opt->log->( new_iteration( $current ) );
        }

    };

    my $error = $@;

    $error
      = iteration_limit_reached_failure->new(
        msg => "iteration limit (@{[ $opt->iterlim ]}) reached" )
      if $iteration > $opt->iterlim;

    return_iterate_results( {
        %{ $iteration[-1] },
        ( $opt->save_mask ? ( mask => $mask ) : () ),
        ( $opt->save_weight ? ( weight => $weight ) : () ),
        iterations => \@iteration,
        success    => !$error,
        error      => $error
    } );
}




1;

#
# This file is part of PDL-Algorithm-Center
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

=pod

=head1 NAME

PDL::Algorithm::Center - Various methods of finding the center of a sample

=head1 VERSION

version 0.06

=head1 DESCRIPTION

C<PDL::Algorithm::Center> is a collection of algorithms which
specialize in centering datasets.

=head1 SUBROUTINES

See L</TYPES> for information on the types used in the subroutine descriptions.

=head2 sigma_clip

  $results = sigma_clip(
      center      => Optional [ Center | CodeRef ],
      clip        => Optional [PositiveNum],
      coords      => Optional [Coords],
      dtol        => PositiveNum,
      iterlim     => Optional [PositiveInt],
      log         => Optional [Bool | CodeRef],
      mask        => Optional [ Undef | Piddle_min1D_ne ],
      save_mask   => Optional [Bool],
      save_weight => Optional [Bool],
      nsigma      => PositiveNum,
      weight      => Optional [ Undef | Piddle_min1D_ne ],
  );

Center a dataset by iteratively excluding data outside of a radius
equal to a specified number of standard deviations. The dataset may be
specified as a list of coordinates and optional weights, or as a
weight piddle of shape I<NxM> (e.g., an image).  If only the weight
piddle is provided, it is converted internally into a list of
coordinates with associated weights.

To operate on a subset of the input data, specify the C<mask> option.

A L<PDL::Algorithm::Center::Failure::parameter> exception will be
thrown if there is a parameter error.

The center of a data set is determined by:

=over

=item 1

clipping (ignoring) the data whose distance to the current center is
greater than a specified number of standard deviations

=item 2

calculating a new center by performing a (weighted) centroid of the
remaining data

=item 3

calculating the standard deviation of the distance from the remaining
data to the center

=item 4

repeat step 1 until either a convergence tolerance has been met or
the iteration limit has been exceeded

=back

The initial center may be explicitly specified,  or may be calculated
by performing a (weighted) centroid of the data.

The initial standard deviation is calculated using the initial center and either
the entire dataset, or from a clipped region about the initial center.

=head3 Options

The following options are available:

=over

=item C<center> => I<ArrayRef | Piddle1D_ne | coderef >

The initial center.  It may be

=over

=item *

An array of length I<N>

The array may contain undefined values for each dimension for which the center should
be determined by finding the mean of the values in that dimension.

=item *

A piddle with shape I<N>  (or
something that can be coerced into one, see L</TYPES>),

=item *

A coderef which will return the center as a piddle with shape I<N>.
The subroutine is called as

  &$center( $coords, $mask, $weight, $total_weight );

with

=over

=item C<$coords>

A piddle with shape I<NxM> containing I<M> coordinates with dimension I<N>

=item C<$mask>

A piddle with shape I<M>, essentially a flattened copy of the initial C<$mask> option to L</iterate>.

=item C<$weight>

A piddle with shape I<M>, essentially a copy of the initial C<$weight> option to L</iterate>.

=item C<$total_weight>

A scalar which is the sum of  C<$mask * $weight>

=back

=back

=item C<clip> => I<positive number>

I<Optional>.  The clipping radius used to determine the initial standard deviation.

=item C<coords> => I<Coords>

I<Optional>.  The coordinates to center.  C<coords> is a piddle of
shape I<NxM> (or anything which can be coerced into it, see
L</TYPES>) where I<N> is the number of dimensions in the data and
I<M> is the number of data elements.

C<weight> may be specified with coords to indicate weighted data.

C<mask> may be specified to indicate that a subset of the coordinates
should be operated on.

C<coords> is useful if the data cube is not fully populated; for dense
data, use C<weight> I<instead>.

=item C<dtol> => I<positive number>

I<Optional>.  If specified iteration will cease when successive centers are closer
than the specified distance.

=item C<iterlim> => I<positive integer>

I<Optional>. The maximum number of iterations to run.  Defaults to 10.

=item C<log> => I<boolean|coderef>

I<Optional>.

If C<log> is true (and not a I<coderef>), a default logger which outputs
to B<STDOUT> will be used.

If a I<coderef> it will be called before the first iteration and at
the end of each iteration. It is passed a copy of the current
iteration's results object; see L</Sigma Clip Iteration Results>.

=item C<mask> => I<piddle>

I<Optional>. This is a piddle which specifies which coordinates to include in
the calculations. Its values are either C<0> or C<1>, where values of C<1>
indicate coordinates to be included.  It defaults to a piddle of all C<1>'s.

When used with C<coords>, C<mask> must be a piddle of shape I<M>,
where I<M> is the number of data elements in C<coords>.

If C<coords> is not specified, C<mask> should have the same shape as
C<weight>.

=item C<save_mask> => I<boolean>

If true, the mask used in the final iteration will be returned
in the iteration result object.

=item C<save_weight> => I<boolean>

If true, the weights used in the final iteration will be returned
in the iteration result object.

=item C<nsigma> => I<scalar>

The size of the clipping radius, in units of the standard deviation.

=item C<weight> => I<piddle>

I<Optional>. Data weights. When used with C<coords>, C<weight> must be
a piddle of shape I<M>, where I<M> is the number of data elements in
C<coords>. If C<coords> is not specified, C<weight> is a piddle of
shape I<NxM>, where I<N> is the number of dimensions in the data and
I<M> is the number of data elements.

It defaults to a piddle of all C<1>'s.

=back

=head3 Sigma Clip Results

B<sigma_clip> returns an object which includes all of the attributes
from the final iteration object (See L</Sigma Clip Iterations> ), with
the following additional attributes/methods:

=over

=item C<iterations> => I<arrayref>

An array of results objects for each iteration.

=item C<success> => I<boolean>

True if the iteration converged, false otherwise.

=item C<error> => I<error object>

If convergence has failed, this will contain an error object
describing the failure.  See L</Errors>.

=item C<mask> => I<piddle>

If the C<$save_mask> option is true, this will be the final
inclusion mask.

=item C<weight> => I<piddle>

If the C<$save_weight> option is true, this will be the final
weights.

=back

=head4 Sigma Clip Iterations

The results for each iteration are stored in an object with the
following attributes/methods:

=over

=item C<center> => I<piddle|undef>

A 1D piddle containing the derived center.  The value for the last
iteration will be undefined if all of the elements have been clipped.

=item C<iter> => I<integer>

The iteration index.  An index of C<0> indicates the values determined
before the iterative loop was entered, and reflects the initial
clipping and mask exclusion.

=item C<nelem> => I<integer>

The number of data elements used in the center.

=item C<total_weight> => I<number>

The combined weight of the data elements used to determine the center.

=item C<sigma> => I<number|undef>

The standard deviation of the clipped data.  The value for the last
iteration will be undefined if all of the elements have been clipped.

=item C<clip> => I<number|undef>

The clipping radius.  This will be undefined for the first iteration
if the C<clip> option was not specified.

=item C<dist> => I<number>

I<Optional>. The distance between the previous and current centers. This is defined
only if the C<dtol> option was passed.

=back

=head2 iterate

  $result = iterate(
    center       => Center | CodeRef,
    initialize   => CodeRef,
    calc_center  => CodeRef,
    calc_wmask   => CodeRef,
    is_converged => CodeRef,
    coords       => Coords,
    iterlim      => PositiveInt,
    log          => Optional [CodeRef],
    mask         => Optional [Piddle1D_ne],
    save_mask    => Optional [Bool],
    save_weight  => Optional [Bool],
    weight       => Optional [Piddle1D_ne],
  );

A generic iteration loop for centering data using callbacks for
calculating centers, included element masks, weight, and iteration completion.

A L<PDL::Algorithm::Center::Failure::parameter> exception will be
thrown if there is a parameter error.

=head3 Options

The following options are accepted:

=over

=item C<center> => I<Piddle1D_ne | coderef >

The initial center.  It may either be a piddle with shape I<N> (or
something that can be coerced into one, see L</TYPES>) or a coderef
which will return the center as a piddle with shape I<N>.  The coderef
is called as

  $initial_center = &$center( $coords, $mask, $weight, $total_weight );

with

=over

=item C<$coords>

A piddle with shape I<NxM> containing I<M> coordinates with dimension I<N>

=item C<$mask>

A piddle with shape I<M>, essentially a flattened copy of the initial C<$mask> option to L</iterate>.

=item C<$weight>

A piddle with shape I<M>, essentially a copy of the initial C<$weight> option to L</iterate>.

=item C<$total_weight>

A scalar which is the sum of C<$mask * $weight>.

=back

=item C<initialize> => I<coderef>

This subroutine provides initialization prior to entering the
iteration loop.  It should initialize the passed iteration object and
work storage.

It is invoked as:

  &$initialize( $coords, $mask, $weight, $current, $work );

with

=over

=item C<$coords>

A piddle of shape I<NxM> with the coordinates of each element

=item C<$mask>

A piddle with shape I<M>, essentially a flattened copy of the initial C<$mask> option to L</iterate>.

=item C<$weight>

A piddle with shape I<M>, essentially a copy of the initial C<$weight> option to L</iterate>.

=item C<$current>

a reference to a L<Hash::Wrap> based object containing data for the
current iteration.  C<initialize> may augment the underlying hash with
its own data (but see L</Work Space>). The following attributes
are provided by C<iterate>:

=over

=item C<nelem>

The number of included coordinates, C<$mask->sum>.

=item C<total_weight>

The sum of the weights of the included coordinates, C<< ($mask * $weight)->dsum >>.

=back

=item C<$work>

A hashref which  may use to store temporary data (e.g. work
piddles) which will be available to all of the callback routines.

=back

=item C<calc_center> => I<coderef>

This subroutine should return a piddle of shape I<N> with the
calculated center.

It will be called as:

  $center = &$calc_center( $coords, $mask, $weight, $current, $work );

with

=over

=item C<$coords>

A piddle of shape I<NxM> with the coordinates of each element

=item C<$mask>

A piddle with shape I<M> containing the current inclusion mask.

=item C<$weight>

A piddle with shape I<M> containing the current weights for the included coordinates.

=item C<$current>

A reference to a L<Hash::Wrap> based object containing
data for the current iteration.

C<calc_center> may augment the underlying hash with its own data (but
see L</Iteration Objects>). The following attributes are provided by
C<iterate>:

=over

=item C<nelem>

The number of included coordinates, C<< $mask->sum >>.

=item C<total_weight>

The sum of the weights of the included coordinates, C<< ($mask*$weight)->dsum) >>.

=back

=item C<$work>

A hashref which  may use to store temporary data (e.g. work
piddles) which will be available to all of the callback routines.

=back

=item C<calc_wmask> => I<coderef>

This subroutine should determine the current set of included
coordinates and their current weights.

It will be called as:

  &$calc_mask( $coords, $mask, $weight, $current, $work );

with

=over

=item C<$coords>

A piddle of shape I<NxM> with the coordinates of each element

=item C<$mask>

A piddle with shape I<M>, essentially a flattened copy of the initial
C<$mask> option to L</iterate>.  Any changes to it will be discarded
at the end of the iteration.  Be sure to update C<< $current->nelem >>
if this is changed.

=item C<$weight>

A piddle with shape I<M>, essentially a flattened copy of the initial
C<$mask> option to L</iterate>.  Any changes to it will be discarded
at the end of the iteration.  Be sure to update C<< $current->total_weight
>> if this is changed.

=item C<$current>

A reference to a L<Hash::Wrap> based object containing data for the
current iteration.

C<calc_center> may augment the underlying hash with its own data (but
see L</Work Space>). The following attributes are provided by
C<iterate>:

=over

=item C<nelem>

The number of included coordinates, C<< $mask->sum >>.  If
C<$mask> is changed this must either be updated or set to the
undefined value.

=item C<total_weight>

The sum of the weights of the included coordinates, C<< ($mask *
$weight)->dsum >>.  If C<$weight> is changed this must either be
updated or set to the undefined value.

=back

=item C<$work>

A hashref which  may use to store temporary data (e.g. work
piddles) which will be available to all of the callback routines.

=back

=item C<is_converged> => I<coderef>

This subroutine should return a boolean value indicating whether the
iteration has converged.

It is invoked as:

  $bool = &$is_converged( $coords, $mask, $weight, $last, $current, $work );

with

=over

=item C<$coords>

A piddle of shape I<NxM> with the coordinates of each element

=item C<$mask>

A piddle with shape I<M> containing the current inclusion mask.

=item C<$weight>

A piddle with shape I<M> containing the current weights for the included coordinates.

=item C<$last>

A reference to a L<Hash::Wrap> based object containing data for the
previous iteration.  C<is_converged> may augment the underlying hash
with its own data (but see L</Work Space>). The following
attributes are provided by C<iterate>:

=over

=item C<nelem>

The number of included coordinates.

=item C<total_weight>

The sum of the weights of the included coordinates.

=back

=item C<$current>

A reference to a L<Hash::Wrap> based object containing data for the
current iteration, with attributes as described above for C<$last>

=item C<$work>

A hashref which  may use to store temporary data (e.g. work
piddles) which will be available to all of the callback routines.

=back

The C<is_converged> routine is passed references to the B<actual>
objects used by B<sigma_clip> to keep track of the iterations.  This
means that the C<is_converged> routine may manipulate the starting
point for the next iteration by altering its C<$current> parameter.

C<is_converged> is called prior to entering the iteration loop with
C<$last> set to C<undef>.  This allows priming the C<$current> structure,
which will be used as C<$last> in the first iteration.

=item C<coords> => I<Coords>

The coordinates to center.  C<coords> is a piddle of
shape I<NxM> (or anything which can be coerced into it, see
L</TYPES>) where I<N> is the number of dimensions in the data and
I<M> is the number of data elements.

=item C<iterlim>

A positive integer specifying the maximum number of iterations.

=item C<log> => I<coderef>

I<Optional>. A subroutine which will be called

=over

=item between the call to C<initialize> and the start of the first iteration

=item at the end of each iteration

=back

It is invoked as

  &$log( $iteration );

where C<$iteration> is a I<copy> of the current iteration object.  The object will
have at least the following fields:

=over

=item C<center> => I<piddle|undef>

A piddle of shape I<N> containing the derived center.  The value for
the last iteration will be undefined if all of the elements have been
clipped.

=item C<iter>

The iteration index

=item C<nelem>

The number of included coordinates.

=item C<total_weight>

The summed weight of the included coordinates.

=back

There may be other attributes added by the various callbacks
(C<calc_wmask>, C<calc_center>, C<is_converged>). See for example,
L</Sigma Clip Iterations>.

=item C<mask> => I<piddle>

I<Optional>. This is a piddle which specifies which coordinates to include in
the calculations. Its values are either C<0> or C<1>, where values of C<1>
indicate coordinates to be included.  It defaults to a piddle of all C<1>'s.

When used with C<coords>, C<mask> must be a piddle of shape I<M>,
where I<M> is the number of data elements in C<coords>.

If C<coords> is not specified, C<mask> should have the same shape as
C<weight>.

=item C<save_mask> => I<boolean>

If true, the mask used in the final iteration will be returned
in the iteration result object.

=item C<save_weight> => I<boolean>

If true, the weights used in the final iteration will be returned
in the iteration result object.

=item C<weight> => I<piddle>

I<Optional>. Data weights.  When used with C<coords>, C<weight> must
be a piddle of shape I<M>, where I<M> is the number of data elements
in C<coords>. If C<coords> is not specified, C<weight> is a piddle of
shape I<NxM>, where I<N> is the number of dimensions in the data and
I<M> is the number of data elements.

It defaults to a piddle of all C<1>'s.

=back

Callbacks are provided with L<Hash::Wrap> based objects which contain
the data for the current iteration.  They should add data to the
objects underlying hash which records particulars about their specific
operation,

=head3 Work Space

Callbacks are passed L<Hash::Wrap> based iteration objects and a
reference to a C<$work> hash.  The iteration objects may have additional
elements added to them (which will be available to the caller),
but should refrain from storing unnecessary data there, as each
new iteration's object is I<copied> from that for the previous iteration.

Instead, use the passed C<$work> hash.  It is shared amongst the
callbacks, so use it to store data which will not be returned to
the caller.

=head3 Results

B<iterate> returns an object which includes all of the attributes
from the final iteration object (See L</Iteration Object> ), with
the following additional attributes/methods:

=over

=item C<iterations> => I<arrayref>

An array of result objects for each iteration.

=item C<success> => I<boolean>

True if the iteration converged, false otherwise.

=item C<error> => I<error object>

If convergence has failed, this will contain an error object
describing the failure.  See L</Errors>.

=item C<mask> => I<piddle>

If the C<$save_mask> option is true, this will be the final
inclusion mask.

=item C<weight> => I<piddle>

If the C<$save_weight> option is true, this will be the final
weights.

=back

The value of the C<center> attribute in the last iteration will be
undefined if all of the elements have been clipped.

=head4 Iteration Object

The results for each iteration are stored in an object with the
following attributes/methods (in addition to those added by the
callbacks).

=over

=item C<center> => I<piddle|undef>

A 1D piddle containing the derived center.  The value for the last
iteration will be undefined if all of the elements have been clipped.

=item C<iter> => I<integer>

The iteration index.  An index of C<0> indicates the values determined
before the iterative loop was entered, and reflects the initial
clipping and mask exclusion.

=item C<nelem> => I<integer>

The number of data elements used in the center.

=item C<total_weight> => I<number>

The combined weight of the data elements used to determine the center.

=back

=head3 Iteration Steps

Before the first iteration:

=over

=item 1

Extract an initial center from C<center>.

=item 2

Create a new iteration object.

=item 3

Call C<initialize>.

=item 4

Call C<log>

=back

For each iteration:

=over

=item 1

Creat a new iteration object by B<copying> the old one.

=item 2

Call C<calc_wmask>, with a copy of the initial mask and weights. C<calc_mask>
should update (in place) at least one of them

=item 3

Update summed weight and number of elements if C<calc_wmask> sets them to C<undef>.

=item 4

Call C<calc_center> with the current mask and weights.

=item 5

Call C<is_converged> with the current mask and weights.

=item 6

Call C<log>

=item 7

Goto step 1 if not converged and iteration limit has not been reached.

=back

=head1 TYPES

In the L<description of the subroutines|/Subroutines>, the following
types are specified:

=over

=item Center

This accepts a non-null, non-empty 1D piddle, or anything that can be converted
into one (for example, a scalar, a scalar piddle, or an array of numbers );

=item CodeRef

A code reference.

=item PositiveNum

A positive real number.

=item PositiveInt

A positive integer.

=item Coords

This accepts a non-null, non-empty 2D piddle, or anything that can be converted or
up-converted to it.

=item Piddle_min1D_ne

This accepts a non-null, non-empty piddle with a minimum of 1 dimension.

=item Piddle1D_ne

This accepts a non-null, non-empty 1D piddle.

=back

=head1 ERRORS

Errors are represented as objects in the following classes:

=over

=item Parameter Validation

These are unconditionally thrown as
L<PDL::Algorithm::Center::Failure::parameter> objects.

=item Iteration

These are stored in the result object's C<error> attribute.

  PDL::Algorithm::Center::Failure::iteration::limit_reached
  PDL::Algorithm::Center::Failure::iteration::empty

=back

The objects stringify to a failure message.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=PDL-Algorithm-Center>
or by email to
L<bug-PDL-Algorithm-Center@rt.cpan.org|mailto:bug-PDL-Algorithm-Center@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SOURCE

The development version is on github at L<https://github.com/djerius/pdl-algorithm-center>
and may be cloned from L<git://github.com/djerius/pdl-algorithm-center.git>

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<PDL::Algorithm::Center> is a collection of algorithms which
#pod specialize in centering datasets.
#pod
#pod
#pod =head1 SUBROUTINES
#pod
#pod See L</TYPES> for information on the types used in the subroutine descriptions.
#pod
#pod
#pod =head1 TYPES
#pod
#pod In the L<description of the subroutines|/Subroutines>, the following
#pod types are specified:
#pod
#pod =over
#pod
#pod =item Center
#pod
#pod This accepts a non-null, non-empty 1D piddle, or anything that can be converted
#pod into one (for example, a scalar, a scalar piddle, or an array of numbers );
#pod
#pod =item CodeRef
#pod
#pod A code reference.
#pod
#pod =item PositiveNum
#pod
#pod A positive real number.
#pod
#pod =item PositiveInt
#pod
#pod A positive integer.
#pod
#pod =item Coords
#pod
#pod This accepts a non-null, non-empty 2D piddle, or anything that can be converted or
#pod up-converted to it.
#pod
#pod =item Piddle_min1D_ne
#pod
#pod This accepts a non-null, non-empty piddle with a minimum of 1 dimension.
#pod
#pod =item Piddle1D_ne
#pod
#pod This accepts a non-null, non-empty 1D piddle.
#pod
#pod =back
#pod
#pod =head1 ERRORS
#pod
#pod Errors are represented as objects in the following classes:
#pod
#pod =over
#pod
#pod =item Parameter Validation
#pod
#pod These are unconditionally thrown as
#pod L<PDL::Algorithm::Center::Failure::parameter> objects.
#pod
#pod =item Iteration
#pod
#pod These are stored in the result object's C<error> attribute.
#pod
#pod   PDL::Algorithm::Center::Failure::iteration::limit_reached
#pod   PDL::Algorithm::Center::Failure::iteration::empty
#pod
#pod =back
#pod
#pod The objects stringify to a failure message.
#pod
#pod =head1 SEE ALSO
