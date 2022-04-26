package Statistics::Descriptive::PDL;

## no critic (ProhibitExplicitReturnUndef)

use 5.010;
use strict;
use warnings;
use Scalar::Util qw /blessed/;
use POSIX qw /fmod/;

#  avoid loading too much, especially into our name space
use PDL::Lite '2.012';
#  try to keep running if PDL::Stats is not installed
eval 'require PDL::Stats::Basic';
my $has_PDL_stats_basic = $@ ? undef : 1;
#$has_PDL_stats_basic = 0;

#  We could inherit from PDL::Objects, but in this case we want
#  to hide the piddle from the caller to avoid arbitrary changes
#  being applied to it.

our $VERSION = '0.16';

our $Tolerance = 0.0;  #  for compatibility with Stats::Descr, but not used here

my @cache_methods = qw /
  count sum mode median
  mean standard_deviation skewness kurtosis
  geometric_mean harmonic_mean
  max min sample_range
  iqr
/;
__PACKAGE__->_make_caching_accessors( \@cache_methods );

sub _make_caching_accessors {
    my ( $pkg, $methods ) = @_;
 
    ## no critic
    no strict 'refs';
    ## use critic
    foreach my $method (@$methods)
    {
        *{ $pkg . "::" . $method } = do
        {
            my $m = $method;
            sub {
                my $self = shift;
                return $self->{_cache}{$method}
                  if defined $self->{_cache}{$method};
 
                my $piddle = $self->_get_piddle;
                return undef
                  if !defined $piddle or $piddle->isempty;

                my $call_meth = "_$method";
                my $val = $self->$call_meth;

                if (blessed $val and $val->isa('PDL')) {
                    $val = $val->sclr;
                }
                return $self->{_cache}{$method} = $val;
            };
        };
    }
 
    return;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {piddle => undef};
    bless $self, $class;

    return $self;
}

sub available_stats {
    my $self = shift;
    my @methods = sort (@cache_methods, qw /percentile variance/);
    return wantarray ? @methods : \@methods;
}

sub add_data {
    my $self = shift;
    my $data;

    #  have we been passed an ndarray?
    if (blessed $_[0] && $_[0]->isa('PDL')) {
        $data = $_[0];
    }
    else {
        $data
          = ref ($_[0]) eq 'ARRAY'
          ? $_[0]
          : \@_;
        return if !scalar @$data;
    }

    my $piddle;
    my $has_existing_data = $self->count;

    $self->clear_cache;

    # Take care of appending to an existing data set
    if ($has_existing_data) {
        $piddle = $self->_get_piddle;
        $piddle = $piddle->append (PDL->pdl ($data)->flat);
        $self->_set_piddle ($piddle);
    }
    else {
        $self->_set_piddle (PDL->pdl($data)->flat);
    }

    return $self->count;
}

sub get_data {
    my $self = shift;
    my $piddle = $self->_get_piddle;
    
    my $data = defined $piddle ? $piddle->unpdl : [];
    
    return wantarray ? @$data : $data;
}

sub get_data_as_hash {
    my $self = shift;

    my $piddle = $self->_get_piddle;
    if (defined $piddle) {
        require Statistics::Descriptive::PDL::SampleWeighted;
        my $wtd_obj = Statistics::Descriptive::PDL::SampleWeighted->new;
        my $wts_piddle = PDL->ones ($piddle->dims);
        $wtd_obj->add_data ($piddle->copy, $wts_piddle);
        return $wtd_obj->get_data_as_hash;
    }

    return wantarray ? () : {};
}

sub values_are_unique {}

#  flatten $data if multidimensional
sub _set_piddle {
    my ($self, $data) = @_;
    $self->{piddle} = PDL->pdl ($data);
}

sub _get_piddle {
    my $self = shift;
    return $self->{piddle};
}

sub clear_cache {
    my $self = shift;
    delete $self->{_cache};
    return;
}

sub _count {
    my $self = shift;
    return $self->_get_piddle->nelem;
}

sub _sum {
    my $self = shift;
    return $self->_get_piddle->sum;
}


sub _min {
    my $self = shift;
    return $self->_get_piddle->min;
}

sub _max {
    my $self = shift;
    return $self->_get_piddle->max;
}

sub _mean {
    my $self = shift;
    return $self->_get_piddle->average;
}


sub sd    {return $_[0]->standard_deviation}
sub stdev {return $_[0]->standard_deviation}

sub _standard_deviation {
    my $self = shift;

    my $piddle = $self->_get_piddle;

    my $sd;
    my $n = $piddle->nelem;
    if ($n > 1) {
        if ($has_PDL_stats_basic) {
            $sd = $piddle->stdv_unbiased;
        }
        else {
            my $var = (($piddle ** 2)->sum - $n * $self->mean ** 2);
            $sd = $var > 0 ? sqrt ($var / ($n - 1)) : 0;
        }
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
    return $self->_get_piddle->median;
}


sub _skewness {
    my $self = shift;

    my $piddle = $self->_get_piddle;

    my $n = $piddle->nelem;

    return undef if $n < 3;

    return $piddle->skew_unbiased
      if $has_PDL_stats_basic;

    #  do it ourselves
    my $mean = $self->mean;
    my $sd   = $self->standard_deviation;
    my $sumpow3 = ((($piddle - $mean) / $sd) ** 3)->sum;
    my $correction = $n / ( ($n-1) * ($n-2) );
    my $skew = $correction * $sumpow3;

    return $skew;
}

sub _kurtosis {
    my $self = shift;
    my $piddle = $self->_get_piddle;

    my $n = $piddle->nelem;

    return undef if $n < 4;

    return $piddle->kurt_unbiased
      if $has_PDL_stats_basic;

    #  do it ourselves
    my $mean = $self->mean;
    my $sd   = $self->standard_deviation;
    my $sumpow4 = ((($piddle - $mean) / $sd) ** 4)->sum;

    my $correction1 = ( $n * ($n+1) ) / ( ($n-1) * ($n-2) * ($n-3) );
    my $correction2 = ( 3  * ($n-1) ** 2) / ( ($n-2) * ($n-3) );

    my $kurt = ( $correction1 * $sumpow4 ) - $correction2;
    return $kurt;
}

sub _sample_range {
    my $self = shift;
    my $min = $self->min // return undef;
    my $max = $self->max // return undef;
    return $max - $min;
}


sub _harmonic_mean {
    my $self = shift;
    my $piddle = $self->_get_piddle;

    return undef if $piddle->which->nelem != $piddle->nelem;

    my $hs = (1 / $piddle)->sum;

    return $hs ? $self->count / $hs : undef;
}

sub _geometric_mean {
    my $self = shift;
    my $piddle = $self->_get_piddle;

    my $count = $self->count;

    return undef if !$count;
    return undef if $piddle->where($piddle < 0)->nelem;

    my $exponent = 1 / $self->count();
    my $powered = $piddle ** $exponent;

    my $gm = $powered->dprodover;
}

sub _mode {
    my $self = shift;
    my $piddle = $self->_get_piddle;
    
    my $count  = $piddle->nelem;
    my $unique = $piddle->uniq;

    return undef if $unique->nelem == $count or $unique->nelem == 1;

    #if (!($count % $unique->nelem)) {
    #    #  might have equal numbers of each value
    #    #  need to check for this, but for now return undef
    #    return undef;
    #}

    my $mode = $piddle->mode;
    
    #  bodge to handle odd values
    return undef if !$piddle->in($mode)->max;
    
    return $mode;
}

sub percentiles {
    my ($self, @percentiles) = @_;

    my $piddle = $self->_get_piddle;

    return
      if !defined $piddle || $piddle->nelem == 0;

    my @vals = map {$self->percentile($_)} @percentiles;

    return @vals;
}


#  caching wrapper
#  need to convert $p to fraction, or perhaps die if it is between 0 and 1
#  hard-coded cache percentiles not ideal
sub percentile {
    my ($self, $p) = @_;
    my $piddle = $self->_get_piddle;

    return undef
      if !defined $piddle || $piddle->nelem == 0;

    return $self->median
      if $p == 50;

    die "Percentile $p outside range 0..100"
      if $p < 0 or $p > 100;
    
    #  allow for other number formats like '005'
    #  needed for cache
    $p += 0;

    return $self->{_cache}{percentile}{$p}
      if defined $self->{_cache}{percentile}{$p};

    my $pctl = $self->_percentile($p);

    if (blessed $pctl && $pctl->isa('PDL')) {
        $pctl = $pctl->sclr;
    }

    if (int ($p) == $p) {
        $self->{_cache}{percentile}{$p} = $pctl;
    }

    return $pctl;
}

sub _percentile {
    my ($self, $p) = @_;

    return $self->_get_piddle->pct($p / 100);
}



sub _iqr {
    my $self = shift;
    $self->percentile(75) - $self->percentile(25);
}


1;

__END__


=head1 NAME

Statistics::Descriptive::PDL - A close to drop-in replacement for
Statistics::Descriptive using PDL as the back-end

=head1 VERSION

Version 0.11

=cut

=head1 SYNOPSIS


    use Statistics::Descriptive::PDL;

    my $stats = Statistics::Descriptive::PDL->new();
    $stats->add_data(1,2,3,4);
    my $mean = $stats->mean;
    my $var  = $stats->variance();

=head1 DESCRIPTION

This module provides basic functions used in descriptive statistics.


=head1 METHODS

=over

=item new

Create a new statistics object.  Takes no arguments.

=item add_data (@data)

=item add_data (\@data)

Add data to the stats object.  Passed through to the underlying PDL object.
Appends to any existing data.

Multidimensional data are flattened into a single dimensional array.

=item get_data

Return the data as a perl array.  Returns an array ref in scalar context.

=item get_data_as_hash

Returns the data as a perl hash, with the unique data values as the hash keys and
the counts of each unique data value as the hash values.

Deduplicates the data if needed, incrementing the weights as appropriate.
Internally it uses a L<Statistics::Descriptive::PDL::SampleWeighted> object.

Data values are stringified so there is obviously potential for loss of precision.


=item values_are_unique

Flag whether the data have duplicate values.
Has no effect on unweighted data.
It is provided purely for a consistent interface with
the weighted variants.

=item clear_cache

Clears any cached results on an object.

=item available_stats

Method to return a list of the available statistics.

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

The above should need no explanation, except that they
use the unbiased methods where appropriate, as per Statistics::Descriptive.

=item count

Number of data items that have been added.


=item skewness

=item kurtosis

Skewness and kurtosis to match that of MS Excel.
If you are used to R then these are the same as type=2
in e1071::skewness and e1071::kurtosis.

=item sd

=item stdev

These are aliases for the standard_deviation method.


=item percentile (10)

=item percentile (45)

The percentile calculation differs from Statistics::Descriptive in that it uses
linear interpolation to determine the values, and thus does not
return the exact same values as the input data.

=item percentiles (10, 20, 30)

A simple wrapper around the percentile method to allow calculation of
multiple values in one call.

=item iqr

The inter-quartile range.  A convenience method to calculate the
difference between the 75th and 25th percentile.

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

