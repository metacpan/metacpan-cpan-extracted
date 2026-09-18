#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Struct::Codec qw(struct_encode struct_decode);

# AN NV WIDER THAN A DOUBLE.
#
# A perl built -Duselongdouble or -Dusequadmath carries more mantissa than the
# 8-byte wire float holds, so those values go out as decimal digits under tag
# 0x38 instead. This file is where that path is proven, and it has to say
# something true on BOTH kinds of perl: on a double perl the assertion is that
# the tag is never written and the bytes are exactly what they always were, and
# the hand-built streams at the end are decoded by every perl either way.
#
# 0.01 shipped the narrowing and a cpansmoker on a 5.40 -Duselongdouble build
# failed twelve subtests across three files, every one of them this.

sub rt { struct_decode(struct_encode($_[0])) }
sub tag { unpack 'C', substr(struct_encode($_[0]), 3, 1) }

my $WIDE = $Config{nvsize} > 8;
diag("nvsize=$Config{nvsize} nvtype=$Config{nvtype}"
     . ($Config{longdblkind} ? " longdblkind=$Config{longdblkind}" : ''));

my $NV     = 0x22;   # the 8-byte IEEE double
my $NV_STR = 0x38;   # decimal digits

# ---- the values the smoker reported -------------------------------------------------
# Every one of these is a literal the compiler builds at THIS perl's NV width,
# so a codec that narrowed it would hand back a different number. On a double
# perl they are already exact and this is the same test 0.01 passed.
{
    my @v = (0.1, -0.1, 1/3, 1e-300, 5e-324, 1.7976931348623157e308,
             123456789.123456789, 1e300, -1e300, 1/7, 2/3, -1/3);
    for my $f (@v) {
        my $o = rt($f);
        ok($o == $f, "$f round-trips to the same number");
        is("$o", "$f", '...and to the same string');
    }
}

# ---- a value only a wide NV can hold ------------------------------------------------
# 1/3 accumulated keeps filling the tail with bits a double has nowhere to put,
# so on a wide perl these are all past what narrowing could carry.
{
    my $acc = 1;
    for my $i (1 .. 12) {
        $acc = $acc / 3 + 1;
        ok(rt($acc) == $acc, "an accumulated fraction survives (round $i)");
    }
}

# ---- which tag each value gets ------------------------------------------------------
# The decimal path costs more than 8 bytes, so it must be taken ONLY where the
# double form would actually lose something. These are exact in binary at every
# NV width, so they are the 8-byte tag on every perl including a wide one.
{
    is(tag($_), $NV, "$_ is written as an 8-byte double") for 0.5, 0.25, 1.5, -2.75, 3.0, 1024.0;

    is(tag(9**9**9), $NV, 'an infinity is written as an 8-byte double');
    is(tag(-9**9**9), $NV, 'and a negative infinity');
    is(tag(-sin(9**9**9)), $NV, 'and a NaN, which is never decimal');
    is(tag(-0.0), $NV, 'and a negative zero');

    if ($WIDE) {
        is(tag($_), $NV_STR, "$_ needs the decimal form on this perl") for 0.1, 1/3;
    }
    else {
        is(tag($_), $NV, "$_ stays an 8-byte double on a double perl") for 0.1, 1/3;
        unlike(join('', map { sprintf '%02X', $_ } unpack 'C*', struct_encode(0.1)),
               qr/38/, 'a double perl never writes tag 0x38 at all');
    }
}

# ---- the specials still survive whichever tag they took ------------------------------
{
    my $inf = 9**9**9;
    ok(rt($inf) == $inf, 'an infinity round-trips');
    ok(rt(-$inf) == -$inf, 'and a negative one');
    my $nan = rt(-sin(9**9**9));
    ok($nan != $nan, 'a NaN round-trips as a NaN');
    is(sprintf('%.1f', rt(-0.0)), '-0.0', 'a negative zero keeps its sign');
}

# ---- floats nested where the seen table and the containers can reach them -------------
{
    my $f = 1/3;
    my $s = [$f, { k => $f }, \$f];
    my $o = rt($s);
    ok($o->[0] == $f && $o->[1]{k} == $f && ${$o->[2]} == $f,
       'a wide float survives inside an array, a hash and a ref');

    my @shared = (\my $x);
    $x = 1/7;
    push @shared, $shared[0];
    my $d = rt(\@shared);
    ok(${$d->[0]} == $x, 'a shared wide float keeps its value');
    is($d->[0], $d->[1], 'and is still shared');
}

# ---- the encoder wrote enough digits --------------------------------------------------
# The precision has to be enough that the encoder's own digits read back as the
# number they came from, and that is asserted on the bytes it really wrote. Not
# by working DECIMAL_DIG out again in Perl: $Config{longdblkind} describes long
# double, which on a quadmath perl is NOT the type the NV is, so a second
# derivation here would claim 21 digits for a 36-digit NV and fail a value the
# codec handles correctly. If the precision were ever a digit short this fails
# with a clearer reason than a random structure comparing unequal.
#
# Read back through the DECODER and not through perl's own numifier. Below 5.30
# Atof is a ULP or two out at the full width of a long double (perl RT #41202,
# fixed there by numifying through strtod), so `0 + $digits` is not an oracle on
# such a perl - it was two of the eight subtests every -Duselongdouble smoker
# below 5.30 failed on 0.03. Where perl does numify through strtod the stronger
# claim is made as well.
{
    my $seen = 0;
    for my $f (0.1, 1/3, 1/7, 1e300, 5e-324, 123456789.123456789) {
        my $b = struct_encode($f);
        next unless unpack('C', substr($b, 3, 1)) == $NV_STR;
        $seen++;
        my $digits = substr($b, 5);
        like($digits, qr/^-?[0-9][0-9.]*(?:[eE][-+]?[0-9]+)?$/, "$f went out as plain decimal");
        ok(struct_decode($b) == $f, "...and those digits read back as $f");
        ok(0 + $digits == $f, "...and perl itself reads them back as it too")
            if $] >= 5.030;
    }
    if ($WIDE) { ok($seen, "$seen of those needed the decimal form") }
    else       { is($seen, 0, 'a double perl needed the decimal form for none of them') }
}

# ---- and enough of them ---------------------------------------------------------------
# A floor on the digit count, which is not DECIMAL_DIG derived a second time:
# seventeen is what a plain double already needs, so a value a double could not
# hold must beat it. 0.03 wrote ONE significant digit on a quadmath perl - the
# precision went to quadmath_snprintf through a "%.*" it was never handed - and
# a third came back 0.3, which every assertion above catches only as a number
# that is not the one that went in.
if ($WIDE) {
    for my $f (0.1, 1/3, 1/7) {
        my $b = struct_encode($f);
        next unless unpack('C', substr($b, 3, 1)) == $NV_STR;
        cmp_ok((substr($b, 5) =~ tr/0-9//), '>=', 17,
               "$f went out with enough digits to be itself");
    }
}

# ---- a stream from the other kind of perl --------------------------------------------
# These bytes are what a wide perl writes. A double perl has to read them too -
# it lands on the nearest double, which is the same number it would have got
# from the 8-byte form - and a wide perl gets the value back exactly.
{
    my $hdr = "S1\x08";
    my $mk  = sub { my $s = shift; $hdr . "\x38" . chr(length $s) . $s };

    is(struct_decode($mk->('1.5')), 1.5, 'a decimal float decodes to its value');
    is(struct_decode($mk->('0.5')), 0.5, 'and another exact one');
    ok(struct_decode($mk->('-2.25')) == -2.25, 'and a negative');

    # 21 and 36 digits: one tenth as an x87 perl writes it and as a binary128
    # perl does. The two directions are NOT symmetrical and the assertion has to
    # say which is which.
    #
    # More digits than this perl holds is exact: the tail rounds away and the
    # value is this perl's own 0.1, whatever this perl is.
    ok(struct_decode($mk->('0.100000000000000000000000000000000005')) == 0.1,
       q{a decimal longer than this NV rounds to this perl's own 0.1})
        unless $WIDE && ($Config{longdblkind} || 0) == 3;

    # FEWER digits than this perl holds is not, and must not be. 21 digits are
    # the x87 perl's nearest tenth, and read on a binary128 they are that
    # number and not this one's nearest tenth - the decoder reproduces what the
    # writer had, it does not guess what the writer meant. So the assertion is
    # that a tenth survives to the precision the stream actually carried.
    for my $d ('0.100000000000000000001', '0.100000000000000000000000000000000005') {
        my $n   = ($d =~ tr/0-9//) - 1;
        my $got = struct_decode($mk->($d));
        cmp_ok(abs($got - 0.1), '<', 1e-18, "a $n-digit tenth from another perl is a tenth here");
    }

    # Near enough, not equal: the number on the right is built by the perl
    # reading this file, and below 5.30 that is Atof, which turns 1e300 into
    # 1.0000000000000006e+300 where the decoder - like the 8-byte form, and like
    # perl from 5.30 - gives 1.0000000000000001e+300. A decoder that misread an
    # exponent would be out by a power of ten and not by a few ULP.
    for my $d ('1e300', '-1.7976931348623157e+308') {
        my $want = 0 + $d;
        my $got  = struct_decode($mk->($d));
        cmp_ok(abs($got - $want), '<', abs($want) * 1e-13,
               "the exponent form $d decodes");
    }

    # The longest the encoder can write is 63 bytes, and 63 must be accepted:
    # the refusal in t/14-corrupt.t starts at 64.
    my $long = '0.' . ('1' x 60);
    is(length($long), 62, 'a 62-byte decimal is inside the limit');
    ok(defined struct_decode($mk->($long)), 'and decodes rather than being refused');
}

done_testing();
