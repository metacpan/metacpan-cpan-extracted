package POMurmur;
# MurmurHash3 x64 128, in Perl, written independently of the C.
#
# WHY THIS EXISTS, AND WHAT IT DOES NOT PROVE.
#
# No MurmurHash3 reference is available on this machine - no Digest::Murmur*,
# no python mmh3, nothing in the tree - so the C implementation cannot be
# checked against a published constant here. Rather than assert vectors from
# memory (which is precisely the naive-probe mistake: a fabricated vector
# either passes vacuously or fails for the wrong reason), this is a second
# implementation, coded separately, in a different language, with different
# arithmetic.
#
# It catches implementation slips - a wrong rotation, a dropped tail case, a
# mis-ordered finalisation. It does NOT catch a shared misreading of the
# algorithm, because both implementations came from the same head. External
# vector verification is still owed and is recorded as such.
#
# Requires 64-bit integers. Skipped by the caller where UVSIZE < 8.
use strict;
use warnings;
use Math::BigInt;

use constant MASK => Math::BigInt->new(2)->bpow(64)->bsub(1);

# Everything below is Math::BigInt.
#
# The first attempt used native 64-bit arithmetic and was WRONG: in _mul,
# $ll + $lh + $hl can exceed UV_MAX, at which point perl promotes the sum to
# an NV and silently loses the low bits. The result was a hash that returned
# all-ones for every input - obviously broken, but it could as easily have
# been subtly broken.
#
# A reference implementation exists to be OBVIOUSLY correct, not fast. It runs
# over a few hundred short inputs in a test; BigInt costs nothing that matters
# here and removes the entire class of overflow question.
sub _b { Math::BigInt->new(ref $_[0] ? $_[0]->bstr : "$_[0]") }

sub _mul { (_b($_[0])->bmul(_b($_[1])))->band(MASK) }

sub _add { (_b($_[0])->badd(_b($_[1])))->band(MASK) }

sub _xor { (_b($_[0])->bxor(_b($_[1])))->band(MASK) }

sub _shr { _b($_[0])->copy->brsft($_[1]) }

sub _rotl {
    my ($x, $r) = @_;
    my $b = _b($x);
    return $b->copy->blsft($r)->band(MASK)
             ->bior($b->copy->brsft(64 - $r))->band(MASK);
}

sub _fmix {
    my ($k) = @_;
    $k = _xor($k, _shr($k, 33));
    $k = _mul($k, Math::BigInt->new('0xff51afd7ed558ccd'));
    $k = _xor($k, _shr($k, 33));
    $k = _mul($k, Math::BigInt->new('0xc4ceb9fe1a85ec53'));
    $k = _xor($k, _shr($k, 33));
    return $k;
}

# Returns (h1, h2) as Math::BigInt.
sub hash128 {
    my ($key, $seed) = @_;
    $seed = 0 unless defined $seed;

    my $len     = length $key;
    my $nblocks = int($len / 16);
    my $h1 = _b($seed);
    my $h2 = _b($seed);
    my $c1 = Math::BigInt->new('0x87c37b91114253d5');
    my $c2 = Math::BigInt->new('0x4cf5ad432745937f');

    for my $i (0 .. $nblocks - 1) {
        my $chunk = substr($key, $i * 16, 16);
        my $k1 = _le(substr($chunk, 0, 8));
        my $k2 = _le(substr($chunk, 8, 8));

        $k1 = _mul($k1, $c1); $k1 = _rotl($k1, 31); $k1 = _mul($k1, $c2);
        $h1 = _xor($h1, $k1);
        $h1 = _rotl($h1, 27); $h1 = _add($h1, $h2);
        $h1 = _add(_mul($h1, 5), 0x52dce729);

        $k2 = _mul($k2, $c2); $k2 = _rotl($k2, 33); $k2 = _mul($k2, $c1);
        $h2 = _xor($h2, $k2);
        $h2 = _rotl($h2, 31); $h2 = _add($h2, $h1);
        $h2 = _add(_mul($h2, 5), 0x38495ab5);
    }

    my $tail = substr($key, $nblocks * 16);
    my $n = length $tail;
    my $k1 = Math::BigInt->bzero;
    my $k2 = Math::BigInt->bzero;

    for my $i (reverse 8 .. 14) {
        next if $n < $i + 1;
        $k2 = _xor($k2, _b(ord(substr($tail, $i, 1)))->blsft(($i - 8) * 8));
    }
    if ($n >= 9) {
        $k2 = _mul($k2, $c2); $k2 = _rotl($k2, 33); $k2 = _mul($k2, $c1);
        $h2 = _xor($h2, $k2);
    }

    for my $i (reverse 0 .. 7) {
        next if $n < $i + 1;
        $k1 = _xor($k1, _b(ord(substr($tail, $i, 1)))->blsft($i * 8));
    }
    if ($n >= 1) {
        $k1 = _mul($k1, $c1); $k1 = _rotl($k1, 31); $k1 = _mul($k1, $c2);
        $h1 = _xor($h1, $k1);
    }

    $h1 = _xor($h1, $len); $h2 = _xor($h2, $len);
    $h1 = _add($h1, $h2);
    $h2 = _add($h2, $h1);
    $h1 = _fmix($h1);
    $h2 = _fmix($h2);
    $h1 = _add($h1, $h2);
    $h2 = _add($h2, $h1);

    return ($h1, $h2);
}

# Eight bytes little-endian to a BigInt.
sub _le {
    my ($s) = @_;
    my $v = Math::BigInt->bzero;
    for my $i (reverse 0 .. 7) {
        $v->blsft(8);
        $v->badd(ord(substr($s, $i, 1)));
    }
    return $v;
}

sub hash128_hex {
    my ($key, $seed) = @_;
    my ($h1, $h2) = hash128($key, $seed);
    my $f = sub { (my $h = lc $_[0]->as_hex) =~ s/\A0x//; ('0' x (16 - length $h)) . $h };
    return $f->($h2) . $f->($h1);   # hi then lo, as the C stores it
}

1;
