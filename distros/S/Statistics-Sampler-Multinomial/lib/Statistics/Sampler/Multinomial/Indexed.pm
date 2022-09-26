package Statistics::Sampler::Multinomial::Indexed;

use 5.014;
use warnings;
use strict;

our $VERSION = '1.02';

use Carp;
use Ref::Util qw /is_arrayref/;
use List::Util 1.29 qw /min max sum pairmap/;
#use List::MoreUtils qw /first_index/;
use Scalar::Util qw /blessed looks_like_number/;

#use POSIX qw /ceil floor/;

use parent qw /Statistics::Sampler::Multinomial/;

sub new {
    my $pkg = shift;
    my $self = Statistics::Sampler::Multinomial->new(@_);
    bless $self, __PACKAGE__;
    
    $self->build_index;
    
    return $self;
}

sub _clone_inner {
    my $self = shift;
    #  parent class handles most details
    my $clone = $self->SUPER::_clone_inner;
    
    #  generate a dup of the index array-of-arrays
    $clone->{index} = [map {[@$_]} @{$self->{index}}];

    return $clone;
}


#  Build a tree based index of cumulative values.
#  This will help the single draw methods.
#  Idea from 
#  https://www.chiark.greenend.org.uk/~sgtatham/algorithms/cumulative.html
sub build_index {
    my $self = shift;
    my $data = $self->{data};

    #my $max_depth = 1 + logb (scalar @$data);
    my $max_depth = 1 + int (log (scalar @$data) / log (2));

    # each index entry contains the cumulative sum of its terminals
    # and each level is half the length of the one below 
    my @indexed;

    #  bottom is just the data
    $indexed[$max_depth] = $data;

    for my $level (reverse (0..$max_depth-1)) {
        my $pop;
        if (@{$indexed[$level+1]} % 2) {
            push @{$indexed[$level+1]}, 0;
            $pop = 1;
        }
        @{$indexed[$level]} = pairmap {($a//0)+($b//0)} @{$indexed[$level+1]};
        if ($pop) {
            pop @{$indexed[$level+1]};
        }
    }
    
    $self->{index} = \@indexed;

    return;
}

sub draw {
    my ($self) = @_;

    my $prng = $self->{prng};

    my $data  = $self->{data}
      // croak 'it appears setup has not been run yet';

    return 0 if @$data == 1;

    my $indexed = $self->{index};
    my $norm    = $indexed->[0][0];

    my $rand = $prng->rand * $norm;
    my $rand_orig = $rand;

    #  climb down the index tree
    #  start from 1 as 0 has single value
    my $level = 1;
    # current array items
    my $left  = 0;
    my $right = 1;

    while ($level < $#$indexed) {
        if ($rand <= $indexed->[$level][$left]) {
            #  descending left
            $left  *= 2;
            $right  = $left + 1;
        }
        else {
            #  descending right,
            #  so update target since left part
            #  of tree not in these sums
            $rand -= $indexed->[$level][$left];
            $left  = $right * 2;
            $right = $left  + 1;
        }
        $level++;
    }

    return $rand > $data->[$left] ? $right : $left;    
}

#  should rebuild the index if a new index exceeds next power of two
sub update_values {
    my ($self, %args) = @_;
    
    if (!defined $self->{sum}) {
        $self->_initialise;
    }

    my $data    = $self->{data};
    my $indexed = $self->{index};

    my $max_update_iter = max (keys %args);

    if ($max_update_iter > $#$data) {
        #  if someone passes in an iter that needs extra index levels
        #  then we rebuild the whole index
        my $max_depth     = int (log (scalar @$data) / log (2));
        my $new_max_depth = int (log ($max_update_iter+1) / log (2));
        if ($new_max_depth > $max_depth) {
            $self->SUPER::update_values (%args);
            $self->{index} = undef;
            $self->build_index;
        }
    }

    
    my $count = 0;
    foreach my $iter (keys %args) {
        croak "iter $iter is not numeric"
          if !looks_like_number $iter;
        
        my $diff = $args{$iter} - ($data->[$iter] // 0);
        $self->{sum} += $diff;
        $data->[$iter] = $args{$iter};
        
        #  update the index - bitshift is faster
        #my $idx = int ($iter / 2);
        my $idx = $iter >> 1;
        foreach my $level (reverse (0 .. $#$indexed-1)) {
            $indexed->[$level][$idx] += $diff;
            #$idx = int ($idx / 2);
            $idx >>= 1;
        }

        $count ++;
    }

    return $count;
}


1;


__END__

=head1 NAME

Statistics::Sampler::Multinomial::Indexed - Generate multinomial samples
using the conditional binomial method, using a hierarchical index
to speed up the draw method.

=head1 SYNOPSIS

    use Statistics::Sampler::Multinomial::Indexed;

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

This is a subclass of L<Statistics::Sampler::Multinomial>.
All methods are inherited from there.

The difference is that this uses an index to speed up
the calls to the draw method.  Note that this can be expensive
to calculate, so is only of benefit for repeated calls.


=head1 METHODS

=over 4

=item $object->new (data => [2,7,9,12])

Generates a new object.  For full arguments, see
the new method in L<Statistics::Sampler::Multinomial>.

=item $object->draw

Draw one sample from the distribution.
Returns the sampled class number (array index).

The internal index means calls will be O(log n)
instead of O(n/2) on average for the non-indexed
variant.

Setting up the index costs O(n log n), so
best used when the setup costs can be amortised
across many calls.  


=item $object->update_values (1 => 10, 4 => 0.2)

Updates the data values at the specified positions.
Argument list must be a set of numeric key/value pairs.
The keys and values are not otherwise checked,
but the system will follow perl's rules
regarding non-numeric values under the warnings pragma.
The same applies for floating point array indices.

Due to the index, this will run at O(log n).

If the updates would increase the size of the data
array beyond the next power of two 
then the index is completely rebuilt.  

=item $object->build_index

Build the index.  This is called automatically in new(),
so is probably only useful if one reblesses a
L<Statistics::Sampler::Multinomial> object into this class.

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
