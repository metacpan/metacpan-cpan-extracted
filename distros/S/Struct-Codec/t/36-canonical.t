use strict;
use warnings;
use Test::More;
use Struct::Codec qw(struct_encode struct_decode);

# canonical => 1: every hash's keys in order, so equal data is equal bytes
# whatever order the hashes hold them in, in this process or another.

sub shuffled {
    my (@k) = @_;
    my %h;
    for my $i (reverse 1 .. @k) { my $j = int rand $i; @k[ $i - 1, $j ] = @k[ $j, $i - 1 ] }
    $h{$_} = length $_ for @k;
    return \%h;
}

# ---- the same bytes, however the hash was built -----------------------------------

{
    my @keys = map { "key$_" } 1 .. 40;
    my $first = struct_encode(shuffled(@keys), canonical => 1);
    my %seen;
    for (1 .. 30) {
        $seen{ struct_encode(shuffled(@keys), canonical => 1) }++;
    }
    is_deeply([ keys %seen ], [$first], 'forty keys put in thirty orders: one encoding');
    my %plain;
    $plain{ struct_encode(shuffled(@keys)) }++ for 1 .. 30;
    cmp_ok(scalar keys %plain, '>', 1, '  where without it the order shows');
    is_deeply(struct_decode($first), shuffled(@keys), '  and it decodes to the data');
}

# in another process, with another hash seed
SKIP: {
    skip 'no perl to run', 1 unless -x $^X;
    my @inc = map { "-I$_" } @INC;
    my $code = 'use Struct::Codec qw(struct_encode); my %h = map { ("k$_" => $_) } 1 .. 50;'
             . ' $h{n} = { map { ("m$_" => [$_]) } 1 .. 20 }; print unpack "H*", struct_encode(\%h, canonical => 1)';
    my %out;
    for my $seed (1, 2, 3, 12345) {
        local $ENV{PERL_HASH_SEED} = $seed;
        local $ENV{PERL_PERTURB_KEYS} = 1;
        my $hex = `"$^X" @inc -e '$code'`;
        $out{$hex}++;
    }
    is(scalar keys %out, 1, 'four hash seeds in four processes: one encoding');
}

# ---- the order is perl's sort, by character ----------------------------------------

{
    # a key is its length (twice it, a bit for UTF-8 beside) and its bytes
    my $s = struct_encode({ b => 1, a => 2, c => 3, aa => 4, B => 5 }, canonical => 1);
    my @at = map { index $s, $_ } "\x02B", "\x02a", "\x04aa", "\x02b", "\x02c";
    ok(!grep({ $_ < 0 } @at), 'the keys are in the stream as written');
    is_deeply([ sort { $at[$a] <=> $at[$b] } 0 .. 4 ], [0 .. 4], '  in the order sort gives: B a aa b c');
}
{
    # Latin-1 keys and UTF-8 keys compare as characters: z (7a) < e-acute (e9) < A-macron (100)
    my $lat = "\x{e9}";
    my $h1 = { z => 1, $lat => 2, "\x{100}" => 3 };
    my %h2; $h2{"\x{100}"} = 3; $h2{$lat} = 2; $h2{z} = 1;
    my $b1 = struct_encode($h1, canonical => 1);
    is($b1, struct_encode(\%h2, canonical => 1), 'keys held as Latin-1 and as UTF-8: one encoding');
    my ($z, $e, $m) = (index($b1, 'z'), index($b1, "\xe9"), index($b1, "\xc4\x80"));
    ok($z < $e && $e < $m, '  ordered by character: z, then e-acute, then A-macron') or diag "$z $e $m";
    my $up = "\x{e9}x"; utf8::upgrade($up);
    my $down = "\x{e9}x"; utf8::downgrade($down);
    is(struct_encode({ $up => 1, "\x{101}" => 2 }, canonical => 1), struct_encode({ "\x{101}" => 2, $down => 1 }, canonical => 1),
       '  an upgraded and a downgraded key are the same key');
    is_deeply(struct_decode($b1), $h1, '  and they decode as they were');
    # a Latin-1 key that begins a UTF-8 one: the shorter first, in any order of building
    my $short = "\x{e9}"; utf8::downgrade($short);
    my $long = "\x{e9}\x{100}";
    my %enc;
    for my $round (1 .. 20) {
        my %h;
        if ($round % 2) { $h{$short} = 1; $h{$long} = 2; $h{"k$_"} = $_ for 1 .. $round }
        else { $h{"k$_"} = $_ for reverse 1 .. $round; $h{$long} = 2; $h{$short} = 1 }
        delete $h{"k$_"} for 1 .. $round;
        $enc{ struct_encode(\%h, canonical => 1) }++;
    }
    is(scalar keys %enc, 1, 'a Latin-1 key that begins a UTF-8 one: one encoding, however built');
    my ($only) = keys %enc;
    ok(index($only, "\x02\xe9") < index($only, "\xc3\xa9\xc4\x80"), '  the shorter first') or diag unpack 'H*', $only;
}
{
    my @keys = ('', 'a', "a\0", "a\0b", 'ab', "\x{263a}", "\x{1F600}", "\x{ff}");
    my $b = struct_encode({ map { ($_ => 1) } reverse @keys }, canonical => 1);
    is_deeply(struct_decode($b), { map { ($_ => 1) } @keys }, 'empty, NUL, wide and astral keys: decoded as they were');
    is($b, struct_encode({ map { ($_ => 1) } @keys }, canonical => 1), '  one encoding');
}

# ---- everywhere in the structure ------------------------------------------------------

{
    my $deep = sub {
        my @o = @_;
        return { map { ("o$_" => [ { map { ("i$_" => { map { ("j$_" => $_) } @o }) } @o } ]) } @o };
    };
    my $x = struct_encode($deep->(1 .. 9), canonical => 1);
    is($x, struct_encode($deep->(reverse 1 .. 9), canonical => 1), 'hashes in lists in hashes: every one in order');
    is_deeply(struct_decode($x), $deep->(1 .. 9), '  the data back');
}
{
    my %big = map { ("k$_" => $_) } 1 .. 20_000;
    my $b = struct_encode(\%big, canonical => 1);
    is($b, struct_encode({ map { ("k$_" => $_) } reverse 1 .. 20_000 }, canonical => 1), 'twenty thousand keys: one encoding');
    is_deeply(struct_decode($b), \%big, '  the data back');
}
{
    is(struct_encode({}, canonical => 1), struct_encode({}), 'an empty hash: as without it');
    is(struct_encode({ a => 1 }, canonical => 1), struct_encode({ a => 1 }), 'one key: as without it');
    is(struct_encode([1, 'x', undef], canonical => 1), struct_encode([1, 'x', undef]), 'no hash at all: as without it');
    my %one = map { ($_ => 1) } 'a' .. 'h';
    is(struct_encode(\%one, canonical => 0), struct_encode(\%one), 'canonical => 0: as without it (the one hash, its own order)');
}

# ---- with the rest of what the codec carries -------------------------------------------

{
    my $shared = { s => 1, t => 2 };
    my $v = { x => $shared, y => $shared, z => [ $shared ] };
    my $back = struct_decode(struct_encode($v, canonical => 1));
    is($back->{x}, $back->{y}, 'a hash referred to twice comes back once');
    is($back->{z}[0], $back->{x}, '  from wherever');
    my $cyc = { a => 1, b => 2 }; $cyc->{self} = $cyc;
    my $c = struct_decode(struct_encode($cyc, canonical => 1));
    is($c->{self}, $c, 'a cycle comes back a cycle');
    my $obj = bless { b => 1, a => 2 }, 'Some::Class';
    my $o = struct_decode(struct_encode($obj, canonical => 1));
    is(ref $o, 'Some::Class', 'a blessed hash keeps its class');
    is_deeply({ %$o }, { %$obj }, '  and its keys');
}
{
    require Hash::Util;
    my %r = (a => 1, b => 2, c => 3);
    Hash::Util::lock_ref_keys(\%r, qw(a b c d e));
    my $b = struct_encode(\%r, canonical => 1);
    is_deeply(struct_decode($b), { a => 1, b => 2, c => 3 }, 'a restricted hash with room for absent keys: the real keys, counted right');
    is($b, struct_encode({ c => 3, b => 2, a => 1 }, canonical => 1), '  the same bytes as the plain hash');
}
{
    package Tied::Hash;
    require Tie::Hash;
    our @ISA = ('Tie::StdHash');
    package main;
    tie my %t, 'Tied::Hash';
    %t = (b => 1, a => 2);
    tie my %u, 'Tied::Hash';
    $u{a} = 2; $u{b} = 1;
    my $canon = struct_encode(\%t, canonical => 1);
    is($canon, struct_encode(\%u, canonical => 1), 'a tied hash is written as its tie, the tie\'s own hash in order too');
    like($canon, qr/Tied::Hash/, '  as its tie');
    is_deeply({ %{ tied %{ struct_decode($canon) } } }, { a => 2, b => 1 }, '  and comes back tied, with its keys');
}
{
    # a pointer object: a blessed integer in a class whose DESTROY is C (t/34's way)
    no warnings 'once';
    *Pointer::Thing::DESTROY = \&Struct::Codec::import;
    my $w = bless \do { my $n = 7 }, 'Pointer::Thing';
    my $v = { b => 1, a => $w, c => 3 };
    ok(!eval { struct_encode($v, canonical => 1); 1 }, 'a pointer object inside: refused, as without it');
    like($@, qr/pointer/i, '  saying so');
    is_deeply(struct_decode(struct_encode($v, canonical => 1, strip_pointers => 1)), { a => undef, b => 1, c => 3 },
              '  and with strip_pointers, written as undef where it sits');
}
{
    my $before = scalar keys %{ { map { $_ => 1 } 1 .. 10 } };
    for (1 .. 2000) {
        eval { struct_encode({ map { ("k$_" => $_) } 1 .. 30, ($_ % 2 ? (bad => bless(\do { my $x = 1 }, 'Pointer::Thing')) : ()) }, canonical => 1) };
    }
    pass('two thousand encodings, half of them refused part way: no crash');
}

# ---- the option itself --------------------------------------------------------------------

{
    ok(!eval { struct_encode({}, canonnical => 1); 1 }, 'a misspelt option: refused');
    like($@, qr/unknown option 'canonnical'/, '  by name');
    ok(!eval { struct_encode({}, 'canonical'); 1 }, 'an option without its value: refused');
    is(Struct::Codec::encode({ b => 1, a => 2 }, canonical => 1), struct_encode({ a => 2, b => 1 }, canonical => 1), 'encode takes it too');
}

done_testing;
