package Statistics::Descriptive::PDL::Weighted;

use 5.010;
use strict;
use warnings;

#  avoid loading too much, especially into our name space
use PDL::Lite '2.012';

#  We could inherit from PDL::Objects, but in this case we want
#  to hide the piddle from the caller to avoid arbitrary changes
#  being applied to it. 

## no critic (ProhibitExplicitReturnUndef)

our $VERSION = '0.17';

use parent 'Statistics::Descriptive::PDL';

my @cache_methods = qw /
  count sum mode median
  mean standard_deviation skewness kurtosis
  geometric_mean harmonic_mean
  sum_weights sum_sqr_weights
/;
__PACKAGE__->_make_caching_accessors( \@cache_methods );


sub new {
    my $proto = shift;
    my $data_type = shift // PDL::double();
    my $class = ref($proto) || $proto;

    my $self = {
        piddle    => undef,
        weights_piddle => undef,
        data_type      => $data_type,
    };
    bless $self, $class;

    return $self;
}


sub _wt_type{PDL::double}

sub add_data {
    my ($self, $data, $weights) = @_;

    my ($data_piddle, $weights_piddle);

    my $data_from_hash;
    
    if (ref $data eq 'HASH') {
        $data_piddle    = PDL->pdl ($self->{data_type}, [keys %$data])->flat;
        $weights_piddle = PDL->pdl ($self->_wt_type, [values %$data])->flat;
        $data_from_hash = 1;
    }
    else {
        $data_piddle    = PDL->pdl ($self->{data_type}, $data)->flat;
        $weights_piddle = PDL->pdl ($self->_wt_type, $weights)->flat;
        die "data and weight vectors not of same length"
          if scalar $data_piddle->nelem != $weights_piddle->nelem;
        die "Cannot pass zero or negative weights"
          if PDL::any($weights_piddle <= 0);
    }

    return if !$data_piddle->nelem;

    my $has_existing_data = $self->count;

    # Take care of appending to an existing data set
    if ($has_existing_data) {
        my $d_piddle = $self->_get_piddle;
        $d_piddle    = $d_piddle->append ($data_piddle);
        $self->_set_piddle ($d_piddle);
        my $w_piddle = $self->_get_weights_piddle;
        $w_piddle    = $w_piddle->append ($weights_piddle);
        $self->_set_weights_piddle ($w_piddle);

        delete $self->{sorted};
    }
    else {
        $self->_set_piddle ($data_piddle);
        $self->_set_weights_piddle ($weights_piddle);
    }

    #  need to clear late because count is cached
    $self->clear_cache;

    #  somewhat awkward but needs to be set after clearing the cache
    if ($data_from_hash && !$has_existing_data) {
        $self->values_are_unique(1);
    }

    return $self->count;
}

sub get_data {
    my $self = shift;
    my $piddle = $self->_get_piddle;
    my $wts_piddle = $self->_get_weights_piddle;
    
    my $data = defined $piddle ? $piddle->unpdl : [];
    my $wts  = defined $wts_piddle ? $wts_piddle->unpdl : [];
    
    return wantarray ? ($data, $wts) : [$data, $wts];
}

sub get_data_as_hash {
    my $self = shift;
    
    my $piddle = $self->_get_piddle;

    return wantarray ? () : {}
      if !defined $piddle;

    my $deduped = $self->_deduplicate;

    my $data = $deduped->_get_piddle->unpdl;
    my $wts  = $deduped->_get_weights_piddle->unpdl;
    my %h;
    @h{@$data} = @$wts;

    return wantarray ? (%h) : \%h;
}


sub values_are_unique {
    my $self = shift;
    if (@_) {
        my $flag = shift;
        $self->{_cache}{deduplicated} = !!$flag;
    }
    return $self->{_cache}{deduplicated};
}

sub _set_weights_piddle {
    my ($self, $data) = @_;
    $self->{weights_piddle} = PDL->pdl ($data);
}

sub _get_weights_piddle {
    my $self = shift;
    return $self->{weights_piddle};
}

sub _count {
    my $self = shift;
    my $piddle = $self->_get_weights_piddle;
    return undef if !defined $piddle;
    return $piddle->sum;
}

sub _sum {
    my $self = shift;
    return ($self->_get_piddle * $self->_get_weights_piddle)->sum;
}

sub _sum_weights {
    my $self = shift;

    return $self->_get_weights_piddle->sum;
}

sub _sum_sqr_weights {
    my $self = shift;
    return $self->_get_weights_piddle->power(2)->sum;
}

#sub min_weight {
#    my $self = shift;
#    return $self->_get_weights_piddle->min;
#}


sub _mean {
    my $self = shift;

    my $data = $self->_get_piddle;
    my $wts  = $self->_get_weights_piddle;
    return ($data * $wts)->sum / $wts->sum;
}


sub _standard_deviation {
    my $self = shift;

    my $data = $self->_get_piddle;
    my $sd;
    my $n = $data->nelem;
    if ($n > 1) {
        #  long winded approach
        my $wts  = $self->_get_weights_piddle;
        my $mean = $self->mean;
        my $sumsqr = ($wts * (($data - $mean) ** 2))->sum;
        my $var = $sumsqr / $self->sum_weights;
        $sd = sqrt $var;
    }
    elsif ($n == 1){
        $sd = 0;
    }

    return $sd;
}

sub variance {
    my $self = shift;
    my $sd = $self->standard_deviation;
    return defined $sd ? $sd ** 2 : undef;
}

sub _median {
    my $self = shift;

    my $data = $self->_sort_piddle;
    my $cumsum = $self->_get_cumsum_weight_vector;

    my $target_wt = $self->sum_weights * 0.5;
    #  vsearch should be faster since it uses a binary search
    my $idx = PDL->pdl($target_wt)->vsearch_insert_leftmost($cumsum->reshape);

    return $data->at($idx);
}

sub _sort_piddle {
    my $self = shift;
    my $data = $self->_get_piddle;

    return undef if !defined $data;

    return $data if $self->{sorted};

    my $wts = $self->_get_weights_piddle;
    my $s = $data->qsorti->reshape;
    my $sorted_data = $data->slice($s);
    my $sorted_wts  = $wts->slice($s);
    
    $self->_set_piddle($sorted_data);
    $self->_set_weights_piddle($sorted_wts);

    $self->{sorted} = 1;
    delete $self->{_cache}{cumsum_weight_vector};

    return $sorted_data;
}

#  de-duplicate if needed, aggregating weights
#  there should be a sumover or which approach that will work better
#  maybe yvals related
sub _deduplicate {
    my ($self, %args) = @_;
    my $piddle = $self->_get_piddle;
    
    return undef
      if !defined $piddle;

    return $self
      if $self->values_are_unique;

    my $unique = $piddle->uniq;

    if ($unique->nelem == $piddle->nelem) {
        $self->values_are_unique(1);
        return $self
    }

    if (!$self->{sorted}) {
        $unique = $unique->qsort;
    }

    $piddle = $self->_sort_piddle;
    my $wts_piddle = $self->_get_weights_piddle;

    #  could use a map with a hash, but this avoids
    #  stringification and loss of precision
    #  (not that that should cause too many issues for most data)
    #  Should try to reduce looping when there are
    #  not many dups in large data sets
    my $j        = 0;  #  index into deduplicated piddle
    my $last_val = $piddle->at(0);
    my @wts;
    foreach my $i (0..$piddle->nelem-1) {
        my $val = $piddle->at($i);
        if ($val != $last_val) {
            $j++;
            $last_val = $val;
        }
        $wts[$j] += $wts_piddle->at($i);
    }

    if ($args{inplace}) {
        $self->_set_piddle($unique);
        $self->_set_weights_piddle(\@wts);
        $self->clear_cache;
        $self->values_are_unique (1);
        return $self;
    }

    my $new = $self->new($self->{data_type});
    $new->_set_piddle($unique);
    $new->_set_weights_piddle(\@wts);
    $new->values_are_unique (1);

    return $new;
}

sub _get_cumsum_weight_vector {
    my $self = shift;

    return $self->{_cache}{cumsum_weight_vector}
      if defined $self->{_cache}{cumsum_weight_vector};
    return $self->{_cache}{cumsum_weight_vector}
      = $self->_get_weights_piddle->cumusumover->reshape;
}

sub _skewness {
    my $self = shift;

    my $data = $self->_get_piddle;

    #  long winded approach
    my $mean = $self->mean;
    my $sd   = $self->standard_deviation;
    my $wts = $self->_get_weights_piddle;
    my $sumpow3 = ($wts * ((($data - $mean) / $sd) ** 3))->sum;
    my $skew = $sumpow3 / $self->sum_weights;
    return $skew;
}

sub _kurtosis {
    my $self = shift;

    my $data = $self->_get_piddle;

    #  long winded approach
    my $mean = $self->mean;
    my $sd   = $self->standard_deviation;
    my $wts = $self->_get_weights_piddle;
    my $sumpow4 = ($wts * ((($data - $mean) / $sd) ** 4))->sum;
    my $kurt = $sumpow4 / $self->sum_weights - 3;
    return $kurt;
}


sub _harmonic_mean {
    my $self = shift;
    
    my $data = $self->_get_piddle;

    #  not sure about this...
    return undef if $data->which->nelem != $data->nelem;

    my $wts = $self->_get_weights_piddle;
    
    my $hs = ((1 / $data) * $wts)->sum;

    return $hs ? $self->count / $hs : undef;
}

sub _geometric_mean {
    my $self = shift;

    my $data = $self->_get_piddle;

    #  should add a sorted status check, as we can use vsearch in such cases
    return undef if $data->where($data < 0)->nelem;

    my $wts = $self->_get_weights_piddle;

    # formula from https://en.wikipedia.org/wiki/Weighted_geometric_mean
    return exp (($data->log * $wts)->sum / $wts->sum);
}

sub _mode {
    my $self = shift;

    #  de-duplicate and aggregate weights if needed
    my $deduped = $self->_deduplicate;

    my $data = $deduped->_get_piddle;


    my $wts = $deduped->_get_weights_piddle;
    my $mode = $data->at($wts->maximum_ind);
    if ($mode > $data->max) {
        #  PDL returns strange numbers when distributions are flat
        $mode = undef;
    }

    return $mode;
}

#  need to convert $p to fraction, or perhaps die if it is between 0 and 1
sub _percentile {
    my ($self, $p) = @_;

    my $data = $self->_get_piddle;
    return undef
      if !defined $data or $data->isempty;

    $data = $self->_sort_piddle;

    my $cumsum = $self->_get_cumsum_weight_vector;

    my $target_wt = $self->sum_weights * ($p / 100);

    my $idx = PDL->pdl($target_wt)->vsearch_insert_leftmost($cumsum->reshape);

    return $data->at($idx);
}


1;

__END__


=head1 NAME

Statistics::Descriptive::PDL::Weighted - A close to drop-in replacement for
Statistics::Descriptive::Weighted using PDL as the back-end

=head1 VERSION

Version 0.11

=cut

=head1 SYNOPSIS


    use Statistics::Descriptive::PDL::Weighted;

    my $stats = Statistics::Descriptive::PDL::Weighted->new;
    $stats->add_data([1,2,3,4], [1,3,5,6]);  #  values then weights
    my $mean = $stats->mean;
    my $var  = $stats->variance;
    
    #  or you can add data using a hash ref
    my %data = (1 => 1, 2 => 3, 3 => 5, 4 => 6);
    $stats->add_data(\%data);
    
    #  if you want equal weights then you need to supply them yourself
    my $data = [1,2,3,4];
    $stats->add_data($data, [(1) x scalar @$data]);
    
    
=head1 DESCRIPTION

This module provides basic functions used in descriptive statistics
using weighted values.


=head1 METHODS

=over

=item new

Create a new statistics object.  Takes no arguments.

=item add_data (\%data)

=item add_data ([1,2,3,4], [0.5,1,0.1,2)

Add data to the stats object.  Appends to any existing data.

If a hash reference is passed then the keys are treated as the numeric data values,
with the hash values the weights.

Unlike Statistics::Descriptive::PDL, you cannot pass a single flat array
since odd things might happen if we convert it to a hash and the values
are multidimensional.

Since the L<PDL::pdl> function is used to process the data and weights you should be able to
specify anything pdl accepts as valid.

An exception is raised the weights are <= 0, or are not the same size as the data.

=item get_data

Returns arrays of the data and the weights.

In scalar context returns an array of arrays, i.e. C<[\@data,\@wts]>.

=item get_data_as_hash

Returns the data as a perl hash, with the data values as the hash keys and weights as the hash values.
Deduplicates the data if needed, incrementing the weights as appropriate.

Data values are stringified so there is obviously potential for loss of precision.

Returns a hash ref in scalar context.

=item values_are_unique

=item values_are_unique (1)

Flag to indicate if the data have duplicate values.
Pass a true value to indicate your data have no
duplicate values, making the median and percentile
calculations faster (at the risk of you not being correct).

=item sum_weights

Sum of the weights vector.

=item sum_sqr_weights

Sum of the squared weights vector.  Each weight is squared and the sum of these values then calculated.

=item sum_sqr_sample_weights

Same as the C< sum_sqr_weights > method.

=item Statistical methods

Most of the methods should need no explanation here,
except to note that the standard_deviation, skewness and kurtosis
use the biased methods.  This is because one cannot guarantee the data are sample counts.
The same applies to the median and percentiles.  The median uses a centre of mass calculation, and the
percentiles using analogous approach.  This is because the weights are not guaranteed
to be integers and so there is no sense interpolating.

Use L<Statistics::Descriptive::PDL::SampleWeighted> when your weights are counts
and you need the unbiased methods.

The iqr is the inter-quartile range, calculated as the difference of the 75th and 25th percentiles.

=item geometric_mean

=item harmonic_mean

=item max

=item mean

=item median

=item min

=item mode

=item sample_range

=item standard_deviation

=item sum

=item variance

=item count

=item skewness

=item kurtosis

=item percentile (10)

=item percentile (45)

=item iqr

=back

=head2 Not yet implemented, and possibly won't be.

Any of the trimmed functions, frequency functions and some others.

=over

=item least_squares_fit

=item trimmed_mean

=item quantile

=item mindex

=item maxdex

=back

=head1 AUTHOR

Shawn Laffan, C<< <shawnlaffan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<https://github.com/shawnlaffan/Statistics-Descriptive-PDL/issues>.



=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2021 Shawn Laffan.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

