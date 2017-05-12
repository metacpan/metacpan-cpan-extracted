package Path::Hilbert;

use 5.012;
use utf8;

use Exporter qw( import );

our @EXPORT = qw( xy2d d2xy );

our $VERSION = '2.000';

BEGIN {
    if (eval "require Path::Hilbert::XS") {
        *xy2d = \&Path::Hilbert::XS::xy2d;
        *d2xy = \&Path::Hilbert::XS::d2xy;
    }
    else {
        *xy2d = \&_xy2d;
        *d2xy = \&_d2xy;
    }
};

# optional constructor if you want OO-style
sub new {
    my $class = shift;
    my ($n) = @_;
    return bless { n => $n } => $class;
}

# convert (x,y) to d
sub _xy2d {
    my ($side, $x, $y) = @_;
    my $n = _valid_n($side);
    my ($X, $Y) = map { int($_ + 0.5) } ($x, $y);
    my $D;
    {
        use integer;
        my $d = 0;
        my ($x, $y) = map { int($_) } ($X, $Y);
        for (my $s = $n / 2; $s > 0; $s /= 2) {
            my $rx = ($x & $s) > 0;
            my $ry = ($y & $s) > 0;
            $d += $s * $s * ((3 * $rx) ^ $ry);
            ($x, $y) = _rot($s, $x, $y, $rx, $ry);
        }
        no integer;
        $D = $d;
    }
    return $D * _side_scale($side);
}

# convert d to (x,y)
sub _d2xy {
    my ($side, $d) = @_;
    my $n = _valid_n($side);
    my $T = int($d + 0.5);
    my ($X, $Y);
    {
        use integer;
        my ($x, $y) = (0, 0);
        my $t = int($T);
        for (my $s = 1; $s < $n; $s *= 2) {
            my $rx = 1 & ($t / 2);
            my $ry = 1 & ($t ^ $rx);
            ($x, $y) = _rot($s, $x, $y, $rx, $ry);
            $x += $s * $rx;
            $y += $s * $ry;
            $t /= 4;
        }
        no integer;
        ($X, $Y) = ($x, $y);
    }
    return map { _side_scale($side) * $_ } ($X, $Y);
}

# rotate/flip a quadrant appropriately
sub _rot {
    use integer;
    my ($n, $x, $y, $rx, $ry) = map { int($_) } @_;
    if (!$ry) {
        if ($rx) {
            $x = $n - 1 - $x;
            $y = $n - 1 - $y;
        }
        ($x, $y) = ($y, $x);
    }
    return ($x, $y);
}

sub _valid_n {
    my $n = _extract_side(shift(@_));
    no integer;
    my $rv = 2 ** int((log($n) / log(2)) + 0.5);
    use integer;
    return int($rv);
}

sub _extract_side {
    my ($n) = @_;
    $n = $n->{ n } if ref($n);
    return $n;
}

sub _side_scale {
    my $side = _extract_side(shift(@_));
    my $n = _valid_n($side);
    return $side / $n;
}

1;

__END__

=head1 NAME

Path::Hilbert - A no-frills converter between 1D and 2D spaces using the Hilbert curve

=head1 VERSION

Version 2.000

=head1 SYNOPSIS

    use Path::Hilbert;
    my ($x, $y) = d2xy(16, 127);
    my $d = xy2d(16, $x, $y);
    die unless $d == 127;

    my $space = Path::Hilbert->new(16);
    my ($u, $v) = $space->d2xy(127);
    my $t = $space->xy2d($u, $v);
    die unless $t == 127;

=head1 DESCRIPTION

See Wikipedia for a description of the Hilbert curve, and why it's a good idea.

Most (all?) of the existing CPAN modules for dealing with Hilbert curves state
"only works for $foo data", "optimized for $foo situations", or "designed to
work as part of the $foo framework".

This module is based directly on the example algorithm given on Wikipedia,
except it is not subject to the strict limitation of "proper" Hilbert curves,
which is that the side-length I<$n> MUST be a non-negative integer power of 2.

If you supply an "invalid but sane" side length (i.e. any positive number), be
fore-warned that you'll get a non-integer answer. Unfortunately, I haven't yet
worked out how to make this particular algorithm work with non-integer I<inputs>
for I<$d>, or I<($x, $y)>, so if you supply such, they'll be rounded to the nearest
integer before being fed into the algorithm. So far, I have not found a
practical real-world use-case where the rounding-error is significant -- except
perhaps in the case of very small (single digit or less) side lengths, but
I hereby advise you to pre- and post-scale the arguments and return values by
some sane amount as the best workaround.

=head2 Function-Oriented Interface

=over

=item ($X, $Y) = d2xy($SIDE, $INDEX)

Returns the X and Y coordinates (each in the range 0 .. n - 1) of the supplied
INDEX (in the range 0 .. SIDE ** 2 - 1), where SIDE itself is an integer power
of 2.

=back

=over

=item $INDEX = xy2d($SIDE, $X, $Y)

Returns the INDEX (in the range 0 .. SIDE ** 2 - 1) of the point corresponding
to the supplied X and Y coordinates (each in the range 0 .. n - 1), where SIDE
itself is an integer power of 2.

=back

=head2 Object-Oriented Interface

=over

=item $object = Path::Hilbert->new(SIDE)

Create a new Path::Hilbert object with the specified SIDE (which must be an
integer power of 2).

=back

=over

=item ($X, $Y) = $object->d2xy($INDEX)

Returns the X and Y coordinates (each in the range 0 .. n - 1) of the supplied
INDEX (in the range 0 .. SIDE ** 2 - 1), where SIDE was provided via new().

=back

=over

=item $INDEX = $object->xy2d($X, $Y)

Returns the INDEX (in the range 0 .. SIDE ** 2 - 1) of the point corresponding
to the supplied X and Y coordinates (each in the range 0 .. n - 1), where SIDE
was provided via new().

=back

=head1 AUTOMATIC USE OF XS

As of v2.000, this module automatically loads and uses L<Path::Hilbert::XS> if
possible (i.e. when that module is installed), except when
L<Path::Hilbert::BigInt> is requested (which still tries GMP, Pari, and
FastCalc in that order, all of which are slower than even the non-XS module).

=head1 CAVEATS

If your platform has I<$n> bit integers, things will go badly if you try a side
length longer than I<2 ** ($n / 2)>. If you need enormous Hilbert spaces, you should
try L<Path::Hilbert::BigInt>, which uses L<Math::BigInt> instead of the native
C<integer> support for your platform.

=head1 BUGS

Please let me know via the CPAN RT if you find any algorithmic defects.

=head1 AUTHOR

PWBENNETT <paul.w.bennett@gmail.com>

=head1 LICENSE

GNU LGPL 3.0 or newer.
