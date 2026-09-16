#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Struct::Codec qw(struct_encode struct_decode);

# ENCODE INTO A BUFFER SOMEBODY ELSE OWNS.
#
# encode_to is the ABI entry a fixed-slot store calls: it writes into caller
# memory of a fixed capacity, and when the value does not fit it writes
# nothing past the capacity, allocates nothing, and says how much it needed.
# _encode_to is the private XSUB that exposes it to a test, with a buffer of
# exactly the capacity asked for, so a byte written past it is a byte written
# past a malloc'd block.

my $s = [1, 2];
my @fixtures = (
    5, -300, 1.5, '', 'x' x 40, "caf\x{e9}", [1, [2, [3]]],
    { a => { b => 'c' } }, bless({ k => 1 }, 'Fit'), [$s, $s], \\5,
    { map { ("k$_" => "v$_") } 1 .. 100 },          # over the stack buffer
    [ ($s) x 40 ],                                   # many REFPs
);

for my $i (0 .. $#fixtures) {
    my $v = $fixtures[$i];
    my $want = struct_encode($v);
    my $len  = length $want;

    my ($got, $need) = Struct::Codec::_encode_to($v, $len);
    is($got, $want, "fixture $i: a buffer of exactly the size fills with the same bytes");
    is($need, $len, '...and need is that size');

    ($got, $need) = Struct::Codec::_encode_to($v, $len + 100);
    is($got, $want, '...a bigger buffer gives the same bytes, no padding');
    is($need, $len, '...and the same need');

    ($got, $need) = Struct::Codec::_encode_to($v, $len - 1);
    ok(!defined $got, '...one byte short is a refusal');
    is($need, $len, '...that says what would have fit');

    ($got, $need) = Struct::Codec::_encode_to($v, 0);
    ok(!defined $got, '...and so is no room at all');
    is($need, $len, '...with the same answer');

    ($got, $need) = Struct::Codec::_encode_to($v, int($len / 2));
    ok(!defined $got, '...and half the room');
    is($need, $len, '...with the same answer, whatever the cut left half-written');
}

# A shared referent whose FIRST tag falls inside a too-small buffer and whose
# second reference falls outside: the TRACK patch of the first tag is a write
# inside the buffer, and the patch must not be attempted where the tag was
# never written. Either way, need must be right and nothing must crash.
{
    my $r = [ 'x' x 20 ];
    my $v = [ $r, 'y' x 100, $r ];
    my $want = struct_encode($v);
    for my $cap (0, 4, 8, 30, 60, 120, length($want) - 1) {
        my ($got, $need) = Struct::Codec::_encode_to($v, $cap);
        ok(!defined $got, "capacity $cap refuses the shared structure");
        is($need, length $want, '...and reports the full need');
    }
    my ($got) = Struct::Codec::_encode_to($v, length $want);
    is($got, $want, 'and at the full size the bytes, TRACK bit included, match encode');
    my $d = struct_decode($got);
    is($d->[0], $d->[2], 'and decode to a shared referent');
}

# A refusal is the same refusal, whatever the buffer.
{
    my $err = '';
    my $captured = 1;
    eval { Struct::Codec::_encode_to([ sub { $captured } ], 1000); 1 } or $err = $@;
    like($err, qr/Struct::Codec: cannot encode a closure/, 'a value that cannot be encoded croaks the same way through encode_to');
    my ($got, $need) = Struct::Codec::_encode_to(5, 4);
    is($got, "S1\x08\x05", 'and the next call is unaffected');
}

done_testing;
