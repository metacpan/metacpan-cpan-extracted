package Statistics::Distribution::Generator;

use strict;
use warnings;
use 5.018;
use utf8;
use overload (
    '0+' => '_render',
    '""' => '_render',
    '@{}' => '_render',
    '|' => '_add_alternative',
    'x' => '_add_dimension',
    fallback => 1,
);

use List::AllUtils qw( reduce );
use Exporter qw( import );
use vars qw( $VERSION );

$VERSION = '0.013';

sub logistic ();

our @EXPORT_OK = qw( gaussian uniform logistic supplied gamma exponential );
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $pi = 3.14159265358979323846264338327950288419716939937510;
our $two_pi = 2 * $pi;
our $e = exp 1;

sub _render {
    my $self = shift;
    if ($self->{ dims }) {
        return [ map { $_->_render } @{$self->{ dims }} ];
    }
    elsif ($self->{ alts }) {
        my $accum = reduce { $a + $b } map { $_->{ weight } // 1 } @{$self->{ alts }};
        my $n = rand() * $accum;
        my $answer;
        for my $alt (@{$self->{ alts }}) {
            $n -= ($alt->{ weight } // 1);
            if ($n <= 0) {
                $answer = $alt->_render;
                last;
            }
        }
        return $answer;
    }
    else {
        die "Something horrible has happened";
    }
}

sub gaussian {
    my ($mean, $sigma) = @_;
    $mean //= 0;
    $sigma //= 1;
    return bless { mean => $mean, sigma => $sigma }, 'Statistics::Distribution::Generator::gaussian';
}

sub uniform {
    my ($min, $max) = @_;
    $min //= 0;
    $max //= 1;
    return bless { min => $min, max => $max }, 'Statistics::Distribution::Generator::uniform';
}

sub logistic () {
    return bless { }, 'Statistics::Distribution::Generator::logistic';
}

sub supplied {
    my ($iv) = @_;
    my $rv;
    if (ref $iv eq 'CODE') {
        $rv = { code => $iv };
    }
    else {
        $rv = { code => sub { return $iv } };
    }
    return bless $rv, 'Statistics::Distribution::Generator::supplied';
}

sub gamma {
    my ($order, $scale) = map { $_ // 1 } @_;
    return bless {
        order => $order,
        scale => $scale,
        norder => int($order),
    }, 'Statistics::Distribution::Generator::gamma';
}

sub exponential {
    my ($lambda) = map { $_ // 1 } @_;
    return bless { lambda => $lambda }, 'Statistics::Distribution::Generator::exponential';
}

sub _rand_nonzero {
    my $rv;
    1 while (!($rv = rand));
    return $rv;
}

sub _gamma_int {
    my $order = shift;
    if ($order < 12){
        my $prod = 1;
        for (my $i=0; $i<$order; $i++){
            $prod *= _rand_nonzero();
        }
        return -log($prod);
    }
    else {
        return _gamma_large_int($order);
    }
}

sub _tan { sin($_[0]) / cos($_[0]); }

sub _gamma_large_int {
    my $order = shift;
    my $sqrt = sqrt(2 * $order - 1);
    my ($x,$y,$v);
    do {
        do {
            $y = _tan($pi * rand);
            $x = $sqrt * $y + $order - 1;
        } while ($x <= 0);
        $v = rand;
    } while ($v > (1 + $y * $y) * exp(($order - 1) * log($x / ($order - 1)) - $sqrt * $y));
    return $x;
}

sub _gamma_frac {
    my $order = shift;
    my $p = $e / ($order + $e);
    my ($q, $x, $u, $v);
    do {
        $u = rand;
        $v = _rand_nonzero();
        if ($u < $p){
            $x = exp((1 / $order) * log($v));
            $q = exp(-$x);
        }
        else {
            $x = 1 - log($v);
            $q = exp(($order - 1) * log($x));
        }
    } while (rand >= $q);
    return $x;
}

sub _add_alternative {
    my ($lhs, $rhs, $swapped) = @_;
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    $rhs = supplied($rhs) unless ref($rhs) =~ /^Statistics::Distribution::Generator/;
    my $self
        = ref($lhs) eq 'Statistics::Distribution::Generator'
        ? { %$lhs }
        : { alts => [ $lhs ] }
        ;
    bless $self, 'Statistics::Distribution::Generator';
    push @{$self->{ alts }}, $rhs;
    return $self;
}

sub _add_dimension {
    my ($lhs, $rhs, $swapped) = @_;
    ($lhs, $rhs) = ($rhs, $lhs) if $swapped;
    $rhs = supplied($rhs) unless ref($rhs) =~ /^Statistics::Distribution::Generator/;
    my $self
        = ref($lhs) eq 'Statistics::Distribution::Generator'
        ? { %$lhs }
        : { dims => [ $lhs ] }
        ;
    bless $self, 'Statistics::Distribution::Generator';
    push @{$self->{ dims }}, $rhs;
    return $self;
}

1;

package Statistics::Distribution::Generator::gaussian;

use strict;
use warnings;
use 5.018;
use utf8;
use base qw( Statistics::Distribution::Generator );
use overload (
    '0+' => '_render',
    '""' => '_render',
    '|' => '_add_alternative',
    'x' => '_add_dimension',
    fallback => 1,
);

sub _render {
    my $self = shift;
    my $U = rand;
    my $V = rand;
    return $self->{ mean } + (sqrt(-2 * log $U) * cos($two_pi * $V) * $self->{ sigma });
}

1;

package Statistics::Distribution::Generator::uniform;

use strict;
use warnings;
use 5.018;
use utf8;
use base qw( Statistics::Distribution::Generator );
use overload (
    '0+' => '_render',
    '""' => '_render',
    '|' => '_add_alternative',
    'x' => '_add_dimension',
    fallback => 1,
);

sub _render {
    my $self = shift;
    return ($self->{ max } - $self->{ min }) * rand() + $self->{ min };
}

1;

package Statistics::Distribution::Generator::logistic;

use strict;
use warnings;
use 5.018;
use utf8;
use base qw( Statistics::Distribution::Generator );
use overload (
    '0+' => '_render',
    '""' => '_render',
    '|' => '_add_alternative',
    'x' => '_add_dimension',
    fallback => 1,
);

sub _render {
    my $self = shift;
    return -log((1 / _rand_nonzero()) - 1);
}

1;

package Statistics::Distribution::Generator::supplied;

use strict;
use warnings;
use 5.018;
use utf8;
use base qw( Statistics::Distribution::Generator );
use overload (
    '0+' => '_render',
    '""' => '_render',
    '|' => '_add_alternative',
    'x' => '_add_dimension',
    fallback => 1,
);

sub _render {
    my $self = shift;
    return $self->{ code }->();
}

1;

package Statistics::Distribution::Generator::gamma;

use strict;
use warnings;
use 5.018;
use utf8;
use base qw( Statistics::Distribution::Generator );
use overload (
    '0+' => '_render',
    '""' => '_render',
    '|' => '_add_alternative',
    'x' => '_add_dimension',
    fallback => 1,
);

sub _render {
    my $self = shift;
    my $rv;
    if ($self->{ order } == $self->{ norder }) {
        $rv = $self->{ scale } * _gamma_int($self->{ norder });
    }
    elsif ($self->{ norder } == 0) {
        $rv = $self->{ scale } * _gamma_frac($self->{ order });
    }
    else {
        $rv = $self->{ scale } * (_gamma_int($self->{ norder }) + _gamma_frac($self->{ norder } - $self->{ order }));
    }
    return $rv;
}

1;

package Statistics::Distribution::Generator::exponential;

use strict;
use warnings;
use 5.018;
use utf8;
use base qw( Statistics::Distribution::Generator );
use overload (
    '0+' => '_render',
    '""' => '_render',
    '|' => '_add_alternative',
    'x' => '_add_dimension',
    fallback => 1,
);

sub _render {
    my $self = shift;
    my $rv = -log(rand) / $self->{ lambda };
}

1;

__END__

=head1 NAME

Statistics::Distribution::Generator - A way to compose complicated probability
functions

=head1 VERSION

Version 0.013

=head1 SYNOPSIS

    use Statistics::Distribution::Generator qw( :all );
    my $g = gaussian(3, 1);
    say $g; # something almost certainly between -3 and 9, but probably about 2 .. 4-ish
    my $cloud = gaussian(0, 1) x gaussian(0, 1) x gaussian(0, 1);
    say @$cloud; # a 3D vector almost certainly within (+/- 6, +/- 6, +/- 6) and probably within (+/- 2, +/- 2, +/- 2)
    my $combo = gaussian(100, 15) | uniform(0, 200); # one answer with an equal chance of being picked from either distribution

=head1 DESCRIPTION

This module allows you to bake together multiple "simple" probability
distributions into a more complex random number generator. It does this lazily:
when you call one of the PDF generating functions, it makes an object, the
value of which is not calculated at creation time, but rather re-calculated
each and every time you try to read the value of the object. If you are
familiar with Functional Programming, you can think of the exported functions
returning functors with their "setup" values curried into them.

To this end, two of Perl's operators (B<x> and B<|>) have been overloaded with
special semantics.

The B<x> operator composes multiple distributions at once, giving an ARRAYREF
of "answers" when interrogated, which is designed primarily to be interpreted
as a vector in N-dimensional space (where N is the number of elements in the
ARRAYREF).

The B<|> operator composes multiple distributions into a single value, giving
a SCALAR "answer" when interrogated. It does this by picking at random between
the composed distributions (which may be weighted to give some higher
precendence than others).

I<The first thing to note> is that B<x> and B<|> have their I<normal> Perl
precendence and associativity. This means that parens are B<strongly> advised
to make your code more readable. This may be fixed in later versions of this
module, by messing about with the L<B> modules, but that would still not make
parens a bad idea.

I<The second thing to note> is that B<x> and B<|> may be "nested" arbitrarily
many levels deep (within the usual memory & CPU limits of your computer, of
course). You could, for instance, compose multiple "vectors" of different sizes
using B<x> to form each one, and select between them at random with X<|>, e.g.

    my $forwards = gaussian(0, 0.5) x gaussian(3, 1) x gaussian(0, 0.5);
    my $backwards = gaussian(0, 0.5) x gaussian(-3, 1) x gaussian(0, 0.5);
    my $left = gaussian(-3, 1) x gaussian(0, 0.5) x gaussian(0, 0.5);
    my $right = gaussian(3, 1) x gaussian(0, 0.5) x gaussian(0, 0.5);
    my $up = gaussian(0, 0.5) x gaussian(0, 0.5) x gaussian(3, 1);
    my $down = gaussian(0, 0.5) x gaussian(0, 0.5) x gaussian(-3, 1);
    my $direction = $forwards | $backwards | $left | $right | $up | $down;
    $robot->move(@$direction);

You are strongly encouraged to seek further elucidation at Wikipedia or any
other available reference site / material.

=head1 EXPORTABLE FUNCTIONS

=over

=item gaussian(MEAN, SIGMA)

Gaussian Normal Distribution. This is the classic "bell curve" shape. Numbers
close to the MEAN are more likely to be selected, and the value of SIGMA is
used to determine how unlikely more-distant values are. For instance, about 2/3
of the "answers" will be in the range (MEAN - SIGMA) Z<><= N Z<><= (MEAN +
SIGMA), and around 99.5% of the "answers" will be in the range (MEAN - 3 * SIGMA)
Z<><= N Z<><= (MEAN + 3 * SIGMA). "Answers" as far away as 6 * SIGMA are
approximately a 1 in a million long shot.

=back

=over

=item uniform(MIN, MAX)

A Uniform Distribution, with equal chance of any N where MIN Z<><= N Z<>< MAX.
This is equivalent to Perl's standard C<rand()> function, except you supply the
MIN and MAX instead of allowing them to fall at 0 and 1 respectively. Any value
within the range I<should> be equally likely to be chosen, provided you have a
"good" random number generator in your computer.

=back

=over

=item logistic

The Logistic Distribution is used descriptively in a wide variety of fields
from market research to the design of neural networks, and is also known as the
I<hyperbolic secant squared> distribution.

=back

=over

=item supplied(VALUE)

=item supplied(CALLBACK)

Allows the caller to supply either a constant VALUE which will always be
returned as is, or a coderef CALLBACK that may use any algorithm you like to
generate a suitable random number. For now, B<this is the main plugin methodology>
for this module. The supplied CALLBACK is given no arguments, and B<SHOULD>
return a numeric answer. If it returns something non-numeric, you are entirely
on your own in how to interpret that, and you are probably doing it wrongly.

=back

=over

=item gamma(ORDER, SCALE)

The Gamma Distribution function is a generalization of the chi-squared and
exponential distributions, and may be given by

    p(x) dx = {1 \over \Gamma(a) b^a} x^{a-1} e^{-x/b} dx
    for x > 0.

The ORDER argument corresponds to what is also known as the "shape parameter"
I<k>, and the SCALE argument corresponds to the "scale parameter" I<theta>.

If I<k> is an integer, the Gamma Distribution is equivalent to the sum of I<k>
exponentially-distributed random variables, each of which has a mean of I<theta>.

=back

=over

=item exponential(LAMBDA)

The Exponential Distribution function is often useful when modeling /
simulating the time between events in certain types of system. It is also used
in reliability theory and the Barometric formula in physics.

=back

=head1 OVERLOADED OPERATORS

=over

=item x

Allows you to compose multi-dimensional random vectors.

    $randvect = $foo x $bar x $baz; # generate a three-dimensional vector

=back

=over

=item |

Allows you to pick a single (optionally weighted) generator from some set of
generators.

    $cointoss = supplied 0 | supplied 1; # fair 50:50 result of either 0 or 1

=back

=head1 OBJECT ATTRIBUTES

=over

=item $distribution->{ weight }

This setting may be used to make B<|>-based selections favor one or more
outcomes more (or less) than the remaining outcomes. The default weight for all
outcomes is 1. Weights are relative, not absolute, so may be scaled however you
need.

    $foo = exponential 1.5;
    $bar = gaussian 20, 1.25;
    $foo->{ weight } = 6;
    $quux = $foo | $bar; # 6:1 chance of picking $foo instead of $bar

=back

=head1 AUTHOR

The main body of this work is by Paul W Bennett

The idea of composing probabilities together is inspired by work done by Sooraj
Bhat, Ashish Agarwal, Richard Vuduc, and Alexander Gray at Georgia Tech and
NYU, published around the end of 2011.

The implementation of the Gamma Distribution is by Nigel Wetters Gourlay.

=head1 CAVEATS

Almost no error checking is done. Garbage in I<will> result in garbage out.

This is B<ALPHA> quality software. Any aspect of it, including the API and core functionality, is likely to change at any time.

=head1 TODO

Build in more probability density functions.

Tests. Lots of very clever tests.

=head1 LICENSE

Artistic 2.0

=cut
