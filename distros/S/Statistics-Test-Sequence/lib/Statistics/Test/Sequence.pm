package Statistics::Test::Sequence;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp qw/croak/;
use Params::Util qw/_POSINT _ARRAY _CODE/;
use Math::BigFloat;
use Memoize;

=head1 NAME

Statistics::Test::Sequence - Sequence correlation test for random numbers

=head1 SYNOPSIS

  use Statistics::Test::Sequence;
  my $tester = Statistics::Test::Sequence->new();
  $tester->set_data( [map {rand()} 1..1000000] );
  
  my ($metric, $actual_freq, $expected_freq) = $tester->test();
  use Data::Dumper;
  print "$metric\n";
  print "Frequencies:\n";
  print Dumper $actual_freq;
  print "Expected frequencies:\n";
  print Dumper $expected_freq;

=head1 DESCRIPTION

This module implements a sequence correlation test for random number
generators. It shows pairwise correlation between subsequent
random numbers.

The algorithm is as follows: (Following Blobel. Citation in SEE ALSO section.)

=over 2

=item *

Given C<N+1> random numbers C<u_j>.

=item *

For all C<j>, compare C<u_j> with C<u_j+1>. If C<u_j> is greater
then C<u_j+1>, assign a 0-Bit to the number. Otherwise, assign a
1-Bit.

=item *

Find all sequences of equal Bits. For every sequence, increment
a counter for the length C<k> of that sequence. (Regardless of whether it's
a sequence of 1's or 0's.)

=item *

For uncorrelated random numbers, the number of sequences C<N(k)>
of length C<k> in the set of C<N+1> random numbers is expected to be:

  N(k) = 2*((k^2+3*k+1)*N - (k^3+3*k^2-k-4)) / (k+3)!

=back

=head1 METHODS

=cut

=head2 new

Creates a new random number tester.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto)||$proto;

    my $self = {
        data => undef,
    };

    bless $self => $class;

    return $self;
}

=head2 set_data

Sets the random numbers to operate on. First argument
must be either an array reference to an array of random
numbers or a code reference.

If the first argument is a code reference, the second
argument must be an integer C<n>. The code reference is
called C<n>-times and its return values are used as
random numbers.

The code reference semantics are particularily useful if
you do not want to store all random numbers in memory at
the same time. You can write a subroutine that, for example,
generates and returns batches of 100 random numbers so no
more than 101 of these numbers will be in memory at the
same time. Note that if you return 100 numbers at once and
pass in C<n=50>, you will have a sequence of 5000 random
numbers.

=cut

sub set_data {
    my $self = shift;
    my $data = shift;
    if (_ARRAY($data)) {
        $self->{data} = $data;
        return 1;
    }
    elsif (_CODE($data)) {
        $self->{data} = $data;
        my $n = shift;
        if (not _POSINT($n)) {
            croak("'set_data' needs an integer as second argument if the first argument is a code reference.");
        }
        $self->{n} = $n;
        return 1;
    }
    else {
        croak("Invalid arguments to 'set_data'.");
    }
}

=head2 test

Runs the sequence test on the data that was previously set using
C<set_data>.

Returns three items: The first is the root mean square of the bin
residuals divided by the number of random numbers. It I<could> be
used as a measure for the quality of the random number generator
and should be as close to zero as possible. A better metric is to
compare the following two return values.

The second return value is a reference to the array of frequencies.
An example is in order here. Generating one million random numbers,
I get:

  [0, 416765, 181078, 56318, 11486, 1056, 150]

This means there were no sequences of length 0 (obvious), 416765
sequences of length 1, etc. There were no sequences of length 7 or
greater. This example is a bad random number generator! (It's a
linear congruent generator with C<(a*x_i+c)%m> and C<a=421>,
C<c=64773>, C<m=259200>, and C<x_0=4711>).

The third return value is similar in nature to the second in that it
is a reference to an array containing sequence length frequencies.
This one, however, contains the frequencies that would be expected for
the given number of random numbers, were they uncorrelated.
The number of bins has the maximum
length of an occurring sequence as an upper limit. In the given example,
you would get: (Dumped with Data::Dumper)

  $VAR1 = [
            '0',
            '416666.75',
            '183333.1',
            '52777.64722222222222222222222222222222222',
            '11507.89523809523809523809523809523809524',
            '2033.72068452380952380952380952380952381',
            '303.1287808641975308641975308641975308642',
            # ...
          ];

Note that where I put in a C<# ...>, you would really see a couple
more lines of numbers until the numbers go below an expected
frequency of C<0.1>.
For C<n=1000000> and C<k=7>, you get about
39 sequences, C<k=8> is expected to be found 4-5 times, etc.

=cut

sub test {
    my $self = shift;
    my $data = $self->{data};

    if (not defined $data) {
        croak("Set data using 'set_data' first.");
    }

    # bin counters
    my @bins;
    # current sequence type (> or <)
    my $current = undef;
    # current sequence length
    my $length = 0;
    # total number of random numbers
    my $numbers;

    if (_ARRAY($data)) {
        $current = ($data->[0] <=> $data->[1]) || 1;
        $length++;
        $numbers = @$data;

        foreach my $i (1 .. $#$data-1) {
            my $cmp = ($data->[$i] <=> $data->[$i+1]) || 1;
            if ($current == $cmp) {
                $length++;
            }
            else {
                $current = $cmp;
                $bins[$length]++;
                $length = 1;
            }
        }
        $bins[$length]++;
    }
    else { # CODE
        my @cache;
        my $calls = $self->{n};
        my $first_run = 1;
        foreach (1..$calls) {
            # get new data
            push @cache, $data->();
            # first run => initialize with first comparison
            if ($first_run and @cache > 1) {
                $current = ($cache[0] <=> $cache[1]) || 1;
                shift @cache;
                $length++;  # == 1
                $numbers++; # == 1
                $first_run = 0;
            }
            while (@cache > 1) {
                $numbers++;
                my $this = shift @cache;
                my $cmp = ($this <=> $cache[0]) || 1;
                if ($current == $cmp) {
                    $length++;
                }
                else {
                    $current = $cmp;
                    $bins[$length]++;
                    $length = 1;
                }
            }
        }
        $bins[$length]++;
    }

    my @expected = (0); # 0-bin is empty
    foreach my $bin (1..$#bins) {
        $expected[$bin] = expected_frequency($bin, $numbers-1);
    }
    my $last_bin = $#bins;
    while ($expected[$last_bin] > 0.1) {
        $last_bin++;
        $expected[$last_bin] = expected_frequency($last_bin, $numbers-1);
    }

    foreach my $bin (0..$last_bin) {
        $bins[$bin] = 0 if not defined $bins[$bin];
    }


    my @diff = map { abs($bins[$_] - $expected[$_]) } 0..$#bins;

    my $residual = 0;
    $residual += $_**2 for @diff;
    $residual = sqrt($residual);
    $residual = "$residual"; # de-bigfloatize

    @expected = map {"$_"} @expected; # de-bigfloatize

    return(
        $residual / ($numbers-1),
        \@bins,
        \@expected,
    );
}

=head1 SUBROUTINES

=head2 expected_frequency

Returns the expected frequency of the sequence length C<k>
in a set of C<n> random numbers assuming uncorrelated random
numbers.

Returns this as a L<Math::BigFloat>.

Expects C<k> and C<n> as arguments.

This subroutine is memoized. (See L<Memoize>.)

=cut

memoize('expected_frequency');
sub expected_frequency {
    my $k = Math::BigFloat->new(shift);
    my $n = Math::BigFloat->new(shift);
    return(
        2 * ( ($k**2 + 3*$k + 1)*$n - ($k**3 + 3*$k**2 - $k - 4) )
        / faculty($k+3)
    );
}

=head2 faculty

Computes the factulty of the first argument recursively as a
L<Math::BigFloat>. This subroutine is memoized. (See L<Memoize>.)

=cut

memoize('faculty');
sub faculty {
    my $n = shift;
    return Math::BigFloat->bone() if $n <= 1;
    return $n * faculty($n-1);
}

1;
__END__

=head1 SEE ALSO

L<Math::BigFloat>, L<Memoize>, L<Params::Util>

Random number generators:
L<Math::Random::MT>, L<Math::Random>, L<Math::Random::OO>,
L<Math::TrulyRandom>, C</dev/random> where available

The algorithm was taken from: (German)

Blobel, V., and Lohrmann, E. I<Statistische und numerische Methoden
der Datenanalyse>. Stuttgart, Leipzig: Teubner, 1998

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
