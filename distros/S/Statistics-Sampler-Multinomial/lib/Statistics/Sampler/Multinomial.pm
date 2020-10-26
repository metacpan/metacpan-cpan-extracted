package Statistics::Sampler::Multinomial;

use 5.014;
use warnings;
use strict;

our $VERSION = '0.86';

use Carp;
use Ref::Util qw /is_arrayref/;
use List::Util qw /min sum/;
use List::MoreUtils qw /first_index/;
use Scalar::Util qw /blessed looks_like_number/;

sub new {
    my ($class, %args) = @_;
    
    my $data = $args{data};
    croak 'data argument not passed'
      if !defined $data;
    croak 'data argument is not an array ref'
      if !is_arrayref ($data);
    croak 'data argument is an empty array'
      if !scalar @$data;

    my $first_neg_idx = first_index {$_ < 0} @$data;
    croak "negative values passed in data array ($data->[$first_neg_idx] at index $first_neg_idx)\n"
      if $first_neg_idx >= 0;
    

    my $self = {
        data => $data,
        data_sum_to_one => $args{data_sum_to_one},
    };

    bless $self, $class;

    my $prng = $args{prng};
    $self->_validate_prng_object ($prng);
    $self->{prng}
      =  $prng
      // "${class}::DefaultPRNG"->new;

    return $self;
}

sub _validate_prng_object {
    my ($self, $prng) = @_;

    #  Math::Random::MT::Auto has boolean op overloading
    #  so make sure we don't trigger it or our tests fail
    #  i.e. don't use "if $prng" directly
    #  (and we waste a random number, but that's less of an issue)
    #return 1 if !defined $prng;

    #  no default yet, so croak if not passed
    croak "prng arg is not defined.  "
        . "Math::Random::MT::Auto is a good default to use"
      if not defined $prng;
    croak 'prng arg is not an object'
      if not blessed $prng;
    croak 'prng arg does not have binomial() method'
      if not $prng->can('binomial');

    return 1;
}


sub _initialise {
    my ($self, %args) = @_;

    my $probs = $self->{data};

    #  caller has not promised they sum to 1
    if ( $self->{data_sum_to_one}) {
        $self->{sum} = 1;
    }
    else {  
        my $sum = sum (@$probs);
        if ($sum != 1) {
            my @scaled_probs = map {$_ / $sum} @$probs;
            $probs = \@scaled_probs;
        }
        $self->{sum} = $sum;
    }

    return;
}

sub get_class_count {
    my $self = shift;
    my $aref = $self->{data};
    return scalar @$aref;
}

#  simplified version of draw_n_samples
#  as we need a single index result
sub draw {
    my ($self) = @_;

    my $prng = $self->{prng};

    my $data  = $self->{data}
      // croak 'it appears setup has not been run yet';
    my $K    = scalar @$data - 1;
    my $norm = $self->{sum} // do {$self->_initialise; $self->{sum}};

    foreach my $kk (0..$K) {
        #  avoid repeated derefs below - unbenchmarked micro-optimisation
        my $data_kk = $data->[$kk];
        next if !$data_kk;

        return $kk
          if   ($data_kk > $norm)  #  MRMA blows up if prob>1, due to rounding errors
            || $prng->binomial (
                  $data_kk / $norm,
                  1,  # constant for single draw 
               );

        $norm -= $data_kk;
    }

    #  we should not get here
    return;
}

sub draw_n_samples {
    my ($self, $n) = @_;

    my $prng = $self->{prng};

    my $data  = $self->{data}
      // croak 'it appears setup has not been run yet';
    my $K    = scalar @$data - 1;
    my $norm = $self->{sum} // do {$self->_initialise; $self->{sum}};

    my @draws;

    foreach my $kk (0..$K) {
        #  avoid repeated derefs below - unbenchmarked micro-optimisation
        my $data_kk = $data->[$kk];
        if (!$data_kk) {
            $draws[$kk] = 0;
            next;
        }

        #  MRMA does not like p>1
        my $prob = $data_kk > $norm ? 1 : $data_kk / $norm;
        my $res = $prng->binomial (
            $prob,
            $n,
        );
        $draws[$kk] = $res;
        $norm -= $data_kk;
        $n    -= $res;
    }

    return \@draws;
}


sub draw_with_mask {
    my ($self, $mask) = @_;
    
    croak 'mask argument is not an array ref'
      if !is_arrayref $mask;
    
    if (!defined $self->{sum}) {
        $self->_initialise;
    }

    #  now we mask
    my @deleted = delete local @{$self->{data}}[@$mask];
    local $self->{sum} = $self->{sum} - sum @deleted;
    
    $self->draw ();
}

#  lots of code duplication going on here
sub draw_n_samples_with_mask {
    my ($self, $n, $mask) = @_;
    
    croak 'mask argument is not an array ref'
      if !is_arrayref $mask;
    
    if (!defined $self->{sum}) {
        $self->_initialise;
    }

    #  now we mask
    my @deleted = delete local @{$self->{data}}[@$mask];
    local $self->{sum} = $self->{sum} - sum @deleted;
    
    $self->draw_n_samples ($n);
}

sub update_values {
    my ($self, %args) = @_;
    
    if (!defined $self->{sum}) {
        $self->_initialise;
    }

    my $data = $self->{data};
    my $count = 0;
    foreach my $iter (keys %args) {
        croak "iter $iter is not numeric"
          if !looks_like_number $iter;
        $self->{sum} += $args{$iter} - ($data->[$iter] // 0);
        $data->[$iter] = $args{$iter};
        $count ++;
    }

    return $count;
}

sub get_data {
    my $self = shift;
    my $data = $self->{data};
    return wantarray ? @$data : [@$data];
}

sub get_sum {
    my $self = shift;
    return $self->{sum} // do {$self->_initialise; $self->{sum}};
}

#  Cuckoo package to act as a method wrapper
#  to use the perl PRNG stream by default.
# currently croaks because we have no binomial method
package Statistics::Sampler::Multinomial::DefaultPRNG {
    use Carp;
    sub new {
        croak "No default PRNG yet implemented for Statistics::Sampler::Multinomial.\n"
            . "Try Math::Random::MT::Auto.";
        return bless {}, __PACKAGE__;
    }
    #sub rand {
    #    rand();
    #}
    sub binomial {
        ...
    }
    1;
}


1;
__END__

=head1 NAME

Statistics::Sampler::Multinomial - Generate multinomial samples
using the conditional binomial method.

=head1 SYNOPSIS

    use Statistics::Sampler::Multinomial;

    my $object = Statistics::Sampler::Multinomial->new(
        data => [0.1, 0.3, 0.2, 0.4],
    );
    $object->draw;
    #  returns a number between 0..3

    my $samples = $object->draw_n_samples(5)
    #  returns an array ref that might look something like
    #  [3,3,0,2,0]
    
    $object->draw_with_mask([1,2]);
    $object->draw_n_samples_with_mask([1,2]);
    #  locally set data at positions 1 and 2 to zero
    #  so they will have zero probability of being returned

    # to specify your own PRNG object, in this case the Mersenne Twister
    my $mrma = Math::Random::MT::Auto->new;
    my $object = Statistics::Sampler::Multinomial->new(
        prng => $mrma,
        data => [1,2,3,5,10],
    );


=head1 DESCRIPTION

Implements multinomial sampling using the conditional binomial method
(the same algorithm as used in the GSL).
Benchmarking shows it to be faster than the Alias
method implemented in L<Statistics::Sampler::Multinomial::AliasMethod>,
presumably because the calls to the PRNG are inside XS and avoid
perl subroutine overheads
(and profiling showed the RNG calls to be the main bottleneck
for the Alias method).  

For more details and background about the various approaches,
see L<http://www.keithschwarz.com/darts-dice-coins>.

=head1 METHODS

=over 4

=item my $object = Statistics::Sampler::Multinomial->new(data => [0.1, 0.4, 0.5], data_sum_to_one => 1)

=item my $object = Statistics::Sampler::Multinomial->new (data => [1,2,3,4,5,100], prng => $prng)

Creates a new object, optionally passing a PRNG object to be used.

Callers can promise the data sum to one, in which case it will not calculate the sum.
No checks of the validity of
such promises are made, so expect failures for lying.
(This should be generalised to use the sum directly).

If no PRNG object is passed then it croaks.
One day it will default to an internal object
that uses the perl PRNG stream and has a binomial method.

Passing your own PRNG means you have control over the random number
stream used, and can use it as part of a separate analysis.
The only requirement of such an object is that it has a binomial()
method.

=item $object->draw

Draw one sample from the distribution.
Returns the sampled class number (array index).

=item $object->draw_n_samples ($n)

Returns an array ref of $n samples across the K classes,
where K is the length of the data array passed in to the call to new.
e.g. for $n=3 and the K=5 example from above,
one could get (0,1,2,0,0).


=item $object->update_values (1 => 10, 4 => 0.2)

Updates the data values at the specified positions.
Argument list must be a set of numeric key/value pairs.
The keys and values are not otherwise checked,
but the system will follow perl's rules
regarding non-numeric values under the warnings pragma.
The same applies for floating point array indices.

=item $object->draw_with_mask ($aref)

=item $object->draw_n_samples_with_mask ($n, $aref)

These locally mask out a subset of classes by setting
their probabilities to false.  In many cases this will
(should) be faster than generating a new object with
the subset excluded, especially if that new object is
then discarded.  

=item $object->get_class_count

Returns the number of classes in the sample,
or zero if initialise has not yet been run.

=item $object->get_data

Returns a copy of the data array.  In scalar context
this will be an array ref.

=item $object->get_sum

Returns the sum of the data array values.

=back


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
L<https://github.com/shawnlaffan/perl-statistics-sampler-multinomial/issues>.

Most tests are skipped on x86 as Math::Random::MT::Auto seeds differently
and thus the PRNG sequences differ between x86 and x64.


=head1 SEE ALSO

These packages also have multinomial samplers and are (much) faster than
this package, but you cannot supply your own PRNG.
If you do not care that all your random samples come from the same PRNG stream
then you should use them.

L<Math::Random>, L<Math::GSL::Randist>



=head1 AUTHOR

Shawn Laffan  C<< <shawnlaffan@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Shawn Laffan C<< <shawnlaffan@gmail.com> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
