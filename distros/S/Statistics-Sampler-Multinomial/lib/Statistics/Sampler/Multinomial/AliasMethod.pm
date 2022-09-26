package Statistics::Sampler::Multinomial::AliasMethod;

use 5.014;
use warnings;
use strict;

our $VERSION = '1.02';

use Carp;
use Ref::Util qw /is_arrayref/;
use List::Util qw /min sum/;
use List::MoreUtils qw /first_index/;
use Scalar::Util qw /blessed/;

use parent qw /Statistics::Sampler::Multinomial/;

sub _validate_prng_object {
    my ($self, $prng) = @_;

    #  Math::Random::MT::Auto has boolean op overloading
    #  so make sure we don't trigger it or our tests fail
    #  i.e. don't use "if $prng" directly
    #  (and we waste a random number, but that's less of an issue)
    return 1 if !defined $prng;

    croak 'prng arg is not an object'
      if not blessed $prng;
    croak 'prng arg does not have rand() method'
      if not $prng->can('rand');

    return 1;
}

sub _initialise_alias_tables {
    my ($self, %args) = @_;

    my $probs = $self->{data};

    #  caller has not promised they sum to 1
    if (!$self->{data_sum_to_one}) {
        my $sum = sum (@$probs);
        if ($sum != 1) {
            my @scaled_probs = map {$_ / $sum} @$probs;
            $probs = \@scaled_probs;
        }
    }

    #  algorithm and comments stolen/adapted from
    #  https://hips.seas.harvard.edu/blog/2013/03/03/the-alias-method-efficient-sampling-with-many-discrete-outcomes/

    my (@smaller, @larger);
    my @J = (0) x scalar @$probs;
    my @q = (0) x scalar @$probs;
    my $kk = -1;
    my $K = scalar @$probs;

    foreach my $prob (@$probs){
        $kk++;
        $q[$kk] = $K * $prob;
        if ($q[$kk] < 1.0) {
            push @smaller, $kk
        }
        else {
            push @larger, $kk;
        }
    }
    
    # Loop though and create little binary mixtures that
    # appropriately allocate the larger outcomes over the
    # overall uniform mixture.
    while (scalar @smaller && scalar @larger) {
        my $small = pop @smaller;
        my $large = pop @larger;
 
        $J[$small] = $large;
        $q[$large] = ($q[$large] + $q[$small]) - 1;
 
        if ($q[$large] < 1.0) {
            push @smaller, $large;
        }
        else {
            push @larger, $large;
        }
    }
    # handle numeric stability issues
    # courtesy http://www.keithschwarz.com/darts-dice-coins/
    while (scalar @larger) {
        my $g  = shift @larger;
        $q[$g] = 1;
    }
    while (scalar @smaller) {
        my $l  = shift @smaller;
        $q[$l] = 1;
    }

    #  need better names for these,
    $self->{J} = \@J;
    $self->{q} = \@q;

    return if !defined wantarray;

    #  should not expose these to the caller
    my %results = (J => \@J, q => \@q);
    return wantarray ? %results : \%results;
}

sub draw {
    my ($self, $args) = @_;

    my $prng = $self->{prng};
    
    my $q  = $self->{q}
      // do {$self->_initialise_alias_tables; $self->{q}};

    my $J  = $self->{J};
    my $K  = scalar @$J;
    my $kk = int ($prng->rand * $K);
 
    # Draw from the binary mixture, either keeping the
    # small one, or choosing the associated larger one.
    return ($prng->rand < $q->[$kk]) ? $kk : $J->[$kk];
}

sub draw_n_samples {
    my ($self, $n) = @_;
    
    my $prng = $self->{prng};

    my $q  = $self->{q}
      // do {$self->_initialise_alias_tables; $self->{q}};
    my $J  = $self->{J};
    my $K  = scalar @$J;
    
    my @draws = (0) x $K;
    for (1..$n) {
        my $kk = int ($prng->rand * $K);
        # Draw from the binary mixture, either keeping the
        # small one, or choosing the associated larger one.
        # {SWL: could try to use Data::Alias or refaliasing here
        # as the derefs cause overhead, albeit the big overhead
        # is the method calls}
        #push @draws, ($prng->rand < $q->[$kk]) ? $kk : $J->[$kk];
        $draws[($prng->rand < $q->[$kk]) ? $kk : $J->[$kk]]++;
    }

    return \@draws;
}

#  Cuckoo package to act as a method wrapper
#  to use the perl PRNG stream by default. 
package Statistics::Sampler::Multinomial::AliasMethod::DefaultPRNG {
    sub new {
        return bless {}, __PACKAGE__;
    }
    sub rand {
        rand();
    }
    1;
}

1;
__END__

=head1 NAME

Statistics::Sampler::Multinomial - Generate multinomial samples using Vose's alias method


=head1 SYNOPSIS

    use Statistics::Sampler::Multinomial::AliasMethod;

    my $object = Statistics::Sampler::Multinomial::AliasMethod->new(
        data => [0.1, 0.3, 0.2, 0.4],
    );
    $object->draw;
    #  returns a number between 0..3
    
    my $samples = $object->draw_n_samples(5)
    #  returns an array ref that might look something like
    #  [3,3,0,2,0]
    
    # to specify your own PRNG object, in this case the Mersenne Twister
    my $mrma = Math::Random::MT::Auto->new;
    my $object = Statistics::Sampler::Multinomial::AliasMethod->new(
        data => [1,2,4,6,200],
        prng => $mrma,
    );


=head1 DESCRIPTION

Implements multinomial sampling using Vose's version of the alias method.

The setup time for the alias method is longer than for other methods,
and the memory requirements are larger since it maintains two lists in memory,
but this is amortised when 
when generating repeated samples because only two random numbers are
needed for each draw, as compared to up to O(log n) for other methods.
This should have a pay off when, for example calculating 
bootstrap confidence intervals for a set of classes,
but benchmarking shows this implementation to not be faster
than the GSL approach.
Profiling suggests the method calls to rand() are the main bottleneck.

For more details and background, see L<http://www.keithschwarz.com/darts-dice-coins>.


=head1 METHODS

=over 4

=item my $object = Statistics::Sampler::Multinomial->new(data => [1,2,3,4,100])

=item my $object = Statistics::Sampler::Multinomial->new(data => [0.1, 0.4, 0.5], data_sum_to_one => 1)

=item my $object = Statistics::Sampler::Multinomial->new (data => [1,2,3,4,5,100], prng => $prng)

Creates a new object, optionally passing a PRNG object to be used.
If no PRNG object is passed then it defaults to an internal object
that uses the perl PRNG stream.

Passing your own PRNG mean you have control over the random number
stream used, and can use it as part of a separate analysis.
The only requirement of such an object is that it has a rand()
method that returns a value in the interval [0,1)
(the same as Perl's rand() builtin).


By default it will standardise the data to sum to one
but callers can skip this step by promising that the
data already sum to one (thus speeding up the code).
No checks of the validity of
such promises are made, so expect failures for lying.

=item $object->draw

Draw one sample from the distribution.
Returns the chosen class number.

=item $object->draw_n_samples ($n)

Returns an array ref of $n samples across the K classes,
where K is the length of the data array passed in to the call to new.
e.g. for $n=3 and the K=5 example from above,
one could get (0,1,2,0,0).

=item $object->get_class_count

Returns the number of classes in the sample,
or zero if initialise has not yet been run.

=back


=head1 BUGS AND LIMITATIONS

Note that the results will differ between standard double
and long double builds of Perl.

L<Math::Random::MT::Auto> (a useful PRNG package) also gives different results
between x32 and x64 architectures.  


Please report any bugs or feature requests to
L<https://github.com/shawnlaffan/perl-statistics-sampler-multinomial/issues>.

=head1 SEE ALSO

Much of the code has been adapted from a python implementation at
L<https://hips.seas.harvard.edu/blog/2013/03/03/the-alias-method-efficient-sampling-with-many-discrete-outcomes>.

L<Statistics::Sampler::Multinomial> is the parent class of this one, and uses the algorithm implemented in the GSL.  

The L<Math::Random> and L<Math::GSL::Randist> packages also have multinomial samplers but do not use the alias method,
and you cannot supply your own PRNG.  They are also substantially faster so if
you care not about the method or PRNG stream then perhaps you should use them...


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
