package Path::Hilbert::BigInt;

use 5.012;
use utf8;

use Math::BigRat try => 'GMP,Pari,Calc';
use Math::BigInt try => 'GMP,Pari,Calc';

use Exporter qw( import );

our @EXPORT = qw( xy2d d2xy );

our $VERSION = '2.000';

# optional constructor if you want OO-style
sub new {
    my $class = shift;
    my ($n) = @_;
    return bless { n => $n } => $class;
}

# convert (x,y) to d
sub xy2d {
    my ($side, $x, $y) = @_;
    my $n = _valid_n($side);
    ($x, $y) = map { Math::BigInt->new("$_") } ($x, $y);
    my $d = Math::BigInt->bzero();
    for (my $s = $n->copy()->brsft(1); $s->bcmp(0) > 0; $s->brsft(1)) {
        my $rx = Math::BigInt->new($x->copy()->band($s)->bcmp(0) > 0 ? "1" : "0");
        my $ry = Math::BigInt->new($y->copy()->band($s)->bcmp(0) > 0 ? "1" : "0");
        my $three_rx = $rx->copy()->bmul("3");
        my $s_squared = $s->copy()->bpow("2");
        $d->badd($s_squared->bmul($three_rx->bxor($ry)));
        ($x, $y) = _rot($s, $x, $y, $rx, $ry);
    }
    return Math::BigRat->new($d);
}

# convert d to (x,y)
sub d2xy {
    my ($side, $d) = @_;
    my $n = _valid_n($side);
    my $t = Math::BigInt->new($d);
    my ($x, $y) = map { Math::BigInt->bzero() } (1 .. 2);
    for (my $s = Math::BigInt->bone(); $s->bcmp($n) < 0; $s->blsft(1)) {
        my $rx = $t->copy()->brsft(1)->band(Math::BigInt->bone());
        my $ry = $t->copy()->bxor($rx)->band(Math::BigInt->bone());
        ($x, $y) = _rot($s, $x, $y, $rx, $ry);
        my $Dx = $s->copy()->bmul($rx);
        my $Dy = $s->copy()->bmul($ry);
        $Dx >= 0 ? $x->badd($Dx) : $x->bsub($Dx->copy()->babs());
        $Dy >= 0 ? $y->badd($Dy) : $y->bsub($Dy->copy()->babs());
        $t->brsft(2);
    }
    return map { Math::BigRat->new($_) } ($x, $y);
}

# rotate/flip a quadrant appropriately
sub _rot {
    my ($n, $x, $y, $rx, $ry) = @_;
    if (!$ry) {
        if ($rx > 0) {
            $x = $n - 1 - $x;
            $y = $n - 1 - $y;
        }
        ($x, $y) = ($y, $x);
    }
    return ($x, $y);
}

sub _valid_n {
    my $n = _extract_side(shift(@_));
    $n = 2 ** int((eval { (log($n) / log(2)) } || 0) + 0.5);
    return Math::BigInt->new(int($n));
}

sub _extract_side {
    my ($side) = @_;
    $side = $side->{ n } if ref($side) eq 'HASH' && exists $side->{ n };
    return $side;
}

1;

__END__

=head1 NAME

Path::Hilbert::BigInt - A slower, no-frills converter between very large 1D and 2D spaces using the Hilbert curve

=head1 VERSION

Version 2.000

=head1 SYNOPSIS

    use Path::Hilbert::BigInt;
    my ($x, $y) = d2xy(8192, 21_342_865);
    my $d = xy2d(8192, $x, $y);
    die unless $d == 21_342_865;

=head1 DESCRIPTION

See the documentation for L<Path::Hilbert>, except s/Path::Hilbert/Path::Hilbert::BigInt/ as needed.

=head1 AUTHOR

PWBENNETT <paul.w.bennett@gmail.com>

=head1 LICENSE

GNU LGLP 3.0 or newer.
