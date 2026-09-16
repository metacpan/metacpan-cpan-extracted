#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Scalar::Util qw(refaddr blessed);
use Struct::Codec qw(struct_encode struct_decode);

# EDGES.
#
# The encoder writes the first 512 bytes on the stack and moves to an SV when
# it outgrows them; the depth limit is 4096; a varint is at most ten bytes; a
# short string is at most 31. Every one of those is a place where an
# off-by-one hides, so each is crossed here one byte at a time, and the odd
# values perl can hold - sparse arrays, restricted hashes, overloaded objects,
# magical variables - go through too.

sub rt { struct_decode(struct_encode($_[0])) }

# ---- the stack buffer boundary ----------------------------------------------------
{
    # A byte string of n > 31 bytes encodes as 3 (header) + 1 (tag) + 2
    # (varint, n >= 128) + n bytes. So n = 506 is 512 bytes exactly.
    for my $n (504 .. 510) {
        my $s = 'x' x $n;
        my $b = struct_encode($s);
        is(length $b, 6 + $n, "a $n-byte string encodes to " . (6 + $n) . ' bytes');
        is(rt($s), $s, "and round-trips across the 512-byte stack boundary");
    }

    # A shared referent whose first tag is on the stack and whose second
    # reference arrives after the move to an SV: the TRACK patch must land in
    # the SV, not in the stack copy that was left behind.
    my $s = [1];
    my $d = [ $s, 'x' x 600, $s ];
    my $b = struct_encode($d);
    is(ord(substr($b, 6, 1)) & 0x80, 0x80, 'the first REF tag, written on the stack, carries TRACK after the move');
    my $o = struct_decode($b);
    is(refaddr($o->[0]), refaddr($o->[2]), 'and the sharing survives');
    is(length $o->[1], 600, 'with the long string intact');

    # And the other way: everything after the move.
    my $e = [ 'x' x 600, $s, $s ];
    my $oe = rt($e);
    is(refaddr($oe->[1]), refaddr($oe->[2]), 'sharing entirely after the move survives too');
}

# ---- the depth limit, exactly ----------------------------------------------------------
{
    my $nest = sub {
        my $n = shift;
        my $inner = 5;
        my $v = $inner;
        $v = [$v] for 1 .. $n;
        return $v;
    };
    # n arrays around a scalar is n + 1 values deep.
    ok(eval { struct_encode($nest->(4095)); 1 }, '4095 nested arrays around a scalar (depth 4096) encode');
    ok(!eval { struct_encode($nest->(4096)); 1 }, 'and 4096 (depth 4097) are refused');
    like($@, qr/deeper than 4096/, '...by name');

    my $hdr = "S1\x08";
    ok(eval { struct_decode($hdr . ("\x28\x2B\x01" x 4095) . "\x05"); 1 }, 'the decoder accepts depth 4096');
    ok(!eval { struct_decode($hdr . ("\x28\x2B\x01" x 4096) . "\x05"); 1 }, 'and refuses 4097');
    like($@, qr/structure too deep/, '...by name');
}

# ---- string length boundaries -------------------------------------------------------
{
    for my $n (30, 31, 32, 33, 127, 128, 129, 16383, 16384, 16385) {
        my $s = 'y' x $n;
        is(rt($s), $s, "a $n-byte string round-trips");
        my $u = "\x{263a}" x $n;
        is(rt($u), $u, "and $n wide characters");
    }
    is(rt("\0" x 1000), "\0" x 1000, 'a thousand NULs');
    my $mb = join '', map { chr($_ % 256) } 0 .. (1024 * 1024 - 1);
    is(rt($mb), $mb, 'a megabyte of every byte value');
}

# ---- numbers at their edges -------------------------------------------------------------
{
    my @n = (0, 1, -1, 15, 16, -16, -17, 127, 128, 255, 256, 65535, 65536,
             2**31 - 1, 2**31, -(2**31), 2**32 - 1, 2**32, 2**53, -(2**53));
    push @n, 9223372036854775807, -9223372036854775808, 18446744073709551615
        if $Config{ivsize} >= 8;
    for my $v (@n) {
        my $o = rt($v);
        is($o, $v, "$v round-trips");
        ok($o == $v, '...and compares numerically');
    }
    for my $f (0.1, -0.1, 1/3, 1e-300, 5e-324, 1.7976931348623157e308, 123456789.123456789) {
        is(rt($f), $f, "$f round-trips as a float");
    }
}

# ---- keys at their edges ----------------------------------------------------------------
{
    my %h = (
        ''        => 'empty',
        "\0"      => 'nul',
        "a\0b"    => 'embedded nul',
        'x' x 300 => 'long',
        '01'      => 'leading zero',
        '1.0'     => 'looks numeric',
        "\xff"    => 'high byte',
        "k\x{263a}" => 'wide',
        42        => 'was a number',
    );
    my $o = rt(\%h);
    is_deeply($o, \%h, 'awkward keys round-trip');
    is(scalar keys %$o, scalar keys %h, 'and none merged');
    ok(exists $o->{''}, 'the empty key is a key');
    ok(utf8::is_utf8((grep { /\x{263a}/ } keys %$o)[0]), 'the wide key kept its flag');
}

# ---- what perl can hold that a literal cannot say ---------------------------------------
{
    my @sparse;
    $sparse[3] = 'four';
    my $o = rt(\@sparse);
    is_deeply($o, [undef, undef, undef, 'four'], 'a sparse array comes back with undef in the holes');
    is(scalar @$o, 4, 'and the same length');

    SKIP: {
        eval { require Hash::Util; 1 } or skip 'no Hash::Util', 3;
        skip 'this Hash::Util has no lock_ref_keys', 3
            unless defined &Hash::Util::lock_ref_keys;
        my %r = (a => 1);
        # lock_ref_keys, not lock_keys: a prototype does not apply to a call
        # made by full name after a runtime import
        Hash::Util::lock_ref_keys(\%r, qw(a b c));
        my $ro = eval { rt(\%r) };
        is_deeply($ro, { a => 1 }, q{a restricted hash encodes its real keys only, not the placeholders})
            or diag $@;
        is(scalar($ro ? keys %$ro : -1), 1, q{one key});
        ok($ro && eval { $ro->{new} = 1; 1 }, q{and comes back unrestricted});
    }

    {
        package Ov;
        use overload '""' => sub { die "stringified an Ov\n" },
                     'bool' => sub { 1 }, '==' => sub { 0 }, fallback => 0;
    }
    my $ov = bless { v => 7 }, 'Ov';
    my $oo;
    ok(eval { $oo = rt({ o => $ov, list => [$ov, $ov] }); 1 }, 'an overloaded object is not stringified on the way in')
        or diag $@;
    is(blessed($oo->{o}), 'Ov', 'and comes back its class');
    is($oo->{o}{v}, 7, 'with its contents');
    is(refaddr($oo->{list}[0]), refaddr($oo->{list}[1]), 'shared as before');

    "abc" =~ /(b)/;
    is(rt($1), 'b', 'a capture variable encodes as its value');
    is(rt($ENV{PATH}), $ENV{PATH}, 'an %ENV element encodes as its value');
    my $env = rt(\%ENV);
    is(scalar keys %$env, scalar keys %ENV, 'and %ENV itself as a plain hash of the same keys');
    is(rt($0), $0, 'and $0');
    my $sub = 'abcdef';
    is(rt(substr($sub, 2, 2)), 'cd', 'a substr as its value');
    is(rt("$sub"), 'abcdef', 'a stringified value as itself');
}

# ---- references at depth -------------------------------------------------------------
{
    my $x = 5;
    my $rrr = \\\$x;
    my $o = rt($rrr);
    is($$$$o, 5, 'a reference to a reference to a reference comes back three deep');
    is(ref $o, 'REF', 'REF');
    is(ref $$o, 'REF', 'REF');
    is(ref $$$o, 'SCALAR', 'SCALAR');

    my $shared = \$x;
    my $two = rt([ \$shared, \$shared ]);
    is(refaddr(${ $two->[0] }), refaddr(${ $two->[1] }), 'two refs to one ref-holding scalar share it');
    is(${ ${ $two->[0] } }, 5, 'and it still points at the value');

    my $empty = rt([ [], {}, [[]], { a => {} }, \'' ]);
    is_deeply($empty, [ [], {}, [[]], { a => {} }, \'' ], 'empty containers of every kind');

    my $mixed = rt(bless [ bless {}, 'In::Hash' ], 'Out::List');
    is(blessed($mixed), 'Out::List', 'a blessed array of');
    is(blessed($mixed->[0]), 'In::Hash', 'a blessed hash');
    is(blessed(rt(bless \(my $s = 1), 'main')), 'main', 'blessed into main');
    is(blessed(rt(bless {}, 'A::B::C9::_d')), 'A::B::C9::_d', 'a long class name');
}

done_testing;
